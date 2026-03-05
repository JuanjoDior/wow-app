import 'package:flutter/material.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/core/error/exceptions.dart';
import 'package:wow_companion/core/l10n/failure_localizer.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';
import 'package:wow_companion/features/planner/data/datasources/weekly_planner_datasource.dart';
import 'package:wow_companion/features/planner/data/repositories/weekly_planner_local_progress_repository.dart';
import 'package:wow_companion/features/planner/domain/entities/weekly_planner.dart';
import 'package:wow_companion/features/planner/domain/services/weekly_planner_local_progress.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';

class WeeklyPlannerPage extends StatefulWidget {
  final String region;
  final String realm;
  final String name;

  const WeeklyPlannerPage({
    super.key,
    required this.region,
    required this.realm,
    required this.name,
  });

  @override
  State<WeeklyPlannerPage> createState() => _WeeklyPlannerPageState();
}

class _WeeklyPlannerPageState extends State<WeeklyPlannerPage> {
  bool _loading = true;
  String? _error;
  WeeklyPlanner? _planner;
  WeeklyPlanner? _rawPlanner;
  Set<String> _objectiveDoneTaskIds = <String>{};
  Set<String> _localDoneTaskIds = <String>{};
  String? _plannerWeekKey;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool force = false}) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final dataSource = sl<WeeklyPlannerDataSource>();
      final progressRepository = sl<WeeklyPlannerLocalProgressRepository>();
      final planner = await dataSource.getWeeklyPlanner(
        region: widget.region,
        realm: widget.realm,
        name: widget.name,
        force: force,
      );
      final plannerKey = progressRepository.buildPlannerKey(
        region: widget.region,
        realm: widget.realm,
        name: widget.name,
      );
      final weekKey = progressRepository.buildWeekKey(
        planner.generatedAt ?? DateTime.now().toUtc(),
      );
      final objectiveDoneTaskIds = planner.checklist
          .where((entry) => entry.done)
          .map((entry) => entry.id)
          .toSet();
      final localDoneTaskIds =
          await progressRepository.getCompletedTaskIds(
              plannerKey: plannerKey,
              weekKey: weekKey,
            )
            ..removeWhere((taskId) => objectiveDoneTaskIds.contains(taskId));
      final effectivePlanner = applyWeeklyPlannerLocalProgress(
        planner,
        localDoneTaskIds,
      );
      if (!mounted) return;
      setState(() {
        _rawPlanner = planner;
        _planner = effectivePlanner;
        _objectiveDoneTaskIds = objectiveDoneTaskIds;
        _localDoneTaskIds = localDoneTaskIds;
        _plannerWeekKey = weekKey;
        _loading = false;
      });
    } on ServerException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } on NotFoundException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.weeklyPlannerTitle),
        actions: [
          IconButton(
            onPressed: _loading ? null : () => _load(force: true),
            tooltip: t.retry,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(t),
    );
  }

  Widget _buildBody(S t) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: WowTheme.primaryGold),
      );
    }

    if (_error != null) {
      final normalized = _error!.toLowerCase();
      final message = normalized.contains('weekly_planner')
          ? t.weeklyPlannerUnavailable
          : localizeFailureMessage(t, _error!);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: WowTheme.textSecondary),
          ),
        ),
      );
    }

    final planner = _planner;
    if (planner == null) {
      return Center(
        child: Text(
          t.buildIntelligenceNoData,
          style: const TextStyle(color: WowTheme.textSecondary),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${planner.name} · ${planner.realm} · ${planner.region.toUpperCase()}',
          style: const TextStyle(color: WowTheme.textSecondary),
        ),
        const SizedBox(height: 10),
        _SummaryCard(planner: planner),
        const SizedBox(height: 12),
        _AffixesCard(affixes: planner.affixes),
        const SizedBox(height: 12),
        _ChecklistCard(
          checklist: planner.checklist,
          objectiveDoneTaskIds: _objectiveDoneTaskIds,
          hasLocalProgress: _localDoneTaskIds.isNotEmpty,
          onToggleTask: _toggleTask,
          onResetLocalProgress: _resetLocalProgress,
        ),
        const SizedBox(height: 12),
        _ActionsCard(planner: planner),
      ],
    );
  }

  Future<void> _toggleTask(WeeklyPlannerChecklistItem item, bool done) async {
    if (_objectiveDoneTaskIds.contains(item.id)) return;
    final rawPlanner = _rawPlanner;
    final weekKey = _plannerWeekKey;
    if (rawPlanner == null || weekKey == null) return;

    final progressRepository = sl<WeeklyPlannerLocalProgressRepository>();
    final plannerKey = progressRepository.buildPlannerKey(
      region: widget.region,
      realm: widget.realm,
      name: widget.name,
    );

    final updatedLocalDoneTaskIds = {..._localDoneTaskIds};
    if (done) {
      updatedLocalDoneTaskIds.add(item.id);
    } else {
      updatedLocalDoneTaskIds.remove(item.id);
    }
    await progressRepository.setCompletedTaskIds(
      plannerKey: plannerKey,
      weekKey: weekKey,
      taskIds: updatedLocalDoneTaskIds,
    );

    if (!mounted) return;
    setState(() {
      _localDoneTaskIds = updatedLocalDoneTaskIds;
      _planner = applyWeeklyPlannerLocalProgress(
        rawPlanner,
        updatedLocalDoneTaskIds,
      );
    });
  }

  Future<void> _resetLocalProgress() async {
    final rawPlanner = _rawPlanner;
    final weekKey = _plannerWeekKey;
    if (rawPlanner == null || weekKey == null) return;

    final progressRepository = sl<WeeklyPlannerLocalProgressRepository>();
    final plannerKey = progressRepository.buildPlannerKey(
      region: widget.region,
      realm: widget.realm,
      name: widget.name,
    );
    await progressRepository.clearCompletedTaskIds(
      plannerKey: plannerKey,
      weekKey: weekKey,
    );

    if (!mounted) return;
    setState(() {
      _localDoneTaskIds = <String>{};
      _planner = rawPlanner;
    });
  }
}

class _SummaryCard extends StatelessWidget {
  final WeeklyPlanner planner;

  const _SummaryCard({required this.planner});

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.weeklyPlannerSummaryTitle,
              style: const TextStyle(
                color: WowTheme.primaryGold,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricChip(
                  label: t.weeklyPlannerCompletion,
                  value: '${planner.summary.completionPct}%',
                ),
                _MetricChip(
                  label: t.weeklyPlannerChecks,
                  value:
                      '${planner.summary.checksCompleted}/${planner.summary.checksTotal}',
                ),
                _MetricChip(
                  label: t.weeklyPlannerRuns,
                  value: '${planner.mythic.weeklyRunsEstimated}',
                ),
                _MetricChip(
                  label: t.weeklyPlannerRating,
                  value: planner.mythic.rating?.toStringAsFixed(0) ?? '—',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AffixesCard extends StatelessWidget {
  final List<String> affixes;

  const _AffixesCard({required this.affixes});

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.weeklyPlannerAffixes,
              style: const TextStyle(
                color: WowTheme.primaryGold,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (affixes.isEmpty)
              Text(
                t.weeklyPlannerNoAffixes,
                style: const TextStyle(color: WowTheme.textSecondary),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: affixes
                    .map(
                      (affix) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: WowTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: WowTheme.border),
                        ),
                        child: Text(
                          affix,
                          style: const TextStyle(color: WowTheme.textPrimary),
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  final List<WeeklyPlannerChecklistItem> checklist;
  final Set<String> objectiveDoneTaskIds;
  final bool hasLocalProgress;
  final Future<void> Function(WeeklyPlannerChecklistItem item, bool done)
  onToggleTask;
  final Future<void> Function() onResetLocalProgress;

  const _ChecklistCard({
    required this.checklist,
    required this.objectiveDoneTaskIds,
    required this.hasLocalProgress,
    required this.onToggleTask,
    required this.onResetLocalProgress,
  });

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.weeklyPlannerChecklist,
                    style: const TextStyle(
                      color: WowTheme.primaryGold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (hasLocalProgress)
                  TextButton(
                    onPressed: onResetLocalProgress,
                    child: Text(
                      t.weeklyPlannerResetLocalProgress,
                      style: const TextStyle(color: WowTheme.primaryGold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ...checklist.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: CheckboxListTile(
                  key: ValueKey('planner-check-${entry.id}'),
                  value: entry.done,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: Colors.greenAccent,
                  checkColor: Colors.black,
                  onChanged: objectiveDoneTaskIds.contains(entry.id)
                      ? null
                      : (value) => onToggleTask(entry, value ?? false),
                  title: Text(
                    '${_localizePlannerTaskLabel(t, entry.id, entry.label)} (${entry.current}/${entry.target})',
                    style: const TextStyle(color: WowTheme.textPrimary),
                  ),
                  subtitle: objectiveDoneTaskIds.contains(entry.id)
                      ? Text(
                          t.weeklyPlannerObjectiveCompleted,
                          style: const TextStyle(
                            color: WowTheme.textSecondary,
                            fontSize: 11,
                          ),
                        )
                      : null,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionsCard extends StatelessWidget {
  final WeeklyPlanner planner;

  const _ActionsCard({required this.planner});

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.weeklyPlannerActions,
              style: const TextStyle(
                color: WowTheme.primaryGold,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (planner.actions.isEmpty)
              Text(
                t.weeklyPlannerNoActions,
                style: const TextStyle(color: WowTheme.textSecondary),
              )
            else
              ...planner.actions.map(
                (action) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '• [${action.priorityScore}] ${_localizePlannerActionLabel(t, action)}',
                    style: const TextStyle(color: WowTheme.textSecondary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _localizePlannerTaskLabel(S t, String id, String fallbackLabel) {
  return switch (id) {
    'enchants_completed' => t.weeklyPlannerTaskEnchantsCompleted,
    'sockets_filled' => t.weeklyPlannerTaskSocketsFilled,
    'mplus_one_run' => t.weeklyPlannerTaskMplusOne,
    'mplus_four_runs' => t.weeklyPlannerTaskMplusFour,
    'mplus_eight_runs' => t.weeklyPlannerTaskMplusEight,
    _ => fallbackLabel,
  };
}

String _localizePlannerActionLabel(S t, WeeklyPlannerAction action) {
  final base = _localizePlannerTaskLabel(t, action.type, action.label);
  if (action.remaining > 0) {
    return t.weeklyPlannerActionRemaining(base, action.remaining);
  }
  return base;
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetricChip({required this.label, required this.value});

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
