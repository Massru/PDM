import 'package:flutter/material.dart';
import '../utils/form_calculator.dart';

// Badge visual que muestra el estado de forma del jugador.
// Barra de progreso + etiqueta + puntuación numérica.

class PlayerFormBadge extends StatelessWidget {
  final double score; // 0-100

  const PlayerFormBadge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    // Calcula color y etiqueta según puntuación (usa escala 0-100)
    final color = FormCalculator.color(score);
    final label = FormCalculator.label(score);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
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
        Text(
          score.toStringAsFixed(0),
          style: TextStyle(color: color.withOpacity(0.7), fontSize: 10),
        ),
      ],
    );
  }
}