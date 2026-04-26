import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

// ── Table definitions ─────────────────────────────────────────────────────────

class WorkersTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get colorHex => text()();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get role => text().nullable()();
  BoolColumn get isOwner => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class HitchesTable extends Table {
  TextColumn get id => text()();
  TextColumn get workerId => text().references(WorkersTable, #id)();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  TextColumn get type => text()(); // 'on' | 'off' | 'transit'
  TextColumn get rigName => text().nullable()();
  TextColumn get location => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get colorHex => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class FamilyEventsTable extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get description => text().nullable()();
  TextColumn get colorHex => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class PayPeriodsTable extends Table {
  TextColumn get id => text()();
  TextColumn get workerId => text().references(WorkersTable, #id)();
  DateTimeColumn get periodStart => dateTime()();
  DateTimeColumn get periodEnd => dateTime()();
  RealColumn get dailyRate => real().nullable()();
  RealColumn get totalExpected => real().nullable()();
  RealColumn get totalActual => real().nullable()();
  BoolColumn get isPaid => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Database ──────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [WorkersTable, HitchesTable, FamilyEventsTable, PayPeriodsTable])
@singleton
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // Add migrations here as schema evolves
    },
  );

  // ── Worker DAOs ─────────────────────────────────────────────────────────────

  Future<List<WorkersTableData>> getAllWorkers() =>
      select(workersTable).get();

  Future<int> insertWorker(WorkersTableCompanion worker) =>
      into(workersTable).insert(worker);

  Future<bool> updateWorker(WorkersTableCompanion worker) =>
      update(workersTable).replace(worker);

  Future<int> deleteWorker(String id) =>
      (delete(workersTable)..where((t) => t.id.equals(id))).go();

  // ── Hitch DAOs ──────────────────────────────────────────────────────────────

  Future<List<HitchesTableData>> getHitchesForWorker({
    required String workerId,
    required DateTime from,
    required DateTime to,
  }) {
    return (select(hitchesTable)
      ..where((t) =>
      t.workerId.equals(workerId) &
      t.startDate.isSmallerOrEqualValue(to) &
      t.endDate.isBiggerOrEqualValue(from)))
        .get();
  }

  Stream<List<HitchesTableData>> watchHitchesForWorker(String workerId) {
    return (select(hitchesTable)
      ..where((t) => t.workerId.equals(workerId))
      ..orderBy([(t) => OrderingTerm.asc(t.startDate)]))
        .watch();
  }

  Future<int> insertHitch(HitchesTableCompanion hitch) =>
      into(hitchesTable).insert(hitch);

  Future<void> insertHitches(List<HitchesTableCompanion> hitches) =>
      batch((b) => b.insertAll(hitchesTable, hitches));

  Future<bool> updateHitch(HitchesTableCompanion hitch) =>
      update(hitchesTable).replace(hitch);

  Future<int> deleteHitch(String id) =>
      (delete(hitchesTable)..where((t) => t.id.equals(id))).go();

  // ── Family events DAOs ──────────────────────────────────────────────────────

  Future<List<FamilyEventsTableData>> getFamilyEvents() =>
      (select(familyEventsTable)
        ..orderBy([(t) => OrderingTerm.asc(t.date)]))
          .get();

  Future<int> insertFamilyEvent(FamilyEventsTableCompanion event) =>
      into(familyEventsTable).insert(event);

  Future<int> deleteFamilyEvent(String id) =>
      (delete(familyEventsTable)..where((t) => t.id.equals(id))).go();

  // ── Pay period DAOs ─────────────────────────────────────────────────────────

  Future<List<PayPeriodsTableData>> getPayPeriods(String workerId) =>
      (select(payPeriodsTable)
        ..where((t) => t.workerId.equals(workerId))
        ..orderBy([(t) => OrderingTerm.desc(t.periodStart)]))
          .get();

  Future<int> insertPayPeriod(PayPeriodsTableCompanion period) =>
      into(payPeriodsTable).insert(period);

  Future<bool> updatePayPeriod(PayPeriodsTableCompanion period) =>
      update(payPeriodsTable).replace(period);
}

// ── Connection ────────────────────────────────────────────────────────────────

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'rigsync.db'));
    return NativeDatabase.createInBackground(file);
  });
}