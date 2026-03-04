import test from 'node:test';
import assert from 'node:assert/strict';

import worker from '../src/index.js';

function createEnv() {
  const cache = new Map();

  const env = {
    CURRENT_PATCH: '12.0.1',
    SERVICE_VERSION: '5.1.0',
    RECS_CACHE: {
      async get(key, type) {
        const value = cache.get(key);
        if (value == null) return null;
        if (type === 'json') return JSON.parse(value);
        return value;
      },
      async put(key, value) {
        cache.set(key, value);
      },
      async delete(key) {
        cache.delete(key);
      },
    },
  };

  return { env, cache };
}

test('health exposes v2 capability', async () => {
  const { env } = createEnv();
  const req = new Request('https://worker.example/health');
  const res = await worker.fetch(req, env);
  const body = await res.json();

  assert.equal(res.status, 200);
  assert.equal(body.status, 'ok');
  assert.equal(body.capabilities?.build_verification_v2, true);
});

test('v1 build gap-analysis uses objective mode in compatibility alias', async () => {
  const { env, cache } = createEnv();
  cache.set(
    'char:eu:sanguino:apastar',
    JSON.stringify({
      name: 'Apastar',
      realm: 'Sanguino',
      region: 'EU',
      class: 'Druid',
      spec: 'Feral',
      equipment: [
        {
          slot: 'MAIN_HAND',
          enchantments: ['Authority of Radiant Power'],
          enchantment_ids: [1234],
          gems: [],
          gem_ids: [],
          sockets_total: 0,
          sockets_filled: 0,
        },
      ],
      _source: 'cache',
    }),
  );

  const req = new Request(
    'https://worker.example/v1/build/gap-analysis?region=eu&realm=sanguino&name=apastar&class=druid&spec=feral',
  );
  const res = await worker.fetch(req, env);
  const body = await res.json();

  assert.equal(res.status, 200);
  assert.equal(body.version, 'v1');
  assert.equal(body.endpoint, '/v1/build/gap-analysis');
  assert.equal(body.summary.analysis_mode, 'objective');
  assert.equal(body.summary.target_profile, 'character_only');
  assert.equal(body.summary.checks_total, 0);
  assert.equal(body.summary.actions_count, 0);
  assert.equal(body.facts.enchanted_items_count, 1);
  assert.equal(body.source.policy, 'official_only');
});

test('v1 build gap-analysis validates required params', async () => {
  const { env } = createEnv();

  const req = new Request(
    'https://worker.example/v1/build/gap-analysis?region=eu',
  );
  const res = await worker.fetch(req, env);
  const body = await res.json();

  assert.equal(res.status, 400);
  assert.equal(body.version, 'v1');
  assert.equal(body.endpoint, '/v1/build/gap-analysis');
  assert.match(body.error, /Missing required params/i);
});

test('v2 build verification matches by IDs even with different localized names', async () => {
  const { env, cache } = createEnv();
  cache.set(
    'char:eu:sanguino:apastar',
    JSON.stringify({
      name: 'Apastar',
      realm: 'Sanguino',
      region: 'EU',
      class: 'Druid',
      spec: 'Feral',
      equipment: [
        {
          slot: 'MAIN_HAND',
          enchantments: ['Authority of Radiant Power'],
          enchantment_ids: [9001],
          gems: [],
          gem_ids: [],
          sockets_total: 0,
          sockets_filled: 0,
        },
      ],
      _source: 'cache',
    }),
  );

  const buildSlots = encodeURIComponent(
    JSON.stringify([
      {
        slot: 'mainHand',
        enchantment_id: 9001,
        enchantment: 'Autoridad de Poder Radiante',
      },
    ]),
  );
  const req = new Request(
    `https://worker.example/v2/build/verification?region=eu&realm=sanguino&name=apastar&build_slots=${buildSlots}`,
  );
  const res = await worker.fetch(req, env);
  const body = await res.json();

  assert.equal(res.status, 200);
  assert.equal(body.version, 'v2');
  assert.equal(body.endpoint, '/v2/build/verification');
  assert.equal(body.summary.target_profile, 'build_target');
  assert.equal(body.summary.checks_total, 1);
  assert.equal(body.summary.checks_completed, 1);
  assert.equal(body.summary.actions_count, 0);
});

test('v2 build verification falls back to name matching when IDs are absent', async () => {
  const { env, cache } = createEnv();
  cache.set(
    'char:eu:sanguino:apastar',
    JSON.stringify({
      name: 'Apastar',
      realm: 'Sanguino',
      region: 'EU',
      class: 'Druid',
      spec: 'Feral',
      equipment: [
        {
          slot: 'FINGER_1',
          enchantments: [],
          enchantment_ids: [],
          gems: ['Radiant Mastery'],
          gem_ids: [],
          sockets_total: 1,
          sockets_filled: 1,
        },
      ],
      _source: 'cache',
    }),
  );

  const buildSlots = encodeURIComponent(
    JSON.stringify([
      {
        slot: 'finger1',
        gems: ['Radiant Mastery'],
      },
    ]),
  );
  const req = new Request(
    `https://worker.example/v2/build/verification?region=eu&realm=sanguino&name=apastar&build_slots=${buildSlots}`,
  );
  const res = await worker.fetch(req, env);
  const body = await res.json();

  assert.equal(res.status, 200);
  assert.equal(body.summary.target_profile, 'build_target');
  assert.equal(body.summary.checks_total, 1);
  assert.equal(body.summary.checks_completed, 1);
  assert.equal(body.summary.actions_count, 0);
});

test('v2 build verification classifies mismatch vs missing actions', async () => {
  const { env, cache } = createEnv();
  cache.set(
    'char:eu:sanguino:apastar',
    JSON.stringify({
      name: 'Apastar',
      realm: 'Sanguino',
      region: 'EU',
      class: 'Druid',
      spec: 'Feral',
      equipment: [
        {
          slot: 'MAIN_HAND',
          enchantments: ['Authority of Radiant Power'],
          enchantment_ids: [1001],
          gems: [],
          gem_ids: [],
          sockets_total: 0,
          sockets_filled: 0,
        },
        {
          slot: 'FINGER_1',
          enchantments: [],
          enchantment_ids: [],
          gems: [],
          gem_ids: [],
          sockets_total: 1,
          sockets_filled: 0,
        },
      ],
      _source: 'cache',
    }),
  );

  const buildSlots = encodeURIComponent(
    JSON.stringify([
      {
        slot: 'mainHand',
        enchantment_id: 2002,
        enchantment: 'Authority of Fiery Resolve',
      },
      {
        slot: 'finger1',
        gem_ids: [3003],
        gems: ['Radiant Mastery'],
      },
    ]),
  );
  const req = new Request(
    `https://worker.example/v2/build/verification?region=eu&realm=sanguino&name=apastar&build_slots=${buildSlots}`,
  );
  const res = await worker.fetch(req, env);
  const body = await res.json();

  assert.equal(res.status, 200);
  assert.equal(body.summary.checks_total, 2);
  assert.equal(body.summary.checks_completed, 0);
  assert.equal(body.summary.mismatched_enchants, 1);
  assert.equal(body.summary.missing_gems, 1);

  const enchantAction = body.actions.find((action) => action.type === 'enchant_mismatch_target');
  const gemAction = body.actions.find((action) => action.type === 'gem_missing_target');
  assert.ok(enchantAction);
  assert.ok(gemAction);
});
