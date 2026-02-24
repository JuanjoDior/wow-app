import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wow_companion/features/items/data/datasources/blizzard_items_datasource.dart';
import 'package:wow_companion/features/items/data/models/item_model.dart';
import 'package:wow_companion/features/items/data/repositories/items_repository_impl.dart';

class _MockBlizzardItemsDataSource extends Mock
    implements BlizzardItemsDataSource {}

void main() {
  late _MockBlizzardItemsDataSource dataSource;
  late ItemsRepositoryImpl repository;

  setUp(() {
    dataSource = _MockBlizzardItemsDataSource();
    repository = ItemsRepositoryImpl(remoteDataSource: dataSource);
  });

  test('getItemDetail propagates locale to datasource', () async {
    when(() => dataSource.getItemById(123, locale: 'es_ES')).thenAnswer(
      (_) async => const ItemModel(
        id: 123,
        name: 'Moneda del linaje',
        quality: 'COMMON',
      ),
    );

    final result = await repository.getItemDetail(123, locale: 'es_ES');

    expect(result.isRight(), isTrue);
    verify(() => dataSource.getItemById(123, locale: 'es_ES')).called(1);
    verifyNever(() => dataSource.getItemById(123, locale: 'en_GB'));
  });
}
