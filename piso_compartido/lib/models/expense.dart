/// Categorías de gastos disponibles en la app.
/// Las primeras cuatro son "fijas" (facturas del piso),
/// el resto son variables (compras del día a día).
enum ExpenseCategory {
  luz,
  agua,
  comunidad,
  internet,
  comida,
  higiene,
  limpieza,
  otro,
}

/// Extension sobre el enum para añadir comportamiento sin modificar
/// la definición base. Esto es un patrón habitual en Dart.
extension ExpenseCategoryExt on ExpenseCategory {
  /// Etiqueta legible en español para mostrar en la UI.
  String get label {
    const labels = {
      ExpenseCategory.luz: 'Luz',
      ExpenseCategory.agua: 'Agua',
      ExpenseCategory.comunidad: 'Comunidad',
      ExpenseCategory.internet: 'Internet',
      ExpenseCategory.comida: 'Comida',
      ExpenseCategory.higiene: 'Higiene',
      ExpenseCategory.limpieza: 'Limpieza',
      ExpenseCategory.otro: 'Otro',
    };
    return labels[this]!;
  }

  /// Indica si la categoría es de gasto fijo (factura del piso).
  /// Se usa para distinguir en la UI y en los cálculos de liquidación.
  bool get isFixed => [
        ExpenseCategory.luz,
        ExpenseCategory.agua,
        ExpenseCategory.comunidad,
        ExpenseCategory.internet,
      ].contains(this);
}

/// Representa un gasto concreto registrado en la app.
class Expense {
  final String id;              // UUID del gasto
  final String paidByPersonId;  // ID de la persona que adelantó el dinero
  final double amount;          // Importe total pagado
  final ExpenseCategory category;
  final String description;     // Texto libre del gasto
  final DateTime date;          // Fecha del gasto (relevante para el período)
  final List<String> splitAmongIds; // IDs de las personas que comparten
                                    // este gasto (puede ser un subconjunto)

  const Expense({
    required this.id,
    required this.paidByPersonId,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    required this.splitAmongIds,
  });

  /// Parte proporcional que corresponde a cada persona.
  /// IMPORTANTE: dividimos entre el número de personas que comparten
  /// el gasto, NO entre todos los inquilinos del piso.
  double get sharePerPerson =>
      splitAmongIds.isEmpty ? 0 : amount / splitAmongIds.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'paidByPersonId': paidByPersonId,
        'amount': amount,
        'category': category.name, // guardamos el nombre del enum como string
        'description': description,
        'date': date.toIso8601String(),
        'splitAmongIds': splitAmongIds,
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'],
        paidByPersonId: json['paidByPersonId'],
        amount: (json['amount'] as num).toDouble(),
        // Reconstruimos el enum buscando por nombre de string
        category: ExpenseCategory.values
            .firstWhere((e) => e.name == json['category']),
        description: json['description'],
        date: DateTime.parse(json['date']),
        splitAmongIds: List<String>.from(json['splitAmongIds']),
      );
}