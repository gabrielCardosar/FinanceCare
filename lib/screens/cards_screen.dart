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
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFF3B82F6),
    Color(0xFF06B6D4),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFFEC4899),
    Color(0xFF64748B),
    Color(0xFF0F172A),
  ];

  void _showCardDialog({CardModel? card}) {
    final isEditing = card != null;
    final cardNameCtrl =
        TextEditingController(text: isEditing ? card.cardName : '');
    final bankNameCtrl =
        TextEditingController(text: isEditing ? card.bankName : '');
    final limitCtrl =
        TextEditingController(text: isEditing ? card.limit.toString() : '');
    final usedLimitCtrl = TextEditingController(
        text: isEditing ? card.usedLimit.toString() : '');
    final invoiceDayCtrl = TextEditingController(
        text: isEditing && card.invoiceDueDay != null
            ? card.invoiceDueDay.toString()
            : '');
    int selectedColor =
        isEditing ? card.colorValue : _cardColors.first.value;

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
                TextField(
                  controller: cardNameCtrl,
                  decoration:
                      const InputDecoration(label: Text('Nome do cartão')),
                  onChanged: (_) => setDialog(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bankNameCtrl,
                  decoration:
                      const InputDecoration(label: Text('Nome do banco')),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: limitCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      label: Text('Limite'), prefixText: 'R\$ '),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: usedLimitCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      label: Text('Limite Utilizado'), prefixText: 'R\$ '),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: invoiceDayCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    label: Text('Dia de vencimento da fatura'),
                    hintText: 'Ex: 15',
                    prefixIcon: Icon(Icons.calendar_today, size: 18),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Cor do cartão',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _cardColors.map((c) {
                    final isSelected = c.value == selectedColor;
                    return GestureDetector(
                      onTap: () =>
                          setDialog(() => selectedColor = c.value),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                      color: c.withOpacity(0.6),
                                      blurRadius: 6)
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 16)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                // Preview do cartão
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Color(selectedColor),
                      Color(selectedColor).withOpacity(0.7),
                    ]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.credit_card,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        cardNameCtrl.text.isEmpty
                            ? 'Nome do cartão'
                            : cardNameCtrl.text,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                final cardName = cardNameCtrl.text.trim();
                final bankName = bankNameCtrl.text.trim();
                final limit = double.tryParse(limitCtrl.text) ?? 0;
                final usedLimit =
                    double.tryParse(usedLimitCtrl.text) ?? 0;
                final invoiceDayRaw =
                    int.tryParse(invoiceDayCtrl.text.trim());
                final invoiceDay = invoiceDayRaw != null
                    ? invoiceDayRaw.clamp(1, 31)
                    : null;

                if (cardName.isEmpty || bankName.isEmpty || limit == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Preencha todos os campos')));
                  return;
                }
                final uid = context.read<AuthProvider>().user?.uid;
                if (uid != null) {
                  if (isEditing) {
                    context.read<CardsProvider>().updateCard(CardModel(
                          id: card.id,
                          uid: card.uid,
                          cardName: cardName,
                          bankName: bankName,
                          limit: limit,
                          usedLimit: usedLimit,
                          createdAt: card.createdAt,
                          colorValue: selectedColor,
                          invoiceDueDay: invoiceDay,
                        ));
                  } else {
                    context.read<CardsProvider>().addCard(CardModel(
                          uid: uid,
                          cardName: cardName,
                          bankName: bankName,
                          limit: limit,
                          usedLimit: usedLimit,
                          colorValue: selectedColor,
                          invoiceDueDay: invoiceDay,
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

  // ✅ FIX: pagar fatura APENAS zera o usedLimit do cartão
  // NÃO mexe no salário — o saldo final é calculado automaticamente
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
            Text(
              'Valor da fatura: ${_currencyFormat.format(card.usedLimit)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: AppColors.success, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'O saldo disponível já descontou essa fatura. Ao pagar, o limite do cartão será liberado.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success),
            onPressed: () {
              // ✅ FIX: só zera o usedLimit — não toca no salário
              context.read<CardsProvider>().updateCard(CardModel(
                    id: card.id,
                    uid: card.uid,
                    cardName: card.cardName,
                    bankName: card.bankName,
                    limit: card.limit,
                    usedLimit: 0,
                    createdAt: card.createdAt,
                    colorValue: card.colorValue,
                    invoiceDueDay: card.invoiceDueDay,
                  ));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Fatura de ${card.cardName} paga! Limite liberado.'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Confirmar Pagamento'),
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
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger),
            onPressed: () {
              final uid = context.read<AuthProvider>().user?.uid;
              if (uid != null) {
                context.read<CardsProvider>().deleteCard(uid, card.id!);
              }
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
                  Icon(Icons.credit_card,
                      size: 64,
                      color: AppColors.primary.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  const Text('Nenhum cartão adicionado'),
                  const SizedBox(height: 8),
                  const Text('Toque no + para adicionar'),
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
                    .withLightness(
                        (HSLColor.fromColor(cardColor).lightness - 0.15)
                            .clamp(0.0, 1.0))
                    .toColor();
                final daysUntil = card.daysUntilInvoice;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cardColor, darker],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: cardColor.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(card.cardName,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(card.bankName,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 14)),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.white70, size: 20),
                                onPressed: () => _showCardDialog(card: card),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.white70, size: 20),
                                onPressed: () => _confirmDelete(card),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (card.invoiceDueDay != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: daysUntil != null && daysUntil <= 5
                                ? Colors.red.withOpacity(0.35)
                                : Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today,
                                  color: Colors.white, size: 13),
                              const SizedBox(width: 5),
                              Text(
                                daysUntil == null
                                    ? 'Fatura: dia ${card.invoiceDueDay}'
                                    : daysUntil == 0
                                        ? 'Fatura vence HOJE!'
                                        : daysUntil < 0
                                            ? 'Fatura atrasada'
                                            : 'Fatura em $daysUntil dias',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _CardInfo(
                              label: 'Limite',
                              value: _currencyFormat.format(card.limit)),
                          _CardInfo(
                              label: 'Utilizado',
                              value: _currencyFormat.format(card.usedLimit),
                              align: CrossAxisAlignment.center),
                          _CardInfo(
                              label: 'Disponível',
                              value:
                                  _currencyFormat.format(card.availableLimit),
                              align: CrossAxisAlignment.end),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Uso do limite',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          Text('${pct.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (pct / 100).clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: Colors.white30,
                          valueColor: AlwaysStoppedAnimation(
                              pct > 80 ? AppColors.danger : Colors.white),
                        ),
                      ),
                      // Botão pagar fatura
                      if (card.usedLimit > 0) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white54),
                            ),
                            icon: const Icon(Icons.payment, size: 16),
                            label: Text(
                              'Pagar Fatura • ${_currencyFormat.format(card.usedLimit)}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            onPressed: () => _showPayInvoiceDialog(card),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _CardInfo extends StatelessWidget {
  final String label;
  final String value;
  final CrossAxisAlignment align;
  const _CardInfo(
      {required this.label,
      required this.value,
      this.align = CrossAxisAlignment.start});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}