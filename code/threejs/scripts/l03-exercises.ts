// Lesson 3, exercises 1 and 2: node scripts/l03-exercises.ts
import * as THREE from 'three';

// Exercise 1: bytes read without a color space are linear values, and the output encodes them to sRGB
const bytes = [200, 100, 50];
const [r, g, b] = bytes.map((byte) => byte / 255);
const shown = new THREE.Color().setRGB(r, g, b).getRGB({ r: 0, g: 0, b: 0 }, THREE.SRGBColorSpace);
console.log('bytes', bytes, 'with NoColorSpace are shown as', [shown.r, shown.g, shown.b].map((v) => Math.round(v * 255)));

// Exercise 2: what the shader receives for a CSS gray
console.log("Color('#808080').getHexString(LinearSRGBColorSpace):", new THREE.Color('#808080').getHexString(THREE.LinearSRGBColorSpace));
