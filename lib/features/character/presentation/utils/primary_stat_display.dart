import 'package:wow_companion/features/character/domain/entities/character.dart';

class PrimaryStatDisplay {
  final String label;
  final int value;

  const PrimaryStatDisplay({required this.label, required this.value});
}

PrimaryStatDisplay determinePrimaryStatDisplay(CharacterStats stats) {
  final candidates = <PrimaryStatDisplay>[
    if ((stats.strength ?? 0) > 0)
      PrimaryStatDisplay(label: 'Fuerza', value: stats.strength!),
    if ((stats.agility ?? 0) > 0)
      PrimaryStatDisplay(label: 'Agilidad', value: stats.agility!),
    if ((stats.intellect ?? 0) > 0)
      PrimaryStatDisplay(label: 'Intelecto', value: stats.intellect!),
  ];

  if (candidates.isNotEmpty) {
    return candidates.reduce((a, b) => a.value >= b.value ? a : b);
  }

  if (stats.agility != null) {
    return PrimaryStatDisplay(label: 'Agilidad', value: stats.agility!);
  }
  if (stats.intellect != null) {
    return PrimaryStatDisplay(label: 'Intelecto', value: stats.intellect!);
  }
  if (stats.strength != null) {
    return PrimaryStatDisplay(label: 'Fuerza', value: stats.strength!);
  }

  return const PrimaryStatDisplay(label: 'Fuerza', value: 0);
}
