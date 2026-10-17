/* Observatory: this build's files kept in the browser, and replaced when a newer build is published.
   Written for each build by artpass/publish/pwa/pwa.py, which fills in BUILD and FILES: a new build is a
   new worker, which is how the browser learns of it. Its own code, not Godot's service worker. */
const BUILD = {"version": 48, "built": 1792203904};
const FILES = ["index.html", "index.js", "index.wasm", "index.pck", "index.audio.worklet.js", "index.audio.position.worklet.js", "index.png", "index.icon.png", "index.apple-touch-icon.png", "manifest.webmanifest", "icon-192.png", "icon-512.png"];
const PREFIX = 'observatory-';
const CACHE = PREFIX + BUILD.version + '-' + BUILD.built;
const SCOPE = self.registration.scope;
const SCOPE_PATH = new URL(SCOPE).pathname;
const key = (name) => new URL(name, SCOPE).href;

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE);
    // One after the other: ninety megabytes at once is a lot for a phone. 'no-cache' makes the browser
    // check its own copy with the server, so a file that has not changed costs a 304 and a file that
    // has cannot come stale out of the browser's cache.
    for (const name of FILES) {
      const response = await fetch(new Request(key(name), { cache: 'no-cache' }));
      if (!response.ok) throw new Error(name + ': ' + response.status);
      await cache.put(key(name), response);
    }
    // Nothing waits for the old pages to close: a page that runs has its files in memory already.
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.filter((k) => k.startsWith(PREFIX) && k !== CACHE).map((k) => caches.delete(k)));
    await self.clients.claim();
    const pages = await self.clients.matchAll({ type: 'window', includeUncontrolled: true });
    for (const page of pages) page.postMessage({ type: 'obs-updated', version: BUILD.version, built: BUILD.built });
  })());
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET' || !request.url.startsWith(SCOPE)) return;
  // The page's address may carry a query (?preset=gardens, ?cinematic=1): the file is the same.
  const name = new URL(request.url).pathname.slice(SCOPE_PATH.length) || 'index.html';
  if (!FILES.includes(name)) return;
  event.respondWith((async () => {
    const cache = await caches.open(CACHE);
    const kept = await cache.match(key(name));
    return kept || fetch(request);
  })());
});

self.addEventListener('message', (event) => {
  if (event.data === 'obs-build' && event.source) {
    event.source.postMessage({ type: 'obs-build', version: BUILD.version, built: BUILD.built });
  }
});
