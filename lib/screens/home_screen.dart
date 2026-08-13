import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../providers/cards_provider.dart';
import '../providers/subscriptions_provider.dart';
import '../providers/bills_payable_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/monthly_report_provider.dart';
import '../providers/purchases_provider.dart';
import '../providers/extra_income_provider.dart';
import '../widgets/account_card.dart';
import '../utils/constants.dart';
import 'cards_screen.dart';
import 'subscriptions_screen.dart';
import 'bills_payable_screen.dart';
import 'notes_screen.dart';
import 'charts_screen.dart';
import 'monthly_reports_screen.dart';
import 'calculator_screen.dart';
import 'purchases_screen.dart';
import 'extra_income_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid != null) {
      context.read<HomeProvider>().loadAccount(uid);
      context.read<CardsProvider>().loadCards(uid);
      context.read<SubscriptionsProvider>().loadSubscriptions(uid);
      context.read<BillsPayableProvider>().loadBills(uid);
      context.read<NotesProvider>().loadNotes(uid);
      context.read<MonthlyReportProvider>().loadReports(uid);
      context.read<PurchasesProvider>().loadPurchases(uid);
      context.read<ExtraIncomeProvider>().load(uid);
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkMonthReset(uid));
    }
  }

  Future<void> _checkMonthReset(String uid) async {
    if (!mounted) return;
    final account = context.read<HomeProvider>().account;
    final bills = context.read<BillsPayableProvider>().bills;
    final subscriptions = context.read<SubscriptionsProvider>().subscriptions;
    final cards = context.read<CardsProvider>().cards;
    await context.read<MonthlyReportProvider>().checkAndGenerateReport(
          uid: uid,
          salary: account?.salary ?? 0,
          bills: bills,
          subscriptions: subscriptions,
          cards: cards,
        );
  }

  void _showSalaryDialog() {
    final ctrl = TextEditingController();
    final account = context.read<HomeProvider>().account;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Salário'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            prefixText: 'R\$ ',
            hintText: account?.salary != null && account!.salary > 0
                ? account.salary.toStringAsFixed(2).replaceAll('.', ',')
                : '0,00',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final text = ctrl.text.replaceAll(',', '.');
              final salary = double.tryParse(text);
              if (salary != null && account != null) {
                context.read<HomeProvider>().updateAccount(account.copyWith(salary: salary));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _navigate(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final account = context.watch<HomeProvider>().account;
    final subscriptions = context.watch<SubscriptionsProvider>().subscriptions;
    final billsProvider = context.watch<BillsPayableProvider>();
    final cards = context.watch<CardsProvider>().cards;
    final extraIncome = context.watch<ExtraIncomeProvider>().total;
    final purchasesTotal = context.watch<PurchasesProvider>().total;
    final urgentCount = billsProvider.urgentBills.length;

    final salary = account?.salary ?? 0;
    final totalSubs = subscriptions.fold<double>(0, (s, sub) => s + sub.monthlyValue);

    // ✅ CARTÃO: só desconta do saldo quando a fatura for PAGA
    // Antes do pagamento, não entra no cálculo do saldo
    // (o campo paidInvoices seria controlado pelo cards_provider quando o usuário pagar)
    // Por ora, usedLimit não desconta — só desconta via totalCardPaid
    final totalCardPaid = context.watch<CardsProvider>().totalPaidInvoices;

    // ✅ Contas pagas descontam
    final totalBillsPaid = billsProvider.totalPaid;

    // ✅ Compras do mês descontam
    // ✅ SALDO = salário + renda_extra - assinaturas - contas_pagas - compras - faturas_pagas_cartão
    final finalBalance = salary + extraIncome
        - totalSubs
        - totalBillsPaid
        - purchasesTotal
        - totalCardPaid;

    return Scaffold(
      appBar: AppBar(title: const Text('Finance Care'), centerTitle: true, elevation: 0),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const CircleAvatar(radius: 28, backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white, size: 32)),
                  const SizedBox(height: 8),
                  Text(context.read<AuthProvider>().user?.email ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  const Text('Finance Care',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _DrawerItem(icon: Icons.home_outlined, label: 'Início',
                      onTap: () => Navigator.pop(context)),
                  _DrawerItem(icon: Icons.credit_card_outlined, label: 'Cartões',
                      onTap: () { Navigator.pop(context); _navigate(const CardsScreen()); }),
                  _DrawerItem(icon: Icons.subscriptions_outlined, label: 'Assinaturas',
                      onTap: () { Navigator.pop(context); _navigate(const SubscriptionsScreen()); }),
                  _DrawerItem(icon: Icons.receipt_long_outlined, label: 'Contas a Pagar',
                      badge: urgentCount > 0 ? urgentCount.toString() : null,
                      onTap: () { Navigator.pop(context); _navigate(const BillsPayableScreen()); }),
                  _DrawerItem(icon: Icons.shopping_bag_outlined, label: 'Compras',
                      onTap: () { Navigator.pop(context); _navigate(const PurchasesScreen()); }),
                  _DrawerItem(icon: Icons.add_circle_outline, label: 'Renda Extra',
                      onTap: () { Navigator.pop(context); _navigate(const ExtraIncomeScreen()); }),
                  _DrawerItem(icon: Icons.bar_chart_outlined, label: 'Gráficos',
                      onTap: () { Navigator.pop(context); _navigate(const ChartsScreen()); }),
                  _DrawerItem(icon: Icons.note_alt_outlined, label: 'Bloco de Notas',
                      onTap: () { Navigator.pop(context); _navigate(const NotesScreen()); }),
                  _DrawerItem(icon: Icons.calculate_outlined, label: 'Calculadora',
                      onTap: () { Navigator.pop(context); _navigate(const CalculatorScreen()); }),
                  _DrawerItem(icon: Icons.calendar_month_outlined, label: 'Relatórios',
                      onTap: () { Navigator.pop(context); _navigate(const MonthlyReportsScreen()); }),
                  const Divider(),
                  _DrawerItem(icon: Icons.logout, label: 'Sair', color: AppColors.danger,
                      onTap: () { Navigator.pop(context); context.read<AuthProvider>().signOut(); }),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Resumo Financeiro',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: _showSalaryDialog,
                child: AccountCard(
                  title: 'Salário',
                  value: _fmt.format(salary),
                  subtitle: 'Toque para editar',
                  valueColor: AppColors.success,
                  icon: Icons.edit,
                ),
              ),
              const SizedBox(height: 12),

              if (extraIncome > 0) ...[
                GestureDetector(
                  onTap: () => _navigate(const ExtraIncomeScreen()),
                  child: AccountCard(
                    title: 'Renda Extra',
                    value: _fmt.format(extraIncome),
                    subtitle: 'Toque para gerenciar',
                    valueColor: AppColors.success,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Faturas dos Cartões (informativo — só desconta quando pago)
              if (cards.any((c) => c.usedLimit > 0)) ...[
                AccountCard(
                  title: 'Faturas dos Cartões',
                  value: _fmt.format(cards.fold<double>(0, (s, c) => s + c.usedLimit)),
                  subtitle: 'Será descontado ao pagar a fatura',
                  valueColor: AppColors.secondary,
                ),
                const SizedBox(height: 12),
              ],

              AccountCard(
                title: 'Contas a Pagar',
                value: _fmt.format(billsProvider.totalPending),
                subtitle: '${billsProvider.pendingBills.length} pendentes'
                    '${totalBillsPaid > 0 ? ' • ${_fmt.format(totalBillsPaid)} pagos' : ''}',
                valueColor: AppColors.danger,
              ),
              const SizedBox(height: 12),

              if (purchasesTotal > 0) ...[
                GestureDetector(
                  onTap: () => _navigate(const PurchasesScreen()),
                  child: AccountCard(
                    title: 'Compras do Mês',
                    value: _fmt.format(purchasesTotal),
                    subtitle: '${context.watch<PurchasesProvider>().purchases.length} compras • toque para ver',
                    valueColor: const Color(0xFFD97706),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              AccountCard(
                title: 'Assinaturas',
                value: _fmt.format(totalSubs),
                subtitle: '${subscriptions.length} ativas',
                valueColor: AppColors.warning,
              ),
              const SizedBox(height: 12),

              AccountCard(
                title: 'Saldo Final',
                value: _fmt.format(finalBalance),
                subtitle: finalBalance < 0 ? 'Você está no vermelho!' : 'Saldo disponível',
                valueColor: finalBalance < 0 ? AppColors.danger : AppColors.success,
              ),
              const SizedBox(height: 28),

              Text('Acesso Rápido',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.95,
                children: [
                  _QuickCard(icon: Icons.credit_card, label: 'Cartões', color: AppColors.primary, onTap: () => _navigate(const CardsScreen())),
                  _QuickCard(icon: Icons.subscriptions, label: 'Assinaturas', color: AppColors.secondary, onTap: () => _navigate(const SubscriptionsScreen())),
                  _QuickCard(icon: Icons.receipt_long, label: 'Contas', color: AppColors.danger,
                      badge: urgentCount > 0 ? urgentCount.toString() : null,
                      onTap: () => _navigate(const BillsPayableScreen())),
                  _QuickCard(icon: Icons.shopping_bag, label: 'Compras', color: const Color(0xFFD97706), onTap: () => _navigate(const PurchasesScreen())),
                  _QuickCard(icon: Icons.add_circle, label: 'Renda Extra', color: AppColors.success, onTap: () => _navigate(const ExtraIncomeScreen())),
                  _QuickCard(icon: Icons.bar_chart, label: 'Gráficos', color: const Color(0xFF0891B2), onTap: () => _navigate(const ChartsScreen())),
                  _QuickCard(icon: Icons.note_alt, label: 'Notas', color: AppColors.warning, onTap: () => _navigate(const NotesScreen())),
                  _QuickCard(icon: Icons.calculate, label: 'Calculadora', color: const Color(0xFF7C3AED), onTap: () => _navigate(const CalculatorScreen())),
                  _QuickCard(icon: Icons.calendar_month, label: 'Relatórios', color: Colors.blueGrey, onTap: () => _navigate(const MonthlyReportsScreen())),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;
  final Color? color;
  const _DrawerItem({required this.icon, required this.label, required this.onTap, this.badge, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return ListTile(
      leading: Stack(clipBehavior: Clip.none, children: [
        Icon(icon, color: c),
        if (badge != null)
          Positioned(top: -4, right: -6,
              child: Container(padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                  child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 9)))),
      ]),
      title: Text(label, style: TextStyle(color: c)),
      onTap: onTap,
    );
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? badge;
  const _QuickCard({required this.icon, required this.label, required this.color, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Stack(children: [
          Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 26)),
            const SizedBox(height: 6),
            Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
          ])),
          if (badge != null)
            Positioned(top: 6, right: 6,
                child: Container(padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                    child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 10)))),
        ]),
      ),
    );
  }
}