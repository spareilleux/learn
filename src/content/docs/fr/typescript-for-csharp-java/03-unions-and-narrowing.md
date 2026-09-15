---
title: 3. Unions et narrowing
description: Types union, narrowing avec typeof, in, instanceof et le flux de contrôle, unions discriminées et exhaustivité avec never, assertions de type qui ne vérifient rien, prédicats de type et fonctions d'assertion — face aux switch expressions de C# et aux sealed interfaces de Java.
sidebar:
  order: 3
---

Code : les fichiers [`examples/l03_*`](https://github.com/spareilleux/learn/tree/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/examples) et [`errors/l03_*`](https://github.com/spareilleux/learn/tree/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/errors), et les côtés C# et Java dans [`compare/l03_switch.cs`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/compare/l03_switch.cs), [`compare/l03_cast.cs`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/compare/l03_cast.cs), [`compare/L03Cast.java`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/compare/L03Cast.java) et [`compare_fail/L03Sealed.java`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/compare_fail/L03Sealed.java).

C# et Java modélisent « une chose parmi plusieurs » avec une hiérarchie de classes : une base abstraite, une sous-classe par cas, et une méthode virtuelle ou un pattern matching pour les distinguer. JavaScript n'a pas de telle hiérarchie pour la plupart de ses valeurs : une case est un nombre ou la chaîne `'open'`, un événement est un objet dont la propriété `kind` dit ce qu'il est. TypeScript décrit ces valeurs avec des **types union**, et suit les vérifications de ton code pour savoir quel membre est une valeur à chaque ligne. Cette seconde partie, le ***narrowing***, le rétrécissement du type, est le sujet de cette leçon ([manuel : narrowing](https://www.typescriptlang.org/docs/handbook/2/narrowing.html)).

## Types union

`A | B` est une valeur qui est un `A` ou un `B`. Avant une vérification, seul ce que possèdent tous les membres est permis :

```ts
// errors/l03_union_members.ts
type Fret = number | 'open' | 'muted';

function describe(fret: Fret): string {
  return `fret ${fret.toFixed(0)}`;
}

console.log(describe(3), describe('open'));
```

```text
> npx tsc -p out/tsconfig.l03_union_members.json --pretty
errors/l03_union_members.ts:5:23 - error TS2339: Property 'toFixed' does not exist on type 'Fret'.
  Property 'toFixed' does not exist on type '"muted"'.

5   return `fret ${fret.toFixed(0)}`;
                        ~~~~~~~


Found 1 error in errors/l03_union_members.ts:5
> node errors/l03_union_members.ts
errors/l03_union_members.ts:5
  return `fret ${fret.toFixed(0)}`;
                      ^

TypeError: fret.toFixed is not a function

Node.js v24.21.0
```

`number` a `toFixed`, `'open'` et `'muted'` non, donc `Fret` non plus. Le message nomme un des membres auxquels la propriété manque. Une union de types littéraux, `'open' | 'muted'`, est aussi la façon dont TypeScript écrit ce dont C# et Java feraient un `enum`, sans l'objet d'exécution que Node.js refuse de supprimer ([leçon 1](../01-compiler-and-tooling/)).

## Le narrowing

```ts
// examples/l03_narrowing.ts
import { show } from './show.ts';

// Une union : une case est un nombre, ou 'open', ou 'muted'
type Fret = number | 'open' | 'muted';

function describe(fret: Fret): string {
  if (typeof fret === 'number') {
    return `fret ${fret.toFixed(0)}`; // ici fret est un number
  }
  return fret === 'open' ? 'open string' : 'not played'; // ici fret est 'open' | 'muted'
}
show('describe(3)', describe(3));
show("describe('muted')", describe('muted'));

// La truthiness restreint aussi, et 0 est falsy : la corde à vide jouée à la case 0 disparaît
function label(fret: number | undefined): string {
  if (fret) return `fret ${fret}`;
  return 'no fret';
}
show('label(0)', label(0));
show('label(undefined)', label(undefined));

// in, instanceof et Array.isArray
interface Note {
  pitch: number;
}
interface Chord {
  pitches: number[];
}
function lowest(event: Note | Chord): number {
  return 'pitch' in event ? event.pitch : Math.min(...event.pitches);
}
show('lowest({ pitch: 40 })', lowest({ pitch: 40 }));
show('lowest({ pitches: [52, 45] })', lowest({ pitches: [52, 45] }));

function message(error: unknown): string {
  if (error instanceof Error) return error.message;
  if (Array.isArray(error)) return `${error.length} errors`;
  return String(error);
}
show("message(new RangeError('fret 25'))", message(new RangeError('fret 25')));
show("message(['a', 'b'])", message(['a', 'b']));

// Flux de contrôle : après un return ou un throw, la suite de la fonction en sait davantage
function parseFret(text: string): Fret {
  if (text === 'o') return 'open';
  if (text === 'x') return 'muted';
  const fret = Number(text);
  if (!Number.isInteger(fret) || fret < 0) throw new RangeError(`not a fret: ${text}`);
  return fret;
}
show("'x32010'.split('').map(parseFret)", 'x32010'.split('').map(parseFret));
```

```text
describe(3)                        'fret 3'
describe('muted')                  'not played'
label(0)                           'no fret'
label(undefined)                   'no fret'
lowest({ pitch: 40 })              40
lowest({ pitches: [52, 45] })      45
message(new RangeError('fret 25')) 'fret 25'
message(['a', 'b'])                '2 errors'
'x32010'.split('').map(parseFret)  [ 'muted', 3, 2, 0, 1, 0 ]
```

Chaque vérification que JavaScript peut exécuter devient une information pour `tsc` :

| Vérification | Restreint à | Équivalent C# / Java |
|---|---|---|
| `typeof fret === 'number'` | `number`, et `'open' \| 'muted'` dans le `else` | `fret is int` / `fret instanceof Integer` |
| `fret === 'open'` | le type littéral `'open'` | `==` sur une constante |
| `if (fret)` | retire `undefined`, `null`, et les types littéraux `0`, `''`, `false` | — |
| `'pitch' in event` | les membres qui déclarent `pitch` | — |
| `error instanceof Error` | `Error` | `error is Exception e` / `error instanceof Exception e` |
| `Array.isArray(error)` | `any[]` | — |
| `return`, `throw` | la suite de la fonction, sans les cas qui en sont sortis | affectation définie, analyse de flux |

Deux de ces vérifications méritent un avertissement. La **truthiness** restreint `number | undefined` à `number`, et le `if (fret)` de `label` envoie aussi la case `0`, la corde à vide, dans la branche `'no fret'` : `tsc` l'accepte, parce que `0` est un `number`, et le programme est faux. Les règles sont celles de la [leçon 2 de JavaScript](../../javascript-for-csharp-java/02-values-and-types/#conversions-----parsing-et-truthiness) ; compare avec `!== undefined` chaque fois que `0` ou `''` est une valeur valide. **`in`** vérifie une propriété à l'exécution, et le typage structurel permet à un objet d'avoir plus de propriétés que son type n'en annonce : un objet `Chord` qui porterait aussi un `pitch` prendrait la branche `Note`. `in` est fiable quand les membres de l'union ne peuvent pas avoir les propriétés les uns des autres, et c'est ce que construit la section suivante.

`tsc` suit le code comme le fait l'analyse d'affectation définie de C#, à travers `return`, `throw`, `&&`, `||` et `?:` : dans `parseFret`, `fret` est un `number` après les deux retours anticipés, et le `throw` garantit que c'est un entier positif ou nul, un fait que le type `number` ne peut pas exprimer.

## Unions discriminées

Quand chaque membre d'une union a la même propriété avec un type littéral différent, vérifier cette propriété restreint l'union à un seul membre. Cette propriété est le **discriminant**, ici `kind` :

```ts
// examples/l03_discriminated.ts
import { show } from './show.ts';

// Une union discriminée : chaque membre a un kind, avec un type littéral différent
type MusicEvent =
  | { kind: 'note'; pitch: number; beats: number }
  | { kind: 'chord'; pitches: number[]; beats: number }
  | { kind: 'rest'; beats: number };

function assertNever(value: never): never {
  throw new Error(`unexpected event: ${JSON.stringify(value)}`);
}

function describe(event: MusicEvent): string {
  switch (event.kind) {
    case 'note':
      return `note ${event.pitch} for ${event.beats}`;
    case 'chord':
      return `chord of ${event.pitches.length} for ${event.beats}`;
    case 'rest':
      return `rest for ${event.beats}`;
    default:
      return assertNever(event); // ici event est never : chaque kind est traité
  }
}

const bar: MusicEvent[] = [
  { kind: 'chord', pitches: [48, 52, 55], beats: 2 },
  { kind: 'note', pitch: 60, beats: 1 },
  { kind: 'rest', beats: 1 },
];
for (const event of bar) show(event.kind, describe(event));

// La vérification que tsc a faite à la compilation s'exécute toujours, pour les données qui ne sont pas passées par tsc
const fromServer = JSON.parse('{"kind": "tie", "beats": 1}') as MusicEvent;
try {
  describe(fromServer);
} catch (err) {
  show('describe(fromServer)', err instanceof Error ? err.message : err);
}
```

```text
chord                              'chord of 3 for 2'
note                               'note 60 for 1'
rest                               'rest for 1'
describe(fromServer)               'unexpected event: {"kind":"tie","beats":1}'
```

Dans `case 'note':`, `event` est `{ kind: 'note'; pitch: number; beats: number }`, et `event.pitch` compile ; dans `case 'rest':`, ce ne serait pas le cas. Après les trois cas, il ne reste rien : `event` a le type `never`, et `assertNever(event)` compile parce qu'un `never` est assignable au paramètre `never`. À l'exécution, la branche `default` existe toujours, et elle attrape ce que les types n'ont pas vu : `fromServer` a été affirmé comme un `MusicEvent`, est arrivé avec le kind `'tie'`, et a atteint `assertNever`.

Une union discriminée est la version TypeScript d'une hiérarchie fermée, un `abstract record` C# avec ses records dérivés, ou une `sealed interface` Java avec ses implémentations `record`. Les données sont de simples objets, ce que renvoie `JSON.parse` et ce qu'envoie un serveur.

## Exhaustivité

Ajoute un membre, et chaque `switch` qui ne le traite pas devrait échouer à la compilation. Avec `assertNever` dans le `default`, ou avec un type de retour déclaré, c'est le cas :

```ts
// errors/l03_exhaustive.ts
// Un nouveau type d'événement : les deux fonctions qui ne le traitent pas sont maintenant des erreurs
type MusicEvent =
  | { kind: 'note'; pitch: number; beats: number }
  | { kind: 'chord'; pitches: number[]; beats: number }
  | { kind: 'rest'; beats: number }
  | { kind: 'tie'; beats: number };

function assertNever(value: never): never {
  throw new Error(`unexpected event: ${JSON.stringify(value)}`);
}

function describe(event: MusicEvent): string {
  switch (event.kind) {
    case 'note':
      return `note ${event.pitch}`;
    case 'chord':
      return `chord of ${event.pitches.length}`;
    case 'rest':
      return 'rest';
    default:
      return assertNever(event);
  }
}

function beatsOf(event: MusicEvent): number {
  switch (event.kind) {
    case 'note':
    case 'chord':
    case 'rest':
      return event.beats;
  }
}

console.log(describe({ kind: 'tie', beats: 1 }), beatsOf({ kind: 'tie', beats: 1 }));
```

```text
> npx tsc -p out/tsconfig.l03_exhaustive.json --pretty
errors/l03_exhaustive.ts:22:26 - error TS2345: Argument of type '{ kind: "tie"; beats: number; }' is not assignable to parameter of type 'never'.

22       return assertNever(event);
                            ~~~~~

errors/l03_exhaustive.ts:26:38 - error TS2366: Function lacks ending return statement and return type does not include 'undefined'.

26 function beatsOf(event: MusicEvent): number {
                                        ~~~~~~


Found 2 errors in the same file, starting at: errors/l03_exhaustive.ts:22
> node errors/l03_exhaustive.ts
errors/l03_exhaustive.ts:10
  throw new Error(`unexpected event: ${JSON.stringify(value)}`);
        ^

Error: unexpected event: {"kind":"tie","beats":1}

Node.js v24.21.0
```

La première erreur dit qu'un événement `tie` atteint un paramètre qui n'accepte rien. La seconde vient du type de retour : `beatsOf` promet un `number`, et un événement `tie` passerait à travers le `switch` et renverrait `undefined`. Sans `assertNever`, une fonction sans type de retour déclaré, ou qui renvoie `void`, compile sans message ([vérification d'exhaustivité](https://www.typescriptlang.org/docs/handbook/2/narrowing.html#exhaustiveness-checking)).

Le même changement en C#, avec une [expression switch](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/switch-expression) sur des records, donne un avertissement :

```text
> dotnet run l03_switch.cs
compare/l03_switch.cs(10,43): warning CS8509: The switch expression does not handle all possible values of its input type (it is not exhaustive). For example, the pattern '_' is not covered.
chord of 3
note 60
SwitchExpressionException
```

C# ne peut pas savoir qu'aucune autre classe ne dérive de `MusicEvent`, donc il demande un cas `_`, compile quand même, et lève [`SwitchExpressionException`](https://learn.microsoft.com/dotnet/api/system.runtime.compilerservices.switchexpressionexception) sur le `Tie`. Les [interfaces scellées](https://docs.oracle.com/en/java/javase/25/language/sealed-classes-and-interfaces.html) de Java ferment la hiérarchie, et un [`switch` avec patterns](https://docs.oracle.com/en/java/javase/25/language/pattern-matching-switch.html) sur l'une d'elles est vérifié comme TypeScript vérifie une union :

```text
> javac L03Sealed.java
L03Sealed.java:10: error: the switch expression does not cover all possible input values
        return switch (e) {
               ^
1 error
```

| | C# | Java | TypeScript |
|---|---|---|---|
| Ensemble fermé de cas | pas de hiérarchies fermées en C# 14 : un cas `_` est attendu | `sealed interface … permits` | un type union |
| Cas manquant | avertissement CS8509, `SwitchExpressionException` à l'exécution | erreur de compilation | erreur, si le `switch` se termine par `assertNever` ou si la fonction déclare son type de retour |
| Données venues de l'extérieur | désérialisées dans les classes | désérialisées dans les records | de simples objets : le discriminant doit être vérifié |

## as ne vérifie rien

Les casts de C# et de Java sont vérifiés à l'exécution. Une **assertion de type** TypeScript, `value as T`, est un message adressé à `tsc`, et disparaît avec les autres types :

```ts
// examples/l03_guards.ts, lignes 11-13
const trusted = JSON.parse('{"px": 1, "py": 2}') as CameraState;
show('trusted.pz', trusted.pz);
show('trusted.pz * 2', trusted.pz * 2);
```

```text
trusted.pz                         undefined
trusted.pz * 2                     NaN
```

```text
> dotnet run l03_cast.cs
(CameraState)parsed: InvalidCastException
parsed as CameraState: True
parsed is CameraState: False
```

```text
> java L03Cast.java
(CameraState) parsed: ClassCastException
parsed instanceof CameraState: false
```

Le `(CameraState)parsed` de C# lève `InvalidCastException`, `as` renvoie `null`, et le cast de Java lève `ClassCastException` : le runtime connaît la classe de chaque objet. Un objet JavaScript parsé depuis du JSON n'a pas de classe à laquelle se comparer, et `as` n'essaie pas. `tsc` ne refuse une assertion qu'entre deux types qui ne se recouvrent pas du tout, et `as unknown as T` passe par `unknown` pour contourner ce refus ([assertions de type](https://www.typescriptlang.org/docs/handbook/2/everyday-types.html#type-assertions)). Le `NaN` sorti de `trusted.pz * 2` est le genre de valeur qui voyage loin de la ligne qui l'a produite.

## Prédicats de type et fonctions d'assertion

Une vérification que `tsc` ne peut pas lire dans une seule expression va dans une fonction dont le type de retour dit ce qu'elle prouve :

```ts
// examples/l03_guards.ts
import { attempt, show } from './show.ts';

interface CameraState {
  px: number;
  py: number;
  pz: number;
}

// as n'est pas un cast : il ne convertit rien et ne vérifie rien
const trusted = JSON.parse('{"px": 1, "py": 2}') as CameraState;
show('trusted.pz', trusted.pz);
show('trusted.pz * 2', trusted.pz * 2);

// Un prédicat de type : une fonction qui renvoie un booléen, et dit à tsc ce que true signifie
function isCameraState(value: unknown): value is CameraState {
  return (
    typeof value === 'object' &&
    value !== null &&
    'px' in value &&
    typeof value.px === 'number' && // après 'px' in value, tsc sait que value a une propriété px de type unknown
    'py' in value &&
    typeof value.py === 'number' &&
    'pz' in value &&
    typeof value.pz === 'number'
  );
}

function restore(saved: string): CameraState {
  const value: unknown = JSON.parse(saved);
  return isCameraState(value) ? value : { px: 0, py: 0, pz: 100 };
}
show("restore('{\"px\":1,\"py\":2}')", restore('{"px":1,"py":2}'));
show("restore('{\"px\":1,\"py\":2,\"pz\":3}')", restore('{"px":1,"py":2,"pz":3}'));

// Une fonction d'assertion : elle ne revient que si la condition est vraie, et lève une exception sinon
type Mode = 'ionian' | 'dorian' | 'phrygian';
const modes: readonly string[] = ['ionian', 'dorian', 'phrygian'];
function assertMode(value: string): asserts value is Mode {
  if (!modes.includes(value)) throw new RangeError(`unknown mode: ${value}`);
}
function brightness(mode: Mode): number {
  return modes.length - modes.indexOf(mode);
}
const fromUrl = new URLSearchParams('?mode=dorian').get('mode') ?? 'ionian';
assertMode(fromUrl);
show('brightness(fromUrl)', brightness(fromUrl)); // fromUrl est un Mode après l'assertion
attempt("assertMode('locrian')", () => assertMode('locrian'));

// tsc fait confiance à un prédicat sans le lire : un prédicat faux est un mensonge qui compile
function isCameraStateLie(value: unknown): value is CameraState {
  return value !== null;
}
const lie: unknown = JSON.parse('"not a camera"');
if (isCameraStateLie(lie)) {
  attempt('lie.px.toFixed(1)', () => lie.px.toFixed(1));
}
```

```text
trusted.pz                         undefined
trusted.pz * 2                     NaN
restore('{"px":1,"py":2}')         { px: 0, py: 0, pz: 100 }
restore('{"px":1,"py":2,"pz":3}')  { px: 1, py: 2, pz: 3 }
brightness(fromUrl)                2
assertMode('locrian')              RangeError: unknown mode: locrian
lie.px.toFixed(1)                  TypeError: Cannot read properties of undefined (reading 'toFixed')
```

- **`value is CameraState`**, un [prédicat de type](https://www.typescriptlang.org/docs/handbook/2/narrowing.html#using-type-predicates), renvoie un `boolean`, et dans la branche où il a renvoyé `true`, l'argument est un `CameraState`. Dans `isCameraState`, chaque `'px' in value` restreint `value` à un objet doté d'une propriété `px` de type `unknown`, que `typeof value.px === 'number'` restreint ensuite à `number` : la fonction compile sans un seul `as`.
- **`asserts value is Mode`**, une [fonction d'assertion](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-3-7.html#assertion-functions), ne revient que si la condition est vraie, et lève une exception sinon ; après l'appel, la variable a le type plus étroit pour le reste de la portée, comme après un `throw` dans la fonction elle-même. La fonction doit être déclarée avec un type explicite, une déclaration `function` ou une `const` annotée, pour que `tsc` s'en serve.
- **`tsc` ne lit pas le corps d'un prédicat.** `isCameraStateLie` vérifie seulement que la valeur n'est pas `null`, compile, et fait croire à `tsc` qu'une chaîne est une caméra. Un prédicat est une assertion enveloppée dans une fonction : ce sont les vérifications qu'il contient qui le rendent vrai, et elles méritent leurs propres tests.

C'est le modèle de la frontière pour les données venues de l'extérieur du programme, `JSON.parse`, `localStorage`, `fetch`, un message SignalR : un `unknown` à l'entrée, un prédicat ou une conversion qui le vérifie, et des types précis à l'intérieur.

## Dans GuitarAlchemist/ga : des statuts que le type exclut

Le Prime Radiant de GA, un graphe de gouvernance dans [`ga-react-components`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components), déclare les statuts de santé que peut avoir un nœud dans [`types.ts`, ligne 34](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/PrimeRadiant/types.ts#L34) :

```ts
export type GovernanceHealthStatus = 'error' | 'warning' | 'healthy' | 'unknown' | 'contradictory';
```

[`ForceRadiant.tsx`, lignes 720-729](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/PrimeRadiant/ForceRadiant.tsx#L720-L729), choisit une prédiction à partir de ce statut, et teste aussi `'ok'` et `'critical'`. `tsc` 7.0.2 signale les deux, parmi les erreurs de la leçon 1 ; le cours reproduit la fonction avec le même type :

```ts
// errors/l03_ga_health.ts
type GovernanceHealthStatus = 'error' | 'warning' | 'healthy' | 'unknown' | 'contradictory';
interface GovernanceNode {
  id: string;
  healthStatus?: GovernanceHealthStatus;
}

function prediction(node: GovernanceNode): string {
  const status = node.healthStatus ?? 'unknown';
  if (status === 'healthy' || status === 'ok') return 'stable';
  if (status === 'warning') return 'at risk';
  if (status === 'error' || status === 'critical') return 'failing';
  return 'uncertain';
}

console.log(prediction({ id: 'policy-7' }));
```

```text
> npx tsc -p out/tsconfig.l03_ga_health.json --pretty
errors/l03_ga_health.ts:10:31 - error TS2367: This comparison appears to be unintentional because the types '"contradictory" | "error" | "unknown" | "warning"' and '"ok"' have no overlap.

10   if (status === 'healthy' || status === 'ok') return 'stable';
                                 ~~~~~~~~~~~~~~~

errors/l03_ga_health.ts:12:29 - error TS2367: This comparison appears to be unintentional because the types '"contradictory" | "unknown"' and '"critical"' have no overlap.

12   if (status === 'error' || status === 'critical') return 'failing';
                               ~~~~~~~~~~~~~~~~~~~~~


Found 2 errors in the same file, starting at: errors/l03_ga_health.ts:10
```

Les messages montrent le *narrowing* à l'œuvre : une fois que `status === 'healthy'` a échoué, `status` ne peut plus être `'healthy'`, et après la ligne `warning`, il ne peut plus être `'warning'` non plus. Aucune des deux comparaisons ne peut jamais être vraie pour une valeur de ce type. À l'exécution, pourtant, elle le peut, à cause de la provenance des données. [`DataLoader.ts`, lignes 276-278](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/PrimeRadiant/DataLoader.ts#L276-L278), reçoit le message `NodeChanged` du [client JavaScript de SignalR](https://learn.microsoft.com/aspnet/core/signalr/javascript-client) avec `healthStatus: string`, et le transmet sous la forme `data as unknown as GovernanceNode` :

```ts
// examples/l03_ga_health.ts
import { show } from './show.ts';

// types.ts, ligne 34 : les statuts que connaît le front end
type GovernanceHealthStatus = 'error' | 'warning' | 'healthy' | 'unknown' | 'contradictory';
interface GovernanceNode {
  id: string;
  healthStatus?: GovernanceHealthStatus;
}

// DataLoader.ts, lignes 276-278 : un message SignalR typé avec une string, transmis avec une double assertion
function onNodeChanged(data: { nodeId: string; healthStatus: string }): GovernanceNode {
  return data as unknown as GovernanceNode;
}

// ForceRadiant.tsx, lignes 720-729, réduit : les statuts 'ok' et 'critical' ne peuvent pas être dans l'union
function prediction(node: GovernanceNode): string {
  const status: string = node.healthStatus ?? 'unknown'; // élargi à string, sinon tsc signale TS2367 plus bas
  if (status === 'healthy' || status === 'ok') return 'stable';
  if (status === 'warning') return 'at risk';
  if (status === 'error' || status === 'critical') return 'failing';
  return 'uncertain';
}

const node = onNodeChanged({ nodeId: 'policy-7', healthStatus: 'critical' });
show('node.healthStatus', node.healthStatus);
show('prediction(node)', prediction(node));
const known: readonly string[] = ['error', 'warning', 'healthy', 'unknown', 'contradictory'];
show('known.includes(node.healthStatus)', known.includes(node.healthStatus ?? 'unknown'));
```

```text
node.healthStatus                  'critical'
prediction(node)                   'failing'
known.includes(node.healthStatus)  false
```

Un `'critical'` venu du serveur atteint un `GovernanceNode` dont le type dit qu'il ne peut pas être `'critical'`, et la comparaison que `tsc` qualifie de non intentionnelle est celle qui le traite. Deux lectures sont possibles, et le code ne dit pas laquelle est la bonne : le serveur envoie `ok` et `critical` (*à vérifier* dans le hub de GA), et il manque deux membres à l'union ; ou il ne les envoie pas, et les comparaisons sont du code mort. Dans les deux cas, la double assertion est l'endroit où le type a cessé de décrire les données. Le troisième exercice convertit plutôt le statut à cette frontière. `ga-react-components` contient 34 `as unknown as`, et le même fichier restaure la caméra avec [`JSON.parse(saved) as { px: number; … }`, ligne 3558](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/PrimeRadiant/ForceRadiant.tsx#L3555-L3561), le modèle de la section sur `as` : une valeur enregistrée à laquelle manque une coordonnée passerait `undefined` à `fg.cameraPosition` (*à vérifier* dans un navigateur) ; le deuxième exercice la vérifie.

### L'ordre des unions dans les messages

TypeScript 5.9.3, sur le même fichier de GA, affichait la première union sous la forme `"warning" | "error" | "unknown" | "contradictory"` ; 7.0.2 affiche `"contradictory" | "error" | "unknown" | "warning"`. Ni l'un ni l'autre ne suit l'ordre de la déclaration. Jusqu'à 6.0, les membres d'une union étaient triés par identifiants de type internes, attribués dans l'ordre où le vérificateur rencontrait les types ; TypeScript 7 vérifie les fichiers en parallèle et trie plutôt les types selon leur contenu, pour que la sortie ne dépende pas du thread qui a vu un type en premier ([notes de version 6.0, `--stableTypeOrdering`](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html#the---stabletypeordering-flag)). N'écris pas de test qui compare le texte d'une union dans un message ou un `.d.ts` d'une version à l'autre.

## Sur ce site : une union inférée à partir de JSON

Le fichier [`astro.config.mjs`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/astro.config.mjs#L1-L4) de ce site commence par `// @ts-check`, qui demande à `tsc` de vérifier un fichier JavaScript, et importe le fichier généré [`streeling-sidebar.json`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/src/streeling-sidebar.json) dans la [barre latérale de Starlight](https://starlight.astro.build/guides/sidebar/). Lancer `tsc` 7.0.2 sur le site à ce commit, avec le `tsconfig.json` du site lui-même, le signale :

```text
astro.config.mjs(146,5): error TS2322: Type '{ label: string; collapsed: true; items: ({ label: string; translations: { fr: string; es: string; }; slug: string; collapsed?: undefined; items?: undefined; } | { label: string; translations: { es: string; fr?: undefined; }; slug: string; collapsed?: undefined; items?: undefined; } | { ...; })[]; }' is not assignable to type 'SidebarItemUserConfig'.
  Types of property 'items' are incompatible.
  […]
                Types of property 'translations' are incompatible.
                  Type '{ es: string; fr?: undefined; }' is not assignable to type 'Record<string, string>'.
                    Property '"fr"' is incompatible with index signature.
                      Type 'undefined' is not assignable to type 'string'.
```

Un import JSON reçoit le type de son contenu, inféré comme pour un littéral objet. Le tableau contient des entrées de formes différentes, donc son type d'élément est une union, et `tsc` [normalise les types des littéraux objets](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-2-7.html#improved-type-inference-for-object-literals) dans une union : une propriété qu'un membre possède et qu'un autre n'a pas est ajoutée à l'autre comme optionnelle et `undefined`, pour pouvoir être lue sur chaque membre. L'entrée `Journal` n'a qu'une traduction espagnole, reçoit `fr?: undefined`, et ne rentre plus dans un `Record<string, string>`. Rien ne se passe mal à l'exécution : le build Astro n'exécute pas `tsc`, et Starlight valide la barre latérale au chargement. L'exemple montre la limite de l'inférence pour les données : un type écrit par le programme, vérifié contre les données à la frontière, dit ce que le code attend, là où un type inféré dit seulement ce que le fichier contenait ce jour-là.

## À retenir

- Une union ne permet que ce que tous ses membres ont ; une vérification la restreint, et `tsc` suit `typeof`, `===`, la truthiness, `in`, `instanceof`, `return` et `throw`.
- Le *narrowing* par truthiness retire aussi `0` et `''` ; `in` peut être trompé par des propriétés en trop.
- Une union discriminée, qui a une propriété littérale commune, est la hiérarchie fermée de TypeScript. Termine son `switch` par `assertNever`, ou déclare le type de retour, et un nouveau membre devient une erreur de compilation, comme avec les interfaces scellées de Java et contrairement à l'avertissement de C#.
- `as` ne vérifie rien, là où les casts de C# et de Java lèvent une exception ; `as unknown as` retire la dernière vérification que fait `tsc`.
- Un prédicat de type ou une fonction d'assertion restreint ce que `tsc` ne peut pas suivre, et `tsc` fait aveuglément confiance à son corps.
- Les données venues de l'extérieur entrent comme `unknown` et sont vérifiées ou converties une seule fois, à la frontière.
- Ne dépends pas de l'ordre des membres d'une union dans les messages ou les fichiers de déclaration.

## Exercices

1. Ajoute un événement `{ kind: 'tie'; beats: number }` au `MusicEvent` de [`errors/l03_exhaustive.ts`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/errors/l03_exhaustive.ts), fais compiler les deux fonctions, et calcule le total des temps d'une mesure.

<details>
<summary>Solution</summary>

[`solutions/l03_ex1_tie.ts`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/solutions/l03_ex1_tie.ts) :

```ts
// solutions/l03_ex1_tie.ts
type MusicEvent =
  | { kind: 'note'; pitch: number; beats: number }
  | { kind: 'chord'; pitches: number[]; beats: number }
  | { kind: 'rest'; beats: number }
  | { kind: 'tie'; beats: number };

function assertNever(value: never): never {
  throw new Error(`unexpected event: ${JSON.stringify(value)}`);
}

function describe(event: MusicEvent): string {
  switch (event.kind) {
    case 'note':
      return `note ${event.pitch} for ${event.beats}`;
    case 'chord':
      return `chord of ${event.pitches.length} for ${event.beats}`;
    case 'rest':
      return `rest for ${event.beats}`;
    case 'tie':
      return `tie for ${event.beats}`;
    default:
      return assertNever(event);
  }
}

// beatsOf n'a besoin d'aucun switch : chaque membre a beats
function beatsOf(event: MusicEvent): number {
  return event.beats;
}

const bar: MusicEvent[] = [
  { kind: 'note', pitch: 60, beats: 2 },
  { kind: 'tie', beats: 1 },
  { kind: 'rest', beats: 1 },
];
console.log(bar.map(describe), bar.reduce((sum, event) => sum + beatsOf(event), 0));
```

```text
[ 'note 60 for 2', 'tie for 1', 'rest for 1' ] 4
```

`beats` est commun à tous les membres, donc `event.beats` compile sans *narrowing*, et `beatsOf` n'a plus de `switch` où oublier un cas.

</details>

2. GA enregistre sa caméra sous forme de six nombres, `px`, `py`, `pz` pour la position et `lx`, `ly`, `lz` pour la cible. Écris `restoreCamera(saved: string | null): CameraState | undefined`, qui renvoie `undefined` pour une valeur absente, du JSON invalide, une coordonnée manquante, ou une coordonnée qui n'est pas un nombre fini, sans `as`.

<details>
<summary>Solution</summary>

[`solutions/l03_ex2_camera.ts`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/solutions/l03_ex2_camera.ts) :

```ts
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

// undefined quand rien d'utilisable n'est enregistré : l'appelant garde sa caméra par défaut
function restoreCamera(saved: string | null): CameraState | undefined {
  if (saved === null) return undefined;
  try {
    const value: unknown = JSON.parse(saved);
    return isCameraState(value) ? value : undefined;
  } catch {
    return undefined; // pas du JSON du tout
  }
}

const good = JSON.stringify({ px: 0, py: 50, pz: 300, lx: 0, ly: 0, lz: 0 });
console.log(restoreCamera(good));
console.log(restoreCamera(null), restoreCamera('{'), restoreCamera('{}'));
console.log(restoreCamera('{"px":0,"py":0,"pz":"300","lx":0,"ly":0,"lz":0}'));
```

```text
{ px: 0, py: 50, pz: 300, lx: 0, ly: 0, lz: 0 }
undefined undefined undefined
undefined
```

Copier l'objet dans un `{ [key: string]: unknown }` avec un *spread* est ce qui permet au prédicat de boucler sur les clés : on sait seulement que `value` est un `object`, qui n'a pas de signature d'index, et la copie en a une dont toutes les valeurs sont `unknown`. `Number.isFinite` rejette aussi `Infinity`, que `JSON.parse` renvoie pour un nombre trop grand pour un double, comme `1e999` dans une valeur de `localStorage` modifiée à la main.

</details>

3. Écris `toHealthStatus(text: string): GovernanceHealthStatus`, qui convertit `'ok'` en `'healthy'`, `'critical'` en `'error'` et tout ce qui est inattendu en `'unknown'`, ainsi qu'une table de prédictions dont `tsc` vérifie qu'elle est complète, sans chaîne de `if`.

<details>
<summary>Solution</summary>

[`solutions/l03_ex3_health.ts`](https://github.com/spareilleux/learn/blob/a504f1c0571aa8ed15a8d9ca81616b5f050bf8cc/code/typescript-for-csharp-java/solutions/l03_ex3_health.ts) :

```ts
// solutions/l03_ex3_health.ts
type GovernanceHealthStatus = 'error' | 'warning' | 'healthy' | 'unknown' | 'contradictory';

// La frontière : chaque chaîne que le serveur peut envoyer devient l'un des statuts que connaît le front end
function toHealthStatus(text: string): GovernanceHealthStatus {
  switch (text) {
    case 'healthy':
    case 'ok':
      return 'healthy';
    case 'warning':
      return 'warning';
    case 'error':
    case 'critical':
      return 'error';
    case 'contradictory':
      return 'contradictory';
    default:
      return 'unknown';
  }
}

// À l'intérieur, l'union dit vrai, et un Record indexé par elle doit lister chaque statut
const predictions: Record<GovernanceHealthStatus, string> = {
  healthy: 'stable',
  warning: 'at risk',
  error: 'failing',
  contradictory: 'uncertain',
  unknown: 'uncertain',
};

for (const text of ['ok', 'critical', 'warning', 'purple']) {
  const status = toHealthStatus(text);
  console.log(text.padEnd(9), status.padEnd(8), predictions[status]);
}
```

```text
ok        healthy  stable
critical  error    failing
warning   warning  at risk
purple    unknown  uncertain
```

Les chaînes du serveur sont traitées dans une seule fonction, dont le type de retour est l'union : à l'intérieur du programme, `status` ne peut être que l'une des cinq valeurs, et `predictions[status]` n'a besoin d'aucune valeur de repli. Un [`Record<GovernanceHealthStatus, string>`](https://www.typescriptlang.org/docs/handbook/utility-types.html#recordkeys-type) doit avoir une propriété pour chaque membre de l'union, donc un sixième statut ajouté au type fait de la table une erreur jusqu'à ce que quelqu'un décide de sa prédiction. La leçon 4 montre comment `Record` est construit.

</details>

## Sources

- [Manuel TypeScript — Narrowing](https://www.typescriptlang.org/docs/handbook/2/narrowing.html), [Types de tous les jours : types union et assertions de type](https://www.typescriptlang.org/docs/handbook/2/everyday-types.html#union-types), [Types utilitaires](https://www.typescriptlang.org/docs/handbook/utility-types.html)
- [Notes de version de TypeScript 3.7 — fonctions d'assertion](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-3-7.html#assertion-functions), [2.7 — inférence des littéraux objets](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-2-7.html#improved-type-inference-for-object-literals), [6.0 — `--stableTypeOrdering`](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html#the---stabletypeordering-flag)
- [Microsoft — expression switch](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/switch-expression), [opérateurs de test de type et de cast](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/type-testing-and-cast)
- [Java — classes et interfaces scellées](https://docs.oracle.com/en/java/javase/25/language/sealed-classes-and-interfaces.html), [pattern matching pour switch](https://docs.oracle.com/en/java/javase/25/language/pattern-matching-switch.html)
