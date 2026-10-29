import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/card_model.dart';
import '../providers/cards_provider.dart';
import '../utils/constants.dart';
import '../widgets/ui.dart';
import '../widgets/card_sheets.dart';
import 'cards_screen.dart' show TransactionTile;

/// Detalhe das faturas de um cartão, navegando mês a mês.
class CardInvoiceScreen extends StatefulWidget {
  final String cardId;
  final InvoiceMonth? initialMonth;

  const CardInvoiceScreen({super.key, required this.cardId, this.initialMonth});

  @override
  State<CardInvoiceScreen> createState() => _CardInvoiceScreenState();
}

class _CardInvoiceScreenState extends State<CardInvoiceScreen> {
  InvoiceMonth? _month;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CardsProvider>();
    final card = provider.cardById(widget.cardId);
    if (card == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(icon: Icons.credit_card_off, title: 'Cartão não encontrado'),
      );
    }
    final ledger = provider.ledgerOf(card);
    final month = _month ??= widget.initialMonth ?? ledger.currentInvoice();
    final status = ledger.statusOf(month);
    final txs = ledger.transactionsIn(month);
    final payments = ledger.paymentsFor(month);
    final remaining = ledger.invoiceRemaining(month);
    final sub = AppColors.subText(context);

    return Scaffold(
      appBar: AppBar(title: Text(card.cardName)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCardPurchaseSheet(context, card),
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Nova compra'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        children: [
          // Seletor de mês
          Row(children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() => _month = month.add(-1)),
            ),
            Expanded(
              child: Column(children: [
                Text(month.label,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                if (month == ledger.currentInvoice())
                  Text('fatura atual', style: TextStyle(fontSize: 12, color: sub)),
              ]),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(() => _month = month.add(1)),
            ),
          ]),
          const SizedBox(height: 8),

          // Resumo da fatura
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [card.color, card.color.withValues(alpha: 0.78)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Expanded(
                  child: Text('Valor da fatura',
                      style: TextStyle(color: Colors.white70)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                  child: Text(status.label,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ]),
              const SizedBox(height: 4),
              Text(Fmt.money(ledger.invoiceTotal(month)),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              Row(children: [
                _WhiteInfo('Fecha', Fmt.dayMonth(card.closingDateOf(month))),
                _WhiteInfo('Vence', Fmt.dayMonth(card.dueDateOf(month))),
                _WhiteInfo('Pago', Fmt.money(ledger.invoicePaid(month))),
              ]),
              if (remaining > 0) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.white, foregroundColor: card.color),
                    onPressed: () => showPayInvoiceSheet(context, ledger, month),
                    icon: const Icon(Icons.payments_outlined),
                    label: Text(status == InvoiceStatus.aberta
                        ? 'Antecipar pagamento (${Fmt.money(remaining)})'
                        : 'Pagar ${Fmt.money(remaining)}'),
                  ),
                ),
              ],
            ]),
          ),
          const SizedBox(height: 16),

          SectionHeader('Lançamentos (${txs.length})'),
          if (txs.isEmpty)
            Surface(
              child: Text('Nenhuma compra nesta fatura.', style: TextStyle(color: sub)),
            )
          else
            Surface(
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
              child: Column(
                children: txs
                    .map((t) => TransactionTile(tx: t, ledger: ledger, month: month))
                    .toList(),
              ),
            ),

          if (payments.isNotEmpty) ...[
            const SizedBox(height: 16),
            const SectionHeader('Pagamentos'),
            Surface(
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
              child: Column(
                children: payments
                    .map((p) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const IconBadge(Icons.check_circle_outline,
                              color: AppColors.success, size: 38),
                          title: Text(Fmt.money(p.amount),
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text('Pago em ${Fmt.dayMonth(p.date)}/${p.date.year}'),
                          trailing: IconButton(
                            tooltip: 'Desfazer pagamento',
                            icon: const Icon(Icons.undo, size: 20),
                            onPressed: () => _confirmUndo(context, p),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmUndo(BuildContext context, CardPayment p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desfazer pagamento'),
        content: Text(
            'Remover o pagamento de ${Fmt.money(p.amount)}? O valor volta para a fatura e para o seu saldo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              context.read<CardsProvider>().deletePayment(p.uid, p.id);
              Navigator.pop(ctx);
            },
            child: const Text('Desfazer'),
          ),
        ],
      ),
    );
  }
}

class _WhiteInfo extends StatelessWidget {
  final String label;
  final String value;
  const _WhiteInfo(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
      ]),
    );
  }
}
