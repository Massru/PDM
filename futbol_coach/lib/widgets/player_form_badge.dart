import 'package:flutter/material.dart';
import '../utils/form_calculator.dart';

// Badge visual del estado de forma de un jugador.
// Muestra etiqueta, barra de progreso y puntuación numérica.
// Se usa en HomeScreen y LineupScreen.
class PlayerFormBadge extends StatelessWidget {
  final double score; // Puntuación de 0 a 100

  const PlayerFormBadge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final color = FormCalculator.color(score);
    final label = FormCalculator.label(score);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Etiqueta textual
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        // Barra de progreso proporcional a la puntuación
        SizedBox(
          width: 60,
          child: LinearProgressIndicator(
            value: score / 100,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Puntuación numérica
        Text(
          score.toStringAsFixed(0),
          style: TextStyle(
            color: color.withOpacity(0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}