// Lesson 4, exercise 3: merge saved preferences into the defaults, one level deep, known keys only
function mergePreferences(defaults, saved) {
  const result = structuredClone(defaults);
  for (const [key, value] of Object.entries(saved)) {
    if (!Object.hasOwn(defaults, key)) continue; // unknown keys, __proto__ included, are ignored
    const current = result[key];
    if (current !== null && typeof current === 'object' && value !== null && typeof value === 'object') {
      result[key] = { ...current, ...value };
    } else {
      result[key] = value;
    }
  }
  return result;
}

const defaults = { skyboxMode: 'default', camera: { fov: 60, near: 0.1 } };
const saved = JSON.parse('{"__proto__":{"isAdmin":true},"camera":{"fov":75},"extra":1}');
const merged = mergePreferences(defaults, saved);
console.log(merged);
console.log(merged.isAdmin, Object.getPrototypeOf(merged) === Object.prototype, defaults.camera.fov);
