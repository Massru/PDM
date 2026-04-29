import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import '../models/person.dart';
import '../models/settlement.dart';
import '../providers/flat_provider.dart';
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
  String? _loadedForFlatId;

  List<Expense> get expenses => List.unmodifiable(_expenses);

  void update(FlatProvider flat) {
    final newFlatId = flat.config?.id;
    _flatProvider = flat;

    // Recargar si cambiamos de piso o es la primera carga
    if (flat.isConfigured && newFlatId != _loadedForFlatId) {
      _loadedForFlatId = newFlatId;
      _loadExpenses();
    }
  }

  Future<void> _loadExpenses() async {
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
    _loadedForFlatId = null;
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

  Settlement computeSettlement() {
    final flat = _flatProvider!;
    final config = flat.config!;
    final people = flat.people;
    final today = flat.simulatedToday;
    final (start, end) = AppDateUtils.currentPeriod(config.billingDay, today);

    final Map<String, double> net = {for (var p in people) p.id: 0.0};
    final Map<String, double> fixedOwed = {};
    final double numPeople = people.length.toDouble();

    for (final cat in config.fixedExpenseCategories) {
      final amount = config.fixedExpenseAmounts[cat] ?? 0.0;
      if (amount <= 0) continue;
      final share = amount / numPeople;
      fixedOwed[cat] = share;
      for (final p in people) {
        net[p.id] = (net[p.id] ?? 0) - share;
      }
    }

    final Map<String, double> variablePaid = {for (var p in people) p.id: 0.0};
    final periodExpenses = _expenses.where((e) {
      return !e.date.isBefore(start) && !e.date.isAfter(end);
    }).toList();

    for (final expense in periodExpenses) {
      net[expense.paidByPersonId] =
          (net[expense.paidByPersonId] ?? 0) + expense.amount;
      variablePaid[expense.paidByPersonId] =
          (variablePaid[expense.paidByPersonId] ?? 0) + expense.amount;
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

  List<Transfer> _minimizeTransfers(
      Map<String, double> net, List<Person> people) {
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