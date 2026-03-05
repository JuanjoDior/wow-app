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
  String get compareRealmExample => 'ej: sanguino';

  @override
  String get compareNameExample => 'ej: iidrexii';

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
  String get ilvl => 'iLvl';

  @override
  String get character => 'Personaje';

  @override
  String get equipment => 'Equipamiento';

  @override
  String get mythicPlus => 'Mythic+';

  @override
  String get rating => 'Puntuación';

  @override
  String get raid => 'Banda';

  @override
  String get raidProgression => 'Progreso de Banda';

  @override
  String get bestMythicRuns => 'Mejores runs de Mythic+';

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
  String unexpectedError(String error) {
    return 'Error inesperado: $error';
  }

  @override
  String get serverError => 'Algo salió mal en el servidor.';

  @override
  String get serverErrorSuggestion => 'Vuelve a intentarlo en unos segundos.';

  @override
  String get networkError => 'No se pudo conectar a internet.';

  @override
  String get networkErrorSuggestion =>
      'Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get cacheError => 'No se pudieron cargar datos en caché.';

  @override
  String get cacheErrorSuggestion => 'Prueba a recargar.';

  @override
  String get rateLimitError => 'Demasiadas solicitudes.';

  @override
  String get rateLimitErrorSuggestion =>
      'Espera un momento e inténtalo de nuevo.';

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
  String get switchToEnglish => 'English';

  @override
  String get switchToSpanish => 'Español';

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
  String get health => 'Salud';

  @override
  String get stamina => 'Aguante';

  @override
  String get strength => 'Fuerza';

  @override
  String get agility => 'Agilidad';

  @override
  String get intellect => 'Intelecto';

  @override
  String get criticalStrike => 'Golpe Crítico';

  @override
  String get haste => 'Celeridad';

  @override
  String get mastery => 'Maestría';

  @override
  String get versatility => 'Versatilidad';

  @override
  String get mana => 'Maná';

  @override
  String get energy => 'Energía';

  @override
  String get rage => 'Furia';

  @override
  String get runicPower => 'Poder Rúnico';

  @override
  String get focus => 'Concentración';

  @override
  String get maelstrom => 'Maelstrom';

  @override
  String get demonHunterFury => 'Furia del DH';

  @override
  String get pain => 'Dolor';

  @override
  String get essence => 'Esencia';

  @override
  String get astralPower => 'Poder Astral';

  @override
  String get externalRaiderIo => 'Raider.IO';

  @override
  String get externalWorldOfWarcraft => 'World of Warcraft';

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
  String get buildsClassAndSpec => 'Clase y Spec';

  @override
  String get buildsSelectClass => 'Selecciona clase';

  @override
  String get buildsSelectSpec => 'Selecciona spec';

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
  String get slotEnchantmentLabel => 'Encantamiento';

  @override
  String get slotGemsLabel => 'Gemas';

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
  String get unknownItem => 'Objeto desconocido';

  @override
  String get tooltipItemLevel => 'Nivel de Objeto';

  @override
  String get tooltipRequiredLevel => 'Nivel Requerido';

  @override
  String get tooltipType => 'Tipo';

  @override
  String get wowSlotHead => 'Casco';

  @override
  String get wowSlotNeck => 'Cuello';

  @override
  String get wowSlotShoulder => 'Hombros';

  @override
  String get wowSlotBack => 'Capa';

  @override
  String get wowSlotChest => 'Pecho';

  @override
  String get wowSlotWrist => 'Muñequeras';

  @override
  String get wowSlotHands => 'Guantes';

  @override
  String get wowSlotWaist => 'Cinturón';

  @override
  String get wowSlotLegs => 'Piernas';

  @override
  String get wowSlotFeet => 'Botas';

  @override
  String get wowSlotFinger1 => 'Anillo #1';

  @override
  String get wowSlotFinger2 => 'Anillo #2';

  @override
  String get wowSlotTrinket1 => 'Reliquia #1';

  @override
  String get wowSlotTrinket2 => 'Reliquia #2';

  @override
  String get wowSlotMainHand => 'Arma Principal';

  @override
  String get wowSlotOffHand => 'Mano Secundaria';

  @override
  String get buildNotFound => 'Build no encontrada';

  @override
  String get buildIntelligenceTitle => 'Verificación de Build';

  @override
  String get buildIntelligenceSubtitle =>
      'Comparación objetiva del personaje vs tu build objetivo';

  @override
  String get buildIntelligenceNoData => 'No hay datos de análisis disponibles.';

  @override
  String get buildIntelligenceMissingCharacter =>
      'Vincula un personaje para ejecutar el análisis.';

  @override
  String get buildIntelligenceCharacterStatus =>
      'Estado verificable del personaje';

  @override
  String get buildIntelligenceNoTargetHint =>
      'Añade enchants y gemas a tu build para activar acciones de comparación.';

  @override
  String get buildIntelligenceEquippedItems => 'Slots equipados';

  @override
  String get buildIntelligenceEnchantedItems => 'Objetos con enchant';

  @override
  String get buildIntelligenceSockets => 'Sockets con gema';

  @override
  String get buildIntelligenceCompletion => 'Completado';

  @override
  String get buildIntelligenceMissingEnchants => 'Enchants faltantes';

  @override
  String get buildIntelligenceMissingGems => 'Gemas faltantes';

  @override
  String get buildIntelligenceTopActions => 'Acciones principales';

  @override
  String get guideTitle => 'Guía de Build';

  @override
  String get guideContent => 'Contenido';

  @override
  String get guideContentRaid => 'Raid';

  @override
  String get guideContentMythicPlus => 'M+';

  @override
  String get guideContentBoth => 'Ambos';

  @override
  String get guideHeroTalent => 'Hero Talent / Import string';

  @override
  String get guideHeroTalentHint => 'Pega aquí tu import string de talentos...';

  @override
  String get guideRotation => 'Rotación';

  @override
  String guideSpellsCount(int count) {
    return '$count habilidades';
  }

  @override
  String get guideRotationEmpty =>
      'Sin habilidades. Añade tu lista de prioridad.';

  @override
  String get guideAddSpell => 'Añadir habilidad';

  @override
  String get guideSearchSpell => 'Buscar habilidad';

  @override
  String get guideConsumables => 'Consumibles';

  @override
  String get guideFlask => 'Frasco';

  @override
  String get guidePotion => 'Poción';

  @override
  String get guideFood => 'Comida';

  @override
  String get guideNotes => 'Notas';

  @override
  String get guideNotesHint => 'Tips situacionales, notas de cooldowns...';

  @override
  String get consumableTypeFlask => 'Frasco';

  @override
  String get consumableTypePotion => 'Poción';

  @override
  String get consumableTypeFood => 'Comida';

  @override
  String get consumableTypeRune => 'Runa';

  @override
  String get consumableTypeWeapon => 'Arma';

  @override
  String get consumableTypeEnchant => 'Encantamiento';
}
