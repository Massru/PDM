import 'match_event.dart';

// Modelo de un partido completo.
// Contiene la alineación inicial, los eventos y el resultado.

class Match {
  final String id;
  final DateTime date;
  final String opponent;       // Rival
  final List<String> lineup;   // IDs de los 11 titulares
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

  // Cuenta eventos de cada tipo para un jugador en este partido
  // Ejemplo: {ballLoss: 2, dribble: 3, goal: 1}
  // Usa un mapa que se va actualizando conforme itera los eventos
  Map<EventType, int> statsForPlayer(String playerId) {
    final stats = <EventType, int>{}; // Mapa vacío: tipo -> contador
    for (final e in events) {
      if (e.playerId == playerId) {
        // stats[type] ?? 0 toma valor actual o 0 si no existe, luego suma 1
        stats[e.type] = (stats[e.type] ?? 0) + 1;
      }
    }
    return stats;
  }

  // Convierte el Match a un Map que puede ser serializado a JSON
  // toIso8601String() convierte DateTime a string formato internacional (2024-03-27T15:30:00.000Z)
  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(), // Convierte DateTime a string ISO
    'opponent': opponent,
    'lineup': lineup, // Lista de IDs de jugadores
    'events': events.map((e) => e.toJson()).toList(), // Serializa cada evento
    'goalsFor': goalsFor,
    'goalsAgainst': goalsAgainst,
    'isFinished': isFinished,
  };

  // Reconstruye un Match desde un Map JSON
  // DateTime.parse convierte string ISO a DateTime
  // Cada evento se deserializa recursivamente con MatchEvent.fromJson
  factory Match.fromJson(Map<String, dynamic> json) => Match(
    id: json['id'],
    date: DateTime.parse(json['date']),
    opponent: json['opponent'],
    lineup: List<String>.from(json['lineup']),
    events: (json['events'] as List)
        .map((e) => MatchEvent.fromJson(e))
        .toList(),
    goalsFor: json['goalsFor'] ?? 0,
    goalsAgainst: json['goalsAgainst'] ?? 0,
    isFinished: json['isFinished'] ?? false,
  );
}