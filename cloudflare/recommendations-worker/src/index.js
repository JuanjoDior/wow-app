/**
 * wow-recommendations Worker  v3
 *
 * Flujo de resolución:
 *  1. KV cache  → devuelve si existe
 *  2. Groq API  → genera con Llama 3.3 70B (gratuito, sin tarjeta)
 *  3. Static fallback → datos embebidos por spec (siempre disponible, gratis)
 *
 * Endpoints:
 *   GET  /health
 *   GET  /recommendations?class=druid&spec=feral[&patch=12.0.1][&force=1]
 *   POST /invalidate   body: { class, spec, patch? }
 *   GET  /specs
 */

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, X-Invalidate-Secret',
};

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

// ─── Static fallback data ─────────────────────────────────────────────────────
// Fuente: Icy Veins Pre-Patch Midnight / Patch 12.0.1 — Febrero 2026
// Cubre specs Tier S y A en Tanks, Healers y DPS principales.
// Actualizar aquí con cada parche relevante.

const STATIC_DATA = {

  // ─────────────────────────────────────────────────────────────────────────
  // DPS
  // ─────────────────────────────────────────────────────────────────────────

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
      flask:   { name: "Flask of Alchemical Chaos",       note: "More RNG, net positive" },
      food:    { name: "Feast of the Midnight Masquerade", note: "Group feast (Agility)" },
      potion:  { name: "Tempered Potion",                 note: "With CDs + Bloodlust" },
      weapon:  { name: "Algari Mana Oil",                 note: "Crit + Haste bonus" },
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
      flask:   { name: "Flask of Alchemical Chaos",       note: "Recommended" },
      food:    { name: "Feast of the Midnight Masquerade", note: "Group feast" },
      potion:  { name: "Tempered Potion",                 note: "With major CDs" },
      weapon:  { name: "Algari Mana Oil",                 note: "Crit + Haste" },
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
      flask:   { name: "Flask of Alchemical Chaos",       note: "Recommended" },
      food:    { name: "Feast of the Midnight Masquerade", note: "Group feast" },
      potion:  { name: "Tempered Potion",                 note: "With major CDs" },
      weapon:  { name: "Algari Mana Oil",                 note: "Crit + Haste" },
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
      flask:   { name: "Flask of Alchemical Chaos",       note: "Recommended" },
      food:    { name: "Feast of the Midnight Masquerade", note: "Group feast" },
      potion:  { name: "Tempered Potion",                 note: "With major CDs" },
      weapon:  { name: "Algari Mana Oil",                 note: "Crit + Haste" },
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
      flask:   { name: "Flask of Alchemical Chaos",       note: "Recommended" },
      food:    { name: "Feast of the Midnight Masquerade", note: "Group feast" },
      potion:  { name: "Tempered Potion",                 note: "With major CDs" },
      weapon:  { name: "Algari Mana Oil",                 note: "Crit + Haste" },
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
      flask:   { name: "Flask of Alchemical Chaos",       note: "Recommended" },
      food:    { name: "Feast of the Midnight Masquerade", note: "Group feast" },
      potion:  { name: "Tempered Potion",                 note: "With major CDs" },
      weapon:  { name: "Algari Mana Oil",                 note: "Crit + Haste" },
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
      flask:   { name: "Flask of Alchemical Chaos",       note: "Recommended" },
      food:    { name: "Feast of the Midnight Masquerade", note: "Group feast" },
      potion:  { name: "Tempered Potion",                 note: "With major CDs" },
      weapon:  { name: "Algari Mana Oil",                 note: "Crit + Haste" },
    },
    stat_priority: ["Agility", "Critical Strike", "Haste", "Mastery", "Versatility"],
  },

  // Devastation Evoker — DPS S-tier (Icy Veins 12.0.1)
  'evoker:devastation': {
    enchants: {
      back:     [{ name: "Chant of Burrowing Rapidity", note: "BiS movement",      is_primary: true }],
      chest:    [{ name: "Stormrider's Intellect",      note: "BiS Intellect",     is_primary: true }],
      wrist:    [{ name: "Chant of Powerful Rituals",   note: "BiS caster",        is_primary: true }],
      legs:     [{ name: "Daybreak Spellthread",        note: "BiS caster",        is_primary: true }],
      feet:     [{ name: "Scout's March",               note: "Movement + stats",  is_primary: true }],
      finger1:  [{ name: "Radiant Haste",               note: "BiS",              is_primary: true },
                 { name: "Glimmering Critical Strike",  note: "Alternative",      is_primary: false }],
      finger2:  [{ name: "Radiant Haste",               note: "BiS",              is_primary: true },
                 { name: "Glimmering Critical Strike",  note: "Alternative",      is_primary: false }],
      mainHand: [{ name: "Authority of Fiery Resolve",  note: "BiS caster",       is_primary: true }],
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

  // ─────────────────────────────────────────────────────────────────────────
  // TANKS
  // ─────────────────────────────────────────────────────────────────────────

  // Protection Paladin — Tank S-tier (Icy Veins 12.0.1)
  'paladin:protection': {
    enchants: {
      back:     [{ name: "Chant of Burrowing Rapidity", note: "BiS survivability",  is_primary: true }],
      chest:    [{ name: "Stormrider's Strength",       note: "BiS Strength",       is_primary: true }],
      wrist:    [{ name: "Chant of Armored Speed",      note: "BiS physical",       is_primary: true }],
      legs:     [{ name: "Stormbound Armor Kit",        note: "BiS physical",       is_primary: true }],
      feet:     [{ name: "Scout's March",               note: "Movement + stats",   is_primary: true }],
      finger1:  [{ name: "Radiant Haste",               note: "BiS (Templar)",     is_primary: true },
                 { name: "Glimmering Critical Strike",  note: "Lightsmith alt",    is_primary: false }],
      finger2:  [{ name: "Radiant Haste",               note: "BiS (Templar)",     is_primary: true },
                 { name: "Glimmering Critical Strike",  note: "Lightsmith alt",    is_primary: false }],
      mainHand: [{ name: "Authority of the Depths",     note: "BiS tank",          is_primary: true },
                 { name: "Authority of Radiant Power",  note: "Offensive alt",     is_primary: false }],
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
    // Templar: Haste > Mastery > Vers/Crit | Lightsmith: Haste > Crit > Vers/Mastery
    stat_priority: ["Strength", "Haste", "Mastery", "Versatility", "Critical Strike"],
  },

  // Protection Warrior — Tank S-tier (Icy Veins 12.0.1)
  'warrior:protection': {
    enchants: {
      back:     [{ name: "Chant of Burrowing Rapidity", note: "BiS survivability",  is_primary: true }],
      chest:    [{ name: "Stormrider's Strength",       note: "BiS Strength",       is_primary: true }],
      wrist:    [{ name: "Chant of Armored Speed",      note: "BiS physical",       is_primary: true }],
      legs:     [{ name: "Stormbound Armor Kit",        note: "BiS physical",       is_primary: true }],
      feet:     [{ name: "Scout's March",               note: "Movement + stats",   is_primary: true }],
      finger1:  [{ name: "Radiant Haste",               note: "BiS",              is_primary: true },
                 { name: "Glimmering Critical Strike",  note: "Alternative",      is_primary: false }],
      finger2:  [{ name: "Radiant Haste",               note: "BiS",              is_primary: true },
                 { name: "Glimmering Critical Strike",  note: "Alternative",      is_primary: false }],
      mainHand: [{ name: "Authority of the Depths",     note: "BiS tank",          is_primary: true },
                 { name: "Authority of Radiant Power",  note: "Offensive alt",     is_primary: false }],
      offHand:  [{ name: "Authority of the Depths",     note: "Shield",            is_primary: true }],
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

  // Blood Death Knight — Tank A-tier (Icy Veins 12.0.1)
  'death knight:blood': {
    enchants: {
      back:     [{ name: "Chant of Burrowing Rapidity", note: "BiS survivability",  is_primary: true }],
      chest:    [{ name: "Stormrider's Strength",       note: "BiS Strength",       is_primary: true }],
      wrist:    [{ name: "Chant of Armored Speed",      note: "BiS physical",       is_primary: true }],
      legs:     [{ name: "Stormbound Armor Kit",        note: "BiS physical",       is_primary: true }],
      feet:     [{ name: "Scout's March",               note: "Movement + stats",   is_primary: true }],
      finger1:  [{ name: "Glimmering Critical Strike",  note: "Deathbringer BiS",  is_primary: true },
                 { name: "Radiant Haste",               note: "San'layn alt",      is_primary: false }],
      finger2:  [{ name: "Glimmering Critical Strike",  note: "Deathbringer BiS",  is_primary: true },
                 { name: "Radiant Haste",               note: "San'layn alt",      is_primary: false }],
      mainHand: [{ name: "Authority of the Depths",     note: "BiS tank",          is_primary: true },
                 { name: "Authority of Radiant Power",  note: "Offensive alt",     is_primary: false }],
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
    // Deathbringer: Crit/Vers/Mastery > Haste | San'layn: Haste > Crit/Vers/Mastery
    stat_priority: ["Strength", "Critical Strike", "Versatility", "Mastery", "Haste"],
  },

  // Guardian Druid — Tank A-tier (Icy Veins 12.0.1)
  'druid:guardian': {
    enchants: {
      back:     [{ name: "Chant of Burrowing Rapidity", note: "BiS survivability",  is_primary: true }],
      chest:    [{ name: "Stormrider's Agility",        note: "BiS Agility",        is_primary: true }],
      wrist:    [{ name: "Chant of Armored Speed",      note: "BiS physical",       is_primary: true }],
      legs:     [{ name: "Stormbound Armor Kit",        note: "BiS physical",       is_primary: true }],
      feet:     [{ name: "Scout's March",               note: "Movement + stats",   is_primary: true }],
      finger1:  [{ name: "Radiant Haste",               note: "BiS survival",      is_primary: true },
                 { name: "Glimmering Critical Strike",  note: "Damage alt",        is_primary: false }],
      finger2:  [{ name: "Radiant Haste",               note: "BiS survival",      is_primary: true },
                 { name: "Glimmering Critical Strike",  note: "Damage alt",        is_primary: false }],
      mainHand: [{ name: "Authority of the Depths",     note: "BiS tank",          is_primary: true },
                 { name: "Authority of Radiant Power",  note: "Damage alt",        is_primary: false }],
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
    // Survival: Armor/Agi/Stam > Haste > Vers > Mastery > Crit
    // Damage: Haste > Vers = Crit = Mastery
    stat_priority: ["Agility", "Haste", "Versatility", "Mastery", "Critical Strike"],
  },

  // Brewmaster Monk — Tank A-tier (Icy Veins 12.0.1)
  'monk:brewmaster': {
    enchants: {
      back:     [{ name: "Chant of Burrowing Rapidity", note: "BiS survivability",  is_primary: true }],
      chest:    [{ name: "Stormrider's Agility",        note: "BiS Agility",        is_primary: true }],
      wrist:    [{ name: "Chant of Armored Speed",      note: "BiS physical",       is_primary: true }],
      legs:     [{ name: "Stormbound Armor Kit",        note: "BiS physical",       is_primary: true }],
      feet:     [{ name: "Scout's March",               note: "Movement + stats",   is_primary: true }],
      finger1:  [{ name: "Glimmering Critical Strike",  note: "BiS offensive",     is_primary: true },
                 { name: "Radiant Versatility",         note: "Defensive alt",     is_primary: false }],
      finger2:  [{ name: "Glimmering Critical Strike",  note: "BiS offensive",     is_primary: true },
                 { name: "Radiant Versatility",         note: "Defensive alt",     is_primary: false }],
      mainHand: [{ name: "Authority of the Depths",     note: "BiS tank",          is_primary: true },
                 { name: "Authority of Radiant Power",  note: "Offensive alt",     is_primary: false }],
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
    // Defense: Vers = Crit = Mastery > Haste | Offense: Crit > Vers > Mastery > Haste
    stat_priority: ["Agility", "Critical Strike", "Versatility", "Mastery", "Haste"],
  },

  // Vengeance Demon Hunter — Tank A-tier (Icy Veins 12.0.1)
  'demon hunter:vengeance': {
    enchants: {
      back:     [{ name: "Chant of Burrowing Rapidity", note: "BiS survivability",  is_primary: true }],
      chest:    [{ name: "Stormrider's Agility",        note: "BiS Agility",        is_primary: true }],
      wrist:    [{ name: "Chant of Armored Speed",      note: "BiS physical",       is_primary: true }],
      legs:     [{ name: "Stormbound Armor Kit",        note: "BiS physical",       is_primary: true }],
      feet:     [{ name: "Scout's March",               note: "Movement + stats",   is_primary: true }],
      finger1:  [{ name: "Radiant Haste",               note: "BiS",              is_primary: true },
                 { name: "Glimmering Critical Strike",  note: "Alternative",      is_primary: false }],
      finger2:  [{ name: "Radiant Haste",               note: "BiS",              is_primary: true },
                 { name: "Glimmering Critical Strike",  note: "Alternative",      is_primary: false }],
      mainHand: [{ name: "Authority of the Depths",     note: "BiS tank",          is_primary: true },
                 { name: "Oil of Deep Toxins",          note: "Offensive alt",     is_primary: false }],
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
    // Defensive: Agi > Haste > Vers/Crit > Mastery
    stat_priority: ["Agility", "Haste", "Versatility", "Critical Strike", "Mastery"],
  },

  // ─────────────────────────────────────────────────────────────────────────
  // HEALERS
  // ─────────────────────────────────────────────────────────────────────────

  // Mistweaver Monk — Healer S-tier (Icy Veins 12.0.1)
  'monk:mistweaver': {
    enchants: {
      back:     [{ name: "Chant of Burrowing Rapidity", note: "BiS movement",      is_primary: true }],
      chest:    [{ name: "Stormrider's Intellect",      note: "BiS Intellect",     is_primary: true }],
      wrist:    [{ name: "Chant of Powerful Rituals",   note: "BiS caster",        is_primary: true }],
      legs:     [{ name: "Daybreak Spellthread",        note: "BiS caster",        is_primary: true }],
      feet:     [{ name: "Scout's March",               note: "Movement + stats",  is_primary: true }],
      finger1:  [{ name: "Radiant Haste",               note: "BiS",              is_primary: true },
                 { name: "Glimmering Critical Strike",  note: "Alternative",      is_primary: false }],
      finger2:  [{ name: "Radiant Haste",               note: "BiS",              is_primary: true },
                 { name: "Glimmering Critical Strike",  note: "Alternative",      is_primary: false }],
      mainHand: [{ name: "Authority of Fiery Resolve",  note: "BiS caster",       is_primary: true }],
      offHand:  [],
    },
    gems: {
      meta:    { name: "Elusive Blasphemite", note: "Movement speed BiS" },
      generic: { name: "Deadly Emerald",      note: "Fill remaining sockets" },
    },
    consumables: {
      flask:   { name: "Flask of Tempered Swiftness",    note: "BiS for Mistweaver" },
      food:    { name: "Feast of the Midnight Masquerade", note: "Group feast" },
      potion:  { name: "Slumbering Soul Serum",          note: "Mana; or Algari Mana Potion" },
      weapon:  { name: "Algari Mana Oil",                note: "Crit + Haste" },
    },
    // Raid: Int > Haste > Crit > Vers > Mastery
    // M+: Int > Haste > Crit >= Vers > Mastery
    stat_priority: ["Intellect", "Haste", "Critical Strike", "Versatility", "Mastery"],
  },

  // Discipline Priest — Healer S-tier (Icy Veins 12.0.1)
  'priest:discipline': {
    enchants: {
      back:     [{ name: "Chant of Burrowing Rapidity", note: "BiS movement",      is_primary: true }],
      chest:    [{ name: "Stormrider's Intellect",      note: "BiS Intellect",     is_primary: true }],
      wrist:    [{ name: "Chant of Powerful Rituals",   note: "BiS caster",        is_primary: true }],
      legs:     [{ name: "Daybreak Spellthread",        note: "BiS caster",        is_primary: true }],
      feet:     [{ name: "Scout's March",               note: "Movement + stats",  is_primary: true }],
      finger1:  [{ name: "Radiant Haste",               note: "Until 20-25% Haste", is_primary: true },
                 { name: "Glimmering Critical Strike",  note: "Above haste cap",  is_primary: false }],
      finger2:  [{ name: "Radiant Haste",               note: "Until 20-25% Haste", is_primary: true },
                 { name: "Glimmering Critical Strike",  note: "Above haste cap",  is_primary: false }],
      mainHand: [{ name: "Authority of Fiery Resolve",  note: "BiS caster",       is_primary: true }],
      offHand:  [],
    },
    gems: {
      meta:    { name: "Elusive Blasphemite", note: "Movement speed BiS" },
      generic: { name: "Quick Sapphire",      note: "One of each color for Blasphemite" },
    },
    consumables: {
      flask:   { name: "Flask of Tempered Swiftness",    note: "BiS; or Aggression/Mastery" },
      food:    { name: "Hearty Salt Baked Seafood",      note: "Personal BiS food" },
      potion:  { name: "Slumbering Soul Serum",          note: "Mana; or Algari Mana Potion" },
      weapon:  { name: "Algari Mana Oil",                note: "Crit + Haste" },
    },
    // Haste until 20-25% > Crit = Mastery > Haste beyond > Vers
    // Voidweaver: Haste > Mastery > Crit > Vers
    stat_priority: ["Intellect", "Haste", "Critical Strike", "Mastery", "Versatility"],
  },

  // Restoration Druid — Healer S-tier (Icy Veins 12.0.1)
  'druid:restoration': {
    enchants: {
      back:     [{ name: "Chant of Burrowing Rapidity", note: "BiS movement",      is_primary: true }],
      chest:    [{ name: "Stormrider's Intellect",      note: "BiS Intellect",     is_primary: true }],
      wrist:    [{ name: "Chant of Powerful Rituals",   note: "BiS caster",        is_primary: true }],
      legs:     [{ name: "Daybreak Spellthread",        note: "BiS caster",        is_primary: true }],
      feet:     [{ name: "Scout's March",               note: "Movement + stats",  is_primary: true }],
      finger1:  [{ name: "Radiant Haste",               note: "Raid BiS",         is_primary: true },
                 { name: "Glimmering Mastery",          note: "M+ alt",           is_primary: false }],
      finger2:  [{ name: "Radiant Haste",               note: "Raid BiS",         is_primary: true },
                 { name: "Glimmering Mastery",          note: "M+ alt",           is_primary: false }],
      mainHand: [{ name: "Authority of Fiery Resolve",  note: "BiS caster",       is_primary: true }],
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
    // Raid: Int > Haste = Mastery > Vers > Crit
    // M+: Int > Mastery = Haste > Vers > Crit
    stat_priority: ["Intellect", "Haste", "Mastery", "Versatility", "Critical Strike"],
  },

  // Preservation Evoker — Healer A-tier (Icy Veins 12.0.1)
  'evoker:preservation': {
    enchants: {
      back:     [{ name: "Chant of Burrowing Rapidity", note: "BiS movement",      is_primary: true }],
      chest:    [{ name: "Stormrider's Intellect",      note: "BiS Intellect",     is_primary: true }],
      wrist:    [{ name: "Chant of Powerful Rituals",   note: "BiS caster",        is_primary: true }],
      legs:     [{ name: "Daybreak Spellthread",        note: "BiS caster",        is_primary: true }],
      feet:     [{ name: "Scout's March",               note: "Movement + stats",  is_primary: true }],
      finger1:  [{ name: "Glimmering Mastery",          note: "Raid BiS",         is_primary: true },
                 { name: "Glimmering Critical Strike",  note: "M+ alt",           is_primary: false }],
      finger2:  [{ name: "Glimmering Mastery",          note: "Raid BiS",         is_primary: true },
                 { name: "Glimmering Critical Strike",  note: "M+ alt",           is_primary: false }],
      mainHand: [{ name: "Authority of Fiery Resolve",  note: "BiS caster",       is_primary: true }],
      offHand:  [],
    },
    gems: {
      meta:    { name: "Elusive Blasphemite", note: "Movement speed BiS" },
      generic: { name: "Deadly Onyx",         note: "Raid: Masterful alts; M+: Quick alts" },
    },
    consumables: {
      flask:   { name: "Flask of Tempered Mastery",    note: "Healing BiS; Aggression for M+" },
      food:    { name: "Feast of the Midnight Masquerade", note: "Group feast" },
      potion:  { name: "Slumbering Soul Serum",        note: "Mana; Invigorating Healing alt" },
      weapon:  { name: "Crystallized Augment Rune",    note: "Or Ethereal Augment Rune" },
    },
    // Raid: Int > Mastery > Crit > Haste > Vers
    // M+: Int > Crit > Haste > Vers > Mastery
    stat_priority: ["Intellect", "Mastery", "Critical Strike", "Haste", "Versatility"],
  },

  // Restoration Shaman — Healer A-tier (Icy Veins 12.0.1)
  'shaman:restoration': {
    enchants: {
      back:     [{ name: "Chant of Burrowing Rapidity", note: "BiS movement",      is_primary: true }],
      chest:    [{ name: "Stormrider's Intellect",      note: "BiS Intellect",     is_primary: true }],
      wrist:    [{ name: "Chant of Powerful Rituals",   note: "BiS caster",        is_primary: true }],
      legs:     [{ name: "Daybreak Spellthread",        note: "BiS caster",        is_primary: true }],
      feet:     [{ name: "Scout's March",               note: "Movement + stats",  is_primary: true }],
      finger1:  [{ name: "Glimmering Critical Strike",  note: "Raid BiS",         is_primary: true },
                 { name: "Radiant Versatility",         note: "M+ alt",           is_primary: false }],
      finger2:  [{ name: "Glimmering Critical Strike",  note: "Raid BiS",         is_primary: true },
                 { name: "Radiant Versatility",         note: "M+ alt",           is_primary: false }],
      mainHand: [{ name: "Authority of Fiery Resolve",  note: "BiS caster",       is_primary: true }],
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
    // Raid: Crit preferred | M+: Vers preferred
    // Stats very close — Crit, Vers, Haste balance; Mastery less value for mana conservation
    stat_priority: ["Intellect", "Critical Strike", "Versatility", "Haste", "Mastery"],
  },

  // Holy Priest — Healer A-tier (Icy Veins 12.0.1)
  'priest:holy': {
    enchants: {
      back:     [{ name: "Chant of Burrowing Rapidity", note: "BiS movement",      is_primary: true }],
      chest:    [{ name: "Stormrider's Intellect",      note: "BiS Intellect",     is_primary: true }],
      wrist:    [{ name: "Chant of Powerful Rituals",   note: "BiS caster",        is_primary: true }],
      legs:     [{ name: "Daybreak Spellthread",        note: "BiS caster",        is_primary: true }],
      feet:     [{ name: "Scout's March",               note: "Movement + stats",  is_primary: true }],
      finger1:  [{ name: "Glimmering Critical Strike",  note: "BiS",              is_primary: true }],
      finger2:  [{ name: "Glimmering Critical Strike",  note: "BiS",              is_primary: true }],
      mainHand: [{ name: "Authority of Fiery Resolve",  note: "BiS caster",       is_primary: true }],
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
    // Raid: Crit > Vers = Mastery > Haste
    // M+: Crit > Vers = Haste > Mastery
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
    if (url.pathname === '/invalidate' && request.method === 'POST') {
      return handleInvalidate(request, env);
    }
    if (url.pathname === '/specs' && request.method === 'GET') {
      return handleSpecs(url, env);
    }
    if (url.pathname === '/debug-gemini' && request.method === 'GET') {
      return handleDebugGemini(env);
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

  const cacheKey = buildCacheKey(classParam, specParam, patch);

  // 1. Static data verificado — SIEMPRE tiene prioridad sobre caché y generación.
  //    Esto garantiza que cualquier actualización manual en STATIC_DATA se aplica
  //    de inmediato, sin importar lo que haya en la KV cache (evita datos de tests
  //    anteriores que queden cacheados durante días).
  const staticKey = `${classParam}:${specParam}`;
  const staticData = STATIC_DATA[staticKey];

  if (staticData && !force) {
    const result = {
      class_name: classParam,
      spec_name: specParam,
      patch,
      generated_at: new Date().toISOString(),
      ...staticData,
      _source: 'static',
    };
    // Actualizar KV con los datos estáticos frescos (sobrescribe cualquier dato viejo)
    const ttl = parseInt(env.CACHE_TTL_SECONDS || '604800', 10);
    await env.RECS_CACHE.put(cacheKey, JSON.stringify(result), { expirationTtl: ttl });
    return json({ ...result, _source: 'static' });
  }

  // 2. KV cache — solo para specs SIN datos estáticos (o cuando force=1 para test)
  if (!force) {
    const cached = await env.RECS_CACHE.get(cacheKey, 'json');
    if (cached) {
      return json({ ...cached, _source: 'cache' });
    }
  }

  // 3. Groq API — solo para specs SIN datos estáticos verificados
  if (env.GROQ_API_KEY) {
    try {
      const recommendations = await generateWithGroq(classParam, specParam, patch, env.GROQ_API_KEY);
      const ttl = parseInt(env.CACHE_TTL_SECONDS || '604800', 10);
      await env.RECS_CACHE.put(cacheKey, JSON.stringify(recommendations), { expirationTtl: ttl });
      return json({ ...recommendations, _source: 'generated' });
    } catch (err) {
      console.error('Groq generation failed:', err.message);
    }
  }

  return json({ error: `No data available for ${classParam}:${specParam}` }, 404);
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

  const cacheKey = buildCacheKey(classParam, specParam, patch);
  await env.RECS_CACHE.delete(cacheKey);
  return json({ invalidated: cacheKey, ok: true });
}

// ─── /specs ───────────────────────────────────────────────────────────────────

async function handleSpecs(url, env) {
  const patch = url.searchParams.get('patch') || env.CURRENT_PATCH || '12.0.1';

  const results = await Promise.all(
    SUPPORTED_SPECS.map(async ({ class: cls, spec }) => {
      const key = buildCacheKey(cls, spec, patch);
      const cached = await env.RECS_CACHE.get(key, 'json');
      return {
        class: cls,
        spec,
        cached: cached !== null,
        generated_at: cached?.generated_at ?? null,
        source: cached?._source ?? null,
      };
    })
  );

  return json({ patch, specs: results });
}

// ─── Debug ──────────────────────────────────────────────────────────────────────

async function handleDebugGemini(env) {
  if (!env.GROQ_API_KEY) {
    return json({ error: 'GROQ_API_KEY not set' }, 500);
  }

  try {
    const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${env.GROQ_API_KEY}`,
      },
      body: JSON.stringify({
        model: 'llama-3.3-70b-versatile',
        temperature: 0.1,
        max_tokens: 20,
        response_format: { type: 'json_object' },
        messages: [{ role: 'user', content: 'Reply with this exact JSON: {"ok": true}' }],
      }),
    });

    const statusCode = response.status;
    const rawText = await response.text();
    let parsed = null;
    try { parsed = JSON.parse(rawText); } catch (_) {}

    return json({
      key_prefix: env.GROQ_API_KEY.slice(0, 8) + '...',
      groq_status: statusCode,
      groq_ok: response.ok,
      groq_response: parsed?.choices?.[0]?.message?.content ?? null,
    });
  } catch (err) {
    return json({ fetch_error: err.message }, 500);
  }
}

// ─── Groq generation ─────────────────────────────────────────────────────────

async function generateWithGroq(className, specName, patch, apiKey) {
  const prompt = buildPrompt(className, specName, patch);

  const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: 'llama-3.3-70b-versatile',
      temperature: 0.2,
      max_tokens: 1500,
      response_format: { type: 'json_object' }, // Fuerza JSON puro sin markdown
      messages: [{ role: 'user', content: prompt }],
    }),
  });

  if (!response.ok) {
    const err = await response.text();
    throw new Error(`Groq API error ${response.status}: ${err}`);
  }

  const data = await response.json();
  const text = data.choices?.[0]?.message?.content ?? '';

  if (!text) {
    throw new Error('Groq returned empty response');
  }

  let parsed;
  try {
    parsed = JSON.parse(text);
  } catch (e) {
    throw new Error(`Failed to parse Groq JSON: ${e.message}. Raw: ${text.slice(0, 200)}`);
  }

  return {
    class_name: className,
    spec_name: specName,
    patch,
    generated_at: new Date().toISOString(),
    ...parsed,
  };
}

function buildPrompt(className, specName, patch) {
  return `You are a World of Warcraft expert specializing in PvE optimization for The War Within expansion (patch ${patch}, Season 3).

Generate BiS enchants, gems, consumables and stat priority for a ${specName} ${className} in The War Within patch ${patch}.

CRITICAL: All item names MUST be from The War Within expansion (patch 11.x / 12.0.x pre-patch Midnight). Do NOT use items from Shadowlands, Dragonflight, or any previous expansion. The War Within items remain valid in patch 12.0.1 pre-patch.

The War Within enchants include (use these, not old ones):
- Back: Chant of Burrowing Rapidity, Chant of Winged Grace
- Chest: Stormrider's Agility / Strength / Intellect
- Wrist: Chant of Armored Speed, Chant of Powerful Rituals
- Legs: Stormbound Armor Kit (physical), Daybreak Spellthread (caster)
- Feet: Scout's March, Cavalry's March
- Rings: Glimmering Critical Strike, Glimmering Mastery, Radiant Haste, Radiant Versatility
- Weapon: Authority of Radiant Power, Authority of Fiery Resolve, Authority of the Depths

The War Within gems include:
- Meta: Culminating Blasphemite
- Regular: Radiant Mastery, Radiant Critical Strike, Energized Ysemerald, Crafty Alexstraszite

The War Within consumables include:
- Flasks: Flask of Alchemical Chaos, Flask of Tempered Aggression, Flask of Tempered Mastery
- Food: Feast of the Midnight Masquerade, or stat-specific foods
- Potions: Tempered Potion, Potion of Unwavering Focus
- Weapon: Algari Mana Oil, Burst of Knowledge

Return ONLY a valid JSON object, no markdown, no explanation:

{
  "enchants": {
    "back":     [{"name": "string", "note": "string", "is_primary": true}],
    "chest":    [{"name": "string", "note": "string", "is_primary": true}],
    "wrist":    [{"name": "string", "note": "string", "is_primary": true}],
    "legs":     [{"name": "string", "note": "string", "is_primary": true}],
    "feet":     [{"name": "string", "note": "string", "is_primary": true}],
    "finger1":  [{"name": "string", "note": "string", "is_primary": true}],
    "finger2":  [{"name": "string", "note": "string", "is_primary": true}],
    "mainHand": [{"name": "string", "note": "string", "is_primary": true}],
    "offHand":  []
  },
  "gems": {
    "meta":    {"name": "string", "note": "string"},
    "generic": {"name": "string", "note": "string"}
  },
  "consumables": {
    "flask":  {"name": "string", "note": "string"},
    "food":   {"name": "string", "note": "string"},
    "potion": {"name": "string", "note": "string"},
    "weapon": {"name": "string", "note": "string"}
  },
  "stat_priority": ["stat1", "stat2", "stat3", "stat4", "stat5"]
}

Rules:
- 1-3 options per enchant slot, best first with is_primary: true, rest with is_primary: false
- offHand: empty [] unless spec actively dual-wields (e.g. Fury Warrior)
- stat_priority names: Agility, Strength, Intellect, Critical Strike, Mastery, Haste, Versatility
- note: short English description max 6 words, or null
- Prioritize raid + M+ viability for patch ${patch}`;
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function buildCacheKey(cls, spec, patch) {
  return `recs:${cls}:${spec.replace(' ', '_')}:${patch}`;
}

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
  });
}
