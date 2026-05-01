import 'package:intl/intl.dart';

/// Utilidades de fecha para el cálculo de períodos de facturación.
/// Esta es una de las partes más delicadas de la app porque los meses
/// tienen distinto número de días y hay que manejar el caso especial
/// del "último día del mes".
class AppDateUtils {
  static final _fmt = DateFormat('dd/MM/yyyy');

  static String format(DateTime dt) => _fmt.format(dt);

  /// Devuelve el último día real de un mes.
  /// El truco: DateTime(año, mes+1, 0) es el día 0 del mes siguiente,
  /// que equivale al último día del mes actual.
  static int lastDayOf(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  /// Resuelve el día de cierre real para un mes concreto.
  /// Maneja dos casos especiales:
  ///   - billingDay == 0: último día del mes (valor especial de la app)
  ///   - billingDay > días del mes: se ajusta al último día disponible
  ///     ej: billingDay=31 en febrero → día 28/29
  static int resolvedBillingDay(int billingDay, int year, int month) {
    if (billingDay == 0) return lastDayOf(year, month);
    final last = lastDayOf(year, month);
    return billingDay > last ? last : billingDay;
  }

  /// Calcula el inicio y fin del período de facturación que contiene [today].
  ///
  /// LÓGICA DEL PERÍODO:
  /// El período va desde el día siguiente al cierre del mes anterior
  /// hasta el día de cierre del mes actual (inclusive).
  ///
  /// Ejemplo con billingDay=25:
  ///   Si hoy es 10 de febrero:
  ///     → El cierre de este mes es el 25 de febrero
  ///     → Como aún no llegamos al cierre, el período actual es:
  ///        start = 26 de enero, end = 25 de febrero 23:59:59
  ///
  ///   Si hoy es 28 de febrero (ya pasamos el cierre del 25):
  ///     → El período actual ya empezó el 26 de febrero:
  ///        start = 26 de febrero, end = 25 de marzo 23:59:59
  static (DateTime start, DateTime end) currentPeriod(
      int billingDay, DateTime today) {
    // Día de cierre ajustado al mes actual
    final closingThisMonth =
        resolvedBillingDay(billingDay, today.year, today.month);

    final DateTime periodEnd;
    final DateTime periodStart;

    if (today.day <= closingThisMonth) {
      // Todavía estamos dentro del período que cierra este mes
      periodEnd = DateTime(
          today.year, today.month, closingThisMonth, 23, 59, 59);

      // El período empezó el día siguiente al cierre del mes anterior
      final prevMonthDate = DateTime(today.year, today.month - 1, 1);
      final closingPrevMonth = resolvedBillingDay(
          billingDay, prevMonthDate.year, prevMonthDate.month);
      periodStart = DateTime(
          prevMonthDate.year, prevMonthDate.month, closingPrevMonth + 1);
    } else {
      // Ya pasó el cierre: estamos en el siguiente período
      periodStart =
          DateTime(today.year, today.month, closingThisMonth + 1);

      final nextMonthDate = DateTime(today.year, today.month + 1, 1);
      final closingNextMonth = resolvedBillingDay(
          billingDay, nextMonthDate.year, nextMonthDate.month);
      periodEnd = DateTime(nextMonthDate.year, nextMonthDate.month,
          closingNextMonth, 23, 59, 59);
    }

    return (periodStart, periodEnd);
  }

  /// Comprueba si una fecha concreta cae dentro del período activo.
  /// Usamos !isBefore y !isAfter en lugar de isAfter e isBefore
  /// para que los extremos del período sean inclusivos.
  static bool isInCurrentPeriod(
      DateTime date, int billingDay, DateTime today) {
    final (start, end) = currentPeriod(billingDay, today);
    return !date.isBefore(start) && !date.isAfter(end);
  }
}