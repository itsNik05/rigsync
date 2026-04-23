import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/failures.dart';
import '../../../calendar/data/datasources/app_database.dart';
import '../../domain/entities/pay_period.dart';
import '../../domain/repositories/i_finance_repository.dart';
import 'package:drift/drift.dart';

@LazySingleton(as: IFinanceRepository)
class FinanceRepositoryImpl implements IFinanceRepository {
  FinanceRepositoryImpl(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  @override
  Future<Either<Failure, List<PayPeriod>>> getPayPeriods(
      String workerId) async {
    try {
      final rows = await _db.getPayPeriods(workerId);
      return Right(rows.map(_rowToPeriod).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<PayPeriod>>> watchPayPeriods(
      String workerId) {
    return _db
        .getPayPeriods(workerId)
        .asStream()
        .map<Either<Failure, List<PayPeriod>>>(
          (rows) => Right(rows.map(_rowToPeriod).toList()),
    )
        .handleError((e) => Left(CacheFailure(e.toString())));
  }

  @override
  Future<Either<Failure, PayPeriod>> addPayPeriod(PayPeriod period) async {
    try {
      final id = period.id.isEmpty ? _uuid.v4() : period.id;
      final p = PayPeriod(
        id: id,
        workerId: period.workerId,
        periodStart: period.periodStart,
        periodEnd: period.periodEnd,
        dailyRate: period.dailyRate,
        totalExpected: period.totalExpected,
        totalActual: period.totalActual,
        isPaid: period.isPaid,
      );
      await _db.insertPayPeriod(PayPeriodsTableCompanion.insert(
        id: id,
        workerId: p.workerId,
        periodStart: p.periodStart,
        periodEnd: p.periodEnd,
        dailyRate: Value(p.dailyRate),
        totalExpected: Value(p.totalExpected),
        totalActual: Value(p.totalActual),
        isPaid: Value(p.isPaid),
      ));
      return Right(p);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PayPeriod>> updatePayPeriod(
      PayPeriod period) async {
    try {
      await _db.updatePayPeriod(PayPeriodsTableCompanion(
        id: Value(period.id),
        workerId: Value(period.workerId),
        periodStart: Value(period.periodStart),
        periodEnd: Value(period.periodEnd),
        dailyRate: Value(period.dailyRate),
        totalExpected: Value(period.totalExpected),
        totalActual: Value(period.totalActual),
        isPaid: Value(period.isPaid),
      ));
      return Right(period);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deletePayPeriod(String periodId) async {
    try {
      await (_db.delete(_db.payPeriodsTable)
        ..where((t) => t.id.equals(periodId)))
          .go();
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  PayPeriod _rowToPeriod(PayPeriodsTableData r) => PayPeriod(
    id: r.id,
    workerId: r.workerId,
    periodStart: r.periodStart,
    periodEnd: r.periodEnd,
    dailyRate: r.dailyRate,
    totalExpected: r.totalExpected,
    totalActual: r.totalActual,
    isPaid: r.isPaid,
  );

}