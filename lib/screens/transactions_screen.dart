import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../blocs/finance_bloc.dart';
import '../l10n/app_strings.dart';
import '../models/entry_type.dart';
import '../models/transaction.dart';
import '../widgets/transaction_tile.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  EntryType? _filter;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final finance = context.watch<FinanceBloc>().state;
    final shown = finance.transactions.where((e) {
      final matchesType = _filter == null || e.type == _filter;
      final matchesQuery = '${e.title} ${e.note}'.toLowerCase().contains(
        _query.toLowerCase(),
      );
      return matchesType && matchesQuery;
    }).toList();
    final groups = <DateTime, List<FinanceTransaction>>{};
    for (final entry in shown) {
      final day = DateTime(
        entry.occurredAt.year,
        entry.occurredAt.month,
        entry.occurredAt.day,
      );
      groups.putIfAbsent(day, () => []).add(entry);
    }

    return Scaffold(
      appBar: AppBar(title: Text(s.t('history'))),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/entry'),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        children: [
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: s.t('search'),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(s.t('all')),
                selected: _filter == null,
                onSelected: (_) => setState(() => _filter = null),
              ),
              ChoiceChip(
                label: Text(s.t('expenses')),
                selected: _filter == EntryType.expense,
                onSelected: (_) => setState(() => _filter = EntryType.expense),
              ),
              ChoiceChip(
                label: Text(s.t('income')),
                selected: _filter == EntryType.income,
                onSelected: (_) => setState(() => _filter = EntryType.income),
              ),
            ],
          ),
          if (groups.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text(s.t('emptySearch'))),
            ),
          for (final group in groups.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 20, 4, 4),
              child: Text(
                DateFormat.yMMMMd(locale).format(group.key),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final entry in group.value)
              TransactionTile(
                transaction: entry,
                category: finance.categories
                    .where((c) => c.id == entry.categoryId)
                    .firstOrNull,
                onTap: () => context.push('/entry/${entry.id}'),
              ),
          ],
        ],
      ),
    );
  }
}
