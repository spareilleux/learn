// The experiment. Reads the dataset, splits it three ways, trains four small models on the CPU, scores them
// against GA's hand-written cost and against two trivial baselines, and writes everything to a JSON file.
//
//   node scripts/train.mjs --data G:/learn-lab/ga-protos/p7/sample.jsonl --out results/measurements.json
//   node scripts/train.mjs --data out/synthetic.jsonl --out out/ci-measurements.json --budget ci
//
// No GPU anywhere: the whole point of P7 is what a laptop processor can do in a few minutes.

import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname } from 'node:path';
import { features, FEATURE_NAMES } from '../src/lib/features.mjs';
import { parseDiagram, chartName } from '../src/lib/voicing.mjs';
import { bestFingering } from '../src/lib/fingering.mjs';
import { splitRows, SPLIT_MODES } from '../src/lib/split.mjs';
import { fitRidge, fitMean, fitSingleFeature } from '../src/lib/linear.mjs';
import { buildBins, fitRandomForest, fitGradientBoosting } from '../src/lib/trees.mjs';
import { fitMlp } from '../src/lib/mlp.mjs';
import { mulberry32, shuffle } from '../src/lib/random.mjs';
import {
  spearman,
  kendallTauB,
  affineFit,
  mae,
  pairwiseAccuracy,
  tieRate,
  bootstrapCI,
  ranks,
  round,
} from '../src/lib/metrics.mjs';

function arg(name, fallback = null) {
  const i = process.argv.indexOf(`--${name}`);
  return i === -1 ? fallback : process.argv[i + 1];
}

const dataPath = arg('data');
const outPath = arg('out', 'results/measurements.json');
const budget = arg('budget', 'full');
const seed = Number(arg('seed', '20260917'));
if (!dataPath) {
  console.error('usage: train.mjs --data <file.jsonl> --out <file.json> [--budget ci|full]');
  process.exit(2);
}

const CONFIG =
  budget === 'ci'
    ? { forest: { trees: 20, maxDepth: 8, minLeaf: 5, mtry: 7 }, boosting: { rounds: 60, maxDepth: 4, minLeaf: 10, learningRate: 0.12 }, mlp: { hidden: 16, epochs: 20, batch: 64 }, bootstrap: 40, pairs: 4000 }
    : { forest: { trees: 60, maxDepth: 12, minLeaf: 5, mtry: 7 }, boosting: { rounds: 300, maxDepth: 5, minLeaf: 20, learningRate: 0.08 }, mlp: { hidden: 32, epochs: 60, batch: 128 }, bootstrap: 200, pairs: 20000 };

mkdirSync(dirname(outPath), { recursive: true });
const started = Date.now();
let allRows = readFileSync(dataPath, 'utf8')
  .split('\n')
  .filter((line) => line.length > 1)
  .map((line) => JSON.parse(line));
const sample = Number(arg('sample', '0'));
if (sample > 0 && sample < allRows.length) allRows = shuffle([...allRows], mulberry32(seed)).slice(0, sample);

// The main task is a ranking task, and a voicing nobody can finger has no rank: those rows are set aside here
// and answered on their own, further down, as a question of their own.
const rows = allRows.filter((r) => r.f === 1);
console.log(`${allRows.length} voicings from ${dataPath}, ${rows.length} of them with a legal fingering`);

const X = rows.map((r) => features(parseDiagram(r.d)));
const y = Float64Array.from(rows, (r) => r.t);
const gaPred = Float64Array.from(rows, (r) => r.g);
const rulePred = Float64Array.from(rows, (r) => r.r);
const spanColumn = FEATURE_NAMES.indexOf('physicalSpanMm');

const take = (indices, source) => indices.map((i) => source[i]);
const takeY = (indices) => Float64Array.from(indices, (i) => y[i]);

function scorePredictor(name, predTest, testIdx, trainIdx, { trainMs = 0, sizeBytes = 0, extra = {} } = {}) {
  const yTest = takeY(testIdx);
  const chordGroups = testIdx.map((i) => rows[i].c);
  // MAE is only comparable after each predictor is put on the target's scale, fitted on the training rows only
  const predTrain = extra.predTrain;
  const { a, b } = predTrain ? affineFit(predTrain, takeY(trainIdx)) : { a: 1, b: 0 };
  const calibrated = Float64Array.from(predTest, (v) => a * v + b);
  const rho = spearman([...predTest], [...yTest]);
  const pairwise = pairwiseAccuracy(predTest, yTest, chordGroups, { pairs: CONFIG.pairs, seed: 7 });
  const ci = bootstrapCI(
    (idx) => spearman(idx.map((k) => predTest[k]), idx.map((k) => yTest[k])),
    chordGroups,
    { rounds: CONFIG.bootstrap, seed: 23 },
  );
  const ciPairs = bootstrapCI(
    (idx) =>
      pairwiseAccuracy(
        idx.map((k) => predTest[k]),
        idx.map((k) => yTest[k]),
        idx.map((k) => chordGroups[k]),
        { pairs: Math.min(CONFIG.pairs, 4000), seed: 31 },
      ).accuracy,
    chordGroups,
    { rounds: Math.min(CONFIG.bootstrap, 60), seed: 29 },
  );
  return {
    name,
    spearman: round(rho),
    spearmanCI: [round(ci.lo), round(ci.hi)],
    kendall: round(kendallTauB([...predTest], [...yTest])),
    mae: round(mae(calibrated, yTest), 4),
    calibration: { a: round(a), b: round(b) },
    pairwise: round(pairwise.accuracy),
    pairwiseCI: [round(ciPairs.lo), round(ciPairs.hi)],
    pairwisePairs: pairwise.pairs,
    withinChordTieRate: round(tieRate(predTest, chordGroups, { pairs: Math.min(CONFIG.pairs, 20000) }).rate),
    trainMs: Math.round(trainMs),
    sizeBytes,
    ...extra.report,
  };
}

const results = {
  dataset: { path: dataPath, rows: rows.length, allRows: allRows.length, budget, seed, sample },
  splits: {},
  node: process.version,
  platform: `${process.platform}-${process.arch}`,
};
results.dataset.chords = new Set(rows.map((r) => r.c)).size;
results.dataset.shapes = new Set(rows.map((r) => r.s)).size;
results.dataset.infeasible = allRows.filter((r) => r.f === 0).length;
results.dataset.infeasibleShare = round(results.dataset.infeasible / allRows.length);

// How the three hand-written signals agree with each other, over the whole dataset
results.agreement = {
  targetVsGa: round(spearman([...y], [...gaPred])),
  targetVsRules: round(spearman([...y], [...rulePred])),
  gaVsRules: round(spearman([...gaPred], [...rulePred])),
  gaWithinChordTieRate: round(tieRate(gaPred, rows.map((r) => r.c), { pairs: 20000 }).rate),
  targetWithinChordTieRate: round(tieRate(y, rows.map((r) => r.c), { pairs: 20000 }).rate),
};

let published = null;
for (const mode of SPLIT_MODES) {
  const split = splitRows(rows, mode, { seed });
  const { train, val, test } = split;
  console.log(`\nsplit by ${mode}: ${train.length} train / ${val.length} val / ${test.length} test, ${split.groupCount} groups`);
  const Xtrain = take(train, X);
  const ytrain = takeY(train);
  const Xval = take(val, X);
  const yval = takeY(val);
  const Xtest = take(test, X);

  const entry = { mode, groups: split.groupCount, train: train.length, val: val.length, test: test.length, models: [] };

  // Two references that are not trained at all
  entry.models.push(
    scorePredictor('ga-hand-written', Float64Array.from(test, (i) => gaPred[i]), test, train, {
      extra: { predTrain: Float64Array.from(train, (i) => gaPred[i]) },
    }),
  );
  entry.models.push(
    scorePredictor('rule-checklist', Float64Array.from(test, (i) => rulePred[i]), test, train, {
      extra: { predTrain: Float64Array.from(train, (i) => rulePred[i]) },
    }),
  );

  const fitAndScore = (name, fit, report = {}) => {
    const t0 = Date.now();
    const model = fit();
    const trainMs = Date.now() - t0;
    const predTest = Float64Array.from(Xtest, (row) => model.predict(row));
    const predTrain = Float64Array.from(Xtrain, (row) => model.predict(row));
    const scored = scorePredictor(name, predTest, test, train, {
      trainMs,
      sizeBytes: model.size(),
      extra: { predTrain, report },
    });
    entry.models.push(scored);
    console.log(`  ${name}: spearman ${scored.spearman}, pairwise ${scored.pairwise}, ${trainMs} ms, ${scored.sizeBytes} B`);
    return { model, predTest };
  };

  fitAndScore('baseline-mean', () => fitMean(Xtrain, ytrain));
  fitAndScore('baseline-span-only', () => fitSingleFeature(Xtrain, ytrain, spanColumn), { feature: FEATURE_NAMES[spanColumn] });

  // Ridge: the regularisation strength is chosen on the validation rows, never on the test rows
  let bestLambda = 1;
  let bestVal = -Infinity;
  for (const lambda of [0.1, 1, 10, 100]) {
    const m = fitRidge(Xtrain, ytrain, lambda);
    const v = spearman(Xval.map((row) => m.predict(row)), [...yval]);
    if (v > bestVal) {
      bestVal = v;
      bestLambda = lambda;
    }
  }
  fitAndScore('ridge', () => fitRidge(Xtrain, ytrain, bestLambda), { lambda: bestLambda });

  const bins = buildBins(Xtrain);
  fitAndScore('random-forest', () => fitRandomForest(Xtrain, ytrain, { ...CONFIG.forest, seed: seed + 1, bins }), {
    hyper: CONFIG.forest,
  });

  // Boosting: the number of rounds is chosen on the validation rows out of a small ladder
  const boosted = fitGradientBoosting(Xtrain, ytrain, { ...CONFIG.boosting, seed: seed + 2, bins });
  const ladder = [Math.round(CONFIG.boosting.rounds / 4), Math.round(CONFIG.boosting.rounds / 2), CONFIG.boosting.rounds];
  let bestRounds = CONFIG.boosting.rounds;
  let bestScore = -Infinity;
  for (const r of ladder) {
    const trimmed = { ...boosted, trees: boosted.trees.slice(0, r) };
    const predict = (row) => {
      let s = boosted.base;
      for (const t of trimmed.trees) {
        let n = t;
        while (n.feature !== undefined) n = row[n.feature] < n.threshold ? n.left : n.right;
        s += boosted.learningRate * n.value;
      }
      return s;
    };
    const v = spearman(Xval.map(predict), [...yval]);
    if (v > bestScore) {
      bestScore = v;
      bestRounds = r;
    }
  }
  const gbt = fitAndScore(
    'gradient-boosting',
    () => fitGradientBoosting(Xtrain, ytrain, { ...CONFIG.boosting, rounds: bestRounds, seed: seed + 2, bins }),
    { hyper: { ...CONFIG.boosting, rounds: bestRounds } },
  );

  fitAndScore('mlp', () => fitMlp(Xtrain, ytrain, { ...CONFIG.mlp, seed: seed + 3 }), { hyper: CONFIG.mlp });

  if (mode === 'chord') {
    // What the boosted trees looked at, as a share of the squared-error gain they collected
    const total = Object.values(gbt.model.importance).reduce((a, b) => a + b, 0);
    entry.importance = Object.entries(gbt.model.importance)
      .map(([j, gain]) => ({ feature: FEATURE_NAMES[Number(j)], share: round(gain / total) }))
      .sort((a, b) => b.share - a.share);

    // Where the model and GA disagree most, by rank, on the test rows
    const yTest = takeY(test);
    const rModel = ranks([...gbt.predTest]);
    const rGa = ranks(test.map((i) => gaPred[i]));
    const rTarget = ranks([...yTest]);
    const n = test.length;
    const disagreements = test
      .map((rowIndex, k) => ({
        diagram: rows[rowIndex].d,
        chart: chartName(parseDiagram(rows[rowIndex].d)),
        quality: rows[rowIndex].q,
        target: round(yTest[k], 3),
        ga: round(gaPred[rowIndex], 3),
        model: round(gbt.predTest[k], 3),
        modelPercentile: round(rModel[k] / n, 3),
        gaPercentile: round(rGa[k] / n, 3),
        targetPercentile: round(rTarget[k] / n, 3),
        gap: round((rModel[k] - rGa[k]) / n, 3),
      }))
      .sort((a, b) => Math.abs(b.gap) - Math.abs(a.gap));
    entry.disagreements = {
      gaHarderModelEasier: disagreements.filter((d) => d.gap < 0).slice(0, 10),
      gaEasierModelHarder: disagreements.filter((d) => d.gap > 0).slice(0, 10),
    };
  }

  if (mode === 'chord') published = gbt.model;
  results.splits[mode] = entry;
}

// What the prototype is for: the search is the expensive thing, the model is the cheap thing. Same voicings,
// same process, one after the other.
{
  const probe = rows.slice(0, Math.min(rows.length, 2000)).map((r) => parseDiagram(r.d));
  const t0 = process.hrtime.bigint();
  for (const frets of probe) bestFingering(frets);
  const searchMs = Number(process.hrtime.bigint() - t0) / 1e6;
  const t1 = process.hrtime.bigint();
  for (const frets of probe) published.predict(features(frets));
  const modelMs = Number(process.hrtime.bigint() - t1) / 1e6;
  results.speed = {
    voicings: probe.length,
    searchMsPerVoicing: round(searchMs / probe.length, 5),
    modelMsPerVoicing: round(modelMs / probe.length, 5),
    speedup: round(searchMs / modelMs, 2),
  };
  console.log(`\nspeed: search ${results.speed.searchMsPerVoicing} ms, model ${results.speed.modelMsPerVoicing} ms per voicing (x${results.speed.speedup})`);
}

// A second question, on the rows the ranking task had to set aside: can the same kind of model tell, from the
// diagram alone, that a voicing has no legal fingering at all? GA's score cannot: it has no "impossible" branch.
// Read as a ranking, pairwise accuracy across chords is the area under the ROC curve.
{
  const Xall = allRows.map((r) => features(parseDiagram(r.d)));
  const yall = Float64Array.from(allRows, (r) => (r.f === 0 ? 1 : 0));
  const split = splitRows(allRows, 'chord', { seed });
  const Xtrain = split.train.map((i) => Xall[i]);
  const ytrain = Float64Array.from(split.train, (i) => yall[i]);
  const Xtest = split.test.map((i) => Xall[i]);
  const ytest = Float64Array.from(split.test, (i) => yall[i]);
  const groups = split.test.map((i) => allRows[i].c);
  const t0 = Date.now();
  const model = fitGradientBoosting(Xtrain, ytrain, { ...CONFIG.boosting, seed: seed + 5 });
  const trainMs = Date.now() - t0;
  const pred = Float64Array.from(Xtest, (row) => model.predict(row));
  const gaOnTest = Float64Array.from(split.test, (i) => allRows[i].g);
  const majority = ytrain.reduce((a, b) => a + b, 0) / ytrain.length > 0.5 ? 1 : 0;
  let right = 0;
  for (let i = 0; i < pred.length; i++) if ((pred[i] >= 0.5 ? 1 : 0) === ytest[i]) right++;
  results.feasibility = {
    share: round(ytest.reduce((a, b) => a + b, 0) / ytest.length),
    trainMs,
    sizeBytes: model.size(),
    accuracy: round(right / pred.length),
    majorityAccuracy: round(
      [...ytest].filter((v) => v === majority).length / ytest.length,
    ),
    auc: round(pairwiseAccuracy(pred, ytest, groups, { pairs: CONFIG.pairs, seed: 13 }).accuracy),
    gaAuc: round(pairwiseAccuracy(gaOnTest, ytest, groups, { pairs: CONFIG.pairs, seed: 13 }).accuracy),
    gaMaxOnImpossible: round(Math.max(...split.test.filter((i) => allRows[i].f === 0).map((i) => allRows[i].g)), 3),
  };
  console.log(`\nfeasibility: accuracy ${results.feasibility.accuracy} (majority ${results.feasibility.majorityAccuracy}), AUC ${results.feasibility.auc}, GA's AUC ${results.feasibility.gaAuc}`);
}

// The leakage gap: the same model, the same data, only the wall moves
const spearmanOf = (mode, name) => results.splits[mode].models.find((m) => m.name === name)?.spearman;
results.leakage = {};
for (const name of ['ga-hand-written', 'baseline-span-only', 'ridge', 'random-forest', 'gradient-boosting', 'mlp']) {
  results.leakage[name] = {
    byVoicing: spearmanOf('voicing', name),
    byChord: spearmanOf('chord', name),
    byShape: spearmanOf('shape', name),
    naiveMinusChord: round(spearmanOf('voicing', name) - spearmanOf('chord', name)),
    chordMinusShape: round(spearmanOf('chord', name) - spearmanOf('shape', name)),
  };
}

results.totalMs = Date.now() - started;
writeFileSync(outPath, `${JSON.stringify(results, null, 2)}\n`);
console.log(`\n${outPath} written in ${(results.totalMs / 1000).toFixed(1)} s`);
