// Lesson 6, exercise 3: GuitarAlchemist's GLSL sky gradient (BSP/Sunburst3D.tsx, lines 450-481) as a TSL colorNode.
// Type-checked by check.sh (l00_tsc); no page renders it.
import * as THREE from 'three/webgpu';
import { color, float, Fn, max, mix, normalize, positionWorld, pow, uniform } from 'three/tsl';

export function createSky() {
  const topColor = uniform(color(0x0077ff));
  const bottomColor = uniform(color(0x000033));
  const offset = uniform(33);
  const exponent = uniform(0.6);

  const material = new THREE.MeshBasicNodeMaterial({ side: THREE.BackSide });
  material.colorNode = Fn(() => {
    // float h = normalize(vWorldPosition + offset).y;
    const h = normalize(positionWorld.add(offset)).y;
    // gl_FragColor = vec4(mix(bottomColor, topColor, max(pow(max(h, 0.0), exponent), 0.0)), 1.0);
    return mix(bottomColor, topColor, max(pow(max(h, float(0)), exponent), 0));
  })();

  const sky = new THREE.Mesh(new THREE.SphereGeometry(500, 32, 32), material);
  return { sky, topColor, bottomColor, offset, exponent };
}
