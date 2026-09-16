// Lesson 2: what a primitive geometry contains, and the defaults of the physically based materials: node scripts/l02-geometries.ts
import * as THREE from 'three';

const geometries: Record<string, THREE.BufferGeometry> = {
  'BoxGeometry(1, 1, 1)': new THREE.BoxGeometry(1, 1, 1),
  'PlaneGeometry(8, 8)': new THREE.PlaneGeometry(8, 8),
  'CircleGeometry(0.06, 32)': new THREE.CircleGeometry(0.06, 32),
  'CylinderGeometry(0.012, 0.012, 0.55, 12)': new THREE.CylinderGeometry(0.012, 0.012, 0.55, 12),
  'SphereGeometry(1, 32, 16)': new THREE.SphereGeometry(1, 32, 16),
};

for (const [name, geometry] of Object.entries(geometries)) {
  const attributes = Object.entries(geometry.attributes).map(([key, a]) => `${key} ${a.count}×${a.itemSize}`);
  const index = geometry.index?.count ?? 0;
  console.log(`${name.padEnd(42)} ${attributes.join(', ')}; index ${index}; triangles ${index / 3}; groups ${geometry.groups.length}`);
}

// A cube's corner is shared by three faces with three different normals: 8 corners, 24 vertices
const box = geometries['BoxGeometry(1, 1, 1)'];
const normals = box.getAttribute('normal');
const corner: string[] = [];
const position = box.getAttribute('position');
for (let i = 0; i < position.count; i++) {
  if (position.getX(i) === 0.5 && position.getY(i) === 0.5 && position.getZ(i) === 0.5) {
    corner.push(`(${normals.getX(i)}, ${normals.getY(i)}, ${normals.getZ(i)})`);
  }
}
console.log('normals at the corner (0.5, 0.5, 0.5):', corner.join(' '));

const standard = new THREE.MeshStandardMaterial();
const physical = new THREE.MeshPhysicalMaterial();
console.log('MeshStandardMaterial:', { color: standard.color.getHexString(), roughness: standard.roughness, metalness: standard.metalness });
console.log('MeshPhysicalMaterial:', { ior: physical.ior, reflectivity: Number(physical.reflectivity.toFixed(4)), clearcoat: physical.clearcoat, transmission: physical.transmission });

// Physical light units: a point light's intensity is in candela, its power in lumens
const bulb = new THREE.PointLight(0xffffff, 1);
bulb.power = 800;
console.log('PointLight with power 800 lm:', { intensity: Number(bulb.intensity.toFixed(2)), decay: bulb.decay, distance: bulb.distance });
