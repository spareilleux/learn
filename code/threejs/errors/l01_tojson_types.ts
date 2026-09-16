// What tsc says about the JSON of a scene, with @types/three 0.186.0
import * as THREE from 'three';

const scene = new THREE.Scene();
scene.add(new THREE.Mesh(new THREE.BoxGeometry(), new THREE.MeshBasicMaterial()));
const json = scene.toJSON();
console.log(json.geometries?.length);
console.log(json.object.children?.map((child) => child.type));
