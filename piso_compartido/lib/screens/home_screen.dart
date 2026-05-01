import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/flat_provider.dart';
import '../utils/date_utils.dart';
import '../widgets/expense_card.dart';
import 'add_expense_screen.dart';
import 'settlement_screen.dart';
import 'setup_screen.dart';
import 'summary_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// didChangeDependencies se llama cuando cambia algún provider que
  /// este widget escucha. Lo usamos para detectar el cierre de período
  /// y navegar a SettlementScreen sin bloquear el build.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final flat = context.watch<FlatProvider>();
    if (flat.periodJustClosed) {
      // addPostFrameCallback garantiza que la navegación ocurre después
      // de que el build actual termine, evitando errores de Flutter
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
      // ── Drawer lateral ───────────────────────────────────────────
      drawer: _FlatsDrawer(
        flats: flatProvider.flats,
        activeFlatId: config.id,
        onSwitch: (id) async {
          // Al cambiar de piso, ExpenseProvider detecta el cambio de ID
          // y recarga los gastos automáticamente
          await flatProvider.switchFlat(id);
          if (context.mounted) Navigator.pop(context);
        },
        onNew: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SetupScreen()),
          );
        },
        onDelete: () async {
          Navigator.pop(context);
          final confirm = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('¿Eliminar piso?'),
              content: Text(
                  'Se eliminará "${config.name}" y todos sus gastos. Esta acción no se puede deshacer.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar')),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                      backgroundColor: Colors.red),
                  child: const Text('Eliminar'),
                ),
              ],
            ),
          );
          if (confirm == true && context.mounted) {
            context.read<ExpenseProvider>().reset();
            await context.read<FlatProvider>().deleteActiveFlat();
          }
        },
      ),

      appBar: AppBar(
        // El título del AppBar muestra el nombre del piso activo
        title: Text(config.name),
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
            ],
            onSelected: (v) {
              if (v == 'settlement') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SettlementScreen()),
                );
              }
            },
          ),
        ],
      ),

      body: Column(
        children: [
          // Banner con la fecha simulada y los controles de simulación
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
                            style:
                                Theme.of(context).textTheme.bodyLarge),
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

/// Drawer que lista todos los pisos guardados y permite cambiar entre ellos.
/// Se extrae como widget separado para mantener el build() de HomeScreen limpio.
class _FlatsDrawer extends StatelessWidget {
  final List<dynamic> flats;
  final String activeFlatId;
  final void Function(String id) onSwitch;
  final VoidCallback onNew;
  final VoidCallback onDelete;

  const _FlatsDrawer({
    required this.flats,
    required this.activeFlatId,
    required this.onSwitch,
    required this.onNew,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: cs.primaryContainer),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'Mis pisos',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(color: cs.onPrimaryContainer),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: flats.map((flat) {
                final isActive = flat.id == activeFlatId;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        isActive ? cs.primary : cs.surfaceVariant,
                    child: Icon(Icons.home,
                        color: isActive
                            ? cs.onPrimary
                            : cs.onSurfaceVariant,
                        size: 20),
                  ),
                  title: Text(flat.name,
                      style: TextStyle(
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.normal)),
                  subtitle: Text(
                      '${flat.people.length} personas · ${flat.billingDayLabel}'),
                  selected: isActive,
                  selectedTileColor:
                      cs.primaryContainer.withOpacity(0.3),
                  // El piso activo no es tappable (ya estás en él)
                  onTap: isActive ? null : () => onSwitch(flat.id),
                  trailing:
                      isActive ? const Icon(Icons.check, size: 18) : null,
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
          // Opciones fijas al fondo del drawer
          ListTile(
            leading: const Icon(Icons.add_home),
            title: const Text('Nuevo piso'),
            onTap: onNew,
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline,
                color: Colors.redAccent),
            title: const Text('Eliminar piso actual',
                style: TextStyle(color: Colors.redAccent)),
            onTap: onDelete,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Banner superior con la fecha simulada y los botones de control de simulación.
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
    // context.read en lugar de watch porque este widget no necesita
    // reconstruirse, solo ejecutar acciones
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
                Row(children: [
                  Icon(Icons.today, size: 14, color: cs.onPrimaryContainer),
                  const SizedBox(width: 4),
                  Text(
                    'Hoy: ${AppDateUtils.format(today)}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onPrimaryContainer),
                  ),
                ]),
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