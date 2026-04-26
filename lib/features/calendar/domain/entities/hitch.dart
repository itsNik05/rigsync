import 'package:equatable/equatable.dart';

/// Core domain entity representing one rotation period for a worker.
class Hitch extends Equatable {
  const Hitch({
    required this.id,
    required this.workerId,
    required this.startDate,
    required this.endDate,
    required this.type,
    this.rigName,
    this.location,
    this.notes,
    this.colorHex,
  });

  final String id;
  final String workerId;
  final DateTime startDate;
  final DateTime endDate;
  final HitchType type;
  final String? rigName;
  final String? location;
  final String? notes;
  final String? colorHex; // e.g. '#2E7D32'

  bool get isOnShift => type == HitchType.on;

  int get durationDays => endDate.difference(startDate).inDays + 1;

  Hitch copyWith({
    String? id,
    String? workerId,
    DateTime? startDate,
    DateTime? endDate,
    HitchType? type,
    String? rigName,
    String? location,
    String? notes,
    String? colorHex,
  }) {
    return Hitch(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      type: type ?? this.type,
      rigName: rigName ?? this.rigName,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  @override
  List<Object?> get props => [
    id,
    workerId,
    startDate,
    endDate,
    type,
    rigName,
    location,
    notes,
    colorHex,
  ];
}

enum HitchType {
  on,      // Working on the rig
  off,     // Home / time off
  transit, // Travelling to/from rig
}