import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/match_screen.dart';
import 'screens/lineup_screen.dart';
import 'screens/player_detail_screen.dart';
import 'screens/history_screen.dart';

class FootballCoachApp extends StatelessWidget {
  const FootballCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Football Coach',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A1628),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E676),
          surface: Color(0xFF132040),
        ),
        fontFamily: 'Roboto',
      ),
      // Rutas nombradas de la app
      initialRoute: '/',
      routes: {
        '/':        (_) => const HomeScreen(),
        '/match':   (_) => const MatchScreen(),
        '/lineup':  (_) => const LineupScreen(),
        '/player':  (_) => const PlayerDetailScreen(),
        '/history': (_) => const HistoryScreen(),
      },
    );
  }
}