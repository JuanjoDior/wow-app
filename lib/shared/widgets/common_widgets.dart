import 'package:flutter/material.dart';
import 'package:wow_companion/core/theme/wow_theme.dart';

/// Spinner de carga con mensaje opcional
class WowLoadingWidget extends StatelessWidget {
  final String? message;

  const WowLoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: WowTheme.primaryGold),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(color: WowTheme.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget de error con botón de reintentar
class WowErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const WowErrorWidget({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: WowTheme.accentRed,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: WowTheme.textSecondary,
                fontSize: 16,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Badge que muestra el item level con el color de calidad
class QualityBadge extends StatelessWidget {
  final String quality;
  final int itemLevel;

  const QualityBadge({
    super.key,
    required this.quality,
    required this.itemLevel,
  });

  @override
  Widget build(BuildContext context) {
    final color = WowTheme.getQualityColor(quality);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        '$itemLevel',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}

/// Icono circular con la inicial de la clase y su color
class ClassIcon extends StatelessWidget {
  final String className;
  final double size;

  const ClassIcon({super.key, required this.className, this.size = 32});

  @override
  Widget build(BuildContext context) {
    final color = WowTheme.getClassColor(className);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Text(
          className.isNotEmpty ? className[0].toUpperCase() : '?',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.45,
          ),
        ),
      ),
    );
  }
}

/// Barra de stat con label, valor y barra de progreso opcional
class StatBar extends StatelessWidget {
  final String label;
  final String value;
  final double? percentage;
  final Color? color;

  const StatBar({
    super.key,
    required this.label,
    required this.value,
    this.percentage,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: WowTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color ?? WowTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (percentage != null) ...[
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: (percentage! / 100).clamp(0.0, 1.0),
                backgroundColor: WowTheme.border,
                color: color ?? WowTheme.accentBlue,
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
