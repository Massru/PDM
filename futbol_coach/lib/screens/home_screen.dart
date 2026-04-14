import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/players_provider.dart';
import '../providers/match_provider.dart';
import '../models/player.dart';
import '../utils/constants.dart';
import '../utils/form_calculator.dart';
import '../utils/pdf_generator.dart'; // ← para exportar ranking de plantilla
import '../widgets/player_form_badge.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playersProv = context.watch<PlayersProvider>();
    final matchProv   = context.watch<MatchProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.sports_soccer,
                  color: AppColors.accent, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Football Coach',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          // Exportar ranking de forma de toda la plantilla a PDF
          IconButton(
            icon: const Icon(Icons.picture_as_pdf,
                color: AppColors.accentWarm),
            tooltip: 'Exportar ranking',
            onPressed: () => PdfGenerator.exportSquadRanking(
              context.read<PlayersProvider>().players,
            ),
          ),
          // Historial de partidos
          IconButton(
            icon: const Icon(Icons.history,
                color: AppColors.textSecondary),
            tooltip: 'Historial',
            onPressed: () =>
                Navigator.pushNamed(context, '/history'),
          ),
          // Añadir jugador a la plantilla
          IconButton(
            icon: const Icon(Icons.person_add, color: AppColors.accent),
            tooltip: 'Añadir jugador',
            onPressed: () => _showAddPlayerDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner de partido activo (solo visible si hay partido en curso)
          if (matchProv.hasActiveMatch)
            _ActiveMatchBanner(matchProv: matchProv),

          // Botón para crear nueva alineación e iniciar partido
          _buildLineupButton(context),

          // Cabecera de la sección de plantilla
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                const Text(
                  'PLANTILLA',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${playersProv.players.length} jugadores',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11),
                ),
                const Spacer(),
                const Icon(Icons.trending_up,
                    color: AppColors.accent, size: 14),
                const SizedBox(width: 4),
                const Text(
                  'Por forma',
                  style:
                      TextStyle(color: AppColors.accent, fontSize: 11),
                ),
              ],
            ),
          ),

          // Lista de jugadores agrupados por posición
          Expanded(
            child: playersProv.players.isEmpty
                ? _buildEmptyState()
                : _buildPlayerList(context, playersProv),
          ),
        ],
      ),
    );
  }

  Widget _buildLineupButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/lineup'),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accent.withOpacity(0.8),
                AppColors.accent,
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.group, color: Colors.black87, size: 22),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nuevo Partido',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'Seleccionar 11 y arrancar partido',
                    style:
                        TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
              Spacer(),
              Icon(Icons.arrow_forward_ios,
                  color: Colors.black54, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerList(BuildContext context, PlayersProvider prov) {
    // Ordenamos toda la plantilla por estado de forma descendente
    final sorted = [...prov.players]..sort((a, b) =>
        FormCalculator.calculate(b)
            .compareTo(FormCalculator.calculate(a)));

    // Agrupamos por posición respetando el orden definido en constants.dart
    final groups = <String, List<Player>>{};
    for (final pos in positions) {
      final inPos = sorted.where((p) => p.position == pos).toList();
      if (inPos.isNotEmpty) groups[pos] = inPos;
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        for (final entry in groups.entries) ...[
          // Cabecera de sección por posición
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: positionColors[entry.key] ?? AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _positionLabel(entry.key),
                  style: TextStyle(
                    color:
                        positionColors[entry.key] ?? AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          // Tiles de jugadores de esa posición
          ...entry.value.map((p) => _PlayerTile(
                player: p,
                onTap: () => Navigator.pushNamed(context, '/player',
                    arguments: p.id),
                onDelete: () =>
                    _confirmDelete(context, prov, p),
              )),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.group_off,
              color: AppColors.textSecondary.withOpacity(0.3),
              size: 64),
          const SizedBox(height: 16),
          const Text(
            'Sin jugadores aún',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pulsa el + de arriba para añadir\nlos jugadores de tu plantilla',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  String _positionLabel(String pos) {
    const labels = {
      'POR': 'PORTEROS',
      'DEF': 'DEFENSAS',
      'MED': 'CENTROCAMPISTAS',
      'DEL': 'DELANTEROS',
    };
    return labels[pos] ?? pos;
  }

  void _showAddPlayerDialog(BuildContext context) {
    final nameCtrl   = TextEditingController();
    final numberCtrl = TextEditingController();
    String selectedPos = 'MED';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Nuevo Jugador',
              style: TextStyle(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDeco('Nombre completo'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: numberCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                keyboardType: TextInputType.number,
                decoration: _inputDeco('Dorsal'),
              ),
              const SizedBox(height: 12),
              // Selector de posición con botones visuales
              Row(
                children: positions.map((pos) {
                  final isSelected = pos == selectedPos;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setDialogState(() => selectedPos = pos),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 4),
                        padding:
                            const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (positionColors[pos] ?? AppColors.accent)
                                  .withOpacity(0.25)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? (positionColors[pos] ??
                                    AppColors.accent)
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          pos,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected
                                ? (positionColors[pos] ??
                                    AppColors.accent)
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar',
                  style:
                      TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent),
              onPressed: () {
                final name =
                    nameCtrl.text.trim();
                final number =
                    int.tryParse(numberCtrl.text.trim()) ?? 0;
                if (name.isEmpty || number == 0) return;
                context
                    .read<PlayersProvider>()
                    .addPlayer(name, number, selectedPos);
                Navigator.pop(context);
              },
              child: const Text('Añadir',
                  style: TextStyle(color: Colors.black87)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, PlayersProvider prov, Player player) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Eliminar jugador',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '¿Seguro que quieres eliminar a ${player.name}?\nSe perderán todas sus estadísticas.',
          style:
              const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style:
                    TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger),
            onPressed: () {
              prov.removePlayer(player.id);
              Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      );
}

// ---- Tile de jugador en la lista principal ----

class _PlayerTile extends StatelessWidget {
  final Player player;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PlayerTile({
    required this.player,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final form     = FormCalculator.calculate(player);
    final posColor = positionColors[player.position] ?? AppColors.accent;

    return Dismissible(
      // Deslizar a la izquierda para eliminar
      key: Key(player.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false; // El diálogo gestiona el borrado real
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.danger.withOpacity(0.2),
        child: const Icon(Icons.delete_outline,
            color: AppColors.danger),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 3),
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Dorsal con color de posición
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: posColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: posColor.withOpacity(0.4)),
                ),
                child: Center(
                  child: Text(
                    '${player.number}',
                    style: TextStyle(
                      color: posColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
                      '${player.totalMatches} partidos',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Badge de estado de forma
              PlayerFormBadge(score: form),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Banner de partido activo ----

class _ActiveMatchBanner extends StatelessWidget {
  final MatchProvider matchProv;
  const _ActiveMatchBanner({required this.matchProv});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/match'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppColors.danger.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            const _LiveDot(),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PARTIDO EN CURSO',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'vs ${matchProv.currentMatch?.opponent ?? ''} · ${matchProv.timerDisplay}',
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 13),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios,
                color: AppColors.danger, size: 14),
          ],
        ),
      ),
    );
  }
}

// Punto rojo parpadeante que indica partido en vivo
class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 10, height: 10,
        decoration: const BoxDecoration(
          color: AppColors.danger,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}