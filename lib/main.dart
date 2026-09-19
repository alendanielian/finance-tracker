import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'blocs/budget_bloc.dart';
import 'blocs/finance_bloc.dart';
import 'blocs/settings_cubit.dart';
import 'l10n/app_strings.dart';
import 'screens/analytics_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/home_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/transaction_form_screen.dart';
import 'screens/transactions_screen.dart';
import 'services/finance_store.dart';
import 'services/firebase_service.dart';
import 'theme/app_theme.dart';
import 'widgets/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await FinanceStore.open();
  final telemetry = await FirebaseService.initialize(
    consent: store.telemetryConsent,
  );
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    telemetry.recordFlutterFatalError(details);
  };
  PlatformDispatcher.instance.onError = telemetry.recordPlatformError;
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => FinanceBloc(store, telemetry: telemetry)),
        BlocProvider(create: (_) => BudgetBloc(store, telemetry: telemetry)),
        BlocProvider(create: (_) => SettingsCubit(store, telemetry: telemetry)),
      ],
      child: FinanceApp(telemetry: telemetry),
    ),
  );
}

class FinanceApp extends StatefulWidget {
  const FinanceApp({super.key, this.telemetry = const NoopTelemetryService()});

  final TelemetryService telemetry;

  @override
  State<FinanceApp> createState() => _FinanceAppState();
}

class _FinanceAppState extends State<FinanceApp> {
  late final GoRouter _router = GoRouter(
    onEnter: (_, _, next, _) => Allow(
      then: () {
        final screenName = _screenName(next.uri.path);
        if (screenName != null) widget.telemetry.logScreenView(screenName);
      },
    ),
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(path: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
          GoRoute(
            path: '/transactions',
            builder: (_, _) => const TransactionsScreen(),
          ),
          GoRoute(
            path: '/analytics',
            builder: (_, _) => const AnalyticsScreen(),
          ),
          GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
        ],
      ),
      GoRoute(path: '/entry', builder: (_, _) => const TransactionFormScreen()),
      GoRoute(
        path: '/entry/:id',
        builder: (_, state) =>
            TransactionFormScreen(id: state.pathParameters['id']),
      ),
      GoRoute(path: '/privacy', builder: (_, _) => const PrivacyPolicyScreen()),
      GoRoute(path: '/categories', builder: (_, _) => const CategoriesScreen()),
    ],
  );

  String? _screenName(String path) {
    if (path.startsWith('/entry/')) return 'edit_transaction';
    return switch (path) {
      '/' => 'home',
      '/transactions' => 'transactions',
      '/analytics' => 'analytics',
      '/settings' => 'settings',
      '/entry' => 'add_transaction',
      '/privacy' => 'privacy',
      '/categories' => 'categories',
      _ => null,
    };
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<SettingsCubit, AppSettings>(
    builder: (context, settings) => MaterialApp.router(
      title: AppStrings(settings.localeCode).t('app'),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
      locale: Locale(settings.localeCode),
      supportedLocales: const [Locale('ru'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    ),
  );
}
