import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';

import '../../../../core/utils/failures.dart';
import '../../../../core/utils/hitch_date_utils.dart';
import '../../domain/entities/hitch.dart';
import '../../domain/entities/worker.dart';
import '../../domain/repositories/i_calendar_repository.dart';
import '../datasources/app_database.dart';

@LazySingleton(as: ICalendarRepository)
class CalendarRepositoryImpl implements ICalendarRepository {
  CalendarRepositoryImpl(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  // ── Workers ────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<Worker>>> getWorkers() async {
    try {
      final rows = await _db.getAllWorkers();
      final workers = rows
          .map((r) => Worker(
        id: r.id,
        name: r.name,
        colorHex: r.colorHex,
        avatarUrl: r.avatarUrl,
        role: r.role,
        isOwner: r.isOwner,
      ))
          .toList();
      return Right(workers);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Worker>> addWorker(Worker worker) async {
    try {
      await _db.insertWorker(WorkersTableCompanion.insert(
        id: worker.id.isEmpty ? _uuid.v4() : worker.id,
        name: worker.name,
        colorHex: worker.colorHex,
      ));
      return Right(worker);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Worker>> updateWorker(Worker worker) async {
    try {
      await _db.updateWorker(WorkersTableCompanion(
        id: Value(worker.id),
        name: Value(worker.name),
        colorHex: Value(worker.colorHex),
      ));
      return Right(worker);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteWorker(String workerId) async {
    try {
      await _db.deleteWorker(workerId);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ── Hitches ────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<Hitch>>> getHitches({
    required String workerId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final rows = await _db.getHitchesForWorker(
        workerId: workerId,
        from: from,
        to: to,
      );
      return Right(rows.map(_rowToHitch).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<Hitch>>> watchHitches({
    required String workerId,
  }) {
    return _db
        .watchHitchesForWorker(workerId)
        .map<Either<Failure, List<Hitch>>>(
          (rows) => Right(rows.map(_rowToHitch).toList()),
    )
        .handleError(
          (e) => Left(CacheFailure(e.toString())),
    );
  }

  @override
  Future<Either<Failure, Hitch>> addHitch(Hitch hitch) async {
    try {
      final id = hitch.id.isEmpty ? _uuid.v4() : hitch.id;
      final h = hitch.copyWith(id: id);
      await _db.insertHitch(HitchesTableCompanion.insert(
        id: id,
        workerId: h.workerId,
        startDate: h.startDate,
        endDate: h.endDate,
        type: _typeStr(h.type),
      ));
      return Right(h);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Hitch>> updateHitch(Hitch hitch) async {
    try {
      await _db.updateHitch(HitchesTableCompanion(
        id: Value(hitch.id),
        workerId: Value(hitch.workerId),
        startDate: Value(hitch.startDate),
        endDate: Value(hitch.endDate),
        type: Value(_typeStr(hitch.type)),
        rigName: Value(hitch.rigName),
        location: Value(hitch.location),
        notes: Value(hitch.notes),
        colorHex: Value(hitch.colorHex),
      ));
      return Right(hitch);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteHitch(String hitchId) async {
    try {
      await _db.deleteHitch(hitchId);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Hitch>>> generateFromPattern({
    required String workerId,
    required DateTime startDate,
    required int daysOn,
    required int daysOff,
    required int months,
    String? rigName,
    String? colorHex,
  }) async {
    try {
      final periods = HitchDateUtils.generatePattern(
        startDate: startDate,
        daysOn: daysOn,
        daysOff: daysOff,
        months: months,
      );

      final hitches = periods
          .map((p) => Hitch(
        id: _uuid.v4(),
        workerId: workerId,
        startDate: p.start,
        endDate: p.end,
        type: p.isOnShift ? HitchType.on : HitchType.off,
        rigName: p.isOnShift ? rigName : null,
        colorHex: colorHex,
      ))
          .toList();

      final companions = hitches
          .map((h) => HitchesTableCompanion.insert(
        id: h.id,
        workerId: h.workerId,
        startDate: h.startDate,
        endDate: h.endDate,
        type: _typeStr(h.type),
      ))
          .toList();

      await _db.insertHitches(companions);
      return Right(hitches);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> syncToCloud() async {
    // TODO: implement Firestore sync
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> pullFromCloud() async {
    // TODO: implement Firestore pull
    return const Right(unit);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Hitch _rowToHitch(HitchesTableData r) => Hitch(
    id: r.id,
    workerId: r.workerId,
    startDate: r.startDate,
    endDate: r.endDate,
    type: switch (r.type) {
      'on' => HitchType.on,
      'transit' => HitchType.transit,
      _ => HitchType.off,
    },
    rigName: r.rigName,
    location: r.location,
    notes: r.notes,
    colorHex: r.colorHex,
  );

  String _typeStr(HitchType t) => switch (t) {
    HitchType.on => 'on',
    HitchType.off => 'off',
    HitchType.transit => 'transit',
  };
}