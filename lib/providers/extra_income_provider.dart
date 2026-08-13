

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/extra_income_model.dart';

class ExtraIncomeProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<ExtraIncomeModel> _items = [];

  List<ExtraIncomeModel> get items => _items;
  double get total => _items.fold(0, (s, i) => s + i.amount);

  void load(String uid) {
    _firestore
        .collection('users')
        .doc(uid)
        .collection('extra_income')
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snap) {
      _items = snap.docs
          .map((d) => ExtraIncomeModel.fromMap({...d.data(), 'id': d.id}))
          .toList();
      notifyListeners();
    });
  }

  Future<void> add(ExtraIncomeModel item) async {
    await _firestore
        .collection('users')
        .doc(item.uid)
        .collection('extra_income')
        .doc(item.id)
        .set(item.toMap());
  }

  Future<void> update(ExtraIncomeModel item) async {
    await _firestore
        .collection('users')
        .doc(item.uid)
        .collection('extra_income')
        .doc(item.id)
        .update(item.toMap());
  }

  Future<void> delete(String uid, String id) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('extra_income')
        .doc(id)
        .delete();
  }
}