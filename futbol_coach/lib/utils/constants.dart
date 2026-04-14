import 'package:flutter/material.dart';

// Paleta de colores global de la app
// Usar siempre estas constantes para mantener coherencia visual
class AppColors {
  static const background  = Color(0xFF0A1628); // Azul noche - fondo principal
  static const surface     = Color(0xFF132040); // Azul medio - appbars y barras
  static const card        = Color(0xFF1C2E50); // Azul card - tarjetas y paneles
  static const accent      = Color(0xFF00E676); // Verde césped - acción principal
  static const accentWarm  = Color(0xFFFFB300); // Ámbar - segundario / goles
  static const danger      = Color(0xFFE53935); // Rojo - peligro / tarjeta roja
  static const yellow      = Color(0xFFFFD600); // Amarillo - tarjeta amarilla
  static const textPrimary = Color(0xFFFFFFFF); // Blanco - texto principal
  static const textSecondary = Color(0xFF8BA0C4); // Azul grisáceo - texto secundario
}

// Color identificativo de cada posición en el campo
const Map<String, Color> positionColors = {
  'POR': Color(0xFFFFB300), // Portero - ámbar
  'DEF': Color(0xFF1565C0), // Defensa - azul
  'MED': Color(0xFF2E7D32), // Centrocampista - verde oscuro
  'DEL': Color(0xFFB71C1C), // Delantero - rojo
};

// Lista de posiciones disponibles (mismo orden en toda la app)
const List<String> positions = ['POR', 'DEF', 'MED', 'DEL'];