

enum PaymentMethod { pix, dinheiro, cartao }

extension PaymentMethodExt on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.pix: return 'PIX';
      case PaymentMethod.dinheiro: return 'Dinheiro';
      case PaymentMethod.cartao: return 'Cartão';
    }
  }
  String get value => name;
}

class PurchaseModel {
  final String id;
  final String uid;
  final String description;
  final double amount;
  final PaymentMethod method;
  final String? cardId;    // só quando method == cartao
  final String? cardName;  // nome do cartão (para exibir mesmo se o cartão for deletado)
  final int installments;  // parcelas (só cartão)
  final DateTime date;

  PurchaseModel({
    required this.id,
    required this.uid,
    required this.description,
    required this.amount,
    required this.method,
    this.cardId,
    this.cardName,
    this.installments = 1,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  bool get isCard => method == PaymentMethod.cartao;

  Map<String, dynamic> toMap() => {
        'id': id,
        'uid': uid,
        'description': description,
        'amount': amount,
        'method': method.value,
        'cardId': cardId,
        'cardName': cardName,
        'installments': installments,
        'date': date.toIso8601String(),
      };

  factory PurchaseModel.fromMap(Map<String, dynamic> map) => PurchaseModel(
        id: map['id'] ?? '',
        uid: map['uid'] ?? '',
        description: map['description'] ?? '',
        amount: (map['amount'] ?? 0).toDouble(),
        method: PaymentMethod.values.firstWhere(
          (e) => e.value == (map['method'] ?? 'pix'),
          orElse: () => PaymentMethod.pix,
        ),
        cardId: map['cardId'],
        cardName: map['cardName'],
        installments: ((map['installments'] ?? 1) as num).toInt(),
        date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      );

  PurchaseModel copyWith({
    String? description,
    double? amount,
    PaymentMethod? method,
    String? cardId,
    String? cardName,
    int? installments,
  }) =>
      PurchaseModel(
        id: id,
        uid: uid,
        description: description ?? this.description,
        amount: amount ?? this.amount,
        method: method ?? this.method,
        cardId: cardId ?? this.cardId,
        cardName: cardName ?? this.cardName,
        installments: installments ?? this.installments,
        date: date,
      );
}