import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cards_provider.dart';
import '../models/card_model.dart';
import '../utils/constants.dart';
import '../widgets/ui.dart';
import '../widgets/card_sheets.dart';
import 'card_invoice_screen.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final _pageCtrl = PageController(viewportFraction: 0.88);
  int _page = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  String get _uid => context.read<AuthProvider>().user?.uid ?? '';

  void _confirmDelete(CardModel card) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir cartão'),
        content: Text(
            'Excluir "${card.cardName}"? Todas as compras e pagamentos desse cartão também serão apagados.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              context.read<CardsProvider>().deleteCard(_uid, card.id!);
              Navigator.pop(ctx);
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _openInvoices(CardModel card, [InvoiceMonth? month]) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => CardInvoiceScreen(cardId: card.id!, initialMonth: month)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CardsProvider>();
    final ledgers = provider.ledgers;
    if (_page >= ledgers.length && ledgers.isNotEmpty) _page = ledgers.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cartões'),
        actions: [
          IconButton(
            tooltip: 'Novo cartão',
            icon: const Icon(Icons.add_card),
            onPressed: () => showCardFormSheet(context, uid: _uid),
          ),
        ],
      ),
      floatingActionButton: ledgers.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => showCardPurchaseSheet(context, ledgers[_page].card),
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Nova compra'),
            ),
      body: ledgers.isEmpty
          ? EmptyState(
              icon: Icons.credit_card,
              title: 'Nenhum cartão ainda',
              message:
                  'Cadastre seus cartões para acompanhar faturas, parcelas e limite.',
              action: FilledButton.icon(
                onPressed: () => showCardFormSheet(context, uid: _uid),
                icon: const Icon(Icons.add),
                label: const Text('Adicionar cartão'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                _LimitSummary(provider: provider),
                const SizedBox(height: 16),
                SizedBox(
                  height: 210,
                  child: PageView.builder(
                    controller: _pageCtrl,
                    itemCount: ledgers.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      child: CreditCardVisual(
                        ledger: ledgers[i],
                        onTap: () => _openInvoices(ledgers[i].card),
                      ),
                    ),
                  ),
                ),
                if (ledgers.length > 1) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      ledgers.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _page ? 20 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: i == _page
                              ? AppColors.primary
                              : AppColors.border(context),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _CardDetails(
                    ledger: ledgers[_page],
                    onEdit: () => showCardFormSheet(context,
                        uid: _uid, card: ledgers[_page].card),
                    onDelete: () => _confirmDelete(ledgers[_page].card),
                    onOpenInvoice: (m) => _openInvoices(ledgers[_page].card, m),
                  ),
                ),
              ],
            ),
    );
  }
}

class _LimitSummary extends StatelessWidget {
  final CardsProvider provider;
  const _LimitSummary({required this.provider});

  @override
  Widget build(BuildContext context) {
    final total = provider.totalLimit;
    final used = provider.totalUsedLimit;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Surface(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: _Metric(
                  label: 'Limite disponível',
                  value: Fmt.money(provider.totalAvailable),
                  color: AppColors.success),
            ),
            Expanded(
              child: _Metric(
                  label: 'Faturas atuais',
                  value: Fmt.money(provider.totalCurrentInvoices),
                  color: AppColors.primary,
                  end: true),
            ),
          ]),
          const SizedBox(height: 12),
          ProgressBar(
              value: total > 0 ? used / total : 0,
              color: used / (total == 0 ? 1 : total) > 0.85
                  ? AppColors.danger
                  : AppColors.primary),
          const SizedBox(height: 6),
          Text('${Fmt.money(used)} usados de ${Fmt.money(total)}',
              style: TextStyle(fontSize: 12, color: AppColors.subText(context))),
        ]),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool end;
  const _Metric(
      {required this.label, required this.value, required this.color, this.end = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.subText(context))),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}

class _CardDetails extends StatelessWidget {
  final CardLedger ledger;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<InvoiceMonth> onOpenInvoice;

  const _CardDetails({
    required this.ledger,
    required this.onEdit,
    required this.onDelete,
    required this.onOpenInvoice,
  });

  @override
  Widget build(BuildContext context) {
    final card = ledger.card;
    final current = ledger.currentInvoice();
    final closed = ledger.unpaidClosedInvoices();
    final currentStatus = ledger.statusOf(current);
    final sub = AppColors.subText(context);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Alertas de faturas fechadas em aberto
      for (final m in closed)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ClosedInvoiceAlert(ledger: ledger, month: m),
        ),

      // Fatura atual
      Surface(
        onTap: () => onOpenInvoice(current),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text('Fatura de ${current.label}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            StatusChip(label: currentStatus.label, color: currentStatus.color),
          ]),
          const SizedBox(height: 8),
          Text(Fmt.money(ledger.invoiceRemaining(current)),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Wrap(spacing: 14, runSpacing: 4, children: [
            _InfoIcon(Icons.lock_clock_outlined,
                'Fecha ${Fmt.dayMonth(card.closingDateOf(current))}'),
            _InfoIcon(Icons.event_outlined,
                'Vence ${Fmt.dayMonth(card.dueDateOf(current))}'),
            if (card.bestPurchaseDay != null)
              _InfoIcon(Icons.star_outline, 'Melhor dia: ${card.bestPurchaseDay}'),
          ]),
          if (card.invoiceClosingDay == null || card.invoiceDueDay == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Defina os dias de fechamento e vencimento para datas exatas.',
                style: TextStyle(fontSize: 12, color: sub),
              ),
            ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: const Text('Ver fatura'),
                onPressed: () => onOpenInvoice(current),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                icon: const Icon(Icons.payments_outlined, size: 18),
                label: const Text('Pagar'),
                onPressed: ledger.invoiceRemaining(current) > 0
                    ? () => showPayInvoiceSheet(context, ledger, current)
                    : null,
              ),
            ),
          ]),
        ]),
      ),
      const SizedBox(height: 12),

      // Limite
      Surface(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(
                child: Text('Limite', style: TextStyle(fontWeight: FontWeight.w700))),
            Text('${ledger.percentUsed.toStringAsFixed(0)}% usado',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: ledger.percentUsed > 85 ? AppColors.danger : sub)),
          ]),
          const SizedBox(height: 10),
          ProgressBar(
              value: ledger.percentUsed / 100,
              color: ledger.percentUsed > 85 ? AppColors.danger : card.color),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _Small('Usado', Fmt.money(ledger.usedLimit))),
            Expanded(child: _Small('Disponível', Fmt.money(ledger.availableLimit))),
            Expanded(child: _Small('Total', Fmt.money(card.limit), end: true)),
          ]),
          const SizedBox(height: 8),
          Text('Parcelas futuras também ocupam o limite até serem pagas.',
              style: TextStyle(fontSize: 11, color: sub)),
        ]),
      ),
      const SizedBox(height: 12),

      // Próximas faturas
      _Projection(ledger: ledger, from: current, onTap: onOpenInvoice),
      const SizedBox(height: 12),

      // Últimas compras
      Surface(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Últimas compras', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          if (ledger.transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('Nenhuma compra lançada', style: TextStyle(color: sub)),
            )
          else
            ...ledger.transactions.take(6).map((t) => TransactionTile(tx: t, ledger: ledger)),
        ]),
      ),
      const SizedBox(height: 12),

      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Editar cartão'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Excluir'),
          ),
        ),
      ]),
    ]);
  }
}

class _ClosedInvoiceAlert extends StatelessWidget {
  final CardLedger ledger;
  final InvoiceMonth month;
  const _ClosedInvoiceAlert({required this.ledger, required this.month});

  @override
  Widget build(BuildContext context) {
    final status = ledger.statusOf(month);
    final color = status.color;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(children: [
        Icon(status == InvoiceStatus.atrasada
                ? Icons.error_outline
                : Icons.schedule_outlined,
            color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
                status == InvoiceStatus.atrasada
                    ? 'Fatura de ${month.shortLabel} atrasada'
                    : 'Fatura de ${month.shortLabel} fechada',
                style: TextStyle(fontWeight: FontWeight.w700, color: color)),
            Text(
                '${Fmt.money(ledger.invoiceRemaining(month))} • vence ${Fmt.dayMonth(ledger.card.dueDateOf(month))}',
                style: const TextStyle(fontSize: 12)),
          ]),
        ),
        TextButton(
          onPressed: () => showPayInvoiceSheet(context, ledger, month),
          child: const Text('Pagar'),
        ),
      ]),
    );
  }
}

class _Projection extends StatelessWidget {
  final CardLedger ledger;
  final InvoiceMonth from;
  final ValueChanged<InvoiceMonth> onTap;
  const _Projection({required this.ledger, required this.from, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final data = ledger.projection(from, months: 6);
    final maxV = data.fold<double>(0, (m, e) => e.value > m ? e.value : m);
    return Surface(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Próximas faturas', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Inclui parcelas já lançadas',
            style: TextStyle(fontSize: 12, color: AppColors.subText(context))),
        const SizedBox(height: 14),
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.map((e) {
              final h = maxV > 0 ? (e.value / maxV) * 70 : 0.0;
              final isCurrent = e.key == from;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(e.key),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FittedBox(
                        child: Text(
                          e.value > 0 ? Fmt.money(e.value).replaceAll('R\$', '').trim() : '–',
                          style: TextStyle(fontSize: 10, color: AppColors.subText(context)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: h < 4 ? 4 : h,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? ledger.card.color
                              : ledger.card.color.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(e.key.shortLabel,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }
}

/// Linha de uma compra no cartão, com opção de excluir.
class TransactionTile extends StatelessWidget {
  final CardTransaction tx;
  final CardLedger ledger;
  final InvoiceMonth? month;

  const TransactionTile({super.key, required this.tx, required this.ledger, this.month});

  @override
  Widget build(BuildContext context) {
    final n = month != null ? tx.installmentNumberIn(month!) : null;
    final amount = month != null ? tx.amountIn(month!) : tx.totalAmount;
    final subtitle = tx.installments == 1
        ? '${Fmt.dayMonth(tx.purchaseDate)} • à vista'
        : n != null
            ? '${Fmt.dayMonth(tx.purchaseDate)} • parcela $n/${tx.installments}'
            : '${Fmt.dayMonth(tx.purchaseDate)} • ${tx.installments}x de ${Fmt.money(tx.regularInstallment)}';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: IconBadge(
          tx.installments > 1 ? Icons.view_week_outlined : Icons.shopping_bag_outlined,
          color: ledger.card.color,
          size: 38),
      title: Text(tx.description, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(Fmt.money(amount), style: const TextStyle(fontWeight: FontWeight.w700)),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 18),
          onSelected: (_) => _confirmDelete(context),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'delete', child: Text('Excluir compra')),
          ],
        ),
      ]),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir compra'),
        content: Text(tx.installments > 1
            ? 'Excluir "${tx.description}" e todas as ${tx.installments} parcelas?'
            : 'Excluir "${tx.description}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              context.read<CardsProvider>().deleteTransaction(tx.uid, tx.id);
              Navigator.pop(ctx);
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

class _InfoIcon extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoIcon(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.subText(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: c),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(fontSize: 12, color: c)),
    ]);
  }
}

class _Small extends StatelessWidget {
  final String label;
  final String value;
  final bool end;
  const _Small(this.label, this.value, {this.end = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.subText(context))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      ],
    );
  }
}
