import 'package:flutter/material.dart';
import '../utils/constants.dart';

// Botón de estadística: muestra icono, etiqueta y contador.
// Al pulsarlo llama onTap y anima el contador.

class StatButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final int count;
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
  late AnimationController _controller; // Controla la animación
  late Animation<double> _scaleAnim; // Anima la escala del contador

  @override
  void initState() {
    super.initState();
    // Crea un controlador de animación que dura 150ms
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    // Define la animación: escala de 1.0 a 1.3 (crece un 30%)
    // EaseOut hace que empiece rápido y termine más lento
    _scaleAnim = Tween(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // Limpia recursos de la animación
    super.dispose();
  }

  void _onTap() {
    // Al tocar: reproduce animación hacia adelante, luego hacia atrás
    // Crea efecto de "pulso" en el contador
    _controller.forward().then((_) => _controller.reverse());
    widget.onTap(); // Llama el callback (registra el evento)
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        // Fondo semi-transparente del color del evento
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: widget.color.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícono del evento
            Icon(widget.icon, color: widget.color, size: 20),
            const SizedBox(height: 2),
            // Contador que se anima con efecto de pulso
            // ScaleTransition aplica la animación de escala
            ScaleTransition(
              scale: _scaleAnim,
              child: Text(
                '${widget.count}', // Muestra el contador actual
                style: TextStyle(
                  color: widget.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            // Etiqueta descriptiva del evento
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