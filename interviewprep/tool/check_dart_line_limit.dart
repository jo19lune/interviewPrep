import 'dart:io';

const maxLines = 200;

void main() {
  final root = Directory('lib');
  final violations = <String>[];

  for (final file
      in root
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .where((file) => !file.path.endsWith('.g.dart'))
          .where((file) => !file.path.endsWith('.freezed.dart'))) {
    final count = _countCodeLines(file.readAsLinesSync());
    if (count > maxLines) {
      violations.add('${file.path}: $count lines');
    }
  }

  if (violations.isNotEmpty) {
    stderr
      ..writeln('Dart files exceed $maxLines code lines:')
      ..writeAll(violations, '\n');
    exitCode = 1;
    return;
  }

  stdout.writeln('All handwritten Dart files are within $maxLines code lines.');
}

int _countCodeLines(List<String> lines) {
  var count = 0;
  var inBlockComment = false;

  for (final line in lines) {
    var content = line.trim();
    if (inBlockComment) {
      final end = content.indexOf('*/');
      if (end == -1) continue;
      content = content.substring(end + 2).trim();
      inBlockComment = false;
    }
    if (content.isEmpty || content.startsWith('//')) continue;

    final start = content.indexOf('/*');
    if (start != -1) {
      final end = content.indexOf('*/', start + 2);
      if (end == -1) {
        content = content.substring(0, start).trim();
        inBlockComment = true;
      } else {
        content = '${content.substring(0, start)}${content.substring(end + 2)}'
            .trim();
      }
    }
    if (content.isNotEmpty) count++;
  }
  return count;
}
