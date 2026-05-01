/// Representa una transferencia de dinero entre dos personas
/// para saldar una deuda del período.
class Transfer {
  final String fromPersonId; // Quien debe pagar
  final String toPersonId;   // Quien debe recibir
  final double amount;       // Cantidad exacta a transferir
  bool isPaid;               // Estado mutable: el usuario lo marca
                             // manualmente en la pantalla de liquidación

  Transfer({
    required this.fromPersonId,
    required this.toPersonId,
    required this.amount,
    this.isPaid = false,
  });
}

/// Resultado completo del cálculo de liquidación de un período.
/// Agrupa toda la información necesaria para mostrar la pantalla
/// de liquidación: desglose de fijos, pagos variables y transferencias.
class Settlement {
  final DateTime periodStart;
  final DateTime periodEnd;
  final List<Transfer> transfers;    // Lista mínima de pagos para saldar todo
  final Map<String, double> fixedOwed;      // Cuánto debe cada uno por fijos
                                            // (clave = nombre categoría)
  final Map<String, double> variablePaid;   // Cuánto ha pagado cada persona
                                            // en gastos variables
                                            // (clave = personId)
  final Map<String, double> netBalance;     // Balance neto final por persona
                                            // positivo = le deben
                                            // negativo = debe
                                            // (clave = personId)

  const Settlement({
    required this.periodStart,
    required this.periodEnd,
    required this.transfers,
    required this.fixedOwed,
    required this.variablePaid,
    required this.netBalance,
  });
}