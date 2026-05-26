import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'providers/account_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/category_provider.dart';
import 'providers/debt_provider.dart';
import 'providers/goal_provider.dart';
import 'providers/transaction_provider.dart';
import 'screens/shell/app_shell.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const KaneboApp());
}

class KaneboApp extends StatelessWidget {
  const KaneboApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AccountProvider()..load()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()..load()),
        ChangeNotifierProxyProvider<AccountProvider, TransactionProvider>(
          create: (ctx) => TransactionProvider(
            Provider.of<AccountProvider>(ctx, listen: false),
          )..load(),
          update: (_, accountProvider, prev) {
            if (prev != null) return prev;
            return TransactionProvider(accountProvider)..load();
          },
        ),
        ChangeNotifierProvider(create: (_) => BudgetProvider()..load()),
        ChangeNotifierProvider(create: (_) => GoalProvider()..load()),
        ChangeNotifierProvider(create: (_) => DebtProvider()..load()),
      ],
      child: MaterialApp(
        title: 'Kanebo Money',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const AppShell(),
      ),
    );
  }
}
