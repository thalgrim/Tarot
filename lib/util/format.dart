String formatDateTime(DateTime dt) {
  final local = dt.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
}

String formatMaybeInt(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(1);
}

String formatScore(double value) {
  if (value == 0) return '0';
  final sign = value > 0 ? '+' : '-';
  return '$sign${formatMaybeInt(value.abs())}';
}

String formatPoints(double value) => formatMaybeInt(value);
