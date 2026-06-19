import 'package:flutter/material.dart';
import '../models/monthly_report_model.dart';
import '../models/bill_payable_model.dart';
import '../models/subscription_model.dart';
import '../models/card_model.dart';
import '../services/firestore_service.dart';

class MonthlyReportProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<MonthlyReportModel> _reports = [];
  bool _isLoading = false;
  String? _error;

  List<MonthlyReportModel> get reports => _reports;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void loadReports(String uid) {
    _firestoreService.getMonthlyReports(uid).listen((reports) {
      _reports = reports;
      notifyListeners();
    });
  }

  /// Verifica se é necessário gerar relatório do mês anterior e resetar.
  /// Deve ser chamado no initState do HomeScreen.
  Future<void> checkAndGenerateReport({
    required String uid,
    required double salary,
    required List<BillPayableModel> bills,
    required List<SubscriptionModel> subscriptions,
    required List<CardModel> cards,
  }) async {
    final now = DateTime.now();
    final last = await _firestoreService.getLastReportMonth(uid);
    final lastYear = last['year'];
    final lastMonth = last['month'];

    // Se nunca gerou ou o mês atual é diferente do último registrado
    bool shouldGenerate = false;
    int reportYear = now.year;
    int reportMonth = now.month;

    if (lastYear == null || lastMonth == null) {
      // Primeira vez — salva o mês atual como referência, sem gerar relatório
      await _firestoreService.saveLastReportMonth(uid, now.year, now.month);
      return;
    }

    // Verifica se virou o mês
    if (lastYear < now.year ||
        (lastYear == now.year && lastMonth < now.month)) {
      shouldGenerate = true;
      // O relatório é referente ao mês anterior (lastYear/lastMonth)
      reportYear = lastYear;
      reportMonth = lastMonth;
    }

    if (!shouldGenerate) return;

    // Verifica se já foi gerado para evitar duplicata
    final alreadyExists = await _firestoreService.reportExists(
        uid, reportYear, reportMonth);
    if (alreadyExists) {
      await _firestoreService.saveLastReportMonth(uid, now.year, now.month);
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final report = _buildReport(
        uid: uid,
        year: reportYear,
        month: reportMonth,
        salary: salary,
        bills: bills,
        subscriptions: subscriptions,
        cards: cards,
      );

      await _firestoreService.saveMonthlyReport(report);
      await _firestoreService.resetMonthlyBills(uid);
      await _firestoreService.saveLastReportMonth(uid, now.year, now.month);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Geração manual do relatório do mês corrente (botão na tela)
  Future<void> generateManualReport({
    required String uid,
    required double salary,
    required List<BillPayableModel> bills,
    required List<SubscriptionModel> subscriptions,
    required List<CardModel> cards,
  }) async {
    final now = DateTime.now();
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final report = _buildReport(
        uid: uid,
        year: now.year,
        month: now.month,
        salary: salary,
        bills: bills,
        subscriptions: subscriptions,
        cards: cards,
      );
      await _firestoreService.saveMonthlyReport(report);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  MonthlyReportModel _buildReport({
    required String uid,
    required int year,
    required int month,
    required double salary,
    required List<BillPayableModel> bills,
    required List<SubscriptionModel> subscriptions,
    required List<CardModel> cards,
  }) {
    final id = '$year-${month.toString().padLeft(2, '0')}';
    final totalSubs =
        subscriptions.fold<double>(0, (s, sub) => s + sub.monthlyValue);
    final totalPaid =
        bills.where((b) => b.isPaid).fold<double>(0, (s, b) => s + b.amount);
    final totalUnpaid =
        bills.where((b) => !b.isPaid).fold<double>(0, (s, b) => s + b.amount);
    final totalCardUsed =
        cards.fold<double>(0, (s, c) => s + c.usedLimit);
    final finalBalance = salary - totalSubs - totalPaid - totalUnpaid;

    return MonthlyReportModel(
      id: id,
      uid: uid,
      year: year,
      month: month,
      salary: salary,
      totalSubscriptions: totalSubs,
      totalBillsPaid: totalPaid,
      totalBillsUnpaid: totalUnpaid,
      totalCardUsed: totalCardUsed,
      finalBalance: finalBalance,
      bills: bills
          .map((b) => ReportBillItem(
                name: b.name,
                amount: b.amount,
                isPaid: b.isPaid,
                isFixed: b.isFixed,
                urgency: b.urgency.value,
              ))
          .toList(),
      subscriptions: subscriptions
          .map((s) => ReportSubscriptionItem(
                name: s.name,
                monthlyValue: s.monthlyValue,
              ))
          .toList(),
      cards: cards
          .map((c) => ReportCardItem(
                cardName: c.cardName,
                bankName: c.bankName,
                limit: c.limit,
                usedLimit: c.usedLimit,
                colorValue: c.colorValue,
              ))
          .toList(),
    );
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
