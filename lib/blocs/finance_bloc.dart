import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/category.dart';
import '../models/transaction.dart';
import '../services/finance_store.dart';
import '../services/firebase_service.dart';

class FinanceState {
  const FinanceState(this.categories, this.transactions);
  final List<FinanceCategory> categories;
  final List<FinanceTransaction> transactions;
}

sealed class FinanceEvent {
  FinanceEvent();
  final Completer<void> done = Completer<void>();
}

final class SaveTransactionRequested extends FinanceEvent {
  SaveTransactionRequested(this.value);
  final FinanceTransaction value;
}

final class DeleteTransactionRequested extends FinanceEvent {
  DeleteTransactionRequested(this.id);
  final String id;
}

final class SaveCategoryRequested extends FinanceEvent {
  SaveCategoryRequested(this.value);
  final FinanceCategory value;
}

final class ClearDemoRequested extends FinanceEvent {}

class FinanceBloc extends Bloc<FinanceEvent, FinanceState> {
  FinanceBloc(this._store, {this.telemetry = const NoopTelemetryService()})
    : super(FinanceState(_store.categories, _store.transactions)) {
    on<SaveTransactionRequested>(
      (event, emit) => _run(event, emit, () async {
        final isNew = !_store.transactions.any(
          (item) => item.id == event.value.id,
        );
        await _store.saveTransaction(event.value);
        if (isNew) telemetry.logAddTransaction();
      }),
    );
    on<DeleteTransactionRequested>(
      (event, emit) =>
          _run(event, emit, () => _store.deleteTransaction(event.id)),
    );
    on<SaveCategoryRequested>(
      (event, emit) =>
          _run(event, emit, () => _store.saveCategory(event.value)),
    );
    on<ClearDemoRequested>(
      (event, emit) => _run(event, emit, _store.clearDemo),
    );
  }

  final FinanceStore _store;
  final TelemetryService telemetry;

  Future<void> _run(
    FinanceEvent event,
    Emitter<FinanceState> emit,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      emit(FinanceState(_store.categories, _store.transactions));
      event.done.complete();
    } catch (error, stackTrace) {
      event.done.completeError(error, stackTrace);
    }
  }

  Future<void> saveTransaction(FinanceTransaction value) {
    final event = SaveTransactionRequested(value);
    add(event);
    return event.done.future;
  }

  Future<void> deleteTransaction(String id) {
    final event = DeleteTransactionRequested(id);
    add(event);
    return event.done.future;
  }

  Future<void> saveCategory(FinanceCategory value) {
    final event = SaveCategoryRequested(value);
    add(event);
    return event.done.future;
  }

  Future<void> clearDemo() {
    final event = ClearDemoRequested();
    add(event);
    return event.done.future;
  }
}
