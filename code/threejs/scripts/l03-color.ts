// Lesson 3: color management and HDR data without a renderer: node scripts/l03-color.ts
import { readFileSync } from 'node:fs';
import * as THREE from 'three';
import { HDRLoader } from 'three/addons/loaders/HDRLoader.js';

const fixed = (values: number[]) => values.map((n) => Number(n.toFixed(4)));

console.log('working color space:', THREE.ColorManagement.workingColorSpace);

// The rosewood of lesson 2, written in hex, as a color picker gives it
const rosewood = new THREE.Color(0x4a2c1d);
console.log('Color(0x4a2c1d) stores', fixed([rosewood.r, rosewood.g, rosewood.b]));
console.log('getHexString()', rosewood.getHexString(), '| getHexString(LinearSRGBColorSpace)', rosewood.getHexString(THREE.LinearSRGBColorSpace));
const halfway = new THREE.Color().setRGB(0.5, 0.5, 0.5);
console.log('setRGB(0.5, 0.5, 0.5).getHexString()', halfway.getHexString());
console.log('setRGB(0.5, 0.5, 0.5, SRGBColorSpace) stores', fixed(new THREE.Color().setRGB(0.5, 0.5, 0.5, THREE.SRGBColorSpace).toArray()));

console.log('new Texture().colorSpace:', JSON.stringify(new THREE.Texture().colorSpace));

// The environment written by make-studio-hdr.ts, parsed as HDRLoader does in the browser
const bytes = readFileSync('public/generated/studio.hdr');
const loader = new HDRLoader();
const parsed = loader.parse(bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength));
if (!parsed?.width || !parsed.data) throw new Error('not an HDR file');
const { width, height, type } = parsed;
const pixels = parsed.data as Uint16Array;
const typeName = (type: number) => Object.entries(THREE).find(([name, value]) => value === type && name.endsWith('Type'))?.[0];
console.log('HDRLoader.parse:', { width, height, type: typeName(type!), values: pixels.constructor.name });
const texel = (x: number, y: number) => {
  const i = (y * width + x) * 4;
  return fixed([...pixels.slice(i, i + 3)].map((half) => THREE.DataUtils.fromHalfFloat(half)));
};
console.log('a wall texel (0, 20):', texel(0, 20), '| a softbox texel (64, 32):', texel(64, 32));
