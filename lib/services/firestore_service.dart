import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/account_model.dart';
import '../models/card_model.dart';
import '../models/subscription_model.dart';
import '../models/bill_payable_model.dart';
import '../models/note_model.dart';
import '../models/monthly_report_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===== CONTA =====
  Future<void> saveAccount(AccountModel account) async {
    try {
      if (account.id == null) {
        await _firestore
            .collection('users')
            .doc(account.uid)
            .collection('accounts')
            .add(account.toMap());
      } else {
        await _firestore
            .collection('users')
            .doc(account.uid)
            .collection('accounts')
            .doc(account.id)
            .update(account.toMap());
      }
    } catch (e) {
      throw Exception('Erro ao salvar conta: $e');
    }
  }

  Stream<AccountModel?> getAccount(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('accounts')
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return AccountModel.fromMap(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    });
  }

  // ===== CARTÕES =====
  Future<void> saveCard(CardModel card) async {
    try {
      if (card.id == null) {
        await _firestore
            .collection('users')
            .doc(card.uid)
            .collection('cards')
            .add(card.toMap());
      } else {
        await _firestore
            .collection('users')
            .doc(card.uid)
            .collection('cards')
            .doc(card.id)
            .update(card.toMap());
      }
    } catch (e) {
      throw Exception('Erro ao salvar cartão: $e');
    }
  }

  Stream<List<CardModel>> getCards(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('cards')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CardModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> deleteCard(String uid, String cardId) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('cards')
          .doc(cardId)
          .delete();
    } catch (e) {
      throw Exception('Erro ao deletar cartão: $e');
    }
  }

  // ===== ASSINATURAS =====
  Future<void> saveSubscription(SubscriptionModel subscription) async {
    try {
      if (subscription.id == null) {
        await _firestore
            .collection('users')
            .doc(subscription.uid)
            .collection('subscriptions')
            .add(subscription.toMap());
      } else {
        await _firestore
            .collection('users')
            .doc(subscription.uid)
            .collection('subscriptions')
            .doc(subscription.id)
            .update(subscription.toMap());
      }
    } catch (e) {
      throw Exception('Erro ao salvar assinatura: $e');
    }
  }

  Stream<List<SubscriptionModel>> getSubscriptions(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('subscriptions')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SubscriptionModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> deleteSubscription(String uid, String subscriptionId) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('subscriptions')
          .doc(subscriptionId)
          .delete();
    } catch (e) {
      throw Exception('Erro ao deletar assinatura: $e');
    }
  }

  // ===== CONTAS A PAGAR =====
  Future<void> saveBillPayable(BillPayableModel bill) async {
    try {
      await _firestore
          .collection('users')
          .doc(bill.uid)
          .collection('bills_payable')
          .doc(bill.id)
          .set(bill.toMap());
    } catch (e) {
      throw Exception('Erro ao salvar conta a pagar: $e');
    }
  }

  Stream<List<BillPayableModel>> getBillsPayable(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('bills_payable')
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BillPayableModel.fromMap(doc.data()))
          .toList();
    });
  }

  Future<void> deleteBillPayable(String uid, String billId) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('bills_payable')
          .doc(billId)
          .delete();
    } catch (e) {
      throw Exception('Erro ao deletar conta a pagar: $e');
    }
  }

  /// Reseta contas NÃO fixas (isPaid volta a false nas fixas, remove as demais)
  /// Deve ser chamado no início de cada mês após salvar o relatório.
  Future<void> resetMonthlyBills(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('bills_payable')
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        final bill = BillPayableModel.fromMap(doc.data());
        if (bill.isFixed) {
          // Fixa: apenas reseta o isPaid para false
          batch.update(doc.reference, {'isPaid': false});
        } else {
          // Variável: deleta
          batch.delete(doc.reference);
        }
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Erro ao resetar contas mensais: $e');
    }
  }

  // ===== NOTAS =====
  Future<void> saveNote(NoteModel note) async {
    try {
      await _firestore
          .collection('users')
          .doc(note.uid)
          .collection('notes')
          .doc(note.id)
          .set(note.toMap());
    } catch (e) {
      throw Exception('Erro ao salvar nota: $e');
    }
  }

  Stream<List<NoteModel>> getNotes(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notes')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NoteModel.fromMap(doc.data()))
          .toList();
    });
  }

  Future<void> deleteNote(String uid, String noteId) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('notes')
          .doc(noteId)
          .delete();
    } catch (e) {
      throw Exception('Erro ao deletar nota: $e');
    }
  }

  // ===== RELATÓRIOS MENSAIS =====
  Future<void> saveMonthlyReport(MonthlyReportModel report) async {
    try {
      await _firestore
          .collection('users')
          .doc(report.uid)
          .collection('monthly_reports')
          .doc(report.id)
          .set(report.toMap());
    } catch (e) {
      throw Exception('Erro ao salvar relatório mensal: $e');
    }
  }

  Stream<List<MonthlyReportModel>> getMonthlyReports(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('monthly_reports')
        .orderBy('year', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MonthlyReportModel.fromMap(doc.data()))
          .toList()
        ..sort((a, b) {
          final cmp = b.year.compareTo(a.year);
          return cmp != 0 ? cmp : b.month.compareTo(a.month);
        });
    });
  }

  /// Verifica se já existe relatório para o mês/ano informados
  Future<bool> reportExists(String uid, int year, int month) async {
    final id = '$year-${month.toString().padLeft(2, '0')}';
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('monthly_reports')
        .doc(id)
        .get();
    return doc.exists;
  }

  /// Salva o último mês registrado para detectar virada de mês
  Future<void> saveLastReportMonth(
      String uid, int year, int month) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .set({'lastReportYear': year, 'lastReportMonth': month},
            SetOptions(merge: true));
  }

  Future<Map<String, int?>> getLastReportMonth(String uid) async {
    final doc =
        await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return {'year': null, 'month': null};
    final data = doc.data()!;
    return {
      'year': data['lastReportYear'] as int?,
      'month': data['lastReportMonth'] as int?,
    };
  }
}
