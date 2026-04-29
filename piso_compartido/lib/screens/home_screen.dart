import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/flat_provider.dart';
import '../utils/date_utils.dart';
import '../widgets/expense_card.dart';
import 'add_expense_screen.dart';
import 'settlement_screen.dart';
import 'summary_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final flat = context.watch<FlatProvider>();
    if (flat.periodJustClosed) {
      // Espera al siguiente frame para navegar
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettlementScreen()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final flatProvider = context.watch<FlatProvider>();
    final config = flatProvider.config!;
    final today = flatProvider.simulatedToday;
    final (start, end) = AppDateUtils.currentPeriod(config.billingDay, today);
    final periodExpenses = expenseProvider.currentPeriodExpenses();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos del piso'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Resumen',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SummaryScreen()),
            ),
          ),
          PopupMenuButton<String>(
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'settlement',
                child: Row(children: [
                  Icon(Icons.receipt_long),
                  SizedBox(width: 8),
                  Text('Ver liquidación'),
                ]),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(children: [
                  Icon(Icons.delete_forever, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Reiniciar configuración'),
                ]),
              ),
            ],
            onSelected: (v) {
              if (v == 'settlement') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SettlementScreen()),
                );
              } else if (v == 'reset') {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('¿Reiniciar?'),
                    content: const Text(
                        'Se borrarán todos los datos. Esta acción no se puede deshacer.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar')),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(context);
                          context.read<FlatProvider>().reset();
                          context.read<ExpenseProvider>().reset();
                        },
                        child: const Text('Reiniciar'),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _DateBanner(today: today, periodStart: start, periodEnd: end),
          Expanded(
            child: periodExpenses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long_outlined,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text('Sin gastos en este período',
                            style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: periodExpenses.length,
                    itemBuilder: (context, i) => ExpenseCard(
                      expense: periodExpenses[i],
                      people: flatProvider.people,
                      onDelete: () => expenseProvider
                          .removeExpense(periodExpenses[i].id),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Añadir gasto'),
      ),
    );
  }
}

class _DateBanner extends StatelessWidget {
  final DateTime today;
  final DateTime periodStart;
  final DateTime periodEnd;

  const _DateBanner({
    required this.today,
    required this.periodStart,
    required this.periodEnd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final flat = context.read<FlatProvider>();

    return Container(
      color: cs.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.today, size: 14, color: cs.onPrimaryContainer),
                    const SizedBox(width: 4),
                    Text(
                      'Hoy: ${AppDateUtils.format(today)}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onPrimaryContainer),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Período: ${AppDateUtils.format(periodStart)} → ${AppDateUtils.format(periodEnd)}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onPrimaryContainer),
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'Avanzar 1 día',
            child: IconButton(
              icon: const Icon(Icons.skip_next),
              color: cs.onPrimaryContainer,
              onPressed: () => flat.advanceDay(days: 1),
            ),
          ),
          Tooltip(
            message: 'Avanzar 7 días',
            child: IconButton(
              icon: const Icon(Icons.fast_forward),
              color: cs.onPrimaryContainer,
              onPressed: () => flat.advanceDay(days: 7),
            ),
          ),
          Tooltip(
            message: 'Volver a hoy',
            child: IconButton(
              icon: const Icon(Icons.restore),
              color: cs.onPrimaryContainer,
              onPressed: () => flat.resetSimulatedDate(),
            ),
          ),
        ],
      ),
    );
  }
}