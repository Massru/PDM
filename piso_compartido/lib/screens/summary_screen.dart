import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/flat_provider.dart';
import '../utils/date_utils.dart';
import '../widgets/person_balance_card.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final flatProvider = context.watch<FlatProvider>();
    final config = flatProvider.config!;
    final today = flatProvider.simulatedToday;
    final (start, end) =
        AppDateUtils.currentPeriod(config.billingDay, today);
    final balances = expenseProvider.computeBalances();
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
                  if (flatProvider.people.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Media por persona:'),
                        Text(
                          '${(total / flatProvider.people.length).toStringAsFixed(2)} €',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Balance por persona',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...balances.map((b) => PersonBalanceCard(balance: b)),
        ],
      ),
    );
  }
}