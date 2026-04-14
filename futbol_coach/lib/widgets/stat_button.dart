import 'package:flutter/material.dart';
import '../utils/constants.dart';

// Botón de estadística con icono, contador animado y etiqueta.
// Al pulsarlo registra el evento y anima el número con un efecto de escala.
class StatButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final int count;        // Contador actual del evento en este partido
  final VoidCallback onTap;

  const StatButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.count,
    required this.onTap,
  });

  @override
  State<StatButton> createState() => _StatButtonState();
}

class _StatButtonState extends State<StatButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    // Animación de pulso: crece a 1.3x y vuelve a 1.0
    _scaleAnim = Tween(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    // Lanzamos la animación y registramos el evento
    _controller.forward().then((_) => _controller.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: widget.color.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, color: widget.color, size: 20),
            const SizedBox(height: 2),
            // El contador se anima con ScaleTransition al incrementar
            ScaleTransition(
              scale: _scaleAnim,
              child: Text(
                '${widget.count}',
                style: TextStyle(
                  color: widget.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Text(
              widget.label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}