import 'package:flutter/material.dart';
import '../models/bill_payable_model.dart';
import '../services/firestore_service.dart';

class BillsPayableProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<BillPayableModel> _bills = [];
  bool _isLoading = false;
  String? _error;

  List<BillPayableModel> get bills => _bills;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<BillPayableModel> get urgentBills =>
      _bills.where((b) => b.urgency == UrgencyLevel.urgente && !b.isPaid).toList();

  List<BillPayableModel> get pendingBills =>
      _bills.where((b) => !b.isPaid).toList();

  List<BillPayableModel> get fixedBills =>
      _bills.where((b) => b.isFixed).toList();

  List<BillPayableModel> get variableBills =>
      _bills.where((b) => !b.isFixed).toList();

  double get totalPending =>
      _bills.where((b) => !b.isPaid).fold(0, (sum, b) => sum + b.amount);

  double get totalPaid =>
      _bills.where((b) => b.isPaid).fold(0, (sum, b) => sum + b.amount);

  void loadBills(String uid) {
    _firestoreService.getBillsPayable(uid).listen((bills) {
      _bills = bills;
      notifyListeners();
    });
  }

  Future<void> addBill(BillPayableModel bill) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _firestoreService.saveBillPayable(bill);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateBill(BillPayableModel bill) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _firestoreService.saveBillPayable(bill);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> togglePaid(BillPayableModel bill) async {
    final updated = bill.copyWith(isPaid: !bill.isPaid);
    await updateBill(updated);
  }

  Future<void> deleteBill(String uid, String billId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _firestoreService.deleteBillPayable(uid, billId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
