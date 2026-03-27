// lib/utils/form_calculator.dart

import 'package:flutter/material.dart';  // ← añade este import
import '../models/player.dart';

class FormCalculator {
  // Cálculo de forma del jugador (escala 0-100)
  // Basado en estadísticas acumuladas y promediadas por partido
  static double calculate(Player p) {
    if (p.totalMatches == 0) return 50.0; // Jugador sin partidos: forma neutra

    // Normaliza las estadísticas dividiendo entre número de partidos jugados
    final dribblesPerMatch = p.dribbles / p.totalMatches;
    final goalsPerMatch    = p.goals / p.totalMatches;
    final assistsPerMatch  = p.assists / p.totalMatches;
    final lossesPerMatch   = p.ballLosses / p.totalMatches;
    final yellowsPerMatch  = p.yellowCards / p.totalMatches;
    final redsPerMatch     = p.redCards / p.totalMatches;

    double score = 50.0; // Base neutral

    // Añade puntos positivos
    score += dribblesPerMatch * 8.0;   // Cada regate promedio suma 8 puntos
    score += goalsPerMatch    * 15.0;  // Cada gol promedio suma 15 puntos
    score += assistsPerMatch  * 10.0;  // Cada asistencia promedio suma 10 puntos
    
    // Resta puntos negativos
    score -= lossesPerMatch   * 5.0;   // Cada pérdida promedio resta 5 puntos
    score -= yellowsPerMatch  * 8.0;   // Cada tarjeta amarilla promedio resta 8 puntos
    score -= redsPerMatch     * 20.0;  // Cada tarjeta roja promedio resta 20 puntos

    // Asegura que quede en rango 0-100
    return score.clamp(0.0, 100.0);
  }

  // Retorna una etiqueta descriptiva según la puntuación
  // Usado para mostrar "Ítem", "Buena", etc. en la UI
  static String label(double score) {
    if (score >= 80) return 'Excelente';
    if (score >= 65) return 'Buena';
    if (score >= 50) return 'Regular';
    if (score >= 35) return 'Baja';
    return 'Mala';
  }

  // Retorna el color asociado a cada nivel de forma
  // Desde verde (excelente) hasta rojo (mala)
  static Color color(double score) {  // ← ahora Color está definido
    if (score >= 80) return const Color(0xFF00E676);
    if (score >= 65) return const Color(0xFF69F0AE);
    if (score >= 50) return const Color(0xFFFFB300);
    if (score >= 35) return const Color(0xFFFF7043);
    return const Color(0xFFE53935);
  }
}