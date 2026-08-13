import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../providers/extra_income_provider.dart';
import '../models/extra_income_model.dart';
import '../utils/constants.dart';

class ExtraIncomeScreen extends StatelessWidget {
  const ExtraIncomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final items = context.watch<ExtraIncomeProvider>().items;
    final total = context.watch<ExtraIncomeProvider>().total;
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFmt = DateFormat('dd/MM/yyyy');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = context.read<AuthProvider>().user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Renda Extra')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDialog(context, uid),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Banner total
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.success, AppColors.success.withOpacity(0.75)],
              ),
            ),
            child: Column(children: [
              const Text('Total recebido este mês',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 6),
              Text(fmt.format(total),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
            ]),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add_circle, size: 64, color: AppColors.success.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      const Text('Nenhuma renda extra registrada',
                          style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      const Text('Toque no + para adicionar',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ]),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border(left: BorderSide(color: AppColors.success, width: 4)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.12),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.attach_money,
                                  color: AppColors.success, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(item.description,
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(dateFmt.format(item.date),
                                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ]),
                            ),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text(fmt.format(item.amount),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success,
                                      fontSize: 15)),
                              const SizedBox(height: 6),
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                // Editar
                                GestureDetector(
                                  onTap: () => _showDialog(context, uid, item: item),
                                  child: const Icon(Icons.edit, size: 16, color: Colors.grey),
                                ),
                                const SizedBox(width: 10),
                                // Excluir com opção
                                GestureDetector(
                                  onTap: () => _showDeleteDialog(context, uid, item),
                                  child: const Icon(Icons.delete,
                                      size: 16, color: AppColors.danger),
                                ),
                              ]),
                            ]),
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

  // ✅ Dialog de exclusão com duas opções
  void _showDeleteDialog(BuildContext context, String uid, ExtraIncomeModel item) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover Renda Extra'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.description,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(fmt.format(item.amount),
                style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Como deseja remover este valor?',
                style: TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            // Opção 1: Desfazer — remove do saldo (dinheiro foi devolvido/gasto)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.danger.withOpacity(0.25)),
              ),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.undo, color: AppColors.danger, size: 18),
                  SizedBox(width: 8),
                  Text('Desfazer entrada',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger)),
                ]),
                SizedBox(height: 4),
                Text(
                  'O dinheiro foi devolvido ou não entrou de verdade.\nO valor será removido do seu saldo.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ]),
            ),
            const SizedBox(height: 10),
            // Opção 2: Só apagar do histórico — dinheiro já foi gasto, não precisa descontar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.withOpacity(0.25)),
              ),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.history, color: Colors.grey, size: 18),
                  SizedBox(width: 8),
                  Text('Só apagar do histórico',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ]),
                SizedBox(height: 4),
                Text(
                  'O dinheiro já foi usado e está no saldo.\nSó remove o registro, sem alterar o saldo.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          // Só apagar
          OutlinedButton(
            onPressed: () {
              context.read<ExtraIncomeProvider>().delete(uid, item.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Registro removido do histórico'),
              ));
            },
            child: const Text('Só apagar'),
          ),
          // Desfazer entrada (remove do saldo também)
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              // Remove do histórico
              context.read<ExtraIncomeProvider>().delete(uid, item.id);
              // Desconta do saldo (salário) pois o dinheiro foi devolvido
              final account = context.read<HomeProvider>().account;
              if (account != null) {
                context.read<HomeProvider>().updateAccount(
                    account.copyWith(salary: account.salary - item.amount));
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${fmt.format(item.amount)} removido do saldo'),
                backgroundColor: AppColors.danger,
              ));
            },
            child: const Text('Desfazer entrada'),
          ),
        ],
      ),
    );
  }

  void _showDialog(BuildContext context, String uid, {ExtraIncomeModel? item}) {
    final isEditing = item != null;
    final descCtrl = TextEditingController(text: isEditing ? item.description : '');
    final valueCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Editar Renda Extra' : 'Adicionar Renda Extra'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                  label: Text('Descrição'),
                  hintText: 'Ex: Freela, bônus, presente...'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valueCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: !isEditing,
              decoration: InputDecoration(
                label: const Text('Valor'),
                prefixText: 'R\$ ',
                hintText: isEditing
                    ? item.amount.toStringAsFixed(2).replaceAll('.', ',')
                    : '0,00',
              ),
              onTap: () => valueCtrl.selection =
                  TextSelection(baseOffset: 0, extentOffset: valueCtrl.text.length),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () {
              final desc = descCtrl.text.trim();
              final valueText = valueCtrl.text.replaceAll(',', '.');
              final value = valueText.isEmpty
                  ? (isEditing ? item.amount : 0.0)
                  : (double.tryParse(valueText) ?? 0);
              if (desc.isEmpty || value <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preencha descrição e valor')));
                return;
              }
              if (isEditing) {
                context.read<ExtraIncomeProvider>().update(
                    item.copyWith(description: desc, amount: value));
              } else {
                context.read<ExtraIncomeProvider>().add(ExtraIncomeModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  uid: uid,
                  description: desc,
                  amount: value,
                ));
              }
              Navigator.pop(ctx);
            },
            child: Text(isEditing ? 'Salvar' : 'Adicionar'),
          ),
        ],
      ),
    );
  }
}