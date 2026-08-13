

class ExtraIncomeModel {
  final String id;
  final String uid;
  final String description;
  final double amount;
  final DateTime date;

  ExtraIncomeModel({
    required this.id,
    required this.uid,
    required this.description,
    required this.amount,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'uid': uid,
        'description': description,
        'amount': amount,
        'date': date.toIso8601String(),
      };

  factory ExtraIncomeModel.fromMap(Map<String, dynamic> map) => ExtraIncomeModel(
        id: map['id'] ?? '',
        uid: map['uid'] ?? '',
        description: map['description'] ?? '',
        amount: (map['amount'] ?? 0).toDouble(),
        date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      );

  ExtraIncomeModel copyWith({String? description, double? amount}) => ExtraIncomeModel(
        id: id,
        uid: uid,
        description: description ?? this.description,
        amount: amount ?? this.amount,
        date: date,
      );
}