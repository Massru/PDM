import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flat_provider.dart';
import '../utils/constants.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _flatNameCtrl = TextEditingController();
  int _numPeople = 2;
  final List<TextEditingController> _nameControllers = [];
  final Set<String> _selectedCategories = {};
  final Map<String, TextEditingController> _amountControllers = {};
  int _billingDay = 1;

  @override
  void initState() {
    super.initState();
    _selectedCategories.addAll(AppConstants.defaultFixedCategories);
    _rebuildControllers();
    _syncAmountControllers();
  }

  void _rebuildControllers() {
    for (final c in _nameControllers) c.dispose();
    _nameControllers.clear();
    for (int i = 0; i < _numPeople; i++) {
      _nameControllers.add(TextEditingController());
    }
  }

  void _syncAmountControllers() {
    for (final cat in _selectedCategories) {
      _amountControllers.putIfAbsent(cat, () => TextEditingController());
    }
    _amountControllers.removeWhere((cat, ctrl) {
      if (!_selectedCategories.contains(cat)) {
        ctrl.dispose();
        return true;
      }
      return false;
    });
  }

  @override
  void dispose() {
    _flatNameCtrl.dispose();
    for (final c in _nameControllers) c.dispose();
    for (final c in _amountControllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final names = _nameControllers.map((c) => c.text.trim()).toList();
    final amounts = <String, double>{};
    for (final cat in _selectedCategories) {
      final raw = _amountControllers[cat]?.text.replaceAll(',', '.') ?? '';
      amounts[cat] = double.tryParse(raw) ?? 0.0;
    }

    final flatProvider = context.read<FlatProvider>();

    await flatProvider.setupFlat(
      flatName: _flatNameCtrl.text.trim().isEmpty
          ? 'Mi piso'
          : _flatNameCtrl.text.trim(),
      names: names,
      fixedCategories: _selectedCategories.toList(),
      fixedAmounts: amounts,
      billingDay: _billingDay,
    );

    await flatProvider.deactivateFlat();

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final billingDayItems = [
      ...List.generate(
        28,
        (i) => DropdownMenuItem<int>(
            value: i + 1, child: Text('Día ${i + 1}')),
      ),
      const DropdownMenuItem<int>(
          value: 0, child: Text('Último día del mes')),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar piso'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Nombre del piso ──────────────────────────────────────
            Text('Nombre del piso:', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _flatNameCtrl,
              decoration: const InputDecoration(
                hintText: 'Ej: Piso Rúa do Demo',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
              ),
            ),

            // ── Número de personas ───────────────────────────────────
            const SizedBox(height: 20),
            Text('¿Cuántas personas vivís?',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: _numPeople > 1
                      ? () => setState(() {
                            _numPeople--;
                            _rebuildControllers();
                          })
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$_numPeople', style: theme.textTheme.headlineSmall),
                IconButton(
                  onPressed: _numPeople < 10
                      ? () => setState(() {
                            _numPeople++;
                            _rebuildControllers();
                          })
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),

            // ── Nombres de los inquilinos ────────────────────────────
            const SizedBox(height: 16),
            Text('Nombres de los inquilinos:',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...List.generate(
              _numPeople,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextFormField(
                  controller: _nameControllers[i],
                  decoration: InputDecoration(
                    hintText: 'Persona ${i + 1}',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Campo requerido'
                      : null,
                ),
              ),
            ),

            // ── Gastos fijos ─────────────────────────────────────────
            const SizedBox(height: 20),
            Text('Gastos fijos del piso:',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Selecciona los gastos fijos e indica el importe mensual.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ...AppConstants.defaultFixedCategories,
                ...AppConstants.variableCategories,
              ]
                  .map(
                    (cat) => FilterChip(
                      label: Text(cat),
                      selected: _selectedCategories.contains(cat),
                      onSelected: (val) => setState(() {
                        if (val) {
                          _selectedCategories.add(cat);
                        } else {
                          _selectedCategories.remove(cat);
                        }
                        _syncAmountControllers();
                      }),
                    ),
                  )
                  .toList(),
            ),
            if (_selectedCategories.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.surfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Importe mensual por categoría:',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      'Los gastos fijos marcados con * son obligatorios.',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 10),
                    ..._selectedCategories.map(
                      (cat) {
                        // Una categoría es "fija" si está en la lista
                        // de categorías fijas por defecto
                        final isFixed = AppConstants
                            .defaultFixedCategories
                            .contains(cat);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            controller: _amountControllers[cat],
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            decoration: InputDecoration(
                              // El asterisco indica campo obligatorio
                              hintText: '0.00',
                              labelText:
                                  isFixed ? '$cat *' : cat,
                              border: const OutlineInputBorder(),
                              suffixText: '€',
                              isDense: true,
                            ),
                            validator: (v) {
                              final raw =
                                  v?.replaceAll(',', '.') ?? '';
                              final n = double.tryParse(raw);

                              if (isFixed) {
                                // Para gastos fijos el importe
                                // es obligatorio y debe ser > 0
                                if (raw.isEmpty || n == null) {
                                  return 'Introduce el importe';
                                }
                                if (n <= 0) {
                                  return 'Debe ser mayor que 0';
                                }
                              } else {
                                // Para gastos variables es opcional,
                                // pero si se rellena debe ser válido
                                if (raw.isNotEmpty &&
                                    (n == null || n < 0)) {
                                  return 'Importe no válido';
                                }
                              }
                              return null;
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],

            // ── Día de cierre ────────────────────────────────────────
            const SizedBox(height: 20),
            Text('Día de cierre del período:',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _billingDay,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              items: billingDayItems,
              onChanged: (v) => setState(() => _billingDay = v!),
            ),

            // ── Botón ────────────────────────────────────────────────
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check),
              label: const Text('Empezar'),
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
            ),
          ],
        ),
      ),
    );
  }
}