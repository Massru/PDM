import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/players_provider.dart';
import '../providers/match_provider.dart';
import '../models/player.dart';
import '../utils/constants.dart';
import '../utils/form_calculator.dart';
import '../widgets/player_form_badge.dart';

class LineupScreen extends StatefulWidget {
  const LineupScreen({super.key});

  @override
  State<LineupScreen> createState() => _LineupScreenState();
}

class _LineupScreenState extends State<LineupScreen> {
  // Set de IDs de jugadores seleccionados para la alineación
  // Set evita duplicados automáticamente
  final Set<String> _selected = {};
  String _opponentName = '';

  @override
  Widget build(BuildContext context) {
    final playersProv = context.watch<PlayersProvider>();
    // Copia lista de jugadores y la ordena por estado de forma (mejor a peor)
    // Esto ayuda al entrenador a elegir los mejores jugadores primero
    final sorted = [...playersProv.players]..sort((a, b) {
      return FormCalculator.calculate(b).compareTo(FormCalculator.calculate(a));
    });

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
          // Campo de texto para ingresar el nombre del rival
          // Se guarda en _opponentName y se usa para crear el partido
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Rival',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _opponentName = v), // Actualiza el estado
            ),
          ),

          // Contador de seleccionados con indicador de color
          // Cambia a verde cuando hay 11 seleccionados
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
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
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Lista scrolleable de todos los jugadores ordenados por forma
          // Permite seleccionar hasta 11 jugadores para la alineación
          Expanded(
            child: ListView.builder(
              itemCount: sorted.length,
              itemBuilder: (_, i) => _playerTile(sorted[i]),
            ),
          ),

          // Botón de iniciar partido
          _buildStartButton(context),
        ],
      ),
    );
  }

  // Cada fila de la lista representa un jugador
  // Permite ver su número, nombre, posición y estado de forma
  Widget _playerTile(Player player) {
    // Calcula la forma de este jugador
    final form       = FormCalculator.calculate(player);
    // Comprueba si está seleccionado
    final isSelected = _selected.contains(player.id);

    return ListTile(
      // Destaca el tile si el jugador está seleccionado
      tileColor: isSelected ? AppColors.card : Colors.transparent,
      // Avatar circular con el dorsal y color por posición
      leading: CircleAvatar(
        backgroundColor: positionColors[player.position] ?? AppColors.accent,
        child: Text(
          '${player.number}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        player.name,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      // Posición (POR, DEF, MED, DEL)
      subtitle: Text(
        player.position,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Badge visual con la forma del jugador
          PlayerFormBadge(score: form),
          const SizedBox(width: 8),
          // Checkbox para seleccionar/deseleccionar
          Checkbox(
            value: isSelected,
            activeColor: AppColors.accent,
            onChanged: (v) => _togglePlayer(player.id),
          ),
        ],
      ),
      // Permite seleccionar tocando en cualquier parte del tile
      onTap: () => _togglePlayer(player.id),
    );
  }

  // Alterna la selección de un jugador
  // Si ya está seleccionado, lo deselecciona
  // Si no está seleccionado y hay menos de 11, lo añade
  void _togglePlayer(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id); // Quita si está seleccionado
      } else if (_selected.length < 11) {
        _selected.add(id); // Añade si no alcanzó el límite de 11
      }
    });
  }

  // Botón de inicio: se habilita solo cuando hay 11 jugadores y rival
  Widget _buildStartButton(BuildContext context) {
    // Valida: debe haber 11 jugadores seleccionados Y un nombre de rival
    final canStart = _selected.length == 11 && _opponentName.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: canStart ? AppColors.accent : AppColors.card,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: canStart ? () => _startMatch(context) : null,
          child: Text(
            canStart
                ? '⚽  Iniciar Partido'
                : 'Selecciona 11 jugadores y el rival',
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
    context.read<MatchProvider>().startMatch(
      _opponentName,
      _selected.toList(),
    );
    Navigator.pushNamed(context, '/match');
  }
}