// Lesson 4, exercise 3: defaults, then saved preferences of the right type for known keys only, then URL overrides
function getDefaults(search, saved) {
  const state = { stars: true, tower: false, skyboxMode: 'milky-way' };
  const preferences = saved ? JSON.parse(saved) : {};
  for (const key of Object.keys(state)) {
    // Object.keys(state) lists the known keys: __proto__ and old keys are never read
    if (Object.hasOwn(preferences, key) && typeof preferences[key] === typeof state[key]) {
      state[key] = preferences[key];
    }
  }
  const params = new URLSearchParams(search);
  if (params.has('tower')) state.tower = true; // last, so the URL wins
  return state;
}

const saved = JSON.stringify({ stars: false, tower: false, skyboxMode: 'milky-way' });
console.log(getDefaults('?tower', saved));
console.log(getDefaults('', '{"bloomLevel":3,"stars":"yes","__proto__":{"isAdmin":true}}'));
console.log(getDefaults('', '{"__proto__":{"isAdmin":true}}').isAdmin);
