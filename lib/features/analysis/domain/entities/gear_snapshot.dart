/// Snapshot de la progresión del personaje guardado localmente.
///
/// Se persiste en SharedPreferences con la clave [characterKey]
/// para calcular la evolución de ilvl y score M+ entre sesiones.
class GearSnapshot {
  /// Clave única: 'region:realmSlug:name' (todo en minúsculas).
  final String characterKey;
  final DateTime date;
  final int ilvl;
  final double mplusScore;

  const GearSnapshot({
    required this.characterKey,
    required this.date,
    required this.ilvl,
    required this.mplusScore,
  });

  Map<String, dynamic> toJson() => {
    'characterKey': characterKey,
    'date':         date.toIso8601String(),
    'ilvl':         ilvl,
    'mplusScore':   mplusScore,
  };

  factory GearSnapshot.fromJson(Map<String, dynamic> json) => GearSnapshot(
    characterKey: json['characterKey'] as String,
    date:         DateTime.parse(json['date'] as String),
    ilvl:         json['ilvl'] as int,
    mplusScore:   (json['mplusScore'] as num).toDouble(),
  );
}
