import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/flat_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.comida;
  String? _paidByPersonId;
  Set<String> _splitAmong = {};
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _date = context.read<FlatProvider>().simulatedToday; // ← esta línea
    final people = context.read<FlatProvider>().people;
    if (people.isNotEmpty) {
      _paidByPersonId = people.first.id;
      _splitAmong = people.map((p) => p.id).toSet();
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = context.read<FlatProvider>().simulatedToday;
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: today, // ← usa fecha simulada como máximo
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_splitAmong.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Selecciona al menos una persona para repartir')),
      );
      return;
    }

    await context.read<ExpenseProvider>().addExpense(
          paidByPersonId: _paidByPersonId!,
          amount: double.parse(_amountCtrl.text.replaceAll(',', '.')),
          category: _category,
          description: _descCtrl.text.trim(),
          splitAmongIds: _splitAmong.toList(),
          date: _date,
        );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final people = context.watch<FlatProvider>().people;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo gasto'), centerTitle: true),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Importe (€)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.euro),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Campo requerido';
                final n = double.tryParse(v.replaceAll(',', '.'));
                if (n == null || n <= 0) return 'Importe no válido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            Text('Categoría:', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: ExpenseCategory.values
                  .map(
                    (cat) => ChoiceChip(
                      label: Text(cat.label),
                      selected: _category == cat,
                      onSelected: (_) => setState(() => _category = cat),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            Text('¿Quién ha pagado?', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _paidByPersonId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              items: people
                  .map((p) =>
                      DropdownMenuItem(value: p.id, child: Text(p.name)))
                  .toList(),
              onChanged: (v) => setState(() => _paidByPersonId = v),
            ),
            const SizedBox(height: 16),
            Text('Repartir entre:', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            ...people.map(
              (p) => CheckboxListTile(
                title: Text(p.name),
                value: _splitAmong.contains(p.id),
                onChanged: (val) => setState(() {
                  if (val == true) {
                    _splitAmong.add(p.id);
                  } else {
                    _splitAmong.remove(p.id);
                  }
                }),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Fecha del gasto'),
              subtitle: Text(
                  '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}'),
              onTap: _pickDate,
              tileColor: theme.colorScheme.surfaceVariant,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save),
              label: const Text('Guardar gasto'),
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
            ),
          ],
        ),
      ),
    );
  }
}