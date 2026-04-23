import 'package:dartz/dartz.dart';

import '../../../../core/utils/failures.dart';
import '../entities/pay_period.dart';

abstract class IFinanceRepository {
  Future<Either<Failure, List<PayPeriod>>> getPayPeriods(String workerId);

  Stream<Either<Failure, List<PayPeriod>>> watchPayPeriods(String workerId);

  Future<Either<Failure, PayPeriod>> addPayPeriod(PayPeriod period);

  Future<Either<Failure, PayPeriod>> updatePayPeriod(PayPeriod period);

  Future<Either<Failure, Unit>> deletePayPeriod(String periodId);
}