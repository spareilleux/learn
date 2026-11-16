import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { copyFileSync, existsSync, mkdirSync, readFileSync, realpathSync, writeFileSync } from 'node:fs';
import { delimiter, dirname, isAbsolute, join, relative, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const source = dirname(fileURLToPath(import.meta.url));
const [outputArg, evaluatorArg, specArg, variant = 'global-parity'] = process.argv.slice(2);
if (!outputArg || !evaluatorArg || !specArg || process.argv.length > 6) {
  console.error('Usage: node run.mjs NEW_OUTPUT_DIR EXTERNAL_EVALUATOR.py EXTERNAL_SPEC.json [global-parity|restarted-tile-parity]');
  process.exit(2);
}
const output = resolve(outputArg);
let repository = source;
while (!existsSync(join(repository, '.git')) && dirname(repository) !== repository) repository = dirname(repository);
const fromRepository = relative(repository, output);
if (existsSync(join(repository, '.git')) && (fromRepository === '' || (!fromRepository.startsWith(`..${sep}`) && fromRepository !== '..' && !isAbsolute(fromRepository)))) {
  console.error('Output must be outside this source checkout so generated project files and caches stay outside Git.');
  process.exit(2);
}
if (existsSync(output)) {
  console.error(`Output must be a new directory: ${output}`);
  process.exit(2);
}
mkdirSync(output, { recursive: true });
const report = { status: 'failed', checks: [], platform: process.platform, selected_variant: variant };
const writeJSON = (name, value) => writeFileSync(join(output, name), JSON.stringify(value, null, 2) + '\n');
const hash = path => createHash('sha256').update(readFileSync(path)).digest('hex');
function check(name, passed, detail) {
  report.checks.push({ name, passed, detail });
  if (!passed) throw new Error(`${name}: ${detail}`);
}
try {
  const evaluator = resolve(evaluatorArg);
  const specPath = resolve(specArg);
  report.sources = {
    evaluator: { path: evaluator, sha256: hash(evaluator) },
    spec: { path: specPath, sha256: hash(specPath) },
    teaching_files: Object.fromEntries(['run.mjs', 'trial.gd', 'project.godot', 'expected-cases.json'].map(name => [name, hash(join(source, name))])),
    evaluator_provenance: 'Demerzel f23ccae6c049d9066a1be2221c68f3b0bcf48373 (caller-supplied file; hashes identify the actual input)'
  };
  const python = process.platform === 'win32' ? 'python' : 'python3';
  const semantic = spawnSync(python, [evaluator, '--input', specPath], { encoding: 'utf8', timeout: 30000 });
  writeFileSync(join(output, 'semantic.stdout.log'), semantic.stdout ?? '');
  writeFileSync(join(output, 'semantic.stderr.log'), semantic.stderr ?? '');
  check('semantic_execution', semantic.status === 0 && !semantic.error, semantic.error?.message ?? `exit ${semantic.status}`);
  const evaluation = JSON.parse(semantic.stdout);
  writeJSON('semantic-report.json', evaluation);
  check('semantic_baselines', evaluation.variants?.['global-parity']?.adjacency_violations === 0 && evaluation.variants?.['restarted-tile-parity']?.adjacency_violations === 12, 'Expected global 0 and restarted 12 adjacency violations');
  check('semantic_admission', evaluation.variants?.[variant]?.adjacency_violations === 0, `Selected ${variant}: ${evaluation.variants?.[variant]?.adjacency_violations} adjacency violations`);
  const spec = JSON.parse(readFileSync(specPath, 'utf8'));
  check('fixed_fixture', spec.sample_id === 'odd-tile-seam-a' && spec.base_warp === 3 && spec.base_weft === 3 && spec.warp_tiles === 2 && spec.weft_tiles === 2 && spec.phase === 0 && spec.spacing_mm === 5 && spec.diameter_mm === 2 && evaluation.warp_count === 6 && evaluation.weft_count === 6, 'This teaching adapter supports only the recorded 6 by 6, phase 0, 5 mm pitch, 2 mm fixture');
  const manifest = {
    kind: 'streeling-weave-teaching-data',
    sample_id: spec.sample_id,
    variant,
    source_spec_sha256: report.sources.spec.sha256,
    source_evaluator_sha256: report.sources.evaluator.sha256,
    spacing_mm: spec.spacing_mm,
    diameter_mm: spec.diameter_mm,
    crossings: Array.from({ length: 36 }, (_, index) => {
      const x = index % 6;
      const y = Math.floor(index / 6);
      return { id: `w${x}-f${y}`, grid_x: x, grid_y: y, x_mm: x * spec.spacing_mm, z_mm: y * spec.spacing_mm, warp_over: (x + y + spec.phase) % 2 === 0 };
    })
  };
  writeJSON('crossings.json', manifest);
  report.manifest_sha256 = hash(join(output, 'crossings.json'));
  const project = join(output, 'project');
  mkdirSync(project);
  for (const name of ['project.godot', 'trial.gd']) copyFileSync(join(source, name), join(project, name));
  let godot = 'godot';
  if (process.platform === 'win32') {
    const executable = (process.env.PATH ?? '').split(delimiter)
      .map(directory => join(directory, 'godot.exe')).find(path => existsSync(path));
    if (!executable) throw new Error('Godot executable godot.exe was not found on PATH');
    godot = realpathSync(executable);
  }
  const godotArgs = ['--headless', '--path', project, '--script', 'res://trial.gd', '--', '--manifest', join(output, 'crossings.json'), '--report', join(output, 'godot-report.json'), '--manifest-sha256', report.manifest_sha256];
  report.godot_command = [godot, ...godotArgs];
  const native = spawnSync(godot, godotArgs, { encoding: 'utf8', timeout: 60000 });
  writeFileSync(join(output, 'godot.stdout.log'), native.stdout ?? '');
  writeFileSync(join(output, 'godot.stderr.log'), native.stderr ?? '');
  check('godot_execution', native.status === 0 && !native.error, native.error?.message ?? `exit ${native.status}; see Godot logs and report`);
  const result = JSON.parse(readFileSync(join(output, 'godot-report.json'), 'utf8'));
  check('loaded_scene_roundtrip', result.status === 'passed', 'Godot report must explicitly pass all scene checks');
  report.status = 'passed';
} catch (error) {
  report.error = String(error.message ?? error);
} finally {
  writeJSON('run-report.json', report);
  console.log(JSON.stringify({ status: report.status, report: join(output, 'run-report.json'), error: report.error }));
  process.exitCode = report.status === 'passed' ? 0 : 1;
}
