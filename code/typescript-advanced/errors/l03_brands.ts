// errors/l03_brands.ts
import { fret, stringIndex, type Fret, type StringIndex, type StringNumber } from '../examples/l03_positions.ts';

declare function openStringOf(string: StringNumber): string;
interface FretboardPosition {
  string: StringIndex;
  fret: Fret;
}

const clicked: FretboardPosition = { string: stringIndex(1), fret: fret(3) };
openStringOf(clicked.string); // a 0-based index where a 1-based number is expected
openStringOf(2); // a plain number
const moved: FretboardPosition = { ...clicked, fret: clicked.fret + 1 }; // arithmetic loses the brand
const swapped: FretboardPosition = { string: clicked.fret, fret: clicked.string };

// An assertion still forges a brand: brands catch mistakes, not deliberate casts
const forged = 99 as StringNumber;
console.log(moved, swapped, forged);
