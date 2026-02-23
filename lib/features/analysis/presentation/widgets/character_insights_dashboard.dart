import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wow_companion/core/di/injection.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';
import 'package:wow_companion/features/analysis/domain/entities/character_insight.dart';
import 'package:wow_companion/features/analysis/presentation/cubit/character_analysis_cubit.dart';
import 'package:wow_companion/features/analysis/presentation/cubit/character_analysis_state.dart';
import 'package:wow_companion/features/analysis/presentation/widgets/insight_card.dart';
import 'package:wow_companion/features/character/domain/entities/character.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';
import 'package:wow_companion/core/l10n/wow_translations.dart';

/// Full insights dashboard injected into CharacterPage.
///
/// Usage:
/// ```dart
/// CharacterInsightsDashboard(character: character)
/// ```
/// The widget creates and manages its own [CharacterAnalysisCubit]
/// internally — no setup required in the parent page.
class CharacterInsightsDashboard extends StatefulWidget {
  final Character character;

  const CharacterInsightsDashboard({super.key, required this.character});

  @override
  State<CharacterInsightsDashboard> createState() =>
      _CharacterInsightsDashboardState();
}

class _CharacterInsightsDashboardState
    extends State<CharacterInsightsDashboard> {
  late final CharacterAnalysisCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<CharacterAnalysisCubit>();
    // Analysis is synchronous — result is available immediately
    _cubit.analyze(widget.character);
  }

  @override
  void didUpdateWidget(CharacterInsightsDashboard old) {
    super.didUpdateWidget(old);
    // Re-run if character changes (refresh)
    if (old.character != widget.character) {
      _cubit.analyze(widget.character);
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    return BlocBuilder<CharacterAnalysisCubit, CharacterAnalysisState>(
      bloc: _cubit,
      builder: (context, state) {
        if (state is! CharacterAnalysisLoaded) return const SizedBox.shrink();

        final result = state.result;
        if (result.insights.isEmpty) return const SizedBox.shrink();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header with issue count ────────────────────────────────
                Row(
                  children: [
                    const Icon(
                      Icons.analytics_outlined,
                      color: WowTheme.primaryGold,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t.analysisTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: WowTheme.primaryGold,
                      ),
                    ),
                    const Spacer(),
                    if (result.hasIssues)
                      _IssueCountBadge(count: result.issueCount),
                  ],
                ),
                const SizedBox(height: 4),
                if (result.specKey != null)
                  Text(
                    t.analysisBased(_formatSpecKey(result.specKey!)),
                    style: const TextStyle(
                      color: WowTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                const SizedBox(height: 12),

                // ── Category sections ─────────────────────────────────────
                _InsightSection(
                  title: t.analysisSectionReadiness,
                  icon: Icons.shield_outlined,
                  insights: result.insights
                      .where((i) =>
                          i.category == InsightCategory.contentReadiness)
                      .toList(),
                ),
                _InsightSection(
                  title: t.analysisSectionEnchantments,
                  icon: Icons.auto_fix_high,
                  insights: result.insights
                      .where((i) =>
                          i.category == InsightCategory.enchantments)
                      .toList(),
                ),
                _InsightSection(
                  title: t.analysisSectionGems,
                  icon: Icons.diamond_outlined,
                  insights: result.insights
                      .where((i) => i.category == InsightCategory.gems)
                      .toList(),
                ),
                _InsightSection(
                  title: t.analysisSectionStats,
                  icon: Icons.bar_chart_outlined,
                  insights: result.insights
                      .where((i) => i.category == InsightCategory.stats)
                      .toList(),
                ),
                _InsightSection(
                  title: t.analysisSectionProgress,
                  icon: Icons.trending_up,
                  insights: result.insights
                      .where(
                          (i) => i.category == InsightCategory.gearProgress)
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatSpecKey(String key) {
    // "mage:frost" → "Escarcha Mago" (traduce con WowTranslations)
    final parts = key.split(':');
    if (parts.length < 2) return key;
    final rawSpec = parts[1].split(' ').map(_capitalize).join(' ');
    final rawCls  = parts[0].split(' ').map(_capitalize).join(' ');
    final spec = WowTranslations.translateSpec(rawSpec);
    final cls  = WowTranslations.translateClass(rawCls);
    return '$spec $cls';
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─── Section ──────────────────────────────────────────────────────────────────

class _InsightSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<CharacterInsight> insights;

  const _InsightSection({
    required this.title,
    required this.icon,
    required this.insights,
  });

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Icon(icon, color: WowTheme.textSecondary, size: 13),
              const SizedBox(width: 5),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: WowTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        for (final insight in insights) InsightCard(insight: insight),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ─── Issue count badge ────────────────────────────────────────────────────────

class _IssueCountBadge extends StatelessWidget {
  final int count;
  const _IssueCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3333).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF3333).withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        () {
          final t = S.of(context)!;
          final word = count == 1 ? t.analysisIssue : t.analysisIssues;
          return '$count $word';
        }(),
        style: const TextStyle(
          color: Color(0xFFFF3333),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
