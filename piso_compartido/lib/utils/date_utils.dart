import 'package:intl/intl.dart';

class AppDateUtils {
  static final _fmt = DateFormat('dd/MM/yyyy');

  static String format(DateTime dt) => _fmt.format(dt);

  /// Último día real de un mes dado
  static int lastDayOf(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  /// Resuelve el día de cierre real para un año/mes concreto.
  /// billingDay == 0 → último día del mes.
  /// billingDay > días del mes → último día del mes.
  static int resolvedBillingDay(int billingDay, int year, int month) {
    if (billingDay == 0) return lastDayOf(year, month);
    final last = lastDayOf(year, month);
    return billingDay > last ? last : billingDay;
  }

  /// Devuelve [start, end) del período que contiene [today].
  ///
  /// El período va desde el día [billingDay]+1 del mes anterior
  /// hasta el día [billingDay] del mes actual (inclusive, a las 23:59:59).
  ///
  /// Ejemplo con billingDay=25 y today=10 de febrero:
  ///   start = 26 de enero, end = 25 de febrero 23:59:59
  ///
  /// Ejemplo con billingDay=25 y today=28 de febrero:
  ///   start = 26 de febrero, end = 25 de marzo 23:59:59
  static (DateTime start, DateTime end) currentPeriod(
      int billingDay, DateTime today) {
    // Día de cierre en el mes actual
    final closingThisMonth =
        resolvedBillingDay(billingDay, today.year, today.month);

    final DateTime periodEnd;
    final DateTime periodStart;

    if (today.day <= closingThisMonth) {
      // Todavía no hemos llegado al cierre: el período acaba este mes
      periodEnd = DateTime(today.year, today.month, closingThisMonth, 23, 59, 59);

      // El inicio es el día siguiente al cierre del mes anterior
      final prevMonthDate = DateTime(today.year, today.month - 1, 1);
      final closingPrevMonth = resolvedBillingDay(
          billingDay, prevMonthDate.year, prevMonthDate.month);
      periodStart = DateTime(
          prevMonthDate.year, prevMonthDate.month, closingPrevMonth + 1);
    } else {
      // Ya pasó el cierre: el período empieza en el día siguiente al cierre de este mes
      periodStart = DateTime(today.year, today.month, closingThisMonth + 1);

      // Y acaba el día de cierre del mes siguiente
      final nextMonthDate = DateTime(today.year, today.month + 1, 1);
      final closingNextMonth = resolvedBillingDay(
          billingDay, nextMonthDate.year, nextMonthDate.month);
      periodEnd = DateTime(
          nextMonthDate.year, nextMonthDate.month, closingNextMonth, 23, 59, 59);
    }

    return (periodStart, periodEnd);
  }

  static bool isInCurrentPeriod(
      DateTime date, int billingDay, DateTime today) {
    final (start, end) = currentPeriod(billingDay, today);
    return !date.isBefore(start) && !date.isAfter(end);
  }
}