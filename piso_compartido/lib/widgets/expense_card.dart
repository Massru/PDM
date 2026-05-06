import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../models/person.dart';
import '../utils/date_utils.dart';

/// Tarjeta que representa un gasto individual en la lista de HomeScreen.
/// Muestra la categoría, descripción, quién pagó, fecha e importe.
/// Incluye botón de eliminar con diálogo de confirmación.
class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final List<Person> people; // lista completa para resolver nombres por ID
  final VoidCallback onDelete;

  const ExpenseCard({
    super.key,
    required this.expense,
    required this.people,
    required this.onDelete,
  });

  /// Resuelve el nombre de una persona a partir de su ID.
  /// Si no se encuentra (caso raro), devuelve '?' como fallback.
  String _personName(String id) => people
      .firstWhere((p) => p.id == id,
          orElse: () => const Person(id: '', name: '?'))
      .name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        // Avatar con la primera letra de la categoría como identificador visual
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            expense.category.label[0],
            style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer),
          ),
        ),
        title: Text(expense.description,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        // Subtítulo con categoría, quién pagó y fecha
        subtitle: Text(
          '${expense.category.label} · ${_personName(expense.paidByPersonId)} · ${AppDateUtils.format(expense.date)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min, // evita que el Row ocupe todo el ancho
          children: [
            Text(
              '${expense.amount.toStringAsFixed(2)} €',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
            // Botón de eliminar: abre diálogo de confirmación antes de borrar
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.redAccent),
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
                          onDelete(); // delegamos la lógica al padre
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