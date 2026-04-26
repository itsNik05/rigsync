import 'package:equatable/equatable.dart';

/// Represents a worker whose schedule is being tracked.
class Worker extends Equatable {
  const Worker({
    required this.id,
    required this.name,
    required this.colorHex,
    this.avatarUrl,
    this.role,
    this.isOwner = false,
  });

  final String id;
  final String name;
  final String colorHex;
  final String? avatarUrl;
  final String? role;
  final bool isOwner; // True if this is the logged-in user's own profile

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  Worker copyWith({
    String? id,
    String? name,
    String? colorHex,
    String? avatarUrl,
    String? role,
    bool? isOwner,
  }) {
    return Worker(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isOwner: isOwner ?? this.isOwner,
    );
  }

  @override
  List<Object?> get props => [id, name, colorHex, avatarUrl, role, isOwner];
}