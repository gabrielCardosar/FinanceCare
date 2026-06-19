import 'package:flutter/material.dart';
import '../models/subscription_model.dart';
import '../services/firestore_service.dart';

class SubscriptionsProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<SubscriptionModel> _subscriptions = [];
  bool _isLoading = false;
  String? _error;

  List<SubscriptionModel> get subscriptions => _subscriptions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void loadSubscriptions(String uid) {
    _firestoreService.getSubscriptions(uid).listen((subs) {
      _subscriptions = subs;
      notifyListeners();
    });
  }

  Future<void> addSubscription(SubscriptionModel subscription) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _firestoreService.saveSubscription(subscription);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSubscription(SubscriptionModel subscription) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _firestoreService.saveSubscription(subscription);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteSubscription(String uid, String subscriptionId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _firestoreService.deleteSubscription(uid, subscriptionId);
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
