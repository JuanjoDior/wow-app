import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';

void main() {
  test('resuelve colores de clase en ingles y castellano', () {
    expect(WowTheme.getClassColor('Demon Hunter'), const Color(0xFFA330C9));
    expect(
      WowTheme.getClassColor('Cazador de Demonios'),
      const Color(0xFFA330C9),
    );
    expect(
      WowTheme.getClassColor('Caballero de la Muerte'),
      const Color(0xFFC41F3B),
    );
    expect(WowTheme.getClassColor('Chamán'), const Color(0xFF0070DE));
    expect(WowTheme.getClassColor('Monje'), const Color(0xFF00FF96));
  });

  test('usa color por defecto para clases desconocidas', () {
    expect(WowTheme.getClassColor('Clase Inventada'), Colors.white);
  });
}
