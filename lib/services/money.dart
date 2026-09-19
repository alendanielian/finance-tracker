import 'package:intl/intl.dart';

int currencyDigits(String code) => code == 'AMD' ? 0 : 2;

String formatMoney(int amountMinor, String code, String locale) {
  final digits = currencyDigits(code);
  final scale = digits == 0 ? 1 : 100;
  return NumberFormat.currency(
    locale: locale,
    name: code,
    decimalDigits: digits,
  ).format(amountMinor / scale);
}

int? parseMoney(String text, String code) {
  final normalized = text.trim().replaceAll(' ', '').replaceAll(',', '.');
  if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(normalized)) return null;
  final parts = normalized.split('.');
  final digits = currencyDigits(code);
  if (parts.length == 2 && parts[1].length > digits) return null;
  final whole = int.tryParse(parts[0]);
  if (whole == null) return null;
  final fractional = parts.length == 2 && digits > 0
      ? int.parse(parts[1].padRight(digits, '0'))
      : 0;
  final scale = digits == 0 ? 1 : 100;
  final amount = whole * scale + fractional;
  return amount > 0 ? amount : null;
}
