

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/purchase_model.dart';

class PurchasesProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<PurchaseModel> _purchases = [];

  List<PurchaseModel> get purchases => _purchases;

  // ✅ Total de compras do mês atual
  double get total => _purchases.fold(0, (s, p) => s + p.amount);
  double get totalPix =>
      _purchases.where((p) => p.method == PaymentMethod.pix).fold(0, (s, p) => s + p.amount);
  double get totalDinheiro =>
      _purchases.where((p) => p.method == PaymentMethod.dinheiro).fold(0, (s, p) => s + p.amount);
  double get totalCartao =>
      _purchases.where((p) => p.method == PaymentMethod.cartao).fold(0, (s, p) => s + p.amount);

  void loadPurchases(String uid) {
    final now = DateTime.now();
    // ✅ Carrega apenas compras do mês atual
    final startOfMonth = DateTime(now.year, now.month, 1);

    _firestore
        .collection('users')
        .doc(uid)
        .collection('purchases')
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snap) {
      _purchases = snap.docs
          .map((d) => PurchaseModel.fromMap({...d.data(), 'id': d.id}))
          // ✅ Filtra só do mês corrente
          .where((p) => p.date.isAfter(startOfMonth.subtract(const Duration(seconds: 1))))
          .toList();
      notifyListeners();
    });
  }

  Future<void> addPurchase(PurchaseModel purchase) async {
    await _firestore
        .collection('users')
        .doc(purchase.uid)
        .collection('purchases')
        .doc(purchase.id)
        .set(purchase.toMap());
  }

  Future<void> updatePurchase(PurchaseModel purchase) async {
    await _firestore
        .collection('users')
        .doc(purchase.uid)
        .collection('purchases')
        .doc(purchase.id)
        .update(purchase.toMap());
  }

  Future<void> deletePurchase(String uid, String purchaseId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('purchases')
        .doc(purchaseId)
        .delete();
  }
}