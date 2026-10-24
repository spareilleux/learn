import { copyFile, mkdir, readFile, realpath, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const lab = path.dirname(fileURLToPath(import.meta.url));
const checkout = await realpath(path.resolve(lab, '../../..'));
let output;
const commands = [];
const sha256 = data => createHash('sha256').update(data).digest('hex');
const jsonWrite = (name, value) => writeFile(path.join(output, name), JSON.stringify(value, null, 2) + '\n');
try {
  if (process.argv.length !== 3) throw new Error('Usage: node code/streeling/voice-leading/run.mjs NEW_OUTPUT_DIR');
  const requested = path.resolve(process.argv[2]);
  const canonicalOutputParent = await realpath(path.dirname(requested));
  const candidate = path.join(canonicalOutputParent, path.basename(requested));
  const relative = path.relative(checkout.toLowerCase(), candidate.toLowerCase());
  if (!relative || (!relative.startsWith('..' + path.sep) && relative !== '..' && !path.isAbsolute(relative)))
    throw new Error('NEW_OUTPUT_DIR must be outside the checkout');
  await mkdir(candidate);
  output = candidate;
  const project = path.join(output, 'project');
  await mkdir(project);
  const manifest = JSON.parse(await readFile(path.join(lab, 'source.json'), 'utf8'));
  if (manifest.commit !== 'dc2e74cbd992a298f67efb928b5b3754615e1924' || manifest.files.length !== 3)
    throw new Error('Missing or unexpected pinned source manifest');
  const inputPaths = ['run.mjs', 'Probe.cs', 'MetadataAdapter.cs', 'VoiceLeadingProbe.csproj', 'global.json', 'NuGet.Config', 'expected-cases.json', 'source.json', 'README.md', '.gitattributes', ...manifest.files.map(f => f.localPath)];
  const inputHashes = {};
  for (const name of inputPaths) {
    const bytes = await readFile(path.join(lab, name));
    const destination = path.join(project, name);
    await mkdir(path.dirname(destination), { recursive: true });
    await copyFile(path.join(lab, name), destination);
    inputHashes[name] = sha256(bytes);
    if (sha256(await readFile(destination)) !== inputHashes[name]) throw new Error(`Copy hash mismatch: ${name}`);
  }
  for (const file of manifest.files) {
    if (inputHashes[file.localPath] !== file.sha256) throw new Error(`Pinned source hash mismatch: ${file.localPath}`);
  }
  const env = { ...process.env,
    DOTNET_CLI_HOME: path.join(output, '.dotnet'),
    NUGET_PACKAGES: path.join(output, '.nuget', 'packages'),
    NUGET_HTTP_CACHE_PATH: path.join(output, '.nuget', 'http-cache'),
    NUGET_PLUGINS_CACHE_PATH: path.join(output, '.nuget', 'plugins-cache'),
    DOTNET_SKIP_FIRST_TIME_EXPERIENCE: '1', DOTNET_CLI_TELEMETRY_OPTOUT: '1',
    DOTNET_CLI_WORKLOAD_UPDATE_NOTIFY_DISABLE: 'true', MSBUILDDISABLENODEREUSE: '1',
    TEMP: path.join(output, 'tmp'), TMP: path.join(output, 'tmp')
  };
  await mkdir(env.TEMP);
  const execute = async (id, executable, args) => {
    const startedAt = new Date().toISOString();
    const child = spawnSync(executable, args, { cwd: project, env, encoding: 'utf8', windowsHide: true, maxBuffer: 16 * 1024 * 1024 });
    const record = { id, executable, args, cwd: project, startedAt, finishedAt: new Date().toISOString(), exitCode: child.status, signal: child.signal, error: child.error?.message ?? null, stdout: child.stdout ?? '', stderr: child.stderr ?? '' };
    commands.push(record);
    await writeFile(path.join(output, `${id}.stdout.txt`), record.stdout);
    await writeFile(path.join(output, `${id}.stderr.txt`), record.stderr);
    await jsonWrite('commands.json', commands);
    if (child.status !== 0 || child.error) throw new Error(`${id} failed (exit ${child.status}): ${record.error ?? record.stderr}`);
    return record.stdout;
  };
  const sdkVersion = (await execute('dotnet-version', 'dotnet', ['--version'])).trim();
  if (sdkVersion !== '10.0.113') throw new Error(`Expected installed SDK 10.0.113; got ${sdkVersion}`);
  await execute('build', 'dotnet', ['build', 'VoiceLeadingProbe.csproj', '--configuration', 'Release', '--configfile', 'NuGet.Config', '--disable-build-servers', '-warnaserror']);
  const stdout = await execute('probe', 'dotnet', [path.join(project, 'bin', 'Release', 'net10.0', 'VoiceLeadingProbe.dll'), path.join(project, 'expected-cases.json')]);
  const probe = JSON.parse(stdout);
  const requiredGates = ['fixed_case_inventory', 'upstream_seven_permutation_count', 'oracle_zero_known_case', 'counterexample_oracle_witness', 'counterexample_cyclic_costs', 'original_equivalence_failure_reproduced', 'normalization_is_exactly_this_example', 'ambiguous_two_minimum_assignments', 'constructed_native_ranking', 'constructed_oracle_ranking', 'mismatched_cardinality_exception'];
  const declared = JSON.parse(await readFile(path.join(project, 'expected-cases.json'), 'utf8'));
  for (const c of declared.cases) requiredGates.push(`${c.id}_native`, `${c.id}_oracle`);
  if (probe.probe_completed !== true || probe.characterization_pass !== true || probe.original_expected_equivalence_satisfied !== false || !Array.isArray(probe.checks) || probe.checks.some(c => c.pass !== true) || requiredGates.some(id => !probe.checks.some(c => c.id === id && c.pass === true)))
    throw new Error('Native characterization missing or failed required checks');
  const results = { ...probe, ORIGINAL_EXPECTED_EQUIVALENCE_SATISFIED: probe.original_expected_equivalence_satisfied,
    provenance: { source: manifest, inputSha256: inputHashes, sdkVersion, nodeVersion: process.version, platform: process.platform, architecture: process.arch, assessedOsScope: 'Windows only', commandRecords: 'commands.json', outputDirectory: output } };
  await jsonWrite('results.json', results);
  console.log(JSON.stringify({ probe_completed: true, characterization_pass: true, ORIGINAL_EXPECTED_EQUIVALENCE_SATISFIED: false, checksPassed: probe.checks.length, results: path.join(output, 'results.json') }, null, 2));
} catch (error) {
  if (output) await jsonWrite('failure.json', { probe_completed: false, characterization_pass: false, error: error.message, commands });
  console.error(error.message);
  process.exitCode = 1;
}
