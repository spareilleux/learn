// solutions/l03_ex2_camera.ts
interface CameraState {
  px: number;
  py: number;
  pz: number;
  lx: number;
  ly: number;
  lz: number;
}
const keys = ['px', 'py', 'pz', 'lx', 'ly', 'lz'] as const;

function isCameraState(value: unknown): value is CameraState {
  if (typeof value !== 'object' || value === null) return false;
  const record: { [key: string]: unknown } = { ...value };
  return keys.every((key) => typeof record[key] === 'number' && Number.isFinite(record[key]));
}

// undefined when nothing usable is saved: the caller keeps its default camera
function restoreCamera(saved: string | null): CameraState | undefined {
  if (saved === null) return undefined;
  try {
    const value: unknown = JSON.parse(saved);
    return isCameraState(value) ? value : undefined;
  } catch {
    return undefined; // not JSON at all
  }
}

const good = JSON.stringify({ px: 0, py: 50, pz: 300, lx: 0, ly: 0, lz: 0 });
console.log(restoreCamera(good));
console.log(restoreCamera(null), restoreCamera('{'), restoreCamera('{}'));
console.log(restoreCamera('{"px":0,"py":0,"pz":"300","lx":0,"ly":0,"lz":0}'));
