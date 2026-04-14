import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/match.dart';
import '../models/match_event.dart';

// Provider que gestiona el partido en curso y el historial de partidos.
// Incluye el cronómetro que avanza segundo a segundo y el marcador en tiempo real.
class MatchProvider extends ChangeNotifier {
  Match? _currentMatch;
  List<Match> _matchHistory = [];
  int _totalSeconds = 0; // Tiempo interno en segundos
  bool _isRunning = false;
  Timer? _timer;

  // Marcador en tiempo real (se actualiza automáticamente con eventos de gol)
  int _goalsFor = 0;     // Goles de nuestro equipo
  int _goalsAgainst = 0; // Goles del rival

  static const _storageKey = 'match_history';
  final _uuid = const Uuid();

  Match? get currentMatch => _currentMatch;
  List<Match> get matchHistory => List.unmodifiable(_matchHistory);
  bool get isRunning => _isRunning;
  bool get hasActiveMatch => _currentMatch != null && !_currentMatch!.isFinished;
  int get goalsFor => _goalsFor;
  int get goalsAgainst => _goalsAgainst;

  // Minuto actual (para guardar en los eventos)
  int get currentMinute => _totalSeconds ~/ 60;

  // Formato MM:SS para mostrar en pantalla
  String get timerDisplay {
    final minutes = _totalSeconds ~/ 60;
    final seconds = _totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  MatchProvider() {
    _loadHistory();
  }

  // Inicia un nuevo partido con la alineación seleccionada
  void startMatch(String opponent, List<String> lineup) {
    _currentMatch = Match(
      id: _uuid.v4(),
      date: DateTime.now(),
      opponent: opponent,
      lineup: lineup,
    );
    _totalSeconds = 0;
    _isRunning = false;
    // Reseteamos el marcador al iniciar partido
    _goalsFor = 0;
    _goalsAgainst = 0;
    notifyListeners();
  }

  // Arranca el cronómetro (tick cada segundo)
  void startTimer() {
    if (_isRunning) return;
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _totalSeconds++;
      notifyListeners();
    });
    notifyListeners();
  }

  // Pausa el cronómetro sin resetear el tiempo
  void pauseTimer() {
    _isRunning = false;
    _timer?.cancel();
    notifyListeners();
  }

  // Ajuste manual fino: delta en minutos (convierte a segundos internamente)
  void adjustMinute(int delta) {
    _totalSeconds = (_totalSeconds + delta * 60).clamp(0, 120 * 60);
    notifyListeners();
  }

  // Registra un evento usando el minuto actual del cronómetro.
  // Si el evento es un gol, incrementa automáticamente el marcador propio.
  void addEvent(String playerId, EventType type, {String? relatedPlayerId}) {
    if (_currentMatch == null) return;

    final event = MatchEvent(
      id: _uuid.v4(),
      playerId: playerId,
      type: type,
      minute: currentMinute, // Se toma automáticamente del cronómetro
      relatedPlayerId: relatedPlayerId,
    );

    _currentMatch!.events.add(event);

    // Si el evento es un gol sumamos al marcador propio automáticamente
    if (type == EventType.goal) {
      _goalsFor++;
    }

    // Si es sustitución, actualizamos la alineación activa del partido
    if (type == EventType.substitutionOut && relatedPlayerId != null) {
      final idx = _currentMatch!.lineup.indexOf(playerId);
      if (idx != -1) {
        _currentMatch!.lineup[idx] = relatedPlayerId;
      }
    }

    notifyListeners();
  }

  // Elimina el último evento registrado (botón deshacer).
  // Si el evento era un gol, resta del marcador propio.
  void undoLastEvent() {
    if (_currentMatch == null || _currentMatch!.events.isEmpty) return;
    final last = _currentMatch!.events.last;
    // Si deshacemos un gol, lo restamos del marcador
    if (last.type == EventType.goal && _goalsFor > 0) {
      _goalsFor--;
    }
    _currentMatch!.events.removeLast();
    notifyListeners();
  }

  // Suma un gol al equipo rival manualmente (botón + en el marcador)
  void addGoalAgainst() {
    _goalsAgainst++;
    notifyListeners();
  }

  // Resta un gol al equipo rival (pulsación larga en el botón - para evitar errores)
  void removeGoalAgainst() {
    if (_goalsAgainst > 0) _goalsAgainst--;
    notifyListeners();
  }

  // Cuenta cuántas veces ocurrió un tipo de evento para un jugador en el partido actual
  int getStatForPlayer(String playerId, EventType type) {
    if (_currentMatch == null) return 0;
    return _currentMatch!.events
        .where((e) => e.playerId == playerId && e.type == type)
        .length;
  }

  // Finaliza el partido, para el cronómetro y guarda en historial.
  // Usa el marcador interno en tiempo real como resultado final.
  void finishMatch() {
    if (_currentMatch == null) return;
    pauseTimer();
    _currentMatch!.goalsFor = _goalsFor;
    _currentMatch!.goalsAgainst = _goalsAgainst;
    _currentMatch!.isFinished = true;
    _matchHistory.add(_currentMatch!);
    _saveHistory();
    notifyListeners();
  }

  // Importante: cancelar el timer al destruir el provider para evitar memory leaks
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- Persistencia del historial ---

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _matchHistory.map((m) => m.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(list));
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _matchHistory = list.map((e) => Match.fromJson(e)).toList();
      notifyListeners();
    }
  }
}