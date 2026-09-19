import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../models/category.dart';
import '../models/entry_type.dart';
import '../models/transaction.dart';
import '../services/money.dart';
import 'category_icon.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.category,
    this.onTap,
  });
  final FinanceTransaction transaction;
  final FinanceCategory? category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final positive = transaction.type == EntryType.income;
    final amount = formatMoney(
      transaction.amountMinor,
      transaction.currencyCode,
      locale,
    );
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      leading: CategoryIcon(category),
      title: Text(
        transaction.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${category?.displayName(locale) ?? AppStrings.of(context).t('category')} · ${DateFormat.MMMd(locale).format(transaction.occurredAt)}${transaction.isDemo ? ' · Demo' : ''}',
      ),
      trailing: Text(
        '${positive ? '+' : '−'}$amount',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: positive ? const Color(0xFF13845F) : null,
        ),
      ),
      onTap: onTap,
    );
  }
}
