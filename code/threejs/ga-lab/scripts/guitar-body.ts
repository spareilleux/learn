// Experiment 10's model: a guitar body built procedurally (no downloaded model, so no license to track), with three
// levels of detail simplified by meshoptimizer, written as one glTF file with glTF Transform:
//   public/generated/guitar-body.glb, meshes "LOD0" (full), "LOD1" (about 25% of the triangles), "LOD2" (about 5%)
//   node scripts/guitar-body.ts
// The outline is a Stratocaster-like double cutaway drawn with Bézier curves, 0.46 m long, extruded 45 mm with a
// rounded bevel; units are meters, as glTF's.
import { mkdirSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { Accessor, Document, NodeIO } from '@gltf-transform/core';
import { MeshoptSimplifier } from 'meshoptimizer';
import * as THREE from 'three';
import { mergeVertices } from 'three/addons/utils/BufferGeometryUtils.js';

const lab = resolve(import.meta.dirname, '..');
const outline = new THREE.Shape();
// Lower bout at the bottom (y < 0), upper bout with two horns at the top, the neck pocket between them
outline.moveTo(0, -0.235);
outline.bezierCurveTo(0.12, -0.235, 0.2, -0.19, 0.2, -0.1);
outline.bezierCurveTo(0.2, -0.02, 0.13, 0.0, 0.14, 0.06);
outline.bezierCurveTo(0.15, 0.12, 0.17, 0.2, 0.13, 0.225);
outline.bezierCurveTo(0.1, 0.24, 0.07, 0.17, 0.03, 0.15);
outline.lineTo(-0.03, 0.15);
outline.bezierCurveTo(-0.08, 0.2, -0.12, 0.235, -0.15, 0.2);
outline.bezierCurveTo(-0.17, 0.17, -0.13, 0.08, -0.14, 0.04);
outline.bezierCurveTo(-0.15, 0.0, -0.2, -0.03, -0.2, -0.1);
outline.bezierCurveTo(-0.2, -0.19, -0.12, -0.235, 0, -0.235);

const extruded = new THREE.ExtrudeGeometry(outline, { depth: 0.035, bevelEnabled: true, bevelThickness: 0.005, bevelSize: 0.006, bevelSegments: 6, curveSegments: 64 });
extruded.center();
// Welded vertices, so the simplifier sees one surface; normals recomputed per level
const full = mergeVertices(extruded.deleteAttribute('uv').deleteAttribute('normal'), 1e-6);
full.computeVertexNormals();

await MeshoptSimplifier.ready;
const positions = new Float32Array(full.getAttribute('position').array);
const indices = new Uint32Array(full.getIndex()!.array);
function level(ratio: number): { index: Uint32Array; error: number } {
  if (ratio === 1) return { index: indices, error: 0 };
  const target = Math.floor((indices.length * ratio) / 3) * 3;
  const [index, error] = MeshoptSimplifier.simplify(indices, positions, 3, target, 0.05, ['LockBorder']);
  return { index, error };
}

const document = new Document();
const buffer = document.createBuffer();
const scene = document.createScene('guitar body');
const material = document.createMaterial('sunburst').setBaseColorFactor([0.42, 0.12, 0.04, 1]).setMetallicFactor(0).setRoughnessFactor(0.35);
const position = document.createAccessor('POSITION').setType(Accessor.Type.VEC3).setArray(positions).setBuffer(buffer);
const normal = document.createAccessor('NORMAL').setType(Accessor.Type.VEC3).setArray(new Float32Array(full.getAttribute('normal').array)).setBuffer(buffer);
const report: Record<string, { triangles: number; error: number }> = {};
for (const [name, ratio] of [['LOD0', 1], ['LOD1', 0.25], ['LOD2', 0.05]] as const) {
  const { index, error } = level(ratio);
  const primitive = document
    .createPrimitive()
    .setMaterial(material)
    .setAttribute('POSITION', position)
    .setAttribute('NORMAL', normal)
    .setIndices(document.createAccessor(`${name}_indices`).setType(Accessor.Type.SCALAR).setArray(new Uint32Array(index)).setBuffer(buffer));
  scene.addChild(document.createNode(name).setMesh(document.createMesh(name).addPrimitive(primitive)));
  report[name] = { triangles: index.length / 3, error: Math.round(error * 10000) / 10000 };
}
mkdirSync(join(lab, 'public', 'generated'), { recursive: true });
await new NodeIO().write(join(lab, 'public', 'generated', 'guitar-body.glb'), document);
console.log(JSON.stringify({ vertices: positions.length / 3, levels: report }, null, 2));
