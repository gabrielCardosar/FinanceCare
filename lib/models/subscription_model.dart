import 'package:flutter/material.dart';

class SubscriptionModel {
  final String? id;
  final String uid;
  final String name;
  final double monthlyValue;
  final String? description;
  final DateTime startDate;
  final bool isActive;
  final int colorValue;

  SubscriptionModel({
    this.id,
    required this.uid,
    required this.name,
    required this.monthlyValue,
    this.description,
    DateTime? startDate,
    this.isActive = true,
    this.colorValue = 0xFF8B5CF6,
  }) : startDate = startDate ?? DateTime.now();

  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'monthlyValue': monthlyValue,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'isActive': isActive,
      'colorValue': colorValue,
    };
  }

  factory SubscriptionModel.fromMap(Map<String, dynamic> map, String id) {
    return SubscriptionModel(
      id: id,
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      monthlyValue: (map['monthlyValue'] ?? 0).toDouble(),
      description: map['description'],
      startDate: map['startDate'] != null
          ? DateTime.parse(map['startDate'])
          : DateTime.now(),
      isActive: map['isActive'] ?? true,
      colorValue: map['colorValue'] ?? 0xFF8B5CF6,
    );
  }

  SubscriptionModel copyWith({
    String? id,
    String? uid,
    String? name,
    double? monthlyValue,
    String? description,
    DateTime? startDate,
    bool? isActive,
    int? colorValue,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      name: name ?? this.name,
      monthlyValue: monthlyValue ?? this.monthlyValue,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      isActive: isActive ?? this.isActive,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}
