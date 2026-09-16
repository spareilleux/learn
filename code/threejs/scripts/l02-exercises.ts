// Lesson 2, exercises 1 and 2: node scripts/l02-exercises.ts
import * as THREE from 'three';

// Exercise 1: a small sphere, to count by hand
const sphere = new THREE.SphereGeometry(1, 8, 4);
console.log('SphereGeometry(1, 8, 4):', { vertices: sphere.getAttribute('position').count, triangles: sphere.index!.count / 3 });

// Exercise 2: the same 800 lumens from a spot light
const spot = new THREE.SpotLight(0xffffff);
spot.power = 800;
console.log('SpotLight with power 800 lm:', { intensity: Number(spot.intensity.toFixed(2)), angle: Number(spot.angle.toFixed(4)) });
spot.angle = Math.PI / 12;
console.log('after angle = π/12:', { intensity: Number(spot.intensity.toFixed(2)), power: Number(spot.power.toFixed(2)) });
