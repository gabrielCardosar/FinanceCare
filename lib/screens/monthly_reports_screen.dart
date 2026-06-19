import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../providers/cards_provider.dart';
import '../providers/subscriptions_provider.dart';
import '../providers/bills_payable_provider.dart';
import '../providers/monthly_report_provider.dart';
import '../models/monthly_report_model.dart';
import '../utils/constants.dart';

class MonthlyReportsScreen extends StatelessWidget {
  const MonthlyReportsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final reports = context.watch<MonthlyReportProvider>().reports;
    final isLoading = context.watch<MonthlyReportProvider>().isLoading;
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios Mensais'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_chart),
            tooltip: 'Gerar relatório do mês atual',
            onPressed: () => _generateManual(context),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reports.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_month,
                          size: 64,
                          color: AppColors.primary.withOpacity(0.4)),
                      const SizedBox(height: 16),
                      const Text(
                        'Nenhum relatório ainda',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'Os relatórios são gerados automaticamente no início de cada mês. '
                          'Você também pode gerar manualmente pelo botão acima.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    return _ReportCard(
                      report: report,
                      currencyFormat: currencyFormat,
                      onTap: () => _openDetail(context, report),
                    );
                  },
                ),
    );
  }

  Future<void> _generateManual(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gerar Relatório'),
        content: const Text(
            'Isso vai salvar um relatório com os dados financeiros do mês atual. Deseja continuar?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Gerar')),
        ],
      ),
    );
    if (confirm != true) return;

    final uid = context.read<AuthProvider>().user?.uid ?? '';
    final salary = context.read<HomeProvider>().account?.salary ?? 0;
    final bills = context.read<BillsPayableProvider>().bills;
    final subscriptions =
        context.read<SubscriptionsProvider>().subscriptions;
    final cards = context.read<CardsProvider>().cards;

    await context.read<MonthlyReportProvider>().generateManualReport(
          uid: uid,
          salary: salary,
          bills: bills,
          subscriptions: subscriptions,
          cards: cards,
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Relatório gerado com sucesso!')),
      );
    }
  }

  void _openDetail(BuildContext context, MonthlyReportModel report) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ReportDetailScreen(report: report)),
    );
  }
}

// ─── CARD RESUMIDO ────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  final MonthlyReportModel report;
  final NumberFormat currencyFormat;
  final VoidCallback onTap;

  const _ReportCard({
    required this.report,
    required this.currencyFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPositive = report.finalBalance >= 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(
              color: isPositive ? AppColors.success : AppColors.danger,
              width: 4,
            ),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05), blurRadius: 6)
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  report.monthLabel,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 17),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? AppColors.success.withOpacity(0.12)
                        : AppColors.danger.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    currencyFormat.format(report.finalBalance),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isPositive
                          ? AppColors.success
                          : AppColors.danger,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _MiniStat(
                    label: 'Salário',
                    value: currencyFormat.format(report.salary),
                    color: AppColors.success),
                const SizedBox(width: 12),
                _MiniStat(
                    label: 'Assinaturas',
                    value:
                        currencyFormat.format(report.totalSubscriptions),
                    color: AppColors.warning),
                const SizedBox(width: 12),
                _MiniStat(
                    label: 'Contas',
                    value: currencyFormat
                        .format(report.totalBillsPaid + report.totalBillsUnpaid),
                    color: AppColors.danger),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${report.bills.length} conta(s)  •  ${report.subscriptions.length} assinatura(s)  •  ${report.cards.length} cartão(ões)',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const Icon(Icons.chevron_right,
                    size: 18, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: color)),
      ],
    );
  }
}

// ─── TELA DE DETALHE DO RELATÓRIO ─────────────────────────────────────

class ReportDetailScreen extends StatelessWidget {
  final MonthlyReportModel report;
  const ReportDetailScreen({Key? key, required this.report})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(title: Text(report.monthLabel)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho resumo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text(report.monthLabel,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(report.finalBalance),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.finalBalance >= 0
                        ? 'Saldo positivo'
                        : 'Saldo negativo',
                    style: TextStyle(
                        color: report.finalBalance >= 0
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _HeaderStat(
                          label: 'Salário',
                          value: currencyFormat.format(report.salary),
                          icon: Icons.attach_money),
                      _HeaderStat(
                          label: 'Assinaturas',
                          value: currencyFormat
                              .format(report.totalSubscriptions),
                          icon: Icons.subscriptions),
                      _HeaderStat(
                          label: 'Cartões',
                          value:
                              currencyFormat.format(report.totalCardUsed),
                          icon: Icons.credit_card),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Gerado em: ${dateFormat.format(report.savedAt)}',
                style:
                    const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 22),

            // ── CONTAS ─────────────────────────────────────────────
            _SectionHeader(
              icon: Icons.receipt_long,
              label: 'Contas a Pagar',
              extra: Row(
                children: [
                  _PillStat(
                    label: 'Pagas',
                    value:
                        currencyFormat.format(report.totalBillsPaid),
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 6),
                  _PillStat(
                    label: 'Não pagas',
                    value:
                        currencyFormat.format(report.totalBillsUnpaid),
                    color: AppColors.danger,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (report.bills.isEmpty)
              _EmptySection('Nenhuma conta neste mês')
            else
              ...report.bills.map((b) => _BillTile(
                    bill: b,
                    currencyFormat: currencyFormat,
                    isDark: isDark,
                  )),

            const SizedBox(height: 22),

            // ── ASSINATURAS ────────────────────────────────────────
            _SectionHeader(
              icon: Icons.subscriptions,
              label: 'Assinaturas',
              extra: _PillStat(
                label: 'Total',
                value: currencyFormat.format(report.totalSubscriptions),
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 8),
            if (report.subscriptions.isEmpty)
              _EmptySection('Nenhuma assinatura neste mês')
            else
              ...report.subscriptions.map((s) => _SubTile(
                    sub: s,
                    currencyFormat: currencyFormat,
                    isDark: isDark,
                  )),

            const SizedBox(height: 22),

            // ── CARTÕES ────────────────────────────────────────────
            _SectionHeader(
              icon: Icons.credit_card,
              label: 'Cartões',
              extra: _PillStat(
                label: 'Uso total',
                value: currencyFormat.format(report.totalCardUsed),
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            if (report.cards.isEmpty)
              _EmptySection('Nenhum cartão neste mês')
            else
              ...report.cards.map((c) => _CardTile(
                    card: c,
                    currencyFormat: currencyFormat,
                    isDark: isDark,
                  )),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─── WIDGETS DE DETALHE ───────────────────────────────────────────────

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _HeaderStat(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(label,
            style:
                const TextStyle(color: Colors.white70, fontSize: 11)),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? extra;
  const _SectionHeader(
      {required this.icon, required this.label, this.extra});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16)),
        const Spacer(),
        if (extra != null) extra!,
      ],
    );
  }
}

class _PillStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _PillStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$label: $value',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color)),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String message;
  const _EmptySection(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(message,
          style: const TextStyle(color: Colors.grey, fontSize: 13)),
    );
  }
}

class _BillTile extends StatelessWidget {
  final ReportBillItem bill;
  final NumberFormat currencyFormat;
  final bool isDark;
  const _BillTile(
      {required this.bill,
      required this.currencyFormat,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: bill.isPaid ? AppColors.success : AppColors.danger,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            bill.isPaid ? Icons.check_circle : Icons.cancel,
            color: bill.isPaid ? AppColors.success : AppColors.danger,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bill.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    if (bill.isFixed)
                      _Tag(label: 'Fixa', color: AppColors.primary),
                    const SizedBox(width: 4),
                    _Tag(
                      label: bill.urgency == 'urgente'
                          ? 'Urgente'
                          : bill.urgency == 'moderado'
                              ? 'Moderado'
                              : 'Leve',
                      color: bill.urgency == 'urgente'
                          ? AppColors.danger
                          : bill.urgency == 'moderado'
                              ? AppColors.warning
                              : AppColors.success,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            currencyFormat.format(bill.amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: bill.isPaid ? AppColors.success : AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubTile extends StatelessWidget {
  final ReportSubscriptionItem sub;
  final NumberFormat currencyFormat;
  final bool isDark;
  const _SubTile(
      {required this.sub,
      required this.currencyFormat,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.subscriptions,
              size: 18, color: AppColors.secondary),
          const SizedBox(width: 10),
          Expanded(
              child: Text(sub.name,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          Text(
            '${currencyFormat.format(sub.monthlyValue)}/mês',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.warning),
          ),
        ],
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  final ReportCardItem card;
  final NumberFormat currencyFormat;
  final bool isDark;
  const _CardTile(
      {required this.card,
      required this.currencyFormat,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    final pct = card.limit > 0 ? (card.usedLimit / card.limit) : 0.0;
    final cardColor = Color(card.colorValue);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: cardColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: cardColor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(
                '${card.cardName} • ${card.bankName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              )),
              Text(
                '${(pct * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: pct > 0.8 ? AppColors.danger : AppColors.success),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(
                  pct > 0.8 ? AppColors.danger : cardColor),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Usado: ${currencyFormat.format(card.usedLimit)}',
                  style: const TextStyle(fontSize: 12)),
              Text('Limite: ${currencyFormat.format(card.limit)}',
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
