import 'dart:io';

import 'package:financetracker/blocs/budget_bloc.dart';
import 'package:financetracker/blocs/finance_bloc.dart';
import 'package:financetracker/blocs/settings_cubit.dart';
import 'package:financetracker/main.dart';
import 'package:financetracker/models/budget.dart';
import 'package:financetracker/services/finance_store.dart';
import 'package:financetracker/services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  testWidgets('home, history and budget dialog work', (tester) async {
    final setup = await tester.runAsync(() async {
      final directory = await Directory.systemTemp.createTemp(
        'finance_ui_test_',
      );
      final store = await FinanceStore.open(storagePath: directory.path);
      return (directory, store);
    });
    final (directory, store) = setup!;
    final telemetry = _ScreenTelemetry();
    final budgets = _ImmediateBudgetBloc(store);
    try {
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => FinanceBloc(store)),
            BlocProvider<BudgetBloc>(create: (_) => budgets),
            BlocProvider(create: (_) => SettingsCubit(store)),
          ],
          child: FinanceApp(telemetry: telemetry),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Это демонстрационные операции'), findsOneWidget);
      expect(find.text('Последние операции'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.receipt_long_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Поиск по названию и заметке'), findsOneWidget);
      expect(telemetry.screens, contains('transactions'));

      await tester.tap(find.byIcon(Icons.pie_chart_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Установить лимит'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '5000');
      await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(budgets.state.single.limitMinor, 500000);
      expect(find.text('Лимит ещё не задан'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    } finally {
      await tester.runAsync(() async {
        await Hive.close();
        await directory.delete(recursive: true);
      });
    }
  });
}

class _ScreenTelemetry extends NoopTelemetryService {
  final screens = <String>[];

  @override
  void logScreenView(String screenName) => screens.add(screenName);
}

class _ImmediateBudgetBloc extends BudgetBloc {
  _ImmediateBudgetBloc(super.store);

  @override
  Future<void> save(MonthlyBudget budget) async {
    emit([budget]);
  }
}
