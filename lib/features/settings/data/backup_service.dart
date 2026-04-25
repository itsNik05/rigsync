import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../calendar/data/datasources/app_database.dart';

class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  // ── Export ─────────────────────────────────────────────────────────────────

  Future<BackupResult> exportBackup() async {
    try {
      final workers = await _db.getAllWorkers();
      final workersJson = workers
          .map((w) => {
        'id': w.id,
        'name': w.name,
        'colorHex': w.colorHex,
        'avatarUrl': w.avatarUrl,
        'role': w.role,
        'isOwner': w.isOwner,
      })
          .toList();

      final now = DateTime.now();
      final allHitches = <Map<String, dynamic>>[];
      for (final worker in workers) {
        final hitches = await _db.getHitchesForWorker(
          workerId: worker.id,
          from: DateTime(now.year - 5),
          to: DateTime(now.year + 5),
        );
        allHitches.addAll(hitches.map((h) => {
          'id': h.id,
          'workerId': h.workerId,
          'startDate': h.startDate.toIso8601String(),
          'endDate': h.endDate.toIso8601String(),
          'type': h.type,
          'rigName': h.rigName,
          'location': h.location,
          'notes': h.notes,
          'colorHex': h.colorHex,
        }));
      }

      final allPayPeriods = <Map<String, dynamic>>[];
      for (final worker in workers) {
        final periods = await _db.getPayPeriods(worker.id);
        allPayPeriods.addAll(periods.map((p) => {
          'id': p.id,
          'workerId': p.workerId,
          'periodStart': p.periodStart.toIso8601String(),
          'periodEnd': p.periodEnd.toIso8601String(),
          'dailyRate': p.dailyRate,
          'totalExpected': p.totalExpected,
          'totalActual': p.totalActual,
          'isPaid': p.isPaid,
        }));
      }

      final familyEvents = await _db.getFamilyEvents();
      final familyEventsJson = familyEvents
          .map((e) => {
        'id': e.id,
        'title': e.title,
        'date': e.date.toIso8601String(),
        'description': e.description,
        'colorHex': e.colorHex,
      })
          .toList();

      final backup = {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'app': 'RigSync by NuvioLabs',
        'workers': workersJson,
        'hitches': allHitches,
        'payPeriods': allPayPeriods,
        'familyEvents': familyEventsJson,
      };

      final jsonString =
      const JsonEncoder.withIndent('  ').convert(backup);

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-')
          .substring(0, 19);
      final file =
      File('${tempDir.path}/rigsync_backup_$timestamp.json');
      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'RigSync Backup — $timestamp',
        text:
        'RigSync data backup. Import this file in Settings → Restore.',
      );

      return BackupResult(
        success: true,
        message: 'Backup exported successfully',
        workerCount: workers.length,
        hitchCount: allHitches.length,
        payPeriodCount: allPayPeriods.length,
      );
    } catch (e) {
      return BackupResult(
        success: false,
        message: 'Backup failed: ${e.toString()}',
      );
    }
  }

  // ── Import ─────────────────────────────────────────────────────────────────

  Future<BackupResult> importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return BackupResult(
          success: false,
          message: 'No file selected',
          cancelled: true,
        );
      }

      final path = result.files.first.path;
      if (path == null) {
        return BackupResult(
          success: false,
          message: 'Could not read file path',
        );
      }

      final file = File(path);
      final jsonString = await file.readAsString();
      final backup = jsonDecode(jsonString) as Map<String, dynamic>;

      if (backup['app'] != 'RigSync by NuvioLabs') {
        return BackupResult(
          success: false,
          message:
          'Invalid backup file. Please select a RigSync backup.',
        );
      }

      // Import workers
      final workers = backup['workers'] as List? ?? [];
      for (final w in workers) {
        final map = w as Map<String, dynamic>;
        try {
          await _db.insertWorker(WorkersTableCompanion.insert(
            id: map['id'] as String,
            name: map['name'] as String,
            colorHex: map['colorHex'] as String,
          ));
        } catch (_) {}
      }

      // Import hitches
      final hitches = backup['hitches'] as List? ?? [];
      for (final h in hitches) {
        final map = h as Map<String, dynamic>;
        try {
          await _db.insertHitch(HitchesTableCompanion.insert(
            id: map['id'] as String,
            workerId: map['workerId'] as String,
            startDate: DateTime.parse(map['startDate'] as String),
            endDate: DateTime.parse(map['endDate'] as String),
            type: map['type'] as String,
          ));
        } catch (_) {}
      }

      // Import pay periods
      final payPeriods = backup['payPeriods'] as List? ?? [];
      for (final p in payPeriods) {
        final map = p as Map<String, dynamic>;
        try {
          await _db.insertPayPeriod(PayPeriodsTableCompanion.insert(
            id: map['id'] as String,
            workerId: map['workerId'] as String,
            periodStart:
            DateTime.parse(map['periodStart'] as String),
            periodEnd: DateTime.parse(map['periodEnd'] as String),
          ));
        } catch (_) {}
      }

      // Import family events
      final events = backup['familyEvents'] as List? ?? [];
      for (final e in events) {
        final map = e as Map<String, dynamic>;
        try {
          await _db.insertFamilyEvent(
              FamilyEventsTableCompanion.insert(
                id: map['id'] as String,
                title: map['title'] as String,
                date: DateTime.parse(map['date'] as String),
              ));
        } catch (_) {}
      }

      return BackupResult(
        success: true,
        message: 'Restore complete',
        workerCount: workers.length,
        hitchCount: hitches.length,
        payPeriodCount: payPeriods.length,
      );
    } catch (e) {
      return BackupResult(
        success: false,
        message: 'Restore failed: ${e.toString()}',
      );
    }
  }
}

// ── Result model ──────────────────────────────────────────────────────────────

class BackupResult {
  const BackupResult({
    required this.success,
    required this.message,
    this.workerCount = 0,
    this.hitchCount = 0,
    this.payPeriodCount = 0,
    this.cancelled = false,
  });

  final bool success;
  final String message;
  final int workerCount;
  final int hitchCount;
  final int payPeriodCount;
  final bool cancelled;
}