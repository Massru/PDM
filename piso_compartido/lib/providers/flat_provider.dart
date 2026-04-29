import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/flat_config.dart';
import '../models/person.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';

class FlatProvider with ChangeNotifier {
  // Todos los pisos guardados
  List<FlatConfig> _flats = [];
  // Piso activo
  FlatConfig? _activeConfig;
  // Personas del piso activo
  List<Person> _people = [];

  bool _isLoading = true;
  DateTime? _simulatedToday;
  bool _periodJustClosed = false;

  List<FlatConfig> get flats => List.unmodifiable(_flats);
  FlatConfig? get config => _activeConfig;
  List<Person> get people => List.unmodifiable(_people);
  bool get isConfigured => _activeConfig != null;
  bool get isLoading => _isLoading;
  DateTime get simulatedToday => _simulatedToday ?? DateTime.now();
  bool get periodJustClosed => _periodJustClosed;

  // Clave de gastos del piso activo
  String get expensesKey => _activeConfig != null
      ? '${AppConstants.prefKeyExpensesPrefix}${_activeConfig!.id}'
      : AppConstants.prefKeyExpenses;

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      // Cargar lista de pisos
      final flatsRaw = prefs.getString(AppConstants.prefKeyFlats);
      if (flatsRaw != null) {
        final list = jsonDecode(flatsRaw) as List;
        _flats = list
            .map((e) => FlatConfig.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Cargar piso activo
      final activeId = prefs.getString(AppConstants.prefKeyActiveFlat);
      if (activeId != null && _flats.isNotEmpty) {
        final found = _flats.where((f) => f.id == activeId);
        if (found.isNotEmpty) {
          _activeConfig = found.first;
          await _loadPeopleForActive(prefs);
        }
      }

      // Migración: si hay datos del formato antiguo y no hay pisos nuevos
      if (_flats.isEmpty) {
        final oldRaw = prefs.getString(AppConstants.prefKeyConfig);
        if (oldRaw != null) {
          final old = jsonDecode(oldRaw) as Map<String, dynamic>;
          final oldConfig = FlatConfig.fromJson({
            'id': 'legacy',
            'name': 'Mi piso',
            ...old['config'] as Map<String, dynamic>,
          });
          _flats = [oldConfig];
          _activeConfig = oldConfig;
          _people = (old['people'] as List)
              .map((e) => Person.fromJson(e as Map<String, dynamic>))
              .toList();
          await _saveFlats(prefs);
          await prefs.setString(AppConstants.prefKeyActiveFlat, 'legacy');
        }
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadPeopleForActive(SharedPreferences prefs) async {
    final raw = prefs.getString('people_${_activeConfig!.id}');
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _people = list
          .map((e) => Person.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      _people = [];
    }
  }

  Future<void> _saveFlats(SharedPreferences prefs) async {
    await prefs.setString(
      AppConstants.prefKeyFlats,
      jsonEncode(_flats.map((f) => f.toJson()).toList()),
    );
  }

  /// Cambia el piso activo
  Future<void> switchFlat(String flatId) async {
    final found = _flats.where((f) => f.id == flatId);
    if (found.isEmpty) return;
    _activeConfig = found.first;
    _simulatedToday = null;
    _periodJustClosed = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefKeyActiveFlat, flatId);
    await _loadPeopleForActive(prefs);
    notifyListeners();
  }

  /// Crea un piso nuevo y lo activa
  Future<void> setupFlat({
    required String flatName,
    required List<String> names,
    required List<String> fixedCategories,
    required Map<String, double> fixedAmounts,
    required int billingDay,
  }) async {
    const uuid = Uuid();
    final flatId = uuid.v4();
    final newPeople =
        names.map((n) => Person(id: uuid.v4(), name: n)).toList();
    final newConfig = FlatConfig(
      id: flatId,
      name: flatName,
      people: names,
      fixedExpenseCategories: fixedCategories,
      fixedExpenseAmounts: fixedAmounts,
      billingDay: billingDay,
    );

    _flats.add(newConfig);
    _activeConfig = newConfig;
    _people = newPeople;
    _simulatedToday = null;
    _periodJustClosed = false;

    final prefs = await SharedPreferences.getInstance();
    await _saveFlats(prefs);
    await prefs.setString(AppConstants.prefKeyActiveFlat, flatId);
    await prefs.setString(
      'people_$flatId',
      jsonEncode(newPeople.map((p) => p.toJson()).toList()),
    );

    notifyListeners();
  }

  void advanceDay({int days = 1}) {
    final before = simulatedToday;
    _simulatedToday = simulatedToday.add(Duration(days: days));
    _periodJustClosed = _crossedClosingDay(before, simulatedToday);
    notifyListeners();
  }

  void resetSimulatedDate() {
    _simulatedToday = null;
    _periodJustClosed = false;
    notifyListeners();
  }

  void acknowledgePeriodClosed() {
    _periodJustClosed = false;
    notifyListeners();
  }

  bool _crossedClosingDay(DateTime before, DateTime after) {
    if (_activeConfig == null) return false;
    final billingDay = _activeConfig!.billingDay;
    DateTime cursor = DateTime(before.year, before.month, before.day);
    final end = DateTime(after.year, after.month, after.day);
    while (cursor.isBefore(end)) {
      cursor = cursor.add(const Duration(days: 1));
      final resolved = AppDateUtils.resolvedBillingDay(
          billingDay, cursor.year, cursor.month);
      if (cursor.day == resolved) return true;
    }
    return false;
  }

  /// Elimina el piso activo
  Future<void> deleteActiveFlat() async {
    if (_activeConfig == null) return;
    final id = _activeConfig!.id;
    _flats.removeWhere((f) => f.id == id);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('people_$id');
    await prefs.remove('${AppConstants.prefKeyExpensesPrefix}$id');
    await _saveFlats(prefs);

    if (_flats.isNotEmpty) {
      await switchFlat(_flats.last.id);
    } else {
      _activeConfig = null;
      _people = [];
      await prefs.remove(AppConstants.prefKeyActiveFlat);
      notifyListeners();
    }
  }

  Future<void> reset() async {
    if (_activeConfig == null) return;
    await deleteActiveFlat();
  }
}