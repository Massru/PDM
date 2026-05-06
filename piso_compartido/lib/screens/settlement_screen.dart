import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/person.dart';
import '../models/settlement.dart';
import '../providers/expense_provider.dart';
import '../providers/flat_provider.dart';
import '../utils/date_utils.dart';

class SettlementScreen extends StatefulWidget {
  const SettlementScreen({super.key});

  @override
  State<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends State<SettlementScreen> {
  late Settlement _settlement;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Calculamos el settlement solo la primera vez para que marcar
    // checkboxes no resetee el estado
    if (!_initialized) {
      _settlement =
          context.read<ExpenseProvider>().computeSettlement();
      _initialized = true;
    }
  }

  String _name(String id) {
    final people = context.read<FlatProvider>().people;
    return people
        .firstWhere((p) => p.id == id,
            orElse: () => const Person(id: '', name: '?'))
        .name;
  }

  /// Cierra el período:
  ///   1. Elimina todos los gastos del período cerrado
  ///   2. Avanza la fecha simulada al día siguiente
  ///   3. Desactiva la flag periodJustClosed
  ///   4. Vuelve a HomeScreen ya en el nuevo período
  Future<void> _closePeriod() async {
    final flat = context.read<FlatProvider>();
    final expenseProvider = context.read<ExpenseProvider>();

    // Borramos todos los gastos del período cerrado
    final toDelete = List.from(
        expenseProvider.currentPeriodExpenses().map((e) => e.id));
    for (final id in toDelete) {
      await expenseProvider.removeExpense(id);
    }

    // Avanzamos un día para entrar en el nuevo período
    flat.advanceDay(days: 1);

    // Desactivamos la flag
    flat.acknowledgePeriodClosed();

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final flat = context.watch<FlatProvider>();
    final config = flat.config!;
    final people = flat.people;

    final pendingTransfers =
        _settlement.transfers.where((t) => !t.isPaid).toList();
    final paidTransfers =
        _settlement.transfers.where((t) => t.isPaid).toList();

    // Todas las transferencias están pagadas (o no hay ninguna)
    final allSettled = _settlement.transfers.isEmpty ||
        _settlement.transfers.every((t) => t.isPaid);

    // Hoy es exactamente el día de cierre del período
    final isTodayClosingDay = flat.isTodayClosingDay;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liquidación del período'),
        centerTitle: true,
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Cabecera del período ─────────────────────────────────────
          Card(
            color: cs.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Período cerrado',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: cs.onPrimaryContainer)),
                  const SizedBox(height: 4),
                  Text(
                    '${AppDateUtils.format(_settlement.periodStart)} → ${AppDateUtils.format(_settlement.periodEnd)}',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.onPrimaryContainer),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Gastos fijos ─────────────────────────────────────────────
          if (config.fixedExpenseAmounts.isNotEmpty &&
              config.fixedExpenseAmounts.values.any((v) => v > 0)) ...[
            Text('Gastos fijos repartidos',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: config.fixedExpenseCategories.map((cat) {
                    final total =
                        config.fixedExpenseAmounts[cat] ?? 0.0;
                    if (total <= 0) return const SizedBox.shrink();
                    final share = total / people.length;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(cat,
                              style: theme.textTheme.bodyMedium),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${total.toStringAsFixed(2)} € total',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(
                                        color: cs.onSurfaceVariant),
                              ),
                              Text(
                                '${share.toStringAsFixed(2)} € / persona',
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(
                                        fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Balance neto por persona ─────────────────────────────────
          Text('Balance neto por persona',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: people.map((p) {
                  final bal = _settlement.netBalance[p.id] ?? 0.0;
                  final isPos = bal >= 0;
                  final color = isPos
                      ? Colors.green.shade700
                      : Colors.red.shade700;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        const Icon(Icons.person, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(p.name,
                                style: theme.textTheme.bodyMedium)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: (isPos ? Colors.green : Colors.red)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: color.withOpacity(0.4)),
                          ),
                          child: Text(
                            '${isPos ? '+' : ''}${bal.toStringAsFixed(2)} €',
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Transferencias necesarias ────────────────────────────────
          Text('Transferencias necesarias',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Marca cada transferencia cuando se haya realizado.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),

          if (_settlement.transfers.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 48, color: Colors.green.shade600),
                    const SizedBox(height: 8),
                    Text(
                      '¡Todo cuadrado! Nadie debe nada a nadie.',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else ...[
            if (pendingTransfers.isNotEmpty)
              ...pendingTransfers.map(
                (t) => _TransferTile(
                  transfer: t,
                  fromName: _name(t.fromPersonId),
                  toName: _name(t.toPersonId),
                  onToggle: () =>
                      setState(() => t.isPaid = !t.isPaid),
                ),
              ),
            if (paidTransfers.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Pagadas',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 4),
              ...paidTransfers.map(
                (t) => _TransferTile(
                  transfer: t,
                  fromName: _name(t.fromPersonId),
                  toName: _name(t.toPersonId),
                  onToggle: () =>
                      setState(() => t.isPaid = !t.isPaid),
                ),
              ),
            ],
          ],

          const SizedBox(height: 24),

          // ── Botón de cierre ──────────────────────────────────────────
          // Tres estados posibles:
          //   1. allSettled + isTodayClosingDay → botón verde activo
          //   2. allSettled + !isTodayClosingDay → botón deshabilitado
          //      con mensaje explicativo
          //   3. !allSettled → solo "Cerrar sin completar"
          if (allSettled && isTodayClosingDay)
            FilledButton.icon(
              onPressed: _closePeriod,
              icon: const Icon(Icons.done_all),
              label: const Text('Cerrar período e iniciar el siguiente'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: Colors.green.shade600,
              ),
            )
          else if (allSettled && !isTodayClosingDay)
            Column(
              children: [
                FilledButton.icon(
                  onPressed: null, // deshabilitado
                  icon: const Icon(Icons.done_all),
                  label:
                      const Text('Cerrar período e iniciar el siguiente'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'El botón se activará el día de cierre del período.',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            )
          else
            OutlinedButton.icon(
              onPressed: () {
                context
                    .read<FlatProvider>()
                    .acknowledgePeriodClosed();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.close),
              label: const Text('Cerrar sin completar'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Widget para mostrar una transferencia individual con checkbox.
class _TransferTile extends StatelessWidget {
  final Transfer transfer;
  final String fromName;
  final String toName;
  final VoidCallback onToggle;

  const _TransferTile({
    required this.transfer,
    required this.fromName,
    required this.toName,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPaid = transfer.isPaid;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isPaid
          ? Colors.green.shade50
          : theme.colorScheme.surface,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPaid
              ? Colors.green.shade100
              : theme.colorScheme.errorContainer,
          child: Icon(
            isPaid ? Icons.check : Icons.arrow_forward,
            color: isPaid
                ? Colors.green.shade700
                : theme.colorScheme.onErrorContainer,
            size: 20,
          ),
        ),
        title: RichText(
          text: TextSpan(
            style: theme.textTheme.bodyMedium,
            children: [
              TextSpan(
                  text: fromName,
                  style:
                      const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: ' → '),
              TextSpan(
                  text: toName,
                  style:
                      const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        subtitle: Text(
          isPaid ? 'Pagado' : 'Pendiente',
          style: TextStyle(
            color: isPaid
                ? Colors.green.shade700
                : theme.colorScheme.error,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${transfer.amount.toStringAsFixed(2)} €',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                decoration:
                    isPaid ? TextDecoration.lineThrough : null,
                color: isPaid ? Colors.grey : null,
              ),
            ),
            const SizedBox(width: 8),
            Checkbox(
              value: isPaid,
              onChanged: (_) => onToggle(),
              activeColor: Colors.green.shade600,
            ),
          ],
        ),
      ),
    );
  }
}