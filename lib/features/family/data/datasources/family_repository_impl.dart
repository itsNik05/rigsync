import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/failures.dart';
import '../../domain/entities/family_event.dart';
import '../../domain/entities/household.dart';
import '../../domain/repositories/i_family_repository.dart';

class FamilyRepositoryImpl implements IFamilyRepository {
  FamilyRepositoryImpl()
      : _auth = FirebaseAuth.instance,
        _firestore = FirebaseFirestore.instance,
        _googleSignIn = GoogleSignIn();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;
  static const _uuid = Uuid();

  // ── Auth ───────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, String>> signInAnonymously() async {
    try {
      final cred = await _auth.signInAnonymously();
      return Right(cred.user!.uid);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return Left(const AuthFailure('Cancelled'));
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      return Right(cred.user!.uid);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<String?> getCurrentUserId() async => _auth.currentUser?.uid;

  @override
  Future<String?> getCurrentUserName() async =>
      _auth.currentUser?.displayName ?? _auth.currentUser?.email;

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ── Household ──────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, Household>> createHousehold(
      String ownerName) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return Left(const AuthFailure('Not signed in'));

      final code = _generateCode();
      final household = Household(
        id: _uuid.v4(),
        ownerId: uid,
        ownerName: ownerName,
        inviteCode: code,
        memberIds: [uid],
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('households')
          .doc(household.id)
          .set(household.toMap());

      // Save household ID to user profile
      await _firestore.collection('users').doc(uid).set({
        'householdId': household.id,
        'role': 'owner',
      }, SetOptions(merge: true));

      return Right(household);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Household>> joinHousehold(
      String inviteCode) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return Left(const AuthFailure('Not signed in'));

      // Find household by invite code
      final query = await _firestore
          .collection('households')
          .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return Left(const NotFoundFailure('Invalid invite code'));
      }

      final doc = query.docs.first;
      final household = Household.fromMap(doc.data(), doc.id);

      // Add user to memberIds
      await _firestore.collection('households').doc(doc.id).update({
        'memberIds': FieldValue.arrayUnion([uid]),
      });

      // Save household ID to user profile
      await _firestore.collection('users').doc(uid).set({
        'householdId': doc.id,
        'role': 'member',
      }, SetOptions(merge: true));

      return Right(household);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Household?>> getMyHousehold() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return const Right(null);

      final userDoc =
      await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) return const Right(null);

      final householdId = userDoc.data()?['householdId'] as String?;
      if (householdId == null) return const Right(null);

      final householdDoc = await _firestore
          .collection('households')
          .doc(householdId)
          .get();
      if (!householdDoc.exists) return const Right(null);

      return Right(
          Household.fromMap(householdDoc.data()!, householdDoc.id));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, Household>> watchHousehold(
      String householdId) {
    return _firestore
        .collection('households')
        .doc(householdId)
        .snapshots()
        .map<Either<Failure, Household>>((snap) {
      if (!snap.exists) return Left(const NotFoundFailure());
      return Right(Household.fromMap(snap.data()!, snap.id));
    }).handleError((e) => Left(ServerFailure(e.toString())));
  }

  @override
  Future<Either<Failure, Unit>> leaveHousehold(
      String householdId) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return Left(const AuthFailure());

      await _firestore
          .collection('households')
          .doc(householdId)
          .update({
        'memberIds': FieldValue.arrayRemove([uid]),
      });

      await _firestore.collection('users').doc(uid).update({
        'householdId': FieldValue.delete(),
      });

      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── Family events ──────────────────────────────────────────────────────────

  @override
  Stream<Either<Failure, List<FamilyEvent>>> watchFamilyEvents(
      String householdId) {
    return _firestore
        .collection('households')
        .doc(householdId)
        .collection('family_events')
        .orderBy('date')
        .snapshots()
        .map<Either<Failure, List<FamilyEvent>>>((snap) {
      final events = snap.docs.map((d) {
        final data = d.data();
        return FamilyEvent(
          id: d.id,
          title: data['title'] as String,
          date: DateTime.fromMillisecondsSinceEpoch(
              data['date'] as int),
          description: data['description'] as String?,
          colorHex: data['colorHex'] as String?,
        );
      }).toList();
      return Right(events);
    }).handleError((e) => Left(ServerFailure(e.toString())));
  }

  @override
  Future<Either<Failure, FamilyEvent>> addFamilyEvent(
      String householdId, FamilyEvent event) async {
    try {
      final id = _uuid.v4();
      await _firestore
          .collection('households')
          .doc(householdId)
          .collection('family_events')
          .doc(id)
          .set({
        'title': event.title,
        'date': event.date.millisecondsSinceEpoch,
        'description': event.description,
        'colorHex': event.colorHex ?? '#AD1457',
        'addedBy': _auth.currentUser?.uid,
      });
      return Right(FamilyEvent(
        id: id,
        title: event.title,
        date: event.date,
        description: event.description,
        colorHex: event.colorHex ?? '#AD1457',
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteFamilyEvent(
      String householdId, String eventId) async {
    try {
      await _firestore
          .collection('households')
          .doc(householdId)
          .collection('family_events')
          .doc(eventId)
          .delete();
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── Hitch sync ─────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, Unit>> syncHitchesToCloud(
      String householdId, List<Map<String, dynamic>> hitches) async {
    try {
      final batch = _firestore.batch();
      final col = _firestore
          .collection('households')
          .doc(householdId)
          .collection('hitches');

      for (final h in hitches) {
        batch.set(col.doc(h['id'] as String), h);
      }
      await batch.commit();
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<Map<String, dynamic>>>> watchHitches(
      String householdId) {
    return _firestore
        .collection('households')
        .doc(householdId)
        .collection('hitches')
        .snapshots()
        .map<Either<Failure, List<Map<String, dynamic>>>>((snap) =>
        Right(snap.docs.map((d) => d.data()).toList()))
        .handleError((e) => Left(ServerFailure(e.toString())));
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = DateTime.now().millisecondsSinceEpoch;
    return List.generate(
        6, (i) => chars[(rand >> (i * 4)) % chars.length]).join();
  }
}