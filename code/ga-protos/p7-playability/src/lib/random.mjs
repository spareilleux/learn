// A seeded pseudo-random generator, so that every sample, every bagging draw and every weight initialisation
// in this prototype is reproducible on any machine. mulberry32: 32-bit state, one multiply-xorshift round.

export function mulberry32(seed) {
  let a = seed >>> 0;
  return function next() {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// Fisher-Yates, in place
export function shuffle(array, rng) {
  for (let i = array.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    [array[i], array[j]] = [array[j], array[i]];
  }
  return array;
}

// A stable 32-bit hash of a string, used to place a group in a split without shuffling every group.
//
// FNV-1a alone is not enough here. Its high bits barely move between two keys that differ in their last
// character, and a split reads exactly those high bits: with the plain FNV-1a, "chord0" to "chord39" all
// landed below 0.6 and the whole test set came out empty. The murmur3 finalizer below spreads the bits before
// anyone looks at them.
export function hash32(text) {
  let h = 0x811c9dc5;
  for (let i = 0; i < text.length; i++) {
    h ^= text.charCodeAt(i);
    h = Math.imul(h, 0x01000193) >>> 0;
  }
  h ^= h >>> 16;
  h = Math.imul(h, 0x85ebca6b) >>> 0;
  h ^= h >>> 13;
  h = Math.imul(h, 0xc2b2ae35) >>> 0;
  h ^= h >>> 16;
  return h >>> 0;
}
