import 'package:wow_companion/features/character/domain/entities/character.dart';

class PrimaryStatDisplay {
  final String statKey;
  final int value;

  const PrimaryStatDisplay({required this.statKey, required this.value});
}

PrimaryStatDisplay determinePrimaryStatDisplay(CharacterStats stats) {
  final candidates = <PrimaryStatDisplay>[
    if ((stats.strength ?? 0) > 0)
      PrimaryStatDisplay(statKey: 'strength', value: stats.strength!),
    if ((stats.agility ?? 0) > 0)
      PrimaryStatDisplay(statKey: 'agility', value: stats.agility!),
    if ((stats.intellect ?? 0) > 0)
      PrimaryStatDisplay(statKey: 'intellect', value: stats.intellect!),
  ];

  if (candidates.isNotEmpty) {
    return candidates.reduce((a, b) => a.value >= b.value ? a : b);
  }

  if (stats.agility != null) {
    return PrimaryStatDisplay(statKey: 'agility', value: stats.agility!);
  }
  if (stats.intellect != null) {
    return PrimaryStatDisplay(statKey: 'intellect', value: stats.intellect!);
  }
  if (stats.strength != null) {
    return PrimaryStatDisplay(statKey: 'strength', value: stats.strength!);
  }

  return const PrimaryStatDisplay(statKey: 'strength', value: 0);
}
