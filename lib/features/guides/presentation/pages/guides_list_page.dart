import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';
import 'package:wow_companion/features/guides/data/cheatsheet_repository.dart';
import 'package:wow_companion/features/guides/domain/entities/cheatsheet.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';

class GuidesListPage extends StatefulWidget {
  const GuidesListPage({super.key});

  @override
  State<GuidesListPage> createState() => _GuidesListPageState();
}

class _GuidesListPageState extends State<GuidesListPage> {
  List<Cheatsheet> _guides = [];
  String _filterRole = 'All';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = sl<CheatsheetRepository>();
    final all = await repo.getAll();
    if (mounted) {
      setState(() {
        _guides = all;
        _loading = false;
      });
    }
  }

  List<Cheatsheet> get _filtered {
    if (_filterRole == 'All') return _guides;
    return _guides.where((g) => g.role == _filterRole).toList();
  }

  String _translateRole(BuildContext context, String role) {
    final t = S.of(context)!;
    switch (role) {
      case 'All':
        return t.all;
      case 'DPS':
        return t.dps;
      case 'Healer':
        return t.healer;
      case 'Tank':
        return t.tank;
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: WowTheme.primaryGold),
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: _buildHeader(),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 700),
                          child: _buildGuideCard(_filtered[index]),
                        ),
                      ),
                      childCount: _filtered.length,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    final t = S.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📖 ${t.quickCheatsheets}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: WowTheme.primaryGold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t.cheatsheetsSubtitle,
            style: const TextStyle(color: WowTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: ['All', 'DPS', 'Healer', 'Tank'].map((role) {
              final selected = _filterRole == role;
              return ChoiceChip(
                label: Text(_translateRole(context, role)),
                selected: selected,
                onSelected: (_) => setState(() => _filterRole = role),
                selectedColor: WowTheme.primaryGold,
                backgroundColor: WowTheme.surfaceLight,
                labelStyle: TextStyle(
                  color: selected ? Colors.black : WowTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard(Cheatsheet guide) {
    final roleColor = _getRoleColor(guide.role);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: roleColor.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () =>
            context.push('/guides/${guide.classSlug}/${guide.specSlug}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getRoleIcon(guide.role),
                  color: roleColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guide.displayTitle,
                      style: TextStyle(
                        color: WowTheme.getClassColor(guide.className),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_translateRole(context, guide.role)} · ${guide.statPriority.take(2).join(" > ")}',
                      style: const TextStyle(
                        color: WowTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: WowTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Tank':
        return const Color(0xFF5B9BD5);
      case 'Healer':
        return const Color(0xFF1EFF00);
      case 'DPS':
        return const Color(0xFFFF4444);
      default:
        return WowTheme.textSecondary;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'Tank':
        return Icons.shield;
      case 'Healer':
        return Icons.favorite;
      case 'DPS':
        return Icons.flash_on;
      default:
        return Icons.help_outline;
    }
  }
}
