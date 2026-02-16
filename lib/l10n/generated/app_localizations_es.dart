// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class SEs extends S {
  SEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'WoW Companion';

  @override
  String get home => 'Inicio';

  @override
  String get favorites => 'Favoritos';

  @override
  String get items => 'Objetos';

  @override
  String get guides => 'Guías';

  @override
  String get search => 'Buscar';

  @override
  String get searchHint => 'Nombre del personaje';

  @override
  String get realmHint => 'Reino (ej: Sanguino)';

  @override
  String get lookUpCharacter => 'Buscar Personaje';

  @override
  String get compareCharacters => 'Comparar Personajes';

  @override
  String get compare => 'Comparar';

  @override
  String get recentSearches => 'Búsquedas Recientes';

  @override
  String get clearAll => 'Borrar todo';

  @override
  String get regionEurope => 'Europa';

  @override
  String get regionAmericas => 'Américas';

  @override
  String get regionKorea => 'Corea';

  @override
  String get regionTaiwan => 'Taiwán';

  @override
  String level(int level) {
    return 'Nivel $level';
  }

  @override
  String itemLevel(int ilvl) {
    return 'Nivel de Objeto $ilvl';
  }

  @override
  String get ilvl => 'iObj';

  @override
  String get character => 'Personaje';

  @override
  String get equipment => 'Equipamiento';

  @override
  String get mythicPlus => 'Mítica+';

  @override
  String get rating => 'Puntuación';

  @override
  String get raid => 'Banda';

  @override
  String get raidProgression => 'Progreso de Banda';

  @override
  String get bestMythicRuns => 'Mejores Míticas+';

  @override
  String get dungeon => 'Mazmorra';

  @override
  String get lvl => 'Niv';

  @override
  String get time => 'Tiempo';

  @override
  String get score => 'Puntos';

  @override
  String get noEnchantmentsOrGems => 'Sin encantamientos ni gemas';

  @override
  String get viewOnWowhead => 'Ver en Wowhead';

  @override
  String get comparison => 'Comparación';

  @override
  String get loadingCharacter => 'Cargando personaje...';

  @override
  String get loadingBothCharacters => 'Cargando ambos personajes...';

  @override
  String get loadingGuide => 'Cargando guía...';

  @override
  String get characterNotFound =>
      'Personaje no encontrado. Revisa la región, reino y nombre.';

  @override
  String get checkRealmAndName =>
      'Revisa la región, el reino y el nombre del personaje.';

  @override
  String get enterRealmAndName => 'Introduce reino y nombre del personaje';

  @override
  String get retry => 'Reintentar';

  @override
  String get equipmentComparison => 'Comparación de Equipo';

  @override
  String get char1 => 'Personaje 1';

  @override
  String get char2 => 'Personaje 2';

  @override
  String get quickCheatsheets => 'Guías Rápidas';

  @override
  String get cheatsheetsSubtitle =>
      'Prioridad de stats, rotaciones y consumibles de un vistazo';

  @override
  String get all => 'Todos';

  @override
  String get dps => 'DPS';

  @override
  String get healer => 'Sanador';

  @override
  String get tank => 'Tanque';

  @override
  String get statPriority => 'Prioridad de Estadísticas';

  @override
  String get rotation => 'Rotación / Prioridad';

  @override
  String get consumables => 'Consumibles';

  @override
  String get tips => 'Consejos';

  @override
  String lastUpdated(String date) {
    return 'Última actualización: $date';
  }

  @override
  String get guideNotFound => 'Guía no encontrada.';

  @override
  String get normal => 'Normal';

  @override
  String get heroic => 'Heroica';

  @override
  String get mythic => 'Mítica';

  @override
  String get progression => 'Progreso';

  @override
  String get region => 'Región';

  @override
  String get realm => 'Reino';

  @override
  String get characterName => 'Nombre del Personaje';

  @override
  String get noFavoritesYet => 'Aún no hay favoritos';

  @override
  String get favoritesHint => 'Busca un personaje y pulsa ★ para guardarlo';

  @override
  String get itemCatalog => 'Catálogo de Objetos';

  @override
  String get comingSoon => 'Próximamente';

  @override
  String get character1 => 'Personaje 1';

  @override
  String get character2 => 'Personaje 2';

  @override
  String get slot => 'Slot';

  @override
  String get builds => 'Builds';

  @override
  String get vs => 'VS';

  @override
  String get buildsNoBuildsYet => 'Aún no hay builds';

  @override
  String get buildsNoBuildsHint => 'Pulsa + para crear tu primera build';

  @override
  String get buildsNewBuild => 'Nueva Build';

  @override
  String get buildsBuildName => 'Nombre de la build (ej: Pícaro M+ Asesinato)';

  @override
  String get buildsGenericBuild => 'Build genérica (sin personaje)';

  @override
  String get buildsNoFavoritesYet => 'Aún no hay favoritos guardados';

  @override
  String get buildsLinkCharacter => 'Vincular a personaje (opcional)';

  @override
  String get buildsCreate => 'Crear';

  @override
  String get buildsCancel => 'Cancelar';

  @override
  String get buildsDeleteTitle => 'Eliminar build';

  @override
  String buildsDeleteConfirm(String name) {
    return '¿Eliminar \"$name\"?';
  }

  @override
  String get buildsDelete => 'Eliminar';

  @override
  String buildsSlots(int obtained, int total) {
    return '$obtained/$total slots';
  }

  @override
  String get slotAssignItem => 'Asignar objeto';

  @override
  String get slotClearSlot => 'Limpiar slot';

  @override
  String get slotAddEnchantment => 'Añadir encantamiento';

  @override
  String get slotRemoveEnchantment => 'Eliminar encantamiento';

  @override
  String get slotAddGem => '+ Gema';

  @override
  String slotSearchItem(String slot) {
    return 'Buscar $slot';
  }

  @override
  String get slotSearchEnchantment => 'Buscar Encantamiento';

  @override
  String get slotSearchGem => 'Buscar Gema';

  @override
  String get searchTypeAtLeast => 'Escribe al menos 2 caracteres...';

  @override
  String get searchNoResults => 'Sin resultados';

  @override
  String get searchLoading => 'Buscando...';

  @override
  String get tooltipItemLevel => 'Nivel de Objeto';

  @override
  String get tooltipRequiredLevel => 'Nivel Requerido';

  @override
  String get tooltipType => 'Tipo';
}
