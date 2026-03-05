import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wow_companion/features/items/domain/entities/item_search_mode.dart';
import 'package:wow_companion/features/items/domain/usecases/search_items.dart';
import 'package:wow_companion/features/items/presentation/cubit/items_state.dart';

class ItemsCubit extends Cubit<ItemsState> {
  final SearchItems _searchItems;
  int _searchRequestId = 0;

  ItemsCubit(this._searchItems) : super(const ItemsInitial());

  Future<void> search(
    String query, {
    ItemSearchMode mode = ItemSearchMode.item,
    String? inventoryType,
    String? slot,
    String region = 'eu',
    String locale = 'en_GB',
  }) async {
    if (query.trim().length < 2) {
      emit(const ItemsInitial());
      return;
    }

    final requestId = ++_searchRequestId;
    emit(const ItemsLoading());

    final result = await _searchItems(
      query.trim(),
      mode: mode,
      inventoryType: inventoryType,
      slot: slot,
      region: region,
      locale: locale,
    );
    if (requestId != _searchRequestId) return;

    result.fold(
      (failure) => emit(ItemsError(failure.message)),
      (items) =>
          items.isEmpty ? emit(const ItemsEmpty()) : emit(ItemsLoaded(items)),
    );
  }

  void clear() => emit(const ItemsInitial());
}
