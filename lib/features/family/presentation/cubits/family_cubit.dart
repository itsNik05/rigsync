import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/family_event.dart';
import '../../domain/entities/household.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/utils/failures.dart';
import '../../domain/repositories/i_family_repository.dart';

// ── State ─────────────────────────────────────────────────────────────────────

enum FamilyStatus { initial, loading, loaded, error }

class FamilyState extends Equatable {
  const FamilyState({
    this.status = FamilyStatus.initial,
    this.isSignedIn = false,
    this.userId,
    this.userName,
    this.household,
    this.familyEvents = const [],
    this.errorMessage,
    this.isOwner = false,
  });

  final FamilyStatus status;
  final bool isSignedIn;
  final String? userId;
  final String? userName;
  final Household? household;
  final List<FamilyEvent> familyEvents;
  final String? errorMessage;
  final bool isOwner;

  bool get hasHousehold => household != null;

  // Upcoming family events (next 30 days)
  List<FamilyEvent> get upcomingEvents {
    final now = DateTime.now();
    final limit = now.add(const Duration(days: 30));
    return familyEvents
        .where((e) => e.date.isAfter(now) && e.date.isBefore(limit))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  FamilyState copyWith({
    FamilyStatus? status,
    bool? isSignedIn,
    String? userId,
    String? userName,
    Household? household,
    List<FamilyEvent>? familyEvents,
    String? errorMessage,
    bool? isOwner,
    bool clearHousehold = false,
  }) {
    return FamilyState(
      status: status ?? this.status,
      isSignedIn: isSignedIn ?? this.isSignedIn,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      household: clearHousehold ? null : (household ?? this.household),
      familyEvents: familyEvents ?? this.familyEvents,
      errorMessage: errorMessage,
      isOwner: isOwner ?? this.isOwner,
    );
  }

  @override
  List<Object?> get props => [
    status, isSignedIn, userId, userName,
    household, familyEvents, errorMessage, isOwner,
  ];
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

class FamilyCubit extends Cubit<FamilyState> {
  FamilyCubit(this._repository) : super(const FamilyState());

  final IFamilyRepository _repository;
  StreamSubscription? _householdSub;
  StreamSubscription? _eventsSub;
  static const _uuid = Uuid();
  String? _pendingHouseholdId;

  Future<void> initialize() async {
    emit(state.copyWith(status: FamilyStatus.loading));

    final uid = await _repository.getCurrentUserId();
    final name = await _repository.getCurrentUserName();

    if (uid == null) {
      emit(state.copyWith(
        status: FamilyStatus.loaded,
        isSignedIn: false,
      ));
      return;
    }

    emit(state.copyWith(
      isSignedIn: true,
      userId: uid,
      userName: name,
    ));

    // Check if already in a household
    final result = await _repository.getMyHousehold();
    result.fold(
          (f) => emit(state.copyWith(
        status: FamilyStatus.error,
        errorMessage: f.message,
      )),
          (household) {
        if (household != null) {
          _subscribeToHousehold(household.id);
          emit(state.copyWith(
            status: FamilyStatus.loaded,
            household: household,
            isOwner: household.ownerId == uid,
          ));
        } else {
          emit(state.copyWith(status: FamilyStatus.loaded));
        }
      },
    );
  }

  /// Called from main.dart after hitches are loaded to sync them
  Future<void> syncExistingHitches(List<Map<String, dynamic>> hitchMaps) async {
    final householdId = state.household?.id ?? _pendingHouseholdId;
    if (householdId == null) return;
    if (!state.isOwner) return;
    await _repository.syncHitchesToCloud(householdId, hitchMaps);
    _pendingHouseholdId = null;
  }

  Future<void> signInWithGoogle() async {
    emit(state.copyWith(status: FamilyStatus.loading));
    final result = await _repository.signInWithGoogle();
    result.fold(
          (f) => emit(state.copyWith(
        status: FamilyStatus.error,
        errorMessage: f.message,
      )),
          (uid) async {
        final name = await _repository.getCurrentUserName();
        emit(state.copyWith(
          isSignedIn: true,
          userId: uid,
          userName: name,
          status: FamilyStatus.loaded,
        ));
        await initialize();
      },
    );
  }

  Future<void> signInAnonymously() async {
    emit(state.copyWith(status: FamilyStatus.loading));
    final result = await _repository.signInAnonymously();
    result.fold(
          (f) => emit(state.copyWith(
        status: FamilyStatus.error,
        errorMessage: f.message,
      )),
          (uid) {
        emit(state.copyWith(
          isSignedIn: true,
          userId: uid,
          status: FamilyStatus.loaded,
        ));
      },
    );
  }

  Future<void> createHousehold(String workerName) async {
    emit(state.copyWith(status: FamilyStatus.loading));
    final result = await _repository.createHousehold(workerName);
    result.fold(
          (f) => emit(state.copyWith(
        status: FamilyStatus.error,
        errorMessage: f.message,
      )),
          (household) {
        _subscribeToHousehold(household.id);
        emit(state.copyWith(
          status: FamilyStatus.loaded,
          household: household,
          isOwner: true,
        ));
        // Trigger hitch sync after household creation
        _pendingHouseholdId = household.id;
      },
    );
  }

  Future<void> joinHousehold(String code) async {
    emit(state.copyWith(status: FamilyStatus.loading));
    final result = await _repository.joinHousehold(code);
    result.fold(
          (f) => emit(state.copyWith(
        status: FamilyStatus.error,
        errorMessage: f.message,
      )),
          (household) {
        _subscribeToHousehold(household.id);
        emit(state.copyWith(
          status: FamilyStatus.loaded,
          household: household,
          isOwner: false,
        ));
      },
    );
  }

  Future<void> leaveHousehold() async {
    if (state.household == null) return;
    await _repository.leaveHousehold(state.household!.id);
    _householdSub?.cancel();
    _eventsSub?.cancel();
    emit(state.copyWith(clearHousehold: true, familyEvents: []));
  }

  Future<void> addFamilyEvent({
    required String title,
    required DateTime date,
    String? description,
    String? colorHex,
  }) async {
    if (state.household == null) return;
    final event = FamilyEvent(
      id: _uuid.v4(),
      title: title,
      date: date,
      description: description,
      colorHex: colorHex ?? '#AD1457',
    );
    await _repository.addFamilyEvent(state.household!.id, event);
  }

  Future<void> deleteFamilyEvent(String eventId) async {
    if (state.household == null) return;
    await _repository.deleteFamilyEvent(state.household!.id, eventId);
  }

  void _subscribeToHousehold(String householdId) {
    _householdSub?.cancel();
    _eventsSub?.cancel();

    _householdSub =
        _repository.watchHousehold(householdId).listen((result) {
          result.fold(
                (_) {},
                (household) => emit(state.copyWith(household: household)),
          );
        });

    _eventsSub =
        _repository.watchFamilyEvents(householdId).listen((result) {
          result.fold(
                (_) {},
                (events) => emit(state.copyWith(familyEvents: events)),
          );
        });
  }

  @override
  Future<void> close() {
    _householdSub?.cancel();
    _eventsSub?.cancel();
    return super.close();
  }

  Future<void> syncHitches(List<Map<String, dynamic>> hitches) async {
    if (state.household == null) return;
    await _repository.syncHitchesToCloud(state.household!.id, hitches);
  }

  Stream<Either<Failure, List<Map<String, dynamic>>>> watchHitches(
      String householdId) {
    return _repository.watchHitches(householdId);
  }

}