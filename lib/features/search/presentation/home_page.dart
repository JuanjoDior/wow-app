import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';
import 'package:wow_companion/features/search/domain/search_entry.dart';
import 'package:wow_companion/features/search/domain/search_history_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _realmController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedRegion = 'eu';
  String? _errorMessage;

  List<SearchEntry> _history = [];
  final SearchHistoryRepository _historyRepo = sl<SearchHistoryRepository>();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _historyRepo.getHistory();
    if (mounted) setState(() => _history = history);
  }

  @override
  void dispose() {
    _realmController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final realm = _realmController.text.trim();
    final name = _nameController.text.trim();

    if (realm.isEmpty || name.isEmpty) {
      setState(
        () => _errorMessage = 'Please enter both realm and character name',
      );
      return;
    }

    setState(() => _errorMessage = null);

    final realmSlug = realm.toLowerCase().replaceAll(' ', '-');

    // Save to history
    _historyRepo.addEntry(
      SearchEntry(
        region: _selectedRegion,
        realm: realmSlug,
        name: name.toLowerCase(),
      ),
    );

    context
        .push('/character/$_selectedRegion/$realmSlug/${name.toLowerCase()}')
        .then((_) => _loadHistory());
  }

  void _onHistoryTap(SearchEntry entry) {
    // Update timestamp by re-adding
    _historyRepo.addEntry(
      SearchEntry(region: entry.region, realm: entry.realm, name: entry.name),
    );

    context
        .push(
          '/character/${entry.region}/${entry.realmSlug}/${entry.name.toLowerCase()}',
        )
        .then((_) => _loadHistory());
  }

  Future<void> _onHistoryDismiss(SearchEntry entry) async {
    await _historyRepo.removeEntry(entry.key);
    _loadHistory();
  }

  Future<void> _onClearHistory() async {
    await _historyRepo.clearHistory();
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              const Text(
                '⚔️ WoW Companion',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: WowTheme.primaryGold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Look up any character by realm and name',
                style: TextStyle(color: WowTheme.textSecondary),
              ),
              const SizedBox(height: 32),

              // Search form
              _buildSearchForm(),

              // Recent searches
              if (_history.isNotEmpty) ...[
                const SizedBox(height: 32),
                _buildHistorySection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchForm() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Column(
        children: [
          // Region selector
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: WowTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: WowTheme.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedRegion,
                isExpanded: true,
                dropdownColor: WowTheme.surfaceDark,
                style: const TextStyle(color: WowTheme.textPrimary),
                items: const [
                  DropdownMenuItem(value: 'eu', child: Text('🇪🇺 Europe')),
                  DropdownMenuItem(value: 'us', child: Text('🇺🇸 Americas')),
                  DropdownMenuItem(value: 'kr', child: Text('🇰🇷 Korea')),
                  DropdownMenuItem(value: 'tw', child: Text('🇹🇼 Taiwan')),
                ],
                onChanged: (v) => setState(() => _selectedRegion = v!),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Realm field
          TextField(
            controller: _realmController,
            decoration: const InputDecoration(
              hintText: 'Realm (e.g. Sargeras)',
              prefixIcon: Icon(
                Icons.dns_outlined,
                color: WowTheme.textSecondary,
              ),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),

          // Name field
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'Character name',
              prefixIcon: Icon(
                Icons.person_outline,
                color: WowTheme.textSecondary,
              ),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _onSearch(),
          ),
          const SizedBox(height: 8),

          // Error message
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: WowTheme.accentRed, fontSize: 13),
              ),
            ),

          const SizedBox(height: 8),

          // Search button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _onSearch,
              icon: const Icon(Icons.search),
              label: const Text('Look Up Character'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/compare'),
              icon: const Icon(
                Icons.compare_arrows,
                color: WowTheme.primaryGold,
              ),
              label: const Text(
                'Compare Characters',
                style: TextStyle(color: WowTheme.primaryGold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: WowTheme.primaryGold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Searches',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: WowTheme.primaryGold,
                ),
              ),
              TextButton(
                onPressed: _onClearHistory,
                child: const Text(
                  'Clear all',
                  style: TextStyle(color: WowTheme.textSecondary, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // History list
          ...List.generate(_history.length, (index) {
            final entry = _history[index];
            return Dismissible(
              key: ValueKey(entry.key),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: WowTheme.accentRed.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onDismissed: (_) => _onHistoryDismiss(entry),
              child: Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  dense: true,
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: WowTheme.accentBlue.withValues(alpha: 0.15),
                    ),
                    child: const Icon(
                      Icons.history,
                      color: WowTheme.accentBlue,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    _capitalize(entry.name),
                    style: const TextStyle(
                      color: WowTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    '${entry.displayRealm} · ${entry.region.toUpperCase()}',
                    style: const TextStyle(
                      color: WowTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: WowTheme.textSecondary,
                    size: 20,
                  ),
                  onTap: () => _onHistoryTap(entry),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }
}
