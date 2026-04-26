import 'package:equatable/equatable.dart';

class RigLocation extends Equatable {
  const RigLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.description,
    this.workerId,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? description;
  final String? workerId;

  @override
  List<Object?> get props => [id, name, latitude, longitude, description, workerId];
}