import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/worker.dart';
import '../../domain/repositories/i_calendar_repository.dart';

// ── State ─────────────────────────────────────────────────────────────────────

enum WorkerStatus { initial, loading, loaded, error }

class WorkerState extends Equatable {
  const WorkerState({
    this.status = WorkerStatus.initial,
    this.workers = const [],
    this.selectedWorkerId,
    this.errorMessage,
  });

  final WorkerStatus status;
  final List<Worker> workers;
  final String? selectedWorkerId;
  final String? errorMessage;

  Worker? get selectedWorker => workers.isEmpty
      ? null
      : workers.firstWhere(
        (w) => w.id == selectedWorkerId,
    orElse: () => workers.first,
  );

  WorkerState copyWith({
    WorkerStatus? status,
    List<Worker>? workers,
    String? selectedWorkerId,
    String? errorMessage,
  }) {
    return WorkerState(
      status: status ?? this.status,
      workers: workers ?? this.workers,
      selectedWorkerId: selectedWorkerId ?? this.selectedWorkerId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, workers, selectedWorkerId, errorMessage];
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

@injectable
class WorkerCubit extends Cubit<WorkerState> {
  WorkerCubit(this._repository) : super(const WorkerState());

  final ICalendarRepository _repository;
  static const _uuid = Uuid();

  Future<void> loadWorkers() async {
    emit(state.copyWith(status: WorkerStatus.loading));

    final result = await _repository.getWorkers();
    result.fold(
          (failure) => emit(state.copyWith(
        status: WorkerStatus.error,
        errorMessage: failure.message,
      )),
          (workers) => emit(state.copyWith(
        status: WorkerStatus.loaded,
        workers: workers,
        selectedWorkerId:
        workers.isEmpty ? null : workers.first.id,
      )),
    );
  }

  Future<void> addWorker({
    required String name,
    required String colorHex,
    String? role,
  }) async {
    final worker = Worker(
      id: _uuid.v4(),
      name: name,
      colorHex: colorHex,
      role: role,
      isOwner: state.workers.isEmpty, // first worker is the owner
    );

    final result = await _repository.addWorker(worker);
    result.fold(
          (failure) => emit(state.copyWith(errorMessage: failure.message)),
          (added) {
        final updated = [...state.workers, added];
        emit(state.copyWith(
          workers: updated,
          selectedWorkerId: state.selectedWorkerId ?? added.id,
        ));
      },
    );
  }

  Future<void> deleteWorker(String workerId) async {
    final result = await _repository.deleteWorker(workerId);
    result.fold(
          (failure) => emit(state.copyWith(errorMessage: failure.message)),
          (_) {
        final updated =
        state.workers.where((w) => w.id != workerId).toList();
        final newSelected = updated.isEmpty
            ? null
            : updated.first.id;
        emit(state.copyWith(
          workers: updated,
          selectedWorkerId: newSelected,
        ));
      },
    );
  }

  void selectWorker(String workerId) {
    emit(state.copyWith(selectedWorkerId: workerId));
  }
}