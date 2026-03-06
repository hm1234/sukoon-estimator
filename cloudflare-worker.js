/**
 * Sukoon Coffee Co. — Settings Sync Worker
 * Cloudflare Worker that stores app settings in KV.
 * No GitHub token needed — the app talks directly to this URL.
 *
 * ── SETUP (one-time, 5 min) ──────────────────────────────────────────────
 *  1. dash.cloudflare.com → Workers & Pages → KV
 *     → Create namespace → Name: "sukoon-sync-kv" → Add
 *
 *  2. Workers & Pages → Create → Create Worker
 *     → Name it "sukoon-sync" → Deploy
 *     → Click "Edit code", paste ALL of this file → Deploy
 *
 *  3. Back on the Worker page → Settings → Bindings → Add
 *     → KV Namespace
 *     → Variable name:  SUKOON_KV
 *     → KV Namespace:   sukoon-sync-kv   (the one you just created)
 *     → Save and deploy
 *
 *  4. Copy the Worker URL shown at the top (looks like:
 *       https://sukoon-sync.YOUR_SUBDOMAIN.workers.dev )
 *     Then paste it into index.html where it says WORKER_URL.
 * ─────────────────────────────────────────────────────────────────────────
 */

const SECRET = 'suk-sync-Xk9pR3nW7qLm2Tz5';   // must match index.html WORKER_SECRET
const KV_KEY = 'settings';

const CORS = {
  'Access-Control-Allow-Origin':  '*',
  'Access-Control-Allow-Methods': 'GET, PUT, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, X-Secret',
};

export default {
  async fetch(request, env) {

    // ── CORS preflight ────────────────────────────────────────────────────
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: CORS });
    }

    // ── Auth ──────────────────────────────────────────────────────────────
    if (request.headers.get('X-Secret') !== SECRET) {
      return new Response('Unauthorized', { status: 401, headers: CORS });
    }

    // ── GET → load settings ───────────────────────────────────────────────
    if (request.method === 'GET') {
      const val = await env.SUKOON_KV.get(KV_KEY);
      return new Response(val || '{}', {
        headers: { ...CORS, 'Content-Type': 'application/json' },
      });
    }

    // ── PUT → save settings ───────────────────────────────────────────────
    if (request.method === 'PUT') {
      const body = await request.text();
      try { JSON.parse(body); } catch (e) {
        return new Response('Invalid JSON', { status: 400, headers: CORS });
      }
      await env.SUKOON_KV.put(KV_KEY, body);
      return new Response('OK', { headers: CORS });
    }

    return new Response('Method not allowed', { status: 405, headers: CORS });
  },
};
