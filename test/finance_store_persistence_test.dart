import 'dart:io';

import 'package:financetracker/models/budget.dart';
import 'package:financetracker/models/entry_type.dart';
import 'package:financetracker/models/transaction.dart';
import 'package:financetracker/services/finance_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  test('transactions and budgets survive closing and reopening Hive', () async {
    final directory = await Directory.systemTemp.createTemp(
      'finance_persistence_test_',
    );
    try {
      final store = await FinanceStore.open(storagePath: directory.path);
      await store.clearDemo();
      await store.saveTransaction(
        FinanceTransaction(
          id: 'persistent-transaction',
          amountMinor: 123450,
          title: 'Офлайн-покупка',
          type: EntryType.expense,
          occurredAt: DateTime(2026, 9, 19, 12),
          categoryId: 'food',
          currencyCode: 'RUB',
          note: 'Сохранено без сети',
        ),
      );
      await store.saveBudget(
        const MonthlyBudget(
          year: 2026,
          month: 9,
          currencyCode: 'RUB',
          limitMinor: 5000000,
        ),
      );
      await Hive.close();

      final reopened = await FinanceStore.open(storagePath: directory.path);
      final transaction = reopened.transactions.singleWhere(
        (item) => item.id == 'persistent-transaction',
      );
      final budget = reopened.budgets.singleWhere(
        (item) => item.id == '2026-9-RUB',
      );

      expect(transaction.amountMinor, 123450);
      expect(transaction.title, 'Офлайн-покупка');
      expect(transaction.note, 'Сохранено без сети');
      expect(budget.limitMinor, 5000000);
    } finally {
      await Hive.close();
      if (directory.existsSync()) directory.deleteSync(recursive: true);
    }
  });
}
