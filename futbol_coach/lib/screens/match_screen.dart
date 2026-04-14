import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/match_provider.dart';
import '../providers/players_provider.dart';
import '../models/match_event.dart';
import '../models/player.dart';
import '../utils/constants.dart';
import '../widgets/stat_button.dart';
import '../widgets/substitution_dialog.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  Player? _selectedPlayer; // Jugador actualmente seleccionado en el campo

  @override
  Widget build(BuildContext context) {
    final matchProv   = context.watch<MatchProvider>();
    final playersProv = context.watch<PlayersProvider>();
    final match       = matchProv.currentMatch;

    if (match == null) return _buildNoMatch();

    // Jugadores actualmente en campo (se actualiza con sustituciones)
    final onFieldPlayers = match.lineup
        .map((id) => playersProv.getById(id))
        .whereType<Player>()
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(matchProv, match.opponent),
      body: Column(
        children: [
          // Barra superior unificada: cronómetro + marcador en tiempo real
          _buildTopBar(matchProv, match.opponent),
          // Campo de fútbol con jugadores posicionados
          Expanded(
            flex: 3,
            child: _buildField(onFieldPlayers, matchProv),
          ),
          // Panel de botones de estadísticas (solo si hay jugador seleccionado)
          if (_selectedPlayer != null)
            _buildStatPanel(matchProv, _selectedPlayer!),
          // Barra inferior con botón de sustitución
          _buildActionButtons(matchProv, playersProv, match.lineup),
        ],
      ),
    );
  }

  AppBar _buildAppBar(MatchProvider prov, String opponent) {
    return AppBar(
      backgroundColor: AppColors.surface,
      title: Text(
        'vs $opponent',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        // Deshacer último evento registrado
        // Si era un gol también resta del marcador
        IconButton(
          icon: const Icon(Icons.undo, color: AppColors.accentWarm),
          onPressed: () {
            prov.undoLastEvent();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Último evento deshecho')),
            );
          },
        ),
        // Finalizar partido
        TextButton(
          onPressed: () => _showFinishDialog(prov),
          child: const Text(
            'FIN',
            style: TextStyle(
                color: AppColors.danger, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // Barra superior unificada:
  // - Izquierda: cronómetro con botón play/pause
  // - Centro: marcador en tiempo real con nuestros goles y los del rival
  // - Derecha: botones de ajuste fino de minuto
  Widget _buildTopBar(MatchProvider prov, String opponent) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // --- Cronómetro con play/pause ---
          GestureDetector(
            onTap: () =>
                prov.isRunning ? prov.pauseTimer() : prov.startTimer(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 34, height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: prov.isRunning
                    ? AppColors.accent.withOpacity(0.2)
                    : AppColors.accentWarm.withOpacity(0.2),
                border: Border.all(
                  color: prov.isRunning
                      ? AppColors.accent
                      : AppColors.accentWarm,
                ),
              ),
              child: Icon(
                prov.isRunning ? Icons.pause : Icons.play_arrow,
                color: prov.isRunning
                    ? AppColors.accent
                    : AppColors.accentWarm,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Tiempo en formato MM:SS
          // FontFeature.tabularFigures evita que el texto salte de ancho al cambiar dígitos
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                prov.timerDisplay,
                style: TextStyle(
                  color: prov.isRunning
                      ? AppColors.accent
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                prov.isRunning ? 'EN JUEGO' : 'PARADO',
                style: TextStyle(
                  color: prov.isRunning
                      ? AppColors.accent
                      : AppColors.textSecondary,
                  fontSize: 8,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),

          const Spacer(),

          // --- Marcador central ---
          _buildScoreboard(prov, opponent),

          const Spacer(),

          // --- Ajuste fino de minuto (±1 minuto) ---
          _minuteAdjustButton(prov, -1),
          const SizedBox(width: 4),
          const Text(
            'min',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
          ),
          const SizedBox(width: 4),
          _minuteAdjustButton(prov, 1),
        ],
      ),
    );
  }

  // Marcador en tiempo real:
  // - Nuestros goles (verde): se actualizan automáticamente al registrar evento gol
  // - Goles del rival (rojo): botón + para sumar con tap, botón - con pulsación larga
  Widget _buildScoreboard(MatchProvider prov, String opponent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nuestros goles (se actualiza automáticamente con eventos de gol)
          Column(
            children: [
              const Text(
                'Nosotros',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 9),
              ),
              Text(
                '${prov.goalsFor}',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),

          // Separador central
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '-',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Goles del rival con controles manuales
          Column(
            children: [
              // Nombre del rival truncado si es muy largo
              Text(
                opponent.length > 8
                    ? '${opponent.substring(0, 8)}...'
                    : opponent,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 9),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botón restar gol rival: requiere pulsación larga para evitar errores accidentales
                  GestureDetector(
                    onLongPress: prov.goalsAgainst > 0
                        ? () {
                            prov.removeGoalAgainst();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Gol del rival deshecho'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        : null,
                    child: Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.remove,
                        size: 12,
                        // Desactivamos visualmente el botón si no hay goles que restar
                        color: prov.goalsAgainst > 0
                            ? AppColors.danger
                            : AppColors.textSecondary.withOpacity(0.3),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Contador de goles del rival
                  Text(
                    '${prov.goalsAgainst}',
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Botón sumar gol rival: tap normal
                  GestureDetector(
                    onTap: () => prov.addGoalAgainst(),
                    child: Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 12,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Botón de ajuste fino de minuto (±1 minuto = ±60 segundos internamente)
  Widget _minuteAdjustButton(MatchProvider prov, int delta) {
    return GestureDetector(
      onTap: () => prov.adjustMinute(delta),
      child: Container(
        width: 26, height: 26,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            delta > 0 ? '+1' : '-1',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildField(List<Player> players, MatchProvider prov) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // Campo de fútbol con gradiente verde
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1B5E20),
            Color(0xFF2E7D32),
            Color(0xFF1B5E20),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Stack(
        children: [
          // Líneas del campo dibujadas con CustomPainter
          _buildFieldLines(),
          // Jugadores posicionados por líneas
          ..._buildPlayerPositions(players, prov),
        ],
      ),
    );
  }

  Widget _buildFieldLines() {
    return CustomPaint(
      painter: _FieldLinesPainter(),
      child: const SizedBox.expand(),
    );
  }

  List<Widget> _buildPlayerPositions(
      List<Player> players, MatchProvider prov) {
    final keepers     = players.where((p) => p.position == 'POR').toList();
    final defenders   = players.where((p) => p.position == 'DEF').toList();
    final midfielders = players.where((p) => p.position == 'MED').toList();
    final forwards    = players.where((p) => p.position == 'DEL').toList();

    final widgets = <Widget>[];

    // Distribuye una fila de jugadores horizontalmente en el campo
    // topFraction: 0.0 = arriba del campo, 1.0 = abajo
    void addRowAligned(List<Player> row, double topFraction) {
      for (int i = 0; i < row.length; i++) {
        final xAlign = row.length == 1
            ? 0.0
            : -1.0 + (2 * i / (row.length - 1));
        final yAlign = -1.0 + 2 * topFraction;
        widgets.add(
          Align(
            alignment: Alignment(xAlign, yAlign),
            child: _playerDot(row[i], prov),
          ),
        );
      }
    }

    addRowAligned(keepers,     0.88); // Portero - abajo
    addRowAligned(defenders,   0.68); // Defensas
    addRowAligned(midfielders, 0.45); // Centrocampistas
    addRowAligned(forwards,    0.18); // Delanteros - arriba

    return widgets;
  }

  // Círculo del jugador en el campo con badges de tarjetas.
  // Al pulsar selecciona el jugador y muestra el panel de estadísticas.
  Widget _playerDot(Player player, MatchProvider prov) {
    final isSelected = _selectedPlayer?.id == player.id;
    final posColor   = positionColors[player.position] ?? AppColors.accent;
    final yellows    = prov.getStatForPlayer(player.id, EventType.yellowCard);
    final reds       = prov.getStatForPlayer(player.id, EventType.redCard);

    return GestureDetector(
      onTap: () => setState(() {
        // Toggle: si ya estaba seleccionado lo deselecciona
        _selectedPlayer = isSelected ? null : player;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width:  isSelected ? 54 : 44,
        height: isSelected ? 54 : 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: posColor,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white38,
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(
                  color: posColor.withOpacity(0.6), blurRadius: 12)]
              : [],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${player.number}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    player.name.split(' ').first,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 7),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Badge amarilla (esquina superior derecha)
            if (yellows > 0)
              Positioned(
                top: 0, right: 0,
                child: Container(
                  width: 12, height: 12,
                  decoration: const BoxDecoration(
                    color: AppColors.yellow,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$yellows',
                      style: const TextStyle(
                          fontSize: 7, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            // Badge roja (esquina superior izquierda)
            if (reds > 0)
              Positioned(
                top: 0, left: 0,
                child: Container(
                  width: 12, height: 12,
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Panel inferior con los botones de estadísticas del jugador seleccionado.
  // Si el jugador es portero, se muestra el botón de parada además de los comunes.
  // Scroll horizontal para acomodar todos los botones.
  Widget _buildStatPanel(MatchProvider prov, Player player) {
    final isKeeper = player.position == 'POR';

    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: AppColors.accent, size: 16),
              const SizedBox(width: 6),
              Text(
                '${player.number} · ${player.name}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Resumen rápido de las stats más importantes del partido
              _miniStat('⚽', prov.getStatForPlayer(player.id, EventType.goal)),
              // Para porteros mostramos paradas en el resumen rápido
              if (isKeeper)
                _miniStat('🧤', prov.getStatForPlayer(player.id, EventType.save)),
              _miniStat('🟡', prov.getStatForPlayer(player.id, EventType.yellowCard)),
              _miniStat('🔴', prov.getStatForPlayer(player.id, EventType.redCard)),
            ],
          ),
          const SizedBox(height: 8),
          // Scroll horizontal para todos los botones de estadísticas
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Botón de parada: SOLO visible para porteros y siempre primero
                if (isKeeper)
                  StatButton(
                    label: 'Parada',
                    icon: Icons.back_hand,
                    color: const Color(0xFF80DEEA),
                    count: prov.getStatForPlayer(player.id, EventType.save),
                    onTap: () => prov.addEvent(player.id, EventType.save),
                  ),
                StatButton(
                  label: 'Pérdida',
                  icon: Icons.sports_soccer,
                  color: AppColors.danger,
                  count: prov.getStatForPlayer(player.id, EventType.ballLoss),
                  onTap: () => prov.addEvent(player.id, EventType.ballLoss),
                ),
                StatButton(
                  label: 'Regate',
                  icon: Icons.swap_horiz,
                  color: AppColors.accent,
                  count: prov.getStatForPlayer(player.id, EventType.dribble),
                  onTap: () => prov.addEvent(player.id, EventType.dribble),
                ),
                StatButton(
                  label: 'Amarilla',
                  icon: Icons.square,
                  color: AppColors.yellow,
                  count: prov.getStatForPlayer(player.id, EventType.yellowCard),
                  onTap: () => prov.addEvent(player.id, EventType.yellowCard),
                ),
                StatButton(
                  label: 'Roja',
                  icon: Icons.square,
                  color: AppColors.danger,
                  count: prov.getStatForPlayer(player.id, EventType.redCard),
                  onTap: () => prov.addEvent(player.id, EventType.redCard),
                ),
                StatButton(
                  label: 'Gol',
                  icon: Icons.sports_soccer,
                  color: AppColors.accentWarm,
                  count: prov.getStatForPlayer(player.id, EventType.goal),
                  // Al registrar un gol también actualiza el marcador automáticamente
                  onTap: () => prov.addEvent(player.id, EventType.goal),
                ),
                StatButton(
                  label: 'Asistencia',
                  icon: Icons.volunteer_activism,
                  color: const Color(0xFF64B5F6),
                  count: prov.getStatForPlayer(player.id, EventType.assist),
                  onTap: () => prov.addEvent(player.id, EventType.assist),
                ),
                // Ocultamos centros y tiros para porteros ya que no son relevantes
                if (!isKeeper) ...[
                  StatButton(
                    label: 'Centro',
                    icon: Icons.sports,
                    color: const Color(0xFFCE93D8),
                    count: prov.getStatForPlayer(player.id, EventType.cross),
                    onTap: () => prov.addEvent(player.id, EventType.cross),
                  ),
                  StatButton(
                    label: 'Tiro',
                    icon: Icons.gps_fixed,
                    color: const Color(0xFFFF8A65),
                    count: prov.getStatForPlayer(player.id, EventType.shot),
                    onTap: () => prov.addEvent(player.id, EventType.shot),
                  ),
                ],
                StatButton(
                  label: 'Recuperación',
                  icon: Icons.shield,
                  color: const Color(0xFF80CBC4),
                  count: prov.getStatForPlayer(player.id, EventType.recovery),
                  onTap: () => prov.addEvent(player.id, EventType.recovery),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String emoji, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '$emoji $count',
        style: const TextStyle(
            color: AppColors.textSecondary, fontSize: 12),
      ),
    );
  }

  Widget _buildActionButtons(
    MatchProvider prov,
    PlayersProvider playersProv,
    List<String> lineup,
  ) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.card),
            icon: const Icon(Icons.swap_vert, color: Colors.white),
            label: const Text('Sustitución',
                style: TextStyle(color: Colors.white)),
            onPressed: () =>
                _showSubstitutionDialog(prov, playersProv, lineup),
          ),
        ],
      ),
    );
  }

  void _showSubstitutionDialog(
    MatchProvider prov,
    PlayersProvider playersProv,
    List<String> lineup,
  ) {
    showDialog(
      context: context,
      builder: (_) => SubstitutionDialog(
        onFieldPlayerIds: lineup,
        allPlayers: playersProv.players,
        onSubstitution: (outId, inId) {
          prov.addEvent(outId, EventType.substitutionOut,
              relatedPlayerId: inId);
          prov.addEvent(inId, EventType.substitutionIn,
              relatedPlayerId: outId);
        },
      ),
    );
  }

  // Diálogo de finalizar partido.
  // Ya no pedimos el resultado manualmente porque lo tenemos del marcador en vivo.
  // Solo confirmamos mostrando el resultado actual.
  void _showFinishDialog(MatchProvider prov) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          'Finalizar Partido',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Resultado final: ${prov.goalsFor} - ${prov.goalsAgainst}\n\n¿Confirmas que quieres finalizar el partido?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(context); // Cierra el diálogo
              prov.finishMatch();
              _applyStatsToPlayers(prov);
              // Vuelve al inicio eliminando toda la pila de navegación
              // para que el botón atrás no vuelva al partido finalizado
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (route) => false,
              );
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  // Aplica las estadísticas del partido finalizado a cada jugador participante.
  // Incluye titulares y sustitutos que entraron durante el partido.
  void _applyStatsToPlayers(MatchProvider prov) {
    final playersProv = context.read<PlayersProvider>();
    final match = prov.currentMatch;
    if (match == null) return;

    // Incluimos titulares y sustitutos que entraron
    final participantIds = <String>{
      ...match.lineup,
      ...match.events
          .where((e) => e.type == EventType.substitutionIn)
          .map((e) => e.playerId),
    };

    for (final id in participantIds) {
      final stats = match.statsForPlayer(id);
      playersProv.applyMatchStats(
        playerId:      id,
        ballLosses:    stats[EventType.ballLoss]   ?? 0,
        dribbles:      stats[EventType.dribble]    ?? 0,
        yellowCards:   stats[EventType.yellowCard] ?? 0,
        redCards:      stats[EventType.redCard]    ?? 0,
        goals:         stats[EventType.goal]       ?? 0,
        assists:       stats[EventType.assist]     ?? 0,
        minutesPlayed: 90,
        crosses:       stats[EventType.cross]      ?? 0,
        recoveries:    stats[EventType.recovery]   ?? 0,
        shots:         stats[EventType.shot]       ?? 0,
        saves:         stats[EventType.save]       ?? 0,
      );
    }
  }

  Widget _buildNoMatch() {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          'No hay partido activo.\nCrea uno desde el menú principal.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

// Pinta las líneas del campo sobre el fondo verde usando CustomPainter
class _FieldLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color       = Colors.white24
      ..strokeWidth = 1.5
      ..style       = PaintingStyle.stroke;

    // Línea central
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
    // Círculo central
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.15,
      paint,
    );
    // Área grande propia (abajo)
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.2, size.height * 0.78,
        size.width * 0.6, size.height * 0.22,
      ),
      paint,
    );
    // Área grande rival (arriba)
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.2, 0,
        size.width * 0.6, size.height * 0.22,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}