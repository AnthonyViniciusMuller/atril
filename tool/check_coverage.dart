// Fails when an lcov report covers fewer lines than a floor.
//
// `flutter test --coverage` writes the report and `make coverage` filters the
// generated code out of it; nothing in either says whether the number went
// down. This reads what is left — the LF and LH lines of each file record are
// the lines found and the lines hit — and exits non-zero under the floor, so
// that a phase which loses coverage is a red build rather than a smaller
// number nobody compared.
//
// Usage: dart run tool/check_coverage.dart [coverage/lcov.info] [floor]

import 'dart:io';

void main(List<String> arguments) {
  final report = File(arguments.isEmpty ? 'coverage/lcov.info' : arguments[0]);
  final floor = arguments.length > 1 ? double.parse(arguments[1]) : 85.0;

  if (!report.existsSync()) {
    stderr.writeln("no report at ${report.path} — run 'make coverage' first");
    exit(1);
  }

  var found = 0;
  var hit = 0;
  var files = 0;
  for (final line in report.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      files++;
    } else if (line.startsWith('LF:')) {
      found += int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      hit += int.parse(line.substring(3));
    }
  }

  if (found == 0) {
    // An empty report is a report of nothing, and passing it would let a
    // broken filter or a test run that produced no data read as a green build.
    stderr.writeln('${report.path} records no lines across $files files');
    exit(1);
  }

  final percent = hit * 100 / found;
  final summary =
      '${percent.toStringAsFixed(1)}% of $found lines covered in $files files';
  if (percent < floor) {
    stderr.writeln('$summary — under the floor of $floor%');
    exit(1);
  }
  stdout.writeln('$summary, floor $floor%');
}
