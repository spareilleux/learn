// Lesson 4: SceneOptions.tsx in GuitarAlchemist/ga (a826864) merges saved preferences with Object.assign
import { show } from './show.js';

function defaults() {
  return { skyboxMode: 'default', camera: { fov: 60, near: 0.1 } };
}

// Line 77: if (saved) Object.assign(state, JSON.parse(saved));
const saved = '{"camera":{"fov":75}}';
const state = defaults();
Object.assign(state, JSON.parse(saved));
show('state.camera', state.camera); // the saved object replaced the default one: near is gone

// JSON.parse makes __proto__ an ordinary property; Object.assign then assigns it, which changes the prototype
const odd = '{"__proto__":{"isAdmin":true},"skyboxMode":"jwst"}';
const parsed = JSON.parse(odd);
show("Object.hasOwn(parsed, '__proto__')", Object.hasOwn(parsed, '__proto__'));
const assigned = Object.assign(defaults(), parsed);
show('assigned.isAdmin', assigned.isAdmin);
show("Object.hasOwn(assigned, 'isAdmin')", Object.hasOwn(assigned, 'isAdmin'));

// Spread defines properties instead of assigning them: the prototype stays Object.prototype
const spread = { ...defaults(), ...parsed };
show('spread.isAdmin', spread.isAdmin);
show('Object.keys(spread)', Object.keys(spread));
show('{}.isAdmin', {}.isAdmin);
