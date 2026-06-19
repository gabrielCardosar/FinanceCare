import 'package:flutter/material.dart';

class CardModel {
  final String? id;
  final String uid;
  final String cardName;
  final String bankName;
  final double limit;
  final double usedLimit;
  final DateTime createdAt;
  final int colorValue;
  final int? invoiceDueDay; // Dia do vencimento da fatura (1-31)

  CardModel({
    this.id,
    required this.uid,
    required this.cardName,
    required this.bankName,
    required this.limit,
    this.usedLimit = 0,
    DateTime? createdAt,
    this.colorValue = 0xFF6366F1,
    this.invoiceDueDay,
  }) : createdAt = createdAt ?? DateTime.now();

  Color get color => Color(colorValue);

  double get availableLimit => limit - usedLimit;
  double get percentageUsed => limit > 0 ? (usedLimit / limit) * 100 : 0;

  /// Retorna a próxima data de vencimento da fatura
  DateTime? get nextInvoiceDate {
    if (invoiceDueDay == null) return null;
    final now = DateTime.now();
    int day = invoiceDueDay!.clamp(1, 28); // seguro para todos os meses
    DateTime candidate = DateTime(now.year, now.month, day);
    if (candidate.isBefore(now)) {
      // Já passou esse mês, retorna próximo mês
      candidate = DateTime(now.year, now.month + 1, day);
    }
    return candidate;
  }

  int? get daysUntilInvoice {
    final next = nextInvoiceDate;
    if (next == null) return null;
    return next.difference(DateTime.now()).inDays;
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'cardName': cardName,
      'bankName': bankName,
      'limit': limit,
      'usedLimit': usedLimit,
      'createdAt': createdAt.toIso8601String(),
      'colorValue': colorValue,
      'invoiceDueDay': invoiceDueDay,
    };
  }

  factory CardModel.fromMap(Map<String, dynamic> map, String id) {
    return CardModel(
      id: id,
      uid: map['uid'] ?? '',
      cardName: map['cardName'] ?? '',
      bankName: map['bankName'] ?? '',
      limit: (map['limit'] ?? 0).toDouble(),
      usedLimit: (map['usedLimit'] ?? 0).toDouble(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      colorValue: map['colorValue'] ?? 0xFF6366F1,
      invoiceDueDay: map['invoiceDueDay'],
    );
  }

  CardModel copyWith({
    String? id,
    String? uid,
    String? cardName,
    String? bankName,
    double? limit,
    double? usedLimit,
    DateTime? createdAt,
    int? colorValue,
    Object? invoiceDueDay = _sentinel,
  }) {
    return CardModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      cardName: cardName ?? this.cardName,
      bankName: bankName ?? this.bankName,
      limit: limit ?? this.limit,
      usedLimit: usedLimit ?? this.usedLimit,
      createdAt: createdAt ?? this.createdAt,
      colorValue: colorValue ?? this.colorValue,
      invoiceDueDay: invoiceDueDay == _sentinel
          ? this.invoiceDueDay
          : invoiceDueDay as int?,
    );
  }
}

// sentinel para permitir passar null explicitamente em copyWith
const Object _sentinel = Object();
