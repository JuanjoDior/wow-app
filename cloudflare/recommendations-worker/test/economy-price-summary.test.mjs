import test from 'node:test';
import assert from 'node:assert/strict';

import worker from '../src/index.js';

function createEnv(overrides = {}) {
  const cache = new Map();

  const env = {
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
    ...overrides,
  };

  return { env, cache };
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

test('economy price summary endpoint is disabled by flag by default', async () => {
  const { env } = createEnv({ FEATURE_ECONOMY_ASSISTANT: 'false' });

  const req = new Request(
    'https://worker.example/v1/economy/price-summary?region=eu&item_ids=111',
  );
  const res = await worker.fetch(req, env);
  const body = await res.json();

  assert.equal(res.status, 503);
  assert.equal(body.version, 'v1');
  assert.equal(body.endpoint, '/v1/economy/price-summary');
  assert.match(body.error, /economy_assistant/i);
});

test('economy price summary validates required params', async () => {
  const { env } = createEnv({ FEATURE_ECONOMY_ASSISTANT: 'true' });

  const req = new Request(
    'https://worker.example/v1/economy/price-summary?region=eu',
  );
  const res = await worker.fetch(req, env);
  const body = await res.json();

  assert.equal(res.status, 400);
  assert.equal(body.version, 'v1');
  assert.equal(body.endpoint, '/v1/economy/price-summary');
  assert.match(body.error, /item_ids/i);
});

test('economy price summary computes commodities stats and serves cache on second call', async () => {
  const { env } = createEnv({ FEATURE_ECONOMY_ASSISTANT: 'true' });
  let oauthCalls = 0;
  let commoditiesCalls = 0;

  await withMockedFetch(async (url) => {
    if (url.hostname === 'oauth.battle.net') {
      oauthCalls += 1;
      return jsonResponse({ access_token: 'token' });
    }
    if (url.pathname === '/data/wow/auctions/commodities') {
      commoditiesCalls += 1;
      return jsonResponse({
        auctions: [
          { item: { id: 111 }, unit_price: 100, quantity: 2 },
          { item: { id: 111 }, unit_price: 200, quantity: 3 },
          { item: { id: 111 }, unit_price: 500, quantity: 1 },
          { item: { id: 222 }, unit_price: 400, quantity: 1 },
        ],
      });
    }
    return new Response('Not Found', { status: 404 });
  }, async () => {
    const requestUrl =
      'https://worker.example/v1/economy/price-summary?region=eu&item_ids=111,333';

    const first = await worker.fetch(new Request(requestUrl), env);
    const firstBody = await first.json();
    assert.equal(first.status, 200);
    assert.equal(firstBody._source, 'economy');
    assert.equal(firstBody.source?.market, 'commodities');
    assert.equal(firstBody.summary?.requested_items, 2);
    assert.equal(firstBody.summary?.resolved_items, 1);
    assert.equal(firstBody.summary?.missing_items, 1);

    const item111 = firstBody.results.find((entry) => entry.item_id === 111);
    assert.ok(item111);
    assert.equal(item111.min_price, 100);
    assert.equal(item111.median_price, 200);
    assert.equal(item111.p95_price, 500);
    assert.equal(item111.total_quantity, 6);
    assert.equal(item111.listing_count, 3);

    const item333 = firstBody.results.find((entry) => entry.item_id === 333);
    assert.ok(item333);
    assert.equal(item333.min_price, null);
    assert.equal(item333.median_price, null);
    assert.equal(item333.p95_price, null);
    assert.equal(item333.total_quantity, 0);
    assert.equal(item333.listing_count, 0);

    const second = await worker.fetch(new Request(requestUrl), env);
    const secondBody = await second.json();
    assert.equal(second.status, 200);
    assert.equal(secondBody._source, 'cache');
    assert.equal(oauthCalls, 1);
    assert.equal(commoditiesCalls, 1);
  });
});

test('economy price summary supports connected realm auctions', async () => {
  const { env } = createEnv({ FEATURE_ECONOMY_ASSISTANT: 'true' });
  let connectedRealmCalls = 0;

  await withMockedFetch(async (url) => {
    if (url.hostname === 'oauth.battle.net') {
      return jsonResponse({ access_token: 'token' });
    }
    if (url.pathname === '/data/wow/connected-realm/1080/auctions') {
      connectedRealmCalls += 1;
      return jsonResponse({
        auctions: [
          { item: { id: 111 }, buyout: 900, quantity: 3 },
          { item: { id: 111 }, buyout: 150, quantity: 1 },
        ],
      });
    }
    return new Response('Not Found', { status: 404 });
  }, async () => {
    const req = new Request(
      'https://worker.example/v1/economy/price-summary?region=eu&item_ids=111&connected_realm_id=1080',
    );
    const res = await worker.fetch(req, env);
    const body = await res.json();

    assert.equal(res.status, 200);
    assert.equal(body.source?.market, 'auctions');
    assert.equal(body.context?.connected_realm_id, 1080);

    const item111 = body.results.find((entry) => entry.item_id === 111);
    assert.ok(item111);
    assert.equal(item111.min_price, 150);
    assert.equal(item111.median_price, 300);
    assert.equal(item111.p95_price, 300);
    assert.equal(item111.total_quantity, 4);
    assert.equal(item111.listing_count, 2);

    assert.equal(connectedRealmCalls, 1);
  });
});

test('economy price summary resolves connected realm from realm param', async () => {
  const { env } = createEnv({ FEATURE_ECONOMY_ASSISTANT: 'true' });
  let realmCalls = 0;
  let auctionsCalls = 0;
  let commoditiesCalls = 0;

  await withMockedFetch(async (url) => {
    if (url.hostname === 'oauth.battle.net') {
      return jsonResponse({ access_token: 'token' });
    }
    if (url.pathname === '/data/wow/realm/sanguino') {
      realmCalls += 1;
      return jsonResponse({
        id: 1303,
        slug: 'sanguino',
        connected_realm: { id: 1080 },
      });
    }
    if (url.pathname === '/data/wow/connected-realm/1080/auctions') {
      auctionsCalls += 1;
      return jsonResponse({
        auctions: [
          { item: { id: 111 }, unit_price: 350, quantity: 5 },
        ],
      });
    }
    if (url.pathname === '/data/wow/auctions/commodities') {
      commoditiesCalls += 1;
      return jsonResponse({ auctions: [] });
    }
    return new Response('Not Found', { status: 404 });
  }, async () => {
    const req = new Request(
      'https://worker.example/v1/economy/price-summary?region=eu&realm=sanguino&item_ids=111',
    );
    const res = await worker.fetch(req, env);
    const body = await res.json();

    assert.equal(res.status, 200);
    assert.equal(body.source?.market, 'auctions');
    assert.equal(body.context?.realm, 'sanguino');
    assert.equal(body.context?.connected_realm_id, 1080);
    assert.equal(realmCalls, 1);
    assert.equal(auctionsCalls, 1);
    assert.equal(commoditiesCalls, 0);
  });
});

test('economy price summary falls back to connected-realm search when realm endpoints omit relation', async () => {
  const { env } = createEnv({ FEATURE_ECONOMY_ASSISTANT: 'true' });
  let connectedRealmSearchCalls = 0;
  let auctionsCalls = 0;

  await withMockedFetch(async (url) => {
    if (url.hostname === 'oauth.battle.net') {
      return jsonResponse({ access_token: 'token' });
    }
    if (url.pathname === '/data/wow/realm/sanguino') {
      return jsonResponse({
        id: 1303,
        slug: 'sanguino',
      });
    }
    if (url.pathname === '/data/wow/search/realm') {
      return jsonResponse({ results: [] });
    }
    if (url.pathname === '/data/wow/search/connected-realm') {
      connectedRealmSearchCalls += 1;
      return jsonResponse({
        results: [
          {
            data: {
              id: 1080,
              realms: [{ slug: 'sanguino', name: { en_US: 'Sanguino' } }],
            },
          },
        ],
      });
    }
    if (url.pathname === '/data/wow/connected-realm/1080/auctions') {
      auctionsCalls += 1;
      return jsonResponse({
        auctions: [{ item: { id: 111 }, unit_price: 500, quantity: 3 }],
      });
    }
    return new Response('Not Found', { status: 404 });
  }, async () => {
    const req = new Request(
      'https://worker.example/v1/economy/price-summary?region=eu&realm=sanguino&item_ids=111',
    );
    const res = await worker.fetch(req, env);
    const body = await res.json();

    assert.equal(res.status, 200);
    assert.equal(body.source?.market, 'auctions');
    assert.equal(body.context?.connected_realm_id, 1080);
    assert.ok(connectedRealmSearchCalls > 0);
    assert.equal(auctionsCalls, 1);
  });
});

test('economy price summary resolves connected realm via realms.id search', async () => {
  const { env } = createEnv({ FEATURE_ECONOMY_ASSISTANT: 'true' });
  let realmsIdSearchCalls = 0;
  let auctionsCalls = 0;

  await withMockedFetch(async (url) => {
    if (url.hostname === 'oauth.battle.net') {
      return jsonResponse({ access_token: 'token' });
    }
    if (url.pathname === '/data/wow/realm/sanguino') {
      return jsonResponse({
        id: 1303,
        slug: 'sanguino',
      });
    }
    if (url.pathname === '/data/wow/search/connected-realm') {
      const realmIdFilter = url.searchParams.get('realms.id');
      if (realmIdFilter === '1303') {
        realmsIdSearchCalls += 1;
        return jsonResponse({
          results: [{ data: { id: 1080, realms: [{ slug: 'sanguino' }] } }],
        });
      }
      return jsonResponse({ results: [] });
    }
    if (url.pathname === '/data/wow/connected-realm/1080/auctions') {
      auctionsCalls += 1;
      return jsonResponse({
        auctions: [{ item: { id: 111 }, unit_price: 900, quantity: 2 }],
      });
    }
    if (url.pathname === '/data/wow/search/realm') {
      return jsonResponse({ results: [] });
    }
    return new Response('Not Found', { status: 404 });
  }, async () => {
    const req = new Request(
      'https://worker.example/v1/economy/price-summary?region=eu&realm=sanguino&item_ids=111',
    );
    const res = await worker.fetch(req, env);
    const body = await res.json();

    assert.equal(res.status, 200);
    assert.equal(body.source?.market, 'auctions');
    assert.equal(body.context?.connected_realm_id, 1080);
    assert.equal(realmsIdSearchCalls, 1);
    assert.equal(auctionsCalls, 1);
  });
});
