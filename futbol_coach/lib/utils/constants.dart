import 'package:flutter/material.dart';

// Paleta de colores y constantes visuales de la app
class AppColors {
  static const background = Color(0xFF0A1628);   // Azul noche
  static const surface = Color(0xFF132040);       // Azul medio
  static const card = Color(0xFF1C2E50);          // Azul card
  static const accent = Color(0xFF00E676);        // Verde césped
  static const accentWarm = Color(0xFFFFB300);    // Ámbar
  static const danger = Color(0xFFE53935);        // Rojo tarjeta
  static const yellow = Color(0xFFFFD600);        // Amarillo tarjeta
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF8BA0C4);
}

// Las posiciones disponibles y sus colores identificativos
const Map<String, Color> positionColors = {
  'POR': Color(0xFFFFB300),   // Portero - ámbar
  'DEF': Color(0xFF1565C0),   // Defensa - azul
  'MED': Color(0xFF2E7D32),   // Medio - verde oscuro
  'DEL': Color(0xFFB71C1C),   // Delantero - rojo
};

const List<String> positions = ['POR', 'DEF', 'MED', 'DEL'];