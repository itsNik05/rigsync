import '../../domain/entities/hitch.dart';

/// Maps between the Drift database row and the domain [Hitch] entity.
class HitchMapper {
  const HitchMapper._();

  static Hitch fromJson(Map<String, dynamic> json) {
    return Hitch(
      id: json['id'] as String,
      workerId: json['worker_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      type: _typeFromString(json['type'] as String),
      rigName: json['rig_name'] as String?,
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      colorHex: json['color_hex'] as String?,
    );
  }

  static Map<String, dynamic> toJson(Hitch hitch) {
    return {
      'id': hitch.id,
      'worker_id': hitch.workerId,
      'start_date': hitch.startDate.toIso8601String(),
      'end_date': hitch.endDate.toIso8601String(),
      'type': _typeToString(hitch.type),
      'rig_name': hitch.rigName,
      'location': hitch.location,
      'notes': hitch.notes,
      'color_hex': hitch.colorHex,
    };
  }

  static HitchType _typeFromString(String value) => switch (value) {
    'on' => HitchType.on,
    'off' => HitchType.off,
    'transit' => HitchType.transit,
    _ => HitchType.off,
  };

  static String _typeToString(HitchType type) => switch (type) {
    HitchType.on => 'on',
    HitchType.off => 'off',
    HitchType.transit => 'transit',
  };
}