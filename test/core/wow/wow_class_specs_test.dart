import 'package:flutter_test/flutter_test.dart';
import 'package:wow_companion/core/wow/wow_class_specs.dart';

void main() {
  test('Devourer es una spec valida de Demon Hunter', () {
    expect(isValidSpecForClass('Demon Hunter', 'Devourer'), isTrue);
    expect(
      wowSpecsByClass['Demon Hunter'],
      containsAll(<String>['Devourer', 'Havoc', 'Vengeance']),
    );
  });

  test('rechaza specs que no pertenecen a la clase', () {
    expect(isValidSpecForClass('Mage', 'Devourer'), isFalse);
    expect(isValidSpecForClass('Demon Hunter', null), isFalse);
  });
}
