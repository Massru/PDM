import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/players_provider.dart';
import 'providers/match_provider.dart';
import 'app.dart';

void main() async {
  // Necesario antes de cualquier llamada a métodos nativos
  WidgetsFlutterBinding.ensureInitialized();

  // Bloquea la orientación en vertical en código Dart
  // (complementar con android:screenOrientation="portrait" en AndroidManifest.xml)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    // MultiProvider registra todos los providers globales de la app
    // Cualquier widget descendiente puede acceder a ellos con context.watch/read
    MultiProvider(
      providers: [
        // Gestión de jugadores y sus estadísticas acumuladas
        ChangeNotifierProvider(create: (_) => PlayersProvider()),
        // Gestión del partido en curso e historial
        ChangeNotifierProvider(create: (_) => MatchProvider()),
      ],
      child: const FootballCoachApp(),
    ),
  );
}