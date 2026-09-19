import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../blocs/finance_bloc.dart';
import '../blocs/settings_cubit.dart';
import '../l10n/app_strings.dart';
import '../models/entry_type.dart';
import '../models/transaction.dart';
import '../services/money.dart';
import '../widgets/category_icon.dart';

class TransactionFormScreen extends StatefulWidget {
  const TransactionFormScreen({super.key, this.id});
  final String? id;

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  EntryType _type = EntryType.expense;
  DateTime _date = DateTime.now();
  String? _categoryId;
  FinanceTransaction? _original;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.id == null || _original != null) return;
    final items = context.read<FinanceBloc>().state.transactions;
    _original = items.where((e) => e.id == widget.id).firstOrNull;
    final value = _original;
    if (value != null) {
      _type = value.type;
      _date = value.occurredAt;
      _categoryId = value.categoryId;
      _titleController.text = value.title;
      _noteController.text = value.note;
      final digits = currencyDigits(value.currencyCode);
      final whole = digits == 0 ? value.amountMinor : value.amountMinor ~/ 100;
      final fraction = digits == 0
          ? ''
          : '.${(value.amountMinor % 100).toString().padLeft(2, '0')}';
      _amountController.text = '$whole$fraction';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _categoryId == null) {
      if (_categoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context).t('selectCategory'))),
        );
      }
      return;
    }
    final settings = context.read<SettingsCubit>().state;
    final currency = _original?.currencyCode ?? settings.currencyCode;
    final amount = parseMoney(_amountController.text, currency)!;
    setState(() => _saving = true);
    final value = FinanceTransaction(
      id: _original?.id ?? const Uuid().v4(),
      amountMinor: amount,
      title: _titleController.text.trim(),
      type: _type,
      occurredAt: _date,
      categoryId: _categoryId!,
      currencyCode: currency,
      note: _noteController.text.trim(),
      isDemo: false,
    );
    await context.read<FinanceBloc>().saveTransaction(value);
    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    final s = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.t('confirmDelete')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.t('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<FinanceBloc>().deleteTransaction(_original!.id);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final finance = context.watch<FinanceBloc>().state;
    final currency =
        _original?.currencyCode ??
        context.watch<SettingsCubit>().state.currencyCode;
    final categories = finance.categories
        .where((c) => c.type == _type && (!c.isArchived || c.id == _categoryId))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.t(widget.id == null ? 'addEntry' : 'editEntry')),
        actions: [
          if (_original != null)
            IconButton(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
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
              selected: {_type},
              onSelectionChanged: (selection) => setState(() {
                _type = selection.first;
                _categoryId = null;
              }),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _amountController,
              autofocus: widget.id == null,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: s.t('amount'),
                suffixText: currency,
              ),
              validator: (value) => parseMoney(value ?? '', currency) == null
                  ? s.t('invalidAmount')
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(labelText: s.t('title')),
              validator: (value) => value == null || value.trim().isEmpty
                  ? s.t('required')
                  : null,
            ),
            const SizedBox(height: 20),
            Text(
              s.t('category'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in categories)
                  ChoiceChip(
                    avatar: CategoryIcon(category, size: 27),
                    label: Text(category.displayName(locale)),
                    selected: _categoryId == category.id,
                    onSelected: (_) =>
                        setState(() => _categoryId = category.id),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  initialDate: _date,
                );
                if (picked != null) setState(() => _date = picked);
              },
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(
                '${s.t('date')}: ${DateFormat.yMMMd(locale).format(_date)}',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(labelText: s.t('note')),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(s.t('save')),
            ),
          ],
        ),
      ),
    );
  }
}
