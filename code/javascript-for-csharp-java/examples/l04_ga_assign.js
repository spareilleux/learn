// Lesson 4: getDefaults in SceneOptions.tsx of GuitarAlchemist/ga (a826864), reduced to plain JavaScript
import { show } from './show.js';

function getDefaults(search, saved) {
  const state = { stars: true, tower: false, skyboxMode: 'milky-way' };
  // Lines 62-73: URL parameters override the defaults
  const params = new URLSearchParams(search);
  if (params.has('tower')) state.tower = true;
  // Lines 75-78: then the preferences saved in localStorage are merged in
  if (saved) Object.assign(state, JSON.parse(saved));
  return state;
}

// Every toggle saves the whole state (lines 94, 103 and 112), so a saved state has every key
const saved = JSON.stringify({ stars: false, tower: false, skyboxMode: 'milky-way' });
show("getDefaults('?tower', null)", getDefaults('?tower', null));
show("getDefaults('?tower', saved)", getDefaults('?tower', saved));

// Object.assign copies every own property of the source, known or not
show('with an old key', getDefaults('', '{"bloomLevel":3,"stars":"yes"}'));

// JSON.parse makes __proto__ an ordinary property; Object.assign then assigns it, which changes the prototype
const parsed = JSON.parse('{"__proto__":{"isAdmin":true}}');
show("Object.hasOwn(parsed, '__proto__')", Object.hasOwn(parsed, '__proto__'));
const state = getDefaults('', '{"__proto__":{"isAdmin":true}}');
show('state.isAdmin', state.isAdmin);
show("Object.hasOwn(state, 'isAdmin')", Object.hasOwn(state, 'isAdmin'));
show('{}.isAdmin', {}.isAdmin);

// Spread defines properties instead of assigning them: the prototype stays Object.prototype
const spread = { ...parsed };
show('spread.isAdmin', spread.isAdmin);
show('Object.keys(spread)', Object.keys(spread));
