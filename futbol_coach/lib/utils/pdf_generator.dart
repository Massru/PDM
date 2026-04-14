import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/player.dart';
import '../models/match.dart';
import '../models/match_event.dart';
import '../utils/form_calculator.dart';

// Clase estática que centraliza toda la generación y exportación de PDFs.
// Usa el paquete pdf para construir el documento y printing para
// mostrarlo al usuario con opciones de compartir, imprimir o guardar.
class PdfGenerator {

  // ---- Colores corporativos adaptados a PdfColor ----
  static const _bgColor       = PdfColor.fromInt(0xFF0A1628);
  static const _cardColor     = PdfColor.fromInt(0xFF1C2E50);
  static const _accent        = PdfColor.fromInt(0xFF00E676);
  static const _accentWarm    = PdfColor.fromInt(0xFFFFB300);
  static const _danger        = PdfColor.fromInt(0xFFE53935);
  static const _yellow        = PdfColor.fromInt(0xFFFFD600);
  static const _textPrimary   = PdfColor.fromInt(0xFFFFFFFF);
  static const _textSecondary = PdfColor.fromInt(0xFF8BA0C4);
  static const _cyan          = PdfColor.fromInt(0xFF80DEEA);

  // Color de fondo para barras — sustituye a PdfColors.white10
  // que no existe en el paquete pdf. Usamos azul oscuro como alternativa.
  static const _barBg = PdfColor.fromInt(0xFF132040);

  static const _posColors = {
    'POR': PdfColor.fromInt(0xFFFFB300),
    'DEF': PdfColor.fromInt(0xFF1565C0),
    'MED': PdfColor.fromInt(0xFF2E7D32),
    'DEL': PdfColor.fromInt(0xFFB71C1C),
  };

  // -------------------------------------------------------
  // EXPORTAR PERFIL DE JUGADOR
  // -------------------------------------------------------

  /// Genera y muestra el PDF del perfil completo de un jugador
  static Future<void> exportPlayerProfile(Player player) async {
    final doc      = pw.Document();
    final form     = FormCalculator.calculate(player);
    final isKeeper = player.position == 'POR';
    final posColor = _posColors[player.position] ?? _accent;
    final matches  = player.totalMatches == 0 ? 1 : player.totalMatches;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: await PdfGoogleFonts.robotoRegular(),
          bold: await PdfGoogleFonts.robotoBold(),
        ),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Cabecera con dorsal, nombre, posición y partidos
            _buildPlayerHeader(player, form, posColor),
            pw.SizedBox(height: 20),

            // Barra visual del estado de forma
            _buildFormBar(form),
            pw.SizedBox(height: 20),

            // Grid de estadísticas acumuladas
            pw.Text(
              'ESTADISTICAS ACUMULADAS',
              style: pw.TextStyle(
                color: _textSecondary,
                fontSize: 9,
                letterSpacing: 1.5,
              ),
            ),
            pw.SizedBox(height: 8),
            isKeeper
                ? _buildKeeperStatsGrid(player)
                : _buildPlayerStatsGrid(player),
            pw.SizedBox(height: 20),

            // Tabla de medias por partido
            pw.Text(
              'MEDIAS POR PARTIDO',
              style: pw.TextStyle(
                color: _textSecondary,
                fontSize: 9,
                letterSpacing: 1.5,
              ),
            ),
            pw.SizedBox(height: 8),
            isKeeper
                ? _buildKeeperAveragesTable(player, matches)
                : _buildPlayerAveragesTable(player, matches),

            pw.Spacer(),

            // Pie de página
            _buildFooter('Perfil generado con Football Coach App'),
          ],
        ),
      ),
    );

    // Abre el visor nativo del dispositivo con opciones de compartir/guardar/imprimir
    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: 'Perfil_${player.name.replaceAll(' ', '_')}.pdf',
    );
  }

  // -------------------------------------------------------
  // EXPORTAR RESUMEN DE PARTIDO
  // -------------------------------------------------------

  /// Genera y muestra el PDF del resumen de un partido
  static Future<void> exportMatchReport(
    Match match,
    List<Player> allPlayers,
  ) async {
    final doc     = pw.Document();
    final date    = match.date;
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final won  = match.goalsFor > match.goalsAgainst;
    final draw = match.goalsFor == match.goalsAgainst;
    final resultColor = won ? _accent : draw ? _accentWarm : _danger;

    // Participantes: titulares + sustitutos que entraron
    final participantIds = <String>{
      ...match.lineup,
      ...match.events
          .where((e) => e.type == EventType.substitutionIn)
          .map((e) => e.playerId),
    };
    final participants = participantIds
        .map((id) => allPlayers.firstWhere(
              (p) => p.id == id,
              orElse: () => Player(
                  id: id,
                  name: 'Desconocido',
                  number: 0,
                  position: ''),
            ))
        .toList()
      ..sort((a, b) => a.number.compareTo(b.number));

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: await PdfGoogleFonts.robotoRegular(),
          bold: await PdfGoogleFonts.robotoBold(),
        ),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Cabecera con rival, fecha y resultado
            _buildMatchHeader(match, dateStr, resultColor),
            pw.SizedBox(height: 16),

            // Resumen rápido de eventos totales del partido
            _buildMatchEventsSummary(match),
            pw.SizedBox(height: 16),

            // Tabla de estadísticas individuales por jugador
            pw.Text(
              'ESTADISTICAS POR JUGADOR',
              style: pw.TextStyle(
                color: _textSecondary,
                fontSize: 9,
                letterSpacing: 1.5,
              ),
            ),
            pw.SizedBox(height: 8),
            _buildMatchPlayersTable(match, participants),

            pw.Spacer(),

            // Pie de página
            _buildFooter(
                'Informe generado con Football Coach App · $dateStr'),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: 'Partido_vs_${match.opponent.replaceAll(' ', '_')}_$dateStr.pdf',
    );
  }

  // -------------------------------------------------------
  // EXPORTAR RANKING DE PLANTILLA
  // -------------------------------------------------------

  /// Genera y muestra el PDF con el ranking de forma de toda la plantilla
  static Future<void> exportSquadRanking(List<Player> players) async {
    final doc = pw.Document();

    // Ordenamos por estado de forma descendente
    final sorted = [...players]..sort((a, b) =>
        FormCalculator.calculate(b)
            .compareTo(FormCalculator.calculate(a)));

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: await PdfGoogleFonts.robotoRegular(),
          bold: await PdfGoogleFonts.robotoBold(),
        ),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Título y subtítulo del ranking
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: _bgColor,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'RANKING DE FORMA',
                    style: pw.TextStyle(
                      color: _accent,
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '${players.length} jugadores ordenados por estado de forma',
                    style: pw.TextStyle(
                        color: _textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Tabla de ranking completa
            _buildSquadTable(sorted),

            pw.Spacer(),
            _buildFooter('Ranking generado con Football Coach App'),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: 'Ranking_Plantilla.pdf',
    );
  }

  // -------------------------------------------------------
  // WIDGETS INTERNOS - JUGADOR
  // -------------------------------------------------------

  static pw.Widget _buildPlayerHeader(
      Player player, double form, PdfColor posColor) {
    final formColor = _pdfFormColor(form);
    final formLabel = FormCalculator.label(form);

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _bgColor,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          // Dorsal en círculo con color de posición
          pw.Container(
            width: 70, height: 70,
            decoration: pw.BoxDecoration(
              color: posColor,
              shape: pw.BoxShape.circle,
            ),
            child: pw.Center(
              child: pw.Text(
                '${player.number}',
                style: pw.TextStyle(
                  color: _textPrimary,
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  player.name,
                  style: pw.TextStyle(
                    color: _textPrimary,
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    // Chip de posición
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: pw.BoxDecoration(
                        color: posColor,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        player.position,
                        style: pw.TextStyle(
                          color: _textPrimary,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      '${player.totalMatches} partidos jugados',
                      style: pw.TextStyle(
                          color: _textSecondary, fontSize: 11),
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
                // Estado de forma en texto
                pw.Text(
                  'Forma: $formLabel (${form.toStringAsFixed(0)}/100)',
                  style: pw.TextStyle(
                    color: formColor,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Barra visual del estado de forma con LayoutBuilder para calcular
  // el ancho real disponible. pw.FractionallySizedBox no existe en el
  // paquete pdf así que calculamos el ancho manualmente con maxWidth.
  static pw.Widget _buildFormBar(double form) {
    final color = _pdfFormColor(form);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'ESTADO DE FORMA',
          style: pw.TextStyle(
              color: _textSecondary, fontSize: 9, letterSpacing: 1.5),
        ),
        pw.SizedBox(height: 6),
        pw.LayoutBuilder(
          builder: (ctx, constraints) {
            // maxWidth en lugar de availableWidth que no existe en pw
            final totalWidth = constraints?.maxWidth ?? 400;
            final fillWidth  = totalWidth * (form / 100);
            return pw.Stack(
              children: [
                // Fondo de la barra
                pw.Container(
                  width: totalWidth,
                  height: 12,
                  decoration: pw.BoxDecoration(
                    color: _barBg,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                ),
                // Relleno proporcional a la puntuación de forma
                pw.Container(
                  width: fillWidth,
                  height: 12,
                  decoration: pw.BoxDecoration(
                    color: color,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // Grid 3x3 para jugadores de campo (sin paradas)
  static pw.Widget _buildPlayerStatsGrid(Player player) {
    final stats = [
      _StatData('Goles',          '${player.goals}',       _accentWarm),
      _StatData('Asistencias',    '${player.assists}',     PdfColor.fromInt(0xFF64B5F6)),
      _StatData('Regates',        '${player.dribbles}',    _accent),
      _StatData('Tiros',          '${player.shots}',       PdfColor.fromInt(0xFFFF8A65)),
      _StatData('Centros',        '${player.crosses}',     PdfColor.fromInt(0xFFCE93D8)),
      _StatData('Recuperaciones', '${player.recoveries}',  PdfColor.fromInt(0xFF80CBC4)),
      _StatData('Perdidas',       '${player.ballLosses}',  _danger),
      _StatData('Amarillas',      '${player.yellowCards}', _yellow),
      _StatData('Rojas',          '${player.redCards}',    _danger),
    ];
    return _statsGrid(stats);
  }

  // Grid para porteros con paradas como estadística principal
  static pw.Widget _buildKeeperStatsGrid(Player player) {
    final stats = [
      _StatData('Paradas',        '${player.saves}',       _cyan),
      _StatData('Recuperaciones', '${player.recoveries}',  PdfColor.fromInt(0xFF80CBC4)),
      _StatData('Perdidas',       '${player.ballLosses}',  _danger),
      _StatData('Regates',        '${player.dribbles}',    _accent),
      _StatData('Asistencias',    '${player.assists}',     PdfColor.fromInt(0xFF64B5F6)),
      _StatData('Goles',          '${player.goals}',       _accentWarm),
      _StatData('Amarillas',      '${player.yellowCards}', _yellow),
      _StatData('Rojas',          '${player.redCards}',    _danger),
    ];
    return _statsGrid(stats);
  }

  // Grid reutilizable: divide los items en filas de 3
  static pw.Widget _statsGrid(List<_StatData> stats) {
    final rows = <pw.Widget>[];
    for (int i = 0; i < stats.length; i += 3) {
      final rowItems =
          stats.sublist(i, (i + 3).clamp(0, stats.length));
      rows.add(
        pw.Row(
          children: rowItems
              .map((s) => pw.Expanded(
                    child: pw.Container(
                      margin: const pw.EdgeInsets.all(3),
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: _cardColor,
                        borderRadius: pw.BorderRadius.circular(8),
                        border: pw.Border.all(
                            color: s.color, width: 0.5),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            s.value,
                            style: pw.TextStyle(
                              color: s.color,
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            s.label,
                            style: pw.TextStyle(
                                color: _textSecondary, fontSize: 9),
                            textAlign: pw.TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        ),
      );
      if (i + 3 < stats.length) rows.add(pw.SizedBox(height: 4));
    }
    return pw.Column(children: rows);
  }

  // Tabla de medias por partido para jugadores de campo
  static pw.Widget _buildPlayerAveragesTable(
      Player player, int matches) {
    final rows = [
      _AvgData('Goles',          player.goals       / matches, _accentWarm),
      _AvgData('Asistencias',    player.assists     / matches, PdfColor.fromInt(0xFF64B5F6)),
      _AvgData('Regates',        player.dribbles    / matches, _accent),
      _AvgData('Tiros',          player.shots       / matches, PdfColor.fromInt(0xFFFF8A65)),
      _AvgData('Centros',        player.crosses     / matches, PdfColor.fromInt(0xFFCE93D8)),
      _AvgData('Recuperaciones', player.recoveries  / matches, PdfColor.fromInt(0xFF80CBC4)),
      _AvgData('Perdidas',       player.ballLosses  / matches, _danger),
      _AvgData('Tarjetas Am.',   player.yellowCards / matches, _yellow),
    ];
    return _averagesTable(rows);
  }

  // Tabla de medias por partido para porteros
  static pw.Widget _buildKeeperAveragesTable(
      Player player, int matches) {
    final rows = [
      _AvgData('Paradas',        player.saves       / matches, _cyan),
      _AvgData('Recuperaciones', player.recoveries  / matches, PdfColor.fromInt(0xFF80CBC4)),
      _AvgData('Perdidas',       player.ballLosses  / matches, _danger),
      _AvgData('Asistencias',    player.assists     / matches, PdfColor.fromInt(0xFF64B5F6)),
      _AvgData('Tarjetas Am.',   player.yellowCards / matches, _yellow),
    ];
    return _averagesTable(rows);
  }

  // Tabla de barras horizontales reutilizable.
  // Usa LayoutBuilder con maxWidth ya que pw.FractionallySizedBox
  // no existe en el paquete pdf.
  static pw.Widget _averagesTable(List<_AvgData> rows) {
    final maxVal =
        rows.map((r) => r.value).reduce((a, b) => a > b ? a : b);

    return pw.LayoutBuilder(
      builder: (ctx, constraints) {
        // maxWidth en lugar de availableWidth que no existe en pw
        final totalWidth = constraints?.maxWidth ?? 400;
        // Descontamos etiqueta (90) y valor numérico (44)
        final barWidth = totalWidth - 90 - 44;

        return pw.Column(
          children: rows.map((r) {
            // Ancho de relleno proporcional al valor máximo
            final fillWidth = maxVal > 0
                ? (barWidth * (r.value / maxVal)).clamp(0.0, barWidth)
                : 0.0;

            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 3),
              child: pw.Row(
                children: [
                  // Etiqueta de la métrica
                  pw.SizedBox(
                    width: 90,
                    child: pw.Text(r.label,
                        style: pw.TextStyle(
                            color: _textSecondary, fontSize: 10)),
                  ),
                  // Barra con fondo y relleno
                  pw.Stack(
                    children: [
                      pw.Container(
                        width: barWidth,
                        height: 14,
                        decoration: pw.BoxDecoration(
                          color: _barBg,
                          borderRadius: pw.BorderRadius.circular(3),
                        ),
                      ),
                      pw.Container(
                        width: fillWidth,
                        height: 14,
                        decoration: pw.BoxDecoration(
                          color: r.color,
                          borderRadius: pw.BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(width: 8),
                  // Valor numérico a la derecha
                  pw.SizedBox(
                    width: 36,
                    child: pw.Text(
                      r.value.toStringAsFixed(2),
                      style: pw.TextStyle(
                        color: r.color,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // -------------------------------------------------------
  // WIDGETS INTERNOS - PARTIDO
  // -------------------------------------------------------

  // Cabecera del partido con rival, fecha, etiqueta y resultado grande
  static pw.Widget _buildMatchHeader(
      Match match, String dateStr, PdfColor resultColor) {
    final result = '${match.goalsFor} - ${match.goalsAgainst}';
    final won    = match.goalsFor > match.goalsAgainst;
    final draw   = match.goalsFor == match.goalsAgainst;
    final label  = won ? 'VICTORIA' : draw ? 'EMPATE' : 'DERROTA';

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _bgColor,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: resultColor, width: 1),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'vs ${match.opponent}',
                  style: pw.TextStyle(
                    color: _textPrimary,
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  dateStr,
                  style: pw.TextStyle(
                      color: _textSecondary, fontSize: 11),
                ),
                pw.SizedBox(height: 4),
                // Chip de resultado: VICTORIA / EMPATE / DERROTA
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: pw.BoxDecoration(
                    color: resultColor,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    label,
                    style: pw.TextStyle(
                      color: _textPrimary,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Resultado grande a la derecha
          pw.Text(
            result,
            style: pw.TextStyle(
              color: resultColor,
              fontSize: 36,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Resumen rápido de eventos totales del partido en cajas.
  // Sin emoticonos — usamos texto plano para compatibilidad con PDF.
  static pw.Widget _buildMatchEventsSummary(Match match) {
    final goals   = match.events.where((e) => e.type == EventType.goal).length;
    final assists = match.events.where((e) => e.type == EventType.assist).length;
    final yellows = match.events.where((e) => e.type == EventType.yellowCard).length;
    final reds    = match.events.where((e) => e.type == EventType.redCard).length;
    final subs    = match.events.where((e) => e.type == EventType.substitutionOut).length;
    final shots   = match.events.where((e) => e.type == EventType.shot).length;
    final saves   = match.events.where((e) => e.type == EventType.save).length;

    // Texto plano en lugar de emoticonos para evitar caracteres no renderizados
    final items = [
      _StatData('Goles',     '$goals',   _accentWarm),
      _StatData('Asist',     '$assists', PdfColor.fromInt(0xFF64B5F6)),
      _StatData('Tiros',     '$shots',   PdfColor.fromInt(0xFFFF8A65)),
      _StatData('Paradas',   '$saves',   _cyan),
      _StatData('Amarillas', '$yellows', _yellow),
      _StatData('Rojas',     '$reds',    _danger),
      _StatData('Sust.',     '$subs',    _textSecondary),
    ];

    return pw.Row(
      children: items
          .map((s) => pw.Expanded(
                child: pw.Container(
                  margin: const pw.EdgeInsets.symmetric(horizontal: 2),
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: _cardColor,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        s.value,
                        style: pw.TextStyle(
                          color: s.color,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        s.label,
                        style: pw.TextStyle(
                            color: _textSecondary, fontSize: 8),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  // Tabla de estadísticas individuales por jugador en el partido.
  // Cabeceras en texto plano sin emoticonos.
  static pw.Widget _buildMatchPlayersTable(
      Match match, List<Player> participants) {
    // Cabeceras en texto plano para compatibilidad PDF
    final headers = [
      'N', 'Jugador', 'Pos', 'Gol', 'Ast',
      'Reg', 'Tiro', 'Par', 'Perd', 'Amar', 'Roja'
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: _cardColor, width: 0.5),
      columnWidths: {
        0:  const pw.FixedColumnWidth(20),
        // Columna de nombre más ancha para que quepan los nombres completos
        1:  const pw.FlexColumnWidth(4),
        2:  const pw.FixedColumnWidth(24),
        3:  const pw.FixedColumnWidth(24),
        4:  const pw.FixedColumnWidth(24),
        5:  const pw.FixedColumnWidth(24),
        6:  const pw.FixedColumnWidth(24),
        7:  const pw.FixedColumnWidth(24),
        8:  const pw.FixedColumnWidth(28),
        9:  const pw.FixedColumnWidth(28),
        10: const pw.FixedColumnWidth(24),
      },
      children: [
        // Fila de cabeceras
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _cardColor),
          children: headers
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      h,
                      style: pw.TextStyle(
                        color: _textSecondary,
                        fontSize: 7,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ))
              .toList(),
        ),
        // Fila por cada jugador participante
        ...participants.map((player) {
          final stats    = match.statsForPlayer(player.id);
          final isSub    = !match.lineup.contains(player.id);
          final posColor =
              _posColors[player.position] ?? _textSecondary;

          return pw.TableRow(
            children: [
              // Dorsal
              _tableCell('${player.number}', posColor),
              // Nombre completo del jugador (no solo apellido)
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      player.name,
                      style: pw.TextStyle(
                        color: isSub ? _textSecondary : _textPrimary,
                        fontSize: 8,
                      ),
                    ),
                    // Etiqueta SUB debajo del nombre si es sustituto
                    if (isSub)
                      pw.Text(
                        'SUB',
                        style: pw.TextStyle(
                          color: _accentWarm,
                          fontSize: 6,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              _tableCell(player.position, posColor),
              _tableCell('${stats[EventType.goal]       ?? 0}', _accentWarm),
              _tableCell('${stats[EventType.assist]     ?? 0}', PdfColor.fromInt(0xFF64B5F6)),
              _tableCell('${stats[EventType.dribble]    ?? 0}', _accent),
              _tableCell('${stats[EventType.shot]       ?? 0}', PdfColor.fromInt(0xFFFF8A65)),
              _tableCell('${stats[EventType.save]       ?? 0}', _cyan),
              _tableCell('${stats[EventType.ballLoss]   ?? 0}', _danger),
              _tableCell('${stats[EventType.yellowCard] ?? 0}', _yellow),
              _tableCell('${stats[EventType.redCard]    ?? 0}', _danger),
            ],
          );
        }),
      ],
    );
  }

  // -------------------------------------------------------
  // WIDGETS INTERNOS - PLANTILLA
  // -------------------------------------------------------

  // Tabla de ranking completa con todos los jugadores ordenados por forma.
  // Cabeceras en texto plano sin emoticonos.
  static pw.Widget _buildSquadTable(List<Player> players) {
    // Cabeceras en texto plano para compatibilidad PDF
    final headers = [
      'Pos', 'N', 'Jugador', 'Forma', 'PJ',
      'Gol', 'Ast', 'Par', 'Perd', 'Amar'
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: _cardColor, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(28),
        1: const pw.FixedColumnWidth(20),
        // Columna de nombre más ancha para que quepan los nombres completos
        2: const pw.FlexColumnWidth(4),
        3: const pw.FixedColumnWidth(52),
        4: const pw.FixedColumnWidth(20),
        5: const pw.FixedColumnWidth(22),
        6: const pw.FixedColumnWidth(22),
        7: const pw.FixedColumnWidth(22),
        8: const pw.FixedColumnWidth(26),
        9: const pw.FixedColumnWidth(26),
      },
      children: [
        // Cabecera de la tabla
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _cardColor),
          children: headers
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      h,
                      style: pw.TextStyle(
                        color: _textSecondary,
                        fontSize: 7,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ))
              .toList(),
        ),
        // Fila por jugador ordenado por forma
        ...players.asMap().entries.map((entry) {
          final i         = entry.key;
          final player    = entry.value;
          final form      = FormCalculator.calculate(player);
          final formColor = _pdfFormColor(form);
          final posColor  =
              _posColors[player.position] ?? _textSecondary;

          return pw.TableRow(
            // Alternamos color de fila para facilitar la lectura
            decoration: pw.BoxDecoration(
              color: i.isEven ? _bgColor : _cardColor,
            ),
            children: [
              _tableCell(player.position, posColor),
              _tableCell('${player.number}', posColor),
              // Nombre completo del jugador
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(
                  player.name,
                  style: pw.TextStyle(
                      color: _textPrimary, fontSize: 8),
                ),
              ),
              // Forma: puntuación + etiqueta
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(
                        text: '${form.toStringAsFixed(0)} ',
                        style: pw.TextStyle(
                          color: formColor,
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.TextSpan(
                        text: FormCalculator.label(form),
                        style: pw.TextStyle(
                            color: formColor, fontSize: 7),
                      ),
                    ],
                  ),
                ),
              ),
              _tableCell('${player.totalMatches}', _textSecondary),
              _tableCell('${player.goals}',        _accentWarm),
              _tableCell('${player.assists}',      PdfColor.fromInt(0xFF64B5F6)),
              // Paradas: relevante para porteros, muestra 0 para el resto
              _tableCell('${player.saves}',        _cyan),
              _tableCell('${player.ballLosses}',   _danger),
              _tableCell('${player.yellowCards}',  _yellow),
            ],
          );
        }),
      ],
    );
  }

  // -------------------------------------------------------
  // HELPERS
  // -------------------------------------------------------

  // Celda de tabla con texto centrado y color
  static pw.Widget _tableCell(String text, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(color: color, fontSize: 8),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // Pie de página con línea separadora superior
  static pw.Widget _buildFooter(String text) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: _cardColor, width: 0.5),
        ),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(color: _textSecondary, fontSize: 8),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // Convierte la puntuación de forma a PdfColor equivalente
  // a los colores usados en la app Flutter
  static PdfColor _pdfFormColor(double score) {
    if (score >= 80) return PdfColor.fromInt(0xFF00E676);
    if (score >= 65) return PdfColor.fromInt(0xFF69F0AE);
    if (score >= 50) return PdfColor.fromInt(0xFFFFB300);
    if (score >= 35) return PdfColor.fromInt(0xFFFF7043);
    return PdfColor.fromInt(0xFFE53935);
  }
}

// ---- Clases de datos auxiliares internas ----

class _StatData {
  final String label;
  final String value;
  final PdfColor color;
  const _StatData(this.label, this.value, this.color);
}

class _AvgData {
  final String label;
  final double value;
  final PdfColor color;
  const _AvgData(this.label, this.value, this.color);
}