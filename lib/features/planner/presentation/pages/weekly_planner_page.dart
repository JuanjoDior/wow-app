import 'package:flutter/material.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/core/error/exceptions.dart';
import 'package:wow_companion/core/l10n/failure_localizer.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';
import 'package:wow_companion/features/planner/data/datasources/weekly_planner_datasource.dart';
import 'package:wow_companion/features/planner/domain/entities/weekly_planner.dart';
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
      final planner = await dataSource.getWeeklyPlanner(
        region: widget.region,
        realm: widget.realm,
        name: widget.name,
        force: force,
      );
      if (!mounted) return;
      setState(() {
        _planner = planner;
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
        _ChecklistCard(checklist: planner.checklist),
        const SizedBox(height: 12),
        _ActionsCard(planner: planner),
      ],
    );
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

  const _ChecklistCard({required this.checklist});

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
              t.weeklyPlannerChecklist,
              style: const TextStyle(
                color: WowTheme.primaryGold,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ...checklist.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      entry.done
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 18,
                      color: entry.done
                          ? Colors.greenAccent
                          : WowTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${entry.label} (${entry.current}/${entry.target})',
                        style: const TextStyle(color: WowTheme.textPrimary),
                      ),
                    ),
                  ],
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
                    '• [${action.priorityScore}] ${action.label}',
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
