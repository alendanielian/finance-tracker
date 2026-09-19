import 'dart:io';

import 'package:financetracker/blocs/budget_bloc.dart';
import 'package:financetracker/blocs/finance_bloc.dart';
import 'package:financetracker/models/budget.dart';
import 'package:financetracker/models/entry_type.dart';
import 'package:financetracker/models/transaction.dart';
import 'package:financetracker/blocs/settings_cubit.dart';
import 'package:financetracker/services/firebase_service.dart';
import 'package:financetracker/services/finance_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  test('first launch seeds once and transactions survive reopening', () async {
    final directory = await Directory.systemTemp.createTemp(
      'finance_store_test_',
    );
    try {
      final first = await FinanceStore.open(storagePath: directory.path);
      expect(first.categories, hasLength(5));
      expect(first.transactions.where((entry) => entry.isDemo), hasLength(2));
      await first.saveTransaction(
        FinanceTransaction(
          id: 'saved',
          amountMinor: 12345,
          title: 'Saved',
          type: EntryType.expense,
          occurredAt: DateTime(2026, 9, 18),
          categoryId: 'food',
          currencyCode: 'RUB',
        ),
      );
      await first.clearDemo();
      await Hive.close();

      final reopened = await FinanceStore.open(storagePath: directory.path);
      expect(reopened.telemetryConsent, isFalse);
      expect(reopened.categories, hasLength(5));
      expect(reopened.transactions, hasLength(1));
      expect(reopened.transactions.single.amountMinor, 12345);
      final telemetry = _RecordingTelemetry();
      final settings = SettingsCubit(reopened, telemetry: telemetry);
      await settings.setTelemetryConsent(true);
      expect(settings.state.telemetryConsent, isTrue);
      final finance = FinanceBloc(reopened, telemetry: telemetry);
      final budgets = BudgetBloc(reopened, telemetry: telemetry);
      await finance.saveTransaction(
        FinanceTransaction(
          id: 'second',
          amountMinor: 200,
          title: 'Second',
          type: EntryType.income,
          occurredAt: DateTime(2026, 9, 18),
          categoryId: 'salary',
          currencyCode: 'RUB',
        ),
      );
      expect(finance.state.transactions, hasLength(2));
      await finance.saveTransaction(finance.state.transactions.first);
      expect(telemetry.events, ['add_transaction']);
      await budgets.save(
        const MonthlyBudget(
          year: 2026,
          month: 9,
          currencyCode: 'RUB',
          limitMinor: 50000,
        ),
      );
      expect(budgets.state.single.limitMinor, 50000);
      expect(telemetry.events, ['add_transaction', 'set_budget']);
      await settings.setTelemetryConsent(false);
      expect(reopened.telemetryConsent, isFalse);
      await finance.close();
      await budgets.close();
      await settings.close();
      await Hive.close();
    } finally {
      await Hive.close();
      await directory.delete(recursive: true);
    }
  });
}

class _RecordingTelemetry extends TelemetryService {
  bool _enabled = false;
  final events = <String>[];

  @override
  bool get available => true;
  @override
  bool get enabled => _enabled;
  @override
  Future<void> setEnabled(bool value) async {
    _enabled = value;
  }

  @override
  void logAddTransaction() {
    if (enabled) events.add('add_transaction');
  }

  @override
  void logSetBudget() {
    if (enabled) events.add('set_budget');
  }

  @override
  void logScreenView(String screenName) {
    if (enabled) events.add('screen_view:$screenName');
  }

  @override
  void recordFlutterFatalError(FlutterErrorDetails details) {}
  @override
  bool recordPlatformError(Object error, StackTrace stack) => false;
}
