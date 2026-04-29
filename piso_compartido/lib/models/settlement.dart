/// Una transferencia mínima necesaria para saldar todas las deudas del período
class Transfer {
  final String fromPersonId; // quien paga
  final String toPersonId;   // quien cobra
  final double amount;
  bool isPaid;               // marcado manualmente en la pantalla

  Transfer({
    required this.fromPersonId,
    required this.toPersonId,
    required this.amount,
    this.isPaid = false,
  });
}

/// Resultado completo de la liquidación de un período
class Settlement {
  final DateTime periodStart;
  final DateTime periodEnd;
  final List<Transfer> transfers;
  /// Desglose: cuánto debe cada persona en gastos fijos
  final Map<String, double> fixedOwed;
  /// Desglose: cuánto ha pagado cada persona en gastos variables
  final Map<String, double> variablePaid;
  /// Balance neto final por persona (positivo = le deben, negativo = debe)
  final Map<String, double> netBalance;

  const Settlement({
    required this.periodStart,
    required this.periodEnd,
    required this.transfers,
    required this.fixedOwed,
    required this.variablePaid,
    required this.netBalance,
  });
}