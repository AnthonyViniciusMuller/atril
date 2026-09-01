/// A number of bytes, as a reader reads one.
///
/// Two things have to be right and neither is arithmetic. The **unit** is
/// chosen so the number has one or two significant figures — nobody reads
/// `134217728 B` — and the **number** is formatted by the reader's locale,
/// because a Brazilian reader writes `1,8 GB` and an English one writes
/// `1.8 GB`. `intl` is what knows the separator; the ARB is what carries the
/// sentence around it.
///
/// The units are decimal and not binary, which is a decision rather than an
/// oversight: `navigator.storage.estimate()` reports bytes and every operating
/// system this app ships on shows a file's size in decimal megabytes, so a
/// reader comparing this screen with their file manager sees the same number.
library;

import 'package:intl/intl.dart';

import '../localization/localization.dart';

/// [bytes], written for [l10n]'s locale.
///
/// The unit is picked by size and the digits by the locale. A value under a
/// kilobyte is shown exactly, because rounding `820 B` to `0,8 kB` loses the
/// only thing the number was saying.
String formatBytes(AppLocalizations l10n, int bytes, {String? locale}) {
  const int kilobyte = 1000;
  const int megabyte = kilobyte * 1000;
  const int gigabyte = megabyte * 1000;

  final whole = NumberFormat.decimalPattern(locale);
  final fraction = NumberFormat('#,##0.#', locale);

  if (bytes < kilobyte) {
    return l10n.bytesExactly(whole.format(bytes));
  }

  if (bytes < megabyte) {
    return l10n.bytesInKilobytes(whole.format((bytes / kilobyte).round()));
  }

  if (bytes < gigabyte) {
    return l10n.bytesInMegabytes(fraction.format(bytes / megabyte));
  }

  return l10n.bytesInGigabytes(fraction.format(bytes / gigabyte));
}
