import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/flat_provider.dart';
import 'providers/expense_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FlatProvider()..loadData()),
        ChangeNotifierProxyProvider<FlatProvider, ExpenseProvider>(
          create: (_) => ExpenseProvider(),
          update: (_, flat, expense) => expense!..update(flat),
        ),
      ],
      child: const PisoGastosApp(),
    ),
  );
}

class PisoGastosApp extends StatelessWidget {
  const PisoGastosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PisoGastos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5C6BC0)),
        useMaterial3: true,
      ),
      home: Consumer<FlatProvider>(
        builder: (context, flat, _) {
          if (flat.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (flat.isConfigured) return const HomeScreen();
          return const WelcomeScreen();
        },
      ),
    );
  }
}