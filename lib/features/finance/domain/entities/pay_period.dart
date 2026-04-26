import 'package:equatable/equatable.dart';

class PayPeriod extends Equatable {
  const PayPeriod({
    required this.id,
    required this.workerId,
    required this.periodStart,
    required this.periodEnd,
    this.dailyRate,
    this.totalExpected,
    this.totalActual,
    this.isPaid = false,
  });

  final String id;
  final String workerId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double? dailyRate;
  final double? totalExpected;
  final double? totalActual;
  final bool isPaid;

  int get durationDays => periodEnd.difference(periodStart).inDays + 1;

  double get calculatedExpected {
    if (totalExpected != null && totalExpected! > 0) return totalExpected!;
    if (dailyRate != null && dailyRate! > 0) return dailyRate! * durationDays;
    return 0.0;
  }

  @override
  List<Object?> get props => [
    id, workerId, periodStart, periodEnd,
    dailyRate, totalExpected, totalActual, isPaid,
  ];
}