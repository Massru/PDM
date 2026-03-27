import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/players_provider.dart';
import 'providers/match_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Fuerza orientación vertical (mejor UX para control de partido)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Inicializa todos los providers globales de la app
  runApp(
    MultiProvider(
      providers: [
        // PlayersProvider: gestiona lista de jugadores y persistencia
        ChangeNotifierProvider(create: (_) => PlayersProvider()),
        // MatchProvider: gestiona partidos activos, cronómetro y eventos
        ChangeNotifierProvider(create: (_) => MatchProvider()),
      ],
      child: const FootballCoachApp(),
    ),
  );
}