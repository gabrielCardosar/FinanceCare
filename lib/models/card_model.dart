import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Mês de referência de uma fatura (o mês em que ela FECHA).
class InvoiceMonth implements Comparable<InvoiceMonth> {
  final int year;
  final int month;

  const InvoiceMonth(this.year, this.month);

  factory InvoiceMonth.fromDate(DateTime d) => InvoiceMonth(d.year, d.month);

  factory InvoiceMonth.fromIndex(int index) =>
      InvoiceMonth(index ~/ 12, index % 12 + 1);

  /// Formato "YYYY-MM"
  factory InvoiceMonth.parse(String key) {
    final parts = key.split('-');
    return InvoiceMonth(int.parse(parts[0]), int.parse(parts[1]));
  }

  int get index => year * 12 + (month - 1);

  InvoiceMonth add(int months) => InvoiceMonth.fromIndex(index + months);

  String get key => '$year-${month.toString().padLeft(2, '0')}';

  static const _short = [
    'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
    'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
  ];
  static const _long = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
  ];

  String get shortLabel => '${_short[month - 1]}/${year % 100}';
  String get label => '${_long[month - 1]} $year';

  bool operator <(InvoiceMonth o) => index < o.index;
  bool operator >(InvoiceMonth o) => index > o.index;
  bool operator <=(InvoiceMonth o) => index <= o.index;
  bool operator >=(InvoiceMonth o) => index >= o.index;

  @override
  int compareTo(InvoiceMonth other) => index.compareTo(other.index);

  @override
  bool operator ==(Object other) =>
      other is InvoiceMonth && other.index == index;

  @override
  int get hashCode => index;

  @override
  String toString() => key;
}

int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Parcela no formato antigo (v1). Mantido apenas para migrar dados antigos.
class CardInstallment {
  final String id;
  final String description;
  final double totalAmount;
  final double installmentAmount;
  final int totalInstallments;
  final int remainingInstallments;
  final DateTime purchaseDate;

  CardInstallment({
    required this.id,
    required this.description,
    required this.totalAmount,
    required this.installmentAmount,
    required this.totalInstallments,
    required this.remainingInstallments,
    required this.purchaseDate,
  });

  factory CardInstallment.fromMap(Map<String, dynamic> map) => CardInstallment(
        id: map['id'] ?? '',
        description: map['description'] ?? '',
        totalAmount: (map['totalAmount'] ?? 0).toDouble(),
        installmentAmount: (map['installmentAmount'] ?? 0).toDouble(),
        totalInstallments: map['totalInstallments'] ?? 1,
        remainingInstallments: map['remainingInstallments'] ?? 1,
        purchaseDate: map['purchaseDate'] != null
            ? DateTime.parse(map['purchaseDate'])
            : DateTime.now(),
      );
}

class CardModel {
  /// Versão atual da lógica de fatura (lançamentos + pagamentos).
  static const int currentLedgerVersion = 2;

  final String? id;
  final String uid;
  final String cardName;
  final String bankName;
  final double limit;
  final DateTime createdAt;
  final int colorValue;
  final int? invoiceDueDay;
  final int? invoiceClosingDay;
  final int ledgerVersion;

  // Campos do formato antigo (v1), lidos apenas para migração
  final double legacyUsedLimit;
  final List<CardInstallment> legacyInstallments;
  final double legacyPaidInvoiceAmount;

  CardModel({
    this.id,
    required this.uid,
    required this.cardName,
    required this.bankName,
    required this.limit,
    DateTime? createdAt,
    this.colorValue = 0xFF6366F1,
    this.invoiceDueDay,
    this.invoiceClosingDay,
    this.ledgerVersion = currentLedgerVersion,
    this.legacyUsedLimit = 0,
    this.legacyInstallments = const [],
    this.legacyPaidInvoiceAmount = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  Color get color => Color(colorValue);

  bool get needsMigration =>
      ledgerVersion < currentLedgerVersion &&
      (legacyUsedLimit > 0 ||
          legacyInstallments.isNotEmpty ||
          legacyPaidInvoiceAmount > 0);

  // ── Ciclo da fatura ───────────────────────────────────────────────────

  /// Data de fechamento da fatura do mês [m].
  /// Sem dia de fechamento definido, a fatura acompanha o mês do calendário.
  DateTime closingDateOf(InvoiceMonth m) {
    final days = _daysInMonth(m.year, m.month);
    final day = invoiceClosingDay == null
        ? days
        : math.min(invoiceClosingDay!, days);
    return DateTime(m.year, m.month, day);
  }

  /// Data de vencimento da fatura que fecha no mês [m].
  /// Se o dia de vencimento é menor ou igual ao de fechamento,
  /// a fatura vence no mês seguinte.
  /// A comparação usa os dias configurados (não ajustados ao tamanho do
  /// mês), para a regra não mudar em meses curtos como fevereiro.
  DateTime dueDateOf(InvoiceMonth m) {
    final dueDay = invoiceDueDay ?? 10;
    final closeDay = invoiceClosingDay ?? 31;
    final target = dueDay > closeDay ? m : m.add(1);
    return DateTime(target.year, target.month,
        math.min(dueDay, _daysInMonth(target.year, target.month)));
  }

  /// Em qual fatura cai uma compra feita em [date].
  /// Compras a partir do dia do fechamento vão para a fatura seguinte.
  InvoiceMonth invoiceFor(DateTime date) {
    final m = InvoiceMonth.fromDate(date);
    if (invoiceClosingDay == null) return m;
    return _dateOnly(date).isBefore(closingDateOf(m)) ? m : m.add(1);
  }

  /// Melhor dia para comprar (primeiro dia da próxima fatura).
  int? get bestPurchaseDay => invoiceClosingDay;

  // ── Persistência ──────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'cardName': cardName,
        'bankName': bankName,
        'limit': limit,
        'createdAt': createdAt.toIso8601String(),
        'colorValue': colorValue,
        'invoiceDueDay': invoiceDueDay,
        'invoiceClosingDay': invoiceClosingDay,
        'ledgerVersion': ledgerVersion,
      };

  factory CardModel.fromMap(Map<String, dynamic> map, String id) => CardModel(
        id: id,
        uid: map['uid'] ?? '',
        cardName: map['cardName'] ?? '',
        bankName: map['bankName'] ?? '',
        limit: (map['limit'] ?? 0).toDouble(),
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'])
            : DateTime.now(),
        colorValue: map['colorValue'] ?? 0xFF6366F1,
        invoiceDueDay: map['invoiceDueDay'],
        invoiceClosingDay: map['invoiceClosingDay'],
        ledgerVersion: map['ledgerVersion'] ?? 1,
        legacyUsedLimit: (map['usedLimit'] ?? 0).toDouble(),
        legacyInstallments: (map['installments'] as List<dynamic>?)
                ?.map((i) => CardInstallment.fromMap(i as Map<String, dynamic>))
                .toList() ??
            [],
        legacyPaidInvoiceAmount: (map['paidInvoiceAmount'] ?? 0).toDouble(),
      );

  CardModel copyWith({
    String? cardName,
    String? bankName,
    double? limit,
    int? colorValue,
    Object? invoiceDueDay = _sentinel,
    Object? invoiceClosingDay = _sentinel,
  }) =>
      CardModel(
        id: id,
        uid: uid,
        cardName: cardName ?? this.cardName,
        bankName: bankName ?? this.bankName,
        limit: limit ?? this.limit,
        createdAt: createdAt,
        colorValue: colorValue ?? this.colorValue,
        invoiceDueDay: invoiceDueDay == _sentinel
            ? this.invoiceDueDay
            : invoiceDueDay as int?,
        invoiceClosingDay: invoiceClosingDay == _sentinel
            ? this.invoiceClosingDay
            : invoiceClosingDay as int?,
        ledgerVersion: ledgerVersion,
        legacyUsedLimit: legacyUsedLimit,
        legacyInstallments: legacyInstallments,
        legacyPaidInvoiceAmount: legacyPaidInvoiceAmount,
      );
}

const Object _sentinel = Object();

/// Uma compra lançada no cartão (à vista ou parcelada).
class CardTransaction {
  final String id;
  final String uid;
  final String cardId;
  final String description;
  final double totalAmount;
  final int installments;
  final DateTime purchaseDate;

  /// Fatura em que cai a 1ª parcela.
  final InvoiceMonth firstInvoice;

  CardTransaction({
    required this.id,
    required this.uid,
    required this.cardId,
    required this.description,
    required this.totalAmount,
    required this.firstInvoice,
    this.installments = 1,
    DateTime? purchaseDate,
  }) : purchaseDate = purchaseDate ?? DateTime.now();

  int get _totalCents => (totalAmount * 100).round();

  /// Valor da parcela [n] (1..installments). Os centavos que sobram da
  /// divisão vão para a 1ª parcela, para a soma bater com o total.
  double installmentValue(int n) {
    final base = _totalCents ~/ installments;
    final rest = _totalCents - base * installments;
    return (n == 1 ? base + rest : base) / 100;
  }

  double get regularInstallment => installmentValue(installments);

  InvoiceMonth get lastInvoice => firstInvoice.add(installments - 1);

  /// Número da parcela que cai na fatura [m], ou null se nenhuma.
  int? installmentNumberIn(InvoiceMonth m) {
    final diff = m.index - firstInvoice.index;
    return diff >= 0 && diff < installments ? diff + 1 : null;
  }

  double amountIn(InvoiceMonth m) {
    final n = installmentNumberIn(m);
    return n == null ? 0 : installmentValue(n);
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'uid': uid,
        'cardId': cardId,
        'description': description,
        'totalAmount': totalAmount,
        'installments': installments,
        'purchaseDate': purchaseDate.toIso8601String(),
        'firstInvoice': firstInvoice.key,
      };

  factory CardTransaction.fromMap(Map<String, dynamic> map) {
    final date = map['purchaseDate'] != null
        ? DateTime.parse(map['purchaseDate'])
        : DateTime.now();
    return CardTransaction(
      id: map['id'] ?? '',
      uid: map['uid'] ?? '',
      cardId: map['cardId'] ?? '',
      description: map['description'] ?? '',
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      installments: math.max(1, ((map['installments'] ?? 1) as num).toInt()),
      purchaseDate: date,
      firstInvoice: map['firstInvoice'] != null
          ? InvoiceMonth.parse(map['firstInvoice'])
          : InvoiceMonth.fromDate(date),
    );
  }
}

/// Um pagamento feito para uma fatura.
class CardPayment {
  final String id;
  final String uid;
  final String cardId;
  final double amount;
  final DateTime date;
  final InvoiceMonth invoice;

  CardPayment({
    required this.id,
    required this.uid,
    required this.cardId,
    required this.amount,
    required this.invoice,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'uid': uid,
        'cardId': cardId,
        'amount': amount,
        'date': date.toIso8601String(),
        'invoice': invoice.key,
      };

  factory CardPayment.fromMap(Map<String, dynamic> map) {
    final date =
        map['date'] != null ? DateTime.parse(map['date']) : DateTime.now();
    return CardPayment(
      id: map['id'] ?? '',
      uid: map['uid'] ?? '',
      cardId: map['cardId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      date: date,
      invoice: map['invoice'] != null
          ? InvoiceMonth.parse(map['invoice'])
          : InvoiceMonth.fromDate(date),
    );
  }
}

enum InvoiceStatus { vazia, aberta, fechada, atrasada, paga }

extension InvoiceStatusExt on InvoiceStatus {
  String get label {
    switch (this) {
      case InvoiceStatus.vazia:
        return 'Sem lançamentos';
      case InvoiceStatus.aberta:
        return 'Aberta';
      case InvoiceStatus.fechada:
        return 'Fechada';
      case InvoiceStatus.atrasada:
        return 'Atrasada';
      case InvoiceStatus.paga:
        return 'Paga';
    }
  }

  Color get color {
    switch (this) {
      case InvoiceStatus.vazia:
        return const Color(0xFF94A3B8);
      case InvoiceStatus.aberta:
        return const Color(0xFF3B82F6);
      case InvoiceStatus.fechada:
        return const Color(0xFFF59E0B);
      case InvoiceStatus.atrasada:
        return const Color(0xFFEF4444);
      case InvoiceStatus.paga:
        return const Color(0xFF10B981);
    }
  }
}

/// Toda a contabilidade de um cartão: faturas, limite e pagamentos.
class CardLedger {
  final CardModel card;
  final List<CardTransaction> transactions;
  final List<CardPayment> payments;

  CardLedger({
    required this.card,
    List<CardTransaction> transactions = const [],
    List<CardPayment> payments = const [],
  })  : transactions = transactions.where((t) => t.cardId == card.id).toList()
          ..sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate)),
        payments = payments.where((p) => p.cardId == card.id).toList()
          ..sort((a, b) => b.date.compareTo(a.date));

  static double _round(double v) => (v * 100).roundToDouble() / 100;

  double invoiceTotal(InvoiceMonth m) =>
      _round(transactions.fold(0.0, (s, t) => s + t.amountIn(m)));

  double invoicePaid(InvoiceMonth m) => _round(payments
      .where((p) => p.invoice == m)
      .fold(0.0, (s, p) => s + p.amount));

  double invoiceRemaining(InvoiceMonth m) =>
      math.max(0, _round(invoiceTotal(m) - invoicePaid(m)));

  List<CardTransaction> transactionsIn(InvoiceMonth m) =>
      transactions.where((t) => t.installmentNumberIn(m) != null).toList();

  List<CardPayment> paymentsFor(InvoiceMonth m) =>
      payments.where((p) => p.invoice == m).toList();

  InvoiceStatus statusOf(InvoiceMonth m, {DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    final total = invoiceTotal(m);
    if (total <= 0) return InvoiceStatus.vazia;
    if (invoiceRemaining(m) <= 0) return InvoiceStatus.paga;
    if (today.isBefore(card.closingDateOf(m))) return InvoiceStatus.aberta;
    if (today.isAfter(card.dueDateOf(m))) return InvoiceStatus.atrasada;
    return InvoiceStatus.fechada;
  }

  /// Fatura que está recebendo as compras de hoje.
  InvoiceMonth currentInvoice({DateTime? now}) =>
      card.invoiceFor(now ?? DateTime.now());

  // ── Limite ────────────────────────────────────────────────────────────

  double get totalCharged =>
      _round(transactions.fold(0.0, (s, t) => s + t.totalAmount));

  /// Total pago que conta para o limite. O que for pago a mais numa fatura
  /// (por exemplo, se uma compra já paga for apagada) não libera limite extra.
  double get totalPaid => _round(payments
      .map((p) => p.invoice)
      .toSet()
      .fold(0.0, (s, m) => s + math.min(invoicePaid(m), invoiceTotal(m))));

  /// Limite comprometido: tudo que foi comprado (inclusive parcelas
  /// futuras) menos o que já foi pago.
  double get usedLimit => math.max(0, _round(totalCharged - totalPaid));

  double get availableLimit => _round(card.limit - usedLimit);

  double get percentUsed =>
      card.limit > 0 ? (usedLimit / card.limit * 100) : 0;

  // ── Faturas ───────────────────────────────────────────────────────────

  /// Faturas já fechadas que ainda têm saldo a pagar (mais antiga primeiro).
  List<InvoiceMonth> unpaidClosedInvoices({DateTime? now}) {
    final current = currentInvoice(now: now);
    final months = <InvoiceMonth>{
      for (final t in transactions)
        for (var i = 0; i < t.installments; i++) t.firstInvoice.add(i),
    }.where((m) => m < current && invoiceRemaining(m) > 0).toList()
      ..sort();
    return months;
  }

  /// Próxima fatura a pagar: a fechada mais antiga em aberto,
  /// ou a fatura atual (aberta) se não houver nenhuma fechada pendente.
  InvoiceMonth nextInvoiceToPay({DateTime? now}) {
    final closed = unpaidClosedInvoices(now: now);
    return closed.isNotEmpty ? closed.first : currentInvoice(now: now);
  }

  /// Total devido de faturas que já fecharam.
  double closedOutstanding({DateTime? now}) => _round(
      unpaidClosedInvoices(now: now).fold(0.0, (s, m) => s + invoiceRemaining(m)));

  /// Saldo a pagar de faturas que vencem até [until] (inclusive).
  double dueUntil(DateTime until, {DateTime? now}) {
    final limitDay = _dateOnly(until);
    final current = currentInvoice(now: now);
    final candidates = [...unpaidClosedInvoices(now: now), current];
    return _round(candidates
        .where((m) => !card.dueDateOf(m).isAfter(limitDay))
        .fold(0.0, (s, m) => s + invoiceRemaining(m)));
  }

  /// Valor pago em faturas dentro de um mês do calendário (sai do saldo).
  double paidInCalendarMonth(int year, int month) => _round(payments
      .where((p) => p.date.year == year && p.date.month == month)
      .fold(0.0, (s, p) => s + p.amount));

  /// Total de cada fatura a partir de [from] (para ver parcelas futuras).
  List<MapEntry<InvoiceMonth, double>> projection(InvoiceMonth from,
          {int months = 6}) =>
      List.generate(months, (i) {
        final m = from.add(i);
        return MapEntry(m, invoiceRemaining(m));
      });
}
