// examples/l03_positions.ts
// Branded numbers for the two string numberings found in GuitarAlchemist/ga's front end:
// InstrumentConfig.ts counts from 0 (0 = highest string), VexTabViewer.tsx and InverseKinematics.tsx from 1 (1 = high E)

// A unique symbol exists only in this module's declarations: nothing outside can name the brand
declare const brand: unique symbol;
type Brand<T, B extends string> = T & { readonly [brand]: B };

export type StringIndex = Brand<number, 'StringIndex'>; // 0-based, 0 = highest string
export type StringNumber = Brand<number, 'StringNumber'>; // 1-based, 1 = highest string, as in tablature
export type Fret = Brand<number, 'Fret'>; // 0 = open string

export const STRING_COUNT = 6;
export const MAX_FRET = 24;

// Smart constructors: the only functions that turn a number into a branded one, after checking it
export function stringIndex(value: number): StringIndex {
  if (!Number.isInteger(value) || value < 0 || value >= STRING_COUNT) throw new RangeError(`string index out of range: ${value}`);
  return value as StringIndex;
}
export function stringNumber(value: number): StringNumber {
  if (!Number.isInteger(value) || value < 1 || value > STRING_COUNT) throw new RangeError(`string number out of range: ${value}`);
  return value as StringNumber;
}
export function fret(value: number): Fret {
  if (!Number.isInteger(value) || value < 0 || value > MAX_FRET) throw new RangeError(`fret out of range: ${value}`);
  return value as Fret;
}

// Conversions are explicit, and written once
export const toStringNumber = (index: StringIndex): StringNumber => (index + 1) as StringNumber;
export const toStringIndex = (number: StringNumber): StringIndex => (number - 1) as StringIndex;
