import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/card_model.dart';
import '../providers/cards_provider.dart';
import '../utils/constants.dart';

Future<T?> _showSheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: child,
      ),
    ),
  );
}

Widget _title(BuildContext context, String text, [String? subtitle]) => Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(text,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800)),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(subtitle,
                style: TextStyle(color: AppColors.subText(context))),
          ),
      ]),
    );

void _snack(BuildContext context, String msg, {Color? color}) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
}

/// Seletor de número de parcelas (1x a 24x).
class InstallmentPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final double total;

  const InstallmentPicker(
      {super.key, required this.value, required this.onChanged, required this.total});

  @override
  Widget build(BuildContext context) {
    final per = total > 0 ? total / value : 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value == 1 ? 'À vista' : 'Parcelado',
                style: TextStyle(fontSize: 12, color: AppColors.subText(context))),
            Text(value == 1 ? Fmt.money(total) : '${value}x de ${Fmt.money(per)}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
        ),
        Text('${value}x',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: value < 24 ? () => onChanged(value + 1) : null,
        ),
      ]),
    );
  }
}

/// Mostra em qual fatura uma compra vai cair.
class InvoiceHint extends StatelessWidget {
  final CardModel card;
  final DateTime date;
  final int installments;

  const InvoiceHint(
      {super.key, required this.card, required this.date, this.installments = 1});

  @override
  Widget build(BuildContext context) {
    final inv = card.invoiceFor(date);
    final last = inv.add(installments - 1);
    final text = installments == 1
        ? 'Entra na fatura de ${inv.label} • vence ${Fmt.dayMonth(card.dueDateOf(inv))}'
        : 'Parcelas de ${inv.shortLabel} até ${last.shortLabel} • 1ª vence ${Fmt.dayMonth(card.dueDateOf(inv))}';
    return Row(children: [
      const Icon(Icons.event_note_outlined, size: 16, color: AppColors.info),
      const SizedBox(width: 6),
      Expanded(
        child: Text(text,
            style: const TextStyle(fontSize: 12, color: AppColors.info)),
      ),
    ]);
  }
}

// ─── Nova compra no cartão ─────────────────────────────────────────────────

Future<void> showCardPurchaseSheet(BuildContext context, CardModel card) {
  final descCtrl = TextEditingController();
  final valueCtrl = TextEditingController();
  int parcelas = 1;
  DateTime date = DateTime.now();
  final provider = context.read<CardsProvider>();
  final available = provider.ledgerOf(card).availableLimit;

  return _showSheet(
    context,
    StatefulBuilder(builder: (ctx, setSheet) {
      final total = Fmt.parseMoney(valueCtrl.text) ?? 0;
      final overLimit = total > available;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _title(ctx, 'Nova compra', '${card.cardName} • disponível ${Fmt.money(available)}'),
          TextField(
            controller: descCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
                labelText: 'Descrição', prefixIcon: Icon(Icons.shopping_bag_outlined)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: valueCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
                labelText: 'Valor total', prefixText: 'R\$ ', hintText: '0,00'),
            onChanged: (_) => setSheet(() {}),
          ),
          const SizedBox(height: 12),
          InstallmentPicker(
              value: parcelas,
              total: total,
              onChanged: (v) => setSheet(() => parcelas = v)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            label: Text('Data da compra: ${Fmt.dayMonth(date)}/${date.year}'),
            onPressed: () async {
              final picked = await showDatePicker(
                context: ctx,
                initialDate: date,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setSheet(() => date = picked);
            },
          ),
          const SizedBox(height: 12),
          InvoiceHint(card: card, date: date, installments: parcelas),
          if (overLimit) ...[
            const SizedBox(height: 8),
            const Row(children: [
              Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.danger),
              SizedBox(width: 6),
              Expanded(
                child: Text('Valor maior que o limite disponível',
                    style: TextStyle(fontSize: 12, color: AppColors.danger)),
              ),
            ]),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () async {
              final desc = descCtrl.text.trim();
              if (desc.isEmpty || total <= 0) {
                _snack(ctx, 'Preencha descrição e valor');
                return;
              }
              final tx = provider.buildTransaction(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                card: card,
                description: desc,
                totalAmount: total,
                installments: parcelas,
                purchaseDate: date,
              );
              Navigator.pop(ctx);
              await provider.saveTransaction(tx);
              if (context.mounted) {
                _snack(context,
                    parcelas == 1
                        ? 'Compra lançada na fatura de ${tx.firstInvoice.shortLabel}'
                        : '${parcelas}x de ${Fmt.money(tx.regularInstallment)} lançado',
                    color: AppColors.success);
              }
            },
            child: const Text('Lançar compra'),
          ),
        ],
      );
    }),
  );
}

// ─── Pagar fatura ──────────────────────────────────────────────────────────

Future<void> showPayInvoiceSheet(
    BuildContext context, CardLedger ledger, InvoiceMonth invoice) {
  final remaining = ledger.invoiceRemaining(invoice);
  final ctrl = TextEditingController(
      text: remaining.toStringAsFixed(2).replaceAll('.', ','));
  final card = ledger.card;
  final status = ledger.statusOf(invoice);

  return _showSheet(
    context,
    StatefulBuilder(builder: (ctx, setSheet) {
      final amount = Fmt.parseMoney(ctrl.text) ?? 0;
      final invalid = amount <= 0 || amount > remaining + 0.001;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _title(ctx, 'Pagar fatura',
              '${card.cardName} • ${invoice.label} • ${status.label.toLowerCase()}'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(children: [
              _row('Total da fatura', Fmt.money(ledger.invoiceTotal(invoice))),
              _row('Já pago', Fmt.money(ledger.invoicePaid(invoice))),
              const Divider(height: 16),
              _row('Falta pagar', Fmt.money(remaining), bold: true),
              _row('Vencimento', Fmt.dayMonth(card.dueDateOf(invoice))),
            ]),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
                labelText: 'Valor do pagamento', prefixText: 'R\$ '),
            onChanged: (_) => setSheet(() {}),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            ActionChip(
              label: const Text('Valor total'),
              onPressed: () => setSheet(() => ctrl.text =
                  remaining.toStringAsFixed(2).replaceAll('.', ',')),
            ),
            ActionChip(
              label: const Text('Metade'),
              onPressed: () => setSheet(() => ctrl.text =
                  (remaining / 2).toStringAsFixed(2).replaceAll('.', ',')),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.info_outline, size: 16, color: AppColors.success),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'O valor sai do seu saldo agora e libera o mesmo valor no limite do cartão.',
                style: TextStyle(fontSize: 12, color: AppColors.subText(ctx)),
              ),
            ),
          ]),
          if (amount > remaining + 0.001)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('O valor é maior do que falta pagar',
                  style: TextStyle(color: AppColors.danger, fontSize: 12)),
            ),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: invalid
                ? null
                : () async {
                    Navigator.pop(ctx);
                    await context
                        .read<CardsProvider>()
                        .payInvoice(card: card, invoice: invoice, amount: amount);
                    if (context.mounted) {
                      _snack(
                          context,
                          amount >= remaining - 0.001
                              ? 'Fatura de ${invoice.shortLabel} paga!'
                              : 'Pagamento parcial de ${Fmt.money(amount)} registrado',
                          color: AppColors.success);
                    }
                  },
            child: Text('Pagar ${Fmt.money(amount)}'),
          ),
        ],
      );
    }),
  );
}

Widget _row(String label, String value, {bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Expanded(child: Text(label)),
        Text(value,
            style: TextStyle(
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                fontSize: bold ? 16 : 14)),
      ]),
    );

// ─── Cadastrar / editar cartão ─────────────────────────────────────────────

const List<Color> cardColors = [
  Color(0xFF5B5BF0), Color(0xFF8B5CF6), Color(0xFF820AD1), Color(0xFF3B82F6),
  Color(0xFF0EA5E9), Color(0xFF10B981), Color(0xFFF59E0B), Color(0xFFF97316),
  Color(0xFFEF4444), Color(0xFFEC4899), Color(0xFF475569), Color(0xFF0F172A),
];

Future<void> showCardFormSheet(BuildContext context,
    {required String uid, CardModel? card}) {
  final isEditing = card != null;
  final nameCtrl = TextEditingController(text: card?.cardName ?? '');
  final bankCtrl = TextEditingController(text: card?.bankName ?? '');
  final limitCtrl = TextEditingController(
      text: isEditing ? card.limit.toStringAsFixed(2).replaceAll('.', ',') : '');
  final closingCtrl =
      TextEditingController(text: card?.invoiceClosingDay?.toString() ?? '');
  final dueCtrl = TextEditingController(text: card?.invoiceDueDay?.toString() ?? '');
  int color = card?.colorValue ?? cardColors.first.toARGB32();

  return _showSheet(
    context,
    StatefulBuilder(builder: (ctx, setSheet) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _title(ctx, isEditing ? 'Editar cartão' : 'Novo cartão'),
          // Pré-visualização
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 90,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(color), Color(color).withValues(alpha: 0.75)]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(children: [
              const Icon(Icons.credit_card, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(nameCtrl.text.isEmpty ? 'Nome do cartão' : nameCtrl.text,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16)),
                      Text(bankCtrl.text.isEmpty ? 'Banco' : bankCtrl.text,
                          style: const TextStyle(color: Colors.white70)),
                    ]),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Nome do cartão'),
            onChanged: (_) => setSheet(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: bankCtrl,
            decoration: const InputDecoration(labelText: 'Banco'),
            onChanged: (_) => setSheet(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: limitCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
                labelText: 'Limite total', prefixText: 'R\$ ', hintText: '0,00'),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                controller: closingCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Fecha dia', hintText: 'Ex: 5'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: dueCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Vence dia', hintText: 'Ex: 12'),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Text(
            'Compras a partir do dia do fechamento entram na fatura seguinte.',
            style: TextStyle(fontSize: 12, color: AppColors.subText(ctx)),
          ),
          const SizedBox(height: 16),
          const Text('Cor', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: cardColors.map((c) {
              final sel = c.toARGB32() == color;
              return GestureDetector(
                onTap: () => setSheet(() => color = c.toARGB32()),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: sel ? AppColors.subText(ctx) : Colors.transparent,
                        width: 3),
                  ),
                  child: sel
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final bank = bankCtrl.text.trim();
              final limit = Fmt.parseMoney(limitCtrl.text) ?? 0;
              final closing = int.tryParse(closingCtrl.text.trim());
              final due = int.tryParse(dueCtrl.text.trim());
              if (name.isEmpty || bank.isEmpty || limit <= 0) {
                _snack(ctx, 'Preencha nome, banco e limite');
                return;
              }
              if ((closing != null && (closing < 1 || closing > 31)) ||
                  (due != null && (due < 1 || due > 31))) {
                _snack(ctx, 'Os dias devem estar entre 1 e 31');
                return;
              }
              final provider = context.read<CardsProvider>();
              Navigator.pop(ctx);
              if (isEditing) {
                await provider.updateCard(card.copyWith(
                  cardName: name,
                  bankName: bank,
                  limit: limit,
                  colorValue: color,
                  invoiceClosingDay: closing,
                  invoiceDueDay: due,
                ));
              } else {
                await provider.addCard(CardModel(
                  uid: uid,
                  cardName: name,
                  bankName: bank,
                  limit: limit,
                  colorValue: color,
                  invoiceClosingDay: closing,
                  invoiceDueDay: due,
                ));
              }
            },
            child: Text(isEditing ? 'Salvar' : 'Adicionar cartão'),
          ),
        ],
      );
    }),
  );
}
