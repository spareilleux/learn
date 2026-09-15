---
title: Journal
description: Notes de progression datées du cours JavaScript — l'installation de Node.js 24.21.0, la CI sur trois OS, les surprises de Node.js et npm, ce qu'a montré le front end de GuitarAlchemist/ga, et les points à vérifier.
sidebar:
  order: 99
---

## Progression

- [x] Node.js 24.21.0 installé sous Windows, et en CI sous Linux, Windows et macOS avec .NET 10 et Java 25
- [x] CI : exemples, snippets d'erreur, solutions et comparaisons C# et Java comparés à leur sortie attendue sur trois OS
- [x] Leçon 1 : Node.js, npm et modules
- [x] Leçon 2 : valeurs et types
- [x] Leçon 3 : fonctions, portée, closures et `this`
- [x] Leçon 4 : objets, prototypes et classes
- [ ] Leçon 5 : tableaux, itération et collections

## 2026-09-14 — Installer Node.js 24.21.0

- L'[index des versions](https://nodejs.org/dist/index.json) liste 24.21.0, publiée le 2026-09-07, comme dernière version LTS, et 26.8.2 comme dernière version Current. Node.js 26 devient LTS le 2026-10-28, d'après le [calendrier](https://github.com/nodejs/Release/blob/main/schedule.json).
- Ma machine avait déjà un Node.js 24.12.0 global. Je n'y ai pas touché, j'ai téléchargé `node-v24.21.0-win-x64.zip` dans un dossier à part, vérifié son SHA-256 avec `SHASUMS256.txt`, et placé ce dossier en tête du `PATH` des shells qui capturent les sorties des leçons. `node -p process.versions.v8` affiche `13.6.233.17-node.53` ; le npm fourni est 11.19.0.
- Les commandes PowerShell de la leçon 1 ont téléchargé, vérifié et décompressé l'archive en 22 secondes, dans un dossier de travail.
- `winget show OpenJS.NodeJS.LTS` proposait 24.19.0, deux versions de retard sur nodejs.org.

## 2026-09-14 — La CI

- [`javascript-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/javascript-examples.yml) installe Node.js 24.21.0 avec `actions/setup-node@v7`, .NET 10 et Java 25, et exécute [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/javascript-for-csharp-java/check.sh). Le premier push est passé sur les trois OS en 1 minute 28 secondes : les 52 sorties capturées sous Windows sont identiques sous Linux et macOS.
- Node.js affiche des chemins absolus dans ses erreurs, sous forme d'URL de fichier, de chemin Windows, ou même de chemin Windows avec le préfixe de chemin long `\\?\`, comme dans le message sur `package.json` de la leçon 1. [`normalize.mjs`](https://github.com/spareilleux/learn/blob/main/code/javascript-for-csharp-java/normalize.mjs) les rend relatifs au dossier du cours, retire les frames de la pile et remplace les identifiants de processus.
- La comparaison C# affichait d'abord `1.0 / 0` sous la forme `∞`, le symbole de l'infini du format numérique de ma culture ; elle fixe maintenant `CultureInfo.InvariantCulture`, qui affiche `Infinity` sur toutes les machines. Java affichait l'emoji guitare sous la forme `?` dans la console Windows, donc les programmes de comparaison n'affichent que de l'ASCII.
- La CI installe aussi `@esbuild/win32-x64@0.25.12` comme dépendance de développement sur chaque OS, pour la leçon 1 : npm l'installe sous Windows et s'arrête avec `EBADPLATFORM` sous Linux et macOS.

## 2026-09-14 — Surprises en écrivant les leçons 1-4

**La suggestion « Did you mean to import » de Node.js dépend du dossier courant.** Un import de module ES sans son extension échoue avec `ERR_MODULE_NOT_FOUND`, et Node.js ajoute une suggestion avec le bon chemin, mais seulement quand la commande s'exécute depuis un dossier où ce chemin relatif existe aussi. `resolveAsCommonJS` crée un module parent CommonJS dont le nom de fichier n'est jamais renseigné ([`resolve.js`, lignes 888-895](https://github.com/nodejs/node/blob/v24.21.0/lib/internal/modules/esm/resolve.js#L888-L895)), et pour un parent sans nom de fichier le résolveur CommonJS cherche à partir de `'.'` ([`loader.js`, lignes 1021-1028](https://github.com/nodejs/node/blob/v24.21.0/lib/internal/modules/cjs/loader.js#L1021-L1028)). Le code est le même sur la branche `main` de Node.js. Je n'ai trouvé aucune issue à ce sujet en cherchant « Did you mean to import » dans nodejs/node. `check.sh` exécute les snippets d'erreur depuis leur propre dossier, et exécute celui-ci une seconde fois depuis le dossier du cours, sans la suggestion.

**Une fonction en double n'est une erreur qu'au niveau supérieur d'un module.** Deux déclarations `function describe` dans le même module ES sont une `SyntaxError` avant que quoi que ce soit s'exécute ; les deux mêmes déclarations dans le corps d'une fonction, ou au niveau supérieur d'un fichier CommonJS, sont acceptées, et la seconde l'emporte. J'avais écrit le doublon au niveau supérieur de l'exemple de la leçon 3 pour montrer le remplacement silencieux, et j'ai obtenu l'erreur à la place.

**`[1, 2, 3].map(multiply)` affiche `[ 0, 2, 6 ]`.** J'ai passé `multiply` à `map` comme exemple inoffensif du fait que les fonctions sont des valeurs, et `map` a passé l'indice comme second argument. L'exemple est resté dans la leçon 3, comme le piège qu'il est, à côté de `['1', '2', '3'].map(parseInt)`.

**`npm init -y` écrit `"type": "commonjs"`.** npm 11.19 ajoute le champ explicitement ; les anciens modèles l'omettaient, ce qui rendait de toute façon les fichiers `.js` CommonJS par défaut.

**Un fichier `.cjs` avec `import` reçoit un conseil qui ne s'applique pas.** Node.js affiche `Warning: Failed to load the ES module … Make sure to set "type": "module" in the nearest package.json file or use the .mjs extension`, puis la `SyntaxError`. Le champ `"type"` ne peut rien pour un fichier `.cjs` : son extension l'emporte.

**`require` d'un module ES fonctionne sans avertissement.** Node.js 24.21.0 charge `modern.mjs` depuis `from-cjs.cjs` en silence ; la [documentation](https://nodejs.org/docs/latest-v24.x/api/modules.html#loading-ecmascript-modules-using-require) indique que la fonctionnalité a cessé d'être expérimentale en 24.15.0. Avec un `await` au niveau supérieur dans le module, `require` lève `ERR_REQUIRE_ASYNC_MODULE`, ce que j'ai vérifié pour la solution de l'exercice 1.

**pnpm ne vérifie pas la plateforme d'une dépendance directe.** Dans un projet de test sous Windows, `npx pnpm@10 add -D @esbuild/linux-x64@0.25.12` a installé le package Linux sans avertissement (pnpm 10.34.5), là où npm le refuse avec `EBADPLATFORM`.

## 2026-09-14 — Ce qu'a montré le front end de GuitarAlchemist/ga (a826864)

J'ai lu [`ReactComponents/ga-react-components`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components) et [`Apps/ga-client`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/ga-client) au commit [`a826864`](https://github.com/GuitarAlchemist/ga/commit/a826864f3a012cad88e415954bf57eca0ce12aa6), à la recherche des pièges des leçons 1 à 4.

- **Deux fichiers de verrouillage.** `Apps/ga-client` a un `package-lock.json` et un `pnpm-lock.yaml` ; rien ne maintient les deux résolutions d'accord.
- **Un package réservé à Windows dans `devDependencies`.** [`ga-react-components/package.json`, ligne 71](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/package.json#L71) liste `@esbuild/win32-x64`. La CI du cours montre que npm refuse ce package précis sous Linux et macOS ; le dossier n'a qu'un `pnpm-lock.yaml`, et pnpm a installé sans broncher un package d'une plateforme étrangère sur ma machine, donc le projet s'installe probablement avec pnpm partout (*à vérifier* sous Linux).
- **Un état sauvegardé qui l'emporte sur l'URL.** Dans [`SceneOptions.tsx`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/PrimeRadiant/SceneOptions.tsx#L57-L80), les paramètres de l'URL sont appliqués avant qu'`Object.assign` fusionne les préférences sauvegardées dans `localStorage`, et chaque bascule sauvegarde toutes les clés. Après la première bascule, `?tower`, `?constellations`, `?weather`, `?skybox` et `?splats` ne changent plus rien. La fusion garde aussi les clés inconnues et les valeurs du mauvais type, et une clé `__proto__` remplace le prototype de l'objet d'état. La leçon 4 reproduit les trois, et son exercice 3 les corrige. Cela ressemble à un bug qui mérite une issue.
- **`|| 0.5` là où `??` est voulu.** [`BSPDoomExplorer.tsx`, ligne 4895](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/BSP/BSPDoomExplorer.tsx#L4895) transformerait une vitesse de rotation de 0 en 0,5. Aucun échantillon ne reçoit une vitesse de 0 aujourd'hui, donc le bug est latent. La [ligne 5386](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/BSP/BSPDoomExplorer.tsx#L5386) fonctionne parce que `NaN` est falsy, pas grâce au regroupement qu'elle semble avoir.
- **Les écouteurs d'événements sont corrects.** Les sept appels à `addEventListener` des deux front ends qui passent un gestionnaire `this.…` utilisent soit une fonction liée une fois et stockée, soit une fonction fléchée stockée dans un champ, et aucun ne fait de `bind` en ligne ; la leçon 3 exécute les trois patterns.
- **L'égalité faible seulement pour `null`.** Les sources TypeScript n'utilisent `==` et `!=` que sous la forme `== null` et `!= null` ; les autres occurrences sont du code de shader GLSL dans des chaînes. Leurs configurations ESLint étendent `js.configs.recommended`, qui n'active pas `eqeqeq`.
- **`parseInt` sans base**, dans [`BSPDoomExplorer.tsx`, ligne 2421](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/BSP/BSPDoomExplorer.tsx#L2421) et [`MusicRoomLoader.ts`, lignes 209-211](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/ReactComponents/ga-react-components/src/components/BSP/MusicRoomLoader.ts#L209-L211). Les entrées sont des chiffres décimaux tirés d'un nom ou d'une correspondance d'expression régulière, donc c'est sans danger à ces endroits.

## À vérifier

- Les commandes d'installation que je n'ai pas exécutées : `winget install OpenJS.NodeJS.LTS`, nvm sous Linux, et le `node@24` de Homebrew sous macOS.
- Si `pnpm install` de `ga-react-components` réussit sous Linux et macOS avec `@esbuild/win32-x64` dans ses dépendances de développement.
