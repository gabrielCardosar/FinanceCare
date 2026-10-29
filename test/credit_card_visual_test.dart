import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/models/card_model.dart';
import 'package:finance_app/utils/constants.dart';
import 'package:finance_app/widgets/ui.dart';

void main() {
  final card = CardModel(
    id: 'c1',
    uid: 'u',
    cardName: 'Cartão com um nome bem comprido',
    bankName: 'Banco Exemplo S.A.',
    limit: 25000,
    invoiceClosingDay: 5,
    invoiceDueDay: 12,
  );
  final ledger = CardLedger(card: card, transactions: [
    CardTransaction(
      id: 't',
      uid: 'u',
      cardId: 'c1',
      description: 'TV',
      totalAmount: 12345.67,
      installments: 10,
      firstInvoice: card.invoiceFor(DateTime.now()),
    ),
  ]);

  for (final (w, h, compact) in [(270.0, 170.0, true), (340.0, 198.0, false)]) {
    testWidgets('cartão ${w}x$h sem overflow', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
                width: w,
                height: h,
                child: CreditCardVisual(ledger: ledger, compact: compact)),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
      expect(find.text('BANCO EXEMPLO S.A.'), findsOneWidget);
    });
  }
}
