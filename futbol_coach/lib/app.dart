import 'package:flutter/material.dart';
import 'utils/constants.dart';
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
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          surface: AppColors.surface,
        ),
        // Fuente global (requiere google_fonts o definir en pubspec)
        fontFamily: 'Roboto',
      ),
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
