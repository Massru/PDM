import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/player.dart';

// Provider que gestiona la lista completa de jugadores.
// Se encarga de toda la persistencia en SharedPreferences.
class PlayersProvider extends ChangeNotifier {
  List<Player> _players = [];
  static const _storageKey = 'players_data';
  final _uuid = const Uuid();

  // Lista inmutable para evitar modificaciones externas accidentales
  List<Player> get players => List.unmodifiable(_players);

  PlayersProvider() {
    _loadFromStorage();
  }

  // --- CRUD de jugadores ---

  void addPlayer(String name, int number, String position) {
    _players.add(Player(
      id: _uuid.v4(),
      name: name,
      number: number,
      position: position,
    ));
    _saveToStorage();
    notifyListeners();
  }

  void updatePlayer(Player updated) {
    final idx = _players.indexWhere((p) => p.id == updated.id);
    if (idx != -1) {
      _players[idx] = updated;
      _saveToStorage();
      notifyListeners();
    }
  }

  void removePlayer(String id) {
    _players.removeWhere((p) => p.id == id);
    _saveToStorage();
    notifyListeners();
  }

  // Busca un jugador por su ID. Devuelve null si no existe.
  Player? getById(String id) {
    try {
      return _players.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // Aplica las estadísticas de un partido finalizado al jugador.
  // Se llama desde match_screen al finalizar el partido.
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
    required int saves,
  }) {
    final idx = _players.indexWhere((p) => p.id == playerId);
    if (idx == -1) return;

    final p = _players[idx];
    // Creamos una copia con los valores incrementados (patrón inmutable)
    _players[idx] = p.copyWith(
      totalMatches:  p.totalMatches  + 1,
      ballLosses:    p.ballLosses    + ballLosses,
      dribbles:      p.dribbles      + dribbles,
      yellowCards:   p.yellowCards   + yellowCards,
      redCards:      p.redCards      + redCards,
      goals:         p.goals         + goals,
      assists:       p.assists       + assists,
      minutesPlayed: p.minutesPlayed + minutesPlayed,
      crosses:       p.crosses       + crosses,
      recoveries:    p.recoveries    + recoveries,
      shots:         p.shots         + shots,
      saves:         p.saves         + saves,
    );

    _saveToStorage();
    notifyListeners();
  }

  // --- Persistencia ---

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _players.map((p) => p.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      // Datos existentes: cargamos del almacenamiento
      final list = jsonDecode(raw) as List;
      _players = list.map((e) => Player.fromJson(e)).toList();
      notifyListeners();
    } else {
      // Primera vez que arranca la app: cargamos la plantilla del Barça
      _seedPlayers();
    }
  }

  // Plantilla inicial de ejemplo (FC Barcelona).
  // Solo se ejecuta la primera vez, cuando no hay datos guardados.
  void _seedPlayers() {
    _players = [
      // ---- TITULARES ----
      Player(id: _uuid.v4(), name: 'Joan García',         number: 13, position: 'POR'),
      Player(id: _uuid.v4(), name: 'Jules Koundé',        number: 23, position: 'DEF'),
      Player(id: _uuid.v4(), name: 'Pau Cubarsí',         number: 5, position: 'DEF'),
      Player(id: _uuid.v4(), name: 'Eric García',         number: 24, position: 'DEF'),
      Player(id: _uuid.v4(), name: 'Alejandro Balde',     number: 3,  position: 'DEF'),
      Player(id: _uuid.v4(), name: 'Frenkie de Jong',     number: 21, position: 'MED'),
      Player(id: _uuid.v4(), name: 'Pedri',               number: 8,  position: 'MED'),
      Player(id: _uuid.v4(), name: 'Fermín López',        number: 16, position: 'MED'),
      Player(id: _uuid.v4(), name: 'Raphinha',            number: 11, position: 'DEL'),
      Player(id: _uuid.v4(), name: 'Ferran Torres',       number: 7,  position: 'DEL'),
      Player(id: _uuid.v4(), name: 'Lamine Yamal',        number: 10, position: 'DEL'),
      // ---- SUPLENTES ----
      Player(id: _uuid.v4(), name: 'Wojciech Szczęsny',  number: 25,  position: 'POR'),
      Player(id: _uuid.v4(), name: 'João Cancelo',        number: 2,  position: 'DEF'),
      Player(id: _uuid.v4(), name: 'Ronald Araújo',       number: 4,  position: 'DEF'),
      Player(id: _uuid.v4(), name: 'Gavi',                number: 6,  position: 'MED'),
      Player(id: _uuid.v4(), name: 'Dani Olmo',           number: 20, position: 'MED'),
      Player(id: _uuid.v4(), name: 'Robert Lewandowski',  number: 9,  position: 'DEL'),
      Player(id: _uuid.v4(), name: 'Marcus Rashford',     number: 14, position: 'DEL'),
    ];
    _saveToStorage();
    notifyListeners();
  }
}