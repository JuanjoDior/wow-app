import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';
import 'package:wow_companion/features/builds/domain/entities/spec_recommendation.dart';
import 'package:wow_companion/features/builds/presentation/cubit/build_detail_cubit.dart';
import 'package:wow_companion/features/builds/presentation/cubit/build_detail_state.dart';
import 'package:wow_companion/l10n/generated/app_localizations.dart';

/// Panel colapsable que muestra las recomendaciones de spec cargadas
/// (stats, gemas, consumibles) cuando hay una SpecRecommendation disponible.
///
/// Si no hay datos cargados todavía o el build no tiene spec asignada,
/// el widget no ocupa espacio.
class SpecRecommendationPanel extends StatefulWidget {
  const SpecRecommendationPanel({super.key});

  @override
  State<SpecRecommendationPanel> createState() =>
      _SpecRecommendationPanelState();
}

class _SpecRecommendationPanelState extends State<SpecRecommendationPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = S.of(context)!;
    return BlocBuilder<BuildDetailCubit, BuildDetailState>(
      buildWhen: (prev, next) {
        final prevRec = prev is BuildDetailLoaded ? prev.recommendation : null;
        final nextRec = next is BuildDetailLoaded ? next.recommendation : null;
        return prevRec != nextRec;
      },
      builder: (context, state) {
        if (state is! BuildDetailLoaded) return const SizedBox.shrink();
        final rec = state.recommendation;
        if (rec == null) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          decoration: BoxDecoration(
            color: WowTheme.surfaceDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: WowTheme.accentBlue.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              InkWell(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: WowTheme.accentBlue.withValues(alpha: 0.8),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${t.recPanelTitle}  ',
                                style: TextStyle(
                                  color: WowTheme.accentBlue
                                      .withValues(alpha: 0.9),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              TextSpan(
                                text: _specLabel(rec),
                                style: TextStyle(
                                  color: WowTheme.textSecondary
                                      .withValues(alpha: 0.7),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _SourceBadge(source: rec.source, t: t),
                      const SizedBox(width: 8),
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        color: WowTheme.textSecondary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Contenido ───────────────────────────────────────────────
              if (_expanded) ...[
                const Divider(
                  color: WowTheme.border,
                  height: 1,
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stat priority
                      if (rec.statPriority.isNotEmpty) ...[
                        _PanelLabel(t.recPanelStatPriority),
                        const SizedBox(height: 6),
                        _StatPriorityRow(stats: rec.statPriority),
                        const SizedBox(height: 14),
                      ],

                      // Gemas
                      if (rec.metaGem != null || rec.genericGem != null) ...[
                        _PanelLabel(t.recPanelGems),
                        const SizedBox(height: 6),
                        if (rec.metaGem != null)
                          _RecommendationRow(
                            icon: '\u25c6',
                            iconColor: const Color(0xFFAA00FF),
                            label: t.recPanelGemMeta,
                            name: rec.metaGem!.name,
                            note: rec.metaGem!.note,
                          ),
                        if (rec.genericGem != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: _RecommendationRow(
                              icon: '\u25c6',
                              iconColor: const Color(0xFF00AAFF),
                              label: t.recPanelGemSockets,
                              name: rec.genericGem!.name,
                              note: rec.genericGem!.note,
                            ),
                          ),
                        const SizedBox(height: 14),
                      ],

                      // Consumibles
                      if (_hasConsumables(rec)) ...[
                        _PanelLabel(t.recPanelConsumables),
                        const SizedBox(height: 6),
                        if (rec.flask != null)
                          _RecommendationRow(
                            icon: '\u2697',
                            iconColor: const Color(0xFF2ECC71),
                            label: t.recPanelFlask,
                            name: rec.flask!.name,
                            note: rec.flask!.note,
                          ),
                        if (rec.potion != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: _RecommendationRow(
                              icon: '\u2697',
                              iconColor: const Color(0xFFE74C3C),
                              label: t.recPanelPotion,
                              name: rec.potion!.name,
                              note: rec.potion!.note,
                            ),
                          ),
                        if (rec.food != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: _RecommendationRow(
                              icon: '\u{1F372}',
                              iconColor: const Color(0xFFF39C12),
                              label: t.recPanelFood,
                              name: rec.food!.name,
                              note: rec.food!.note,
                            ),
                          ),
                        if (rec.weaponEnhancement != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: _RecommendationRow(
                              icon: '\u2694',
                              iconColor: WowTheme.primaryGold,
                              label: t.recPanelWeapon,
                              name: rec.weaponEnhancement!.name,
                              note: rec.weaponEnhancement!.note,
                            ),
                          ),
                        const SizedBox(height: 4),
                      ],

                      // Patch / fuente
                      Text(
                        t.recPanelFootnote(rec.patch),
                        style: TextStyle(
                          color: WowTheme.textSecondary.withValues(alpha: 0.45),
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _specLabel(SpecRecommendation rec) {
    final cls = _capitalize(rec.className);
    final spec = _capitalize(rec.specName);
    return '$spec $cls';
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  bool _hasConsumables(SpecRecommendation rec) =>
      rec.flask != null ||
      rec.potion != null ||
      rec.food != null ||
      rec.weaponEnhancement != null;
}

// ─── Source badge ─────────────────────────────────────────────────────────────
class _SourceBadge extends StatelessWidget {
  final RecommendationSource source;
  final S t;
  const _SourceBadge({required this.source, required this.t});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (source) {
      RecommendationSource.remote        => (t.recPanelSourceAI,     WowTheme.accentBlue),
      RecommendationSource.cache         => (t.recPanelSourceCache,  const Color(0xFF2ECC71)),
      RecommendationSource.workerStatic  => (t.recPanelSourceWorker, const Color(0xFFF39C12)),
      RecommendationSource.local         => (t.recPanelSourceLocal,  WowTheme.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─── Stat priority row ────────────────────────────────────────────────────────
class _StatPriorityRow extends StatelessWidget {
  final List<String> stats;
  const _StatPriorityRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: stats.asMap().entries.map((e) {
        final isFirst = e.key == 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isFirst
                ? WowTheme.primaryGold.withValues(alpha: 0.12)
                : WowTheme.border.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: isFirst
                  ? WowTheme.primaryGold.withValues(alpha: 0.4)
                  : WowTheme.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (e.key > 0) ...[
                Text(
                  '${e.key + 1}',
                  style: TextStyle(
                    color: WowTheme.textSecondary.withValues(alpha: 0.5),
                    fontSize: 9,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                e.value,
                style: TextStyle(
                  color: isFirst
                      ? WowTheme.primaryGold
                      : WowTheme.textSecondary,
                  fontSize: 11,
                  fontWeight:
                      isFirst ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Recommendation row ───────────────────────────────────────────────────────
class _RecommendationRow extends StatelessWidget {
  final String icon;
  final Color iconColor;
  final String label;
  final String name;
  final String? note;

  const _RecommendationRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.name,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              color: WowTheme.textSecondary.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ),
        Text(
          '$icon ',
          style: TextStyle(color: iconColor, fontSize: 11),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: WowTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (note != null)
                Text(
                  note!,
                  style: TextStyle(
                    color: WowTheme.textSecondary.withValues(alpha: 0.55),
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Panel label ──────────────────────────────────────────────────────────────
class _PanelLabel extends StatelessWidget {
  final String text;
  const _PanelLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: WowTheme.textSecondary.withValues(alpha: 0.55),
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}
