import 'package:flutter/material.dart';
import '../providers/expense_provider.dart';

class PersonBalanceCard extends StatelessWidget {
  final BalanceSummary balance;

  const PersonBalanceCard({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = balance.balance >= 0;
    final balanceColor =
        isPositive ? Colors.green.shade700 : Colors.red.shade700;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, size: 20),
                    const SizedBox(width: 8),
                    Text(balance.person.name,
                        style: theme.textTheme.titleMedium),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isPositive
                            ? Colors.green
                            : Colors.red)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: balanceColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    '${isPositive ? '+' : ''}${balance.balance.toStringAsFixed(2)} €',
                    style: TextStyle(
                        color: balanceColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _stat(context, 'Ha pagado',
                    '${balance.totalPaid.toStringAsFixed(2)} €'),
                _stat(context, 'Le corresponde',
                    '${balance.totalOwes.toStringAsFixed(2)} €'),
                _stat(
                  context,
                  isPositive ? 'Le deben' : 'Debe',
                  '${balance.balance.abs().toStringAsFixed(2)} €',
                  color: balanceColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value,
      {Color? color}) {
    return Column(
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}