import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wow_companion/core/error/exceptions.dart';
import 'package:wow_companion/core/error/failures.dart';
import 'package:wow_companion/features/items/data/datasources/tooltip_remote_datasource.dart';
import 'package:wow_companion/features/items/data/repositories/tooltip_repository_impl.dart';
import 'package:wow_companion/features/items/domain/entities/item.dart';
import 'package:wow_companion/features/items/domain/entities/tooltip_detail.dart';

class _MockTooltipRemoteDataSource extends Mock
    implements TooltipRemoteDataSource {}

void main() {
  late _MockTooltipRemoteDataSource dataSource;
  late TooltipRepositoryImpl repository;

  setUp(() {
    dataSource = _MockTooltipRemoteDataSource();
    repository = TooltipRepositoryImpl(remoteDataSource: dataSource);
  });

  test('returns tooltip detail from datasource with forwarded args', () async {
    when(
      () => dataSource.getTooltipDetail(
        TooltipEntityKind.item,
        12345,
        locale: 'es_ES',
        region: 'eu',
        bonusIds: const [1, 2],
      ),
    ).thenAnswer(
      (_) async => const TooltipDetail(
        entityKind: TooltipEntityKind.item,
        id: 12345,
        name: 'Victor\'s Flashfrozen Blade',
      ),
    );

    final result = await repository.getTooltipDetail(
      TooltipEntityKind.item,
      12345,
      locale: 'es_ES',
      region: 'eu',
      bonusIds: const [1, 2],
    );

    expect(result, isA<Right<Failure, TooltipDetail>>());
    expect(result.getOrElse(() => throw StateError('missing')).id, 12345);
    verify(
      () => dataSource.getTooltipDetail(
        TooltipEntityKind.item,
        12345,
        locale: 'es_ES',
        region: 'eu',
        bonusIds: const [1, 2],
      ),
    ).called(1);
  });

  test('maps datasource server failures to ServerFailure', () async {
    when(
      () => dataSource.getTooltipDetail(
        TooltipEntityKind.spell,
        3001,
        locale: 'en_GB',
        region: 'eu',
        bonusIds: const [],
      ),
    ).thenThrow(const ServerException(message: 'Boom', statusCode: 500));

    final result = await repository.getTooltipDetail(
      TooltipEntityKind.spell,
      3001,
      locale: 'en_GB',
    );

    expect(result.isLeft(), isTrue);
    expect(
      result.swap().getOrElse(() => const CacheFailure()),
      isA<ServerFailure>(),
    );
  });
}
