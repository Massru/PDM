import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/match_provider.dart';
import '../providers/players_provider.dart';
import '../models/match.dart';
import '../models/match_event.dart';
import '../models/player.dart';
import '../utils/constants.dart';

// Pantalla de historial de partidos finalizados.
// Muestra cada partido como una tarjeta expandible con estadísticas por jugador.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final matchProv = context.watch<MatchProvider>();
    // Más reciente primero
    final history = matchProv.matchHistory.reversed.toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Historial de Partidos',
          style: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: history.isEmpty
          ? _buildEmpty()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (_, i) => _MatchCard(match: history[i]),
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sports_soccer,
              color: AppColors.textSecondary.withOpacity(0.3), size: 64),
          const SizedBox(height: 16),
          const Text(
            'Sin partidos jugados aún',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Los partidos finalizados aparecerán aquí',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ---- Tarjeta de un partido con estadísticas expandibles ----

class _MatchCard extends StatelessWidget {
  final Match match;
  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final date    = match.date;
    final dateStr = '${date.day.toString().padLeft(2, '0')}/'
                    '${date.month.toString().padLeft(2, '0')}/'
                    '${date.year}';
    final result  = '${match.goalsFor} - ${match.goalsAgainst}';
    final won     = match.goalsFor > match.goalsAgainst;
    final draw    = match.goalsFor == match.goalsAgainst;

    // Color del resultado: verde ganado, ámbar empate, rojo derrota
    final resultColor = won
        ? AppColors.accent
        : draw
            ? AppColors.accentWarm
            : AppColors.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: resultColor.withOpacity(0.3)),
      ),
      child: Theme(
        // Elimina el divider por defecto del ExpansionTile
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              // Franja de color indicando el resultado
              Container(
                width: 4, height: 40,
                decoration: BoxDecoration(
                  color: resultColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'vs ${match.opponent}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Resultado con color
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: resultColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: resultColor.withOpacity(0.4)),
                ),
                child: Text(
                  result,
                  style: TextStyle(
                    color: resultColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          // Resumen rápido de eventos del partido
          subtitle: Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: _buildQuickStats(),
          ),
          children: [
            const Divider(color: Colors.white10),
            const SizedBox(height: 8),
            // Tabla de estadísticas individuales por jugador
            _buildPlayerStats(context),
          ],
        ),
      ),
    );
  }

  // Resumen rápido de los eventos más relevantes del partido
  Widget _buildQuickStats() {
    final goals   = match.events.where((e) => e.type == EventType.goal).length;
    final assists = match.events.where((e) => e.type == EventType.assist).length;
    final yellows = match.events.where((e) => e.type == EventType.yellowCard).length;
    final reds    = match.events.where((e) => e.type == EventType.redCard).length;
    final subs    = match.events.where((e) => e.type == EventType.substitutionOut).length;

    return Row(
      children: [
        _quickStat('⚽', '$goals'),
        _quickStat('🅰️', '$assists'),
        _quickStat('🟡', '$yellows'),
        _quickStat('🔴', '$reds'),
        _quickStat('🔄', '$subs'),
      ],
    );
  }

  Widget _quickStat(String emoji, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Text(
        '$emoji $value',
        style: const TextStyle(
            color: AppColors.textSecondary, fontSize: 12),
      ),
    );
  }

  // Tabla de estadísticas individuales de cada jugador participante
  Widget _buildPlayerStats(BuildContext context) {
    final playersProv = context.read<PlayersProvider>();

    // Todos los que participaron: titulares + sustitutos que entraron
    final participantIds = <String>{
      ...match.lineup,
      ...match.events
          .where((e) => e.type == EventType.substitutionIn)
          .map((e) => e.playerId),
    };

    final participants = participantIds
        .map((id) => playersProv.getById(id))
        .whereType<Player>()
        .toList()
      ..sort((a, b) => a.number.compareTo(b.number));

    if (participants.isEmpty) {
      return const Text('Sin datos de jugadores',
          style: TextStyle(color: AppColors.textSecondary));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'ESTADÍSTICAS POR JUGADOR',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
        // Cabecera de columnas
        Row(
          children: [
            const SizedBox(width: 28),
            const Expanded(
              child: Text('Jugador',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 11)),
            ),
            _headerCell('⚽'),
            _headerCell('🅰️'),
            _headerCell('↔️'),
            _headerCell('🎯'),
            _headerCell('🔄'),
            _headerCell('❌'),
            _headerCell('🟡'),
            _headerCell('🔴'),
          ],
        ),
        const SizedBox(height: 6),
        const Divider(color: Colors.white10, height: 1),
        const SizedBox(height: 6),
        // Fila por cada jugador participante
        ...participants.map((p) => _playerRow(p)),
        const SizedBox(height: 8),
        // Leyenda de iconos
        const Text(
          '⚽ Goles  🅰️ Asist  ↔️ Regates  🎯 Tiros  🔄 Recupera  ❌ Pérdidas  🟡 Amarilla  🔴 Roja',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
        ),
      ],
    );
  }

  Widget _headerCell(String text) {
    return SizedBox(
      width: 26,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _playerRow(Player player) {
    final stats    = match.statsForPlayer(player.id);
    final isSub    = !match.lineup.contains(player.id);
    final posColor = positionColors[player.position] ?? AppColors.accent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Dorsal con color de posición
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: posColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                '${player.number}',
                style: TextStyle(
                  color: posColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Nombre con etiqueta SUB si entró como sustituto
          Expanded(
            child: Row(
              children: [
                Text(
                  player.name.split(' ').last,
                  style: TextStyle(
                    color: isSub
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (isSub) ...[
                  const SizedBox(width: 4),
                  const Text(
                    'SUB',
                    style: TextStyle(
                      color: AppColors.accentWarm,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Estadísticas individuales del partido
          _statCell(stats[EventType.goal]       ?? 0, AppColors.accentWarm),
          _statCell(stats[EventType.assist]     ?? 0, const Color(0xFF64B5F6)),
          _statCell(stats[EventType.dribble]    ?? 0, AppColors.accent),
          _statCell(stats[EventType.shot]       ?? 0, const Color(0xFFFF8A65)),
          _statCell(stats[EventType.recovery]   ?? 0, const Color(0xFF80CBC4)),
          _statCell(stats[EventType.ballLoss]   ?? 0, AppColors.danger),
          _statCell(stats[EventType.yellowCard] ?? 0, AppColors.yellow),
          _statCell(stats[EventType.redCard]    ?? 0, AppColors.danger),
        ],
      ),
    );
  }

  Widget _statCell(int value, Color color) {
    return SizedBox(
      width: 26,
      child: Text(
        value > 0 ? '$value' : '·',
        textAlign: TextAlign.center,
        style: TextStyle(
          // Solo mostramos color si el valor es mayor que 0
          color: value > 0
              ? color
              : AppColors.textSecondary.withOpacity(0.4),
          fontSize: 13,
          fontWeight: value > 0 ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}