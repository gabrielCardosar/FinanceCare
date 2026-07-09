import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/cards_provider.dart';
import '../models/card_model.dart';
import '../utils/constants.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({Key? key}) : super(key: key);

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  static const List<Color> _cardColors = [
    Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFF3B82F6),
    Color(0xFF06B6D4), Color(0xFF10B981), Color(0xFFF59E0B),
    Color(0xFFEF4444), Color(0xFFEC4899), Color(0xFF64748B),
    Color(0xFF0F172A),
  ];

  void _showCardDialog({CardModel? card}) {
    final isEditing = card != null;
    final cardNameCtrl = TextEditingController(text: isEditing ? card.cardName : '');
    final bankNameCtrl = TextEditingController(text: isEditing ? card.bankName : '');
    final limitCtrl = TextEditingController(text: isEditing ? card.limit.toString() : '');
    final usedLimitCtrl = TextEditingController(text: isEditing ? card.usedLimit.toString() : '');
    final dueDayCtrl = TextEditingController(
        text: isEditing && card.invoiceDueDay != null ? card.invoiceDueDay.toString() : '');
    final closingDayCtrl = TextEditingController(
        text: isEditing && card.invoiceClosingDay != null ? card.invoiceClosingDay.toString() : '');
    int selectedColor = isEditing ? card.colorValue : _cardColors.first.value;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(isEditing ? 'Editar Cartão' : 'Adicionar Cartão'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: cardNameCtrl,
                    decoration: const InputDecoration(label: Text('Nome do cartão')),
                    onChanged: (_) => setDialog(() {})),
                const SizedBox(height: 10),
                TextField(controller: bankNameCtrl,
                    decoration: const InputDecoration(label: Text('Banco'))),
                const SizedBox(height: 10),
                TextField(controller: limitCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(label: Text('Limite'), prefixText: 'R\$ ')),
                const SizedBox(height: 10),
                TextField(controller: usedLimitCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(label: Text('Limite Utilizado'), prefixText: 'R\$ ')),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: closingDayCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        label: Text('Dia fechamento'),
                        hintText: 'Ex: 8',
                        prefixIcon: Icon(Icons.lock_clock, size: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: dueDayCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        label: Text('Dia vencimento'),
                        hintText: 'Ex: 15',
                        prefixIcon: Icon(Icons.calendar_today, size: 16),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                const Text('Cor do cartão',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _cardColors.map((c) {
                    final isSel = c.value == selectedColor;
                    return GestureDetector(
                      onTap: () => setDialog(() => selectedColor = c.value),
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: c, shape: BoxShape.circle,
                          border: isSel ? Border.all(color: Colors.white, width: 2) : null,
                          boxShadow: isSel ? [BoxShadow(color: c.withOpacity(0.6), blurRadius: 6)] : null,
                        ),
                        child: isSel ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Color(selectedColor), Color(selectedColor).withOpacity(0.7)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(children: [
                    const Icon(Icons.credit_card, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(cardNameCtrl.text.isEmpty ? 'Pré-visualização' : cardNameCtrl.text,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                final cardName = cardNameCtrl.text.trim();
                final bankName = bankNameCtrl.text.trim();
                final limit = double.tryParse(limitCtrl.text) ?? 0;
                final usedLimit = double.tryParse(usedLimitCtrl.text) ?? 0;
                final dueDay = int.tryParse(dueDayCtrl.text.trim())?.clamp(1, 31);
                final closingDay = int.tryParse(closingDayCtrl.text.trim())?.clamp(1, 31);
                if (cardName.isEmpty || bankName.isEmpty || limit == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Preencha todos os campos')));
                  return;
                }
                final uid = context.read<AuthProvider>().user?.uid;
                if (uid != null) {
                  if (isEditing) {
                    context.read<CardsProvider>().updateCard(card.copyWith(
                      cardName: cardName, bankName: bankName,
                      limit: limit, usedLimit: usedLimit,
                      colorValue: selectedColor,
                      invoiceDueDay: dueDay, invoiceClosingDay: closingDay,
                    ));
                  } else {
                    context.read<CardsProvider>().addCard(CardModel(
                      uid: uid, cardName: cardName, bankName: bankName,
                      limit: limit, usedLimit: usedLimit,
                      colorValue: selectedColor,
                      invoiceDueDay: dueDay, invoiceClosingDay: closingDay,
                    ));
                  }
                }
                Navigator.pop(context);
              },
              child: Text(isEditing ? 'Salvar' : 'Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

  // Adicionar parcelamento
  void _showInstallmentDialog(CardModel card) {
    final descCtrl = TextEditingController();
    final totalCtrl = TextEditingController();
    int parcelas = 2;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text('Parcelamento - ${card.cardName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(label: Text('Descrição da compra')),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: totalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(label: Text('Valor total'), prefixText: 'R\$ '),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Número de parcelas:', style: TextStyle(fontSize: 13)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: parcelas > 2 ? () => setDialog(() => parcelas--) : null,
                        ),
                        Text('$parcelas×', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: parcelas < 48 ? () => setDialog(() => parcelas++) : null,
                        ),
                      ],
                    ),
                  ],
                ),
                Builder(builder: (_) {
                  final total = double.tryParse(totalCtrl.text) ?? 0;
                  final perParcel = total > 0 ? total / parcelas : 0;
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Valor por parcela:'),
                        Text(
                          _currencyFormat.format(perParcel),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                final total = double.tryParse(totalCtrl.text) ?? 0;
                final desc = descCtrl.text.trim();
                if (total == 0 || desc.isEmpty) return;

                final perParcel = total / parcelas;
                final installment = CardInstallment(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  description: desc,
                  totalAmount: total,
                  installmentAmount: perParcel,
                  totalInstallments: parcelas,
                  remainingInstallments: parcelas,
                  purchaseDate: DateTime.now(),
                );

                // Adiciona o parcelamento e debita a primeira parcela do limite
                final updatedCard = card.copyWith(
                  usedLimit: card.usedLimit + perParcel,
                  installments: [...card.installments, installment],
                );
                context.read<CardsProvider>().updateCard(updatedCard);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Parcelamento adicionado: ${parcelas}x de ${_currencyFormat.format(perParcel)}'),
                  backgroundColor: AppColors.success,
                ));
              },
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPayInvoiceDialog(CardModel card) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pagar Fatura'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cartão: ${card.cardName}'),
            const SizedBox(height: 8),
            Text('Valor: ${_currencyFormat.format(card.usedLimit)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.success, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ao pagar, o limite será liberado e os parcelamentos avançarão.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () {
              // Avança os parcelamentos (remove os que acabaram)
              final updatedInstallments = card.installments
                  .map((i) => i.copyWith(remainingInstallments: i.remainingInstallments - 1))
                  .where((i) => i.remainingInstallments > 0)
                  .toList();

              // Calcula o novo usedLimit = soma das parcelas restantes no próximo mês
              final nextMonthUsed = updatedInstallments.fold<double>(
                  0, (s, i) => s + i.installmentAmount);

              context.read<CardsProvider>().updateCard(card.copyWith(
                usedLimit: nextMonthUsed,
                installments: updatedInstallments,
              ));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Fatura de ${card.cardName} paga! Limite liberado.'),
                backgroundColor: AppColors.success,
              ));
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(CardModel card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deletar cartão'),
        content: Text('Deseja deletar "${card.cardName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              final uid = context.read<AuthProvider>().user?.uid;
              if (uid != null) context.read<CardsProvider>().deleteCard(uid, card.id!);
              Navigator.pop(context);
            },
            child: const Text('Deletar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cards = context.watch<CardsProvider>().cards;

    return Scaffold(
      appBar: AppBar(title: const Text('Meus Cartões')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCardDialog(),
        child: const Icon(Icons.add),
      ),
      body: cards.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.credit_card, size: 64, color: AppColors.primary.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  const Text('Nenhum cartão adicionado'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                final pct = card.percentageUsed;
                final cardColor = card.color;
                final darker = HSLColor.fromColor(cardColor)
                    .withLightness((HSLColor.fromColor(cardColor).lightness - 0.15).clamp(0.0, 1.0))
                    .toColor();

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [cardColor, darker], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: cardColor.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabeçalho
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(card.cardName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(card.bankName, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ]),
                          Row(children: [
                            IconButton(icon: const Icon(Icons.edit, color: Colors.white70, size: 18), onPressed: () => _showCardDialog(card: card)),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.white70, size: 18), onPressed: () => _confirmDelete(card)),
                          ]),
                        ],
                      ),

                      // Fechamento e vencimento
                      if (card.invoiceClosingDay != null || card.invoiceDueDay != null) ...[
                        const SizedBox(height: 8),
                        Row(children: [
                          if (card.invoiceClosingDay != null)
                            _DateChip(
                              label: 'Fecha dia ${card.invoiceClosingDay}',
                              icon: Icons.lock_clock,
                              urgent: card.daysUntilClosing != null && card.daysUntilClosing! <= 3,
                            ),
                          if (card.invoiceClosingDay != null && card.invoiceDueDay != null)
                            const SizedBox(width: 6),
                          if (card.invoiceDueDay != null)
                            _DateChip(
                              label: card.daysUntilInvoice == 0
                                  ? 'Vence HOJE'
                                  : card.daysUntilInvoice != null && card.daysUntilInvoice! < 0
                                      ? 'Venceu!'
                                      : 'Vence dia ${card.invoiceDueDay}',
                              icon: Icons.calendar_today,
                              urgent: card.daysUntilInvoice != null && card.daysUntilInvoice! <= 5,
                            ),
                        ]),
                      ],

                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _CardInfo(label: 'Limite', value: _currencyFormat.format(card.limit)),
                          _CardInfo(label: 'Fatura', value: _currencyFormat.format(card.usedLimit), align: CrossAxisAlignment.center),
                          _CardInfo(label: 'Disponível', value: _currencyFormat.format(card.availableLimit), align: CrossAxisAlignment.end),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Uso do limite', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text('${pct.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (pct / 100).clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: Colors.white30,
                          valueColor: AlwaysStoppedAnimation(pct > 80 ? AppColors.danger : Colors.white),
                        ),
                      ),

                      // Parcelamentos ativos
                      if (card.installments.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Parcelamentos ativos:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                              const SizedBox(height: 6),
                              ...card.installments.map((inst) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  Expanded(child: Text(inst.description,
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                      overflow: TextOverflow.ellipsis)),
                                  Text(
                                    '${inst.remainingInstallments}x ${_currencyFormat.format(inst.installmentAmount)}',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ]),
                              )),
                            ],
                          ),
                        ),
                      ],

                      // Botões
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
                            icon: const Icon(Icons.credit_score, size: 15),
                            label: const Text('Parcela', style: TextStyle(fontSize: 12)),
                            onPressed: () => _showInstallmentDialog(card),
                          ),
                        ),
                        if (card.usedLimit > 0) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.greenAccent, side: const BorderSide(color: Colors.greenAccent)),
                              icon: const Icon(Icons.payment, size: 15),
                              label: const Text('Pagar Fatura', style: TextStyle(fontSize: 12)),
                              onPressed: () => _showPayInvoiceDialog(card),
                            ),
                          ),
                        ],
                      ]),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool urgent;
  const _DateChip({required this.label, required this.icon, this.urgent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: urgent ? Colors.red.withOpacity(0.35) : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 12),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
      ]),
    );
  }
}

class _CardInfo extends StatelessWidget {
  final String label;
  final String value;
  final CrossAxisAlignment align;
  const _CardInfo({required this.label, required this.value, this.align = CrossAxisAlignment.start});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: align, children: [
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
    ]);
  }
}