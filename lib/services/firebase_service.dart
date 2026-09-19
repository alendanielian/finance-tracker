import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Only fixed event and screen names cross this boundary. Financial values,
/// category names, transaction IDs, titles and notes never become parameters.
abstract class TelemetryService {
  const TelemetryService();

  bool get available;
  bool get enabled;
  Future<void> setEnabled(bool value);
  void logAddTransaction();
  void logSetBudget();
  void logScreenView(String screenName);
  void recordFlutterFatalError(FlutterErrorDetails details);
  bool recordPlatformError(Object error, StackTrace stack);
}

class NoopTelemetryService extends TelemetryService {
  const NoopTelemetryService();

  @override
  bool get available => false;
  @override
  bool get enabled => false;
  @override
  Future<void> setEnabled(bool value) async {}
  @override
  void logAddTransaction() {}
  @override
  void logSetBudget() {}
  @override
  void logScreenView(String screenName) {}
  @override
  void recordFlutterFatalError(FlutterErrorDetails details) {}
  @override
  bool recordPlatformError(Object error, StackTrace stack) => false;
}

class FirebaseService extends TelemetryService {
  FirebaseService._(this._available, this._enabled);

  static Future<FirebaseService> initialize({required bool consent}) async {
    try {
      await Firebase.initializeApp();
      final service = FirebaseService._(true, consent);
      await service._applyCollection(consent);
      return service;
    } catch (error) {
      // Local finance features must keep working if Firebase is unavailable.
      debugPrint('Firebase initialization unavailable: $error');
      return FirebaseService._(false, false);
    }
  }

  final bool _available;
  bool _enabled;

  @override
  bool get available => _available;
  @override
  bool get enabled => _available && _enabled;

  Future<void> _applyCollection(bool value) async {
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(value);
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(value);
    if (!value) {
      await FirebaseCrashlytics.instance.deleteUnsentReports();
      await FirebaseAnalytics.instance.resetAnalyticsData();
    }
  }

  @override
  Future<void> setEnabled(bool value) async {
    if (!_available) return;
    await _applyCollection(value);
    _enabled = value;
  }

  void _send(Future<void> future) {
    unawaited(_ignoreFailure(future));
  }

  Future<void> _ignoreFailure(Future<void> future) async {
    try {
      await future;
    } catch (error) {
      debugPrint('Firebase telemetry unavailable: $error');
    }
  }

  @override
  void logAddTransaction() {
    if (enabled) {
      _send(FirebaseAnalytics.instance.logEvent(name: 'add_transaction'));
    }
  }

  @override
  void logSetBudget() {
    if (enabled) _send(FirebaseAnalytics.instance.logEvent(name: 'set_budget'));
  }

  @override
  void logScreenView(String screenName) {
    if (enabled) {
      _send(FirebaseAnalytics.instance.logScreenView(screenName: screenName));
    }
  }

  @override
  void recordFlutterFatalError(FlutterErrorDetails details) {
    if (enabled) {
      _send(FirebaseCrashlytics.instance.recordFlutterFatalError(details));
    }
  }

  @override
  bool recordPlatformError(Object error, StackTrace stack) {
    if (!enabled) return false;
    _send(FirebaseCrashlytics.instance.recordError(error, stack, fatal: true));
    return true;
  }
}
