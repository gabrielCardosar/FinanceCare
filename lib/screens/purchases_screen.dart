import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/purchases_provider.dart';
import '../providers/cards_provider.dart';
import '../models/purchase_model.dart';
import '../utils/constants.dart';

class PurchasesScreen extends StatelessWidget {
  const PurchasesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final purchases = context.watch<PurchasesProvider>().purchases;
    final provider = context.watch<PurchasesProvider>();
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFmt = DateFormat('dd/MM HH:mm');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = context.read<AuthProvider>().user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Compras')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDialog(context, uid),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Banner totais
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            color: AppColors.primary.withOpacity(0.08),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Stat(
                    label: 'PIX',
                    value: fmt.format(provider.totalPix),
                    color: AppColors.primary),
                _Stat(
                    label: 'Dinheiro',
                    value: fmt.format(provider.totalDinheiro),
                    color: AppColors.success),
                _Stat(
                    label: 'Cartão',
                    value: fmt.format(provider.totalCartao),
                    color: AppColors.secondary),
                _Stat(
                    label: 'Total',
                    value: fmt.format(provider.total),
                    color: AppColors.danger),
              ],
            ),
          ),
          Expanded(
            child: purchases.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart,
                            size: 64,
                            color: AppColors.primary.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        const Text('Nenhuma compra registrada',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: purchases.length,
                    itemBuilder: (context, index) {
                      final p = purchases[index];
                      final methodColor = p.method == PaymentMethod.pix
                          ? AppColors.primary
                          : p.method == PaymentMethod.dinheiro
                              ? AppColors.success
                              : AppColors.secondary;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCardBg
                              : AppColors.lightCardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border(
                              left: BorderSide(
                                  color: methodColor, width: 4)),
                          boxShadow: [
                            BoxShadow(
                                color:
                                    Colors.black.withOpacity(0.04),
                                blurRadius: 4)
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: methodColor.withOpacity(0.12),
                                  shape: BoxShape.circle),
                              child: Icon(
                                p.method == PaymentMethod.pix
                                    ? Icons.qr_code
                                    : p.method == PaymentMethod.dinheiro
                                        ? Icons.money
                                        : Icons.credit_card,
                                color: methodColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(p.description,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text(
                                    p.method == PaymentMethod.cartao &&
                                            p.cardName != null
                                        ? '${p.method.label} • ${p.cardName}'
                                        : p.method.label,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: methodColor),
                                  ),
                                  Text(dateFmt.format(p.date),
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(fmt.format(p.amount),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.danger)),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Editar
                                    GestureDetector(
                                      onTap: () =>
                                          _showDialog(context, uid,
                                              purchase: p),
                                      child: const Icon(Icons.edit,
                                          size: 16,
                                          color: Colors.grey),
                                    ),
                                    const SizedBox(width: 10),
                                    // ✅ Deletar
                                    GestureDetector(
                                      onTap: () =>
                                          _confirmDelete(context, uid, p),
                                      child: const Icon(Icons.delete,
                                          size: 16,
                                          color: AppColors.danger),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, String uid, PurchaseModel p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Compra'),
        content: Text('Excluir "${p.description}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger),
            onPressed: () {
              context
                  .read<PurchasesProvider>()
                  .deletePurchase(uid, p.id);
              Navigator.pop(ctx);
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _showDialog(BuildContext context, String uid,
      {PurchaseModel? purchase}) {
    final isEditing = purchase != null;
    final descCtrl = TextEditingController(
        text: isEditing ? purchase.description : '');
    // ✅ FIX: campo começa vazio
    final valueCtrl = TextEditingController();
    PaymentMethod method =
        isEditing ? purchase.method : PaymentMethod.pix;
    String? selectedCardId =
        isEditing ? purchase.cardId : null;
    final cards = context.read<CardsProvider>().cards;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(
              isEditing ? 'Editar Compra' : 'Registrar Compra'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                      label: Text('Descrição')),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: valueCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: InputDecoration(
                    label: const Text('Valor'),
                    prefixText: 'R\$ ',
                    hintText: isEditing
                        ? purchase.amount
                            .toStringAsFixed(2)
                            .replaceAll('.', ',')
                        : '0,00',
                  ),
                  onTap: () => valueCtrl.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: valueCtrl.text.length),
                ),
                const SizedBox(height: 16),
                const Text('Forma de pagamento',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: PaymentMethod.values.map((m) {
                    final isSel = m == method;
                    final color = m == PaymentMethod.pix
                        ? AppColors.primary
                        : m == PaymentMethod.dinheiro
                            ? AppColors.success
                            : AppColors.secondary;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 3),
                        child: GestureDetector(
                          onTap: () => setDialog(() {
                            method = m;
                            if (m != PaymentMethod.cartao)
                              selectedCardId = null;
                          }),
                          child: AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? color.withOpacity(0.15)
                                  : Colors.grey.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: isSel
                                      ? color
                                      : Colors.grey.withOpacity(0.2),
                                  width: isSel ? 1.5 : 1),
                            ),
                            child: Column(children: [
                              Icon(
                                  m == PaymentMethod.pix
                                      ? Icons.qr_code
                                      : m == PaymentMethod.dinheiro
                                          ? Icons.money
                                          : Icons.credit_card,
                                  color:
                                      isSel ? color : Colors.grey,
                                  size: 20),
                              const SizedBox(height: 4),
                              Text(m.label,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isSel
                                          ? color
                                          : Colors.grey)),
                            ]),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (method == PaymentMethod.cartao &&
                    cards.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                        label: Text('Qual cartão?')),
                    value: selectedCardId,
                    items: cards
                        .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.cardName)))
                        .toList(),
                    onChanged: (v) =>
                        setDialog(() => selectedCardId = v),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                final desc = descCtrl.text.trim();
                final valueText =
                    valueCtrl.text.replaceAll(',', '.');
                final value = valueText.isEmpty
                    ? (isEditing ? purchase.amount : 0.0)
                    : (double.tryParse(valueText) ?? 0);
                if (desc.isEmpty || value <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Preencha descrição e valor')));
                  return;
                }
                final selectedCard = selectedCardId != null &&
                        cards.isNotEmpty
                    ? cards.firstWhere(
                        (c) => c.id == selectedCardId,
                        orElse: () => cards.first)
                    : null;

                if (isEditing) {
                  context.read<PurchasesProvider>().updatePurchase(
                      purchase.copyWith(
                          description: desc,
                          amount: value,
                          method: method,
                          cardId: selectedCardId,
                          cardName: selectedCard?.cardName));
                } else {
                  final newP = PurchaseModel(
                    id: DateTime.now()
                        .millisecondsSinceEpoch
                        .toString(),
                    uid: uid,
                    description: desc,
                    amount: value,
                    method: method,
                    cardId: selectedCardId,
                    cardName: selectedCard?.cardName,
                  );
                  context
                      .read<PurchasesProvider>()
                      .addPurchase(newP);
                  // Debita do limite do cartão se for no cartão
                  if (method == PaymentMethod.cartao &&
                      selectedCard != null) {
                    context.read<CardsProvider>().updateCard(
                        selectedCard.copyWith(
                            usedLimit:
                                selectedCard.usedLimit + value));
                  }
                }
                Navigator.pop(context);
              },
              child: Text(isEditing ? 'Salvar' : 'Registrar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat(
      {required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label,
          style: const TextStyle(fontSize: 11, color: Colors.grey)),
      Text(value,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: color)),
    ]);
  }
}