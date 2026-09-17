// GA's hand-written playability cost, ported line for line from
// Common/GA.Domain.Services/Fretboard/Voicings/Analysis/VoicingPhysicalAnalyzer.cs at GuitarAlchemist/ga@66bdd049,
// CalculatePlayability (lines 86-155) and DetectBarreRequirement (lines 219-234), with the fret geometry of
// Common/GA.Domain.Services/Fretboard/Analysis/PhysicalFretboardCalculator.cs (CalculateFretDistanceMm, ScaleLengths.Electric).
//
// The score is what GaCLI writes into the voicing index's documents and what GaApi sorts "easy chords" by.
// It is the reference this prototype tries to beat, not a ground truth.

import { fretDistanceMm } from './voicing.mjs';

// GA's DetectBarreRequirement: the same fret on three adjacent entries of the fret array.
// GA's array is the index's string order, string 1 first.
export function gaBarreRequired(frets) {
  for (let i = 0; i < frets.length - 2; i++) {
    const f = frets[i];
    if (f > 0 && frets[i + 1] === f && frets[i + 2] === f) return true;
  }
  return false;
}

export function gaPlayability(frets) {
  const fretted = frets.filter((f) => f > 0);
  const open = frets.filter((f) => f === 0);
  const minFret = fretted.length ? Math.min(...fretted) : 0;
  const maxFret = fretted.length ? Math.max(...fretted) : 0;

  const physicalSpan = fretted.length ? fretDistanceMm(minFret, maxFret) : 0;
  const spanScore = physicalSpan / 80;
  const handStretch = maxFret - minFret;
  const barreRequired = gaBarreRequired(frets);
  const minimumFingers = Math.min(new Set(fretted).size, 4);

  let difficulty;
  if (spanScore <= 0.8 && !barreRequired && open.length > 0) difficulty = 'Beginner';
  else if (spanScore > 1.2 || (barreRequired && handStretch >= 4)) difficulty = 'Advanced';
  else difficulty = 'Intermediate';

  let score = 1;
  if (barreRequired) score += 2;
  score += spanScore * 3;
  if (open.length === 0) score += 1;
  if (minimumFingers === 4) score += 1;
  score = Math.min(10, score);

  return { difficulty, handStretch, barreRequired, minimumFingers, spanScore, score };
}

export function gaCost(frets) {
  return gaPlayability(frets).score;
}
