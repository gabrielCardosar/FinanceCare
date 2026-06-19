import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../services/firestore_service.dart';

class CardsProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<CardModel> _cards = [];
  bool _isLoading = false;
  String? _error;

  List<CardModel> get cards => _cards;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void loadCards(String uid) {
    _firestoreService.getCards(uid).listen((cards) {
      _cards = cards;
      notifyListeners();
    });
  }

  Future<void> addCard(CardModel card) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestoreService.saveCard(card);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCard(CardModel card) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestoreService.saveCard(card);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteCard(String uid, String cardId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestoreService.deleteCard(uid, cardId);
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