import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/budget_bloc.dart';
import '../blocs/finance_bloc.dart';
import '../blocs/settings_cubit.dart';
import '../l10n/app_strings.dart';
import '../models/budget.dart';
import '../models/entry_type.dart';
import '../services/finance_metrics.dart';
import '../services/money.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  Future<void> _setBudget(BuildContext context, MonthlyBudget? current) async {
    final s = AppStrings.of(context);
    final settings = context.read<SettingsCubit>().state;
    var amountText = '';
    if (current != null) {
      final scale = currencyDigits(settings.currencyCode) == 0 ? 1 : 100;
      amountText = (current.limitMinor / scale).toStringAsFixed(
        currencyDigits(settings.currencyCode),
      );
    }
    final amount = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.t('setBudget')),
        content: TextFormField(
          initialValue: amountText,
          onChanged: (value) => amountText = value,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: s.t('limit'),
            suffixText: settings.currencyCode,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(s.t('cancel')),
          ),
          FilledButton(
            onPressed: () {
              final parsed = parseMoney(amountText, settings.currencyCode);
              if (parsed != null) Navigator.pop(dialogContext, parsed);
            },
            child: Text(s.t('save')),
          ),
        ],
      ),
    );
    if (amount == null || !context.mounted) return;
    final now = DateTime.now();
    await context.read<BudgetBloc>().save(
      MonthlyBudget(
        year: now.year,
        month: now.month,
        currencyCode: settings.currencyCode,
        limitMinor: amount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final settings = context.watch<SettingsCubit>().state;
    final finance = context.watch<FinanceBloc>().state;
    final budgets = context.watch<BudgetBloc>().state;
    final now = DateTime.now();
    final current = budgets
        .where(
          (b) =>
              b.year == now.year &&
              b.month == now.month &&
              b.currencyCode == settings.currencyCode,
        )
        .firstOrNull;
    final month = FinanceMetrics.inMonth(
      finance.transactions,
      now,
      settings.currencyCode,
    );
    final expenses = FinanceMetrics.total(month, EntryType.expense);
    final byCategory = FinanceMetrics.expenseByCategory(month);
    final chartTotal = byCategory.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    final ratio = current == null ? 0.0 : expenses / current.limitMinor;
    final progressColor = ratio > 1
        ? const Color(0xFFDC5858)
        : ratio >= 0.8
        ? const Color(0xFFE6A832)
        : const Color(0xFF2EA479);
    final currency = settings.currencyCode;
    final locale = settings.localeCode;

    return Scaffold(
      appBar: AppBar(title: Text(s.t('analytics'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        s.t('budget'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        onPressed: () => _setBudget(context, current),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ],
                  ),
                  Text(
                    current == null
                        ? s.t('noBudget')
                        : '${formatMoney(expenses, currency, locale)} / ${formatMoney(current.limitMinor, currency, locale)}',
                  ),
                  const SizedBox(height: 14),
                  LinearProgressIndicator(
                    value: ratio.clamp(0, 1),
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(12),
                    color: progressColor,
                  ),
                  const SizedBox(height: 8),
                  Text('${s.t('used')}: ${(ratio * 100).toStringAsFixed(0)}%'),
                  if (current == null)
                    TextButton(
                      onPressed: () => _setBudget(context, null),
                      child: Text(s.t('setBudget')),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.t('byCategory'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  if (chartTotal == 0)
                    Text(s.t('noExpenses'))
                  else ...[
                    SizedBox(
                      height: 220,
                      child: PieChart(
                        PieChartData(
                          centerSpaceRadius: 45,
                          sectionsSpace: 3,
                          sections: byCategory.entries.map((entry) {
                            final category = finance.categories
                                .where((c) => c.id == entry.key)
                                .firstOrNull;
                            return PieChartSectionData(
                              value: entry.value.toDouble(),
                              color: Color(category?.colorValue ?? 0xFF9AA8A5),
                              radius: 55,
                              title:
                                  '${(entry.value / chartTotal * 100).round()}%',
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    for (final entry in byCategory.entries)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 8,
                          backgroundColor: Color(
                            finance.categories
                                    .where((c) => c.id == entry.key)
                                    .firstOrNull
                                    ?.colorValue ??
                                0xFF9AA8A5,
                          ),
                        ),
                        title: Text(
                          finance.categories
                                  .where((c) => c.id == entry.key)
                                  .firstOrNull
                                  ?.displayName(locale) ??
                              s.t('category'),
                        ),
                        trailing: Text(
                          formatMoney(entry.value, currency, locale),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.t('balanceTrend'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 180,
                    child: _BalanceChart(currency: currency),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceChart extends StatelessWidget {
  const _BalanceChart({required this.currency});
  final String currency;

  @override
  Widget build(BuildContext context) {
    final all = FinanceMetrics.inCurrency(
      context.watch<FinanceBloc>().state.transactions,
      currency,
    );
    final today = DateTime.now();
    final spots = <FlSpot>[];
    for (var offset = 6; offset >= 0; offset--) {
      final day = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: offset));
      final cutoff = day.add(const Duration(days: 1));
      final balance = FinanceMetrics.balance(
        all.where((e) => e.occurredAt.isBefore(cutoff)),
      );
      spots.add(FlSpot((6 - offset).toDouble(), balance.toDouble()));
    }
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 4,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).colorScheme.primary
                  .withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}
