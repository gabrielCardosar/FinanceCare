import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/models/card_model.dart';

CardModel _card({int? closing = 5, int? due = 12, double limit = 1000}) =>
    CardModel(
      id: 'c1',
      uid: 'u',
      cardName: 'Nubank',
      bankName: 'Nu',
      limit: limit,
      invoiceClosingDay: closing,
      invoiceDueDay: due,
    );

CardTransaction _tx(CardModel card, double total, DateTime date,
        {int installments = 1, String id = 't'}) =>
    CardTransaction(
      id: id,
      uid: 'u',
      cardId: card.id!,
      description: 'compra',
      totalAmount: total,
      installments: installments,
      purchaseDate: date,
      firstInvoice: card.invoiceFor(date),
    );

void main() {
  group('InvoiceMonth', () {
    test('add vira o ano', () {
      expect(const InvoiceMonth(2026, 11).add(3), const InvoiceMonth(2027, 2));
      expect(const InvoiceMonth(2026, 1).add(-1), const InvoiceMonth(2025, 12));
    });
    test('parse/key', () {
      expect(InvoiceMonth.parse('2026-03').key, '2026-03');
    });
  });

  group('ciclo da fatura', () {
    test('compra antes do fechamento cai na fatura do mês', () {
      final c = _card();
      expect(c.invoiceFor(DateTime(2026, 10, 4)), const InvoiceMonth(2026, 10));
    });
    test('compra no dia do fechamento vai para a próxima fatura', () {
      final c = _card();
      expect(c.invoiceFor(DateTime(2026, 10, 5)), const InvoiceMonth(2026, 11));
      expect(c.invoiceFor(DateTime(2026, 12, 20)), const InvoiceMonth(2027, 1));
    });
    test('vencimento depois do fechamento é no mesmo mês', () {
      final c = _card(closing: 5, due: 12);
      expect(c.dueDateOf(const InvoiceMonth(2026, 10)), DateTime(2026, 10, 12));
    });
    test('vencimento antes do fechamento é no mês seguinte', () {
      final c = _card(closing: 28, due: 5);
      expect(c.dueDateOf(const InvoiceMonth(2026, 12)), DateTime(2027, 1, 5));
    });
    test('fechamento dia 31 em fevereiro usa o último dia', () {
      final c = _card(closing: 31, due: 8);
      expect(c.closingDateOf(const InvoiceMonth(2026, 2)), DateTime(2026, 2, 28));
    });
    test('sem dia de fechamento acompanha o mês', () {
      final c = _card(closing: null);
      expect(c.invoiceFor(DateTime(2026, 10, 31)), const InvoiceMonth(2026, 10));
    });
  });

  group('parcelamento', () {
    test('centavos que sobram vão para a 1ª parcela', () {
      final c = _card();
      final t = _tx(c, 100, DateTime(2026, 10, 1), installments: 3);
      expect(t.installmentValue(1), 33.34);
      expect(t.installmentValue(2), 33.33);
      expect(t.installmentValue(3), 33.33);
    });
    test('parcelas caem em faturas consecutivas', () {
      final c = _card();
      // depois do fechamento (dia 5) → 1ª parcela na fatura de dezembro
      final t = _tx(c, 300, DateTime(2026, 11, 10), installments: 3);
      final l = CardLedger(card: c, transactions: [t]);
      expect(l.invoiceTotal(const InvoiceMonth(2026, 11)), 0);
      expect(l.invoiceTotal(const InvoiceMonth(2026, 12)), 100);
      expect(l.invoiceTotal(const InvoiceMonth(2027, 1)), 100);
      expect(l.invoiceTotal(const InvoiceMonth(2027, 2)), 100);
      expect(l.invoiceTotal(const InvoiceMonth(2027, 3)), 0);
    });
    test('parcelado compromete o limite inteiro', () {
      final c = _card();
      final l = CardLedger(card: c, transactions: [
        _tx(c, 600, DateTime(2026, 10, 1), installments: 6),
      ]);
      expect(l.usedLimit, 600);
      expect(l.availableLimit, 400);
    });
  });

  group('pagamentos', () {
    final c = _card();
    const m = InvoiceMonth(2026, 10);
    final txs = [
      _tx(c, 200, DateTime(2026, 9, 20), id: 'a'),
      _tx(c, 300, DateTime(2026, 9, 25), installments: 3, id: 'b'),
    ];

    test('pagar a fatura libera só o valor pago', () {
      final l = CardLedger(card: c, transactions: txs, payments: [
        CardPayment(
            id: 'p', uid: 'u', cardId: 'c1', amount: 300, invoice: m,
            date: DateTime(2026, 10, 12)),
      ]);
      expect(l.invoiceTotal(m), 300);
      expect(l.invoiceRemaining(m), 0);
      expect(l.usedLimit, 200); // restam 2 parcelas de 100
      expect(l.statusOf(m, now: DateTime(2026, 10, 12)), InvoiceStatus.paga);
    });

    test('pagamento parcial deixa saldo e fatura atrasa após vencimento', () {
      final l = CardLedger(card: c, transactions: txs, payments: [
        CardPayment(id: 'p', uid: 'u', cardId: 'c1', amount: 100, invoice: m),
      ]);
      expect(l.invoiceRemaining(m), 200);
      expect(l.statusOf(m, now: DateTime(2026, 10, 4)), InvoiceStatus.aberta);
      expect(l.statusOf(m, now: DateTime(2026, 10, 8)), InvoiceStatus.fechada);
      expect(l.statusOf(m, now: DateTime(2026, 10, 13)), InvoiceStatus.atrasada);
    });

    test('próxima fatura a pagar é a fechada mais antiga', () {
      final l = CardLedger(card: c, transactions: txs);
      final now = DateTime(2026, 11, 7); // fatura atual = dezembro
      expect(l.unpaidClosedInvoices(now: now),
          [const InvoiceMonth(2026, 10), const InvoiceMonth(2026, 11)]);
      expect(l.nextInvoiceToPay(now: now), const InvoiceMonth(2026, 10));
      expect(l.closedOutstanding(now: now), 400);
    });

    test('a pagar até uma data considera o vencimento', () {
      final l = CardLedger(card: c, transactions: txs);
      final now = DateTime(2026, 10, 8); // out fechou, vence 12/10
      expect(l.dueUntil(DateTime(2026, 10, 31), now: now), 300);
      expect(l.dueUntil(DateTime(2026, 11, 30), now: now), 400);
    });

    test('pagamentos saem do saldo pela data do pagamento', () {
      final l = CardLedger(card: c, transactions: txs, payments: [
        CardPayment(
            id: 'p1', uid: 'u', cardId: 'c1', amount: 50, invoice: m,
            date: DateTime(2026, 10, 2)),
        CardPayment(
            id: 'p2', uid: 'u', cardId: 'c1', amount: 70, invoice: m,
            date: DateTime(2026, 11, 2)),
      ]);
      expect(l.paidInCalendarMonth(2026, 10), 50);
      expect(l.paidInCalendarMonth(2026, 11), 70);
    });

    test('ignora lançamentos de outros cartões', () {
      final other = CardTransaction(
          id: 'x', uid: 'u', cardId: 'outro', description: '',
          totalAmount: 999, firstInvoice: m);
      final l = CardLedger(card: c, transactions: [...txs, other]);
      expect(l.totalCharged, 500);
    });
  });
}
