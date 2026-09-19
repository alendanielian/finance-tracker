import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../models/budget.dart';
import '../models/category.dart';
import '../models/entry_type.dart';
import '../models/transaction.dart';

class FinanceStore {
  FinanceStore._(
    this._categories,
    this._transactions,
    this._budgets,
    this._settings,
  );

  final Box<dynamic> _categories;
  final Box<dynamic> _transactions;
  final Box<dynamic> _budgets;
  final Box<dynamic> _settings;

  static Future<FinanceStore> open({String? storagePath}) async {
    if (storagePath == null) {
      await Hive.initFlutter();
    } else {
      Hive.init(storagePath);
    }
    final store = FinanceStore._(
      await Hive.openBox<dynamic>('categories_v1'),
      await Hive.openBox<dynamic>('transactions_v1'),
      await Hive.openBox<dynamic>('budgets_v1'),
      await Hive.openBox<dynamic>('settings_v1'),
    );
    await store._seedOnce();
    return store;
  }

  List<FinanceCategory> get categories => _categories.values
      .map((value) => FinanceCategory.fromMap(value as Map<dynamic, dynamic>))
      .toList();

  List<FinanceTransaction> get transactions =>
      _transactions.values
          .map(
            (value) =>
                FinanceTransaction.fromMap(value as Map<dynamic, dynamic>),
          )
          .toList()
        ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

  List<MonthlyBudget> get budgets => _budgets.values
      .map((value) => MonthlyBudget.fromMap(value as Map<dynamic, dynamic>))
      .toList();

  String get localeCode =>
      _settings.get('localeCode', defaultValue: 'ru') as String;
  String get currencyCode =>
      _settings.get('currencyCode', defaultValue: 'RUB') as String;
  bool get telemetryConsent =>
      _settings.get('telemetryConsent', defaultValue: false) as bool;

  Future<void> saveCategory(FinanceCategory category) =>
      _categories.put(category.id, category.toMap());
  Future<void> saveTransaction(FinanceTransaction transaction) =>
      _transactions.put(transaction.id, transaction.toMap());
  Future<void> deleteTransaction(String id) => _transactions.delete(id);
  Future<void> saveBudget(MonthlyBudget budget) =>
      _budgets.put(budget.id, budget.toMap());
  Future<void> setLocale(String value) => _settings.put('localeCode', value);
  Future<void> setCurrency(String value) =>
      _settings.put('currencyCode', value);
  Future<void> setTelemetryConsent(bool value) =>
      _settings.put('telemetryConsent', value);

  Future<void> clearDemo() async {
    final ids = transactions.where((t) => t.isDemo).map((t) => t.id);
    await _transactions.deleteAll(ids);
  }

  Future<void> _seedOnce() async {
    if (_settings.get('seeded', defaultValue: false) == true) return;
    const initial = [
      FinanceCategory(
        id: 'food',
        name: 'Еда',
        iconCode: 'food',
        colorValue: 0xFFFFB257,
        type: EntryType.expense,
      ),
      FinanceCategory(
        id: 'transport',
        name: 'Транспорт',
        iconCode: 'transport',
        colorValue: 0xFF7D9EEB,
        type: EntryType.expense,
      ),
      FinanceCategory(
        id: 'shopping',
        name: 'Покупки',
        iconCode: 'shopping',
        colorValue: 0xFFC694E8,
        type: EntryType.expense,
      ),
      FinanceCategory(
        id: 'bills',
        name: 'Счета',
        iconCode: 'bills',
        colorValue: 0xFF65C8BE,
        type: EntryType.expense,
      ),
      FinanceCategory(
        id: 'salary',
        name: 'Зарплата',
        iconCode: 'salary',
        colorValue: 0xFF71C486,
        type: EntryType.income,
      ),
    ];
    for (final category in initial) {
      await saveCategory(category);
    }
    final now = DateTime.now();
    await saveTransaction(
      FinanceTransaction(
        id: 'demo-salary',
        amountMinor: 12000000,
        title: 'Пример: зарплата',
        type: EntryType.income,
        occurredAt: now.subtract(const Duration(days: 2)),
        categoryId: 'salary',
        currencyCode: 'RUB',
        isDemo: true,
      ),
    );
    await saveTransaction(
      FinanceTransaction(
        id: 'demo-food',
        amountMinor: 185000,
        title: 'Пример: продукты',
        type: EntryType.expense,
        occurredAt: now.subtract(const Duration(days: 1)),
        categoryId: 'food',
        currencyCode: 'RUB',
        isDemo: true,
      ),
    );
    await _settings.put('seeded', true);
  }
}
