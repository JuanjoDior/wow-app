enum ItemSearchMode { item, enchant, gem, consumable }

extension ItemSearchModeApi on ItemSearchMode {
  String get apiValue => switch (this) {
    ItemSearchMode.item => 'item',
    ItemSearchMode.enchant => 'enchant',
    ItemSearchMode.gem => 'gem',
    ItemSearchMode.consumable => 'consumable',
  };
}
