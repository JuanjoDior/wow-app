class BuildSyncResult {
  final int slotsUpdated;
  final int itemsMatched;
  final int itemsTargeted;

  const BuildSyncResult({
    required this.slotsUpdated,
    required this.itemsMatched,
    required this.itemsTargeted,
  });
}
