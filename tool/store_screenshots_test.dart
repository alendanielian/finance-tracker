import 'dart:io';
import 'dart:ui' as ui;

import 'package:financetracker/blocs/budget_bloc.dart';
import 'package:financetracker/blocs/finance_bloc.dart';
import 'package:financetracker/blocs/settings_cubit.dart';
import 'package:financetracker/main.dart';
import 'package:financetracker/models/budget.dart';
import 'package:financetracker/models/entry_type.dart';
import 'package:financetracker/models/transaction.dart';
import 'package:financetracker/services/finance_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  testWidgets('generate real UI screenshots for Google Play', (tester) async {
    final setup = await tester.runAsync(() async {
      final directory = await Directory.systemTemp.createTemp(
        'finance_store_screenshots_',
      );
      final store = await FinanceStore.open(storagePath: directory.path);
      await _seedStore(store);
      return (directory, store);
    });
    final (directory, store) = setup!;
    final fontBytes = File(r'C:\Windows\Fonts\segoeui.ttf').readAsBytesSync();
    final fontLoader = FontLoader('Roboto')
      ..addFont(Future.value(ByteData.sublistView(fontBytes)));
    await tester.runAsync(fontLoader.load);
    final iconBytes = File(
      r'C:\development\flutter\bin\cache\artifacts\material_fonts\MaterialIcons-Regular.otf',
    ).readAsBytesSync();
    final iconFontLoader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(iconBytes)));
    await tester.runAsync(iconFontLoader.load);
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final captureKey = GlobalKey();
    final output = Directory(
      '${Directory.current.path}${Platform.pathSeparator}store_assets'
      '${Platform.pathSeparator}screenshots${Platform.pathSeparator}raw',
    );
    output.createSync(recursive: true);

    try {
      await tester.pumpWidget(
        RepaintBoundary(
          key: captureKey,
          child: MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => FinanceBloc(store)),
              BlocProvider(create: (_) => BudgetBloc(store)),
              BlocProvider(create: (_) => SettingsCubit(store)),
            ],
            child: const FinanceApp(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 800));

      await _capture(tester, captureKey, output, '01_home.png');

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.enterText(find.byType(TextFormField).at(0), '1250');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Ужин с друзьями',
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'Еда'));
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(milliseconds: 300));
      await _capture(tester, captureKey, output, '02_add_expense.png');

      await tester.tap(find.byTooltip('Назад'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byIcon(Icons.pie_chart_outline));
      await tester.pump(const Duration(milliseconds: 800));
      await _capture(tester, captureKey, output, '03_budget.png');

      await tester.drag(find.byType(ListView), const Offset(0, -260));
      await tester.pump(const Duration(milliseconds: 500));
      await _capture(tester, captureKey, output, '04_analytics.png');

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pump(const Duration(milliseconds: 500));
      await _capture(tester, captureKey, output, '05_privacy.png');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    } finally {
      await tester.runAsync(() async {
        await Hive.close();
        await directory.delete(recursive: true);
      });
    }
  });
}

Future<void> _seedStore(FinanceStore store) async {
  await store.clearDemo();
  await store.setLocale('ru');
  await store.setCurrency('RUB');
  final now = DateTime.now();
  final entries = [
    FinanceTransaction(
      id: 'store-salary',
      amountMinor: 15000000,
      title: 'Зарплата',
      type: EntryType.income,
      occurredAt: now.subtract(const Duration(days: 5)),
      categoryId: 'salary',
      currencyCode: 'RUB',
      note: 'За текущий месяц',
    ),
    FinanceTransaction(
      id: 'store-groceries',
      amountMinor: 485000,
      title: 'Продукты на неделю',
      type: EntryType.expense,
      occurredAt: now.subtract(const Duration(hours: 3)),
      categoryId: 'food',
      currencyCode: 'RUB',
    ),
    FinanceTransaction(
      id: 'store-shopping',
      amountMinor: 640000,
      title: 'Покупки для дома',
      type: EntryType.expense,
      occurredAt: now.subtract(const Duration(days: 1)),
      categoryId: 'shopping',
      currencyCode: 'RUB',
    ),
    FinanceTransaction(
      id: 'store-bills',
      amountMinor: 320000,
      title: 'Интернет и связь',
      type: EntryType.expense,
      occurredAt: now.subtract(const Duration(days: 2)),
      categoryId: 'bills',
      currencyCode: 'RUB',
    ),
    FinanceTransaction(
      id: 'store-taxi',
      amountMinor: 178000,
      title: 'Такси',
      type: EntryType.expense,
      occurredAt: now.subtract(const Duration(days: 3)),
      categoryId: 'transport',
      currencyCode: 'RUB',
    ),
  ];
  for (final entry in entries) {
    await store.saveTransaction(entry);
  }
  await store.saveBudget(
    MonthlyBudget(
      year: now.year,
      month: now.month,
      currencyCode: 'RUB',
      limitMinor: 3000000,
    ),
  );
}

Future<void> _capture(
  WidgetTester tester,
  GlobalKey key,
  Directory output,
  String fileName,
) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw StateError('Could not encode $fileName');
    await File('${output.path}${Platform.pathSeparator}$fileName')
        .writeAsBytes(data.buffer.asUint8List());
    image.dispose();
  });
}
