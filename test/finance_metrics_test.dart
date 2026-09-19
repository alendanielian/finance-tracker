import 'package:financetracker/models/entry_type.dart';
import 'package:financetracker/models/transaction.dart';
import 'package:financetracker/services/finance_metrics.dart';
import 'package:financetracker/services/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FinanceTransaction entry(
    String id,
    int amount,
    EntryType type,
    DateTime date,
    String currency,
    String category,
  ) => FinanceTransaction(
    id: id,
    amountMinor: amount,
    title: id,
    type: type,
    occurredAt: date,
    categoryId: category,
    currencyCode: currency,
  );

  test('monthly totals exclude other months and currencies', () {
    final entries = [
      entry(
        'salary',
        100000,
        EntryType.income,
        DateTime(2026, 9, 1),
        'RUB',
        'salary',
      ),
      entry(
        'food',
        25000,
        EntryType.expense,
        DateTime(2026, 9, 18),
        'RUB',
        'food',
      ),
      entry(
        'old',
        5000,
        EntryType.expense,
        DateTime(2026, 8, 31),
        'RUB',
        'food',
      ),
      entry(
        'foreign',
        9000,
        EntryType.expense,
        DateTime(2026, 9, 18),
        'USD',
        'food',
      ),
    ];
    final current = FinanceMetrics.inMonth(entries, DateTime(2026, 9), 'RUB');
    expect(FinanceMetrics.total(current, EntryType.income), 100000);
    expect(FinanceMetrics.total(current, EntryType.expense), 25000);
    expect(FinanceMetrics.balance(current), 75000);
    expect(FinanceMetrics.expenseByCategory(current), {'food': 25000});
  });

  test('money parsing respects currency minor units', () {
    expect(parseMoney('123,45', 'RUB'), 12345);
    expect(parseMoney('123.456', 'RUB'), isNull);
    expect(parseMoney('123', 'AMD'), 123);
    expect(parseMoney('123.5', 'AMD'), isNull);
    expect(parseMoney('0', 'USD'), isNull);
  });
}
