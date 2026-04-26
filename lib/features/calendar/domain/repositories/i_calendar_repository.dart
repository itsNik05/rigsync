import 'package:dartz/dartz.dart';

import '../../../../core/utils/failures.dart';
import '../entities/hitch.dart';
import '../entities/worker.dart';

/// Repository interface for all calendar operations.
/// Implemented in the data layer; injected into use cases.
abstract class ICalendarRepository {
  // ── Workers ────────────────────────────────────────────────────────────────

  Future<Either<Failure, List<Worker>>> getWorkers();

  Future<Either<Failure, Worker>> addWorker(Worker worker);

  Future<Either<Failure, Worker>> updateWorker(Worker worker);

  Future<Either<Failure, Unit>> deleteWorker(String workerId);

  // ── Hitches ────────────────────────────────────────────────────────────────

  /// Returns all hitches for a given worker within a date range.
  Future<Either<Failure, List<Hitch>>> getHitches({
    required String workerId,
    required DateTime from,
    required DateTime to,
  });

  /// Returns a reactive stream of hitches for the calendar view.
  Stream<Either<Failure, List<Hitch>>> watchHitches({
    required String workerId,
  });

  Future<Either<Failure, Hitch>> addHitch(Hitch hitch);

  Future<Either<Failure, Hitch>> updateHitch(Hitch hitch);

  Future<Either<Failure, Unit>> deleteHitch(String hitchId);

  /// Bulk-generate hitches from a pattern template.
  Future<Either<Failure, List<Hitch>>> generateFromPattern({
    required String workerId,
    required DateTime startDate,
    required int daysOn,
    required int daysOff,
    required int months,
    String? rigName,
  });

  // ── Sync ───────────────────────────────────────────────────────────────────

  /// Sync local changes to Firestore (family sharing).
  Future<Either<Failure, Unit>> syncToCloud();

  /// Pull latest changes from Firestore.
  Future<Either<Failure, Unit>> pullFromCloud();
}