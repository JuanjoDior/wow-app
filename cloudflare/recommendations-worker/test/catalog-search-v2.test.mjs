import test from 'node:test';
import assert from 'node:assert/strict';

import worker from '../src/index.js';

function createEnv() {
  const cache = new Map();
  return {
    env: {
      CURRENT_PATCH: '12.0.1',
      SERVICE_VERSION: '5.1.0',
      BLIZZARD_CLIENT_ID: 'test-client',
      BLIZZARD_CLIENT_SECRET: 'test-secret',
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
    },
    cache,
  };
}

function jsonResponse(payload, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

function withMockedFetch(mock, fn) {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async (input, init) => {
    const requestUrl = typeof input === 'string' ? input : input.url;
    const url = new URL(requestUrl);
    return mock(url, init);
  };

  return Promise.resolve()
    .then(fn)
    .finally(() => {
      globalThis.fetch = originalFetch;
    });
}

function itemEntry({
  id,
  name,
  quality = 'EPIC',
  level = 600,
  itemClass = 'Armor',
  itemSubclass = 'Plate',
  inventoryType = 'HEAD',
  inventoryName = 'Head',
}) {
  return {
    data: {
      id,
      name,
      quality: { type: quality },
      level,
      item_class: { name: itemClass },
      item_subclass: { name: itemSubclass },
      inventory_type: { type: inventoryType, name: inventoryName },
    },
  };
}

test('catalog search item mode respects inventory_type', async () => {
  const { env } = createEnv();

  await withMockedFetch(async (url) => {
    if (url.hostname === 'oauth.battle.net') {
      return jsonResponse({ access_token: 'token' });
    }
    if (url.pathname === '/data/wow/search/item') {
      const locale = url.searchParams.get('locale');
      const localizedHead = locale === 'en_US' ? 'Helm of Precision' : 'Yelmo de precisión';
      const localizedChest = locale === 'en_US' ? 'Chestguard of Power' : 'Coraza de poder';
      return jsonResponse({
        results: [
          itemEntry({
            id: 1001,
            name: localizedHead,
            inventoryType: 'HEAD',
            inventoryName: locale === 'en_US' ? 'Head' : 'Cabeza',
          }),
          itemEntry({
            id: 1002,
            name: localizedChest,
            inventoryType: 'CHEST',
            inventoryName: locale === 'en_US' ? 'Chest' : 'Pecho',
          }),
        ],
      });
    }
    if (url.pathname === '/data/wow/search/spell') {
      return jsonResponse({ results: [] });
    }
    return new Response('Not Found', { status: 404 });
  }, async () => {
    const req = new Request(
      'https://worker.example/v2/catalog/search?q=helm&mode=item&region=eu&locale=en_GB&inventory_type=HEAD',
    );
    const res = await worker.fetch(req, env);
    const body = await res.json();

    assert.equal(res.status, 200);
    assert.equal(body.version, 'v2');
    assert.equal(body.endpoint, '/v2/catalog/search');
    assert.equal(body.query.inventory_type, 'HEAD');
    assert.equal(body.results.length, 1);
    assert.equal(body.results[0].inventory_type, 'HEAD');
  });
});

test('catalog search gem mode prioritizes gem over recipe', async () => {
  const { env } = createEnv();

  await withMockedFetch(async (url) => {
    if (url.hostname === 'oauth.battle.net') {
      return jsonResponse({ access_token: 'token' });
    }
    if (url.pathname === '/data/wow/search/item') {
      const locale = url.searchParams.get('locale');
      const recipeName =
        locale === 'en_US'
          ? 'Design: Culminating Blasphemite'
          : 'Boceto: blasfemita culminante';
      const gemName =
        locale === 'en_US'
          ? 'Culminating Blasphemite'
          : 'Blasfemita culminante';
      return jsonResponse({
        results: [
          itemEntry({
            id: 223087,
            name: recipeName,
            itemClass: locale === 'en_US' ? 'Recipe' : 'Receta',
            itemSubclass: locale === 'en_US' ? 'Jewelcrafting' : 'Joyería',
            inventoryType: 'NON_EQUIP',
            inventoryName:
              locale === 'en_US' ? 'Non-equippable' : 'No equipable',
          }),
          itemEntry({
            id: 213743,
            name: gemName,
            itemClass: locale === 'en_US' ? 'Gem' : 'Gema',
            itemSubclass: locale === 'en_US' ? 'Other' : 'Otros',
            inventoryType: 'NON_EQUIP',
            inventoryName:
              locale === 'en_US' ? 'Non-equippable' : 'No equipable',
          }),
        ],
      });
    }
    return new Response('Not Found', { status: 404 });
  }, async () => {
    const req = new Request(
      'https://worker.example/v2/catalog/search?q=Culminating%20Blasphemite&mode=gem&region=eu&locale=en_GB',
    );
    const res = await worker.fetch(req, env);
    const body = await res.json();

    assert.equal(res.status, 200);
    assert.ok(body.results.length >= 2);
    assert.equal(body.results[0].id, 213743);
  });
});

test('catalog search enchant mode returns localized and canonical english names', async () => {
  const { env } = createEnv();

  await withMockedFetch(async (url) => {
    if (url.hostname === 'oauth.battle.net') {
      return jsonResponse({ access_token: 'token' });
    }
    if (url.pathname === '/data/wow/search/item') {
      const locale = url.searchParams.get('locale');
      return jsonResponse({
        results: [
          itemEntry({
            id: 3001,
            name:
              locale === 'en_US'
                ? 'Enchant Weapon - Authority of Fiery Resolve'
                : 'Encantar arma: autoridad de resolución ígnea',
            itemClass: locale === 'en_US' ? 'Recipe' : 'Receta',
            itemSubclass: locale === 'en_US' ? 'Enchanting' : 'Encantamiento',
            inventoryType: 'NON_EQUIP',
            inventoryName:
              locale === 'en_US' ? 'Non-equippable' : 'No equipable',
          }),
        ],
      });
    }
    if (url.pathname === '/data/wow/search/spell') {
      return jsonResponse({ results: [] });
    }
    return new Response('Not Found', { status: 404 });
  }, async () => {
    const req = new Request(
      'https://worker.example/v2/catalog/search?q=Authority%20of%20Fiery%20Resolve&mode=enchant&region=eu&locale=es_ES',
    );
    const res = await worker.fetch(req, env);
    const body = await res.json();

    assert.equal(res.status, 200);
    assert.ok(body.results.length >= 1);
    assert.equal(body.results[0].id, 3001);
    assert.equal(
      body.results[0].name_en_us,
      'Enchant Weapon - Authority of Fiery Resolve',
    );
    assert.equal(
      body.results[0].name_localized,
      'Encantar arma: autoridad de resolución ígnea',
    );
  });
});

test('catalog search validates mode', async () => {
  const { env } = createEnv();
  const req = new Request(
    'https://worker.example/v2/catalog/search?q=coin&mode=invalid',
  );
  const res = await worker.fetch(req, env);
  const body = await res.json();

  assert.equal(res.status, 400);
  assert.equal(body.version, 'v2');
  assert.equal(body.endpoint, '/v2/catalog/search');
  assert.match(body.error, /invalid mode/i);
});
