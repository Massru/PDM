class AppConstants {
  static const List<String> defaultFixedCategories = [
    'Luz',
    'Agua',
    'Comunidad',
    'Internet',
  ];

  static const List<String> variableCategories = [
    'Comida',
    'Higiene',
    'Limpieza',
    'Otro',
  ];

  static const String prefKeyFlats = 'flats';
  static const String prefKeyActiveFlat = 'active_flat_id';
  static const String prefKeyExpensesPrefix = 'expenses_';

  // Compatibilidad con versión anterior (un solo piso)
  static const String prefKeyConfig = 'flat_config';
  static const String prefKeyExpenses = 'expenses';
}