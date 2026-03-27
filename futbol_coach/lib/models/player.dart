// Modelo principal de jugador.
// Contiene tanto sus datos fijos (nombre, dorsal) como
// las estadísticas acumuladas a lo largo de todos los partidos.

class Player {
  final String id;
  String name;
  int number; // Dorsal
  String position; // POR, DEF, MED, DEL
  String? photoUrl;

  // --- Estadísticas acumuladas (todos los partidos) ---
  int totalMatches;
  int ballLosses;      // Pérdidas de balón
  int dribbles;        // Regates exitosos
  int yellowCards;
  int redCards;
  int goals;
  int assists;
  int minutesPlayed;
  int crosses;      // Centro
  int recoveries;   // Recuperación
  int shots;        // Tiro

  Player({
    required this.id,
    required this.name,
    required this.number,
    required this.position,
    this.photoUrl,
    this.totalMatches = 0,
    this.ballLosses = 0,
    this.dribbles = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.goals = 0,
    this.assists = 0,
    this.minutesPlayed = 0,
    this.crosses = 0,
    this.recoveries = 0,
    this.shots = 0,
  });

  // Serialización para guardar en SharedPreferences
  // Serializa jugador para SharedPreferences (convierte a JSON)
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'number': number,
    'position': position,
    'photoUrl': photoUrl,
    'totalMatches': totalMatches,
    'ballLosses': ballLosses,
    'dribbles': dribbles,
    'yellowCards': yellowCards,
    'redCards': redCards,
    'goals': goals,
    'assists': assists,
    'minutesPlayed': minutesPlayed,
    'crosses': crosses,
    'recoveries': recoveries,
    'shots': shots,
  };

  // Deserializa jugador desde localStorage
  factory Player.fromJson(Map<String, dynamic> json) => Player(
    id: json['id'],
    name: json['name'],
    number: json['number'],
    position: json['position'],
    photoUrl: json['photoUrl'],
    totalMatches: json['totalMatches'] ?? 0,
    ballLosses: json['ballLosses'] ?? 0,
    dribbles: json['dribbles'] ?? 0,
    yellowCards: json['yellowCards'] ?? 0,
    redCards: json['redCards'] ?? 0,
    goals: json['goals'] ?? 0,
    assists: json['assists'] ?? 0,
    minutesPlayed: json['minutesPlayed'] ?? 0,
    crosses: json['crosses'] ?? 0,
    recoveries: json['recoveries'] ?? 0,
    shots: json['shots'] ?? 0,
  );

  // Copia con campos modificados (patrón inmutable)
  // Crea copia del jugador con campos opcionales actualizados
  // Usado al guardar cambios sin reemplazar el objeto entero
  Player copyWith({
    String? name,
    int? number,
    String? position,
    int? totalMatches,
    int? ballLosses,
    int? dribbles,
    int? yellowCards,
    int? redCards,
    int? goals,
    int? assists,
    int? minutesPlayed,
    int? crosses,
    int? recoveries,
    int? shots,
  }) => Player(
    id: id,
    name: name ?? this.name,
    number: number ?? this.number,
    position: position ?? this.position,
    photoUrl: photoUrl,
    totalMatches: totalMatches ?? this.totalMatches,
    ballLosses: ballLosses ?? this.ballLosses,
    dribbles: dribbles ?? this.dribbles,
    yellowCards: yellowCards ?? this.yellowCards,
    redCards: redCards ?? this.redCards,
    goals: goals ?? this.goals,
    assists: assists ?? this.assists,
    minutesPlayed: minutesPlayed ?? this.minutesPlayed,
    crosses: crosses ?? this.crosses,
    recoveries: recoveries ?? this.recoveries,
    shots: shots ?? this.shots,
  );
}