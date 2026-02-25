/**
 * wow-recommendations Worker  v5
 *
 * Endpoints:
 *   GET  /health
 *   GET  /recommendations?class=druid&spec=feral[&patch=12.0.1][&force=1]
 *   GET  /character?region=eu&realm=sanguino&name=apastar[&force=1]
 *   POST /invalidate   body: { class, spec, patch? }
 *   GET  /specs
 *
 * Flujo /recommendations:
 *  1. Static data embebido → prioridad máxima, siempre disponible y gratuito
 *  2. KV cache            → para specs sin datos estáticos (raro)
 *  3. 404                 → spec no soportada
 *
 * Flujo /character:
 *  1. KV cache (TTL=5min)
 *  2. Blizzard Battle.net API (profile + equipment + statistics + media en paralelo)
 *     → Token OAuth2 client_credentials cacheado en KV (TTL=23h)
 *  3. 404 / 502 si falla Blizzard
 */

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, X-Invalidate-Secret',
};

// ─── Blizzard API base URLs ───────────────────────────────────────────────────
const BLIZZARD_API_BASE = {
  us: 'https://us.api.blizzard.com',
  eu: 'https://eu.api.blizzard.com',
  kr: 'https://kr.api.blizzard.com',
  tw: 'https://tw.api.blizzard.com',
};
const BLIZZARD_OAUTH_URL = 'https://oauth.battle.net/token';
const REALM_SEARCH_LOCALES = {
  us: ['en_US', 'es_MX', 'pt_BR'],
  eu: ['en_GB', 'es_ES', 'fr_FR', 'de_DE', 'it_IT', 'ru_RU'],
  kr: ['ko_KR', 'en_US'],
  tw: ['zh_TW', 'en_US'],
};

// ─── Supported specs (for /specs endpoint) ───────────────────────────────────
export const SUPPORTED_SPECS = [
  // DPS
  { class: 'druid',        spec: 'feral' },
  { class: 'druid',        spec: 'balance' },
  { class: 'evoker',       spec: 'devastation' },
  { class: 'hunter',       spec: 'beast mastery' },
  { class: 'mage',         spec: 'fire' },
  { class: 'paladin',      spec: 'retribution' },
  { class: 'warrior',      spec: 'arms' },
  { class: 'warrior',      spec: 'fury' },
  // Tanks
  { class: 'death knight', spec: 'blood' },
  { class: 'demon hunter', spec: 'vengeance' },
  { class: 'druid',        spec: 'guardian' },
  { class: 'monk',         spec: 'brewmaster' },
  { class: 'paladin',      spec: 'protection' },
  { class: 'warrior',      spec: 'protection' },
  // Healers
  { class: 'druid',        spec: 'restoration' },
  { class: 'evoker',       spec: 'preservation' },
  { class: 'monk',         spec: 'mistweaver' },
  { class: 'priest',       spec: 'discipline' },
  { class: 'priest',       spec: 'holy' },
  { class: 'shaman',       spec: 'restoration' },
];

// ─── Static recommendations data ─────────────────────────────────────────────
// Fuente: Icy Veins Pre-Patch Midnight / Patch 12.0.1 — Febrero 2026
const STATIC_DATA = {

  // ─── DPS ──────────────────────────────────────────────────────────────────

  'druid:feral': {
    enchants: {
      back:     [{ name: "Chant of Burrowing Rapidity", note: "BiS survivability + movement", is_primary: true },
                 { name: "Chant of Winged Grace",       note: "Movement alternative",         is_primary: false }],
      chest:    [{ name: "Stormrider's Agility",        note: "BiS Agility",                  is_primary: true }],
      wrist:    [{ name: "Chant of Armored Speed",      note: "BiS physical",                 is_primary: true },
                 { name: "Chant of Powerful Rituals",   note: "Alternative",                  is_primary: false }],
      legs:     [{ name: "Stormbound Armor Kit",        note: "BiS physical",                 is_primary: true }],
      feet:     [{ name: "Scout's March",               note: "Movement + stats",             is_primary: true },
                 { name: "Cavalry's March",             note: "Alternative",                  is_primary: false }],
      finger1:  [{ name: "Glimmering Mastery",          note: "Sim to confirm",               is_primary: true },
                 { name: "Radiant Haste",               note: "Haste alternative",            is_primary: false },
                 { name: "Glimmering Critical Strike",  note: "Crit alternative",             is_primary: false }],
      finger2:  [{ name: "Glimmering Mastery",          note: "Sim to confirm",               is_primary: true },
                 { name: "Radiant Haste",               note: "Haste alternative",            is_primary: false },
                 { name: "Glimmering Critical Strike",  note: "Crit alternative",             is_primary: false }],
      mainHand: [{ name: "Authority of Radiant Power",  note: "BiS Agility/physical",         is_primary: true },
                 { name: "Authority of Fiery Resolve",  note: "Caster alternative",           is_primary: false }],
      offHand:  [],
    },
    gems: {
      meta:    { name: "Culminating Blasphemite", note: "Meta BiS" },
      generic: { name: "Radiant Mastery",         note: "Sim — Crit/Mastery close" },
    },
    consumables: {
      flask:   { name: "Flask of Alchemical Chaos",        note: "More RNG, net positive" },
      food:    { name: "Feast of the Midnight Masquerade", note: "Group feast (Agility)" },
      potion:  { name: "Tempered Potion",                  note: "With CDs + Bloodlust" },
      weapon:  { name: "Algari Mana Oil",                  note: "Crit + Haste bonus" },
    },
    stat_priority: ["Agility", "Critical Strike", "Mastery", "Haste", "Versatility"],
  },

  'druid:balance': {
    enchants: {
      back:     [{ name: "Chant of Burrowing Rapidity",  note: "Survivability",       is_primary: true }],
      chest:    [{ name: "Stormrider's Intellect",       note: "BiS Intellect",       is_primary: true }],
      wrist:    [{ name: "Chant of Powerful Rituals",    note: "BiS caster",          is_primary: true }],
      legs:     [{ name: "Daybreak Spellthread",         note: "BiS caster",          is_primary: true }],
      feet:     [{ name: "Scout's March",                note: "Movement + stats",    is_primary: true }],
      finger1:  [{ name: "Radiant Haste",                note: "BiS",                 is_primary: true },
                 { name: "Glimmering Critical Strike",   note: "Alternative",         is_primary: false }],
      finger2:  [{ name: "Radiant Haste",                note: "BiS",                 is_primary: true },
                 { name: "Glimmering Critical Strike",   note: "Alternative",         is_primary: false }],
      mainHand: [{ name: "Authority of Fiery Resolve",   note: "BiS caster",          is_primary: true }],
      offHand:  [],
    },
    gems: {
      meta:    { name: "Culminating Blasphemite", note: "Meta BiS" },
      generic: { name: "Energized Ysemerald",     note: "Haste/Crit" },
    },
    consumables: {
      flask:   { name: "Flask of Alchemical Chaos",        note: "Recommended" },
      food:    { name: "Feast of the Midnight Masquerade", note: "Group feast" },
      potion:  { name: "Tempered Potion",                  note: "With major CDs" },
      weapon:  { name: "Algari Mana Oil",                  note: "Crit + Haste" },
    },
    stat_priority: ["Intellect", "Haste", "Critical Strike", "Mastery", "Versatility"],
  },

  'warrior:arms': {
    enchants: {
      back:     [{ name: "Chant of Burrowing Rapidity",  note: "Survivability",       is_primary: true }],
      chest:    [{ name: "Stormrider's Strength",        note: "BiS Strength",        is_primary: true }],
      wrist:    [{ name: "Chant of Armored Speed",       note: "BiS physical",        is_primary: true }],
      legs:     [{ name: "Stormbound Armor Kit",         note: "BiS physical",        is_primary: true }],
      feet:     [{ name: "Scout's March",                note: "Movement + stats",    is_primary: true }],
      finger1:  [{ name: "Glimmering Critical Strike",   note: "BiS",                 is_primary: true },
                 { name: "Glimmering Mastery",           note: "Alternative",         is_primary: false }],
      finger2:  [{ name: "Glimmering Critical Strike",   note: "BiS",                 is_primary: true },
                 { name: "Glimmering Mastery",           note: "Alternative",         is_primary: false }],
      mainHand: [{ name: "Authority of Radiant Power",   note: "BiS physical",        is_primary: true }],
      offHand:  [],
    },
    gems: {
      meta:    { name: "Culminating Blasphemite",  note: "Meta BiS" },
      generic: { name: "Radiant Critical Strike",  note: "BiS" },
    },
    consumables: {
      flask:   { name: "Flask of Alchemical Chaos",        note: "Recommended" },
      food:    { name: "Feast of the Midnight Masquerade", note: "Group feast" },
      potion:  { name: "Tempered Potion",                  note: "With major CDs" },
      weapon:  { name: "Algari Mana Oil",                  note: "Crit + Haste" },
    },
    stat_priority: ["Strength", "Critical Strike", "Mastery", "Haste", "Versatility"],
  },

  'warrior:fury': {
    enchants: {
      back:     [{ name: "Chant of Burrowing Rapidity",  note: "Survivability",       is_primary: true }],
      chest:    [{ name: "Stormrider's Strength",        note: "BiS Strength",        is_primary: true }],
      wrist:    [{ name: "Chant of Armored Speed",       note: "BiS physical",        is_primary: true }],
      legs:     [{ name: "Stormbound Armor Kit",         note: "BiS physical",        is_primary: true }],
      feet:     [{ name: "Scout's March",                note: "Movement + stats",    is_primary: true }],
      finger1:  [{ name: "Radiant Haste",                note: "BiS",                 is_primary: true }],
      finger2:  [{ name: "Radiant Haste",                note: "BiS",                 is_primary: true }],
      mainHand: [{ name: "Authority of Radiant Power",   note: "BiS physical",        is_primary: true }],
      offHand:  [{ name: "Authority of Radiant Power",   note: "Dual wield",          is_primary: true }],
    },
    gems: {
      meta:    { name: "Culminating Blasphemite", note: "Meta BiS" },
      generic: { name: "Energized Ysemerald",     note: "Haste" },
    },
    consumables: {
      flask:   { name: "Flask of Alchemical Chaos",        note: "Recommended" },
      food:    { name: "Feast of the Midnight Masquerade", note: "Group feast" },
      potion:  { name: "Tempered Potion",                  note: "With major CDs" },
      weapon:  { name: "Algari Mana Oil",                  note: "Crit + Haste" },
    },
    stat_priority: ["Strength", "Haste", "Critical Strike", "Mastery", "Versatility"],
  },

  'paladin:retribution': {
    enchants: {
      back:     [{ name: "Chant of Burrowing Rapidity",  note: "Survivability",       is_primary: true }],
      chest:    [{ name: "Stormrider's Strength",        note: "BiS Strength",        is_primary: true }],
      wrist:    [{ name: "Chant of Armored Speed",       note: "BiS physical",        is_primary: true }],
      legs:     [{ name: "Stormbound Armor Kit",         note: "BiS physical",        is_primary: true }],
      feet:     [{ name: "Scout's March",                note: "Movement + stats",    is_primary: true }],
      finger1:  [{ name: "Radiant Haste",                note: "BiS",                 is_primary: true }],
      finger2:  [{ name: "Radiant Haste",                note: "BiS",                 is_primary: true }],
      mainHand: [{ name: "Authority of Radiant Power",   note: "BiS physical",        is_primary: true }],
      offHand:  [],
    },
    gems: {
      meta:    { name: "Culminating Blasphemite", note: "Meta BiS" },
      generic: { name: "Energized Ysemerald",     note: "Haste" },
    },
    consumables: {
      flask:   { name: "Flask of Alchemical Chaos",        note: "Recommended" },
      food:    { name: "Feast of the Midnight Masquerade", note: "Group feast" },
      potion:  { name: "Tempered Potion",                  note: "With major CDs" },
      weapon:  { name: "Algari Mana Oil",                  note: "Crit + Haste" },
    },
    stat_priority: ["Strength", "Haste", "Critical Strike", "Versatility", "Mastery"],
  },

  'mage:fire': {
    enchants: {
      back:     [{ name: "Chant of Burrowing Rapidity",  note: "Survivability",       is_primary: true }],
      chest:    [{ name: "Stormrider's Intellect",       note: "BiS Intellect",       is_primary: true }],
      wrist:    [{ name: "Chant of Powerful Rituals",    note: "BiS caster",          is_primary: true }],
      legs:     [{ name: "Daybreak Spellthread",         note: "BiS caster",          is_primary: true }],
      feet:     [{ name: "Scout's March",                note: "Movement + stats",    is_primary: true }],
      finger1:  [{ name: "Glimmering Critical Strike",   note: "BiS",                 is_primary: true }],
      finger2:  [{ name: "Glimmering Critical Strike",   note: "BiS",                 is_primary: true }],
      mainHand: [{ name: "Authority of Fiery Resolve",   note: "BiS caster",          is_primary: true }],
      offHand:  [],
    },
    gems: {
      meta:    { name: "Culminating Blasphemite",  note: "Meta BiS" },
      generic: { name: "Radiant Critical Strike",  note: "BiS" },
    },
    consumables: {
      flask:   { name: "Flask of Alchemical Chaos",        note: "Recommended" },
      food:    { name: "Feast of the Midnight Masquerade", note: "Group feast" },
      potion:  { name: "Tempered Potion",                  note: "With major CDs" },
      weapon:  { name: "Algari Mana Oil",                  note: "Crit + Haste" },
    },
    stat_priority: ["Intellect", "Critical Strike", "Mastery", "Haste", "Versatility"],
  },

  'hunter:beast mastery': {
    enchants: {
      back:     [{ name: "Chant of Burrowing Rapidity",  note: "Survivability",       is_primary: true }],
      chest:    [{ name: "Stormrider's Agility",         note: "BiS Agility",         is_primary: true }],
      wrist:    [{ name: "Chant of Armored Speed",       note: "BiS physical",        is_primary: true }],
      legs:     [{ name: "Stormbound Armor Kit",         note: "BiS physical",        is_primary: true }],
      feet:     [{ name: "Scout's March",                note: "Movement + stats",    is_primary: true }],
      finger1:  [{ name: "Glimmering Critical Strike",   note: "BiS",                 is_primary: true }],
      finger2:  [{ name: "Glimmering Critical Strike",   note: "BiS",                 is_primary: true }],
      mainHand: [{ name: "Authority of Radiant Power",   note: "BiS physical",        is_primary: true }],
      offHand:  [],
    },
    gems: {
      meta:    { name: "Culminating Blasphemite",  note: "Meta BiS" },
      generic: { name: "Radiant Critical Strike",  note: "BiS" },
    },
    consumables: {
      flask:   { name: "Flask of Alchemical Chaos",        note: "Recommended" },
      food:    { name: "Feast of the Midnight Masquerade", note: "Group feast" },
      potion:  { name: "Tempered Potion",                  note: "With major CDs" },
      weapon:  { name: "Algari Mana Oil",                  note: "Crit + Haste" },
    },
    stat_priority: ["Agility", "Critical Strike", "Haste", "Mastery", "Versatility"],
  },

  'evoker:devastation': {
    enchants: {
      back:     [{ name: "Chant of Burrowing Rapidity", note: "BiS movement",      is_primary: true }],
      chest:    [{ name: "Stormrider's Intellect",      note: "BiS Intellect",     is_primary: true }],
      wrist:    [{ name: "Chant of Powerful Rituals",   note: "BiS caster",        is_primary: true }],
      legs:     [{ name: "Daybreak Spellthread",        note: "BiS caster",        is_primary: true }],
      feet:     [{ name: "Scout's March",               note: "Movement + stats",  is_primary: true }],
      finger1:  [{ name: "Radiant Haste",               note: "BiS",               is_primary: true },
                 { name: "Glimmering Critical Strike",  note: "Alternative",       is_primary: false }],
      finger2:  [{ name: "Radiant Haste",               note: "BiS",               is_primary: true },
                 { name: "Glimmering Critical Strike",  note: "Alternative",       is_primary: false }],
      mainHand: [{ name: "Authority of Fiery Resolve",  note: "BiS caster",        is_primary: true }],
      offHand:  [],
    },
    gems: {
      meta:    { name: "Culminating Blasphemite", note: "Meta BiS" },
      generic: { name: "Quick Ruby",              note: "Fill remaining sockets" },
    },
    consumables: {
      flask:   { name: "Flask of Alchemical Chaos",        note: "Recommended" },
      food:    { name: "Beledar's Bounty",                 note: "Secondary stat food" },
      potion:  { name: "Tempered Potion",                  note: "With major CDs" },
      weapon:  { name: "Crystallized Augment Rune",        note: "Primary stat boost" },
    },
    stat_priority: ["Intellect", "Haste", "Critical Strike", "Mastery", "Versatility"],
  },

  // ─── TANKS ────────────────────────────────────────────────────────────────

  'paladin:protection': {
    enchants: {
      back:     [{ name: "Chant of Burrowing Rapidity", note: "BiS survivability",  is_primary: true }],
      chest:    [{ name: "Stormrider's Strength",       note: "BiS Strength",       is_primary: true }],
      wrist:    [{ name: "Chant of Armored Speed",      note: "BiS physical",       is_primary: true }],
      legs:     [{ name: "Stormbound Armor Kit",        note: "BiS physical",       is_primary: true }],
      feet:     [{ name: "Scout's March",               note: "Movement + stats",   is_primary: true }],
      finger1:  [{ name: "Radiant Haste",               note: "BiS (Templar)",      is_primary: true },
                 { name: "Glimmering Critical Strike",  note: "Lightsmith alt",     is_primary: false }],
      finger2:  [{ name: "Radiant Haste",               note: "BiS (Templar)",      is_primary: true },
                 { name: "Glimmering Critical Strike",  note: "Lightsmith alt",     is_primary: false }],
      mainHand: [{ name: "Authority of the Depths",     note: "BiS tank",           is_primary: true },
                 { name: "Authority of Radiant Power",  note: "Offensive alt",      is_primary: false }],
      offHand:  [],
    },
    gems: {
      meta:    { name: "Culminating Blasphemite", note: "Meta BiS" },
      generic: { name: "Masterful Emerald",       note: "Fill remaining sockets" },
    },
    consumables: {
      flask:   { name: "Flask of Alchemical Chaos",        note: "Recommended" },
      food:    { name: "Feast of the Midnight Masquerade", note: "Group feast" },
      potion:  { name: "Tempered Potion",                  note: "With CDs" },
      weapon:  { name: "Algari Mana Oil",                  note: "Crit + Haste" },
    },
    stat_priority: ["Strength", "Haste", "Mastery", "Versatility", "Critical Strike"],
  },

  'warrior:protection': {
    enchants: {
      back:     [{ name: "Chant of Burrowing Rapidity", note: "BiS survivability",  is_primary: true }],
      chest:    [{ name: "Stormrider's Strength",       note: "BiS Strength",       is_primary: true }],
      wrist:    [{ name: "Chant of Armored Speed",      note: "BiS physical",       is_primary: true }],
      legs:     [{ name: "Stormbound Armor Kit",        note: "BiS physical",       is_primary: true }],
      feet:     [{ name: "Scout's March",               note: "Movement + stats",   is_primary: true }],
      finger1:  [{ name: "Radiant Haste",               note: "BiS",                is_primary: true },
                 { name: "Glimmering Critical Strike",  note: "Alternative",        is_primary: false }],
      finger2:  [{ name: "Radiant Haste",               note: "BiS",                is_primary: true },
                 { name: "Glimmering Critical Strike",  note: "Alternative",        is_primary: false }],
      mainHand: [{ name: "Authority of the Depths",     note: "BiS tank",           is_primary: true },
                 { name: "Authority of Radiant Power",  note: "Offensive alt",      is_primary: false }],
      offHand:  [{ name: "Authority of the Depths",     note: "Shield",             is_primary: true }],
    },
    gems: {
      meta:    { name: "Culminating Blasphemite", note: "Meta BiS" },
      generic: { name: "Deadly Emerald",          note: "Fill remaining sockets" },
    },
    consumables: {
      flask:   { name: "Flask of Alchemical Chaos",        note: "Recommended" },
      food:    { name: "Feast of the Midnight Masquerade", note: "Group feast" },
      potion:  { name: "Tempered Potion",                  note: "Damage / mit CDs" },
      weapon:  { name: "Algari Mana Oil",                  note: "Crit + Haste" },
    },
    stat_priority: ["Strength", "Haste", "Critical Strike", "Versatility", "Mastery"],
  },

  'death knight:blood': {
    enchants: {
      back:     [{ name: "Chant of Burrowing Rapidity", note: "BiS survivability",  is_primary: true }],
      chest:    [{ name: "Stormrider's Strength",       note: "BiS Strength",       is_primary: true }],
      wrist:    [{ name: "Chant of Armored Speed",      note: "BiS physical",       is_primary: true }],
      legs:     [{ name: "Stormbound Armor Kit",        note: "BiS physical",       is_primary: true }],
      feet:     [{ name: "Scout's March",               note: "Movement + stats",   is_primary: true }],
      finger1:  [{ name: "Glimmering Critical Strike",  note: "Deathbringer BiS",   is_primary: true },
                 { name: "Radiant Haste",               note: "San'layn alt",       is_primary: false }],
      finger2:  [{ name: "Glimmering Critical Strike",  note: "Deathbringer BiS",   is_primary: true },
                 { name: "Radiant Haste",               note: "San'layn alt",       is_primary: false }],
      mainHand: [{ name: "Authority of the Depths",     note: "BiS tank",           is_primary: true },
                 { name: "Authority of Radiant Power",  note: "Offensive alt",      is_primary: false }],
      offHand:  [],
    },
    gems: {
      meta:    { name: "Culminating Blasphemite", note: "Meta BiS (damage focus)" },
      generic: { name: "Deadly Emerald",          note: "Sim to confirm" },
    },
    consumables: {
      flask:   { name: "Flask of Alchemical Chaos",        note: "Generic BiS" },
      food:    { name: "Feast of the Midnight Masquerade", note: "Group feast" },
      potion:  { name: "Tempered Potion",                  note: "Damage CDs" },
      weapon:  { name: "Algari Mana Oil",                  note: "Or Ironclaw Whetstone" },
    },
    stat_priority: ["Strength", "Critical Strike", "Versatility", "Mastery", "Haste"],
  },

  'druid:guardian': {
    enchants: {
      back:     [{ name: "Chant of Burrowing Rapidity", note: "BiS survivability",  is_primary: true }],
      chest:    [{ name: "Stormrider's Agility",        note: "BiS Agility",        is_primary: true }],
      wrist:    [{ name: "Chant of Armored Speed",      note: "BiS physical",       is_primary: true }],
      legs:     [{ name: "Stormbound Armor Kit",        note: "BiS physical",       is_primary: true }],
      feet:     [{ name: "Scout's March",               note: "Movement + stats",   is_primary: true }],
      finger1:  [{ name: "Radiant Haste",               note: "BiS survival",       is_primary: true },
                 { name: "Glimmering Critical Strike",  note: "Damage alt",         is_primary: false }],
      finger2:  [{ name: "Radiant Haste",               note: "BiS survival",       is_primary: true },
                 { name: "Glimmering Critical Strike",  note: "Damage alt",         is_primary: false }],
      mainHand: [{ name: "Authority of the Depths",     note: "BiS tank",           is_primary: true },
                 { name: "Authority of Radiant Power",  note: "Damage alt",         is_primary: false }],
      offHand:  [],
    },
    gems: {
      meta:    { name: "Culminating Blasphemite", note: "Meta BiS" },
      generic: { name: "Versatile Emerald",       note: "Fill remaining sockets" },
    },
    consumables: {
      flask:   { name: "Flask of Alchemical Chaos",        note: "Always keep active" },
      food:    { name: "Feast of the Midnight Masquerade", note: "Group feast" },
      potion:  { name: "Tempered Potion",                  note: "With CDs" },
      weapon:  { name: "Crystallized Augment Rune",        note: "Primary stat boost" },
    },
    stat_priority: ["Agility", "Haste", "Versatility", "Mastery", "Critical Strike"],
  },

  'monk:brewmaster': {
    enchants: {
      back:     [{ name: "Chant of Burrowing Rapidity", note: "BiS survivability",  is_primary: true }],
      chest:    [{ name: "Stormrider's Agility",        note: "BiS Agility",        is_primary: true }],
      wrist:    [{ name: "Chant of Armored Speed",      note: "BiS physical",       is_primary: true }],
      legs:     [{ name: "Stormbound Armor Kit",        note: "BiS physical",       is_primary: true }],
      feet:     [{ name: "Scout's March",               note: "Movement + stats",   is_primary: true }],
      finger1:  [{ name: "Glimmering Critical Strike",  note: "BiS offensive",      is_primary: true },
                 { name: "Radiant Versatility",         note: "Defensive alt",      is_primary: false }],
      finger2:  [{ name: "Glimmering Critical Strike",  note: "BiS offensive",      is_primary: true },
                 { name: "Radiant Versatility",         note: "Defensive alt",      is_primary: false }],
      mainHand: [{ name: "Authority of the Depths",     note: "BiS tank",           is_primary: true },
                 { name: "Authority of Radiant Power",  note: "Offensive alt",      is_primary: false }],
      offHand:  [],
    },
    gems: {
      meta:    { name: "Culminating Blasphemite", note: "Meta BiS" },
      generic: { name: "Deadly Sapphire",         note: "Fill remaining sockets" },
    },
    consumables: {
      flask:   { name: "Flask of Alchemical Chaos",        note: "Recommended" },
      food:    { name: "Feast of the Midnight Masquerade", note: "Group feast" },
      potion:  { name: "Tempered Potion",                  note: "With CDs" },
      weapon:  { name: "Ironclaw Weightstone",             note: "Or Algari Mana Oil" },
    },
    stat_priority: ["Agility", "Critical Strike", "Versatility", "Mastery", "Haste"],
  },

  'demon hunter:vengeance': {
    enchants: {
      back:     [{ name: "Chant of Burrowing Rapidity", note: "BiS survivability",  is_primary: true }],
      chest:    [{ name: "Stormrider's Agility",        note: "BiS Agility",        is_primary: true }],
      wrist:    [{ name: "Chant of Armored Speed",      note: "BiS physical",       is_primary: true }],
      legs:     [{ name: "Stormbound Armor Kit",        note: "BiS physical",       is_primary: true }],
      feet:     [{ name: "Scout's March",               note: "Movement + stats",   is_primary: true }],
      finger1:  [{ name: "Radiant Haste",               note: "BiS",                is_primary: true },
                 { name: "Glimmering Critical Strike",  note: "Alternative",        is_primary: false }],
      finger2:  [{ name: "Radiant Haste",               note: "BiS",                is_primary: true },
                 { name: "Glimmering Critical Strike",  note: "Alternative",        is_primary: false }],
      mainHand: [{ name: "Authority of the Depths",     note: "BiS tank",           is_primary: true },
                 { name: "Oil of Deep Toxins",          note: "Offensive alt",      is_primary: false }],
      offHand:  [],
    },
    gems: {
      meta:    { name: "Elusive Blasphemite",    note: "Movement speed BiS" },
      generic: { name: "Deadly Emerald",         note: "Fill remaining sockets" },
    },
    consumables: {
      flask:   { name: "Flask of Alchemical Chaos",        note: "Generic BiS" },
      food:    { name: "Beledar's Bounty",                 note: "Secondary stat food" },
      potion:  { name: "Tempered Potion",                  note: "With CDs" },
      weapon:  { name: "Oil of Deep Toxins",               note: "Or Ironclaw Whetstone" },
    },
    stat_priority: ["Agility", "Haste", "Versatility", "Critical Strike", "Mastery"],
  },

  // ─── HEALERS ──────────────────────────────────────────────────────────────

  'monk:mistweaver': {
    enchants: {
      back:     [{ name: "Chant of Burrowing Rapidity", note: "BiS movement",      is_primary: true }],
      chest:    [{ name: "Stormrider's Intellect",      note: "BiS Intellect",     is_primary: true }],
      wrist:    [{ name: "Chant of Powerful Rituals",   note: "BiS caster",        is_primary: true }],
      legs:     [{ name: "Daybreak Spellthread",        note: "BiS caster",        is_primary: true }],
      feet:     [{ name: "Scout's March",               note: "Movement + stats",  is_primary: true }],
      finger1:  [{ name: "Radiant Haste",               note: "BiS",               is_primary: true },
                 { name: "Glimmering Critical Strike",  note: "Alternative",       is_primary: false }],
      finger2:  [{ name: "Radiant Haste",               note: "BiS",               is_primary: true },
                 { name: "Glimmering Critical Strike",  note: "Alternative",       is_primary: false }],
      mainHand: [{ name: "Authority of Fiery Resolve",  note: "BiS caster",        is_primary: true }],
      offHand:  [],
    },
    gems: {
      meta:    { name: "Elusive Blasphemite", note: "Movement speed BiS" },
      generic: { name: "Deadly Emerald",      note: "Fill remaining sockets" },
    },
    consumables: {
      flask:   { name: "Flask of Tempered Swiftness",      note: "BiS for Mistweaver" },
      food:    { name: "Feast of the Midnight Masquerade", note: "Group feast" },
      potion:  { name: "Slumbering Soul Serum",            note: "Mana; or Algari Mana Potion" },
      weapon:  { name: "Algari Mana Oil",                  note: "Crit + Haste" },
    },
    stat_priority: ["Intellect", "Haste", "Critical Strike", "Versatility", "Mastery"],
  },

  'priest:discipline': {
    enchants: {
      back:     [{ name: "Chant of Burrowing Rapidity", note: "BiS movement",         is_primary: true }],
      chest:    [{ name: "Stormrider's Intellect",      note: "BiS Intellect",        is_primary: true }],
      wrist:    [{ name: "Chant of Powerful Rituals",   note: "BiS caster",           is_primary: true }],
      legs:     [{ name: "Daybreak Spellthread",        note: "BiS caster",           is_primary: true }],
      feet:     [{ name: "Scout's March",               note: "Movement + stats",     is_primary: true }],
      finger1:  [{ name: "Radiant Haste",               note: "Until 20-25% Haste",   is_primary: true },
                 { name: "Glimmering Critical Strike",  note: "Above haste cap",      is_primary: false }],
      finger2:  [{ name: "Radiant Haste",               note: "Until 20-25% Haste",   is_primary: true },
                 { name: "Glimmering Critical Strike",  note: "Above haste cap",      is_primary: false }],
      mainHand: [{ name: "Authority of Fiery Resolve",  note: "BiS caster",           is_primary: true }],
      offHand:  [],
    },
    gems: {
      meta:    { name: "Elusive Blasphemite", note: "Movement speed BiS" },
      generic: { name: "Quick Sapphire",      note: "One of each color for Blasphemite" },
    },
    consumables: {
      flask:   { name: "Flask of Tempered Swiftness",  note: "BiS; or Aggression/Mastery" },
      food:    { name: "Hearty Salt Baked Seafood",    note: "Personal BiS food" },
      potion:  { name: "Slumbering Soul Serum",        note: "Mana; or Algari Mana Potion" },
      weapon:  { name: "Algari Mana Oil",              note: "Crit + Haste" },
    },
    stat_priority: ["Intellect", "Haste", "Critical Strike", "Mastery", "Versatility"],
  },

  'druid:restoration': {
    enchants: {
      back:     [{ name: "Chant of Burrowing Rapidity", note: "BiS movement",      is_primary: true }],
      chest:    [{ name: "Stormrider's Intellect",      note: "BiS Intellect",     is_primary: true }],
      wrist:    [{ name: "Chant of Powerful Rituals",   note: "BiS caster",        is_primary: true }],
      legs:     [{ name: "Daybreak Spellthread",        note: "BiS caster",        is_primary: true }],
      feet:     [{ name: "Scout's March",               note: "Movement + stats",  is_primary: true }],
      finger1:  [{ name: "Radiant Haste",               note: "Raid BiS",          is_primary: true },
                 { name: "Glimmering Mastery",          note: "M+ alt",            is_primary: false }],
      finger2:  [{ name: "Radiant Haste",               note: "Raid BiS",          is_primary: true },
                 { name: "Glimmering Mastery",          note: "M+ alt",            is_primary: false }],
      mainHand: [{ name: "Authority of Fiery Resolve",  note: "BiS caster",        is_primary: true }],
      offHand:  [],
    },
    gems: {
      meta:    { name: "Elusive Blasphemite", note: "Movement speed BiS" },
      generic: { name: "Masterful Emerald",   note: "Fill remaining sockets" },
    },
    consumables: {
      flask:   { name: "Flask of Tempered Swiftness",  note: "BiS; or Tempered Mastery" },
      food:    { name: "Beledar's Bounty",             note: "Personal BiS food" },
      potion:  { name: "Algari Mana Potion",           note: "Mana; Tempered Potion for stats" },
      weapon:  { name: "Algari Mana Oil",              note: "Crit + Haste" },
    },
    stat_priority: ["Intellect", "Haste", "Mastery", "Versatility", "Critical Strike"],
  },

  'evoker:preservation': {
    enchants: {
      back:     [{ name: "Chant of Burrowing Rapidity", note: "BiS movement",      is_primary: true }],
      chest:    [{ name: "Stormrider's Intellect",      note: "BiS Intellect",     is_primary: true }],
      wrist:    [{ name: "Chant of Powerful Rituals",   note: "BiS caster",        is_primary: true }],
      legs:     [{ name: "Daybreak Spellthread",        note: "BiS caster",        is_primary: true }],
      feet:     [{ name: "Scout's March",               note: "Movement + stats",  is_primary: true }],
      finger1:  [{ name: "Glimmering Mastery",          note: "Raid BiS",          is_primary: true },
                 { name: "Glimmering Critical Strike",  note: "M+ alt",            is_primary: false }],
      finger2:  [{ name: "Glimmering Mastery",          note: "Raid BiS",          is_primary: true },
                 { name: "Glimmering Critical Strike",  note: "M+ alt",            is_primary: false }],
      mainHand: [{ name: "Authority of Fiery Resolve",  note: "BiS caster",        is_primary: true }],
      offHand:  [],
    },
    gems: {
      meta:    { name: "Elusive Blasphemite", note: "Movement speed BiS" },
      generic: { name: "Deadly Onyx",         note: "Raid: Masterful alts; M+: Quick alts" },
    },
    consumables: {
      flask:   { name: "Flask of Tempered Mastery",        note: "Healing BiS; Aggression for M+" },
      food:    { name: "Feast of the Midnight Masquerade", note: "Group feast" },
      potion:  { name: "Slumbering Soul Serum",            note: "Mana; Invigorating Healing alt" },
      weapon:  { name: "Crystallized Augment Rune",        note: "Or Ethereal Augment Rune" },
    },
    stat_priority: ["Intellect", "Mastery", "Critical Strike", "Haste", "Versatility"],
  },

  'shaman:restoration': {
    enchants: {
      back:     [{ name: "Chant of Burrowing Rapidity", note: "BiS movement",      is_primary: true }],
      chest:    [{ name: "Stormrider's Intellect",      note: "BiS Intellect",     is_primary: true }],
      wrist:    [{ name: "Chant of Powerful Rituals",   note: "BiS caster",        is_primary: true }],
      legs:     [{ name: "Daybreak Spellthread",        note: "BiS caster",        is_primary: true }],
      feet:     [{ name: "Scout's March",               note: "Movement + stats",  is_primary: true }],
      finger1:  [{ name: "Glimmering Critical Strike",  note: "Raid BiS",          is_primary: true },
                 { name: "Radiant Versatility",         note: "M+ alt",            is_primary: false }],
      finger2:  [{ name: "Glimmering Critical Strike",  note: "Raid BiS",          is_primary: true },
                 { name: "Radiant Versatility",         note: "M+ alt",            is_primary: false }],
      mainHand: [{ name: "Authority of Fiery Resolve",  note: "BiS caster",        is_primary: true }],
      offHand:  [],
    },
    gems: {
      meta:    { name: "Elusive Blasphemite", note: "Movement speed BiS" },
      generic: { name: "Versatile Ruby",      note: "Fill remaining sockets" },
    },
    consumables: {
      flask:   { name: "Flask of Tempered Aggression",  note: "Raid; Tempered Versatility for M+" },
      food:    { name: "Feast of the Divine Day",       note: "Group feast" },
      potion:  { name: "Slumbering Soul Serum",         note: "Mana; Invigorating Healing alt" },
      weapon:  { name: "Algari Mana Oil",               note: "Crit + Haste" },
    },
    stat_priority: ["Intellect", "Critical Strike", "Versatility", "Haste", "Mastery"],
  },

  'priest:holy': {
    enchants: {
      back:     [{ name: "Chant of Burrowing Rapidity", note: "BiS movement",      is_primary: true }],
      chest:    [{ name: "Stormrider's Intellect",      note: "BiS Intellect",     is_primary: true }],
      wrist:    [{ name: "Chant of Powerful Rituals",   note: "BiS caster",        is_primary: true }],
      legs:     [{ name: "Daybreak Spellthread",        note: "BiS caster",        is_primary: true }],
      feet:     [{ name: "Scout's March",               note: "Movement + stats",  is_primary: true }],
      finger1:  [{ name: "Glimmering Critical Strike",  note: "BiS",               is_primary: true }],
      finger2:  [{ name: "Glimmering Critical Strike",  note: "BiS",               is_primary: true }],
      mainHand: [{ name: "Authority of Fiery Resolve",  note: "BiS caster",        is_primary: true }],
      offHand:  [],
    },
    gems: {
      meta:    { name: "Elusive Blasphemite",  note: "Movement; Insightful for mana" },
      generic: { name: "Masterful Ruby",       note: "Fill remaining sockets" },
    },
    consumables: {
      flask:   { name: "Flask of Tempered Aggression",  note: "Raid and M+ BiS" },
      food:    { name: "Hearty Salt Baked Seafood",     note: "Personal BiS food" },
      potion:  { name: "Algari Mana Potion",            note: "Mana; Tempered for damage" },
      weapon:  { name: "Algari Mana Oil",               note: "Crit + Haste" },
    },
    stat_priority: ["Intellect", "Critical Strike", "Versatility", "Mastery", "Haste"],
  },

};

// ─── Router ───────────────────────────────────────────────────────────────────

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: CORS_HEADERS });
    }

    const url = new URL(request.url);

    if (url.pathname === '/health') {
      return json({ status: 'ok', patch: env.CURRENT_PATCH, specs: SUPPORTED_SPECS.length });
    }
    if (url.pathname === '/recommendations' && request.method === 'GET') {
      return handleRecommendations(url, env);
    }
    if (url.pathname === '/character' && request.method === 'GET') {
      return handleCharacter(url, env);
    }
    if (url.pathname === '/invalidate' && request.method === 'POST') {
      return handleInvalidate(request, env);
    }
    if (url.pathname === '/specs' && request.method === 'GET') {
      return handleSpecs(url, env);
    }

    return new Response('Not Found', { status: 404, headers: CORS_HEADERS });
  },
};

// ─── /recommendations ─────────────────────────────────────────────────────────

async function handleRecommendations(url, env) {
  const classParam = (url.searchParams.get('class') || '').toLowerCase().trim();
  const specParam  = (url.searchParams.get('spec')  || '').toLowerCase().trim();
  const patch      = url.searchParams.get('patch') || env.CURRENT_PATCH || '12.0.1';
  const force      = url.searchParams.get('force') === '1';

  if (!classParam || !specParam) {
    return json({ error: 'Missing required params: class, spec' }, 400);
  }

  const cacheKey = buildRecsKey(classParam, specParam, patch);

  // 1. Static data — prioridad máxima.
  const staticKey = `${classParam}:${specParam}`;
  const staticData = STATIC_DATA[staticKey];

  if (staticData && !force) {
    const result = {
      class_name: classParam,
      spec_name:  specParam,
      patch,
      generated_at: new Date().toISOString(),
      ...staticData,
      _source: 'static',
    };
    const ttl = parseInt(env.CACHE_TTL_SECONDS || '604800', 10);
    await env.RECS_CACHE.put(cacheKey, JSON.stringify(result), { expirationTtl: ttl });
    return json(result);
  }

  // 2. KV cache
  if (!force) {
    const cached = await env.RECS_CACHE.get(cacheKey, 'json');
    if (cached) {
      return json({ ...cached, _source: 'cache' });
    }
  }

  return json({ error: `No data available for ${classParam}:${specParam}` }, 404);
}

// ─── /character ───────────────────────────────────────────────────────────────
//
// Obtiene el perfil completo de un personaje desde la Blizzard Battle.net API.
// Datos devueltos: perfil, equipo (con enchants+gemas exactos), estadísticas,
// y URL de render del personaje.
//
// Nota sobre locale: se usa en_US para que los nombres de encantamientos y gemas
// coincidan con nuestra static data de recomendaciones (necesario para el análisis).

async function handleCharacter(url, env) {
  const region = (url.searchParams.get('region') || 'eu').toLowerCase().trim();
  const realmInput = (url.searchParams.get('realm') || '').trim();
  const realmLegacyKeyPart = realmInput.toLowerCase();
  const name   = (url.searchParams.get('name')   || '').toLowerCase().trim();
  const force  = url.searchParams.get('force') === '1';

  if (!realmInput || !name) {
    return json({ error: 'Missing required params: realm, name' }, 400);
  }

  if (!BLIZZARD_API_BASE[region]) {
    return json({ error: `Unknown region: ${region}. Use: us, eu, kr, tw` }, 400);
  }

  const legacyCacheKey = `char:${region}:${realmLegacyKeyPart}:${name}`;
  const cacheTtl = parseInt(env.BLIZZARD_CHAR_CACHE_TTL || '300', 10);

  // 1. Legacy cache alias (pre-realm-canonicalization).
  if (!force) {
    const cachedLegacy = await env.RECS_CACHE.get(legacyCacheKey, 'json');
    if (cachedLegacy) {
      return json({ ...cachedLegacy, _source: 'cache' });
    }
  }

  // 2. Blizzard API
  if (!env.BLIZZARD_CLIENT_SECRET) {
    return json({ error: 'Blizzard API not configured (missing BLIZZARD_CLIENT_SECRET secret)' }, 503);
  }

  try {
    const token = await getBlizzardToken(region, env);
    const realmSlug = await resolveRealmSlug(region, realmInput, token, env);
    const canonicalCacheKey = `char:${region}:${realmSlug}:${name}`;

    if (!force) {
      const cachedCanonical = await env.RECS_CACHE.get(canonicalCacheKey, 'json');
      if (cachedCanonical) {
        return json({ ...cachedCanonical, _source: 'cache' });
      }
    }

    const data = await fetchBlizzardCharacter(region, realmSlug, name, token, env);
    const result = { ...data, _source: 'blizzard' };
    const hasMedia = Boolean(result.avatar_url || result.thumbnail_url);
    const effectiveCacheTtl = hasMedia ? cacheTtl : 60;

    // Cachear resultado con clave canónica.
    await env.RECS_CACHE.put(canonicalCacheKey, JSON.stringify(result), { expirationTtl: effectiveCacheTtl });

    return json(result);
  } catch (err) {
    const status = err.status || 502;
    return json({ error: err.message || 'Blizzard API error' }, status);
  }
}

// ─── Blizzard: token OAuth2 (client_credentials) ─────────────────────────────
//
// El token dura 24h. Lo cacheamos en KV 23h para renovar con margen.
// La clave de KV es `btoken:{region}` (tokens son region-independientes para
// client_credentials, pero usamos clave por región por si cambia en el futuro).

async function getBlizzardToken(region, env) {
  const tokenKey = `btoken:${region}`;

  // Intentar desde KV
  const cached = await env.RECS_CACHE.get(tokenKey, 'json');
  if (cached && cached.expires_at > Date.now()) {
    return cached.access_token;
  }

  // Solicitar nuevo token
  const credentials = btoa(`${env.BLIZZARD_CLIENT_ID}:${env.BLIZZARD_CLIENT_SECRET}`);
  const response = await fetch(BLIZZARD_OAUTH_URL, {
    method: 'POST',
    headers: {
      'Authorization': `Basic ${credentials}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: 'grant_type=client_credentials',
  });

  if (!response.ok) {
    const err = new Error(`Blizzard OAuth failed: ${response.status}`);
    err.status = 502;
    throw err;
  }

  const tokenData = await response.json();

  // Cachear 23h (el token dura 24h)
  const ttl23h = 23 * 60 * 60;
  await env.RECS_CACHE.put(tokenKey, JSON.stringify({
    access_token: tokenData.access_token,
    expires_at:   Date.now() + ttl23h * 1000,
  }), { expirationTtl: ttl23h });

  return tokenData.access_token;
}

function stripDiacritics(str) {
  return String(str || '')
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '');
}

function normalizeRealmLookupValue(value) {
  return stripDiacritics(String(value || '').toLowerCase())
    .replace(/[’']/g, '')
    .replace(/[^\p{L}\p{N}\s-]/gu, ' ')
    .replace(/[-_]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function slugifyRealmValue(value) {
  return String(value || '')
    .toLowerCase()
    .trim()
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function buildRealmSlugCandidates(input) {
  const raw = String(input || '').trim().toLowerCase();
  if (!raw) return [];

  const collapsedWhitespace = raw.replace(/\s+/g, ' ');
  const withoutApostrophes = collapsedWhitespace.replace(/[’']/g, '');
  const withoutDiacritics = stripDiacritics(withoutApostrophes);
  const asciiOnly = withoutDiacritics.replace(/[^a-z0-9\s-]/g, ' ');

  const candidates = [
    slugifyRealmValue(raw),
    slugifyRealmValue(collapsedWhitespace),
    slugifyRealmValue(withoutApostrophes),
    slugifyRealmValue(withoutDiacritics),
    slugifyRealmValue(asciiOnly),
  ].filter(Boolean);

  return [...new Set(candidates)];
}

function isSafeRealmSlug(slug) {
  return /^[a-z0-9-]+$/.test(slug);
}

async function resolveRealmSlug(region, realmInput, token, env) {
  const normalizedRealm = normalizeRealmLookupValue(realmInput);
  if (!normalizedRealm) {
    const err = new Error('Character not found. Check region, realm and name.');
    err.status = 404;
    throw err;
  }

  const cacheKey = `realm_slug:${region}:${normalizedRealm}`;
  try {
    const cached = await env.RECS_CACHE.get(cacheKey);
    if (cached && isSafeRealmSlug(cached)) return cached;
  } catch (_) {
    // Ignore cache failures; realm resolution should still continue.
  }

  const candidates = buildRealmSlugCandidates(realmInput);
  for (const candidate of candidates) {
    const resolved = await tryFetchRealmBySlug(region, candidate, token);
    if (!resolved) continue;

    try {
      const ttl = parseInt(env.BLIZZARD_REALM_CACHE_TTL || '2592000', 10);
      await env.RECS_CACHE.put(cacheKey, resolved, { expirationTtl: ttl });
    } catch (_) {
      // Ignore cache failures.
    }
    return resolved;
  }

  const fromSearch = await searchRealmByName(region, realmInput, token);
  if (fromSearch) {
    try {
      const ttl = parseInt(env.BLIZZARD_REALM_CACHE_TTL || '2592000', 10);
      await env.RECS_CACHE.put(cacheKey, fromSearch, { expirationTtl: ttl });
    } catch (_) {
      // Ignore cache failures.
    }
    return fromSearch;
  }

  const fallbackCandidate = candidates.find(isSafeRealmSlug);
  if (fallbackCandidate) return fallbackCandidate;

  const err = new Error('Character not found. Check region, realm and name.');
  err.status = 404;
  throw err;
}

async function tryFetchRealmBySlug(region, slug, token) {
  if (!slug || !isSafeRealmSlug(slug)) return null;

  const base = BLIZZARD_API_BASE[region];
  const namespace = `dynamic-${region}`;
  const locale = 'en_US';
  const headers = { 'Authorization': `Bearer ${token}` };

  const url =
    `${base}/data/wow/realm/${encodeURIComponent(slug)}` +
    `?namespace=${namespace}&locale=${locale}`;

  try {
    const response = await fetch(url, { headers });
    if (!response.ok) return null;
    const data = await response.json();
    const resolved = String(data?.slug || slug).toLowerCase().trim();
    return isSafeRealmSlug(resolved) ? resolved : slug;
  } catch (_) {
    return null;
  }
}

async function searchRealmByName(region, realmInput, token) {
  const base = BLIZZARD_API_BASE[region];
  const namespace = `dynamic-${region}`;
  const rawInput = String(realmInput || '').trim();
  const normalizedLookup = normalizeRealmLookupValue(rawInput);
  if (!rawInput || !normalizedLookup) return null;

  const locales = REALM_SEARCH_LOCALES[region] || ['en_US'];
  const headers = { 'Authorization': `Bearer ${token}` };
  let fallbackSlug = null;

  for (const locale of locales) {
    const searchFields = [`name.${locale}`, 'name.en_US'];
    for (const searchField of [...new Set(searchFields)]) {
      const searchParams = new URLSearchParams({
        namespace,
        locale,
        _pageSize: '50',
      });
      searchParams.set(searchField, rawInput);

      const url = `${base}/data/wow/search/realm?${searchParams.toString()}`;
      let response;
      try {
        response = await fetch(url, { headers });
      } catch (_) {
        continue;
      }

      if (!response.ok) continue;

      const payload = await response.json();
      const entries = extractRealmSearchEntries(payload);

      for (const entry of entries) {
        const slug = getRealmSlugFromEntry(entry);
        if (!slug) continue;

        if (fallbackSlug === null) fallbackSlug = slug;

        const names = getRealmNamesFromEntry(entry);
        const isExact = names
          .map(normalizeRealmLookupValue)
          .some(name => name === normalizedLookup);

        if (isExact) return slug;
      }
    }
  }

  return fallbackSlug;
}

function extractRealmSearchEntries(payload) {
  const results = Array.isArray(payload?.results) ? payload.results : [];
  return results
    .map(entry => entry?.data || entry)
    .filter(Boolean);
}

function getRealmSlugFromEntry(entry) {
  const candidates = [
    entry?.slug,
    entry?.realm?.slug,
    entry?.key?.slug,
  ];

  for (const candidate of candidates) {
    if (typeof candidate !== 'string') continue;
    const normalized = candidate.trim().toLowerCase();
    if (isSafeRealmSlug(normalized)) return normalized;
  }

  return null;
}

function getRealmNamesFromEntry(entry) {
  const names = [];

  const collect = (value) => {
    if (typeof value === 'string' && value.trim().length > 0) {
      names.push(value.trim());
      return;
    }
    if (value && typeof value === 'object') {
      for (const nested of Object.values(value)) {
        if (typeof nested === 'string' && nested.trim().length > 0) {
          names.push(nested.trim());
        }
      }
    }
  };

  collect(entry?.name);
  collect(entry?.realm?.name);
  collect(entry?.display_string);

  return [...new Set(names)];
}

function extractNumericStatValue(source, preferredKeys = []) {
  if (typeof source === 'number' && Number.isFinite(source)) {
    return source;
  }
  if (!source || typeof source !== 'object') {
    return null;
  }

  const fallbackKeys = ['effective', 'value', 'max', 'base', 'current'];
  const keys = [...preferredKeys, ...fallbackKeys];

  for (const key of keys) {
    const value = source[key];
    if (typeof value === 'number' && Number.isFinite(value)) {
      return value;
    }
  }

  return null;
}

function extractPowerTypeValue(source) {
  if (typeof source === 'string') {
    const normalized = source.trim().toUpperCase().replace(/\s+/g, '_');
    if (/^[A-Z_]+$/.test(normalized)) {
      return normalized;
    }
    return null;
  }

  if (!source || typeof source !== 'object') {
    return null;
  }

  const keys = ['type', 'power_type', 'name', 'id'];
  for (const key of keys) {
    const nested = extractPowerTypeValue(source[key]);
    if (nested) return nested;
  }

  return null;
}

// ─── Blizzard: fetch character data en paralelo ───────────────────────────────

async function fetchBlizzardCharacter(region, realmSlug, name, token, env) {
  const base      = BLIZZARD_API_BASE[region];
  const namespace = `profile-${region}`;
  // en_US para que los nombres de encantamientos/gemas coincidan con nuestra static data
  const locale    = 'en_US';

  // Character name: lowercase + URL-encode (maneja caracteres especiales: Ä, ñ, etc.)
  const charName   = encodeURIComponent(name.toLowerCase());

  const charPath = `/profile/wow/character/${encodeURIComponent(realmSlug)}/${charName}`;
  const qs       = `namespace=${namespace}&locale=${locale}`;
  const headers  = { 'Authorization': `Bearer ${token}` };

  // 4 llamadas en paralelo → minimiza latencia
  const mediaPromise = fetchCharacterMedia(base, charPath, qs, headers);
  const [profileRes, equipRes, statsRes, media] = await Promise.all([
    fetch(`${base}${charPath}?${qs}`,                          { headers }),
    fetch(`${base}${charPath}/equipment?${qs}`,                { headers }),
    fetch(`${base}${charPath}/statistics?${qs}`,               { headers }),
    mediaPromise,
  ]);

  // Profile es el endpoint crítico; si falla → error al cliente
  if (!profileRes.ok) {
    const err = new Error(
      profileRes.status === 404
        ? 'Character not found. Check region, realm and name.'
        : `Blizzard profile API error: ${profileRes.status}`
    );
    err.status = profileRes.status === 404 ? 404 : 502;
    throw err;
  }

  // Parsear respuestas (los demás endpoints son opcionales — si fallan, usamos null)
  const [profile, equip, stats] = await Promise.all([
    profileRes.json(),
    equipRes.ok  ? equipRes.json()  : null,
    statsRes.ok  ? statsRes.json()  : null,
  ]);

  const iconUrlsByItemId = await resolveItemIcons(region, equip, token, env);
  return normalizeCharacter(profile, equip, stats, media, region, iconUrlsByItemId);
}

async function fetchCharacterMedia(base, charPath, qs, headers) {
  const mediaEndpoints = [
    `${base}${charPath}/character-media?${qs}`,
    `${base}${charPath}/character-media/summary?${qs}`,
  ];

  for (const endpoint of mediaEndpoints) {
    try {
      const response = await fetch(endpoint, { headers });
      if (!response.ok) continue;
      return await response.json();
    } catch (_) {
      // Intentar siguiente endpoint.
    }
  }

  return null;
}

// ─── Normalización del personaje ─────────────────────────────────────────────

function normalizeCharacter(profile, equip, stats, media, region, iconUrlsByItemId = {}) {

  // ── Avatar / render ──────────────────────────────────────────────────────
  const mediaUrls = extractCharacterMediaUrls(media);
  const avatarUrl = mediaUrls.renderUrl;
  const thumbnailUrl = mediaUrls.thumbnailUrl;

  // ── Equipo ───────────────────────────────────────────────────────────────
  const equipment = [];
  if (equip?.equipped_items) {
    for (const item of equip.equipped_items) {

      // Encantamientos: sólo tipo PERMANENT (excluye BONUS_SOCKETS, TEMPORARY, etc.)
      // display_string: "Enchanted: Chant of Burrowing Rapidity" → extraemos el nombre
      const enchantments = (item.enchantments || [])
        .filter(e => e.enchantment_slot?.type === 'PERMANENT')
        .map(e => {
          // Primero intentamos source_item.name: "Enchant Cloak - Chant of Burrowing Rapidity"
          // y extraemos lo que va después del primer " - "
          const sourceName = e.source_item?.name || '';
          if (sourceName.includes(' - ')) {
            return sourceName.split(' - ').slice(1).join(' - ').trim();
          }
          // Fallback: display_string menos el prefijo "Enchanted: "
          return (e.display_string || '').replace(/^Enchanted:\s*/i, '').trim();
        })
        .filter(e => e.length > 0);

      // Gemas: sólo sockets que tienen ítem equipado (ignorar sockets vacíos)
      const gems = (item.sockets || [])
        .map(s => s.item?.name || '')
        .filter(g => g.length > 0);

      const itemId = item.item?.id ?? null;

      equipment.push({
        slot:         item.slot?.type  || 'UNKNOWN',
        name:         item.name        || 'Unknown',
        item_level:   item.level?.value ?? 0,
        quality:      item.quality?.type || 'COMMON',
        item_id:      itemId,
        icon_url:     itemId != null ? (iconUrlsByItemId[itemId] ?? null) : null,
        enchantments: enchantments,
        gems:         gems,
        // Blizzard equipment summary no devuelve bonus_ids directamente
        bonus_ids:    [],
      });
    }
  }

  // ── Estadísticas ─────────────────────────────────────────────────────────
  let normalizedStats = null;
  if (stats) {
    // Crítico: melee y spell tienen el mismo rating para la mayoría de specs;
    // usamos melee si existe, spell como fallback
    const critValue =
      extractNumericStatValue(stats.melee_crit, ['value']) ??
      extractNumericStatValue(stats.spell_crit, ['value']);
    const hasteValue =
      extractNumericStatValue(stats.melee_haste, ['value']) ??
      extractNumericStatValue(stats.spell_haste, ['value']);
    const powerType =
      extractPowerTypeValue(stats.power) ??
      extractPowerTypeValue(stats.power_type) ??
      'MANA';

    normalizedStats = {
      health:          extractNumericStatValue(stats.health, ['effective', 'max', 'value']),
      mana:            extractNumericStatValue(stats.power, ['effective', 'value', 'max']),
      power_type:      powerType,
      strength:        extractNumericStatValue(stats.strength, ['effective', 'value', 'base']),
      agility:         extractNumericStatValue(stats.agility, ['effective', 'value', 'base']),
      intellect:       extractNumericStatValue(stats.intellect, ['effective', 'value', 'base']),
      stamina:         extractNumericStatValue(stats.stamina, ['effective', 'value', 'base']),
      critical_strike: critValue,
      haste:           hasteValue,
      mastery:         extractNumericStatValue(stats.mastery, ['value']),
      // versatility_damage_done_bonus ya viene como porcentaje (e.g. 12.0)
      versatility:
        extractNumericStatValue(stats.versatility_damage_done_bonus, ['value']) ??
        extractNumericStatValue(stats.versatility, ['damage_done_bonus', 'value']),
    };
  }

  return {
    name:              profile.name,
    realm:             profile.realm?.name           || '',
    region:            region.toUpperCase(),
    level:             profile.level                 ?? 80,
    race:              profile.race?.name            || 'Unknown',
    class:             profile.character_class?.name || 'Unknown',
    spec:              profile.active_spec?.name     ?? null,
    guild:             profile.guild?.name           ?? null,
    achievement_points: profile.achievement_points   ?? null,
    average_item_level: profile.average_item_level   ?? null,
    equipped_item_level: profile.equipped_item_level ?? null,
    avatar_url:        avatarUrl,
    thumbnail_url:     thumbnailUrl,
    equipment:         equipment,
    stats:             normalizedStats,
  };
}

function extractCharacterMediaUrls(media) {
  const renderUrl = findMediaAssetUrl(media, ['main-raw', 'main']);
  const thumbnailUrl = findMediaAssetUrl(media, ['avatar', 'inset']) || renderUrl;

  return { renderUrl, thumbnailUrl };
}

function findMediaAssetUrl(media, preferredKeys = []) {
  const assets = Array.isArray(media?.assets) ? media.assets : [];
  if (assets.length === 0) return null;

  for (const key of preferredKeys) {
    const matchedAsset = assets.find(asset => asset?.key === key);
    const matchedUrl = extractMediaAssetUrl(matchedAsset);
    if (matchedUrl) return matchedUrl;
  }

  for (const asset of assets) {
    const assetUrl = extractMediaAssetUrl(asset);
    if (assetUrl) return assetUrl;
  }

  return null;
}

function extractMediaAssetUrl(asset) {
  if (!asset) return null;

  const value = asset.value;
  if (typeof value === 'string' && value.trim().length > 0) {
    return value.trim();
  }

  if (value && typeof value === 'object') {
    const href = value.href;
    if (typeof href === 'string' && href.trim().length > 0) {
      return href.trim();
    }
  }

  return null;
}

async function resolveItemIcons(region, equip, token, env) {
  const iconUrlsByItemId = {};
  const equippedItems = equip?.equipped_items;
  if (!Array.isArray(equippedItems) || equippedItems.length === 0) {
    return iconUrlsByItemId;
  }

  const itemIds = [...new Set(
    equippedItems
      .map(item => item?.item?.id)
      .filter(itemId => Number.isInteger(itemId))
  )];

  if (itemIds.length === 0) {
    return iconUrlsByItemId;
  }

  const ttl = parseInt(env.BLIZZARD_ITEM_ICON_CACHE_TTL || '604800', 10);
  const base = BLIZZARD_API_BASE[region];
  const namespace = `static-${region}`;
  const locale = 'en_US';
  const headers = { 'Authorization': `Bearer ${token}` };

  await Promise.all(itemIds.map(async (itemId) => {
    const cacheKey = `itemicon:${region}:${itemId}`;

    try {
      const cachedUrl = await env.RECS_CACHE.get(cacheKey);
      if (cachedUrl && typeof cachedUrl === 'string') {
        iconUrlsByItemId[itemId] = cachedUrl;
        return;
      }
    } catch (_) {
      // Ignorar errores de cache para no romper el perfil completo.
    }

    try {
      const mediaUrl =
        `${base}/data/wow/media/item/${itemId}?namespace=${namespace}&locale=${locale}`;
      const mediaRes = await fetch(mediaUrl, { headers });
      if (!mediaRes.ok) {
        return;
      }

      const media = await mediaRes.json();
      const iconUrl = extractItemIconUrl(media);
      if (!iconUrl) {
        return;
      }

      iconUrlsByItemId[itemId] = iconUrl;
      try {
        await env.RECS_CACHE.put(cacheKey, iconUrl, { expirationTtl: ttl });
      } catch (_) {
        // Ignorar errores de cache; el icono ya se resolvió para esta respuesta.
      }
    } catch (_) {
      // Fallo por item: degradación controlada, icon_url quedará null.
    }
  }));

  return iconUrlsByItemId;
}

function extractItemIconUrl(media) {
  const assets = media?.assets;
  if (!Array.isArray(assets) || assets.length === 0) {
    return null;
  }

  const iconAsset = assets.find(
    asset => asset?.key === 'icon' && typeof asset?.value === 'string' && asset.value.length > 0
  );
  if (iconAsset) {
    return iconAsset.value;
  }

  const firstValidAsset = assets.find(
    asset => typeof asset?.value === 'string' && asset.value.length > 0
  );
  return firstValidAsset?.value ?? null;
}

// ─── /invalidate ─────────────────────────────────────────────────────────────

async function handleInvalidate(request, env) {
  if (env.INVALIDATE_SECRET) {
    const provided = request.headers.get('X-Invalidate-Secret');
    if (provided !== env.INVALIDATE_SECRET) {
      return json({ error: 'Unauthorized' }, 401);
    }
  }

  let body;
  try {
    body = await request.json();
  } catch {
    return json({ error: 'Invalid JSON body' }, 400);
  }

  const classParam = (body.class || '').toLowerCase().trim();
  const specParam  = (body.spec  || '').toLowerCase().trim();
  const patch      = body.patch || env.CURRENT_PATCH || '12.0.1';

  if (!classParam || !specParam) {
    return json({ error: 'Missing required fields: class, spec' }, 400);
  }

  const cacheKey = buildRecsKey(classParam, specParam, patch);
  await env.RECS_CACHE.delete(cacheKey);
  return json({ invalidated: cacheKey, ok: true });
}

// ─── /specs ───────────────────────────────────────────────────────────────────

async function handleSpecs(url, env) {
  const patch = url.searchParams.get('patch') || env.CURRENT_PATCH || '12.0.1';

  const results = await Promise.all(
    SUPPORTED_SPECS.map(async ({ class: cls, spec }) => {
      const key = buildRecsKey(cls, spec, patch);
      const cached = await env.RECS_CACHE.get(key, 'json');
      return {
        class: cls,
        spec,
        cached:       cached !== null,
        generated_at: cached?.generated_at ?? null,
        source:       cached?._source      ?? null,
      };
    })
  );

  return json({ patch, specs: results });
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function buildRecsKey(cls, spec, patch) {
  return `recs:${cls}:${spec.replace(' ', '_')}:${patch}`;
}

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
  });
}
