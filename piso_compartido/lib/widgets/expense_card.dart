import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../models/person.dart';
import '../utils/date_utils.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final List<Person> people;
  final VoidCallback onDelete;

  const ExpenseCard({
    super.key,
    required this.expense,
    required this.people,
    required this.onDelete,
  });

  String _personName(String id) =>
      people.firstWhere((p) => p.id == id, orElse: () => const Person(id: '', name: '?')).name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(expense.category.label[0],
              style: TextStyle(color: theme.colorScheme.onPrimaryContainer)),
        ),
        title: Text(expense.description,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${expense.category.label} · ${_personName(expense.paidByPersonId)} · ${AppDateUtils.format(expense.date)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${expense.amount.toStringAsFixed(2)} €',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('¿Eliminar gasto?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar')),
                    FilledButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onDelete();
                        },
                        child: const Text('Eliminar')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}