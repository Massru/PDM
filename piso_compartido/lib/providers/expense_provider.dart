import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import '../models/person.dart';
import '../models/settlement.dart';
import '../providers/flat_provider.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';
import '../utils/storage_service.dart';

class BalanceSummary {
  final Person person;
  final double totalPaid;
  final double totalOwes;
  final double balance;

  const BalanceSummary({
    required this.person,
    required this.totalPaid,
    required this.totalOwes,
    required this.balance,
  });
}

class ExpenseProvider with ChangeNotifier {
  List<Expense> _expenses = [];
  FlatProvider? _flatProvider;
  bool _loaded = false;

  List<Expense> get expenses => List.unmodifiable(_expenses);

  void update(FlatProvider flat) {
    _flatProvider = flat;
    if (flat.isConfigured && !_loaded) {
      _loaded = true;
      _loadExpenses();
    }
  }

  Future<void> _loadExpenses() async {
    _expenses = await StorageService.loadList(
      AppConstants.prefKeyExpenses,
      Expense.fromJson,
    );
    notifyListeners();
  }

  Future<void> _save() async {
    await StorageService.save(
      AppConstants.prefKeyExpenses,
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
    _expenses.add(expense);
    await _save();
    notifyListeners();
  }

  Future<void> removeExpense(String id) async {
    _expenses.removeWhere((e) => e.id == id);
    await _save();
    notifyListeners();
  }

  void reset() {
    _expenses = [];
    _loaded = false;
    notifyListeners();
  }

  List<Expense> currentPeriodExpenses() {
    final billingDay = _flatProvider?.config?.billingDay;
    if (billingDay == null) return [];
    final today = _flatProvider!.simulatedToday;
    return _expenses
        .where((e) => AppDateUtils.isInCurrentPeriod(e.date, billingDay, today))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
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
  /// Incluye gastos fijos (repartidos igualmente entre todos) +
  /// gastos variables registrados. Luego calcula las transferencias
  /// mínimas para saldar todas las deudas.
  Settlement computeSettlement() {
    final flat = _flatProvider!;
    final config = flat.config!;
    final people = flat.people;
    final today = flat.simulatedToday;
    final (start, end) = AppDateUtils.currentPeriod(config.billingDay, today);

    // Balance neto por persona en euros
    // positivo = le deben dinero, negativo = debe dinero
    final Map<String, double> net = {for (var p in people) p.id: 0.0};

    // 1. Gastos fijos: se reparten a partes iguales entre todos.
    //    Se considera que "el piso" los debe, no una persona concreta.
    //    Cada persona debe su parte; si alguien ya pagó una factura
    //    de esa categoría en el período, se le acredita.
    final Map<String, double> fixedOwed = {};
    final double numPeople = people.length.toDouble();

    for (final cat in config.fixedExpenseCategories) {
      final amount = config.fixedExpenseAmounts[cat] ?? 0.0;
      if (amount <= 0) continue;
      final share = amount / numPeople;
      fixedOwed[cat] = share;
      // Todos deben su parte
      for (final p in people) {
        net[p.id] = (net[p.id] ?? 0) - share;
      }
    }

    // 2. Gastos variables del período: quien pagó suma, quienes deben restan
    final Map<String, double> variablePaid = {for (var p in people) p.id: 0.0};
    final periodExpenses = _expenses.where((e) {
      return !e.date.isBefore(start) && !e.date.isAfter(end);
    }).toList();

    for (final expense in periodExpenses) {
      // El que pagó recupera lo que puso
      net[expense.paidByPersonId] =
          (net[expense.paidByPersonId] ?? 0) + expense.amount;
      variablePaid[expense.paidByPersonId] =
          (variablePaid[expense.paidByPersonId] ?? 0) + expense.amount;
      // Cada persona que comparte el gasto debe su parte
      for (final personId in expense.splitAmongIds) {
        net[personId] = (net[personId] ?? 0) - expense.sharePerPerson;
      }
    }

    // 3. Algoritmo de liquidación mínima (greedy deudor/acreedor)
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

  /// Dado un mapa de balances netos, calcula las transferencias mínimas.
  List<Transfer> _minimizeTransfers(
      Map<String, double> net, List<Person> people) {
    // Separar deudores (net < 0) y acreedores (net > 0)
    final debtors = people
        .where((p) => (net[p.id] ?? 0) < -0.01)
        .map((p) => [p.id, net[p.id]!])
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
      final debt = -(debtors[di][1] as double);
      final credit = creditors[ci][1] as double;

      final amount = debt < credit ? debt : credit;
      if (amount > 0.01) {
        transfers.add(Transfer(
          fromPersonId: debtorId,
          toPersonId: creditorId,
          amount: double.parse(amount.toStringAsFixed(2)),
        ));
      }

      debtors[di][1] = (debtors[di][1] as double) + amount;
      creditors[ci][1] = (creditors[ci][1] as double) - amount;

      if ((debtors[di][1] as double).abs() < 0.01) di++;
      if ((creditors[ci][1] as double).abs() < 0.01) ci++;
    }

    return transfers;
  }
}