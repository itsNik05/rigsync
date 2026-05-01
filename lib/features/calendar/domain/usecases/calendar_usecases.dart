import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../entities/hitch.dart';
import '../repositories/i_calendar_repository.dart';

// ── GetHitches ────────────────────────────────────────────────────────────────

@lazySingleton
class GetHitchesUseCase extends UseCase<List<Hitch>, GetHitchesParams> {
  GetHitchesUseCase(this._repository);

  final ICalendarRepository _repository;

  @override
  Future<Either<Failure, List<Hitch>>> call(GetHitchesParams params) {
    return _repository.getHitches(
      workerId: params.workerId,
      from: params.from,
      to: params.to,
    );
  }
}

class GetHitchesParams extends Equatable {
  const GetHitchesParams({
    required this.workerId,
    required this.from,
    required this.to,
  });

  final String workerId;
  final DateTime from;
  final DateTime to;

  @override
  List<Object?> get props => [workerId, from, to];
}

// ── AddHitch ──────────────────────────────────────────────────────────────────

@lazySingleton
class AddHitchUseCase extends UseCase<Hitch, Hitch> {
  AddHitchUseCase(this._repository);

  final ICalendarRepository _repository;

  @override
  Future<Either<Failure, Hitch>> call(Hitch params) {
    return _repository.addHitch(params);
  }
}

// ── UpdateHitch ───────────────────────────────────────────────────────────────

@lazySingleton
class UpdateHitchUseCase extends UseCase<Hitch, Hitch> {
  UpdateHitchUseCase(this._repository);

  final ICalendarRepository _repository;

  @override
  Future<Either<Failure, Hitch>> call(Hitch params) {
    return _repository.updateHitch(params);
  }
}

// ── DeleteHitch ───────────────────────────────────────────────────────────────

@lazySingleton
class DeleteHitchUseCase extends UseCase<Unit, String> {
  DeleteHitchUseCase(this._repository);

  final ICalendarRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String hitchId) {
    return _repository.deleteHitch(hitchId);
  }
}

// ── GenerateFromPattern ───────────────────────────────────────────────────────

@lazySingleton
class GenerateFromPatternUseCase
    extends UseCase<List<Hitch>, GeneratePatternParams> {
  GenerateFromPatternUseCase(this._repository);

  final ICalendarRepository _repository;

  @override
  Future<Either<Failure, List<Hitch>>> call(GeneratePatternParams params) {
    return _repository.generateFromPattern(
      workerId: params.workerId,
      startDate: params.startDate,
      daysOn: params.daysOn,
      daysOff: params.daysOff,
      months: params.months,
      rigName: params.rigName,
    );
  }
}

class GeneratePatternParams extends Equatable {
  const GeneratePatternParams({
    required this.workerId,
    required this.startDate,
    required this.daysOn,
    required this.daysOff,
    this.months = 12,
    this.rigName,
    this.colorHex,
  });

  final String workerId;
  final DateTime startDate;
  final int daysOn;
  final int daysOff;
  final int months;
  final String? rigName;
  final String? colorHex;

  @override
  List<Object?> get props =>
      [workerId, startDate, daysOn, daysOff, months, rigName, colorHex];
}