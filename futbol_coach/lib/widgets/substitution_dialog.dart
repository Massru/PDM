import 'package:flutter/material.dart';
import '../models/player.dart';
import '../utils/constants.dart';

// Diálogo de sustitución en dos pasos:
// Paso 1: el entrenador pincha en el jugador que SALE (lista de titulares en campo)
// Paso 2: el entrenador pincha en el jugador que ENTRA (lista de suplentes en banquillo)
class SubstitutionDialog extends StatefulWidget {
  final List<String> onFieldPlayerIds; // IDs de jugadores actualmente en campo
  final List<Player> allPlayers;       // Todos los jugadores de la plantilla
  final Function(String outId, String inId) onSubstitution;

  const SubstitutionDialog({
    super.key,
    required this.onFieldPlayerIds,
    required this.allPlayers,
    required this.onSubstitution,
  });

  @override
  State<SubstitutionDialog> createState() => _SubstitutionDialogState();
}

class _SubstitutionDialogState extends State<SubstitutionDialog> {
  // null = estamos en paso 1 (eligiendo quién sale)
  // String = ya elegimos quién sale, estamos en paso 2 (eligiendo quién entra)
  String? _outPlayerId;

  @override
  Widget build(BuildContext context) {
    // Jugadores en campo ordenados por dorsal
    final onField = widget.allPlayers
        .where((p) => widget.onFieldPlayerIds.contains(p.id))
        .toList()
      ..sort((a, b) => a.number.compareTo(b.number));

    // Jugadores en banquillo ordenados por dorsal
    final onBench = widget.allPlayers
        .where((p) => !widget.onFieldPlayerIds.contains(p.id))
        .toList()
      ..sort((a, b) => a.number.compareTo(b.number));

    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera con título del paso actual
            Row(
              children: [
                const Icon(Icons.swap_vert, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(
                  _outPlayerId == null ? 'Jugador que SALE' : 'Jugador que ENTRA',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Botón para volver al paso anterior
                if (_outPlayerId != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: AppColors.textSecondary, size: 20),
                    onPressed: () => setState(() => _outPlayerId = null),
                  ),
                IconButton(
                  icon: const Icon(Icons.close,
                      color: AppColors.textSecondary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            // Indicador de pasos (1 → 2)
            const SizedBox(height: 8),
            Row(
              children: [
                _stepDot(1, _outPlayerId == null),
                Container(width: 24, height: 2, color: Colors.white12),
                _stepDot(2, _outPlayerId != null),
              ],
            ),

            // Banner con el nombre del jugador que sale (solo en paso 2)
            if (_outPlayerId != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.danger.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_upward,
                        color: AppColors.danger, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Sale: ${_playerName(_outPlayerId!)}',
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Lista de jugadores según el paso actual
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView(
                shrinkWrap: true,
                children: _outPlayerId == null
                    // Paso 1: mostrar jugadores en campo
                    ? onField.map((p) => _playerRow(
                          player: p,
                          color: AppColors.danger,
                          icon: Icons.arrow_upward,
                          onTap: () => setState(() => _outPlayerId = p.id),
                        )).toList()
                    // Paso 2: mostrar jugadores en banquillo
                    : onBench.map((p) => _playerRow(
                          player: p,
                          color: AppColors.accent,
                          icon: Icons.arrow_downward,
                          onTap: () {
                            widget.onSubstitution(_outPlayerId!, p.id);
                            Navigator.pop(context);
                          },
                        )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fila de jugador seleccionable
  Widget _playerRow({
    required Player player,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final posColor = positionColors[player.position] ?? AppColors.accent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            // Dorsal con color de posición
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: posColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: posColor.withOpacity(0.4)),
              ),
              child: Center(
                child: Text(
                  '${player.number}',
                  style: TextStyle(
                    color: posColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Nombre y posición
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    player.position,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(icon, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  // Círculo numerado para el indicador de pasos
  Widget _stepDot(int step, bool active) {
    return Container(
      width: 24, height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.accent : AppColors.surface,
        border: Border.all(
          color: active ? AppColors.accent : Colors.white24,
        ),
      ),
      child: Center(
        child: Text(
          '$step',
          style: TextStyle(
            color: active ? Colors.black : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Obtiene el nombre de un jugador por su ID
  String _playerName(String id) {
    try {
      return widget.allPlayers.firstWhere((p) => p.id == id).name;
    } catch (_) {
      return '';
    }
  }
}