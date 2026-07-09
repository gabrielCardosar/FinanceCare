import 'package:flutter/material.dart';

// Modelo de parcela de um cartão
class CardInstallment {
  final String id;
  final String description;
  final double totalAmount;      // valor total da compra
  final double installmentAmount; // valor de cada parcela
  final int totalInstallments;   // total de parcelas
  final int remainingInstallments; // parcelas restantes
  final DateTime purchaseDate;

  CardInstallment({
    required this.id,
    required this.description,
    required this.totalAmount,
    required this.installmentAmount,
    required this.totalInstallments,
    required this.remainingInstallments,
    required this.purchaseDate,
  });

  // Valor que entra na fatura atual
  double get currentInvoiceAmount => installmentAmount;

  Map<String, dynamic> toMap() => {
        'id': id,
        'description': description,
        'totalAmount': totalAmount,
        'installmentAmount': installmentAmount,
        'totalInstallments': totalInstallments,
        'remainingInstallments': remainingInstallments,
        'purchaseDate': purchaseDate.toIso8601String(),
      };

  factory CardInstallment.fromMap(Map<String, dynamic> map) => CardInstallment(
        id: map['id'] ?? '',
        description: map['description'] ?? '',
        totalAmount: (map['totalAmount'] ?? 0).toDouble(),
        installmentAmount: (map['installmentAmount'] ?? 0).toDouble(),
        totalInstallments: map['totalInstallments'] ?? 1,
        remainingInstallments: map['remainingInstallments'] ?? 1,
        purchaseDate: map['purchaseDate'] != null
            ? DateTime.parse(map['purchaseDate'])
            : DateTime.now(),
      );

  CardInstallment copyWith({
    int? remainingInstallments,
  }) =>
      CardInstallment(
        id: id,
        description: description,
        totalAmount: totalAmount,
        installmentAmount: installmentAmount,
        totalInstallments: totalInstallments,
        remainingInstallments: remainingInstallments ?? this.remainingInstallments,
        purchaseDate: purchaseDate,
      );
}

class CardModel {
  final String? id;
  final String uid;
  final String cardName;
  final String bankName;
  final double limit;
  final double usedLimit;
  final DateTime createdAt;
  final int colorValue;
  final int? invoiceDueDay;     // dia do VENCIMENTO da fatura (ex: 15)
  final int? invoiceClosingDay; // dia do FECHAMENTO da fatura (ex: 8)
  final List<CardInstallment> installments; // parcelamentos ativos

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
    this.invoiceClosingDay,
    this.installments = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  Color get color => Color(colorValue);

  double get availableLimit => limit - usedLimit;
  double get percentageUsed => limit > 0 ? (usedLimit / limit) * 100 : 0;

  // Total das parcelas na fatura atual
  double get installmentsInCurrentInvoice =>
      installments.fold(0, (sum, i) => sum + i.currentInvoiceAmount);

  // Data de vencimento da próxima fatura
  DateTime? get nextInvoiceDate {
    if (invoiceDueDay == null) return null;
    final now = DateTime.now();
    int day = invoiceDueDay!.clamp(1, 28);
    DateTime candidate = DateTime(now.year, now.month, day);
    if (candidate.isBefore(now)) {
      candidate = DateTime(now.year, now.month + 1, day);
    }
    return candidate;
  }

  // Data de fechamento da próxima fatura
  DateTime? get nextClosingDate {
    if (invoiceClosingDay == null) return null;
    final now = DateTime.now();
    int day = invoiceClosingDay!.clamp(1, 28);
    DateTime candidate = DateTime(now.year, now.month, day);
    if (candidate.isBefore(now)) {
      candidate = DateTime(now.year, now.month + 1, day);
    }
    return candidate;
  }

  int? get daysUntilInvoice {
    final next = nextInvoiceDate;
    if (next == null) return null;
    return next.difference(DateTime.now()).inDays;
  }

  int? get daysUntilClosing {
    final next = nextClosingDate;
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
      'invoiceClosingDay': invoiceClosingDay,
      'installments': installments.map((i) => i.toMap()).toList(),
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
      invoiceClosingDay: map['invoiceClosingDay'],
      installments: (map['installments'] as List<dynamic>?)
              ?.map((i) => CardInstallment.fromMap(i as Map<String, dynamic>))
              .toList() ??
          [],
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
    Object? invoiceClosingDay = _sentinel,
    List<CardInstallment>? installments,
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
      invoiceClosingDay: invoiceClosingDay == _sentinel
          ? this.invoiceClosingDay
          : invoiceClosingDay as int?,
      installments: installments ?? this.installments,
    );
  }
}

const Object _sentinel = Object();