// Representa un evento ocurrido durante el partido:
// un regate, una pérdida de balón, una tarjeta, etc.
// Guardamos el historial completo para poder revertir o auditar.

enum EventType {
  ballLoss,     // Pérdida de balón
  dribble,      // Regate exitoso
  yellowCard,
  redCard,
  goal,
  assist,
  substitutionOut,  // Jugador sale
  substitutionIn,   // Jugador entra
  cross,        // Centro
  recovery,     // Recuperación
  shot,         // Tiro
}

class MatchEvent {
  final String id;
  final String playerId;
  final EventType type;
  final int minute;         // Minuto del partido
  final String? relatedPlayerId; // Para sustituciones: el otro jugador

  const MatchEvent({
    required this.id,
    required this.playerId,
    required this.type,
    required this.minute,
    this.relatedPlayerId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'playerId': playerId,
    'type': type.name,
    'minute': minute,
    'relatedPlayerId': relatedPlayerId,
  };

  factory MatchEvent.fromJson(Map<String, dynamic> json) => MatchEvent(
    id: json['id'],
    playerId: json['playerId'],
    type: EventType.values.byName(json['type']),
    minute: json['minute'],
    relatedPlayerId: json['relatedPlayerId'],
  );
}