import 'package:dartz/dartz.dart';

import '../../../../core/utils/failures.dart';
import '../entities/family_event.dart';
import '../entities/household.dart';

abstract class IFamilyRepository {
  // ── Auth ───────────────────────────────────────────────────────────────────
  Future<Either<Failure, String>> signInAnonymously();
  Future<Either<Failure, String>> signInWithGoogle();
  Future<String?> getCurrentUserId();
  Future<String?> getCurrentUserName();
  Future<void> signOut();

  // ── Household ──────────────────────────────────────────────────────────────
  Future<Either<Failure, Household>> createHousehold(String ownerName);
  Future<Either<Failure, Household>> joinHousehold(String inviteCode);
  Future<Either<Failure, Household?>> getMyHousehold();
  Stream<Either<Failure, Household>> watchHousehold(String householdId);
  Future<Either<Failure, Unit>> leaveHousehold(String householdId);

  // ── Family events ──────────────────────────────────────────────────────────
  Stream<Either<Failure, List<FamilyEvent>>> watchFamilyEvents(
      String householdId);
  Future<Either<Failure, FamilyEvent>> addFamilyEvent(
      String householdId, FamilyEvent event);
  Future<Either<Failure, Unit>> deleteFamilyEvent(
      String householdId, String eventId);

  // ── Hitch sync ────────────────────────────────────────────────────────────
  Future<Either<Failure, Unit>> syncHitchesToCloud(
      String householdId, List<Map<String, dynamic>> hitches);
  Stream<Either<Failure, List<Map<String, dynamic>>>> watchHitches(
      String householdId);
}