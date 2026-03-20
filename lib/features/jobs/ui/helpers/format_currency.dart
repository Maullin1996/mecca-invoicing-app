import 'package:intl/intl.dart';

final _currencyFormatter = NumberFormat('#,###', 'es_CO');

String formatCurrency(num value) {
  return _currencyFormatter.format(value).replaceAll(',', '.');
}
