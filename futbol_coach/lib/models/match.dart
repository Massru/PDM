import 'match_event.dart';

// Modelo de un partido completo.
// Contiene la alineación inicial, el historial de eventos y el resultado final.
class Match {
  final String id;
  final DateTime date;
  final String opponent;       // Nombre del equipo rival
  final List<String> lineup;   // IDs de los jugadores en campo (se actualiza con sustituciones)
  final List<MatchEvent> events;
  int goalsFor;
  int goalsAgainst;
  bool isFinished;

  Match({
    required this.id,
    required this.date,
    required this.opponent,
    required this.lineup,
    List<MatchEvent>? events,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
    this.isFinished = false,
  }) : events = events ?? [];

  // Devuelve un mapa con el recuento de cada tipo de evento
  // para un jugador específico en este partido
  Map<EventType, int> statsForPlayer(String playerId) {
    final stats = <EventType, int>{};
    for (final e in events) {
      if (e.playerId == playerId) {
        stats[e.type] = (stats[e.type] ?? 0) + 1;
      }
    }
    return stats;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'opponent': opponent,
    'lineup': lineup,
    'events': events.map((e) => e.toJson()).toList(),
    'goalsFor': goalsFor,
    'goalsAgainst': goalsAgainst,
    'isFinished': isFinished,
  };

  factory Match.fromJson(Map<String, dynamic> json) => Match(
    id: json['id'],
    date: DateTime.parse(json['date']),
    opponent: json['opponent'],
    lineup: List<String>.from(json['lineup']),
    events: (json['events'] as List)
        .map((e) => MatchEvent.fromJson(e))
        .toList(),
    goalsFor:     json['goalsFor']     ?? 0,
    goalsAgainst: json['goalsAgainst'] ?? 0,
    isFinished:   json['isFinished']   ?? false,
  );
}