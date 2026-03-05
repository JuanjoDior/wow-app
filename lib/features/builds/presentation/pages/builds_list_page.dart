import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wow_companion/core/config/feature_flags.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/core/error/exceptions.dart';
import 'package:wow_companion/core/l10n/failure_localizer.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';
import 'package:wow_companion/core/wow/character_search_input.dart';
import 'package:wow_companion/features/builds/domain/entities/build.dart';
import 'package:wow_companion/features/builds/presentation/cubit/builds_cubit.dart';
import 'package:wow_companion/features/builds/presentation/cubit/builds_state.dart';
import 'package:wow_companion/features/builds/presentation/widgets/create_build_dialog.dart';
import 'package:wow_companion/features/planner/data/datasources/weekly_planner_datasource.dart';
import 'package:wow_companion/features/planner/domain/entities/weekly_planner.dart';
import 'package:wow_companion/core/l10n/wow_translations.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';

class BuildsListPage extends StatelessWidget {
  final bool showWeeklyPlannerCard;

  const BuildsListPage({super.key, bool? showWeeklyPlannerCard})
    : showWeeklyPlannerCard =
          showWeeklyPlannerCard ?? FeatureFlags.weeklyPlanner;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BuildsCubit>()..loadBuilds(),
      child: _BuildsListView(showWeeklyPlannerCard: showWeeklyPlannerCard),
    );
  }
}

class _BuildsListView extends StatelessWidget {
  final bool showWeeklyPlannerCard;

  const _BuildsListView({required this.showWeeklyPlannerCard});

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
              child: Text(
                state.message,
                style: const TextStyle(color: WowTheme.textSecondary),
              ),
            );
          }
          if (state is BuildsLoaded) {
            if (state.builds.isEmpty) return _buildEmpty(t);
            return _buildList(context, state.builds, showWeeklyPlannerCard);
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
        const Icon(Icons.construction, size: 64, color: WowTheme.textSecondary),
        const SizedBox(height: 12),
        Text(
          t.buildsNoBuildsYet,
          style: const TextStyle(color: WowTheme.textSecondary, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          t.buildsNoBuildsHint,
          style: const TextStyle(color: WowTheme.textSecondary, fontSize: 13),
        ),
      ],
    ),
  );

  Widget _buildList(
    BuildContext context,
    List<Build> builds,
    bool showWeeklyPlannerCard,
  ) {
    final children = <Widget>[
      if (showWeeklyPlannerCard) _WeeklyPlannerSummaryCard(builds: builds),
      ...builds.map((buildData) => _BuildCard(buildData: buildData)),
    ];
    return ListView(padding: const EdgeInsets.all(12), children: children);
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

class _WeeklyPlannerSummaryCard extends StatefulWidget {
  final List<Build> builds;

  const _WeeklyPlannerSummaryCard({required this.builds});

  @override
  State<_WeeklyPlannerSummaryCard> createState() =>
      _WeeklyPlannerSummaryCardState();
}

class _WeeklyPlannerSummaryCardState extends State<_WeeklyPlannerSummaryCard> {
  _PlannerTarget? _target;
  bool _loading = false;
  String? _errorMessage;
  WeeklyPlanner? _planner;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void didUpdateWidget(covariant _WeeklyPlannerSummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_targetKey(oldWidget.builds) != _targetKey(widget.builds)) {
      _refresh();
    }
  }

  String? _targetKey(List<Build> builds) => _pickTarget(builds)?.key;

  _PlannerTarget? _pickTarget(List<Build> builds) {
    final linked = builds.where((build) {
      final key = build.characterRefKey;
      return key != null && key.trim().isNotEmpty;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (linked.isEmpty) return null;
    final key = linked.first.characterRefKey!;
    final parts = key.split('-');
    if (parts.length < 3) return null;
    return _PlannerTarget(
      region: parts[0],
      realm: parts[1],
      name: parts.sublist(2).join('-'),
    );
  }

  Future<void> _refresh() async {
    final target = _pickTarget(widget.builds);
    if (!mounted) return;
    setState(() {
      _target = target;
      _loading = target != null;
      _errorMessage = null;
      _planner = null;
    });

    if (target == null) return;

    try {
      final planner = await sl<WeeklyPlannerDataSource>().getWeeklyPlanner(
        region: target.region,
        realm: target.realm,
        name: target.name,
      );
      if (!mounted) return;
      setState(() {
        _planner = planner;
        _loading = false;
      });
    } on ServerException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _loading = false;
      });
    } on NotFoundException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _loading = false;
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = _target;
    if (target == null) return const SizedBox.shrink();
    final t = S.of(context)!;

    return Card(
      color: WowTheme.surfaceDark,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.weeklyPlannerSummaryTitle,
                        style: const TextStyle(
                          color: WowTheme.primaryGold,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${target.name} · ${target.realm} · ${target.region.toUpperCase()}',
                        style: const TextStyle(
                          color: WowTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _loading ? null : _refresh,
                  tooltip: t.retry,
                  icon: const Icon(Icons.refresh, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_loading && _planner == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: CircularProgressIndicator(
                    color: WowTheme.primaryGold,
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (_errorMessage != null)
              Text(
                localizeFailureMessage(t, _errorMessage!),
                style: const TextStyle(color: WowTheme.textSecondary),
              )
            else if (_planner == null)
              Text(
                t.buildIntelligenceNoData,
                style: const TextStyle(color: WowTheme.textSecondary),
              )
            else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _PlannerMetricChip(
                    label: t.weeklyPlannerCompletion,
                    value: '${_planner!.summary.completionPct}%',
                  ),
                  _PlannerMetricChip(
                    label: t.weeklyPlannerRuns,
                    value: '${_planner!.mythic.weeklyRunsEstimated}',
                  ),
                  _PlannerMetricChip(
                    label: t.weeklyPlannerActions,
                    value: '${_planner!.summary.actionsCount}',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.push(
                      buildWeeklyPlannerRoute(
                        region: target.region,
                        realm: target.realm,
                        name: target.name,
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.calendar_month_outlined,
                    size: 16,
                    color: WowTheme.primaryGold,
                  ),
                  label: Text(
                    t.weeklyPlannerTitle,
                    style: const TextStyle(color: WowTheme.primaryGold),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: WowTheme.primaryGold),
                    minimumSize: const Size(0, 36),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlannerMetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _PlannerMetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: WowTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: WowTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: WowTheme.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: WowTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlannerTarget {
  final String region;
  final String realm;
  final String name;

  const _PlannerTarget({
    required this.region,
    required this.realm,
    required this.name,
  });

  String get key => '$region-$realm-$name'.toLowerCase();
}

// ─── Build card ────────────────────────────────────────────────────────────
class _BuildCard extends StatelessWidget {
  final Build buildData;
  const _BuildCard({required this.buildData});

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    final localeCode = Localizations.localeOf(context).languageCode;
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
                        text: _detailLine(localeCode),
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
    final realm = parts.length >= 2
        ? parts[1]
        : (parts.isNotEmpty ? parts[0] : '');
    final region =
        buildData.characterRefKey?.split('-').firstOrNull?.toUpperCase() ?? '';
    return [realm, region].where((s) => s.isNotEmpty).join(' · ');
  }

  String _detailLine(String localeCode) {
    final parts = <String>[
      if (buildData.characterRace != null)
        WowTranslations.translateRace(buildData.characterRace!, localeCode),
      WowTranslations.translateClass(buildData.characterClass!, localeCode),
      if (buildData.characterSpec != null)
        WowTranslations.translateSpec(buildData.characterSpec!, localeCode),
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
    final t = S.of(context)!;
    final (label, color, icon) = switch (content) {
      BuildContent.raid => (
        t.guideContentRaid,
        const Color(0xFFA335EE),
        Icons.shield_outlined,
      ),
      BuildContent.mythicPlus => (
        'M+',
        const Color(0xFF0070DD),
        Icons.timer_outlined,
      ),
      BuildContent.both => (
        '${t.guideContentRaid} · M+',
        WowTheme.primaryGold,
        Icons.auto_awesome_outlined,
      ),
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
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
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
