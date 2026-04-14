import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/players_provider.dart';
import '../models/player.dart';
import '../utils/constants.dart';
import '../utils/form_calculator.dart';
import '../utils/pdf_generator.dart'; // ← para exportar el perfil a PDF

// Recibe el ID del jugador como argumento de ruta:
// Navigator.pushNamed(context, '/player', arguments: player.id)
class PlayerDetailScreen extends StatelessWidget {
  const PlayerDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerId = ModalRoute.of(context)!.settings.arguments as String;
    final player   = context.watch<PlayersProvider>().getById(playerId);

    if (player == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text('Jugador no encontrado',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final form     = FormCalculator.calculate(player);
    final posColor = positionColors[player.position] ?? AppColors.accent;
    final isKeeper = player.position == 'POR';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // AppBar expandible con cabecera visual del jugador
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(player, form, posColor),
            ),
            actions: [
              // Botón exportar perfil del jugador a PDF
              IconButton(
                icon: const Icon(Icons.picture_as_pdf,
                    color: AppColors.accentWarm),
                tooltip: 'Exportar PDF',
                onPressed: () => PdfGenerator.exportPlayerProfile(player),
              ),
              // Botón editar datos del jugador
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    color: AppColors.accent),
                onPressed: () => _showEditDialog(context, player),
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // Estado de forma con barra de progreso grande
                _sectionTitle('Estado de Forma'),
                const SizedBox(height: 8),
                _FormMeter(score: form, player: player),

                const SizedBox(height: 24),

                // Grid de estadísticas acumuladas.
                // Los porteros tienen grid diferente con paradas incluidas.
                _sectionTitle('Estadísticas Acumuladas'),
                const SizedBox(height: 12),
                isKeeper
                    ? _buildKeeperStatsGrid(player)
                    : _buildPlayerStatsGrid(player),

                const SizedBox(height: 24),

                // Gráfica de barras horizontales con medias por partido.
                // También diferenciada para porteros y jugadores de campo.
                _sectionTitle('Estadísticas Detalladas'),
                const SizedBox(height: 12),
                isKeeper
                    ? _KeeperBarChart(player: player)
                    : _BarChart(player: player),

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Player player, double form, Color posColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [posColor.withOpacity(0.6), AppColors.surface],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(72, 8, 16, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Dorsal grande como elemento visual principal
              Text(
                '${player.number}',
                style: TextStyle(
                  color: posColor,
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _positionChip(player.position, posColor),
                        const SizedBox(width: 8),
                        Text(
                          '${player.totalMatches} partidos',
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _positionChip(String pos, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        pos,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  // Grid 3x3 para jugadores de campo (sin paradas)
  Widget _buildPlayerStatsGrid(Player player) {
    final stats = [
      _StatItem('Goles',          '${player.goals}',
          Icons.sports_soccer,      AppColors.accentWarm),
      _StatItem('Asistencias',    '${player.assists}',
          Icons.volunteer_activism,  const Color(0xFF64B5F6)),
      _StatItem('Regates',        '${player.dribbles}',
          Icons.swap_horiz,          AppColors.accent),
      _StatItem('Tiros',          '${player.shots}',
          Icons.gps_fixed,           const Color(0xFFFF8A65)),
      _StatItem('Centros',        '${player.crosses}',
          Icons.sports,              const Color(0xFFCE93D8)),
      _StatItem('Recuperaciones', '${player.recoveries}',
          Icons.shield,              const Color(0xFF80CBC4)),
      _StatItem('Pérdidas',       '${player.ballLosses}',
          Icons.sports_soccer,       AppColors.danger),
      _StatItem('Amarillas',      '${player.yellowCards}',
          Icons.square,              AppColors.yellow),
      _StatItem('Rojas',          '${player.redCards}',
          Icons.square,              AppColors.danger),
    ];
    return _statsGrid(stats);
  }

  // Grid para porteros: paradas como primera estadística,
  // sin tiros ni centros que no son relevantes para esta posición
  Widget _buildKeeperStatsGrid(Player player) {
    final stats = [
      _StatItem('Paradas',        '${player.saves}',
          Icons.back_hand,           const Color(0xFF80DEEA)),
      _StatItem('Recuperaciones', '${player.recoveries}',
          Icons.shield,              const Color(0xFF80CBC4)),
      _StatItem('Pérdidas',       '${player.ballLosses}',
          Icons.sports_soccer,       AppColors.danger),
      _StatItem('Regates',        '${player.dribbles}',
          Icons.swap_horiz,          AppColors.accent),
      _StatItem('Asistencias',    '${player.assists}',
          Icons.volunteer_activism,  const Color(0xFF64B5F6)),
      _StatItem('Goles',          '${player.goals}',
          Icons.sports_soccer,       AppColors.accentWarm),
      _StatItem('Amarillas',      '${player.yellowCards}',
          Icons.square,              AppColors.yellow),
      _StatItem('Rojas',          '${player.redCards}',
          Icons.square,              AppColors.danger),
    ];
    return _statsGrid(stats);
  }

  // Grid reutilizable para ambos tipos de jugador
  Widget _statsGrid(List<_StatItem> stats) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: stats.map((s) => _statCard(s)).toList(),
    );
  }

  Widget _statCard(_StatItem item) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: item.color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, color: item.color, size: 20),
          const SizedBox(height: 6),
          Text(
            item.value,
            style: TextStyle(
              color: item.color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            item.label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, Player player) {
    final nameCtrl   = TextEditingController(text: player.name);
    final numberCtrl = TextEditingController(text: '${player.number}');
    String selectedPos = player.position;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Editar Jugador',
              style: TextStyle(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDeco('Nombre'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: numberCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                keyboardType: TextInputType.number,
                decoration: _inputDeco('Dorsal'),
              ),
              const SizedBox(height: 10),
              // Selector de posición con botones visuales
              Row(
                children: positions.map((pos) {
                  final isSel = pos == selectedPos;
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
                          color: isSel
                              ? (positionColors[pos] ?? AppColors.accent)
                                  .withOpacity(0.2)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSel
                                ? (positionColors[pos] ??
                                    AppColors.accent)
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          pos,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSel
                                ? (positionColors[pos] ??
                                    AppColors.accent)
                                : AppColors.textSecondary,
                            fontWeight: isSel
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
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent),
              onPressed: () {
                final name   = nameCtrl.text.trim();
                final number = int.tryParse(numberCtrl.text.trim()) ??
                    player.number;
                if (name.isEmpty) return;
                context.read<PlayersProvider>().updatePlayer(
                      player.copyWith(
                        name: name,
                        number: number,
                        position: selectedPos,
                      ),
                    );
                Navigator.pop(context);
              },
              child: const Text('Guardar',
                  style: TextStyle(color: Colors.black87)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      );
}

// ---- Medidor visual de estado de forma ----

class _FormMeter extends StatelessWidget {
  final double score;
  final Player player;
  const _FormMeter({required this.score, required this.player});

  @override
  Widget build(BuildContext context) {
    final color = FormCalculator.color(score);
    final label = FormCalculator.label(score);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Basado en ${player.totalMatches} partidos',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Puntuación numérica en círculo
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.15),
                  border: Border.all(color: color, width: 2),
                ),
                child: Center(
                  child: Text(
                    score.toStringAsFixed(0),
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Barra de progreso grande
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 10,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Goles · Asistencias · Regates · Recuperaciones · Tiros · Centros  −  Pérdidas · Tarjetas',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---- Gráfica de barras para jugadores de campo ----

class _BarChart extends StatelessWidget {
  final Player player;
  const _BarChart({required this.player});

  @override
  Widget build(BuildContext context) {
    final matches = player.totalMatches == 0 ? 1 : player.totalMatches;

    // Métricas relevantes para jugadores de campo
    final data = [
      _BarData('Goles',     player.goals       / matches, AppColors.accentWarm),
      _BarData('Asist',     player.assists     / matches, const Color(0xFF64B5F6)),
      _BarData('Regates',   player.dribbles    / matches, AppColors.accent),
      _BarData('Tiros',     player.shots       / matches, const Color(0xFFFF8A65)),
      _BarData('Centros',   player.crosses     / matches, const Color(0xFFCE93D8)),
      _BarData('Recupera',  player.recoveries  / matches, const Color(0xFF80CBC4)),
      _BarData('Pérdidas',  player.ballLosses  / matches, AppColors.danger),
      _BarData('Amarillas', player.yellowCards / matches, AppColors.yellow),
    ];

    return _buildBarContainer(data);
  }
}

// ---- Gráfica de barras para porteros ----

class _KeeperBarChart extends StatelessWidget {
  final Player player;
  const _KeeperBarChart({required this.player});

  @override
  Widget build(BuildContext context) {
    final matches = player.totalMatches == 0 ? 1 : player.totalMatches;

    // Métricas relevantes para porteros: paradas como métrica principal
    final data = [
      _BarData('Paradas',   player.saves       / matches, const Color(0xFF80DEEA)),
      _BarData('Recupera',  player.recoveries  / matches, const Color(0xFF80CBC4)),
      _BarData('Pérdidas',  player.ballLosses  / matches, AppColors.danger),
      _BarData('Asist',     player.assists     / matches, const Color(0xFF64B5F6)),
      _BarData('Amarillas', player.yellowCards / matches, AppColors.yellow),
      _BarData('Rojas',     player.redCards    / matches, AppColors.danger),
    ];

    return _buildBarContainer(data);
  }
}

// Widget reutilizable que construye el contenedor de barras horizontales.
// Compartido por _BarChart y _KeeperBarChart para evitar duplicar código.
Widget _buildBarContainer(List<_BarData> data) {
  // El valor máximo se usa para normalizar las barras proporcionalmente
  final maxVal = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Media por partido',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 12),
        ...data.map((d) => _buildBar(d, maxVal)),
      ],
    ),
  );
}

// Construye una barra horizontal individual con etiqueta y valor numérico
Widget _buildBar(_BarData d, double maxVal) {
  // Evitamos división por cero si todos los valores son 0
  final ratio = maxVal > 0 ? (d.value / maxVal).clamp(0.0, 1.0) : 0.0;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        SizedBox(
          width: 66,
          child: Text(
            d.label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              // Fondo de la barra
              Container(
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Barra coloreada proporcional al valor
              FractionallySizedBox(
                widthFactor: ratio,
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: d.color.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Valor numérico a la derecha
        SizedBox(
          width: 34,
          child: Text(
            d.value.toStringAsFixed(2),
            style: TextStyle(
              color: d.color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    ),
  );
}

// ---- Clases de datos auxiliares ----

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatItem(this.label, this.value, this.icon, this.color);
}

class _BarData {
  final String label;
  final double value;
  final Color color;
  const _BarData(this.label, this.value, this.color);
}