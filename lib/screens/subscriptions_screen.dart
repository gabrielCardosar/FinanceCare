import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/subscriptions_provider.dart';
import '../models/subscription_model.dart';
import '../utils/constants.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  static const List<Color> _subColors = [
    Color(0xFF8B5CF6),
    Color(0xFF6366F1),
    Color(0xFF3B82F6),
    Color(0xFF06B6D4),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFFEC4899),
    Color(0xFF64748B),
  ];

  void _showSubscriptionDialog({SubscriptionModel? subscription}) {
    final isEditing = subscription != null;
    final nameCtrl =
        TextEditingController(text: isEditing ? subscription.name : '');
    final valueCtrl = TextEditingController(
        text: isEditing ? subscription.monthlyValue.toString() : '');
    final descCtrl = TextEditingController(
        text: isEditing ? (subscription.description ?? '') : '');
    int selectedColor =
        isEditing ? subscription.colorValue : _subColors.first.value;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(isEditing ? 'Editar Assinatura' : 'Nova Assinatura'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      label: Text('Nome da assinatura')),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: valueCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      label: Text('Valor mensal'), prefixText: 'R\$ '),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                      label: Text('Descrição (opcional)')),
                ),
                const SizedBox(height: 16),
                const Text('Cor da assinatura',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _subColors.map((c) {
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
                // Nota: assinaturas são fixas por natureza
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: AppColors.primary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Assinaturas são fixas e não são deletadas no reset mensal.',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.primary),
                        ),
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
                final name = nameCtrl.text.trim();
                final value = double.tryParse(valueCtrl.text) ?? 0;
                if (name.isEmpty || value == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Preencha nome e valor')));
                  return;
                }
                final uid =
                    context.read<AuthProvider>().user?.uid;
                if (uid != null) {
                  if (isEditing) {
                    final updated = subscription.copyWith(
                      name: name,
                      monthlyValue: value,
                      description:
                          descCtrl.text.isEmpty ? null : descCtrl.text,
                      colorValue: selectedColor,
                    );
                    context
                        .read<SubscriptionsProvider>()
                        .updateSubscription(updated);
                  } else {
                    final newSub = SubscriptionModel(
                      uid: uid,
                      name: name,
                      monthlyValue: value,
                      description:
                          descCtrl.text.isEmpty ? null : descCtrl.text,
                      colorValue: selectedColor,
                    );
                    context
                        .read<SubscriptionsProvider>()
                        .addSubscription(newSub);
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

  void _confirmDelete(SubscriptionModel sub) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover assinatura'),
        content: Text('Deseja remover "${sub.name}"?'),
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
                context
                    .read<SubscriptionsProvider>()
                    .deleteSubscription(uid, sub.id!);
              }
              Navigator.pop(context);
            },
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subscriptions =
        context.watch<SubscriptionsProvider>().subscriptions;
    final total = subscriptions.fold<double>(
        0, (sum, s) => sum + s.monthlyValue);

    return Scaffold(
      appBar: AppBar(title: const Text('Assinaturas')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSubscriptionDialog(),
        child: const Icon(Icons.add),
      ),
      body: subscriptions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.subscriptions,
                      size: 64,
                      color: AppColors.secondary.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  const Text('Nenhuma assinatura cadastrada'),
                  const SizedBox(height: 8),
                  const Text('Toque em + para adicionar'),
                ],
              ),
            )
          : Column(
              children: [
                // Banner total
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary]),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total mensal',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                          Text(_currencyFormat.format(total),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.push_pin,
                                color: Colors.white70, size: 14),
                            const SizedBox(width: 4),
                            Text('${subscriptions.length} fixas',
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: subscriptions.length,
                    itemBuilder: (context, index) {
                      final sub = subscriptions[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCardBg
                              : AppColors.lightCardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border(
                              left: BorderSide(
                                  color: sub.color, width: 4)),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2)),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: sub.color.withOpacity(0.15),
                            child: Icon(Icons.subscriptions,
                                color: sub.color, size: 20),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(sub.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('Fixa',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                          subtitle: sub.description != null &&
                                  sub.description!.isNotEmpty
                              ? Text(sub.description!)
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _currencyFormat
                                        .format(sub.monthlyValue),
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: sub.color,
                                        fontSize: 14),
                                  ),
                                  const Text('/mês',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey)),
                                ],
                              ),
                              PopupMenuButton(
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    onTap: () =>
                                        _showSubscriptionDialog(
                                            subscription: sub),
                                    child: const ListTile(
                                      leading: Icon(Icons.edit),
                                      title: Text('Editar'),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  PopupMenuItem(
                                    onTap: () => _confirmDelete(sub),
                                    child: const ListTile(
                                      leading: Icon(Icons.delete,
                                          color: AppColors.danger),
                                      title: Text('Remover',
                                          style: TextStyle(
                                              color: AppColors.danger)),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
