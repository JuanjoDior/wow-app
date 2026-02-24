import 'package:flutter_test/flutter_test.dart';
import 'package:wow_companion/core/wow/supported_regions.dart';

void main() {
  group('supported regions', () {
    test('contains exactly US/EU/KR/TW', () {
      expect(supportedRegionCodes, ['eu', 'us', 'kr', 'tw']);
      expect(supportedRegionCodes.contains('cn'), isFalse);
    });

    test('isSupportedRegion handles trim and case', () {
      expect(isSupportedRegion('EU'), isTrue);
      expect(isSupportedRegion(' us '), isTrue);
      expect(isSupportedRegion('KR'), isTrue);
      expect(isSupportedRegion('tw'), isTrue);
      expect(isSupportedRegion('cn'), isFalse);
      expect(isSupportedRegion(''), isFalse);
    });
  });
}
