/// Representa la configuración completa de un piso compartido.
/// Es el modelo central de la app: contiene quién vive en el piso,
/// qué gastos fijos tiene y cuándo se cierra el período de facturación.
class FlatConfig {
  final String id;           // ID único generado con uuid al crear el piso
  final String name;         // Nombre del piso, ej: "Piso Rúa do Demo"
  final List<String> people; // Nombres de los inquilinos (solo strings, las
                             // entidades Person completas se guardan aparte)
  final List<String> fixedExpenseCategories; // Categorías fijas seleccionadas
                                             // ej: ['Luz', 'Agua', 'Internet']
  final Map<String, double> fixedExpenseAmounts; // Importe mensual de cada
                             // categoría fija, ej: {'Luz': 60.0, 'Agua': 25.0}
  final int billingDay;      // Día de cierre del período: 1-28, o 0 = último
                             // día del mes (valor especial)

  const FlatConfig({
    required this.id,
    required this.name,
    required this.people,
    required this.fixedExpenseCategories,
    required this.fixedExpenseAmounts,
    required this.billingDay,
  });

  /// Devuelve una cadena legible del día de cierre para mostrar en la UI.
  /// Si billingDay es 0 (último día del mes) lo indica explícitamente.
  String get billingDayLabel =>
      billingDay == 0 ? 'Último día del mes' : 'Día $billingDay';

  /// Serializa el modelo a un Map para guardarlo en SharedPreferences como JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'people': people,
        'fixedExpenseCategories': fixedExpenseCategories,
        // Convertimos el Map explícitamente para asegurar tipos correctos
        'fixedExpenseAmounts':
            fixedExpenseAmounts.map((k, v) => MapEntry(k, v)),
        'billingDay': billingDay,
      };

  /// Reconstruye un FlatConfig desde un Map leído de SharedPreferences.
  /// Importante: los valores numéricos del JSON siempre llegan como 'num',
  /// por eso hacemos el cast explícito a double con (v as num).toDouble().
  factory FlatConfig.fromJson(Map<String, dynamic> json) => FlatConfig(
        id: json['id'] as String,
        // Fallback a 'Mi piso' por compatibilidad con datos guardados
        // antes de que existiera el campo 'name'
        name: json['name'] as String? ?? 'Mi piso',
        people: List<String>.from(json['people']),
        fixedExpenseCategories:
            List<String>.from(json['fixedExpenseCategories']),
        fixedExpenseAmounts: json['fixedExpenseAmounts'] != null
            ? Map<String, double>.from(
                (json['fixedExpenseAmounts'] as Map)
                    .map((k, v) => MapEntry(k as String, (v as num).toDouble())),
              )
            : {},
        billingDay: json['billingDay'] as int,
      );
}