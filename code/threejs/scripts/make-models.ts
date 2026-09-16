// Lesson 4: writes a small animated glTF model, a metronome, and two compressed copies of it, with glTF Transform.
// The geometry comes from three.js primitives; the arm swings from +25° to −25° and back in one second.
//   public/generated/metronome.glb          no compression
//   public/generated/metronome-draco.glb    KHR_draco_mesh_compression
//   public/generated/metronome-meshopt.glb  EXT_meshopt_compression, with KHR_mesh_quantization
// node scripts/make-models.ts
import { mkdirSync, readFileSync } from 'node:fs';
import { gzipSync } from 'node:zlib';
import { Accessor, Document, NodeIO, type Node } from '@gltf-transform/core';
import { ALL_EXTENSIONS } from '@gltf-transform/extensions';
import { draco, meshopt } from '@gltf-transform/functions';
import draco3d from 'draco3dgltf';
import { MeshoptEncoder } from 'meshoptimizer';
import * as THREE from 'three';

const document = new Document();
const buffer = document.createBuffer();
const scene = document.createScene('metronome');

function material(name: string, color: number, metalness: number, roughness: number) {
  const c = new THREE.Color(color); // sRGB hex to linear, as glTF's baseColorFactor is linear
  return document.createMaterial(name).setBaseColorFactor([c.r, c.g, c.b, 1]).setMetallicFactor(metalness).setRoughnessFactor(roughness);
}

// A three.js BufferGeometry becomes a glTF mesh: one accessor per attribute, plus the indices
function mesh(name: string, geometry: THREE.BufferGeometry, mat: ReturnType<typeof material>) {
  const primitive = document.createPrimitive().setMaterial(mat);
  for (const [three, gltf] of [['position', 'POSITION'], ['normal', 'NORMAL'], ['uv', 'TEXCOORD_0']] as const) {
    const attribute = geometry.getAttribute(three);
    const accessor = document
      .createAccessor(`${name}_${gltf}`)
      .setType(attribute.itemSize === 3 ? Accessor.Type.VEC3 : Accessor.Type.VEC2)
      .setArray(new Float32Array(attribute.array))
      .setBuffer(buffer);
    primitive.setAttribute(gltf, accessor);
  }
  const index = geometry.getIndex()!;
  primitive.setIndices(document.createAccessor(`${name}_indices`).setType(Accessor.Type.SCALAR).setArray(new Uint16Array(index.array)).setBuffer(buffer));
  return document.createMesh(name).addPrimitive(primitive);
}

function node(name: string, geometry: THREE.BufferGeometry, mat: ReturnType<typeof material>, translation: [number, number, number]): Node {
  return document.createNode(name).setMesh(mesh(name, geometry, mat)).setTranslation(translation);
}

const wood = material('walnut', 0x5b3a29, 0, 0.6);
const brass = material('brass', 0xd4a95e, 1, 0.25);

// The body: a tapered box, from a cylinder with four sides turned by 45°
const bodyGeometry = new THREE.CylinderGeometry(0.2, 0.55, 1.6, 4, 1).rotateY(Math.PI / 4).toNonIndexed();
bodyGeometry.computeVertexNormals();
const body = node('body', mergeIndex(bodyGeometry), wood, [0, 0.8, 0]);

// The arm pivots at the bottom: its geometry is moved up so that the node's origin is the pivot
const arm = document.createNode('arm').setTranslation([0, 0.25, 0.36]);
arm.addChild(node('rod', new THREE.BoxGeometry(0.04, 1.3, 0.02).translate(0, 0.65, 0), brass, [0, 0, 0]));
arm.addChild(node('weight', new THREE.SphereGeometry(0.09, 48, 24), brass, [0, 0.95, 0]));

const root = document.createNode('metronome').addChild(body).addChild(arm);
scene.addChild(root);

// One animation, "swing": arm rotation around Z, as quaternions (x, y, z, w), linearly interpolated
const angles = [0, 25, 0, -25, 0];
const times = document.createAccessor('swing_times').setType(Accessor.Type.SCALAR).setArray(new Float32Array([0, 0.25, 0.5, 0.75, 1])).setBuffer(buffer);
const rotations = document
  .createAccessor('swing_rotations')
  .setType(Accessor.Type.VEC4)
  .setArray(new Float32Array(angles.flatMap((deg) => new THREE.Quaternion().setFromAxisAngle(new THREE.Vector3(0, 0, 1), THREE.MathUtils.degToRad(deg)).toArray())))
  .setBuffer(buffer);
const sampler = document.createAnimationSampler().setInput(times).setOutput(rotations).setInterpolation('LINEAR');
const channel = document.createAnimationChannel().setTargetNode(arm).setTargetPath('rotation').setSampler(sampler);
document.createAnimation('swing').addSampler(sampler).addChannel(channel);

// BufferGeometry.toNonIndexed() drops the index; glTF Transform's weld() could restore it, but three.js can do it here
function mergeIndex(geometry: THREE.BufferGeometry) {
  const count = geometry.getAttribute('position').count;
  return geometry.setIndex(Array.from({ length: count }, (_, i) => i));
}

const io = new NodeIO().registerExtensions(ALL_EXTENSIONS).registerDependencies({
  'draco3d.encoder': await draco3d.createEncoderModule(),
  'draco3d.decoder': await draco3d.createDecoderModule(),
  'meshopt.encoder': MeshoptEncoder,
});

mkdirSync('public/generated', { recursive: true });
// The size on disk, and after gzip, as a web server would send it
const size = (path: string) => {
  const bytes = readFileSync(path);
  return `${bytes.length} bytes, ${gzipSync(bytes, { level: 9 }).length} gzipped`;
};

await io.write('public/generated/metronome.glb', document);
console.log('metronome.glb', size('public/generated/metronome.glb'));

const dracoCopy = await io.readBinary(await io.writeBinary(document));
await dracoCopy.transform(draco());
await io.write('public/generated/metronome-draco.glb', dracoCopy);
console.log('metronome-draco.glb', size('public/generated/metronome-draco.glb'));

const meshoptCopy = await io.readBinary(await io.writeBinary(document));
await MeshoptEncoder.ready;
await meshoptCopy.transform(meshopt({ encoder: MeshoptEncoder, level: 'medium' }));
await io.write('public/generated/metronome-meshopt.glb', meshoptCopy);
console.log('metronome-meshopt.glb', size('public/generated/metronome-meshopt.glb'));
