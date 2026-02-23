import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';
import 'package:wow_companion/features/builds/domain/entities/build.dart';
import 'package:wow_companion/features/builds/presentation/cubit/builds_cubit.dart';
import 'package:wow_companion/features/builds/presentation/cubit/builds_state.dart';
import 'package:wow_companion/features/builds/presentation/widgets/create_build_dialog.dart';
import 'package:wow_companion/core/l10n/wow_translations.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';

class BuildsListPage extends StatelessWidget {
  const BuildsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BuildsCubit>()..loadBuilds(),
      child: const _BuildsListView(),
    );
  }
}

class _BuildsListView extends StatelessWidget {
  const _BuildsListView();

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.builds)),
      floatingActionButton: FloatingActionButton(
        backgroundColor: WowTheme.primaryGold,
        foregroundColor: WowTheme.darkBackground,
        onPressed: () => _showCreateDialog(context),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<BuildsCubit, BuildsState>(
        builder: (context, state) {
          if (state is BuildsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: WowTheme.primaryGold),
            );
          }
          if (state is BuildsError) {
            return Center(
              child: Text(state.message,
                  style: const TextStyle(color: WowTheme.textSecondary)),
            );
          }
          if (state is BuildsLoaded) {
            if (state.builds.isEmpty) return _buildEmpty(t);
            return _buildList(context, state.builds);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmpty(S t) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction,
                size: 64, color: WowTheme.textSecondary),
            const SizedBox(height: 12),
            Text(t.buildsNoBuildsYet,
                style: const TextStyle(
                    color: WowTheme.textSecondary, fontSize: 16)),
            const SizedBox(height: 4),
            Text(t.buildsNoBuildsHint,
                style: const TextStyle(
                    color: WowTheme.textSecondary, fontSize: 13)),
          ],
        ),
      );

  Widget _buildList(BuildContext context, List<Build> builds) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: builds.length,
      itemBuilder: (_, i) => _BuildCard(buildData: builds[i]),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<BuildsCubit>(),
        child: const CreateBuildDialog(),
      ),
    );
  }
}

// ─── Build card ────────────────────────────────────────────────────────────
class _BuildCard extends StatelessWidget {
  final Build buildData;
  const _BuildCard({required this.buildData});

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    final hasClass = buildData.characterClass != null;
    final classColor = hasClass
        ? WowTheme.getClassColor(buildData.characterClass!)
        : WowTheme.primaryGold;

    final progress = buildData.progress;
    final barColor = progress < 0.33
        ? const Color(0xFFE74C3C)
        : progress < 0.66
        ? const Color(0xFFF39C12)
        : progress < 1.0
        ? WowTheme.primaryGold
        : const Color(0xFF2ECC71);

    return Card(
      color: WowTheme.surfaceDark,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasClass
              ? classColor.withValues(alpha: 0.35)
              : WowTheme.border,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await context.push('/builds/${buildData.id}');
          if (context.mounted) context.read<BuildsCubit>().loadBuilds();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardAvatar(
                classColor: classColor,
                hasClass: hasClass,
                avatarUrl: buildData.characterAvatarUrl,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            buildData.name,
                            style: TextStyle(
                              color: classColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        _DeleteButton(buildData: buildData),
                      ],
                    ),
                    if (buildData.characterRefDisplay != null)
                      _InfoLine(
                        text: _realmRegion(),
                        icon: Icons.location_on_outlined,
                      ),
                    if (hasClass)
                      _InfoLine(
                        text: _detailLine(),
                        icon: Icons.person_outline,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (buildData.guide.content != null)
                          _ContentBadge(content: buildData.guide.content!),
                        const Spacer(),
                        Text(
                          _formatDate(buildData.createdAt),
                          style: const TextStyle(
                            color: WowTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: WowTheme.border,
                              color: barColor,
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          t.buildsSlots(
                            buildData.obtainedSlots,
                            buildData.totalSlots,
                          ),
                          style: TextStyle(color: barColor, fontSize: 12),
                        ),
                      ],
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

  String _realmRegion() {
    final parts = buildData.characterRefDisplay?.split(' - ') ?? [];
    final realm = parts.length >= 2 ? parts[1] : (parts.isNotEmpty ? parts[0] : '');
    final region = buildData.characterRefKey?.split('-').firstOrNull?.toUpperCase() ?? '';
    return [realm, region].where((s) => s.isNotEmpty).join(' · ');
  }

  String _detailLine() {
    final parts = <String>[
      if (buildData.characterRace != null)
        WowTranslations.translateRace(buildData.characterRace!),
      WowTranslations.translateClass(buildData.characterClass!),
      if (buildData.characterSpec != null)
        WowTranslations.translateSpec(buildData.characterSpec!),
    ];
    return parts.join('  ·  ');
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

// ─── Card avatar ────────────────────────────────────────────────────────────
class _CardAvatar extends StatelessWidget {
  final Color classColor;
  final bool hasClass;
  final String? avatarUrl;

  const _CardAvatar({
    required this.classColor,
    required this.hasClass,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: classColor, width: 2),
        color: WowTheme.surfaceLight,
      ),
      child: ClipOval(
        child: avatarUrl != null
            ? Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallbackIcon(),
              )
            : _fallbackIcon(),
      ),
    );
  }

  Widget _fallbackIcon() => Icon(
    hasClass ? Icons.person_outline : Icons.construction_outlined,
    color: classColor,
    size: 24,
  );
}

// ─── Info line ────────────────────────────────────────────────────────────
class _InfoLine extends StatelessWidget {
  final String text;
  final IconData icon;

  const _InfoLine({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: WowTheme.textSecondary),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: WowTheme.textSecondary,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Content badge ────────────────────────────────────────────────────────────
class _ContentBadge extends StatelessWidget {
  final BuildContent content;

  const _ContentBadge({required this.content});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (content) {
      BuildContent.raid     => ('Raid', const Color(0xFFA335EE), Icons.shield_outlined),
      BuildContent.mythicPlus => ('M+', const Color(0xFF0070DD), Icons.timer_outlined),
      BuildContent.both     => ('Raid · M+', WowTheme.primaryGold, Icons.auto_awesome_outlined),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Delete button ────────────────────────────────────────────────────────────
class _DeleteButton extends StatelessWidget {
  final Build buildData;

  const _DeleteButton({required this.buildData});

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    return IconButton(
      icon: const Icon(
        Icons.delete_outline,
        color: WowTheme.textSecondary,
        size: 20,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      onPressed: () => _confirmDelete(context, t),
    );
  }

  void _confirmDelete(BuildContext context, S t) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: WowTheme.surfaceDark,
        title: Text(
          t.buildsDeleteTitle,
          style: const TextStyle(color: WowTheme.textPrimary),
        ),
        content: Text(
          t.buildsDeleteConfirm(buildData.name),
          style: const TextStyle(color: WowTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(),
            child: Text(
              t.buildsCancel,
              style: const TextStyle(color: WowTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<BuildsCubit>().deleteBuild(buildData.id);
              Navigator.of(context, rootNavigator: true).pop();
            },
            child: Text(
              t.buildsDelete,
              style: const TextStyle(color: WowTheme.accentRed),
            ),
          ),
        ],
      ),
    );
  }
}
