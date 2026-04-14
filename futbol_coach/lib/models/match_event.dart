// Tipos de evento que se pueden registrar durante un partido
enum EventType {
  ballLoss,        // Pérdida de balón
  dribble,         // Regate exitoso
  yellowCard,      // Tarjeta amarilla
  redCard,         // Tarjeta roja
  goal,            // Gol
  assist,          // Asistencia
  substitutionOut, // Jugador que sale del campo
  substitutionIn,  // Jugador que entra al campo
  cross,           // Centro al área
  recovery,        // Recuperación de balón
  shot,            // Tiro a puerta
  save,            // Parada (solo porteros)
}

// Representa un evento puntual ocurrido durante el partido.
// Guardamos el historial completo para poder auditar o revertir.
class MatchEvent {
  final String id;
  final String playerId;           // Jugador protagonista del evento
  final EventType type;
  final int minute;                // Minuto del partido en que ocurrió
  final String? relatedPlayerId;   // Para sustituciones: el otro jugador implicado

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