import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';

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
    context.push(
      '/character/$_selectedRegion/$realmSlug/${name.toLowerCase()}',
    );
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
              ConstrainedBox(
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
                            DropdownMenuItem(
                              value: 'eu',
                              child: Text('🇪🇺 Europe'),
                            ),
                            DropdownMenuItem(
                              value: 'us',
                              child: Text('🇺🇸 Americas'),
                            ),
                            DropdownMenuItem(
                              value: 'kr',
                              child: Text('🇰🇷 Korea'),
                            ),
                            DropdownMenuItem(
                              value: 'tw',
                              child: Text('🇹🇼 Taiwan'),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedRegion = v!),
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
                          style: const TextStyle(
                            color: WowTheme.accentRed,
                            fontSize: 13,
                          ),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
