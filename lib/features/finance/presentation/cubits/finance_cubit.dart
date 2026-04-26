import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/pay_period.dart';
import '../../domain/usecases/finance_usecases.dart';

// ── State ─────────────────────────────────────────────────────────────────────

enum FinanceStatus { initial, loading, loaded, error }

class FinanceState extends Equatable {
  const FinanceState({
    this.status = FinanceStatus.initial,
    this.periods = const [],
    this.selectedYear,
    this.errorMessage,
  });

  final FinanceStatus status;
  final List<PayPeriod> periods;
  final int? selectedYear;
  final String? errorMessage;

  int get currentYear => selectedYear ?? DateTime.now().year;

  List<PayPeriod> get periodsForYear => periods
      .where((p) => p.periodStart.year == currentYear)
      .toList();

  double get totalExpectedYear => periodsForYear
      .where((p) => !p.isPaid)
      .fold(0, (sum, p) => sum + p.calculatedExpected);

  double get totalActualYear =>
      periodsForYear.fold(0, (sum, p) => sum + (p.totalActual ?? 0));

  double get totalPendingYear => periodsForYear
      .where((p) => !p.isPaid)
      .fold(0, (sum, p) => sum + p.calculatedExpected);

  double get totalEarnedYear => periodsForYear
      .fold(0, (sum, p) => sum + p.calculatedExpected);

  int get paidPeriodsCount =>
      periodsForYear.where((p) => p.isPaid).length;

  // Monthly breakdown for chart — returns 12 values Jan–Dec
  List<double> get monthlyExpected {
    return List.generate(12, (i) {
      final month = i + 1;
      return periodsForYear
          .where((p) => p.periodStart.month == month)
          .fold(0.0, (sum, p) => sum + p.calculatedExpected);
    });
  }

  List<double> get monthlyActual {
    return List.generate(12, (i) {
      final month = i + 1;
      return periodsForYear
          .where((p) => p.periodStart.month == month && p.isPaid)
          .fold(0.0, (sum, p) => sum + (p.totalActual ?? 0));
    });
  }

  FinanceState copyWith({
    FinanceStatus? status,
    List<PayPeriod>? periods,
    int? selectedYear,
    String? errorMessage,
  }) {
    return FinanceState(
      status: status ?? this.status,
      periods: periods ?? this.periods,
      selectedYear: selectedYear ?? this.selectedYear,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, periods, selectedYear, errorMessage];
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

class FinanceCubit extends Cubit<FinanceState> {
  FinanceCubit({
    required GetPayPeriodsUseCase getPayPeriods,
    required AddPayPeriodUseCase addPayPeriod,
    required UpdatePayPeriodUseCase updatePayPeriod,
    required DeletePayPeriodUseCase deletePayPeriod,
  })  : _getPayPeriods = getPayPeriods,
        _addPayPeriod = addPayPeriod,
        _updatePayPeriod = updatePayPeriod,
        _deletePayPeriod = deletePayPeriod,
        super(FinanceState(selectedYear: DateTime.now().year));

  final GetPayPeriodsUseCase _getPayPeriods;
  final AddPayPeriodUseCase _addPayPeriod;
  final UpdatePayPeriodUseCase _updatePayPeriod;
  final DeletePayPeriodUseCase _deletePayPeriod;
  static const _uuid = Uuid();

  String? _currentWorkerId;

  Future<void> loadPeriods(String workerId) async {
    _currentWorkerId = workerId;
    emit(state.copyWith(status: FinanceStatus.loading));

    final result = await _getPayPeriods(workerId);
    result.fold(
          (f) => emit(state.copyWith(
        status: FinanceStatus.error,
        errorMessage: f.message,
      )),
          (periods) => emit(state.copyWith(
        status: FinanceStatus.loaded,
        periods: periods,
      )),
    );
  }

  Future<void> addPayPeriod({
    required DateTime start,
    required DateTime end,
    required double dailyRate,
    String? rigName,
  }) async {
    // If no worker loaded yet, get it from the first available worker
    if (_currentWorkerId == null) {
      emit(state.copyWith(errorMessage: 'No worker selected. Please select a worker first.'));
      return;
    }

    final days = end.difference(start).inDays + 1;
    final period = PayPeriod(
      id: _uuid.v4(),
      workerId: _currentWorkerId!,
      periodStart: start,
      periodEnd: end,
      dailyRate: dailyRate,
      totalExpected: dailyRate * days,
    );

    final result = await _addPayPeriod(period);
    result.fold(
          (f) => emit(state.copyWith(errorMessage: f.message)),
          (added) => emit(state.copyWith(
        periods: [...state.periods, added],
      )),
    );
  }

  Future<void> markAsPaid(String periodId, double actualAmount) async {
    final period = state.periods.firstWhere((p) => p.id == periodId);
    final updated = PayPeriod(
      id: period.id,
      workerId: period.workerId,
      periodStart: period.periodStart,
      periodEnd: period.periodEnd,
      dailyRate: period.dailyRate,
      totalExpected: period.totalExpected,
      totalActual: actualAmount,
      isPaid: true,
    );

    final result = await _updatePayPeriod(updated);
    result.fold(
          (f) => emit(state.copyWith(errorMessage: f.message)),
          (p) {
        final updatedList = state.periods
            .map((e) => e.id == p.id ? p : e)
            .toList();
        emit(state.copyWith(periods: updatedList));
      },
    );
  }

  Future<void> deletePayPeriod(String periodId) async {
    final result = await _deletePayPeriod(periodId);
    result.fold(
          (f) => emit(state.copyWith(errorMessage: f.message)),
          (_) => emit(state.copyWith(
        periods: state.periods.where((p) => p.id != periodId).toList(),
      )),
    );
  }

  void changeYear(int year) {
    emit(state.copyWith(selectedYear: year));
  }
}