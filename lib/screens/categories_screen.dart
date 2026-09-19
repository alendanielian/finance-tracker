import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../blocs/finance_bloc.dart';
import '../l10n/app_strings.dart';
import '../models/category.dart';
import '../models/entry_type.dart';
import '../widgets/category_icon.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  Future<void> _add(BuildContext context) async {
    final s = AppStrings.of(context);
    var name = '';
    var type = EntryType.expense;
    final result = await showDialog<(String, EntryType)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(s.t('addCategory')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) => name = value,
                autofocus: true,
                maxLength: 28,
                decoration: InputDecoration(labelText: s.t('name')),
              ),
              SegmentedButton<EntryType>(
                segments: [
                  ButtonSegment(
                    value: EntryType.expense,
                    label: Text(s.t('expenses')),
                  ),
                  ButtonSegment(
                    value: EntryType.income,
                    label: Text(s.t('income')),
                  ),
                ],
                selected: {type},
                onSelectionChanged: (selection) =>
                    setDialogState(() => type = selection.first),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(s.t('cancel')),
            ),
            FilledButton(
              onPressed: () {
                if (name.trim().isNotEmpty) {
                  Navigator.pop(dialogContext, (name.trim(), type));
                }
              },
              child: Text(s.t('add')),
            ),
          ],
        ),
      ),
    );
    if (result == null || !context.mounted) return;
    await context.read<FinanceBloc>().saveCategory(
      FinanceCategory(
        id: const Uuid().v4(),
        name: result.$1,
        iconCode: 'other',
        colorValue: result.$2 == EntryType.expense ? 0xFF9E82DD : 0xFF57AF87,
        type: result.$2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final categories = context.watch<FinanceBloc>().state.categories;
    return Scaffold(
      appBar: AppBar(title: Text(s.t('categories'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Icons.add),
        label: Text(s.t('addCategory')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        children: [
          for (final category in categories)
            ListTile(
              leading: CategoryIcon(category),
              title: Text(
                category.displayName(locale),
                style: category.isArchived
                    ? const TextStyle(decoration: TextDecoration.lineThrough)
                    : null,
              ),
              subtitle: Text(
                category.type == EntryType.expense
                    ? s.t('expenses')
                    : s.t('income'),
              ),
              trailing: IconButton(
                tooltip: category.isArchived ? s.t('add') : s.t('archive'),
                icon: Icon(
                  category.isArchived
                      ? Icons.unarchive_outlined
                      : Icons.archive_outlined,
                ),
                onPressed: () => context.read<FinanceBloc>().saveCategory(
                  category.copyWith(isArchived: !category.isArchived),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
