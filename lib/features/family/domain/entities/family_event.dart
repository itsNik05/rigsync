import 'package:equatable/equatable.dart';

class FamilyEvent extends Equatable {
  const FamilyEvent({
    required this.id,
    required this.title,
    required this.date,
    this.description,
    this.colorHex,
  });

  final String id;
  final String title;
  final DateTime date;
  final String? description;
  final String? colorHex;

  @override
  List<Object?> get props => [id, title, date, description, colorHex];
}