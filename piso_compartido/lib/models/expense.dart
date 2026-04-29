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

extension ExpenseCategoryExt on ExpenseCategory {
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

  bool get isFixed => [
        ExpenseCategory.luz,
        ExpenseCategory.agua,
        ExpenseCategory.comunidad,
        ExpenseCategory.internet,
      ].contains(this);
}

class Expense {
  final String id;
  final String paidByPersonId;
  final double amount;
  final ExpenseCategory category;
  final String description;
  final DateTime date;
  final List<String> splitAmongIds;

  const Expense({
    required this.id,
    required this.paidByPersonId,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    required this.splitAmongIds,
  });

  double get sharePerPerson =>
      splitAmongIds.isEmpty ? 0 : amount / splitAmongIds.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'paidByPersonId': paidByPersonId,
        'amount': amount,
        'category': category.name,
        'description': description,
        'date': date.toIso8601String(),
        'splitAmongIds': splitAmongIds,
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'],
        paidByPersonId: json['paidByPersonId'],
        amount: (json['amount'] as num).toDouble(),
        category: ExpenseCategory.values
            .firstWhere((e) => e.name == json['category']),
        description: json['description'],
        date: DateTime.parse(json['date']),
        splitAmongIds: List<String>.from(json['splitAmongIds']),
      );
}