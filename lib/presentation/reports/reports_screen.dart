import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/providers.dart';
import '../../domain/entities.dart';
import '../../l10n/gen/app_localizations.dart';
import '../widgets/empty_state.dart';
import '../widgets/money_text.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final summary = ref.watch(monthSummaryProvider(month));
    final byCategory = ref.watch(spendingByCategoryProvider(month));
    final trend = ref.watch(trendProvider(month));
    final catsById = ref.watch(categoriesByIdProvider);
    final notifier = ref.read(selectedMonthProvider.notifier);
    final l = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => notifier.shift(-1)),
            Text(month, style: Theme.of(context).textTheme.titleMedium),
            IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => notifier.shift(1)),
          ],
        ),
        const SizedBox(height: 8),
        _SummaryStrip(summary: summary),
        const SizedBox(height: 24),
        Text(l.spendingByCategory,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (byCategory.isEmpty)
          EmptyState(
            icon: Icons.pie_chart_outline,
            message: l.noExpensesThisMonth,
          )
        else
          _CategoryPie(spend: byCategory, catsById: catsById),
        const SizedBox(height: 24),
        Text(l.incomeVsExpense,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (trend.isEmpty)
          EmptyState(
            icon: Icons.bar_chart_outlined,
            message: l.noDataThisMonth,
          )
        else
          _TrendBars(points: trend),
      ],
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.summary});
  final PeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget cell(String label, int amount) => Column(
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            MoneyText(amount,
                colorBySign: true,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            cell(l.income, summary.incomeMinor),
            cell(l.expense, -summary.expenseMinor),
            cell(l.net, summary.netMinor),
          ],
        ),
      ),
    );
  }
}

class _CategoryPie extends StatelessWidget {
  const _CategoryPie({required this.spend, required this.catsById});
  final List<CategorySpend> spend;
  final Map<int, Category> catsById;

  @override
  Widget build(BuildContext context) {
    final total = spend.fold<int>(0, (s, e) => s + e.totalMinor);
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: spend.map((s) {
                final cat = catsById[s.categoryId];
                final color =
                    cat != null ? Color(cat.colorValue) : Colors.grey;
                final pct = total == 0 ? 0.0 : s.totalMinor / total * 100;
                return PieChartSectionData(
                  value: s.totalMinor.toDouble(),
                  color: color,
                  title: '${pct.toStringAsFixed(0)}%',
                  radius: 60,
                  titleStyle: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...spend.map((s) {
          final cat = catsById[s.categoryId];
          final color = cat != null ? Color(cat.colorValue) : Colors.grey;
          return ListTile(
            dense: true,
            leading: CircleAvatar(backgroundColor: color, radius: 8),
            title: Text(cat?.name ?? AppLocalizations.of(context).category),
            trailing: MoneyText(s.totalMinor),
          );
        }),
      ],
    );
  }
}

class _TrendBars extends StatelessWidget {
  const _TrendBars({required this.points});
  final List<TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final maxVal = points.fold<int>(
      1,
      (m, p) => [m, p.incomeMinor, p.expenseMinor].reduce((a, b) => a > b ? a : b),
    );
    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal.toDouble() * 1.1,
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= points.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(DateFormat.d().format(points[i].bucket),
                        style: const TextStyle(fontSize: 9)),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          barGroups: [
            for (var i = 0; i < points.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                      toY: points[i].incomeMinor.toDouble(),
                      color: Colors.green,
                      width: 6),
                  BarChartRodData(
                      toY: points[i].expenseMinor.toDouble(),
                      color: Colors.red,
                      width: 6),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
