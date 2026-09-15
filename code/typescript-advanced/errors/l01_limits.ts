// errors/l01_limits.ts
// Tail-recursive: evaluated in a loop, stopped after 1,000 iterations
type BuildTuple<N extends number, Acc extends unknown[] = []> = Acc['length'] extends N ? Acc : BuildTuple<N, [...Acc, unknown]>;
type Length999 = BuildTuple<999>['length'];
type Length1000 = BuildTuple<1000>['length'];

// Not tail-recursive: each level nests instantiations, stopped at a depth of 100
type Reverse<T extends unknown[]> = T extends [infer Head, ...infer Tail] ? [...Reverse<Tail>, Head] : [];
type Reversed49 = Reverse<BuildTuple<49>>['length'];
// The same depth passes once a shorter reversal is in the cache: each level starts from a result already computed
type Reversed40 = Reverse<BuildTuple<40>>['length'];
type Reversed80 = Reverse<BuildTuple<80>>['length'];

// A template literal type whose cross product reaches 100,000 members
type Digit = '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9';
type FourDigits = `${Digit}${Digit}${Digit}${Digit}`;
type FiveDigits = `${Digit}${Digit}${Digit}${Digit}${Digit}`;

const lengths: [Length999, Length1000, Reversed49, Reversed40, Reversed80] = [999, 1000, 49, 40, 80];
const codes: [FourDigits, FiveDigits] = ['0440', '04400'];
console.log(lengths, codes);
