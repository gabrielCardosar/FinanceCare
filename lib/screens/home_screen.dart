import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/card_model.dart';
import '../models/bill_payable_model.dart';
import '../providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../providers/cards_provider.dart';
import '../providers/subscriptions_provider.dart';
import '../providers/bills_payable_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/monthly_report_provider.dart';
import '../providers/purchases_provider.dart';
import '../providers/extra_income_provider.dart';
import '../utils/constants.dart';
import '../widgets/ui.dart';
import '../widgets/card_sheets.dart';
import 'cards_screen.dart';
import 'card_invoice_screen.dart';
import 'subscriptions_screen.dart';
import 'bills_payable_screen.dart';
import 'notes_screen.dart';
import 'charts_screen.dart';
import 'monthly_reports_screen.dart';
import 'calculator_screen.dart';
import 'purchases_screen.dart';
import 'extra_income_screen.dart';

/// Tela principal com navegação inferior.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

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
    final cards = context.read<CardsProvider>();
    await context.read<MonthlyReportProvider>().checkAndGenerateReport(
          uid: uid,
          salary: account?.salary ?? 0,
          bills: bills,
          subscriptions: subscriptions,
          cards: cards.ledgers,
        );
  }

  @override
  Widget build(BuildContext context) {
    final urgent = context.watch<BillsPayableProvider>().urgentBills.length;
    final overdueCards = context.watch<CardsProvider>().overdueCount;

    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          _Dashboard(onGoToTab: (i) => setState(() => _tab = i)),
          const CardsScreen(),
          const BillsPayableScreen(),
          const _MoreScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Início'),
          NavigationDestination(
              icon: Badge(
                  isLabelVisible: overdueCards > 0,
                  label: Text('$overdueCards'),
                  child: const Icon(Icons.credit_card_outlined)),
              selectedIcon: const Icon(Icons.credit_card),
              label: 'Cartões'),
          NavigationDestination(
              icon: Badge(
                  isLabelVisible: urgent > 0,
                  label: Text('$urgent'),
                  child: const Icon(Icons.receipt_long_outlined)),
              selectedIcon: const Icon(Icons.receipt_long),
              label: 'Contas'),
          const NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Mais'),
        ],
      ),
    );
  }
}

void _push(BuildContext context, Widget screen) =>
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

// ─── Painel inicial ────────────────────────────────────────────────────────

class _Dashboard extends StatelessWidget {
  final ValueChanged<int> onGoToTab;
  const _Dashboard({required this.onGoToTab});

  void _showSalaryDialog(BuildContext context) {
    final account = context.read<HomeProvider>().account;
    final ctrl = TextEditingController(
        text: account != null && account.salary > 0
            ? account.salary.toStringAsFixed(2).replaceAll('.', ',')
            : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Salário mensal'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(prefixText: 'R\$ ', hintText: '0,00'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final salary = Fmt.parseMoney(ctrl.text);
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

  void _pickCardForPurchase(BuildContext context) {
    final cards = context.read<CardsProvider>().cards;
    if (cards.isEmpty) {
      onGoToTab(1);
      return;
    }
    if (cards.length == 1) {
      showCardPurchaseSheet(context, cards.first);
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Em qual cartão?',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ),
          ...cards.map((c) => ListTile(
                leading: IconBadge(Icons.credit_card, color: c.color),
                title: Text(c.cardName),
                subtitle: Text(c.bankName),
                onTap: () {
                  Navigator.pop(ctx);
                  showCardPurchaseSheet(context, c);
                },
              )),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final account = context.watch<HomeProvider>().account;
    final subs = context.watch<SubscriptionsProvider>().subscriptions;
    final bills = context.watch<BillsPayableProvider>();
    final cards = context.watch<CardsProvider>();
    final extra = context.watch<ExtraIncomeProvider>().total;
    final purchases = context.watch<PurchasesProvider>();

    final salary = account?.salary ?? 0;
    final totalSubs = subs.fold<double>(0, (s, sub) => s + sub.monthlyValue);
    final income = salary + extra;

    // SALDO = renda - assinaturas - contas pagas - compras PIX/dinheiro - faturas pagas no mês
    // Compras no cartão só saem do saldo quando a fatura é paga.
    final spent = totalSubs +
        bills.totalPaid +
        purchases.totalFromBalance +
        cards.totalPaidThisMonth;
    final balance = income - spent;
    // Previsto: o que sobra depois de pagar contas pendentes e faturas que vencem no mês
    final forecast = balance - bills.totalPending - cards.totalDueThisMonth;

    final name = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.split(' ').first
        : (user?.email?.split('@').first ?? '');
    final now = DateTime.now();
    final upcoming = [...bills.pendingBills]..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // Cabeçalho
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Olá${name.isNotEmpty ? ', $name' : ''} 👋',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
                Text(InvoiceMonth.fromDate(now).label,
                    style: TextStyle(color: AppColors.subText(context))),
              ]),
            ),
            IconButton.filledTonal(
              tooltip: 'Relatórios',
              icon: const Icon(Icons.insights_outlined),
              onPressed: () => _push(context, const ChartsScreen()),
            ),
          ]),
          const SizedBox(height: 18),

          // Saldo
          _BalanceHero(
            balance: balance,
            income: income,
            spent: spent,
            forecast: forecast,
            onEditSalary: () => _showSalaryDialog(context),
          ),
          const SizedBox(height: 18),

          // Ações rápidas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _QuickAction(
                  icon: Icons.add_shopping_cart,
                  label: 'Compra\nno cartão',
                  color: AppColors.primary,
                  onTap: () => _pickCardForPurchase(context)),
              _QuickAction(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Compra\nPIX/dinheiro',
                  color: AppColors.orange,
                  onTap: () => _push(context, const PurchasesScreen())),
              _QuickAction(
                  icon: Icons.receipt_long_outlined,
                  label: 'Contas\na pagar',
                  color: AppColors.danger,
                  onTap: () => onGoToTab(2)),
              _QuickAction(
                  icon: Icons.trending_up,
                  label: 'Renda\nextra',
                  color: AppColors.success,
                  onTap: () => _push(context, const ExtraIncomeScreen())),
            ],
          ),
          const SizedBox(height: 22),

          // Alertas de faturas
          ..._invoiceAlerts(context, cards),

          // Cartões
          SectionHeader('Cartões',
              action: cards.cards.isEmpty ? 'Adicionar' : 'Ver todos',
              onAction: () => onGoToTab(1)),
          if (cards.cards.isEmpty)
            Surface(
              onTap: () => onGoToTab(1),
              child: Row(children: [
                const IconBadge(Icons.add_card, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Cadastre um cartão para controlar faturas e parcelas',
                      style: TextStyle(color: AppColors.subText(context))),
                ),
              ]),
            )
          else
            SizedBox(
              height: 170,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: cards.ledgers.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final l = cards.ledgers[i];
                  return SizedBox(
                    width: 270,
                    child: CreditCardVisual(
                      ledger: l,
                      compact: true,
                      onTap: () =>
                          _push(context, CardInvoiceScreen(cardId: l.card.id!)),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 22),

          // Resumo do mês
          const SectionHeader('Resumo do mês'),
          Surface(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(children: [
              _SummaryRow(
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppColors.success,
                  label: 'Salário',
                  value: salary,
                  positive: true,
                  onTap: () => _showSalaryDialog(context)),
              if (extra > 0)
                _SummaryRow(
                    icon: Icons.trending_up,
                    color: AppColors.success,
                    label: 'Renda extra',
                    value: extra,
                    positive: true,
                    onTap: () => _push(context, const ExtraIncomeScreen())),
              _SummaryRow(
                  icon: Icons.subscriptions_outlined,
                  color: AppColors.secondary,
                  label: 'Assinaturas',
                  detail: '${subs.length} ativas',
                  value: totalSubs,
                  onTap: () => _push(context, const SubscriptionsScreen())),
              _SummaryRow(
                  icon: Icons.task_alt,
                  color: AppColors.danger,
                  label: 'Contas pagas',
                  detail: '${bills.paidBills.length} de ${bills.bills.length}',
                  value: bills.totalPaid,
                  onTap: () => onGoToTab(2)),
              _SummaryRow(
                  icon: Icons.shopping_bag_outlined,
                  color: AppColors.orange,
                  label: 'Compras PIX/dinheiro',
                  value: purchases.totalFromBalance,
                  onTap: () => _push(context, const PurchasesScreen())),
              _SummaryRow(
                  icon: Icons.credit_score_outlined,
                  color: AppColors.primary,
                  label: 'Faturas pagas',
                  value: cards.totalPaidThisMonth,
                  onTap: () => onGoToTab(1),
                  last: true),
            ]),
          ),
          const SizedBox(height: 12),
          Surface(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(children: [
              _SummaryRow(
                  icon: Icons.pending_actions_outlined,
                  color: AppColors.warning,
                  label: 'Contas pendentes',
                  detail: '${bills.pendingBills.length} contas',
                  value: bills.totalPending,
                  onTap: () => onGoToTab(2)),
              _SummaryRow(
                  icon: Icons.event_outlined,
                  color: AppColors.info,
                  label: 'Faturas a vencer no mês',
                  value: cards.totalDueThisMonth,
                  onTap: () => onGoToTab(1),
                  last: true),
            ]),
          ),

          // Próximas contas
          if (upcoming.isNotEmpty) ...[
            const SizedBox(height: 22),
            SectionHeader('Próximas contas', action: 'Ver todas', onAction: () => onGoToTab(2)),
            Surface(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                children: upcoming.take(4).map((b) => _BillTile(bill: b)).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _invoiceAlerts(BuildContext context, CardsProvider cards) {
    final alerts = <Widget>[];
    for (final l in cards.ledgers) {
      for (final m in l.unpaidClosedInvoices()) {
        final status = l.statusOf(m);
        alerts.add(Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Surface(
            color: status.color.withValues(alpha: 0.08),
            onTap: () => showPayInvoiceSheet(context, l, m),
            child: Row(children: [
              IconBadge(
                  status == InvoiceStatus.atrasada
                      ? Icons.error_outline
                      : Icons.schedule_outlined,
                  color: status.color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                      '${l.card.cardName}: fatura ${status == InvoiceStatus.atrasada ? 'atrasada' : 'fechada'}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(
                      '${Fmt.money(l.invoiceRemaining(m))} • vence ${Fmt.dayMonth(l.card.dueDateOf(m))}',
                      style: TextStyle(fontSize: 12, color: AppColors.subText(context))),
                ]),
              ),
              Text('Pagar',
                  style: TextStyle(color: status.color, fontWeight: FontWeight.w700)),
            ]),
          ),
        ));
      }
    }
    if (alerts.isNotEmpty) alerts.add(const SizedBox(height: 12));
    return alerts;
  }
}

class _BalanceHero extends StatelessWidget {
  final double balance;
  final double income;
  final double spent;
  final double forecast;
  final VoidCallback onEditSalary;

  const _BalanceHero({
    required this.balance,
    required this.income,
    required this.spent,
    required this.forecast,
    required this.onEditSalary,
  });

  @override
  Widget build(BuildContext context) {
    final negative = balance < 0;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: negative
            ? const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight)
            : AppColors.heroGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: (negative ? AppColors.danger : AppColors.primary)
                .withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(
            child: Text('Saldo disponível',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
          ),
          InkWell(
            onTap: onEditSalary,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: Colors.white24, borderRadius: BorderRadius.circular(20)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.edit_outlined, size: 14, color: Colors.white),
                SizedBox(width: 4),
                Text('Salário',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(Fmt.money(balance),
              style: const TextStyle(
                  color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
        ),
        if (negative)
          const Text('Você está no vermelho!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: _HeroStat(icon: Icons.south_west, label: 'Entradas', value: income)),
          Container(width: 1, height: 34, color: Colors.white24),
          const SizedBox(width: 14),
          Expanded(child: _HeroStat(icon: Icons.north_east, label: 'Saídas', value: spent)),
        ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            const Icon(Icons.auto_graph, color: Colors.white70, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Previsto no fim do mês',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
            ),
            Text(Fmt.money(forecast),
                style: TextStyle(
                    color: forecast < 0 ? const Color(0xFFFFC9C9) : Colors.white,
                    fontWeight: FontWeight.w800)),
          ]),
        ),
      ]),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  const _HeroStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 14),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(Fmt.money(value),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    ]);
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 78,
        child: Column(children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.2)),
        ]),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String? detail;
  final double value;
  final bool positive;
  final bool last;
  final VoidCallback? onTap;

  const _SummaryRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.detail,
    this.positive = false,
    this.last = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(bottom: BorderSide(color: AppColors.border(context))),
        ),
        child: Row(children: [
          IconBadge(icon, color: color, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (detail != null)
                Text(detail!,
                    style: TextStyle(fontSize: 12, color: AppColors.subText(context))),
            ]),
          ),
          Text(
            '${positive ? '+' : '-'} ${Fmt.money(value)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: positive ? AppColors.success : null,
            ),
          ),
        ]),
      ),
    );
  }
}

class _BillTile extends StatelessWidget {
  final BillPayableModel bill;
  const _BillTile({required this.bill});

  @override
  Widget build(BuildContext context) {
    final days = bill.daysUntilDue;
    final when = bill.isOverdue
        ? 'Vencida'
        : days <= 0
            ? 'Vence hoje'
            : days == 1
                ? 'Vence amanhã'
                : 'Vence ${Fmt.dayMonth(bill.dueDate)}';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: IconBadge(bill.urgency.icon, color: bill.urgency.color, size: 38),
      title: Text(bill.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(when,
          style: TextStyle(
              fontSize: 12, color: bill.isOverdue ? AppColors.danger : null)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(Fmt.money(bill.amount), style: const TextStyle(fontWeight: FontWeight.w700)),
        IconButton(
          tooltip: 'Marcar como paga',
          icon: const Icon(Icons.check_circle_outline, color: AppColors.success),
          onPressed: () => context.read<BillsPayableProvider>().togglePaid(bill),
        ),
      ]),
    );
  }
}

// ─── Aba "Mais" ────────────────────────────────────────────────────────────

class _MoreScreen extends StatelessWidget {
  const _MoreScreen();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final items = [
      _MoreItem(Icons.shopping_bag_outlined, 'Compras', AppColors.orange,
          () => _push(context, const PurchasesScreen())),
      _MoreItem(Icons.subscriptions_outlined, 'Assinaturas', AppColors.secondary,
          () => _push(context, const SubscriptionsScreen())),
      _MoreItem(Icons.trending_up, 'Renda extra', AppColors.success,
          () => _push(context, const ExtraIncomeScreen())),
      _MoreItem(Icons.pie_chart_outline, 'Gráficos', AppColors.info,
          () => _push(context, const ChartsScreen())),
      _MoreItem(Icons.calendar_month_outlined, 'Relatórios', const Color(0xFF64748B),
          () => _push(context, const MonthlyReportsScreen())),
      _MoreItem(Icons.sticky_note_2_outlined, 'Notas', AppColors.warning,
          () => _push(context, const NotesScreen())),
      _MoreItem(Icons.calculate_outlined, 'Calculadora', const Color(0xFF7C3AED),
          () => _push(context, const CalculatorScreen())),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Mais')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Surface(
            child: Row(children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.14),
                child: const Icon(Icons.person, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user?.displayName ?? 'Minha conta',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(user?.email ?? '',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: AppColors.subText(context))),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.95,
            children: items
                .map((i) => Surface(
                      padding: const EdgeInsets.all(8),
                      onTap: i.onTap,
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        IconBadge(i.icon, color: i.color, size: 46),
                        const SizedBox(height: 8),
                        Text(i.label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
            icon: const Icon(Icons.logout),
            label: const Text('Sair da conta'),
            onPressed: () => context.read<AuthProvider>().signOut(),
          ),
        ],
      ),
    );
  }
}

class _MoreItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  _MoreItem(this.icon, this.label, this.color, this.onTap);
}
