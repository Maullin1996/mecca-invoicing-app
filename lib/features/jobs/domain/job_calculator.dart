import 'dart:math' as math;

class JobCalculationResult {
  const JobCalculationResult({
    required this.minutesWorked,
    required this.hoursCharged,
    required this.newBalance,
    required this.totalDay,
  });

  final int minutesWorked;
  final int hoursCharged;
  final int newBalance;
  final int totalDay;
}

JobCalculationResult calculateJob({
  required int saldoActual,
  required int minutosTrabajados,
  required int valorHora,
  required int valorAnexos,
  required bool usarSaldo,
}) {
  final int hoursCharged;
  final int newBalance;

  if (usarSaldo) {
    final minutesTotal = saldoActual + minutosTrabajados;

    if (minutesTotal <= 0) {
      hoursCharged = 0;
      newBalance = minutesTotal;
    } else {
      final charged = minutesTotal ~/ 60;
      hoursCharged = math.max(0, charged);
      newBalance = minutesTotal - (hoursCharged * 60);
    }
  } else {
    final charged = (minutosTrabajados / 60).ceil();
    hoursCharged = math.max(0, charged);
    final minutosFacturados = hoursCharged * 60;
    final diferencia = minutosTrabajados - minutosFacturados;
    newBalance = saldoActual + diferencia;
  }

  final totalDay = (hoursCharged * valorHora) + valorAnexos;

  return JobCalculationResult(
    minutesWorked: minutosTrabajados,
    hoursCharged: hoursCharged,
    newBalance: newBalance,
    totalDay: totalDay,
  );
}

JobCalculationResult calculateJobManualHours({
  required int saldoActual,
  required int minutosTrabajados,
  required int horasACobrar,
  required int valorHora,
  required int valorAnexos,
}) {
  final hoursCharged = math.max(0, horasACobrar);
  final delta = minutosTrabajados - (hoursCharged * 60);
  final newBalance = saldoActual + delta;
  final totalDay = (hoursCharged * valorHora) + valorAnexos;

  return JobCalculationResult(
    minutesWorked: minutosTrabajados,
    hoursCharged: hoursCharged,
    newBalance: newBalance,
    totalDay: totalDay,
  );
}
