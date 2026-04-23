import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../entities/pay_period.dart';
import '../repositories/i_finance_repository.dart';

// ── GetPayPeriods ─────────────────────────────────────────────────────────────

@lazySingleton
class GetPayPeriodsUseCase extends UseCase<List<PayPeriod>, String> {
  GetPayPeriodsUseCase(this._repository);
  final IFinanceRepository _repository;

  @override
  Future<Either<Failure, List<PayPeriod>>> call(String workerId) =>
      _repository.getPayPeriods(workerId);
}

// ── AddPayPeriod ──────────────────────────────────────────────────────────────

@lazySingleton
class AddPayPeriodUseCase extends UseCase<PayPeriod, PayPeriod> {
  AddPayPeriodUseCase(this._repository);
  final IFinanceRepository _repository;

  @override
  Future<Either<Failure, PayPeriod>> call(PayPeriod params) =>
      _repository.addPayPeriod(params);
}

// ── UpdatePayPeriod ───────────────────────────────────────────────────────────

@lazySingleton
class UpdatePayPeriodUseCase extends UseCase<PayPeriod, PayPeriod> {
  UpdatePayPeriodUseCase(this._repository);
  final IFinanceRepository _repository;

  @override
  Future<Either<Failure, PayPeriod>> call(PayPeriod params) =>
      _repository.updatePayPeriod(params);
}

// ── DeletePayPeriod ───────────────────────────────────────────────────────────

@lazySingleton
class DeletePayPeriodUseCase extends UseCase<Unit, String> {
  DeletePayPeriodUseCase(this._repository);
  final IFinanceRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String periodId) =>
      _repository.deletePayPeriod(periodId);
}