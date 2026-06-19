import 'package:flutter/material.dart';
import '../models/account_model.dart';
import '../services/firestore_service.dart';

class HomeProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  AccountModel? _account;
  bool _isLoading = false;
  String? _error;

  AccountModel? get account => _account;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void loadAccount(String uid) {
    _firestoreService.getAccount(uid).listen((account) {
      _account = account ?? AccountModel(uid: uid, salary: 0);
      notifyListeners();
    });
  }

  Future<void> updateAccount(AccountModel account) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestoreService.saveAccount(account);
      _account = account;
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
