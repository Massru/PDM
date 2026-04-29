import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/settlement.dart';
import '../providers/expense_provider.dart';
import '../providers/flat_provider.dart';
import '../utils/date_utils.dart';
import '../models/person.dart';

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
    if (!_initialized) {
      _settlement = context.read<ExpenseProvider>().computeSettlement();
      _initialized = true;
    }
  }

  String _name(String id) {
  final people = context.read<FlatProvider>().people;
  return people.firstWhere((p) => p.id == id, orElse: () => Person(id: '', name: '?')).name;
}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final flat = context.read<FlatProvider>();
    final config = flat.config!;
    final people = flat.people;

    final pendingTransfers =
        _settlement.transfers.where((t) => !t.isPaid).toList();
    final paidTransfers =
        _settlement.transfers.where((t) => t.isPaid).toList();
    final allSettled = pendingTransfers.isEmpty;

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
          // ── Cabecera del período ───────────────────────────────────
          Card(
            color: cs.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Período cerrado',
                      style: theme.textTheme.titleMedium?.copyWith(
                          color: cs.onPrimaryContainer)),
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

          // ── Gastos fijos del período ───────────────────────────────
          if (config.fixedExpenseAmounts.isNotEmpty &&
              config.fixedExpenseAmounts.values.any((v) => v > 0)) ...[
            Text('Gastos fijos repartidos',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    ...config.fixedExpenseCategories.map((cat) {
                      final total =
                          config.fixedExpenseAmounts[cat] ?? 0.0;
                      if (total <= 0) return const SizedBox.shrink();
                      final share = total / people.length;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(cat,
                                style: theme.textTheme.bodyMedium),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${total.toStringAsFixed(2)} € total',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant),
                                ),
                                Text(
                                  '${share.toStringAsFixed(2)} € / persona',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Balance neto por persona ───────────────────────────────
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
                  final color =
                      isPos ? Colors.green.shade700 : Colors.red.shade700;
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

          // ── Transferencias necesarias ──────────────────────────────
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
                    Text('¡Todo cuadrado! Nadie debe nada a nadie.',
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          else ...[
            if (pendingTransfers.isNotEmpty) ...[
              ...pendingTransfers.map(
                (t) => _TransferTile(
                  transfer: t,
                  fromName: _name(t.fromPersonId),
                  toName: _name(t.toPersonId),
                  onToggle: () => setState(() => t.isPaid = !t.isPaid),
                ),
              ),
            ],
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
                  onToggle: () => setState(() => t.isPaid = !t.isPaid),
                ),
              ),
            ],
          ],

          const SizedBox(height: 24),

          // ── Botón de cerrar ────────────────────────────────────────
          if (allSettled || _settlement.transfers.every((t) => t.isPaid))
            FilledButton.icon(
              onPressed: () {
                context.read<FlatProvider>().acknowledgePeriodClosed();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.done_all),
              label: const Text('Cerrar período'),
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: Colors.green.shade600),
            )
          else
            OutlinedButton.icon(
              onPressed: () {
                context.read<FlatProvider>().acknowledgePeriodClosed();
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
          backgroundColor:
              isPaid ? Colors.green.shade100 : theme.colorScheme.errorContainer,
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
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(text: ' → '),
              TextSpan(
                  text: toName,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        subtitle: Text(
          isPaid ? 'Pagado' : 'Pendiente',
          style: TextStyle(
            color: isPaid ? Colors.green.shade700 : theme.colorScheme.error,
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
                decoration: isPaid ? TextDecoration.lineThrough : null,
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
