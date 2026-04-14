import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/players_provider.dart';
import '../providers/match_provider.dart';
import '../models/player.dart';
import '../utils/constants.dart';
import '../utils/form_calculator.dart';
import '../widgets/player_form_badge.dart';

// Pantalla de selección de alineación.
// Muestra todos los jugadores ordenados por estado de forma descendente.
// El entrenador selecciona exactamente 11 jugadores, debe incluir al menos
// un portero, y escribe el nombre del rival.
class LineupScreen extends StatefulWidget {
  const LineupScreen({super.key});

  @override
  State<LineupScreen> createState() => _LineupScreenState();
}

class _LineupScreenState extends State<LineupScreen> {
  final Set<String> _selected = {}; // IDs de jugadores seleccionados
  String _opponentName = '';

  @override
  Widget build(BuildContext context) {
    final playersProv = context.watch<PlayersProvider>();

    // Ordenamos por estado de forma descendente para facilitar la selección
    final sorted = [...playersProv.players]..sort((a, b) =>
        FormCalculator.calculate(b).compareTo(FormCalculator.calculate(a)));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Nueva Alineación',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: Column(
        children: [
          // Campo para el nombre del rival
          // IMPORTANTE: usar setState en onChanged para que el botón se reactive
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Rival',
                labelStyle:
                    const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _opponentName = v),
            ),
          ),

          // Contador de jugadores seleccionados + aviso de portero
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${_selected.length}/11 seleccionados',
                      style: TextStyle(
                        color: _selected.length == 11
                            ? AppColors.accent
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Ordenados por forma ↓',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                // Aviso de portero: solo visible si hay 11 seleccionados pero ningún portero
                if (_selected.length == 11 && !_hasKeeper(playersProv))
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: AppColors.danger, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Debes incluir al menos un portero',
                          style: TextStyle(
                              color: AppColors.danger, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Lista de jugadores
          Expanded(
            child: ListView.builder(
              itemCount: sorted.length,
              itemBuilder: (_, i) => _playerTile(sorted[i], playersProv),
            ),
          ),

          // Botón de inicio (solo activo con 11 jugadores, rival escrito y portero incluido)
          _buildStartButton(context, playersProv),
        ],
      ),
    );
  }

  // Comprueba si alguno de los jugadores seleccionados es portero
  bool _hasKeeper(PlayersProvider prov) {
    return _selected.any((id) {
      final player = prov.getById(id);
      return player?.position == 'POR';
    });
  }

  Widget _playerTile(Player player, PlayersProvider prov) {
    final form       = FormCalculator.calculate(player);
    final isSelected = _selected.contains(player.id);
    final isKeeper   = player.position == 'POR';

    return ListTile(
      tileColor: isSelected ? AppColors.card : Colors.transparent,
      leading: CircleAvatar(
        backgroundColor:
            positionColors[player.position] ?? AppColors.accent,
        child: Text(
          '${player.number}',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(player.name,
          style: const TextStyle(color: AppColors.textPrimary)),
      subtitle: Row(
        children: [
          Text(player.position,
              style: const TextStyle(color: AppColors.textSecondary)),
          // Etiqueta especial para porteros para que sean fáciles de identificar
          if (isKeeper) ...[
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.accentWarm.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: AppColors.accentWarm.withOpacity(0.5)),
              ),
              child: const Text(
                'Portero',
                style: TextStyle(
                    color: AppColors.accentWarm, fontSize: 9),
              ),
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlayerFormBadge(score: form),
          const SizedBox(width: 8),
          Checkbox(
            value: isSelected,
            activeColor: AppColors.accent,
            onChanged: (v) => _togglePlayer(player.id, prov),
          ),
        ],
      ),
      onTap: () => _togglePlayer(player.id, prov),
    );
  }

  void _togglePlayer(String id, PlayersProvider prov) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else if (_selected.length < 11) {
        _selected.add(id);
      }
    });
  }

  Widget _buildStartButton(BuildContext context, PlayersProvider prov) {
    final has11      = _selected.length == 11;
    final hasKeeper  = _hasKeeper(prov);
    final hasOpponent = _opponentName.isNotEmpty;
    // Solo se puede iniciar si hay 11 jugadores, al menos un portero y rival escrito
    final canStart   = has11 && hasKeeper && hasOpponent;

    // Mensaje de ayuda dinámico según lo que falta
    String hint;
    if (!hasOpponent) {
      hint = 'Escribe el nombre del rival';
    } else if (!has11) {
      hint = 'Selecciona ${11 - _selected.length} jugadores más';
    } else if (!hasKeeper) {
      hint = 'Debes incluir un portero';
    } else {
      hint = '⚽  Iniciar Partido';
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                canStart ? AppColors.accent : AppColors.card,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: canStart ? () => _startMatch(context) : null,
          child: Text(
            hint,
            style: TextStyle(
              color: canStart ? Colors.black : AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _startMatch(BuildContext context) {
    context
        .read<MatchProvider>()
        .startMatch(_opponentName, _selected.toList());
    Navigator.pushNamed(context, '/match');
  }
}