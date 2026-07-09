import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/bills_payable_provider.dart';
import '../models/bill_payable_model.dart';
import '../utils/constants.dart';

class BillsPayableScreen extends StatefulWidget {
  const BillsPayableScreen({Key? key}) : super(key: key);

  @override
  State<BillsPayableScreen> createState() => _BillsPayableScreenState();
}

class _BillsPayableScreenState extends State<BillsPayableScreen>
    with SingleTickerProviderStateMixin {
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _dateFormat = DateFormat('dd/MM/yyyy');
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showBillDialog({BillPayableModel? bill}) {
    final isEditing = bill != null;
    final nameCtrl = TextEditingController(text: isEditing ? bill.name : '');
    final amountCtrl = TextEditingController(text: isEditing ? bill.amount.toString() : '');
    DateTime selectedDate = isEditing ? bill.dueDate : DateTime.now().add(const Duration(days: 7));
    UrgencyLevel selectedUrgency = isEditing ? bill.urgency : UrgencyLevel.leve;
    bool isFixed = isEditing ? bill.isFixed : false;

    // Validade: mês e ano em que a conta expira
    DateTime? expiresAt = isEditing ? bill.expiresAt : null;
    int? remainingMonths = isEditing ? bill.remainingMonths : null;
    bool hasExpiry = expiresAt != null || remainingMonths != null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(isEditing ? 'Editar Conta' : 'Nova Conta a Pagar'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(label: Text('Nome da conta')),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(label: Text('Valor'), prefixText: 'R\$ '),
                ),
                const SizedBox(height: 14),
                const Text('Vencimento', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                    );
                    if (picked != null) setDialog(() => selectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 8),
                      Text(_dateFormat.format(selectedDate)),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),

                // ── VALIDADE DA CONTA ──────────────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hasExpiry ? AppColors.warning.withOpacity(0.08) : Colors.grey.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: hasExpiry ? AppColors.warning.withOpacity(0.4) : Colors.grey.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.timer_outlined, color: hasExpiry ? AppColors.warning : Colors.grey, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Validade da conta', style: TextStyle(fontWeight: FontWeight.w600, color: hasExpiry ? AppColors.warning : null)),
                            const Text('A conta some automaticamente quando expirar', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ]),
                        ),
                        Switch(value: hasExpiry, activeColor: AppColors.warning, onChanged: (v) {
                          setDialog(() {
                            hasExpiry = v;
                            if (!v) { expiresAt = null; remainingMonths = null; }
                            else remainingMonths = 3;
                          });
                        }),
                      ]),
                      if (hasExpiry) ...[
                        const SizedBox(height: 12),
                        const Text('Número de parcelas restantes:', style: TextStyle(fontSize: 13)),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: (remainingMonths ?? 1) > 1 ? () => setDialog(() => remainingMonths = (remainingMonths ?? 1) - 1) : null,
                            ),
                            Container(
                              width: 60, height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.warning.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('${remainingMonths ?? 1}x', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => setDialog(() => remainingMonths = (remainingMonths ?? 1) + 1),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Row(children: [
                            const Icon(Icons.info_outline, size: 14, color: AppColors.warning),
                            const SizedBox(width: 6),
                            Expanded(child: Text(
                              'A conta aparecerá por ${remainingMonths ?? 1} mês(es) e depois sumirá automaticamente.',
                              style: const TextStyle(fontSize: 11, color: AppColors.warning),
                            )),
                          ]),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── CONTA FIXA ─────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isFixed ? AppColors.primary.withOpacity(0.1) : Colors.grey.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isFixed ? AppColors.primary.withOpacity(0.4) : Colors.grey.withOpacity(0.2)),
                  ),
                  child: Row(children: [
                    Icon(Icons.push_pin, color: isFixed ? AppColors.primary : Colors.grey, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Conta Fixa', style: TextStyle(fontWeight: FontWeight.w600, color: isFixed ? AppColors.primary : null)),
                      const Text('Não some no reset mensal', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ])),
                    Switch(value: isFixed, activeColor: AppColors.primary, onChanged: (v) => setDialog(() => isFixed = v)),
                  ]),
                ),
                const SizedBox(height: 14),

                // ── URGÊNCIA ───────────────────────────────────────
                const Text('Nível de Urgência', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: UrgencyLevel.values.map((level) {
                    final isSel = level == selectedUrgency;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: GestureDetector(
                          onTap: () => setDialog(() => selectedUrgency = level),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSel ? level.color : level.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: isSel ? Border.all(color: level.color, width: 2) : null,
                            ),
                            child: Column(children: [
                              Icon(level.icon, color: isSel ? Colors.white : level.color, size: 20),
                              const SizedBox(height: 4),
                              Text(level.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSel ? Colors.white : level.color)),
                            ]),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final amount = double.tryParse(amountCtrl.text) ?? 0;
                if (name.isEmpty || amount == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha nome e valor')));
                  return;
                }

                // Calcula data de expiração se houver parcelas
                DateTime? expiry;
                if (hasExpiry && remainingMonths != null) {
                  final now = DateTime.now();
                  expiry = DateTime(now.year, now.month + remainingMonths!, now.day);
                }

                final uid = context.read<AuthProvider>().user?.uid ?? '';
                if (isEditing) {
                  context.read<BillsPayableProvider>().updateBill(bill.copyWith(
                    name: name, amount: amount, dueDate: selectedDate,
                    urgency: selectedUrgency, isFixed: isFixed,
                    expiresAt: hasExpiry ? expiry : null,
                    remainingMonths: hasExpiry ? remainingMonths : null,
                  ));
                } else {
                  context.read<BillsPayableProvider>().addBill(BillPayableModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    uid: uid, name: name, amount: amount, dueDate: selectedDate,
                    urgency: selectedUrgency, isFixed: isFixed,
                    expiresAt: expiry,
                    remainingMonths: hasExpiry ? remainingMonths : null,
                  ));
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

  void _togglePaid(BillPayableModel bill) {
    context.read<BillsPayableProvider>().togglePaid(bill);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(bill.isPaid ? '${bill.name} marcada como pendente' : '${bill.name} paga!'),
      backgroundColor: bill.isPaid ? AppColors.warning : AppColors.success,
      duration: const Duration(seconds: 2),
    ));
  }

  Widget _buildList(List<BillPayableModel> bills) {
    if (bills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 56, color: AppColors.danger.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text('Nenhuma conta aqui', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: bills.length,
      itemBuilder: (context, index) {
        final bill = bills[index];
        final isOverdue = bill.isOverdue;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final hasExpiry = bill.expiresAt != null || bill.remainingMonths != null;

        return Dismissible(
          key: Key(bill.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) async {
            return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Deletar conta'),
                content: Text('Deletar "${bill.name}"?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Não')),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Sim'),
                  ),
                ],
              ),
            );
          },
          onDismissed: (_) {
            final uid = context.read<AuthProvider>().user?.uid;
            if (uid != null) context.read<BillsPayableProvider>().deleteBill(uid, bill.id);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: bill.isPaid ? Colors.grey : bill.urgency.color, width: 4)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _togglePaid(bill),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: bill.isPaid ? AppColors.success.withOpacity(0.18) : bill.urgency.color.withOpacity(0.12),
                        border: Border.all(color: bill.isPaid ? AppColors.success : bill.urgency.color, width: 2),
                      ),
                      child: Icon(bill.isPaid ? Icons.check : bill.urgency.icon,
                          color: bill.isPaid ? AppColors.success : bill.urgency.color, size: 18),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          if (bill.isFixed) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.push_pin, size: 12, color: AppColors.primary)),
                          if (hasExpiry) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.timer, size: 12, color: AppColors.warning)),
                          Expanded(
                            child: Text(bill.name,
                                style: TextStyle(fontWeight: FontWeight.bold,
                                    decoration: bill.isPaid ? TextDecoration.lineThrough : null,
                                    color: bill.isPaid ? Colors.grey : null),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ]),
                        const SizedBox(height: 3),
                        Row(children: [
                          Icon(Icons.calendar_today, size: 10, color: isOverdue ? AppColors.danger : Colors.grey),
                          const SizedBox(width: 3),
                          Text(
                            isOverdue ? 'Venceu ${_dateFormat.format(bill.dueDate)}' : 'Vence ${_dateFormat.format(bill.dueDate)}',
                            style: TextStyle(fontSize: 10, color: isOverdue ? AppColors.danger : Colors.grey, fontWeight: isOverdue ? FontWeight.bold : null),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(color: bill.urgency.color.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                            child: Text(bill.urgency.label, style: TextStyle(fontSize: 9, color: bill.urgency.color, fontWeight: FontWeight.w600)),
                          ),
                        ]),
                        // Mostra validade
                        if (hasExpiry && bill.remainingMonths != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Expira em ${bill.remainingMonths}x mês(es)',
                              style: const TextStyle(fontSize: 10, color: AppColors.warning),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_currencyFormat.format(bill.amount),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
                              color: bill.isPaid ? Colors.grey : AppColors.danger,
                              decoration: bill.isPaid ? TextDecoration.lineThrough : null)),
                      GestureDetector(
                        onTap: () => _showBillDialog(bill: bill),
                        child: const Padding(padding: EdgeInsets.only(top: 4), child: Icon(Icons.edit, size: 14, color: Colors.grey)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final billsProvider = context.watch<BillsPayableProvider>();
    final allBills = billsProvider.bills;
    final pendingBills = allBills.where((b) => !b.isPaid).toList();
    final paidBills = allBills.where((b) => b.isPaid).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contas a Pagar'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Todas (${allBills.length})'),
            Tab(text: 'Pendentes (${pendingBills.length})'),
            Tab(text: 'Pagas (${paidBills.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _showBillDialog(), child: const Icon(Icons.add)),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.danger, AppColors.danger.withOpacity(0.75)]),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _BannerStat(label: 'Pendente', value: _currencyFormat.format(billsProvider.totalPending), color: Colors.white),
                  Container(width: 1, height: 30, color: Colors.white30),
                  _BannerStat(label: 'Pago', value: _currencyFormat.format(billsProvider.totalPaid), color: Colors.greenAccent),
                  Container(width: 1, height: 30, color: Colors.white30),
                  _BannerStat(label: 'Fixas', value: '${billsProvider.fixedBills.length}', color: Colors.lightBlueAccent),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildList(allBills), _buildList(pendingBills), _buildList(paidBills)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _BannerStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
    ]);
  }
}