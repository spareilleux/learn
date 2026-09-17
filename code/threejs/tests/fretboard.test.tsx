// Lesson 12: tests of lesson 9's <Fretboard> without a browser or a GPU. @react-three/test-renderer runs React Three
// Fiber's reconciler in Node.js: the scene graph is built, props and events work, nothing is drawn.
// check.sh runs them with: npx vitest run
import ReactThreeTestRenderer from '@react-three/test-renderer';
import * as THREE from 'three';
import { afterEach, describe, expect, test, vi } from 'vitest';
import { pressPoint } from '../src/05-picking/fretboard.ts';
import { counters, Fretboard, type Marker, type Pick } from '../src/09-r3f/Fretboard.tsx';

// Tells React that this is a test that wraps updates in act(): without it, React warns on every update, and R3F disposes
// removed objects later, at idle priority, instead of right away
declare global {
  var IS_REACT_ACT_ENVIRONMENT: boolean;
}
globalThis.IS_REACT_ACT_ENVIRONMENT = true;

const C_MAJOR: Marker[] = [
  { string: 5, fret: 3 },
  { string: 4, fret: 2 },
  { string: 2, fret: 1 },
];

afterEach(() => {
  counters.fretboardRenders = 0;
  counters.markerBuilds = 0;
  vi.restoreAllMocks();
});

describe('Fretboard', () => {
  test('has a neck, 12 frets and 6 strings', async () => {
    const renderer = await ReactThreeTestRenderer.create(<Fretboard />);
    const names = renderer.scene.findAll((node) => node.type === 'Mesh').map((node) => node.props.name as string);
    expect(names.filter((name) => name.startsWith('fret '))).toHaveLength(12);
    expect(names.filter((name) => name.startsWith('string '))).toHaveLength(6);
    expect(names).toContain('neck');
    await renderer.unmount();
  });

  test('shares one geometry between the frets, unless they are written inline', async () => {
    for (const [frets, expected] of [['shared', 1], ['inline', 12]] as const) {
      const renderer = await ReactThreeTestRenderer.create(<Fretboard frets={frets} />);
      const geometries = new Set(
        renderer.scene.findAll((node) => node.type === 'Mesh' && String(node.props.name).startsWith('fret ')).map((node) => (node.instance as THREE.Mesh).geometry),
      );
      expect(geometries.size).toBe(expected);
      await renderer.unmount();
    }
  });

  test('computes the markers once for the same array, and on every render for a new one', async () => {
    const renderer = await ReactThreeTestRenderer.create(<Fretboard markers={C_MAJOR} />);
    for (let i = 0; i < 5; i++) await renderer.update(<Fretboard markers={C_MAJOR} />);
    expect(counters.markerBuilds).toBe(1);
    for (let i = 0; i < 5; i++) await renderer.update(<Fretboard markers={[...C_MAJOR]} />);
    expect(counters.markerBuilds).toBe(6);
    expect(renderer.scene.findAll((node) => node.props.name === 'marker')).toHaveLength(3);
    await renderer.unmount();
  });

  test('reports the note under the pointer', async () => {
    const picks: Pick[] = [];
    const renderer = await ReactThreeTestRenderer.create(<Fretboard onPick={(pick) => picks.push(pick)} />);
    const group = renderer.scene.find((node) => node.props.name === 'fretboard');
    // No raycaster runs here: the test supplies the intersection point that R3F would have computed
    await renderer.fireEvent(group, 'onPointerMove', { point: pressPoint(3, 5), stopPropagation: () => {} });
    expect(picks).toEqual([{ fret: 5, string: 3, note: 'C4' }]);
    expect(renderer.scene.findAll((node) => node.props.name === 'hover')).toHaveLength(1);
    await renderer.unmount();
  });

  test('disposes the geometries it created on unmount, including the shared one', async () => {
    const dispose = vi.spyOn(THREE.BufferGeometry.prototype, 'dispose');
    const renderer = await ReactThreeTestRenderer.create(<Fretboard />);
    await renderer.unmount();
    // R3F disposes the <boxGeometry> and the 6 <cylinderGeometry> of the strings, the effect the shared fret geometry
    expect(dispose.mock.calls.length).toBe(8);
  });
});
