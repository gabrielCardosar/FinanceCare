import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/home_provider.dart';
import '../providers/subscriptions_provider.dart';
import '../providers/cards_provider.dart';
import '../providers/bills_payable_provider.dart';
import '../models/bill_payable_model.dart';
import '../utils/constants.dart';

class ChartsScreen extends StatelessWidget {
  const ChartsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final account = context.watch<HomeProvider>().account;
    final subscriptions = context.watch<SubscriptionsProvider>().subscriptions;
    final cards = context.watch<CardsProvider>().cards;
    final bills = context.watch<BillsPayableProvider>().bills;
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    final salary = account?.salary ?? 0;
    final totalSubs =
        subscriptions.fold<double>(0, (s, sub) => s + sub.monthlyValue);
    final totalBills =
        bills.where((b) => !b.isPaid).fold<double>(0, (s, b) => s + b.amount);
    final remaining =
        (salary - totalSubs - totalBills).clamp(0.0, double.infinity);

    final pieData = <_PieSlice>[
      _PieSlice(label: 'Disponível', value: remaining, color: AppColors.success),
      _PieSlice(label: 'Assinaturas', value: totalSubs, color: AppColors.warning),
      _PieSlice(label: 'Contas', value: totalBills, color: AppColors.danger),
    ].where((s) => s.value > 0).toList();
    final total = pieData.fold<double>(0, (s, d) => s + d.value);

    return Scaffold(
      appBar: AppBar(title: const Text('Gráficos Financeiros')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Distribuição do Salário ──────────────────────────
            const _SectionTitle('Distribuição do Salário'),
            const SizedBox(height: 12),
            if (salary == 0)
              const _EmptyChart(message: 'Configure seu salário na tela inicial')
            else ...[
              Center(
                child: SizedBox(
                  height: 200,
                  width: 200,
                  child: _PieChart(slices: pieData, total: total),
                ),
              ),
              const SizedBox(height: 16),
              ...pieData.map((s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: s.color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(s.label)),
                        Text(
                          currencyFormat.format(s.value),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(total > 0 ? s.value / total * 100 : 0).toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: s.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
            const SizedBox(height: 28),

            // ── Uso dos Cartões ──────────────────────────────────
            const _SectionTitle('Uso dos Cartões'),
            const SizedBox(height: 12),
            if (cards.isEmpty)
              const _EmptyChart(message: 'Nenhum cartão cadastrado')
            else
              ...cards.map((card) {
                final pct =
                    card.limit > 0 ? (card.usedLimit / card.limit) : 0.0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: card.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                card.cardName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Text(
                            '${(pct * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: pct > 0.8
                                  ? AppColors.danger
                                  : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: pct.clamp(0.0, 1.0),
                          minHeight: 10,
                          backgroundColor: Colors.grey.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation(
                            pct > 0.8 ? AppColors.danger : card.color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Utilizado: ${currencyFormat.format(card.usedLimit)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            'Limite: ${currencyFormat.format(card.limit)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      if (card.invoiceDueDay != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Fatura vence dia ${card.invoiceDueDay}'
                          '${card.daysUntilInvoice != null ? ' (em ${card.daysUntilInvoice} dias)' : ''}',
                          style: TextStyle(
                            fontSize: 11,
                            color: (card.daysUntilInvoice ?? 99) <= 5
                                ? AppColors.danger
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            const SizedBox(height: 28),

            // ── Contas por Urgência ──────────────────────────────
            const _SectionTitle('Contas por Urgência'),
            const SizedBox(height: 12),
            if (bills.isEmpty)
              const _EmptyChart(message: 'Nenhuma conta cadastrada')
            else
              _UrgencyChart(bills: bills, currencyFormat: currencyFormat),
            const SizedBox(height: 28),

            // ── Assinaturas ──────────────────────────────────────
            const _SectionTitle('Assinaturas'),
            const SizedBox(height: 12),
            if (subscriptions.isEmpty)
              const _EmptyChart(message: 'Nenhuma assinatura cadastrada')
            else
              ...subscriptions.map((sub) {
                final pct =
                    totalSubs > 0 ? sub.monthlyValue / totalSubs : 0.0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: sub.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                sub.name,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          Text(
                            currencyFormat.format(sub.monthlyValue),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: sub.color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: Colors.grey.withOpacity(0.15),
                          valueColor: AlwaysStoppedAnimation(sub.color),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─── WIDGETS ────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final String message;
  const _EmptyChart({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.grey, fontSize: 13),
      ),
    );
  }
}

class _PieSlice {
  final String label;
  final double value;
  final Color color;
  const _PieSlice({required this.label, required this.value, required this.color});
}

class _PieChart extends StatelessWidget {
  final List<_PieSlice> slices;
  final double total;
  const _PieChart({required this.slices, required this.total});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PiePainter(slices: slices, total: total),
      child: const SizedBox.expand(),
    );
  }
}

class _PiePainter extends CustomPainter {
  final List<_PieSlice> slices;
  final double total;
  _PiePainter({required this.slices, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    double startAngle = -3.14159 / 2;

    for (final slice in slices) {
      final sweep = (slice.value / total) * 2 * 3.14159;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle, sweep, true,
        Paint()
          ..color = slice.color
          ..style = PaintingStyle.fill,
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle, sweep, true,
        Paint()
          ..color = Colors.white.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      startAngle += sweep;
    }
    canvas.drawCircle(
      center,
      radius * 0.55,
      Paint()
        ..color = const Color(0xFF1A1A2E)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

// ✅ CORRIGIDO: urgency é UrgencyLevel (enum), compara com UrgencyLevel.urgente
class _UrgencyChart extends StatelessWidget {
  final List<BillPayableModel> bills;
  final NumberFormat currencyFormat;
  const _UrgencyChart({required this.bills, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: comparar com enum UrgencyLevel, não com String
    final groups = {
      UrgencyLevel.urgente: bills.where((b) => b.urgency == UrgencyLevel.urgente).toList(),
      UrgencyLevel.moderado: bills.where((b) => b.urgency == UrgencyLevel.moderado).toList(),
      UrgencyLevel.leve: bills.where((b) => b.urgency == UrgencyLevel.leve).toList(),
    };

    return Column(
      children: groups.entries.map((e) {
        final level = e.key;
        final group = e.value;
        final total = group.fold<double>(0, (s, b) => s + b.amount);
        final count = group.length;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: level.color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: level.color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(level.icon, color: level.color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: level.color,
                      ),
                    ),
                    Text(
                      '$count conta${count != 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                currencyFormat.format(total),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: level.color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}