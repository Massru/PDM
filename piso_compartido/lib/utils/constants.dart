/// Constantes globales de la app.
/// Centralizar aquí las claves de SharedPreferences evita errores
/// de typo al leer/escribir datos y facilita refactorizaciones.
class AppConstants {
  // Categorías que aparecen preseleccionadas en el setup del piso
  static const List<String> defaultFixedCategories = [
    'Luz', 'Agua', 'Comunidad', 'Internet',
  ];

  // Categorías de gastos del día a día
  static const List<String> variableCategories = [
    'Comida', 'Higiene', 'Limpieza', 'Otro',
  ];

  // Clave donde se guarda la lista JSON de todos los pisos
  static const String prefKeyFlats = 'flats';

  // Clave donde se guarda el ID del piso activo entre sesiones
  static const String prefKeyActiveFlat = 'active_flat_id';

  // Prefijo para las claves de gastos: cada piso tiene su propia clave
  // formada por este prefijo + el ID del piso, ej: 'expenses_abc-123'
  static const String prefKeyExpensesPrefix = 'expenses_';

  // Claves del formato antiguo (un solo piso), mantenidas para migración
  static const String prefKeyConfig = 'flat_config';
  static const String prefKeyExpenses = 'expenses';
}