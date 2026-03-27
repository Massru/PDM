import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/player.dart';

// Provider que gestiona la lista completa de jugadores.
// Se encarga de la persistencia (guardar/cargar de SharedPreferences).

class PlayersProvider extends ChangeNotifier {
  List<Player> _players = [];
  static const _storageKey = 'players_data';
  final _uuid = const Uuid();

  List<Player> get players => List.unmodifiable(_players);

  // Jugadores ordenados por estado de forma (para la pantalla de alineación)
  List<Player> get playersByForm {
    final sorted = [..._players];
    sorted.sort((a, b) {
      // Se ordena por goles como proxy simple de forma
      // En LineupScreen se calcula la forma completa con FormCalculator
      return b.goals.compareTo(a.goals);
    });
    return sorted;
  }

  PlayersProvider() {
    // Carga los jugadores guardados al iniciar
    // Si no hay datos guardados, se crean los jugadores de ejemplo
    _loadFromStorage();
  }

  // --- CRUD de jugadores ---

  // Crea un nuevo jugador y lo añade a la lista
  // Genera un ID único con uuid y guarda los cambios en almacenamiento
  void addPlayer(String name, int number, String position) {
    _players.add(Player(
      id: _uuid.v4(),
      name: name,
      number: number,
      position: position,
    ));
    _saveToStorage(); // Persiste inmediatamente
    notifyListeners(); // Notifica a la UI para actualizar
  }

  // Reemplaza un jugador existente con sus datos actualizados
  // Busca por ID y lo reemplaza en la lista
  void updatePlayer(Player updated) {
    final idx = _players.indexWhere((p) => p.id == updated.id);
    if (idx != -1) { // Si se encontró el jugador
      _players[idx] = updated;
      _saveToStorage();
      notifyListeners();
    }
  }

  // Elimina un jugador por su ID
  // removeWhere elimina todos los que cumplan la condición
  void removePlayer(String id) {
    _players.removeWhere((p) => p.id == id);
    _saveToStorage();
    notifyListeners();
  }

  // Busca un jugador por su ID en toda la lista
  // Retorna null si no lo encuentra (en lugar de lanzar excepción)
  Player? getById(String id) {
    try {
      // firstWhere lanza excepción si no encuentra
      return _players.firstWhere((p) => p.id == id);
    } catch (_) {
      // Captura la excepción y retorna null
      return null;
    }
  }

  // Actualiza las estadísticas acumuladas de un jugador después del partido
  // Se llama para cada jugador que jugó en el partido
  // Suma los valores del partido a los acumulados usando copyWith
  void applyMatchStats({
    required String playerId,
    required int ballLosses,
    required int dribbles,
    required int yellowCards,
    required int redCards,
    required int goals,
    required int assists,
    required int minutesPlayed,
    required int crosses,
    required int recoveries,
    required int shots,
  }) {
    final idx = _players.indexWhere((p) => p.id == playerId);
    if (idx == -1) return; // Jugador no encontrado

    final p = _players[idx];
    // copyWith crea una copia con los campos nuevos actualizados
    _players[idx] = p.copyWith(
      totalMatches: p.totalMatches + 1, // Incrementa contador de partidos
      ballLosses:   p.ballLosses + ballLosses,
      dribbles:     p.dribbles + dribbles,
      yellowCards:  p.yellowCards + yellowCards,
      redCards:     p.redCards + redCards,
      goals:        p.goals + goals,
      assists:      p.assists + assists,
      minutesPlayed: p.minutesPlayed + minutesPlayed,
      crosses:       p.crosses + crosses,
      recoveries:    p.recoveries + recoveries,
      shots:         p.shots + shots,
    );

    _saveToStorage();
    notifyListeners();
  }

  // Guarda la lista actual de jugadores en SharedPreferences
  // Convierte cada Player a JSON, luego todo a string JSON
  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    // Mapea cada Player a su representación JSON
    final jsonList = _players.map((p) => p.toJson()).toList();
    // Codifica la lista a JSON string y la guarda
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  // Recupera los jugadores del almacenamiento
  // Si no hay nada guardado, crea los jugadores de ejemplo
  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey); // Obtiene el JSON guardado
    if (raw != null) {
      // Si hay datos guardados, los decodifica y reconvierte a objetos Player
      final list = jsonDecode(raw) as List;
      _players = list.map((e) => Player.fromJson(e)).toList();
      notifyListeners();
    } else {
      // Si es la primera vez, crea jugadores por defecto
      _seedPlayers();
    }
  }

  // Crea los jugadores de ejemplo (plantilla del Barcelona)
  // Se llama solo la primera vez que se usa la app
  // Incluye titulares y suplentes en sus posiciones
  void _seedPlayers() {
  _players = [
    // ---- TITULARES ----
    Player(id: _uuid.v4(), name: 'Joan García',          number: 13, position: 'POR'),
    Player(id: _uuid.v4(), name: 'Jules Koundé',         number: 23, position: 'DEF'),
    Player(id: _uuid.v4(), name: 'Pau Cubarsí',          number: 5, position: 'DEF'),
    Player(id: _uuid.v4(), name: 'Eric García',          number: 24, position: 'DEF'),
    Player(id: _uuid.v4(), name: 'Alejandro Balde',      number: 3,  position: 'DEF'),
    Player(id: _uuid.v4(), name: 'Frenkie de Jong',      number: 21, position: 'MED'),
    Player(id: _uuid.v4(), name: 'Pedri',                number: 8,  position: 'MED'),
    Player(id: _uuid.v4(), name: 'Fermín López',         number: 16, position: 'MED'),
    Player(id: _uuid.v4(), name: 'Raphinha',             number: 11, position: 'DEL'),
    Player(id: _uuid.v4(), name: 'Ferran Torres',        number: 7,  position: 'DEL'),
    Player(id: _uuid.v4(), name: 'Lamine Yamal',         number: 10, position: 'DEL'),

    // ---- SUPLENTES ----
    Player(id: _uuid.v4(), name: 'Wojciech Szczęsny',   number: 25,  position: 'POR'),
    Player(id: _uuid.v4(), name: 'João Cancelo',         number: 2,  position: 'DEF'),
    Player(id: _uuid.v4(), name: 'Ronald Araújo',        number: 4,  position: 'DEF'),
    Player(id: _uuid.v4(), name: 'Gavi',                 number: 6,  position: 'MED'),
    Player(id: _uuid.v4(), name: 'Dani Olmo',            number: 20, position: 'MED'),
    Player(id: _uuid.v4(), name: 'Robert Lewandowski',   number: 9,  position: 'DEL'),
    Player(id: _uuid.v4(), name: 'Marcus Rashford',      number: 14, position: 'DEL'),
  ];
  _saveToStorage();
  notifyListeners();
}
}