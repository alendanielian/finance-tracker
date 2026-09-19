import '../models/entry_type.dart';
import '../models/transaction.dart';

class FinanceMetrics {
  const FinanceMetrics._();

  static List<FinanceTransaction> inCurrency(
    Iterable<FinanceTransaction> entries,
    String currency,
  ) => entries.where((e) => e.currencyCode == currency).toList();

  static List<FinanceTransaction> inMonth(
    Iterable<FinanceTransaction> entries,
    DateTime month,
    String currency,
  ) => entries
      .where(
        (e) =>
            e.currencyCode == currency &&
            e.occurredAt.year == month.year &&
            e.occurredAt.month == month.month,
      )
      .toList();

  static int total(Iterable<FinanceTransaction> entries, EntryType type) =>
      entries
          .where((e) => e.type == type)
          .fold(0, (sum, e) => sum + e.amountMinor);

  static int balance(Iterable<FinanceTransaction> entries) =>
      total(entries, EntryType.income) - total(entries, EntryType.expense);

  static Map<String, int> expenseByCategory(
    Iterable<FinanceTransaction> entries,
  ) {
    final result = <String, int>{};
    for (final entry in entries.where((e) => e.type == EntryType.expense)) {
      result.update(
        entry.categoryId,
        (amount) => amount + entry.amountMinor,
        ifAbsent: () => entry.amountMinor,
      );
    }
    return result;
  }
}
