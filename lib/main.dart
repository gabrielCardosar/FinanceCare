import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/home_provider.dart';
import 'providers/cards_provider.dart';
import 'providers/subscriptions_provider.dart';
import 'providers/bills_payable_provider.dart';
import 'providers/notes_provider.dart';
import 'providers/monthly_report_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'utils/constants.dart';
import 'providers/purchases_provider.dart';
import 'providers/extra_income_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
    providers: [
  ChangeNotifierProvider(create: (_) => AuthProvider()),
  ChangeNotifierProvider(create: (_) => HomeProvider()),
  ChangeNotifierProvider(create: (_) => CardsProvider()),
  ChangeNotifierProvider(create: (_) => SubscriptionsProvider()),
  ChangeNotifierProvider(create: (_) => BillsPayableProvider()),
  ChangeNotifierProvider(create: (_) => NotesProvider()),
  ChangeNotifierProvider(create: (_) => MonthlyReportProvider()),
  ChangeNotifierProvider(create: (_) => PurchasesProvider()),
  ChangeNotifierProvider(create: (_) => ExtraIncomeProvider()),
],
      child: MaterialApp(
        title: 'Finance Care',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            if (authProvider.isLoading) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }
            return authProvider.user != null
                ? const HomeScreen()
                : const LoginScreen();
          },
        ),
      ),
    );
  }
}
