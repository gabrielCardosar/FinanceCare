
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bill_payable_model.dart';

class BillsPayableProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<BillPayableModel> _bills = [];
  final bool _isLoading = false;

  List<BillPayableModel> get bills => _bills;
  bool get isLoading => _isLoading;

  List<BillPayableModel> get pendingBills => _bills.where((b) => !b.isPaid).toList();
  List<BillPayableModel> get paidBills => _bills.where((b) => b.isPaid).toList();
  List<BillPayableModel> get urgentBills =>
      _bills.where((b) => !b.isPaid && b.urgency == UrgencyLevel.urgente).toList();
  List<BillPayableModel> get fixedBills => _bills.where((b) => b.isFixed).toList();

  // ✅ Total PENDENTE (para exibição)
  double get totalPending =>
      _bills.where((b) => !b.isPaid).fold(0, (s, b) => s + b.amount);

  // ✅ Total PAGO (para descontar do saldo)
  double get totalPaid =>
      _bills.where((b) => b.isPaid).fold(0, (s, b) => s + b.amount);

  void loadBills(String uid) {
    _firestore
        .collection('users')
        .doc(uid)
        .collection('bills')
        .orderBy('dueDate')
        .snapshots()
        .listen((snap) {
      _bills = snap.docs
          .map((d) => BillPayableModel.fromMap({...d.data(), 'id': d.id}))
          .toList();
      notifyListeners();
    });
  }

  Future<void> addBill(BillPayableModel bill) async {
    await _firestore
        .collection('users')
        .doc(bill.uid)
        .collection('bills')
        .doc(bill.id)
        .set(bill.toMap());
  }

  Future<void> updateBill(BillPayableModel bill) async {
    await _firestore
        .collection('users')
        .doc(bill.uid)
        .collection('bills')
        .doc(bill.id)
        .update(bill.toMap());
  }

  // ✅ togglePaid: simplesmente inverte isPaid no Firestore
  // O saldo é calculado automaticamente no home_screen
  // NÃO mexe no salário aqui
  Future<void> togglePaid(BillPayableModel bill) async {
    final updated = bill.copyWith(isPaid: !bill.isPaid);
    await updateBill(updated);
  }

  Future<void> deleteBill(String uid, String billId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('bills')
        .doc(billId)
        .delete();
  }

  // Reset mensal: marca não-fixas como não pagas
  Future<void> monthlyReset(String uid) async {
    for (final bill in _bills) {
      if (!bill.isFixed && bill.isPaid) {
        await updateBill(bill.copyWith(isPaid: false));
      }
    }
  }
}