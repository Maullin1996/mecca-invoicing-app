int parseCurrency(String value) {
  final normalized = value.replaceAll('.', '').trim();

  if (normalized.isEmpty) return 0;

  return int.parse(normalized);
}
