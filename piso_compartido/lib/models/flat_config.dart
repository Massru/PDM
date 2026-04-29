class FlatConfig {
  final List<String> people;
  final List<String> fixedExpenseCategories;
  /// Importes fijos por categoría (clave = nombre categoría)
  final Map<String, double> fixedExpenseAmounts;
  /// Día de cierre: 1-31, o 0 = último día del mes
  final int billingDay;

  const FlatConfig({
    required this.people,
    required this.fixedExpenseCategories,
    required this.fixedExpenseAmounts,
    required this.billingDay,
  });

  String get billingDayLabel =>
      billingDay == 0 ? 'Último día del mes' : 'Día $billingDay';

  Map<String, dynamic> toJson() => {
        'people': people,
        'fixedExpenseCategories': fixedExpenseCategories,
        'fixedExpenseAmounts':
            fixedExpenseAmounts.map((k, v) => MapEntry(k, v)),
        'billingDay': billingDay,
      };

  factory FlatConfig.fromJson(Map<String, dynamic> json) => FlatConfig(
        people: List<String>.from(json['people']),
        fixedExpenseCategories:
            List<String>.from(json['fixedExpenseCategories']),
        fixedExpenseAmounts: json['fixedExpenseAmounts'] != null
            ? Map<String, double>.from(
                (json['fixedExpenseAmounts'] as Map)
                    .map((k, v) => MapEntry(k as String, (v as num).toDouble())),
              )
            : {},
        billingDay: json['billingDay'],
      );
}