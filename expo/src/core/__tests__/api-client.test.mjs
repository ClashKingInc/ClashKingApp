import assert from 'node:assert/strict';
import test from 'node:test';

import {
  ApiClient,
  BadRequestException,
  NotFoundException,
  UnauthorizedException,
} from '../api/client.ts';

test('QUERY sends JSON, bearer auth, and web credentials', async () => {
  let request;
  const client = new ApiClient({
    baseUrl: 'https://api.example/v2',
    environment: 'production',
    platform: 'web',
    tokenProvider: { getAccessToken: async () => 'access-token' },
    fetchImplementation: async (input, init) => {
      request = { input, init };
      return new Response('{"ok":true}', { status: 200 });
    },
  });
  assert.deepEqual(
    await client.requestRecord('/stats/war', {
      method: 'QUERY',
      body: { player_tags: ['#ABC'] },
      requiresAuth: true,
    }),
    { ok: true },
  );
  assert.equal(request.input, 'https://api.example/v2/stats/war');
  assert.equal(request.init.method, 'QUERY');
  assert.equal(request.init.credentials, 'include');
  assert.equal(request.init.headers.Authorization, 'Bearer access-token');
  assert.equal(request.init.body, '{"player_tags":["#ABC"]}');
});

test('proxy GET always requires bearer auth', async () => {
  let request;
  const client = new ApiClient({
    baseUrl: 'https://api.example/v2',
    proxyUrl: 'https://api.example/proxy/v1',
    environment: 'production',
    tokenProvider: { getAccessToken: async () => 'proxy-token' },
    fetchImplementation: async (input, init) => {
      request = { input, init };
      return new Response('{}');
    },
  });
  await client.proxyGet('players/%23ABC');
  assert.equal(request.input, 'https://api.example/proxy/v1/players/%23ABC');
  assert.equal(request.init.headers.Authorization, 'Bearer proxy-token');
});

test('missing bearer fails closed except in local mode', async () => {
  const production = new ApiClient({
    baseUrl: 'https://api.example/v2',
    environment: 'production',
    tokenProvider: { getAccessToken: async () => null },
    fetchImplementation: async () => new Response('{}'),
  });
  await assert.rejects(production.get('/auth/me', { requiresAuth: true }), UnauthorizedException);
  const local = new ApiClient({
    baseUrl: 'http://localhost:8000/v2',
    environment: 'local',
    tokenProvider: { getAccessToken: async () => null },
    fetchImplementation: async () => new Response('{}'),
  });
  await assert.doesNotReject(local.get('/auth/me', { requiresAuth: true }));
});

test('errors and endpoint status overrides remain explicit', async () => {
  const badRequest = new ApiClient({
    baseUrl: 'https://api.example/v2',
    environment: 'production',
    fetchImplementation: async () => new Response('{"detail":"Specific failure"}', { status: 400 }),
  });
  await assert.rejects(
    badRequest.get('/bad'),
    (error) => error instanceof BadRequestException && error.message === 'Specific failure',
  );

  const missing = new ApiClient({
    baseUrl: 'https://api.example/v2',
    environment: 'production',
    fetchImplementation: async () => new Response('', { status: 404 }),
  });
  await assert.rejects(missing.get('/optional'), NotFoundException);
  assert.equal((await missing.get('/optional', { acceptedStatuses: [404] })).status, 404);
});
