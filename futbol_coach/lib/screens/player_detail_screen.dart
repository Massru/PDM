import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/players_provider.dart';
import '../models/player.dart';
import '../utils/constants.dart';
import '../utils/form_calculator.dart';

// Pantalla de detalle del jugador:
// - Recibe el ID del jugador como argumento de ruta
// - Muestra profundo análisis: forma, estadísticas, gráficas de rendimiento
// - Permite editar nombre/dorsal
// - Usa CustomScrollView para UI fluida

class PlayerDetailScreen extends StatelessWidget {
  const PlayerDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtiene el ID del jugador desde los argumentos de navegación
    final playerId = ModalRoute.of(context)!.settings.arguments as String;
    final player   = context.watch<PlayersProvider>().getById(playerId);

    if (player == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: Text('Jugador no encontrado', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final form     = FormCalculator.calculate(player);
    final posColor = positionColors[player.position] ?? AppColors.accent;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // --- AppBar con cabecera del jugador ---
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.surface,
            flexibleSpace: FlexibleSpaceBar(
              // Cabecera expandida con foto/color y datos del jugador
            background: _buildHeader(player, form, posColor),
            ),
            // Botón de editar nombre/dorsal
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.accent),
                onPressed: () => _showEditDialog(context, player),
              ),
            ],
          ),

          // --- Contenido ---
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // Sección: Estado de forma
                _sectionTitle('Estado de Forma'),
                const SizedBox(height: 8),
                _FormMeter(score: form, player: player),

                const SizedBox(height: 24),

                // Sección: Estadísticas del partido
                _sectionTitle('Estadísticas Acumuladas'),
                const SizedBox(height: 12),
                _buildStatsGrid(player),

                const SizedBox(height: 24),

                // Sección: Gráfica de radar
                _sectionTitle('Perfil de Rendimiento'),
                const SizedBox(height: 12),
                _RadarChart(player: player),

                const SizedBox(height: 24),

                // Sección: Gráfica de barras
                _sectionTitle('Estadísticas Detalladas'),
                const SizedBox(height: 12),
                _BarChart(player: player),

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
          colors: [
            posColor.withOpacity(0.6),
            AppColors.surface,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(72, 8, 16, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Dorsal grande
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
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
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

  // Grid 3x2 con las estadísticas principales
  Widget _buildStatsGrid(Player player) {
    final stats = [
      _StatItem('Goles',         '${player.goals}',       Icons.sports_soccer,  AppColors.accentWarm),
      _StatItem('Asistencias',   '${player.assists}',     Icons.volunteer_activism, const Color(0xFF64B5F6)),
      _StatItem('Regates',       '${player.dribbles}',    Icons.swap_horiz,     AppColors.accent),
      _StatItem('Tiros',         '${player.shots}',       Icons.gps_fixed,      const Color(0xFFFF8A65)),
      _StatItem('Centros',       '${player.crosses}',     Icons.sports,         const Color(0xFFCE93D8)),
      _StatItem('Recuperaciones','${player.recoveries}',  Icons.shield,         const Color(0xFF80CBC4)),
      _StatItem('Pérdidas',      '${player.ballLosses}',  Icons.sports_soccer,  AppColors.danger),
      _StatItem('Amarillas',     '${player.yellowCards}', Icons.square,         AppColors.yellow),
      _StatItem('Rojas',         '${player.redCards}',    Icons.square,         AppColors.danger),
    ];
  
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
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
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
          title: const Text('Editar Jugador', style: TextStyle(color: AppColors.textPrimary)),
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
              Row(
                children: positions.map((pos) {
                  final isSel = pos == selectedPos;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setDialogState(() => selectedPos = pos),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSel
                              ? (positionColors[pos] ?? AppColors.accent).withOpacity(0.2)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSel
                                ? (positionColors[pos] ?? AppColors.accent)
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          pos,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSel
                                ? (positionColors[pos] ?? AppColors.accent)
                                : AppColors.textSecondary,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
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
              child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
              onPressed: () {
                final name   = nameCtrl.text.trim();
                final number = int.tryParse(numberCtrl.text.trim()) ?? player.number;
                if (name.isEmpty) return;
                context.read<PlayersProvider>().updatePlayer(
                  player.copyWith(name: name, number: number, position: selectedPos),
                );
                Navigator.pop(context);
              },
              child: const Text('Guardar', style: TextStyle(color: Colors.black87)),
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

// ---- Medidor visual de forma ----

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
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Círculo con puntuación
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
          // Leyenda de la fórmula
          const Text(
            'Goles · Asistencias · Regates  −  Pérdidas · Tarjetas',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---- Gráfica de radar (perfil del jugador) ----

class _RadarChart extends StatelessWidget {
  final Player player;
  const _RadarChart({required this.player});

  @override
  Widget build(BuildContext context) {
    // Normalizamos cada métrica a 0-1 con topes razonables
    final matches = player.totalMatches == 0 ? 1 : player.totalMatches;
    final values = [
      (player.goals    / matches * 2).clamp(0.0, 1.0),   // Goles / partido (tope ~0.5)
      (player.assists  / matches * 2).clamp(0.0, 1.0),   // Asistencias
      (player.dribbles / matches / 5).clamp(0.0, 1.0),   // Regates (tope ~5/partido)
      1.0 - (player.ballLosses / matches / 8).clamp(0.0, 1.0), // Inv. pérdidas
      1.0 - (player.yellowCards / matches * 3).clamp(0.0, 1.0), // Inv. amarillas
    ];

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.polygon,
          tickCount: 4,
          ticksTextStyle: const TextStyle(fontSize: 0), // Ocultamos ticks
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          gridBorderData: const BorderSide(color: Colors.white12, width: 1),
          tickBorderData: const BorderSide(color: Colors.white10, width: 1),
          titleTextStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
          getTitle: (index, _) {
            const titles = ['Gol', 'Asist', 'Regate', 'Posesión', 'Disciplina'];
            return RadarChartTitle(text: titles[index]);
          },
          dataSets: [
            RadarDataSet(
              fillColor: AppColors.accent.withOpacity(0.2),
              borderColor: AppColors.accent,
              borderWidth: 2,
              entryRadius: 3,
              dataEntries: values.map((v) => RadarEntry(value: v)).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Gráfica de barras horizontal ----

class _BarChart extends StatelessWidget {
  final Player player;
  const _BarChart({required this.player});

  @override
  Widget build(BuildContext context) {
    final matches = player.totalMatches == 0 ? 1 : player.totalMatches;

    // Datos para la gráfica: ratio por partido
    final data = [
      _BarData('Goles',    player.goals    / matches, AppColors.accentWarm),
      _BarData('Asist',    player.assists  / matches, const Color(0xFF64B5F6)),
      _BarData('Regates',  player.dribbles / matches, AppColors.accent),
      _BarData('Pérdidas', player.ballLosses / matches, AppColors.danger),
      _BarData('Amarillas',player.yellowCards / matches, AppColors.yellow),
    ];

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

  Widget _buildBar(_BarData d, double maxVal) {
    // Evitamos división por cero
    final ratio = maxVal > 0 ? (d.value / maxVal).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              d.label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                // Fondo
                Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Barra coloreada
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