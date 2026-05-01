import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import '../models/person.dart';
import '../models/settlement.dart';
import '../providers/flat_provider.dart';
import '../utils/date_utils.dart';
import '../utils/storage_service.dart';

/// Resumen del balance de una persona en el período actual.
/// Se usa en SummaryScreen y en el cálculo de liquidación.
class BalanceSummary {
  final Person person;
  final double totalPaid; // Lo que ha pagado adelantando dinero
  final double totalOwes; // Lo que le corresponde pagar según los repartos
  final double balance;   // totalPaid - totalOwes
                          // positivo = le deben dinero
                          // negativo = debe dinero

  const BalanceSummary({
    required this.person,
    required this.totalPaid,
    required this.totalOwes,
    required this.balance,
  });
}

/// Provider que gestiona todos los gastos del piso activo.
///
/// Se conecta a FlatProvider mediante ChangeNotifierProxyProvider en main.dart,
/// lo que significa que recibe una llamada a update() cada vez que
/// FlatProvider notifica cambios. Esto nos permite recargar los gastos
/// automáticamente al cambiar de piso.
class ExpenseProvider with ChangeNotifier {
  List<Expense> _expenses = [];
  FlatProvider? _flatProvider;
  String? _loadedForFlatId; // ID del piso cuyos gastos están en memoria

  List<Expense> get expenses => List.unmodifiable(_expenses);

  /// Llamado por el ProxyProvider cada vez que FlatProvider cambia.
  /// La clave está en comparar el ID del piso activo con el que
  /// tenemos cargado: si son distintos, recargamos desde disco.
  /// Así evitamos el bug original donde se recargaba en cada notificación.
  void update(FlatProvider flat) {
    final newFlatId = flat.config?.id;
    _flatProvider = flat;

    if (flat.isConfigured && newFlatId != _loadedForFlatId) {
      _loadedForFlatId = newFlatId;
      _loadExpenses();
    }
  }

  Future<void> _loadExpenses() async {
    // Usamos la clave específica del piso activo
    final key = _flatProvider!.expensesKey;
    _expenses = await StorageService.loadList(key, Expense.fromJson);
    notifyListeners();
  }

  Future<void> _save() async {
    final key = _flatProvider!.expensesKey;
    await StorageService.save(
      key,
      _expenses.map((e) => e.toJson()).toList(),
    );
  }

  Future<void> addExpense({
    required String paidByPersonId,
    required double amount,
    required ExpenseCategory category,
    required String description,
    required List<String> splitAmongIds,
    DateTime? date,
  }) async {
    const uuid = Uuid();
    final expense = Expense(
      id: uuid.v4(),
      paidByPersonId: paidByPersonId,
      amount: amount,
      category: category,
      description: description,
      date: date ?? DateTime.now(),
      splitAmongIds: splitAmongIds,
    );
    // Añadimos en memoria primero para que la UI responda inmediatamente,
    // luego guardamos en disco de forma asíncrona
    _expenses.add(expense);
    await _save();
    notifyListeners();
  }

  Future<void> removeExpense(String id) async {
    _expenses.removeWhere((e) => e.id == id);
    await _save();
    notifyListeners();
  }

  /// Reset completo al cambiar/eliminar piso.
  void reset() {
    _expenses = [];
    _loadedForFlatId = null;
    notifyListeners();
  }

  /// Filtra los gastos que pertenecen al período activo.
  /// El período se calcula en función de la fecha simulada actual.
  List<Expense> currentPeriodExpenses() {
    final billingDay = _flatProvider?.config?.billingDay;
    if (billingDay == null) return [];
    final today = _flatProvider!.simulatedToday;
    return _expenses
        .where((e) =>
            AppDateUtils.isInCurrentPeriod(e.date, billingDay, today))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // más recientes primero
  }

  List<BalanceSummary> computeBalances() {
    final people = _flatProvider?.people ?? [];
    if (people.isEmpty) return [];

    final periodExpenses = currentPeriodExpenses();
    final Map<String, double> totalPaid = {for (var p in people) p.id: 0.0};
    final Map<String, double> totalOwes = {for (var p in people) p.id: 0.0};

    for (final expense in periodExpenses) {
      totalPaid[expense.paidByPersonId] =
          (totalPaid[expense.paidByPersonId] ?? 0) + expense.amount;
      for (final personId in expense.splitAmongIds) {
        totalOwes[personId] =
            (totalOwes[personId] ?? 0) + expense.sharePerPerson;
      }
    }

    return people.map((p) {
      final paid = totalPaid[p.id] ?? 0;
      final owes = totalOwes[p.id] ?? 0;
      return BalanceSummary(
        person: p,
        totalPaid: paid,
        totalOwes: owes,
        balance: paid - owes,
      );
    }).toList();
  }

  /// Calcula la liquidación completa del período actual.
  ///
  /// El proceso es:
  ///   1. Gastos fijos: se reparten igualmente entre todos los inquilinos.
  ///      Cada persona debe su parte, independientemente de quién haya
  ///      pagado la factura (si nadie la registró, la deuda queda pendiente).
  ///   2. Gastos variables: quien pagó suma en su balance,
  ///      quienes comparten el gasto restan su parte.
  ///   3. Con el balance neto de cada persona, calculamos las transferencias
  ///      mínimas para saldar todo.
  Settlement computeSettlement() {
    final flat = _flatProvider!;
    final config = flat.config!;
    final people = flat.people;
    final today = flat.simulatedToday;
    final (start, end) = AppDateUtils.currentPeriod(config.billingDay, today);

    // Balance neto: empezamos en 0 para todos
    final Map<String, double> net = {for (var p in people) p.id: 0.0};
    final Map<String, double> fixedOwed = {};
    final double numPeople = people.length.toDouble();

    // 1. Aplicar gastos fijos: todos deben su parte
    for (final cat in config.fixedExpenseCategories) {
      final amount = config.fixedExpenseAmounts[cat] ?? 0.0;
      if (amount <= 0) continue;
      final share = amount / numPeople;
      fixedOwed[cat] = share;
      for (final p in people) {
        net[p.id] = (net[p.id] ?? 0) - share;
      }
    }

    // 2. Aplicar gastos variables del período
    final Map<String, double> variablePaid = {for (var p in people) p.id: 0.0};
    final periodExpenses = _expenses
        .where((e) => !e.date.isBefore(start) && !e.date.isAfter(end))
        .toList();

    for (final expense in periodExpenses) {
      // Quien pagó recupera su dinero
      net[expense.paidByPersonId] =
          (net[expense.paidByPersonId] ?? 0) + expense.amount;
      variablePaid[expense.paidByPersonId] =
          (variablePaid[expense.paidByPersonId] ?? 0) + expense.amount;
      // Cada persona que comparte el gasto debe su parte
      for (final personId in expense.splitAmongIds) {
        net[personId] = (net[personId] ?? 0) - expense.sharePerPerson;
      }
    }

    final transfers = _minimizeTransfers(net, people);

    return Settlement(
      periodStart: start,
      periodEnd: end,
      transfers: transfers,
      fixedOwed: fixedOwed,
      variablePaid: variablePaid,
      netBalance: net,
    );
  }

  /// Algoritmo greedy para calcular el mínimo número de transferencias
  /// que saldan todas las deudas del período.
  ///
  /// ALGORITMO:
  ///   1. Separamos personas en deudores (net < 0) y acreedores (net > 0)
  ///   2. El mayor deudor paga al mayor acreedor todo lo que pueda
  ///   3. El que queda a 0 sale de la lista, el otro continúa
  ///   4. Repetimos hasta que todos estén a 0
  ///
  /// Esto garantiza que nunca necesitamos más transferencias que (n-1)
  /// siendo n el número de personas, y normalmente son bastante menos.
  List<Transfer> _minimizeTransfers(
      Map<String, double> net, List<Person> people) {
    // Trabajamos con listas mutables de [id, saldo]
    final debtors = people
        .where((p) => (net[p.id] ?? 0) < -0.01) // umbral para evitar
        .map((p) => [p.id, net[p.id]!])          // imprecisiones de float
        .toList()
      ..sort((a, b) => (a[1] as double).compareTo(b[1] as double));

    final creditors = people
        .where((p) => (net[p.id] ?? 0) > 0.01)
        .map((p) => [p.id, net[p.id]!])
        .toList()
      ..sort((a, b) => (b[1] as double).compareTo(a[1] as double));

    final transfers = <Transfer>[];
    int di = 0, ci = 0;

    while (di < debtors.length && ci < creditors.length) {
      final debtorId = debtors[di][0] as String;
      final creditorId = creditors[ci][0] as String;
      final debt = -(debtors[di][1] as double);   // lo que debe (positivo)
      final credit = creditors[ci][1] as double;   // lo que le deben

      // La transferencia es el mínimo entre lo que debe y lo que le deben
      final amount = debt < credit ? debt : credit;

      if (amount > 0.01) {
        transfers.add(Transfer(
          fromPersonId: debtorId,
          toPersonId: creditorId,
          // Redondeamos a 2 decimales para evitar 33.333333...
          amount: double.parse(amount.toStringAsFixed(2)),
        ));
      }

      // Actualizamos los saldos restantes
      debtors[di][1] = (debtors[di][1] as double) + amount;
      creditors[ci][1] = (creditors[ci][1] as double) - amount;

      // Si alguien quedó a 0, avanzamos al siguiente
      if ((debtors[di][1] as double).abs() < 0.01) di++;
      if ((creditors[ci][1] as double).abs() < 0.01) ci++;
    }

    return transfers;
  }
}