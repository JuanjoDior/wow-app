/**
 * wow-recommendations Worker  v5
 *
 * Endpoints:
 *   GET  /health
 *   GET  /character?region=eu&realm=sanguino&name=apastar[&force=1]
 *   GET  /v1/character/snapshot?region=eu&realm=sanguino&name=apastar[&force=1]
 *   GET  /v1/build/gap-analysis      (v1, compatibility alias)
 *   GET  /v2/build/verification      (objective verification)
 *   GET  /v1/planner/weekly          (reservado)
 *   GET  /recommendations            (deprecated)
 *   GET  /specs                      (deprecated)
 *   POST /invalidate                 (deprecated)
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
  'Access-Control-Expose-Headers': 'X-Request-Id',
};

const CACHE_TTLS = Object.freeze({
  character: { envKey: 'BLIZZARD_CHAR_CACHE_TTL', fallback: 300 },
  characterNoMedia: { envKey: null, fallback: 60 },
  oauthToken: { envKey: 'BLIZZARD_TOKEN_CACHE_TTL', fallback: 23 * 60 * 60 },
  realmSlug: { envKey: 'BLIZZARD_REALM_CACHE_TTL', fallback: 2592000 },
  itemIcon: { envKey: 'BLIZZARD_ITEM_ICON_CACHE_TTL', fallback: 604800 },
});

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

// ─── Legacy recommendation catalog (disabled in v2 objective mode) ──────────
export const SUPPORTED_SPECS = [];

// ─── Router ───────────────────────────────────────────────────────────────────

export default {
  async fetch(request, env) {
    const startedAt = Date.now();
    const requestId = buildRequestId(request);
    const url = new URL(request.url);
    let response;
    let status = 500;
    let source = null;
    let cacheHit = null;

    try {
      if (request.method === 'OPTIONS') {
        response = new Response(null, { headers: CORS_HEADERS });
      } else if (url.pathname === '/health') {
        response = json({
          status: 'ok',
          patch: env.CURRENT_PATCH,
          specs: SUPPORTED_SPECS.length,
          service_version: env.SERVICE_VERSION || 'v5',
          capabilities: {
            build_verification_v2: true,
          },
        });
      } else if (url.pathname === '/v2/build/verification' && request.method === 'GET') {
        response = await handleBuildVerificationV2(url, env);
      } else if (url.pathname === '/recommendations' && request.method === 'GET') {
        response = await handleRecommendations(url, env);
      } else if (url.pathname === '/character' && request.method === 'GET') {
        response = await handleCharacter(url, env);
      } else if (url.pathname === '/v1/character/snapshot' && request.method === 'GET') {
        response = await handleCharacterSnapshotV1(url, env);
      } else if (url.pathname === '/v1/build/gap-analysis' && request.method === 'GET') {
        response = await handleBuildGapAnalysisV1(url, env);
      } else if (url.pathname === '/v1/planner/weekly' && request.method === 'GET') {
        response = notImplementedV1('/v1/planner/weekly');
      } else if (url.pathname === '/invalidate' && request.method === 'POST') {
        response = await handleInvalidate(request, env);
      } else if (url.pathname === '/specs' && request.method === 'GET') {
        response = await handleSpecs(url, env);
      } else {
        response = new Response('Not Found', { status: 404, headers: CORS_HEADERS });
      }

      status = response.status;
      ({ source, cacheHit } = await inferResponseSource(response));
    } catch (error) {
      source = 'error';
      cacheHit = false;
      response = json({ error: 'Internal server error', request_id: requestId }, 500);
      status = 500;
      logWorkerError({ requestId, endpoint: url.pathname, method: request.method, error });
    }

    response.headers.set('X-Request-Id', requestId);
    logRequestTelemetry({
      requestId,
      endpoint: url.pathname,
      method: request.method,
      status,
      latencyMs: Date.now() - startedAt,
      source,
      cacheHit,
    });
    return response;
  },
};

// ─── /recommendations ─────────────────────────────────────────────────────────

async function handleRecommendations(url, env) {
  return json({
    error: 'Deprecated endpoint. Use /v2/build/verification for objective analysis.',
  }, 410);
}

// ─── /character ───────────────────────────────────────────────────────────────
//
// Obtiene el perfil completo de un personaje desde la Blizzard Battle.net API.
// Datos devueltos: perfil, equipo (con enchants+gemas exactos), estadísticas,
// y URL de render del personaje.
//
// Nota sobre locale: se usa en_US para normalizar nombres e IDs de enchants/gemas
// y permitir comparación estable entre respuestas Blizzard y build local.

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

  const legacyCacheKey = buildCharacterLegacyKey(region, realmLegacyKeyPart, name);
  const cacheTtl = getCacheTtlSeconds(env, 'character');

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
    const canonicalCacheKey = buildCharacterCanonicalKey(region, realmSlug, name);

    if (!force) {
      const cachedCanonical = await env.RECS_CACHE.get(canonicalCacheKey, 'json');
      if (cachedCanonical) {
        return json({ ...cachedCanonical, _source: 'cache' });
      }
    }

    const data = await fetchBlizzardCharacter(region, realmSlug, name, token, env);
    const result = { ...data, _source: 'blizzard' };
    const hasMedia = Boolean(result.avatar_url || result.thumbnail_url);
    const effectiveCacheTtl = hasMedia
      ? cacheTtl
      : getCacheTtlSeconds(env, 'characterNoMedia');

    // Cachear resultado con clave canónica.
    await env.RECS_CACHE.put(canonicalCacheKey, JSON.stringify(result), { expirationTtl: effectiveCacheTtl });

    return json(result);
  } catch (err) {
    const status = err.status || 502;
    return json({ error: err.message || 'Blizzard API error' }, status);
  }
}

// ─── /v1/character/snapshot ──────────────────────────────────────────────────
//
// Contrato estable v1 para consumo de la app.
// Conserva el payload de /character dentro de "snapshot" para no romper clientes
// actuales y añadir versionado explícito.

async function handleCharacterSnapshotV1(url, env) {
  const response = await handleCharacter(url, env);
  const contentType = response.headers.get('Content-Type') || '';
  if (!contentType.includes('application/json')) return response;

  let payload;
  try {
    payload = await response.clone().json();
  } catch {
    return response;
  }

  if (!response.ok) {
    return json({
      version: 'v1',
      endpoint: '/v1/character/snapshot',
      error: payload?.error || 'Unknown error',
    }, response.status);
  }

  const source = payload?._source ?? null;
  return json({
    version: 'v1',
    source,
    generated_at: new Date().toISOString(),
    snapshot: payload,
  });
}

// ─── /v1/build/gap-analysis (compat) + /v2/build/verification ───────────────
//
// Política actual:
// - No usa recomendaciones estáticas/manuales.
// - Compara únicamente datos oficiales Blizzard del personaje contra target local.
// - Si no hay target local, devuelve facts objetivos del personaje.

async function handleBuildGapAnalysisV1(url, env) {
  return handleBuildVerificationV2(url, env, {
    version: 'v1',
    endpoint: '/v1/build/gap-analysis',
  });
}

async function handleBuildVerificationV2(url, env, compat = null) {
  const region = (url.searchParams.get('region') || '').toLowerCase().trim();
  const realm = (url.searchParams.get('realm') || '').trim();
  const name = (url.searchParams.get('name') || '').trim();

  const version = compat?.version || 'v2';
  const endpoint = compat?.endpoint || '/v2/build/verification';

  if (!region || !realm || !name) {
    return json({
      version,
      endpoint,
      error: 'Missing required params: region, realm, name',
    }, 400);
  }

  const characterResponse = await handleCharacter(url, env);
  const contentType = characterResponse.headers.get('Content-Type') || '';
  if (!contentType.includes('application/json')) return characterResponse;

  let characterPayload;
  try {
    characterPayload = await characterResponse.clone().json();
  } catch {
    return json({
      version,
      endpoint,
      error: 'Invalid character payload',
    }, 502);
  }

  if (!characterResponse.ok) {
    return json({
      version,
      endpoint,
      error: characterPayload?.error || 'Character lookup failed',
    }, characterResponse.status);
  }

  const localBuildSlots = parseBuildSlotsQuery(url.searchParams.get('build_slots'));
  const analysis = computeObjectiveBuildVerification(characterPayload, localBuildSlots);

  return json({
    version,
    endpoint,
    generated_at: new Date().toISOString(),
    source: {
      character: characterPayload?._source ?? null,
      policy: 'official_only',
    },
    context: {
      region,
      realm,
      name: name.toLowerCase(),
      class_name: normalizeSpecToken(characterPayload?.class || ''),
      spec_name: normalizeSpecToken(characterPayload?.spec || ''),
      local_build_slots: localBuildSlots.length,
    },
    facts: analysis.facts,
    summary: analysis.summary,
    actions: analysis.actions,
  });
}

// ─── Blizzard: token OAuth2 (client_credentials) ─────────────────────────────
//
// El token dura 24h. Lo cacheamos en KV 23h para renovar con margen.
// La clave de KV es `btoken:{region}` (tokens son region-independientes para
// client_credentials, pero usamos clave por región por si cambia en el futuro).

async function getBlizzardToken(region, env) {
  const tokenKey = buildTokenKey(region);

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
  const ttl23h = getCacheTtlSeconds(env, 'oauthToken');
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

  const cacheKey = buildRealmSlugKey(region, normalizedRealm);
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
      const ttl = getCacheTtlSeconds(env, 'realmSlug');
      await env.RECS_CACHE.put(cacheKey, resolved, { expirationTtl: ttl });
    } catch (_) {
      // Ignore cache failures.
    }
    return resolved;
  }

  const fromSearch = await searchRealmByName(region, realmInput, token);
  if (fromSearch) {
    try {
      const ttl = getCacheTtlSeconds(env, 'realmSlug');
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
  // en_US para tener nomenclatura estable en el payload normalizado
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
      const enchantments = [];
      const enchantmentIds = [];
      for (const enchant of item.enchantments || []) {
        if (enchant?.enchantment_slot?.type !== 'PERMANENT') continue;

        const enchantId = enchant?.source_item?.id;
        if (Number.isInteger(enchantId)) {
          enchantmentIds.push(enchantId);
        }

        const sourceName = enchant?.source_item?.name || '';
        const parsedName = sourceName.includes(' - ')
          ? sourceName.split(' - ').slice(1).join(' - ').trim()
          : (enchant?.display_string || '').replace(/^Enchanted:\s*/i, '').trim();
        if (parsedName.length > 0) {
          enchantments.push(parsedName);
        }
      }

      const sockets = Array.isArray(item.sockets) ? item.sockets : [];
      const gems = [];
      const gemIds = [];
      for (const socket of sockets) {
        const gemName = socket?.item?.name || '';
        if (typeof gemName === 'string' && gemName.trim().length > 0) {
          gems.push(gemName.trim());
        }
        const gemId = socket?.item?.id;
        if (Number.isInteger(gemId)) {
          gemIds.push(gemId);
        }
      }
      const socketsTotal = sockets.length;
      const socketsFilled = gemIds.length;

      const itemId = item.item?.id ?? null;

      equipment.push({
        slot:         item.slot?.type  || 'UNKNOWN',
        name:         item.name        || 'Unknown',
        item_level:   item.level?.value ?? 0,
        quality:      item.quality?.type || 'COMMON',
        item_id:      itemId,
        icon_url:     itemId != null ? (iconUrlsByItemId[itemId] ?? null) : null,
        enchantments: enchantments,
        enchantment_ids: enchantmentIds,
        gems:         gems,
        gem_ids:      gemIds,
        sockets_total: socketsTotal,
        sockets_filled: socketsFilled,
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

  const ttl = getCacheTtlSeconds(env, 'itemIcon');
  const base = BLIZZARD_API_BASE[region];
  const namespace = `static-${region}`;
  const locale = 'en_US';
  const headers = { 'Authorization': `Bearer ${token}` };

  await Promise.all(itemIds.map(async (itemId) => {
    const cacheKey = buildItemIconKey(region, itemId);

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

function normalizeSpecToken(value) {
  return String(value || '')
    .toLowerCase()
    .trim()
    .replace(/\s+/g, ' ');
}

function normalizeTextToken(value) {
  return String(value || '')
    .toLowerCase()
    .trim()
    .replace(/\s+/g, ' ');
}

function normalizeBuildSlot(value) {
  const raw = String(value || '').trim();
  if (!raw) return null;

  const collapsed = raw
    .replace(/[\s-]+/g, '_')
    .replace(/([a-z])([A-Z])/g, '$1_$2')
    .toLowerCase();

  switch (collapsed) {
    case 'head':
    case 'neck':
    case 'shoulder':
    case 'back':
    case 'chest':
    case 'wrist':
    case 'hands':
    case 'waist':
    case 'legs':
    case 'feet':
    case 'main_hand':
    case 'mainhand':
    case 'off_hand':
    case 'offhand':
    case 'finger_1':
    case 'finger1':
    case 'finger_2':
    case 'finger2':
    case 'trinket_1':
    case 'trinket1':
    case 'trinket_2':
    case 'trinket2':
      break;
    default:
      return null;
  }

  switch (collapsed) {
    case 'main_hand':
    case 'mainhand':
      return 'mainHand';
    case 'off_hand':
    case 'offhand':
      return 'offHand';
    case 'finger_1':
    case 'finger1':
      return 'finger1';
    case 'finger_2':
    case 'finger2':
      return 'finger2';
    case 'trinket_1':
    case 'trinket1':
      return 'trinket1';
    case 'trinket_2':
    case 'trinket2':
      return 'trinket2';
    default:
      return collapsed;
  }
}

function parseBuildSlotsQuery(rawValue) {
  if (!rawValue) return [];

  let parsed;
  try {
    parsed = JSON.parse(rawValue);
  } catch {
    return [];
  }

  if (!Array.isArray(parsed)) return [];

  const normalized = [];
  for (const entry of parsed) {
    if (!entry || typeof entry !== 'object') continue;
    const slot = normalizeBuildSlot(entry.slot);
    if (!slot) continue;

    const enchantRaw = entry.enchantment;
    const enchantment = typeof enchantRaw === 'string'
      ? enchantRaw.trim()
      : (typeof enchantRaw?.name === 'string' ? enchantRaw.name.trim() : '');
    const enchantmentId = Number.isInteger(entry.enchantment_id)
      ? entry.enchantment_id
      : (Number.isInteger(entry.enchantmentId) ? entry.enchantmentId : null);

    const gemsRaw = Array.isArray(entry.gems) ? entry.gems : [];
    const gems = gemsRaw
      .map((gem) => {
        if (typeof gem === 'string') return gem.trim();
        if (typeof gem?.name === 'string') return gem.name.trim();
        return '';
      })
      .filter(Boolean);

    const gemIdsRaw = Array.isArray(entry.gem_ids)
      ? entry.gem_ids
      : (Array.isArray(entry.gemIds) ? entry.gemIds : []);
    const gemIds = gemIdsRaw
      .filter((id) => Number.isInteger(id))
      .map((id) => Number(id));

    if (enchantmentId == null && !enchantment && gemIds.length === 0 && gems.length === 0) {
      continue;
    }

    normalized.push({
      slot,
      enchantment_id: enchantmentId,
      enchantment: enchantment || null,
      gem_ids: gemIds,
      gems,
    });
  }

  return normalized;
}

function hasTargetEnchantment(slot) {
  return Number.isInteger(slot?.enchantment_id) ||
    normalizeTextToken(slot?.enchantment).length > 0;
}

function hasTargetGems(slot) {
  const gemIds = Array.isArray(slot?.gem_ids) ? slot.gem_ids : [];
  const gems = Array.isArray(slot?.gems) ? slot.gems : [];
  return gemIds.length > 0 || gems.some((gem) => normalizeTextToken(gem).length > 0);
}

function toTargetGemList(slot) {
  const gemIds = Array.isArray(slot?.gem_ids) ? slot.gem_ids : [];
  const gemNames = Array.isArray(slot?.gems) ? slot.gems : [];
  const maxLen = Math.max(gemIds.length, gemNames.length);
  const targets = [];

  for (let i = 0; i < maxLen; i += 1) {
    const id = Number.isInteger(gemIds[i]) ? gemIds[i] : null;
    const nameRaw = typeof gemNames[i] === 'string' ? gemNames[i].trim() : '';
    if (id == null && !nameRaw) continue;
    targets.push({ id, name: nameRaw || null });
  }

  return targets;
}

function getCharacterEnchantIdsForSlot(slotKey, equipBySlot) {
  const items = getEquipItemsForTargetSlot(slotKey, equipBySlot);
  if (!Array.isArray(items) || items.length === 0) return [];

  const result = [];
  for (const item of items) {
    const ids = Array.isArray(item?.enchantment_ids) ? item.enchantment_ids : [];
    for (const id of ids) {
      if (Number.isInteger(id)) result.push(id);
    }
  }
  return result;
}

function getCharacterGemIdsForSlot(slotKey, equipBySlot) {
  const items = getEquipItemsForTargetSlot(slotKey, equipBySlot);
  if (!Array.isArray(items) || items.length === 0) return [];

  const result = [];
  for (const item of items) {
    const ids = Array.isArray(item?.gem_ids) ? item.gem_ids : [];
    for (const id of ids) {
      if (Number.isInteger(id)) result.push(id);
    }
  }
  return result;
}

function hasMatchByIdOrName(currentIds, currentNames, targetId, targetName) {
  if (Number.isInteger(targetId) && currentIds.includes(targetId)) {
    return true;
  }

  const normalizedTargetName = normalizeTextToken(targetName);
  if (!normalizedTargetName) return false;
  return currentNames.map((name) => normalizeTextToken(name)).includes(normalizedTargetName);
}

function computeCharacterFacts(equipment = []) {
  const equippedItemsCount = Array.isArray(equipment) ? equipment.length : 0;
  let enchantedItemsCount = 0;
  let socketsTotalCount = 0;
  let socketsFilledCount = 0;

  for (const item of equipment) {
    const enchantments = Array.isArray(item?.enchantments) ? item.enchantments : [];
    if (enchantments.length > 0) {
      enchantedItemsCount += 1;
    }

    const socketsTotal = Number.isInteger(item?.sockets_total) ? item.sockets_total : 0;
    const socketsFilled = Number.isInteger(item?.sockets_filled) ? item.sockets_filled : 0;
    socketsTotalCount += socketsTotal;
    socketsFilledCount += Math.min(socketsFilled, socketsTotal);
  }

  return {
    equipped_items_count: equippedItemsCount,
    enchanted_items_count: enchantedItemsCount,
    sockets_total_count: socketsTotalCount,
    sockets_filled_count: socketsFilledCount,
    sockets_empty_count: Math.max(0, socketsTotalCount - socketsFilledCount),
  };
}

function computeObjectiveBuildVerification(characterPayload, localBuildSlots = []) {
  const equipment = Array.isArray(characterPayload?.equipment)
    ? characterPayload.equipment
    : [];
  const equipBySlot = buildEquipmentLookup(equipment);
  const facts = computeCharacterFacts(equipment);

  const buildTargets = localBuildSlots.filter(
    (slot) => hasTargetEnchantment(slot) || hasTargetGems(slot),
  );
  const hasBuildTarget = buildTargets.length > 0;

  let checksTotal = 0;
  let checksCompleted = 0;
  let missingEnchants = 0;
  let missingGems = 0;
  let mismatchedEnchants = 0;
  let mismatchedGems = 0;
  const actions = [];

  for (const slotTarget of buildTargets) {
    const slotKey = slotTarget.slot;
    const currentEnchantments = getCharacterEnchantmentsForSlot(slotKey, equipBySlot);
    const currentEnchantmentIds = getCharacterEnchantIdsForSlot(slotKey, equipBySlot);
    const currentGems = getCharacterGemsForSlot(slotKey, equipBySlot);
    const currentGemIds = getCharacterGemIdsForSlot(slotKey, equipBySlot);

    if (hasTargetEnchantment(slotTarget)) {
      checksTotal += 1;
      const targetEnchantName = slotTarget.enchantment || null;
      const targetEnchantId = Number.isInteger(slotTarget.enchantment_id)
        ? slotTarget.enchantment_id
        : null;
      const enchantMatched = hasMatchByIdOrName(
        currentEnchantmentIds,
        currentEnchantments,
        targetEnchantId,
        targetEnchantName,
      );
      if (enchantMatched) {
        checksCompleted += 1;
      } else {
        const hasCurrent = currentEnchantments.length > 0 || currentEnchantmentIds.length > 0;
        if (hasCurrent) {
          mismatchedEnchants += 1;
        } else {
          missingEnchants += 1;
        }
        const recommendedText = targetEnchantName || (targetEnchantId != null ? `Enchant #${targetEnchantId}` : 'Unknown enchant');
        actions.push({
          priority_score: getEnchantPriorityScore(slotKey),
          slot: slotKey,
          type: hasCurrent ? 'enchant_mismatch_target' : 'enchant_missing_target',
          label: `${hasCurrent ? 'Replace with' : 'Apply'} ${recommendedText}`,
          recommended: recommendedText,
          expected: recommendedText,
          expected_id: targetEnchantId,
          current: currentEnchantments,
          source: 'build',
        });
      }
    }

    const targetGems = toTargetGemList(slotTarget);
    for (const targetGem of targetGems) {
      checksTotal += 1;
      const gemMatched = hasMatchByIdOrName(
        currentGemIds,
        currentGems,
        targetGem.id,
        targetGem.name,
      );
      if (gemMatched) {
        checksCompleted += 1;
        continue;
      }

      const hasCurrentGem = currentGemIds.length > 0 || currentGems.length > 0;
      if (hasCurrentGem) {
        mismatchedGems += 1;
      } else {
        missingGems += 1;
      }

      const recommendedText = targetGem.name || (targetGem.id != null ? `Gem #${targetGem.id}` : 'Unknown gem');
      actions.push({
        priority_score: 65,
        slot: slotKey,
        type: hasCurrentGem ? 'gem_mismatch_target' : 'gem_missing_target',
        label: `${hasCurrentGem ? 'Replace with' : 'Socket'} ${recommendedText}`,
        recommended: recommendedText,
        expected: recommendedText,
        expected_id: targetGem.id,
        current: currentGems,
        source: 'build',
      });
    }
  }

  const completionPct = checksTotal > 0
    ? Math.round((checksCompleted / checksTotal) * 100)
    : 0;

  actions.sort((a, b) => b.priority_score - a.priority_score);

  return {
    facts,
    summary: {
      analysis_mode: 'objective',
      target_profile: hasBuildTarget ? 'build_target' : 'character_only',
      checks_total: checksTotal,
      checks_completed: checksCompleted,
      completion_pct: completionPct,
      missing_enchants: missingEnchants,
      missing_gems: missingGems,
      mismatched_enchants: mismatchedEnchants,
      mismatched_gems: mismatchedGems,
      actions_count: actions.length,
    },
    actions,
  };
}

function normalizeEquipSlot(slot) {
  const raw = String(slot || '').toUpperCase().replace(/[\s-]+/g, '_');
  switch (raw) {
    case 'HEAD':
      return 'head';
    case 'NECK':
      return 'neck';
    case 'SHOULDER':
      return 'shoulder';
    case 'CLOAK':
    case 'BACK':
      return 'back';
    case 'CHEST':
      return 'chest';
    case 'WRIST':
    case 'BRACER':
      return 'wrist';
    case 'HAND':
    case 'HANDS':
      return 'hands';
    case 'WAIST':
      return 'waist';
    case 'LEGS':
      return 'legs';
    case 'FEET':
      return 'feet';
    case 'FINGER':
    case 'FINGER_1':
    case 'FINGER_2':
      return 'finger';
    case 'MAIN_HAND':
    case 'MAINHAND':
      return 'mainHand';
    case 'OFF_HAND':
    case 'OFFHAND':
      return 'offHand';
    case 'TRINKET':
    case 'TRINKET_1':
    case 'TRINKET_2':
      return 'trinket';
    default:
      return null;
  }
}

function buildEquipmentLookup(equipment = []) {
  const bySlot = {};

  if (!Array.isArray(equipment)) {
    return bySlot;
  }

  for (const item of equipment) {
    const mappedSlot = normalizeEquipSlot(item?.slot);
    if (!mappedSlot) continue;
    if (!bySlot[mappedSlot]) bySlot[mappedSlot] = [];
    bySlot[mappedSlot].push(item);
  }

  return bySlot;
}

function getEquipItemsForTargetSlot(slotKey, equipBySlot) {
  if (!equipBySlot || typeof equipBySlot !== 'object') return null;

  switch (slotKey) {
    case 'finger1':
      return equipBySlot.finger?.[0] ? [equipBySlot.finger[0]] : [];
    case 'finger2':
      return equipBySlot.finger?.[1] ? [equipBySlot.finger[1]] : [];
    case 'trinket1':
      return equipBySlot.trinket?.[0] ? [equipBySlot.trinket[0]] : [];
    case 'trinket2':
      return equipBySlot.trinket?.[1] ? [equipBySlot.trinket[1]] : [];
    case 'mainHand':
      return equipBySlot.mainHand?.[0] ? [equipBySlot.mainHand[0]] : [];
    case 'offHand':
      return equipBySlot.offHand?.[0] ? [equipBySlot.offHand[0]] : [];
    default:
      return equipBySlot[slotKey]?.[0] ? [equipBySlot[slotKey][0]] : [];
  }
}

function getEnchantPriorityScore(slotKey) {
  switch (slotKey) {
    case 'mainHand':
      return 95;
    case 'offHand':
      return 80;
    case 'finger1':
    case 'finger2':
      return 70;
    default:
      return 60;
  }
}

function getCharacterEnchantmentsForSlot(slotKey, equipBySlot) {
  const items = getEquipItemsForTargetSlot(slotKey, equipBySlot);
  if (!Array.isArray(items) || items.length === 0) return [];

  const result = [];
  for (const item of items) {
    const enchantments = Array.isArray(item?.enchantments) ? item.enchantments : [];
    for (const enchant of enchantments) {
      if (typeof enchant === 'string' && enchant.trim()) {
        result.push(enchant.trim());
      }
    }
  }

  return result;
}

function getCharacterGemsForSlot(slotKey, equipBySlot) {
  const items = getEquipItemsForTargetSlot(slotKey, equipBySlot);
  if (!Array.isArray(items) || items.length === 0) return [];

  const result = [];
  for (const item of items) {
    const gems = Array.isArray(item?.gems) ? item.gems : [];
    for (const gem of gems) {
      if (typeof gem === 'string' && gem.trim()) {
        result.push(gem.trim());
      }
    }
  }

  return result;
}

// ─── /invalidate ─────────────────────────────────────────────────────────────

async function handleInvalidate(request, env) {
  return json({
    error: 'Deprecated endpoint. Recommendation cache invalidation is no longer supported.',
  }, 410);
}

// ─── /specs ───────────────────────────────────────────────────────────────────

async function handleSpecs(url, env) {
  return json({
    error: 'Deprecated endpoint. Recommendation catalog has been removed.',
  }, 410);
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function parsePositiveInt(value, fallback) {
  const parsed = parseInt(String(value ?? ''), 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
}

function getCacheTtlSeconds(env, cacheType) {
  const config = CACHE_TTLS[cacheType];
  if (!config) return 300;
  if (!config.envKey) return config.fallback;
  return parsePositiveInt(env[config.envKey], config.fallback);
}

function buildCharacterLegacyKey(region, realmInput, name) {
  return `char:${region}:${realmInput}:${name}`;
}

function buildCharacterCanonicalKey(region, realmSlug, name) {
  return `char:${region}:${realmSlug}:${name}`;
}

function buildTokenKey(region) {
  return `btoken:${region}`;
}

function buildRealmSlugKey(region, normalizedRealm) {
  return `realm_slug:${region}:${normalizedRealm}`;
}

function buildItemIconKey(region, itemId) {
  return `itemicon:${region}:${itemId}`;
}

function notImplementedV1(endpoint) {
  return json({
    version: 'v1',
    endpoint,
    status: 'not_implemented',
    message: 'Endpoint reserved for upcoming phase.',
  }, 501);
}

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
  });
}

function buildRequestId(request) {
  const cfRay = request.headers.get('cf-ray');
  if (cfRay && cfRay.trim()) return cfRay;
  if (typeof crypto?.randomUUID === 'function') return crypto.randomUUID();
  return `${Date.now()}-${Math.random().toString(16).slice(2)}`;
}

async function inferResponseSource(response) {
  const contentType = response.headers.get('Content-Type') || '';
  if (!contentType.includes('application/json')) {
    return { source: null, cacheHit: null };
  }

  try {
    const payload = await response.clone().json();
    const rawSource = payload?._source ?? payload?.source ?? null;
    const source = typeof rawSource === 'string'
      ? rawSource
      : (typeof rawSource?.character === 'string' ? rawSource.character : null);
    if (source === 'cache') {
      return { source: 'cache', cacheHit: true };
    }
    if (source === 'static' || source === 'blizzard') {
      return { source, cacheHit: false };
    }
    return { source, cacheHit: null };
  } catch {
    return { source: null, cacheHit: null };
  }
}

function logRequestTelemetry({
  requestId,
  endpoint,
  method,
  status,
  latencyMs,
  source,
  cacheHit,
}) {
  console.log(JSON.stringify({
    event: 'request_summary',
    request_id: requestId,
    endpoint,
    method,
    status,
    latency_ms: latencyMs,
    source,
    cache_hit: cacheHit,
    timestamp: new Date().toISOString(),
  }));
}

function logWorkerError({ requestId, endpoint, method, error }) {
  console.error(JSON.stringify({
    event: 'request_error',
    request_id: requestId,
    endpoint,
    method,
    error_message: error?.message || 'Unknown error',
    error_stack: error?.stack || null,
    timestamp: new Date().toISOString(),
  }));
}


