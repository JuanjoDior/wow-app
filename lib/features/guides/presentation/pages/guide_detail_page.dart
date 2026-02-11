import 'package:flutter/material.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';
import 'package:wow_companion/features/guides/data/cheatsheet_repository.dart';
import 'package:wow_companion/features/guides/domain/entities/cheatsheet.dart';
import 'package:wow_companion/shared/widgets/common_widgets.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';

class GuideDetailPage extends StatefulWidget {
  final String classSlug;
  final String specSlug;

  const GuideDetailPage({
    super.key,
    required this.classSlug,
    required this.specSlug,
  });

  @override
  State<GuideDetailPage> createState() => _GuideDetailPageState();
}

class _GuideDetailPageState extends State<GuideDetailPage> {
  Cheatsheet? _guide;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = sl<CheatsheetRepository>();
    final guide = await repo.getBySpec(widget.classSlug, widget.specSlug);
    if (mounted) {
      setState(() {
        _guide = guide;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(_guide?.displayTitle ?? t.guides)),
      body: _loading
          ? WowLoadingWidget(message: t.loadingGuide)
          : _guide == null
              ? WowErrorWidget(message: t.guideNotFound)
              : _buildContent(_guide!),
    );
  }

  Widget _buildContent(Cheatsheet guide) {
    final t = S.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleSection(guide),
          const SizedBox(height: 20),
          _buildSection(
            icon: Icons.bar_chart,
            title: t.statPriority,
            color: const Color(0xFF0070DD),
            child: _buildStatPriority(guide.statPriority),
          ),
          const SizedBox(height: 16),
          _buildSection(
            icon: Icons.replay,
            title: t.rotation,
            color: const Color(0xFFFF8000),
            child: _buildRotation(guide.rotation),
          ),
          const SizedBox(height: 16),
          _buildSection(
            icon: Icons.local_drink,
            title: t.consumables,
            color: const Color(0xFFA335EE),
            child: _buildConsumables(guide.consumables),
          ),
          if (guide.tips.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSection(
              icon: Icons.lightbulb_outline,
              title: t.tips,
              color: WowTheme.primaryGold,
              child: _buildTips(guide.tips),
            ),
          ],
          const SizedBox(height: 24),
          if (guide.lastUpdated != null)
            Center(
              child: Text(
                t.lastUpdated(guide.lastUpdated!),
                style: const TextStyle(
                  color: WowTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(Cheatsheet guide) {
    final roleColor = _getRoleColor(guide.role);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: roleColor.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_getRoleIcon(guide.role), color: roleColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    guide.displayTitle,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: WowTheme.getClassColor(guide.className),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _translateRole(guide.role),
                      style: TextStyle(
                        color: roleColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _translateRole(String role) {
    final t = S.of(context)!;
    switch (role) {
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

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildStatPriority(List<String> stats) {
    return Column(
      children: [
        for (var i = 0; i < stats.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: i == 0
                        ? WowTheme.primaryGold.withValues(alpha: 0.2)
                        : WowTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: i == 0
                            ? WowTheme.primaryGold
                            : WowTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    stats[i],
                    style: TextStyle(
                      color: i == 0
                          ? WowTheme.textPrimary
                          : WowTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: i == 0 ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (i < stats.length - 1)
                  const Text(
                    ' > ',
                    style: TextStyle(
                      color: WowTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRotation(List<RotationStep> steps) {
    return Column(
      children: steps.map((step) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8000).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '${step.priority}',
                    style: const TextStyle(
                      color: Color(0xFFFF8000),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.ability,
                      style: const TextStyle(
                        color: WowTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (step.condition.isNotEmpty)
                      Text(
                        step.condition,
                        style: const TextStyle(
                          color: WowTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConsumables(List<ConsumableInfo> consumables) {
    return Column(
      children: consumables.map((c) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(
                _getConsumableIcon(c.type),
                color: const Color(0xFFA335EE),
                size: 18,
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 60,
                child: Text(
                  c.type,
                  style: const TextStyle(
                    color: WowTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  c.name,
                  style: const TextStyle(
                    color: WowTheme.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ),
              if (c.note != null)
                Text(
                  c.note!,
                  style: const TextStyle(
                    color: WowTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTips(List<String> tips) {
    return Column(
      children: tips.map((tip) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💡 ', style: TextStyle(fontSize: 14)),
              Expanded(
                child: Text(
                  tip,
                  style: const TextStyle(
                    color: WowTheme.textPrimary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _getConsumableIcon(String type) {
    switch (type) {
      case 'Flask':
        return Icons.science;
      case 'Food':
        return Icons.restaurant;
      case 'Potion':
        return Icons.local_drink;
      case 'Rune':
        return Icons.auto_awesome;
      case 'Weapon':
        return Icons.build;
      default:
        return Icons.inventory_2;
    }
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
