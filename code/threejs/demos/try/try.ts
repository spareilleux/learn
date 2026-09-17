// The "try it" panel of the live lesson pages: each control sets one of the page's URL parameters and reloads it, which
// is how the lessons' exercises change a page (the pages read their parameters once, when they start).
import GUI from 'three/addons/libs/lil-gui.module.min.js';

type Control =
  // A parameter present or absent; invert: the box is ticked when it is absent; value: the value that counts as present
  | { key: string; label: string; kind: 'flag'; invert?: boolean; value?: string }
  | { key: string; label: string; kind: 'select'; options: string[] }
  | { key: string; label: string; kind: 'number'; min: number; max: number; step: number; value: number };

const PANELS: Record<string, Control[]> = {
  '01-scene': [
    { key: 'cubes', label: 'cubes', kind: 'number', min: 1, max: 20, step: 1, value: 1 },
    { key: 'linear', label: 'linear output', kind: 'flag' },
  ],
  '02-materials-lights': [
    { key: 'noshadows', label: 'shadows', kind: 'flag', invert: true },
    { key: 'neckshadow', label: 'neck casts a shadow', kind: 'flag', invert: true, value: 'off' },
  ],
  '03-color': [
    { key: 'tone', label: 'tone mapping', kind: 'select', options: ['none', 'aces', 'agx', 'neutral'] },
    { key: 'exposure', label: 'exposure', kind: 'number', min: 0.25, max: 8, step: 0.25, value: 1 },
  ],
  '05-picking': [
    { key: 'sidebar', label: '240 px sidebar', kind: 'flag' },
    { key: 'damping', label: 'damping', kind: 'flag' },
  ],
  '06-tsl': [{ key: 'harmonic', label: 'harmonic', kind: 'number', min: 1, max: 6, step: 1, value: 1 }],
  '07-post': [
    { key: 'pipeline', label: 'pipeline', kind: 'select', options: ['bloom', 'bloom-fxaa', 'direct', 'none'] },
    { key: 'threshold', label: 'bloom threshold', kind: 'number', min: 0, max: 2, step: 0.05, value: 1 },
  ],
  '08-performance': [
    { key: 'mode', label: 'mode', kind: 'select', options: ['meshes', 'unshared', 'instanced', 'tiles', 'batched', 'lod'] },
    { key: 'count', label: 'markers', kind: 'select', options: ['10000', '1000', '100', '40000'] },
    { key: 'view', label: 'view', kind: 'select', options: ['all', 'close'] },
  ],
  '09-r3f': [
    { key: 'frets', label: 'frets', kind: 'select', options: ['shared', 'inline'] },
    { key: 'markers', label: 'markers', kind: 'select', options: ['stable', 'literal'] },
    { key: 'text', label: "drei's Text", kind: 'flag' },
  ],
  '10-physics': [{ key: 'build', label: 'Rapier build', kind: 'select', options: ['deterministic', 'standard'] }],
  '13-fretboard': [{ key: 'version', label: 'version', kind: 'select', options: ['port', 'ga'] }],
};

const page = /(\d\d-[^/]*)\.html$/.exec(location.pathname)?.[1] ?? '';
const controls = PANELS[page];
const params = new URLSearchParams(location.search);

// The page again, with one parameter changed: the first option or the default value removes the parameter
function reloadWith(key: string, value: string | null) {
  if (value === null) params.delete(key);
  else params.set(key, value);
  const query = [...params].map(([k, v]) => (v === '' ? k : `${k}=${encodeURIComponent(v)}`)).join('&');
  location.replace(`${location.pathname}${query ? `?${query}` : ''}`);
}

if (controls && !params.has('probe')) {
  const gui = new GUI({ title: 'Try it' });
  for (const control of controls) {
    if (control.kind === 'flag') {
      const present = params.has(control.key) && (control.value === undefined || params.get(control.key) === control.value);
      const state = { value: control.invert ? !present : present };
      gui.add(state, 'value').name(control.label).onChange((checked: boolean) => {
        const on = control.invert ? !checked : checked;
        reloadWith(control.key, on ? (control.value ?? '') : null);
      });
    } else if (control.kind === 'select') {
      const state = { value: params.get(control.key) ?? control.options[0] };
      gui.add(state, 'value', control.options).name(control.label).onChange((value: string) => {
        reloadWith(control.key, value === control.options[0] ? null : value);
      });
    } else {
      const state = { value: Number(params.get(control.key) ?? control.value) };
      gui
        .add(state, 'value', control.min, control.max, control.step)
        .name(control.label)
        .onFinishChange((value: number) => reloadWith(control.key, value === control.value ? null : String(value)));
    }
  }
  gui.add({ reset: () => location.replace(location.pathname) }, 'reset').name('reset');
  // In a narrow frame the panel would cover the scene: start folded
  if (window.innerWidth < 560) gui.close();
}
