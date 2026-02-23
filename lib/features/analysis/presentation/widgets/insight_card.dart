import 'package:flutter/material.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';
import 'package:wow_companion/features/analysis/domain/entities/character_insight.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';

// ─── Insight card ─────────────────────────────────────────────────────────────

/// Collapsible card that shows one [CharacterInsight].
///
/// Collapsed: icon + title + severity badge
/// Expanded: description, mode-toggle (simple/advanced), action items
class InsightCard extends StatefulWidget {
  final CharacterInsight insight;

  const InsightCard({super.key, required this.insight});

  @override
  State<InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<InsightCard> {
  bool _expanded = false;
  bool _showAdvanced = false;

  @override
  Widget build(BuildContext context) {
    final insight = widget.insight;
    final color = _colorForSeverity(insight.severity);
    final icon = _iconForSeverity(insight.severity);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: WowTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        insight.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: WowTheme.textPrimary,
                        ),
                      ),
                    ),
                    _SeverityBadge(severity: insight.severity),
                    const SizedBox(width: 8),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: WowTheme.textSecondary,
                      size: 18,
                    ),
                  ],
                ),
              ),

              // ── Expanded body ────────────────────────────────────────────
              if (_expanded) ...[
                const Divider(height: 1, color: WowTheme.border),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description
                      Text(
                        insight.description,
                        style: const TextStyle(
                          color: WowTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Simple / Advanced toggle
                      _ExplanationSection(
                        simple: insight.simpleExplanation,
                        advanced: insight.advancedDetail,
                        showAdvanced: _showAdvanced,
                        onToggle: (v) => setState(() => _showAdvanced = v),
                      ),

                      // Action items
                      if (insight.actionItems.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _ActionItems(items: insight.actionItems),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _colorForSeverity(InsightSeverity s) => switch (s) {
    InsightSeverity.critical => const Color(0xFFFF3333),
    InsightSeverity.warning => const Color(0xFFFFAA00),
    InsightSeverity.info => const Color(0xFF4FC3F7),
    InsightSeverity.positive => const Color(0xFF66BB6A),
  };

  IconData _iconForSeverity(InsightSeverity s) => switch (s) {
    InsightSeverity.critical => Icons.error_outline,
    InsightSeverity.warning => Icons.warning_amber_rounded,
    InsightSeverity.info => Icons.info_outline,
    InsightSeverity.positive => Icons.check_circle_outline,
  };
}

// ─── Severity badge ───────────────────────────────────────────────────────────

class _SeverityBadge extends StatelessWidget {
  final InsightSeverity severity;
  const _SeverityBadge({required this.severity});

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    final (label, color) = switch (severity) {
      InsightSeverity.critical => (t.insightBadgeFix,    const Color(0xFFFF3333)),
      InsightSeverity.warning  => (t.insightBadgeImprove, const Color(0xFFFFAA00)),
      InsightSeverity.info     => (t.insightBadgeInfo,   const Color(0xFF4FC3F7)),
      InsightSeverity.positive => (t.insightBadgeGood,   const Color(0xFF66BB6A)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Explanation section ──────────────────────────────────────────────────────

class _ExplanationSection extends StatelessWidget {
  final String simple;
  final String? advanced;
  final bool showAdvanced;
  final ValueChanged<bool> onToggle;

  const _ExplanationSection({
    required this.simple,
    required this.advanced,
    required this.showAdvanced,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    final hasAdvanced = advanced != null && advanced!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasAdvanced)
          Row(
            children: [
              _ModeChip(
                label: t.insightModeSimple,
                selected: !showAdvanced,
                onTap: () => onToggle(false),
              ),
              const SizedBox(width: 6),
              _ModeChip(
                label: t.insightModeAdvanced,
                selected: showAdvanced,
                onTap: () => onToggle(true),
              ),
            ],
          ),
        if (hasAdvanced) const SizedBox(height: 8),
        Text(
          showAdvanced && hasAdvanced ? advanced! : simple,
          style: const TextStyle(
            color: WowTheme.textSecondary,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: selected
              ? WowTheme.primaryGold.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected
                ? WowTheme.primaryGold.withValues(alpha: 0.5)
                : WowTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? WowTheme.primaryGold : WowTheme.textSecondary,
            fontSize: 10,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ─── Action items ─────────────────────────────────────────────────────────────

class _ActionItems extends StatelessWidget {
  final List<String> items;
  const _ActionItems({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context)!.insightActionSteps,
          style: const TextStyle(
            color: WowTheme.primaryGold,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        for (final (index, item) in items.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${index + 1}.',
                  style: const TextStyle(
                    color: WowTheme.primaryGold,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: WowTheme.textPrimary,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
