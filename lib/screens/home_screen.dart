import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../blocs/finance_bloc.dart';
import '../blocs/settings_cubit.dart';
import '../l10n/app_strings.dart';
import '../models/entry_type.dart';
import '../services/finance_metrics.dart';
import '../services/money.dart';
import '../widgets/transaction_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final settings = context.watch<SettingsCubit>().state;
    final finance = context.watch<FinanceBloc>().state;
    final currency = settings.currencyCode;
    final locale = settings.localeCode;
    final all = FinanceMetrics.inCurrency(finance.transactions, currency);
    final month = FinanceMetrics.inMonth(all, DateTime.now(), currency);
    final balance = FinanceMetrics.balance(all);
    final income = FinanceMetrics.total(month, EntryType.income);
    final expenses = FinanceMetrics.total(month, EntryType.expense);
    final demo = finance.transactions.any((e) => e.isDemo);

    return Scaffold(
      appBar: AppBar(title: Text(s.t('app'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
        children: [
          if (demo)
            Card(
              color: const Color(0xFFFFF3DB),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline),
                    const SizedBox(width: 10),
                    Expanded(child: Text(s.t('demo'))),
                    TextButton(
                      onPressed: () => context.read<FinanceBloc>().clearDemo(),
                      child: Text(s.t('clearDemo')),
                    ),
                  ],
                ),
              ),
            ),
          Card(
            color: Theme.of(context).colorScheme.primary,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${s.t('balance')} · $currency',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatMoney(balance, currency, locale),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _Summary(
                          label: s.t('incomeMonth'),
                          value: formatMoney(income, currency, locale),
                          icon: Icons.arrow_downward_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Summary(
                          label: s.t('expenseMonth'),
                          value: formatMoney(expenses, currency, locale),
                          icon: Icons.arrow_upward_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => context.push('/entry'),
            icon: const Icon(Icons.add_rounded),
            label: Text(s.t('addEntry')),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.t('recent'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: () => context.go('/transactions'),
                child: Text(s.t('all')),
              ),
            ],
          ),
          if (finance.transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text(s.t('empty'))),
            )
          else
            ...finance.transactions.take(5).map((entry) {
              final category = finance.categories
                  .where((c) => c.id == entry.categoryId)
                  .firstOrNull;
              return TransactionTile(
                transaction: entry,
                category: category,
                onTap: () => context.push('/entry/${entry.id}'),
              );
            }),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: Colors.white70, size: 19),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}
