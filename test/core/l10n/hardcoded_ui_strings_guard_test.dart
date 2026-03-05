import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _allowedUiLiterals = <String>{'⚔️', '💡', 'EN', 'ES', 'VS', 'DPS'};

final _uiLiteralPatterns = <RegExp>[
  RegExp(r'''Text\(\s*(['"])([^'"\n]+)\1'''),
  RegExp(
    r'''(?:tooltip|hintText|title|label|semanticLabel)\s*:\s*(['"])([^'"\n]+)\1''',
  ),
];

bool _isUiFile(String path) {
  final normalized = path.replaceAll('\\', '/');
  if (!normalized.startsWith('lib/')) return false;
  if (normalized.contains('/l10n/generated/')) return false;
  if (normalized.contains('/presentation/')) return true;
  return normalized.startsWith('lib/shared/widgets/');
}

bool _isAcceptableLiteral(String rawValue) {
  final value = rawValue.trim();
  if (value.isEmpty) return true;
  if (value.contains(r'${') || value.contains(r'$')) return true;
  if (_allowedUiLiterals.contains(value)) return true;
  if (!RegExp(r'[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]').hasMatch(value)) return true;
  return false;
}

int _lineNumber(String content, int offset) {
  return '\n'.allMatches(content.substring(0, offset)).length + 1;
}

void main() {
  test('UI text should use l10n keys instead of hardcoded literals', () {
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => _isUiFile(file.path))
        .toList(growable: false);

    final violations = <String>[];
    for (final file in dartFiles) {
      final content = file.readAsStringSync();
      for (final pattern in _uiLiteralPatterns) {
        for (final match in pattern.allMatches(content)) {
          final literal = (match.group(2) ?? '').trim();
          if (_isAcceptableLiteral(literal)) continue;

          final line = _lineNumber(content, match.start);
          violations.add('${file.path}:$line -> "$literal"');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Found hardcoded UI literals:\n${violations.join('\n')}',
    );
  });
}
