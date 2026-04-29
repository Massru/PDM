class FlatConfig {
  final String id;
  final String name; // nombre del piso, ej: "Piso Rúa do Demo"
  final List<String> people;
  final List<String> fixedExpenseCategories;
  final Map<String, double> fixedExpenseAmounts;
  final int billingDay;

  const FlatConfig({
    required this.id,
    required this.name,
    required this.people,
    required this.fixedExpenseCategories,
    required this.fixedExpenseAmounts,
    required this.billingDay,
  });

  String get billingDayLabel =>
      billingDay == 0 ? 'Último día del mes' : 'Día $billingDay';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'people': people,
        'fixedExpenseCategories': fixedExpenseCategories,
        'fixedExpenseAmounts':
            fixedExpenseAmounts.map((k, v) => MapEntry(k, v)),
        'billingDay': billingDay,
      };

  factory FlatConfig.fromJson(Map<String, dynamic> json) => FlatConfig(
        id: json['id'] as String,
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