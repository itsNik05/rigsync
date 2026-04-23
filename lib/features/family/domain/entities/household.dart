import 'package:equatable/equatable.dart';

class Household extends Equatable {
  const Household({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.inviteCode,
    required this.memberIds,
    required this.createdAt,
  });

  final String id;
  final String ownerId;
  final String ownerName;
  final String inviteCode;
  final List<String> memberIds;
  final DateTime createdAt;

  factory Household.fromMap(Map<String, dynamic> map, String docId) {
    return Household(
      id: docId,
      ownerId: map['ownerId'] as String,
      ownerName: map['ownerName'] as String? ?? 'Worker',
      inviteCode: map['inviteCode'] as String,
      memberIds: List<String>.from(map['memberIds'] as List? ?? []),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['createdAt'] as int? ?? 0),
    );
  }

  Map<String, dynamic> toMap() => {
    'ownerId': ownerId,
    'ownerName': ownerName,
    'inviteCode': inviteCode,
    'memberIds': memberIds,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  @override
  List<Object?> get props =>
      [id, ownerId, ownerName, inviteCode, memberIds, createdAt];
}