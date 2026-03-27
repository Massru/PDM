import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/match.dart';
import '../models/match_event.dart';

class MatchProvider extends ChangeNotifier {
  Match? _currentMatch;
  List<Match> _matchHistory = [];
  // Tiempo en segundos: se convierte a minutos al guardar en eventos
  int _totalSeconds = 0;
  bool _isRunning = false;
  Timer? _timer;

  static const _storageKey = 'match_history';
  final _uuid = const Uuid();

  Match? get currentMatch => _currentMatch;
  List<Match> get matchHistory => List.unmodifiable(_matchHistory);
  bool get isRunning => _isRunning;
  bool get hasActiveMatch => _currentMatch != null && !_currentMatch!.isFinished;

  // Minuto actual (para guardar en los eventos)
  // Se calcula dividiendo segundos totales entre 60 (división entera ~/ trunca decimales)
  int get currentMinute => _totalSeconds ~/ 60;

  // Formato MM:SS para mostrar en pantalla
  // Calcula minutos y segundos restantes, los formatea con ceros a la izquierda
  String get timerDisplay {
    final minutes = _totalSeconds ~/ 60;
    final seconds = _totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  MatchProvider() {
    _loadHistory();
  }

  // Crea un nuevo partido con los datos iniciales
  // Los eventos comienzan vacíos y se van registrando conforme avanza el partido
  void startMatch(String opponent, List<String> lineup) {
    _currentMatch = Match(
      id: _uuid.v4(),
      date: DateTime.now(),
      opponent: opponent,
      lineup: lineup,
    );
    _totalSeconds = 0;
    _isRunning = false;
    notifyListeners();
  }

  // Inicia el cronómetro automático
  // Crea un Timer que llama cada 1 segundo, incrementando _totalSeconds
  // Luego notifica a los listeners para actualizar la UI
  void startTimer() {
    if (_isRunning) return; // Evita crear múltiples timers
    _isRunning = true;
    // Timer.periodic crea un timer recurrente que se ejecuta cada Duration
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _totalSeconds++;
      notifyListeners();
    });
    notifyListeners();
  }

  // Pausa el cronómetro: cancela el Timer y actualiza el estado
  void pauseTimer() {
    _isRunning = false;
    _timer?.cancel(); // Detiene el timer periódico
    notifyListeners();
  }

  // Ajusta tiempo en minutos completos: -1 min = -60 seg, +1 min = +60 seg
  // Limitado a 0-120 minutos (rango válido de partido)
  // clamp(0, 120*60) asegura que no quede negativo ni pase de 2 horas
  void adjustMinute(int delta) {
    _totalSeconds = (_totalSeconds + delta * 60).clamp(0, 120 * 60);
    notifyListeners();
  }

  // Registra un evento en el partido actual
  // Si es una sustitución (substitutionOut), actualiza la alineación actual
  // reemplazando el jugador que sale con el que entra
  void addEvent(String playerId, EventType type, {String? relatedPlayerId}) {
    if (_currentMatch == null) return;

    final event = MatchEvent(
      id: _uuid.v4(),
      playerId: playerId,
      type: type,
      minute: currentMinute, // Guardamos minuto entero, no segundos
      relatedPlayerId: relatedPlayerId,
    );

    _currentMatch!.events.add(event);

    // Si es sustitución, actualizamos la alineación actual
    // Encuentra la posición del jugador que sale y la reemplaza con el que entra
    if (type == EventType.substitutionOut && relatedPlayerId != null) {
      final idx = _currentMatch!.lineup.indexOf(playerId);
      if (idx != -1) {
        _currentMatch!.lineup[idx] = relatedPlayerId;
      }
    }

    notifyListeners();
  }

  // Deshace el último evento registrado
  // Útil para corregir errores de registro rápidamente
  void undoLastEvent() {
    if (_currentMatch == null || _currentMatch!.events.isEmpty) return;
    _currentMatch!.events.removeLast(); // Elimina el último evento de la lista
    notifyListeners();
  }

  // Cuenta cuántas veces ocurrió un evento específico para un jugador
  // Por ejemplo: cuántas tarjetas amarillas tiene un jugador en este partido
  int getStatForPlayer(String playerId, EventType type) {
    if (_currentMatch == null) return 0;
    // Filtra eventos del jugador con ese tipo, y cuenta cuántos hay
    return _currentMatch!.events
        .where((e) => e.playerId == playerId && e.type == type)
        .length;
  }

  // Finaliza el partido actual con el resultado final
  // Detiene el cronómetro, marca como finalizado y lo guarda en el historial
  void finishMatch(int goalsFor, int goalsAgainst) {
    if (_currentMatch == null) return;
    pauseTimer(); // Pausa el cronómetro
    _currentMatch!.goalsFor = goalsFor;
    _currentMatch!.goalsAgainst = goalsAgainst;
    _currentMatch!.isFinished = true;
    // Añade el partido finalizado al historial permanente
    _matchHistory.add(_currentMatch!);
    _saveHistory(); // Persiste en SharedPreferences
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Serializa todo el historial de partidos a JSON y lo guarda en SharedPreferences
  // Esto permite recuperar los datos después de cerrar la app
  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    // Convierte cada Match a JSON, luego todo a una lista JSON
    final list = _matchHistory.map((m) => m.toJson()).toList();
    // Guarda la lista bajo la clave 'match_history'
    await prefs.setString(_storageKey, jsonEncode(list));
  }

  // Recupera el historial de partidos guardado en SharedPreferences
  // Se llama en el constructor para cargar los datos al iniciar la app
  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey); // Obtiene el JSON guardado
    if (raw != null) {
      // Decodifica JSON a List de Maps
      final list = jsonDecode(raw) as List;
      // Convierte cada Map a un objeto Match usando fromJson
      _matchHistory = list.map((e) => Match.fromJson(e)).toList();
      notifyListeners(); // Notifica a listeners para actualizar UI
    }
  }
}