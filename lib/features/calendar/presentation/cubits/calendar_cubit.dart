import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/hitch.dart';
import '../../domain/entities/worker.dart';
import '../../domain/usecases/calendar_usecases.dart';

// ── State ─────────────────────────────────────────────────────────────────────

enum CalendarStatus { initial, loading, loaded, error }

class CalendarState extends Equatable {
  const CalendarState({
    this.status = CalendarStatus.initial,
    this.selectedDay,
    this.focusedDay,
    this.hitches = const [],
    this.workers = const [],
    this.selectedWorker,
    this.errorMessage,
  });

  final CalendarStatus status;
  final DateTime? selectedDay;
  final DateTime? focusedDay;
  final List<Hitch> hitches;
  final List<Worker> workers;
  final Worker? selectedWorker;
  final String? errorMessage;

  /// Returns hitches that fall on [day].
  List<Hitch> hitchesForDay(DateTime day) {
    return hitches.where((h) {
      final d = DateTime(day.year, day.month, day.day);
      return !d.isBefore(DateTime(h.startDate.year, h.startDate.month, h.startDate.day)) &&
          !d.isAfter(DateTime(h.endDate.year, h.endDate.month, h.endDate.day));
    }).toList();
  }

  CalendarState copyWith({
    CalendarStatus? status,
    DateTime? selectedDay,
    DateTime? focusedDay,
    List<Hitch>? hitches,
    List<Worker>? workers,
    Worker? selectedWorker,
    String? errorMessage,
  }) {
    return CalendarState(
      status: status ?? this.status,
      selectedDay: selectedDay ?? this.selectedDay,
      focusedDay: focusedDay ?? this.focusedDay,
      hitches: hitches ?? this.hitches,
      workers: workers ?? this.workers,
      selectedWorker: selectedWorker ?? this.selectedWorker,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    selectedDay,
    focusedDay,
    hitches,
    workers,
    selectedWorker,
    errorMessage,
  ];
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

@injectable
class CalendarCubit extends Cubit<CalendarState> {
  CalendarCubit({
    required GetHitchesUseCase getHitches,
    required AddHitchUseCase addHitch,
    required UpdateHitchUseCase updateHitch,
    required DeleteHitchUseCase deleteHitch,
    required GenerateFromPatternUseCase generateFromPattern,
  })  : _getHitches = getHitches,
        _addHitch = addHitch,
        _updateHitch = updateHitch,
        _deleteHitch = deleteHitch,
        _generateFromPattern = generateFromPattern,
        super(CalendarState(focusedDay: DateTime.now()));

  final GetHitchesUseCase _getHitches;
  final AddHitchUseCase _addHitch;
  final UpdateHitchUseCase _updateHitch;
  final DeleteHitchUseCase _deleteHitch;
  final GenerateFromPatternUseCase _generateFromPattern;

  Future<void> loadHitches(String workerId) async {
    emit(state.copyWith(status: CalendarStatus.loading));

    final now = DateTime.now();
    final result = await _getHitches(GetHitchesParams(
      workerId: workerId,
      from: DateTime(now.year - 1, 1, 1),
      to: DateTime(now.year + 2, 12, 31),
    ));

    result.fold(
          (failure) => emit(state.copyWith(
        status: CalendarStatus.error,
        errorMessage: failure.message,
      )),
          (hitches) => emit(state.copyWith(
        status: CalendarStatus.loaded,
        hitches: hitches,
      )),
    );
  }

  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    emit(state.copyWith(
      selectedDay: selectedDay,
      focusedDay: focusedDay,
    ));
  }

  void onPageChanged(DateTime focusedDay) {
    emit(state.copyWith(focusedDay: focusedDay));
  }

  Future<void> addHitch(Hitch hitch) async {
    final result = await _addHitch(hitch);
    result.fold(
          (failure) => emit(state.copyWith(errorMessage: failure.message)),
          (added) => emit(state.copyWith(hitches: [...state.hitches, added])),
    );
  }

  Future<void> deleteHitch(String hitchId) async {
    final result = await _deleteHitch(hitchId);
    result.fold(
          (failure) => emit(state.copyWith(errorMessage: failure.message)),
          (_) => emit(state.copyWith(
        hitches: state.hitches.where((h) => h.id != hitchId).toList(),
      )),
    );
  }

  Future<void> generatePattern(GeneratePatternParams params) async {
    emit(state.copyWith(status: CalendarStatus.loading));
    final result = await _generateFromPattern(params);
    result.fold(
          (failure) => emit(state.copyWith(
        status: CalendarStatus.error,
        errorMessage: failure.message,
      )),
          (generated) => emit(state.copyWith(
        status: CalendarStatus.loaded,
        hitches: [...state.hitches, ...generated],
      )),
    );
  }
}