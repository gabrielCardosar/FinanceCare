class AccountModel {
  final String? id;
  final String uid;
  final double salary;
  final double extraIncome; // renda extra (fora da renda fixa)
  final List<BillModel> bills;
  final DateTime createdAt;
  final DateTime updatedAt;

  AccountModel({
    this.id,
    required this.uid,
    required this.salary,
    this.extraIncome = 0,
    this.bills = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get totalBills => bills.fold(0, (sum, bill) => sum + bill.amount);

  // Renda total = salário + renda extra
  double get totalIncome => salary + extraIncome;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'salary': salary,
      'extraIncome': extraIncome,
      'bills': bills.map((b) => b.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AccountModel.fromMap(Map<String, dynamic> map, String id) {
    return AccountModel(
      id: id,
      uid: map['uid'] ?? '',
      salary: (map['salary'] ?? 0).toDouble(),
      extraIncome: (map['extraIncome'] ?? 0).toDouble(),
      bills: (map['bills'] as List<dynamic>?)
              ?.map((b) => BillModel.fromMap(b as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }

  AccountModel copyWith({
    String? id,
    String? uid,
    double? salary,
    double? extraIncome,
    List<BillModel>? bills,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AccountModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      salary: salary ?? this.salary,
      extraIncome: extraIncome ?? this.extraIncome,
      bills: bills ?? this.bills,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class BillModel {
  final String id;
  final String name;
  final double amount;
  final DateTime dueDate;
  final bool isPaid;

  BillModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    this.isPaid = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'isPaid': isPaid,
    };
  }

  factory BillModel.fromMap(Map<String, dynamic> map) {
    return BillModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'])
          : DateTime.now(),
      isPaid: map['isPaid'] ?? false,
    );
  }

  BillModel copyWith({
    String? id,
    String? name,
    double? amount,
    DateTime? dueDate,
    bool? isPaid,
  }) {
    return BillModel(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
    );
  }
}