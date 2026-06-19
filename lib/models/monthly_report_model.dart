/// Snapshot financeiro salvo no final/início de cada mês.
class MonthlyReportModel {
  final String id; // formato: "YYYY-MM"  ex: "2025-06"
  final String uid;
  final int year;
  final int month;
  final double salary;
  final double totalSubscriptions;
  final double totalBillsPaid;
  final double totalBillsUnpaid;
  final double totalCardUsed;
  final double finalBalance;
  final List<ReportBillItem> bills;
  final List<ReportSubscriptionItem> subscriptions;
  final List<ReportCardItem> cards;
  final DateTime savedAt;

  MonthlyReportModel({
    required this.id,
    required this.uid,
    required this.year,
    required this.month,
    required this.salary,
    required this.totalSubscriptions,
    required this.totalBillsPaid,
    required this.totalBillsUnpaid,
    required this.totalCardUsed,
    required this.finalBalance,
    required this.bills,
    required this.subscriptions,
    required this.cards,
    DateTime? savedAt,
  }) : savedAt = savedAt ?? DateTime.now();

  String get monthLabel {
    const months = [
      '', 'Janeiro', 'Fevereiro', 'Março', 'Abril',
      'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro',
      'Outubro', 'Novembro', 'Dezembro'
    ];
    return '${months[month]} $year';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'year': year,
      'month': month,
      'salary': salary,
      'totalSubscriptions': totalSubscriptions,
      'totalBillsPaid': totalBillsPaid,
      'totalBillsUnpaid': totalBillsUnpaid,
      'totalCardUsed': totalCardUsed,
      'finalBalance': finalBalance,
      'bills': bills.map((b) => b.toMap()).toList(),
      'subscriptions': subscriptions.map((s) => s.toMap()).toList(),
      'cards': cards.map((c) => c.toMap()).toList(),
      'savedAt': savedAt.toIso8601String(),
    };
  }

  factory MonthlyReportModel.fromMap(Map<String, dynamic> map) {
    return MonthlyReportModel(
      id: map['id'] ?? '',
      uid: map['uid'] ?? '',
      year: map['year'] ?? 0,
      month: map['month'] ?? 0,
      salary: (map['salary'] ?? 0).toDouble(),
      totalSubscriptions: (map['totalSubscriptions'] ?? 0).toDouble(),
      totalBillsPaid: (map['totalBillsPaid'] ?? 0).toDouble(),
      totalBillsUnpaid: (map['totalBillsUnpaid'] ?? 0).toDouble(),
      totalCardUsed: (map['totalCardUsed'] ?? 0).toDouble(),
      finalBalance: (map['finalBalance'] ?? 0).toDouble(),
      bills: (map['bills'] as List<dynamic>?)
              ?.map((b) => ReportBillItem.fromMap(b as Map<String, dynamic>))
              .toList() ??
          [],
      subscriptions: (map['subscriptions'] as List<dynamic>?)
              ?.map((s) =>
                  ReportSubscriptionItem.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      cards: (map['cards'] as List<dynamic>?)
              ?.map((c) => ReportCardItem.fromMap(c as Map<String, dynamic>))
              .toList() ??
          [],
      savedAt: map['savedAt'] != null
          ? DateTime.parse(map['savedAt'])
          : DateTime.now(),
    );
  }
}

class ReportBillItem {
  final String name;
  final double amount;
  final bool isPaid;
  final bool isFixed;
  final String urgency;

  ReportBillItem({
    required this.name,
    required this.amount,
    required this.isPaid,
    required this.isFixed,
    required this.urgency,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'amount': amount,
        'isPaid': isPaid,
        'isFixed': isFixed,
        'urgency': urgency,
      };

  factory ReportBillItem.fromMap(Map<String, dynamic> map) => ReportBillItem(
        name: map['name'] ?? '',
        amount: (map['amount'] ?? 0).toDouble(),
        isPaid: map['isPaid'] ?? false,
        isFixed: map['isFixed'] ?? false,
        urgency: map['urgency'] ?? 'leve',
      );
}

class ReportSubscriptionItem {
  final String name;
  final double monthlyValue;

  ReportSubscriptionItem({required this.name, required this.monthlyValue});

  Map<String, dynamic> toMap() =>
      {'name': name, 'monthlyValue': monthlyValue};

  factory ReportSubscriptionItem.fromMap(Map<String, dynamic> map) =>
      ReportSubscriptionItem(
        name: map['name'] ?? '',
        monthlyValue: (map['monthlyValue'] ?? 0).toDouble(),
      );
}

class ReportCardItem {
  final String cardName;
  final String bankName;
  final double limit;
  final double usedLimit;
  final int colorValue;

  ReportCardItem({
    required this.cardName,
    required this.bankName,
    required this.limit,
    required this.usedLimit,
    required this.colorValue,
  });

  Map<String, dynamic> toMap() => {
        'cardName': cardName,
        'bankName': bankName,
        'limit': limit,
        'usedLimit': usedLimit,
        'colorValue': colorValue,
      };

  factory ReportCardItem.fromMap(Map<String, dynamic> map) => ReportCardItem(
        cardName: map['cardName'] ?? '',
        bankName: map['bankName'] ?? '',
        limit: (map['limit'] ?? 0).toDouble(),
        usedLimit: (map['usedLimit'] ?? 0).toDouble(),
        colorValue: map['colorValue'] ?? 0xFF6366F1,
      );
}
