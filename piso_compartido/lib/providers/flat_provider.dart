import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/flat_config.dart';
import '../models/person.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';

/// Provider principal de la app. Gestiona:
///   - La lista de todos los pisos guardados
///   - Qué piso está activo en este momento
///   - Las personas del piso activo
///   - La fecha simulada (para pruebas)
///   - La detección del cierre de período
///
/// Extiende ChangeNotifier para integrarse con el sistema de Provider:
/// cada vez que llamamos a notifyListeners(), todos los widgets que
/// escuchan este provider se reconstruyen.
class FlatProvider with ChangeNotifier {
  List<FlatConfig> _flats = [];   // Todos los pisos guardados
  FlatConfig? _activeConfig;       // Configuración del piso activo
  List<Person> _people = [];       // Personas del piso activo
  bool _isLoading = true;
  DateTime? _simulatedToday;       // null = usar DateTime.now() real
  bool _periodJustClosed = false;  // Se activa al cruzar el día de cierre

  // Getters públicos — exponemos copias inmutables para evitar
  // modificaciones accidentales desde fuera del provider
  List<FlatConfig> get flats => List.unmodifiable(_flats);
  FlatConfig? get config => _activeConfig;
  List<Person> get people => List.unmodifiable(_people);
  bool get isConfigured => _activeConfig != null;
  bool get isLoading => _isLoading;
  bool get periodJustClosed => _periodJustClosed;

  /// Fecha actual de la app. Si hay fecha simulada la usa,
  /// si no usa la fecha real del sistema.
  DateTime get simulatedToday => _simulatedToday ?? DateTime.now();

  /// Clave de SharedPreferences donde se guardan los gastos del piso activo.
  /// Cada piso tiene su propia clave para no mezclar datos entre pisos.
  String get expensesKey => _activeConfig != null
      ? '${AppConstants.prefKeyExpensesPrefix}${_activeConfig!.id}'
      : AppConstants.prefKeyExpenses;

  /// Carga inicial de datos al arrancar la app.
  /// Se llama en main.dart al crear el provider: FlatProvider()..loadData()
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Cargar todos los pisos guardados
      final flatsRaw = prefs.getString(AppConstants.prefKeyFlats);
      if (flatsRaw != null) {
        final list = jsonDecode(flatsRaw) as List;
        _flats = list
            .map((e) => FlatConfig.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // 2. Restaurar el piso que estaba activo en la última sesión
      final activeId = prefs.getString(AppConstants.prefKeyActiveFlat);
      if (activeId != null && _flats.isNotEmpty) {
        final found = _flats.where((f) => f.id == activeId);
        if (found.isNotEmpty) {
          _activeConfig = found.first;
          await _loadPeopleForActive(prefs);
        }
      }

      // 3. MIGRACIÓN: si hay datos del formato antiguo (un solo piso)
      //    y no hay pisos en el nuevo formato, los convertimos.
      //    Esto garantiza que usuarios con versiones anteriores
      //    no pierdan sus datos al actualizar.
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
    } catch (_) {
      // Si algo falla al cargar, arrancamos con estado vacío
      // en lugar de crashear la app
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Carga las personas del piso activo desde SharedPreferences.
  /// Las personas se guardan separadas de la config con la clave 'people_{id}'
  /// para poder actualizarlas independientemente.
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

  /// Guarda la lista completa de pisos en SharedPreferences.
  Future<void> _saveFlats(SharedPreferences prefs) async {
    await prefs.setString(
      AppConstants.prefKeyFlats,
      jsonEncode(_flats.map((f) => f.toJson()).toList()),
    );
  }

  /// Cambia el piso activo. Llamado desde el Drawer y desde WelcomeScreen.
  /// Resetea la fecha simulada al cambiar de piso para evitar confusiones.
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

  /// Crea un piso nuevo, lo guarda y lo activa inmediatamente.
  /// Al llamar a notifyListeners(), el Consumer en main.dart detecta
  /// que isConfigured pasó a true y navega a HomeScreen automáticamente.
  Future<void> setupFlat({
    required String flatName,
    required List<String> names,
    required List<String> fixedCategories,
    required Map<String, double> fixedAmounts,
    required int billingDay,
  }) async {
    const uuid = Uuid();
    final flatId = uuid.v4();

    // Creamos entidades Person con ID propio para cada inquilino
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
    // Guardamos las personas con su propia clave separada
    await prefs.setString(
      'people_$flatId',
      jsonEncode(newPeople.map((p) => p.toJson()).toList()),
    );

    notifyListeners();
  }

  /// Avanza la fecha simulada [days] días hacia adelante.
  /// IMPORTANTE: después de avanzar, comprobamos si cruzamos el día
  /// de cierre del período. Si es así, activamos _periodJustClosed
  /// para que HomeScreen muestre la pantalla de liquidación.
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

  /// Llamado desde SettlementScreen cuando el usuario cierra la liquidación.
  /// Desactiva la flag para no volver a mostrar la pantalla de liquidación.
  void acknowledgePeriodClosed() {
    _periodJustClosed = false;
    notifyListeners();
  }

  /// Comprueba si entre [before] y [after] hemos cruzado el día de cierre.
  /// Itera día a día porque el usuario puede avanzar 7 días de golpe
  /// y podría cruzar el día de cierre en medio del salto.
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

  /// Elimina el piso activo: borra sus datos de SharedPreferences,
  /// lo quita de la lista y activa el siguiente piso disponible.
  /// Si no quedan pisos, vuelve al estado inicial (WelcomeScreen).
  Future<void> deleteActiveFlat() async {
    if (_activeConfig == null) return;
    final id = _activeConfig!.id;
    _flats.removeWhere((f) => f.id == id);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('people_$id');
    await prefs.remove('${AppConstants.prefKeyExpensesPrefix}$id');
    await _saveFlats(prefs);

    if (_flats.isNotEmpty) {
      // Si quedan pisos, activamos el último de la lista
      await switchFlat(_flats.last.id);
    } else {
      // Sin pisos: volvemos a WelcomeScreen
      _activeConfig = null;
      _people = [];
      await prefs.remove(AppConstants.prefKeyActiveFlat);
      notifyListeners();
    }
  }

  Future<void> reset() async => deleteActiveFlat();
}