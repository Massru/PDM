import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/flat_provider.dart';
import '../utils/date_utils.dart';
import '../widgets/person_balance_card.dart';

/// Pantalla de resumen del período actual.
/// Muestra el total gastado, la media por persona y el balance
/// individual de cada inquilino (quién debe y quién tiene crédito).
class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // watch en ambos providers para que la pantalla se actualice
    // si se añade un gasto mientras está abierta
    final expenseProvider = context.watch<ExpenseProvider>();
    final flatProvider = context.watch<FlatProvider>();
    final config = flatProvider.config!;
    final today = flatProvider.simulatedToday;

    // Calculamos el período usando la fecha simulada
    final (start, end) =
        AppDateUtils.currentPeriod(config.billingDay, today);

    // computeBalances() hace todos los cálculos de quién debe qué
    final balances = expenseProvider.computeBalances();

    // Total del período: suma de todos los gastos (no de los balances,
    // que se compensan entre sí y sumarían 0)
    final total = expenseProvider
        .currentPeriodExpenses()
        .fold<double>(0, (s, e) => s + e.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen del período'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Tarjeta de totales ───────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Período actual',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    '${AppDateUtils.format(start)} → ${AppDateUtils.format(end)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total gastado:'),
                      Text(
                        '${total.toStringAsFixed(2)} €',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  // Solo mostramos la media si hay personas en el piso
                  if (flatProvider.people.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Media por persona:'),
                        Text(
                          '${(total / flatProvider.people.length).toStringAsFixed(2)} €',
                          style:
                              Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Balance individual ───────────────────────────────────────
          Text('Balance por persona',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          // Mapeamos cada balance a su tarjeta visual
          ...balances.map((b) => PersonBalanceCard(balance: b)),
        ],
      ),
    );
  }
}