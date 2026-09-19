import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/finance_store.dart';
import '../services/firebase_service.dart';

class AppSettings {
  const AppSettings(this.localeCode, this.currencyCode, this.telemetryConsent);
  final String localeCode;
  final String currencyCode;
  final bool telemetryConsent;
}

class SettingsCubit extends Cubit<AppSettings> {
  SettingsCubit(this._store, {this.telemetry = const NoopTelemetryService()})
    : super(
        AppSettings(
          _store.localeCode,
          _store.currencyCode,
          _store.telemetryConsent,
        ),
      );
  final FinanceStore _store;
  final TelemetryService telemetry;

  bool get telemetryAvailable => telemetry.available;

  Future<void> setLocale(String value) async {
    await _store.setLocale(value);
    emit(AppSettings(value, state.currencyCode, state.telemetryConsent));
  }

  Future<void> setCurrency(String value) async {
    await _store.setCurrency(value);
    emit(AppSettings(state.localeCode, value, state.telemetryConsent));
  }

  Future<void> setTelemetryConsent(bool value) async {
    if (!telemetry.available) return;
    await telemetry.setEnabled(value);
    await _store.setTelemetryConsent(value);
    emit(AppSettings(state.localeCode, state.currencyCode, value));
  }
}
