import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/flat_config.dart';
import '../models/person.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';
import '../utils/storage_service.dart';

class FlatProvider with ChangeNotifier {
  FlatConfig? _config;
  List<Person> _people = [];
  bool _isLoading = true;
  DateTime? _simulatedToday;
  DateTime? _lastCheckedDay; // para detectar cruce de período

  FlatConfig? get config => _config;
  List<Person> get people => List.unmodifiable(_people);
  bool get isConfigured => _config != null;
  bool get isLoading => _isLoading;
  DateTime get simulatedToday => _simulatedToday ?? DateTime.now();

  /// Devuelve true si al avanzar el día hemos cruzado el día de cierre
  bool get periodJustClosed => _periodJustClosed;
  bool _periodJustClosed = false;

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await StorageService.load<Map<String, dynamic>>(
        AppConstants.prefKeyConfig,
        (json) => json,
      );
      if (prefs != null) {
        _config = FlatConfig.fromJson(prefs['config'] as Map<String, dynamic>);
        _people = (prefs['people'] as List)
            .map((e) => Person.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setupFlat({
    required List<String> names,
    required List<String> fixedCategories,
    required Map<String, double> fixedAmounts,
    required int billingDay,
  }) async {
    const uuid = Uuid();
    _people = names.map((n) => Person(id: uuid.v4(), name: n)).toList();
    _config = FlatConfig(
      people: names,
      fixedExpenseCategories: fixedCategories,
      fixedExpenseAmounts: fixedAmounts,
      billingDay: billingDay,
    );

    await StorageService.save(AppConstants.prefKeyConfig, {
      'config': _config!.toJson(),
      'people': _people.map((p) => p.toJson()).toList(),
    });

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

  /// Marca el cierre de período como ya gestionado
  void acknowledgePeriodClosed() {
    _periodJustClosed = false;
    notifyListeners();
  }

  /// Comprueba si entre [before] y [after] hemos cruzado el día de cierre
  bool _crossedClosingDay(DateTime before, DateTime after) {
    if (_config == null) return false;
    final billingDay = _config!.billingDay;

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

  Future<void> reset() async {
    await StorageService.remove(AppConstants.prefKeyConfig);
    await StorageService.remove(AppConstants.prefKeyExpenses);
    _config = null;
    _people = [];
    _simulatedToday = null;
    _periodJustClosed = false;
    notifyListeners();
  }
}