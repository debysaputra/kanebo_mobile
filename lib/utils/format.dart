import 'package:intl/intl.dart';

/// Helper format mata uang & tanggal.
class Fmt {
  Fmt._();

  static final NumberFormat _idr = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _compact = NumberFormat.compactCurrency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 1,
  );

  static final NumberFormat _plain = NumberFormat.decimalPattern('id_ID');

  static String idr(num value) => _idr.format(value);

  static String idrCompact(num value) {
    if (value.abs() < 10000) return _idr.format(value);
    return _compact.format(value);
  }

  static String plain(num value) => _plain.format(value);

  static String date(DateTime date) =>
      DateFormat('d MMM yyyy', 'id_ID').format(date);

  static String dateShort(DateTime date) =>
      DateFormat('d MMM', 'id_ID').format(date);

  static String dateLong(DateTime date) =>
      DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);

  static String monthYear(DateTime date) =>
      DateFormat('MMMM yyyy', 'id_ID').format(date);

  static String time(DateTime date) => DateFormat('HH:mm').format(date);

  static String relative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(date.year, date.month, date.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';
    if (diff > 1 && diff < 7) return '$diff hari lalu';
    return date.year == now.year ? dateShort(date) : date.toString();
  }
}
