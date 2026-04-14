import 'package:flutter/material.dart';
import '../models/player.dart';

// Calcula el "estado de forma" de un jugador de 0 a 100.
// La fórmula pondera estadísticas positivas y negativas
// normalizadas por el número de partidos jugados.
// Para porteros, las paradas también suman positivamente.
class FormCalculator {

  /// Devuelve una puntuación de 0 a 100
  static double calculate(Player p) {
    // Sin partidos jugados devolvemos 50 (neutro)
    if (p.totalMatches == 0) return 50.0;

    // Normalizamos cada métrica por partidos jugados
    final dribblesPerMatch   = p.dribbles    / p.totalMatches;
    final goalsPerMatch      = p.goals       / p.totalMatches;
    final assistsPerMatch    = p.assists     / p.totalMatches;
    final lossesPerMatch     = p.ballLosses  / p.totalMatches;
    final yellowsPerMatch    = p.yellowCards / p.totalMatches;
    final redsPerMatch       = p.redCards    / p.totalMatches;
    final recoveriesPerMatch = p.recoveries  / p.totalMatches;
    final shotsPerMatch      = p.shots       / p.totalMatches;
    final crossesPerMatch    = p.crosses     / p.totalMatches;
    final savesPerMatch      = p.saves       / p.totalMatches;

    // Partimos de 50 puntos base
    double score = 50.0;

    // POSITIVOS - cada métrica suma según su impacto en el juego
    score += goalsPerMatch      * 15.0; // Goles: máximo impacto
    score += assistsPerMatch    * 10.0; // Asistencias: muy valoradas
    score += dribblesPerMatch   *  8.0; // Regates: alto impacto técnico
    score += recoveriesPerMatch *  6.0; // Recuperaciones: trabajo defensivo
    score += shotsPerMatch      *  4.0; // Tiros: intención ofensiva
    score += crossesPerMatch    *  3.0; // Centros: contribución ofensiva

    // Paradas: solo suman para porteros (el resto siempre tendrá 0)
    // Peso alto porque una buena parada equivale a evitar un gol
    score += savesPerMatch      * 10.0;

    // NEGATIVOS - penalizamos comportamientos perjudiciales
    score -= lossesPerMatch     *  5.0; // Pérdidas: penalización moderada
    score -= yellowsPerMatch    *  8.0; // Amarilla: penaliza bastante
    score -= redsPerMatch       * 20.0; // Roja: penalización severa

    // Limitamos el resultado entre 0 y 100
    return score.clamp(0.0, 100.0);
  }

  /// Etiqueta textual según la puntuación
  static String label(double score) {
    if (score >= 80) return 'Excelente';
    if (score >= 65) return 'Buena';
    if (score >= 50) return 'Regular';
    if (score >= 35) return 'Baja';
    return 'Mala';
  }

  /// Color asociado al estado de forma
  static Color color(double score) {
    if (score >= 80) return const Color(0xFF00E676);
    if (score >= 65) return const Color(0xFF69F0AE);
    if (score >= 50) return const Color(0xFFFFB300);
    if (score >= 35) return const Color(0xFFFF7043);
    return const Color(0xFFE53935);
  }
}