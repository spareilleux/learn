// Lesson 1, exercise 2: a parent's scale and rotation apply to its children: node scripts/l01-exercises.ts
import * as THREE from 'three';

const guitar = new THREE.Group();
guitar.position.set(2, 0, 0);
guitar.rotation.y = Math.PI / 2;
guitar.scale.setScalar(2);
const peg = new THREE.Object3D();
peg.position.set(1, 0, 0);
guitar.add(peg);

const world = peg.getWorldPosition(new THREE.Vector3()).toArray().map((n) => Number(n.toFixed(3)) + 0);
console.log('peg in world space, guitar scaled by 2:', world);

// Moving the peg to world (0, 0, 0) without changing its parent: worldToLocal() inverts matrixWorld
const local = guitar.worldToLocal(new THREE.Vector3(0, 0, 0)).toArray().map((n) => Number(n.toFixed(3)) + 0);
console.log('world (0, 0, 0) in the guitar\'s local space:', local);
