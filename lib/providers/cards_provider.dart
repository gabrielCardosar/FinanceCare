import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/card_model.dart';

/// Cartões de crédito.
///
/// Cada compra no cartão vira um [CardTransaction] (em `card_transactions`) e
/// cada pagamento de fatura vira um [CardPayment] (em `card_payments`).
/// Faturas, limite usado e status são calculados a partir disso no [CardLedger].
///
/// Regra do saldo: compras no cartão NÃO saem do saldo na hora;
/// só o pagamento da fatura sai, na data em que é pago.
class CardsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<CardModel> _cards = [];
  List<CardTransaction> _transactions = [];
  List<CardPayment> _payments = [];
  final Map<String, CardLedger> _ledgers = {};
  final Set<String> _migrating = {};
  final List<StreamSubscription> _subs = [];

  List<CardModel> get cards => _cards;
  List<CardTransaction> get transactions => _transactions;
  List<CardPayment> get payments => _payments;

  CollectionReference<Map<String, dynamic>> _col(String uid, String name) =>
      _firestore.collection('users').doc(uid).collection(name);

  CardLedger ledgerOf(CardModel card) => _ledgers[card.id ?? ''] ??= CardLedger(
      card: card, transactions: _transactions, payments: _payments);

  List<CardLedger> get ledgers => _cards.map(ledgerOf).toList();

  CardModel? cardById(String? id) {
    for (final c in _cards) {
      if (c.id == id) return c;
    }
    return null;
  }

  // ── Totais (todos os cartões) ───────────────────────────────────────────

  double get totalLimit => _cards.fold(0, (s, c) => s + c.limit);
  double get totalUsedLimit => ledgers.fold(0, (s, l) => s + l.usedLimit);
  double get totalAvailable => ledgers.fold(0, (s, l) => s + l.availableLimit);

  /// Soma das faturas atuais (abertas) de todos os cartões.
  double get totalCurrentInvoices => ledgers.fold(
      0, (s, l) => s + l.invoiceRemaining(l.currentInvoice()));

  /// Faturas já fechadas e ainda não pagas.
  double get totalClosedOutstanding =>
      ledgers.fold(0, (s, l) => s + l.closedOutstanding());

  /// Pago em faturas no mês corrente — é o que desconta do saldo.
  double get totalPaidThisMonth {
    final now = DateTime.now();
    return ledgers.fold(
        0, (s, l) => s + l.paidInCalendarMonth(now.year, now.month));
  }

  /// A pagar em faturas que vencem até o fim do mês corrente.
  double get totalDueThisMonth {
    final now = DateTime.now();
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    return ledgers.fold(0, (s, l) => s + l.dueUntil(endOfMonth));
  }

  int get overdueCount => ledgers
      .where((l) => l
          .unpaidClosedInvoices()
          .any((m) => l.statusOf(m) == InvoiceStatus.atrasada))
      .length;

  // ── Carregamento ────────────────────────────────────────────────────────

  void loadCards(String uid) {
    for (final s in _subs) {
      s.cancel();
    }
    _subs
      ..clear()
      ..add(_col(uid, 'cards').snapshots().listen((snap) {
        _cards = snap.docs.map((d) => CardModel.fromMap(d.data(), d.id)).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        _changed();
        for (final c in _cards.where((c) => c.needsMigration)) {
          _migrateLegacyCard(c);
        }
      }))
      ..add(_col(uid, 'card_transactions').snapshots().listen((snap) {
        _transactions = snap.docs
            .map((d) => CardTransaction.fromMap({...d.data(), 'id': d.id}))
            .toList();
        _changed();
      }))
      ..add(_col(uid, 'card_payments').snapshots().listen((snap) {
        _payments = snap.docs
            .map((d) => CardPayment.fromMap({...d.data(), 'id': d.id}))
            .toList();
        _changed();
      }));
  }

  void _changed() {
    _ledgers.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  // ── Cartões ─────────────────────────────────────────────────────────────

  Future<void> addCard(CardModel card) async {
    final ref = _col(card.uid, 'cards').doc();
    await ref.set({...card.toMap(), 'id': ref.id});
  }

  Future<void> updateCard(CardModel card) async {
    if (card.id == null) return;
    await _col(card.uid, 'cards').doc(card.id).update(card.toMap());
  }

  /// Exclui o cartão junto com seus lançamentos e pagamentos.
  Future<void> deleteCard(String uid, String cardId) async {
    final batch = _firestore.batch();
    for (final name in ['card_transactions', 'card_payments']) {
      final docs =
          await _col(uid, name).where('cardId', isEqualTo: cardId).get();
      for (final d in docs.docs) {
        batch.delete(d.reference);
      }
    }
    batch.delete(_col(uid, 'cards').doc(cardId));
    await batch.commit();
  }

  // ── Compras ─────────────────────────────────────────────────────────────

  /// Cria uma compra calculando em qual fatura ela cai.
  CardTransaction buildTransaction({
    required String id,
    required CardModel card,
    required String description,
    required double totalAmount,
    int installments = 1,
    DateTime? purchaseDate,
  }) {
    final date = purchaseDate ?? DateTime.now();
    return CardTransaction(
      id: id,
      uid: card.uid,
      cardId: card.id!,
      description: description,
      totalAmount: totalAmount,
      installments: installments,
      purchaseDate: date,
      firstInvoice: card.invoiceFor(date),
    );
  }

  Future<void> saveTransaction(CardTransaction tx) async {
    await _col(tx.uid, 'card_transactions').doc(tx.id).set(tx.toMap());
  }

  Future<void> deleteTransaction(String uid, String txId) async {
    await _col(uid, 'card_transactions').doc(txId).delete();
  }

  // ── Pagamentos ──────────────────────────────────────────────────────────

  Future<void> payInvoice({
    required CardModel card,
    required InvoiceMonth invoice,
    required double amount,
  }) async {
    if (amount <= 0) return;
    final ref = _col(card.uid, 'card_payments').doc();
    await ref.set(CardPayment(
      id: ref.id,
      uid: card.uid,
      cardId: card.id!,
      amount: amount,
      invoice: invoice,
    ).toMap());
  }

  Future<void> deletePayment(String uid, String paymentId) async {
    await _col(uid, 'card_payments').doc(paymentId).delete();
  }

  // ── Migração do formato antigo (usedLimit + installments no cartão) ─────

  Future<void> _migrateLegacyCard(CardModel card) async {
    if (card.id == null || !_migrating.add(card.id!)) return;
    try {
      final now = DateTime.now();
      final current = card.invoiceFor(now);
      final batch = _firestore.batch();
      final txCol = _col(card.uid, 'card_transactions');

      void addTx(String desc, double total, int n, InvoiceMonth first,
          DateTime date) {
        final ref = txCol.doc();
        batch.set(
            ref,
            CardTransaction(
              id: ref.id,
              uid: card.uid,
              cardId: card.id!,
              description: desc,
              totalAmount: total,
              installments: n,
              purchaseDate: date,
              firstInvoice: first,
            ).toMap());
      }

      // Parcelamentos: as parcelas restantes continuam a partir da fatura atual
      double installmentsInInvoice = 0;
      for (final i in card.legacyInstallments) {
        if (i.remainingInstallments <= 0) continue;
        installmentsInInvoice += i.installmentAmount;
        addTx(i.description, i.installmentAmount * i.remainingInstallments,
            i.remainingInstallments, current, i.purchaseDate);
      }

      // O que sobrou da fatura antiga vira um lançamento único
      final rest = card.legacyUsedLimit - installmentsInInvoice;
      if (rest > 0.009) {
        addTx('Saldo anterior da fatura', rest, 1, current, now);
      }

      // Fatura já paga este mês: mantém o desconto no saldo
      if (card.legacyPaidInvoiceAmount > 0) {
        final previous = current.add(-1);
        addTx('Fatura anterior', card.legacyPaidInvoiceAmount, 1, previous, now);
        final payRef = _col(card.uid, 'card_payments').doc();
        batch.set(
            payRef,
            CardPayment(
              id: payRef.id,
              uid: card.uid,
              cardId: card.id!,
              amount: card.legacyPaidInvoiceAmount,
              invoice: previous,
              date: now,
            ).toMap());
      }

      batch.update(_col(card.uid, 'cards').doc(card.id), {
        'ledgerVersion': CardModel.currentLedgerVersion,
        'usedLimit': 0,
        'installments': [],
        'paidInvoiceAmount': 0,
      });
      await batch.commit();
    } catch (e) {
      _migrating.remove(card.id);
      debugPrint('Erro ao migrar cartão ${card.id}: $e');
    }
  }
}
