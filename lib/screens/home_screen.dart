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
import '../utils/constants.dart';
import '../widgets/account_card.dart';
import 'cards_screen.dart';
import 'subscriptions_screen.dart';
import 'bills_payable_screen.dart';
import 'notes_screen.dart';
import 'charts_screen.dart';
import 'monthly_reports_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TextEditingController _salaryController;
  final _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _salaryController = TextEditingController();

    final uid = context.read<AuthProvider>().user?.uid;
    if (uid != null) {
      context.read<HomeProvider>().loadAccount(uid);
      context.read<CardsProvider>().loadCards(uid);
      context.read<SubscriptionsProvider>().loadSubscriptions(uid);
      context.read<BillsPayableProvider>().loadBills(uid);
      context.read<NotesProvider>().loadNotes(uid);
      context.read<MonthlyReportProvider>().loadReports(uid);

      // Verifica virada de mês logo após carregar todos os dados
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkMonthReset(uid));
    }
  }

  Future<void> _checkMonthReset(String uid) async {
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

  @override
  void dispose() {
    _salaryController.dispose();
    super.dispose();
  }

  void _showSalaryDialog() {
    final account = context.read<HomeProvider>().account;
    _salaryController.text = account?.salary.toString() ?? '0';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Salário'),
        content: TextField(
          controller: _salaryController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              label: Text('Salário mensal'), prefixText: 'R\$ '),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final salary = double.tryParse(_salaryController.text) ?? 0;
              final account = context.read<HomeProvider>().account;
              if (account != null) {
                context
                    .read<HomeProvider>()
                    .updateAccount(account.copyWith(salary: salary));
              }
              Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _navigate(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final account = context.watch<HomeProvider>().account;
    final subscriptions = context.watch<SubscriptionsProvider>().subscriptions;
    final billsProvider = context.watch<BillsPayableProvider>();
    final urgentCount = billsProvider.urgentBills.length;

    final totalSubscriptions =
        subscriptions.fold<double>(0, (s, sub) => s + sub.monthlyValue);
    final totalBillsPending = billsProvider.totalPending;
    final finalBalance =
        (account?.salary ?? 0) - totalSubscriptions - totalBillsPending;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Care'),
        centerTitle: true,
        elevation: 0,
      ),
      // ─── MENU HAMBÚRGUER ─────────────────────────────────────────
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
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.read<AuthProvider>().user?.email ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  const Text('Finance Care',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            _DrawerItem(
                icon: Icons.home_outlined,
                label: 'Início',
                onTap: () => Navigator.pop(context)),
            _DrawerItem(
              icon: Icons.credit_card_outlined,
              label: 'Cartões',
              onTap: () {
                Navigator.pop(context);
                _navigate(const CardsScreen());
              },
            ),
            _DrawerItem(
              icon: Icons.subscriptions_outlined,
              label: 'Assinaturas',
              onTap: () {
                Navigator.pop(context);
                _navigate(const SubscriptionsScreen());
              },
            ),
            _DrawerItem(
              icon: Icons.receipt_long_outlined,
              label: 'Contas a Pagar',
              badge: urgentCount > 0 ? urgentCount.toString() : null,
              onTap: () {
                Navigator.pop(context);
                _navigate(const BillsPayableScreen());
              },
            ),
            _DrawerItem(
              icon: Icons.bar_chart_outlined,
              label: 'Gráficos',
              onTap: () {
                Navigator.pop(context);
                _navigate(const ChartsScreen());
              },
            ),
            _DrawerItem(
              icon: Icons.note_alt_outlined,
              label: 'Bloco de Notas',
              onTap: () {
                Navigator.pop(context);
                _navigate(const NotesScreen());
              },
            ),
            _DrawerItem(
              icon: Icons.calendar_month_outlined,
              label: 'Relatórios Mensais',
              onTap: () {
                Navigator.pop(context);
                _navigate(const MonthlyReportsScreen());
              },
            ),
            const Spacer(),
            const Divider(),
            _DrawerItem(
              icon: Icons.logout,
              label: 'Sair',
              color: AppColors.danger,
              onTap: () {
                Navigator.pop(context);
                context.read<AuthProvider>().signOut();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      // ─── CORPO ───────────────────────────────────────────────────
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo Financeiro',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _showSalaryDialog,
              child: AccountCard(
                title: 'Salário',
                value: _currencyFormat.format(account?.salary ?? 0),
                subtitle: 'Toque para editar',
                valueColor: AppColors.success,
                icon: Icons.edit,
              ),
            ),
            const SizedBox(height: 12),
            AccountCard(
              title: 'Contas a Pagar',
              value: _currencyFormat.format(totalBillsPending),
              subtitle:
                  '${billsProvider.pendingBills.length} pendentes',
              valueColor: AppColors.danger,
            ),
            const SizedBox(height: 12),
            AccountCard(
              title: 'Assinaturas',
              value: _currencyFormat.format(totalSubscriptions),
              subtitle: '${subscriptions.length} assinaturas ativas',
              valueColor: AppColors.warning,
            ),
            const SizedBox(height: 12),
            AccountCard(
              title: 'Saldo Final',
              value: _currencyFormat.format(finalBalance),
              subtitle: finalBalance < 0
                  ? 'Você está no vermelho'
                  : 'Saldo disponível',
              valueColor:
                  finalBalance < 0 ? AppColors.danger : AppColors.success,
            ),
            const SizedBox(height: 28),
            Text(
              'Acesso Rápido',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.0,
              children: [
                _QuickCard(
                    icon: Icons.credit_card,
                    label: 'Cartões',
                    color: AppColors.primary,
                    onTap: () => _navigate(const CardsScreen())),
                _QuickCard(
                    icon: Icons.subscriptions,
                    label: 'Assinaturas',
                    color: AppColors.secondary,
                    onTap: () => _navigate(const SubscriptionsScreen())),
                _QuickCard(
                    icon: Icons.receipt_long,
                    label: 'Contas',
                    color: AppColors.danger,
                    badge: urgentCount > 0 ? urgentCount.toString() : null,
                    onTap: () => _navigate(const BillsPayableScreen())),
                _QuickCard(
                    icon: Icons.bar_chart,
                    label: 'Gráficos',
                    color: AppColors.success,
                    onTap: () => _navigate(const ChartsScreen())),
                _QuickCard(
                    icon: Icons.note_alt,
                    label: 'Notas',
                    color: AppColors.warning,
                    onTap: () => _navigate(const NotesScreen())),
                _QuickCard(
                    icon: Icons.calendar_month,
                    label: 'Relatórios',
                    color: const Color(0xFF0891B2),
                    onTap: () => _navigate(const MonthlyReportsScreen())),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── WIDGETS ─────────────────────────────────────────────────────────

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;
  final Color? color;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: c),
          if (badge != null)
            Positioned(
              top: -4,
              right: -6,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                    color: AppColors.danger, shape: BoxShape.circle),
                child: Text(badge!,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 9)),
              ),
            ),
        ],
      ),
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

  const _QuickCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(height: 6),
                  Text(label,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      color: AppColors.danger, shape: BoxShape.circle),
                  child: Text(badge!,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 10)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
