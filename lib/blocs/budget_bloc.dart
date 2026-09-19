import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/budget.dart';
import '../services/finance_store.dart';
import '../services/firebase_service.dart';

class SaveBudgetRequested {
  SaveBudgetRequested(this.budget);
  final MonthlyBudget budget;
  final Completer<void> done = Completer<void>();
}

class BudgetBloc extends Bloc<SaveBudgetRequested, List<MonthlyBudget>> {
  BudgetBloc(this._store, {this.telemetry = const NoopTelemetryService()})
    : super(_store.budgets) {
    on<SaveBudgetRequested>((event, emit) async {
      try {
        await _store.saveBudget(event.budget);
        telemetry.logSetBudget();
        emit(_store.budgets);
        event.done.complete();
      } catch (error, stackTrace) {
        event.done.completeError(error, stackTrace);
      }
    });
  }
  final FinanceStore _store;
  final TelemetryService telemetry;

  Future<void> save(MonthlyBudget budget) {
    final event = SaveBudgetRequested(budget);
    add(event);
    return event.done.future;
  }
}
