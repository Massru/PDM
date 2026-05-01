import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/flat_provider.dart';
import 'providers/expense_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  // Necesario antes de usar plugins nativos (SharedPreferences)
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        // FlatProvider se crea y lanza loadData() inmediatamente (..loadData())
        ChangeNotifierProvider(create: (_) => FlatProvider()..loadData()),

        // ProxyProvider permite que ExpenseProvider reciba actualizaciones
        // de FlatProvider automáticamente. Cada vez que FlatProvider notifica,
        // se llama a expense..update(flat), que compara el ID del piso
        // activo con el cargado y recarga los gastos si hace falta.
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
      // Consumer escucha FlatProvider y decide qué pantalla mostrar.
      // No hace falta Navigator.push en ningún sitio para la navegación
      // principal: basta con que isConfigured cambie de valor.
      home: Consumer<FlatProvider>(
        builder: (context, flat, _) {
          // Mientras carga desde disco mostramos un spinner
          if (flat.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // Si hay piso activo → pantalla principal
          if (flat.isConfigured) return const HomeScreen();
          // Si no → pantalla de bienvenida
          return const WelcomeScreen();
        },
      ),
    );
  }
}