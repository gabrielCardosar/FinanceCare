import 'package:flutter/material.dart';

enum UrgencyLevel { leve, moderado, urgente }

extension UrgencyLevelExtension on UrgencyLevel {
  String get label {
    switch (this) {
      case UrgencyLevel.leve:
        return 'Leve';
      case UrgencyLevel.moderado:
        return 'Moderado';
      case UrgencyLevel.urgente:
        return 'Urgente';
    }
  }

  Color get color {
    switch (this) {
      case UrgencyLevel.leve:
        return const Color(0xFF10B981);
      case UrgencyLevel.moderado:
        return const Color(0xFFF59E0B);
      case UrgencyLevel.urgente:
        return const Color(0xFFEF4444);
    }
  }

  IconData get icon {
    switch (this) {
      case UrgencyLevel.leve:
        return Icons.check_circle_outline;
      case UrgencyLevel.moderado:
        return Icons.warning_amber_outlined;
      case UrgencyLevel.urgente:
        return Icons.error_outline;
    }
  }

  String get value => name;
}

class BillPayableModel {
  final String id;
  final String uid;
  final String name;
  final double amount;
  final DateTime dueDate;
  final UrgencyLevel urgency;
  final bool isPaid;
  final bool isFixed; // Conta fixa: não é deletada no reset mensal
  final DateTime createdAt;

  BillPayableModel({
    required this.id,
    required this.uid,
    required this.name,
    required this.amount,
    required this.dueDate,
    this.urgency = UrgencyLevel.leve,
    this.isPaid = false,
    this.isFixed = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isOverdue =>
      !isPaid &&
      dueDate.isBefore(DateTime.now().subtract(const Duration(days: 1)));

  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'name': name,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'urgency': urgency.value,
      'isPaid': isPaid,
      'isFixed': isFixed,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BillPayableModel.fromMap(Map<String, dynamic> map) {
    return BillPayableModel(
      id: map['id'] ?? '',
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'])
          : DateTime.now(),
      urgency: UrgencyLevel.values.firstWhere(
        (e) => e.value == (map['urgency'] ?? 'leve'),
        orElse: () => UrgencyLevel.leve,
      ),
      isPaid: map['isPaid'] ?? false,
      isFixed: map['isFixed'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  BillPayableModel copyWith({
    String? id,
    String? uid,
    String? name,
    double? amount,
    DateTime? dueDate,
    UrgencyLevel? urgency,
    bool? isPaid,
    bool? isFixed,
    DateTime? createdAt,
  }) {
    return BillPayableModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      urgency: urgency ?? this.urgency,
      isPaid: isPaid ?? this.isPaid,
      isFixed: isFixed ?? this.isFixed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
