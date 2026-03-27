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
  Player? _selectedPlayer;

  @override
  Widget build(BuildContext context) {
    final matchProv   = context.watch<MatchProvider>();
    final playersProv = context.watch<PlayersProvider>();
    final match       = matchProv.currentMatch;

    if (match == null) return _buildNoMatch();

    final onFieldPlayers = match.lineup
        .map((id) => playersProv.getById(id))
        .whereType<Player>()
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(matchProv, match.opponent),
      body: Column(
        children: [
          _buildMinuteBar(matchProv),
          Expanded(
            flex: 3,
            child: _buildField(onFieldPlayers, matchProv),
          ),
          if (_selectedPlayer != null)
            _buildStatPanel(matchProv, _selectedPlayer!),
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
        IconButton(
          icon: const Icon(Icons.undo, color: AppColors.accentWarm),
          onPressed: () {
            prov.undoLastEvent();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Último evento deshecho')),
            );
          },
        ),
        TextButton(
          onPressed: () => _showFinishDialog(prov),
          child: const Text(
            'FIN',
            style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // Barra con cronómetro real: play/pause + minuto actual y botones de ajuste
  Widget _buildMinuteBar(MatchProvider prov) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Botón play/pause
          GestureDetector(
            onTap: () => prov.isRunning ? prov.pauseTimer() : prov.startTimer(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: prov.isRunning
                    ? AppColors.accent.withOpacity(0.2)
                    : AppColors.accentWarm.withOpacity(0.2),
                border: Border.all(
                  color: prov.isRunning ? AppColors.accent : AppColors.accentWarm,
                ),
              ),
              child: Icon(
                prov.isRunning ? Icons.pause : Icons.play_arrow,
                color: prov.isRunning ? AppColors.accent : AppColors.accentWarm,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Muestra MM:SS (convertido de segundos internos)
          Text(
            prov.timerDisplay,
            style: TextStyle(
              color: prov.isRunning ? AppColors.accent : AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 22,
              fontFeatures: const [FontFeature.tabularFigures()], // Evita que salte el ancho al cambiar dígitos
            ),
          ),
          const SizedBox(width: 8),
          Text(
            prov.isRunning ? 'EN JUEGO' : 'PARADO',
            style: TextStyle(
              color: prov.isRunning ? AppColors.accent : AppColors.textSecondary,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          _minuteAdjustButton(prov, -1),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Ajustar',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ),
          _minuteAdjustButton(prov, 1),
        ],
      ),
    );
  }

  Widget _minuteAdjustButton(MatchProvider prov, int delta) {
    return GestureDetector(
      onTap: () => prov.adjustMinute(delta), // ← ahora llama a adjustMinute
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            delta > 0 ? '+1' : '-1',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ),
      ),
    );
  }

  // Visualización táctica: campo con líneas y posiciones de jugadores
  Widget _buildField(List<Player> players, MatchProvider prov) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // Gradiente verde estilo cancha de fútbol
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF1B5E20)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Stack(
        children: [
          _buildFieldLines(),
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

  // Posiciona los jugadores en el campo según su posición (POR, DEF, MED, DEL)
  // Usa Alignment para distribuirlos uniformemente por líneas
  List<Widget> _buildPlayerPositions(List<Player> players, MatchProvider prov) {
    final keepers     = players.where((p) => p.position == 'POR').toList();
    final defenders   = players.where((p) => p.position == 'DEF').toList();
    final midfielders = players.where((p) => p.position == 'MED').toList();
    final forwards    = players.where((p) => p.position == 'DEL').toList();

    final widgets = <Widget>[];

    // Función auxiliar para agregar una fila de jugadores alineados
    // Calcula automáticamente las posiciones X e Y según el índice en la fila
    void addRowAligned(List<Player> row, double topFraction) {
      for (int i = 0; i < row.length; i++) {
        // Calcula posición X: distribuye uniformemente en la horizontal
        // Si hay un solo jugador (portero), lo pone al centro (0.0)
        // Si hay múltiples, los distribuye de -1.0 a 1.0 uniformemente
        final xAlign = row.length == 1
            ? 0.0
            : -1.0 + (2 * i / (row.length - 1));
        // Calcula posición Y: fila de la cancha
        // topFraction 0.88 = casi arriba (portero), 0.18 = casi abajo (delanteros)
        final yAlign = -1.0 + 2 * topFraction;
        widgets.add(
          Align(
            alignment: Alignment(xAlign, yAlign),
            child: _playerDot(row[i], prov),
          ),
        );
      }
    }

    // Distribuye líneas tácticas: Portero → Defensas → Mediocampistas → Delanteros
    // Los números (0.88, 0.68, etc) representan la fracción vertical en el campo
    addRowAligned(keepers,     0.88);
    addRowAligned(defenders,   0.68);
    addRowAligned(midfielders, 0.45);
    addRowAligned(forwards,    0.18);

    return widgets;
  }

  // Crea el punto interactivo (círculo) del jugador en el campo
  // Muestra: dorsal, nombre, tarjetas, y estado de selección
  // Al pulsar, selecciona/deselecciona al jugador para ver sus estadísticas
  Widget _playerDot(Player player, MatchProvider prov) {
    final isSelected = _selectedPlayer?.id == player.id;
    final posColor   = positionColors[player.position] ?? AppColors.accent; // Color por posición
    final yellows    = prov.getStatForPlayer(player.id, EventType.yellowCard);
    final reds       = prov.getStatForPlayer(player.id, EventType.redCard);

    return GestureDetector(
      // Al tocar este punto, alterna la selección del jugador
      onTap: () => setState(() {
        _selectedPlayer = isSelected ? null : player; // Toggle
      }),
      child: AnimatedContainer(
        // Anima suavemente el tamaño y sombra al cambiar de estado
        duration: const Duration(milliseconds: 200),
        width:  isSelected ? 54 : 44, // Más grande si está seleccionado
        height: isSelected ? 54 : 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: posColor,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white38,
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: posColor.withOpacity(0.6), blurRadius: 12)]
              : [],
        ),
        child: Stack(
          children: [
            // Centro: dorsal y nombre del jugador
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
                  // Primer nombre del jugador
                  Text(
                    player.name.split(' ').first,
                    style: const TextStyle(color: Colors.white70, fontSize: 7),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Esquina superior derecha: tarjeta amarilla (si la tiene)
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
                      style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            // Esquina superior izquierda: tarjeta roja (si la tiene)
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

  // Panel con estadísticas del jugador seleccionado
  // Muestra resumen rápido y botones para registrar eventos
  Widget _buildStatPanel(MatchProvider prov, Player player) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado: dorsal, nombre, y mini-estadísticas
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
              // Mini-resumen: goles, tarjetas amarillas y rojas
              _miniStat('⚽', prov.getStatForPlayer(player.id, EventType.goal)),
              _miniStat('🟡', prov.getStatForPlayer(player.id, EventType.yellowCard)),
              _miniStat('🔴', prov.getStatForPlayer(player.id, EventType.redCard)),
            ],
          ),
          const SizedBox(height: 8),
          // Lista horizontal de StatButtons para registrar cada tipo de evento
          // Scroll horizontal si no caben todos en la pantalla
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
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
                  onTap: () => prov.addEvent(player.id, EventType.goal),
                ),
                StatButton(
                  label: 'Asistencia',
                  icon: Icons.volunteer_activism,
                  color: const Color(0xFF64B5F6),
                  count: prov.getStatForPlayer(player.id, EventType.assist),
                  onTap: () => prov.addEvent(player.id, EventType.assist),
                ),
                StatButton(
                  label: 'Centro',
                  icon: Icons.sports,
                  color: const Color(0xFFCE93D8),
                  count: prov.getStatForPlayer(player.id, EventType.cross),
                  onTap: () => prov.addEvent(player.id, EventType.cross),
                ),
                StatButton(
                  label: 'Recuperación',
                  icon: Icons.shield,
                  color: const Color(0xFF80CBC4),
                  count: prov.getStatForPlayer(player.id, EventType.recovery),
                  onTap: () => prov.addEvent(player.id, EventType.recovery),
                ),
                StatButton(
                  label: 'Tiro',
                  icon: Icons.gps_fixed,
                  color: const Color(0xFFFF8A65),
                  count: prov.getStatForPlayer(player.id, EventType.shot),
                  onTap: () => prov.addEvent(player.id, EventType.shot),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Muestra un mini-stat: emoji + número
  Widget _miniStat(String emoji, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      // Muestra el emoji seguido del contador
      child: Text(
        '$emoji $count',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
    );
  }

  // Barra de botones inferiores: solo botón de sustitución
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
          // Botón para cambair jugador (sustitución)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.card),
            icon: const Icon(Icons.swap_vert, color: Colors.white),
            label: const Text('Sustitución', style: TextStyle(color: Colors.white)),
            onPressed: () => _showSubstitutionDialog(prov, playersProv, lineup),
          ),
        ],
      ),
    );
  }

  // Muestra el diálogo de sustitución
  // El usuario elige primero quién sale y luego quién entra
  void _showSubstitutionDialog(
    MatchProvider prov,
    PlayersProvider playersProv,
    List<String> lineup,
  ) {
    showDialog(
      context: context,
      builder: (_) => SubstitutionDialog(
        onFieldPlayerIds: lineup, // Jugadores que están en cancha
        allPlayers: playersProv.players, // Todos los jugadores
        // Callback cuando se confirma la sustitución
        onSubstitution: (outId, inId) {
          // Registra dos eventos: salida del jugador y entrada del otro
          prov.addEvent(outId, EventType.substitutionOut, relatedPlayerId: inId);
          prov.addEvent(inId,  EventType.substitutionIn,  relatedPlayerId: outId);
        },
      ),
    );
  }

  // Diálogo para finaliziar el partido
  // Permite ingresar goles a favor y en contra
  void _showFinishDialog(MatchProvider prov) {
    int goalsFor = 0, goalsAgainst = 0;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          'Finalizar Partido',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Campo para goles propios
            _goalInput('Goles a favor',   (v) => goalsFor = v),
            const SizedBox(height: 8),
            // Campo para goles del rival
            _goalInput('Goles en contra', (v) => goalsAgainst = v),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(context);
              prov.finishMatch(goalsFor, goalsAgainst);
              _applyStatsToPlayers(prov);
              Navigator.pop(context);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Widget _goalInput(String label, Function(int) onChanged) {
    return TextField(
      keyboardType: TextInputType.number,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      onChanged: (v) => onChanged(int.tryParse(v) ?? 0),
    );
  }

  void _applyStatsToPlayers(MatchProvider prov) {
    final playersProv = context.read<PlayersProvider>();
    final match = prov.currentMatch;
    if (match == null) return;
  
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

class _FieldLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color       = Colors.white24
      ..strokeWidth = 1.5
      ..style       = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.15,
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.2, size.height * 0.78,
        size.width * 0.6, size.height * 0.22,
      ),
      paint,
    );
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