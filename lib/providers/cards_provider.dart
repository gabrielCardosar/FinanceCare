

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/card_model.dart';

class CardsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<CardModel> _cards = [];

  List<CardModel> get cards => _cards;

  // ✅ Total de faturas PAGAS (desconta do saldo)
  // Cartões têm um campo invoicePaid: quando o usuário paga a fatura,
  // o valor vai para cá e o usedLimit volta a 0
  double get totalPaidInvoices =>
      _cards.fold(0, (s, c) => s + c.paidInvoiceAmount);

  // Total de faturas pendentes (só informativo, NÃO desconta do saldo)
  double get totalPendingInvoices =>
      _cards.fold(0, (s, c) => s + c.usedLimit);

  void loadCards(String uid) {
    _firestore
        .collection('users')
        .doc(uid)
        .collection('cards')
        .snapshots()
        .listen((snap) {
      _cards = snap.docs
          .map((d) => CardModel.fromMap(d.data(), d.id))
          .toList();
      notifyListeners();
    });
  }

  Future<void> addCard(CardModel card) async {
    final ref = _firestore
        .collection('users')
        .doc(card.uid)
        .collection('cards')
        .doc();
    await ref.set({...card.toMap(), 'id': ref.id});
  }

  Future<void> updateCard(CardModel card) async {
    if (card.id == null) return;
    await _firestore
        .collection('users')
        .doc(card.uid)
        .collection('cards')
        .doc(card.id)
        .update(card.toMap());
  }

  Future<void> deleteCard(String uid, String cardId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('cards')
        .doc(cardId)
        .delete();
  }

  // ✅ Pagar fatura: zera usedLimit, acumula em paidInvoiceAmount, avança parcelamentos
  Future<void> payInvoice(CardModel card) async {
    final updatedInst = card.installments
        .map((i) => i.copyWith(remainingInstallments: i.remainingInstallments - 1))
        .where((i) => i.remainingInstallments > 0)
        .toList();

    final nextUsed = updatedInst.fold<double>(0, (s, i) => s + i.installmentAmount);

    // Acumula o valor pago e zera a fatura atual
    final updatedCard = card.copyWith(
      usedLimit: nextUsed,
      installments: updatedInst,
      // paidInvoiceAmount acumula o que foi pago este mês
      paidInvoiceAmount: card.paidInvoiceAmount + card.usedLimit,
    );
    await updateCard(updatedCard);
  }

  // Reset mensal: zera paidInvoiceAmount
  Future<void> monthlyReset(String uid) async {
    for (final card in _cards) {
      if (card.paidInvoiceAmount > 0) {
        await updateCard(card.copyWith(paidInvoiceAmount: 0));
      }
    }
  }
}