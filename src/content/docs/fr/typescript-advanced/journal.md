---
title: Journal
description: Notes de progression datées du cours TypeScript avancé — le projet du cours sous TypeScript 7.0.2, les limites du vérificateur mesurées, les prédictions que les tests de types ont démenties, le côté C# et Java, les tailles de bundle, ce que les leçons ont trouvé dans GuitarAlchemist/ga, et les points à vérifier.
sidebar:
  order: 99
---

## Progression

- [x] Le projet du cours : TypeScript 7.0.2, Zod 4.6.5, Valibot 1.5.0, ArkType 2.2.3 et esbuild 0.28.2 épinglés dans son propre `package.json` et son propre fichier de verrouillage
- [x] `check.sh` : tests de types, extraits d'erreur, exemples et solutions exécutés avec Node.js 24.21.0, tailles de bundle, comparaisons C# et Java, le tout comparé avec `expected/`
- [ ] CI sous Linux, Windows et macOS
- [x] Leçon 1 : programmation au niveau des types
- [x] Leçon 2 : variance et assignabilité
- [x] Leçon 3 : modéliser avec les types
- [x] Leçon 4 : frontières à l'exécution
- [ ] Leçon 5 : fichiers de déclaration

## 2026-09-15 — Le projet du cours

- Le cours a son propre [`package.json`](https://github.com/spareilleux/learn/blob/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/package.json), distinct de celui du cours de base, avec les mêmes versions de TypeScript et de Node.js : 7.0.2 et 24.21.0. Le [`tsconfig.json`](https://github.com/spareilleux/learn/blob/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/tsconfig.json) ajoute `exactOptionalPropertyTypes` et `noUncheckedIndexedAccess` à `strict`, puisque la leçon 2 dépend de la première, et garde `erasableSyntaxOnly` pour que Node.js exécute chaque exemple directement, sans étape de build.
- Les tests de types vivent dans les exemples : des lignes `type _1 = Expect<Equal<…>>` que `tsc` vérifie avec tout le projet. Une prédiction fausse fait échouer `check.sh` avant que quoi que ce soit ne s'exécute, ce qui est arrivé plusieurs fois pendant l'écriture des leçons 1 à 3, comme le liste la suite.
- `check.sh` est le script du cours de base avec deux ajouts : [`bundle-size.mjs`](https://github.com/spareilleux/learn/blob/d039c6a49edd3fac4b6bf6003260282e3f77119d/code/typescript-advanced/bundle-size.mjs), dont la sortie est comparée comme les autres, et des comparaisons C# qui référencent ASP.NET Core avec `#:sdk Microsoft.NET.Sdk.Web`.
- Le dépôt de GA ne s'extrait pas entièrement sous Windows : les dossiers `test-results/` de Playwright sont commités, avec des chemins de plus de 260 caractères. Un clone partiel (*sparse*) des dossiers qu'utilisent les leçons, avec `git config core.longpaths true`, fonctionne.

## 2026-09-15 — Les limites du vérificateur, mesurées

- Les limites sont des constantes de [`internal/checker/checker.go`](https://github.com/microsoft/typescript-go/blob/2bd066d87f5bafd315be9f40889d0a60b9e58e0b/internal/checker/checker.go) : 100 instanciations imbriquées et 5 000 000 dans une même expression, 1 000 étapes pour un type conditionnel récursif terminal, et 100 000 membres pour une union construite par un produit cartésien.
- Les mesures concordent : un constructeur de tuple récursif terminal atteint 999 éléments et échoue à 1 000 avec `TS2589` ; une union de cinq positions de chiffres, 100 000 chaînes, échoue avec `TS2590`.
- Un `Reverse` qui n'est pas récursif terminal est plus difficile à prédire. Seul dans son fichier, 48 éléments passent et 49 échouent. Avec un `Reverse` de 40 éléments évalué d'abord dans le même fichier, 80 éléments passent : les instanciations sont mises en cache, et la seconde évaluation part des résultats de la première. Une limite au niveau des types mesurée dans un fichier n'est pas une limite pour un autre fichier.

## 2026-09-15 — Les prédictions que les tests de types ont démenties

- Je m'attendais à ce que `satisfies Record<GovernanceHealthStatus, HexColor>`, où `HexColor` est un *template literal type*, élargisse les couleurs en `string`. Il garde les types littéraux : un *template literal type* utilisé comme type contextuel compte comme un contexte littéral, et seul un type contextuel comme `string` les élargit.
- Je m'attendais à ce qu'un paramètre de type `const` avec une contrainte de tableau mutable se rabatte sur `string[]`. C'était le comportement de 5.0 à 5.2 ; depuis 5.3, il infère un tuple mutable. J'ai vérifié avec `npx -p typescript@5.0.4`, `5.2.2` et `5.3.3`.
- Je m'attendais à ce que `in out T` sur un type qui ne fait que lire `T` soit refusé. Il est accepté : `in out` rend un type invariant, ce qui est toujours sûr, et seule une annotation qui contredit la structure, comme `in` sur un type qui renvoie `T`, est une erreur (`TS2636`).
- Dans la première version de la machine à états de la leçon 3, une fonction `stopFrom` utilisait `as` pour que `send(state, 'stop')` compile pour n'importe quel état. Le test de types que j'ai ajouté ensuite a montré que `EventOf<LiveState>` est `never` : l'assertion cachait que l'état `stopped` n'a pas d'événement `stop`. La fonction prend maintenant `Exclude<LiveState, 'stopped'>`, sans assertion.
- Un littéral objet affirmé avec `as` vers un type dont il n'a pas toutes les propriétés n'est pas toujours accepté : directement, `tsc` signale `TS2352` ; en passant par une variable, les types sont comparables et cela compile. La leçon 2 montre la seconde forme, qui est celle qu'on trouve dans du vrai code.

## 2026-09-15 — Le côté C# et Java

- `dotnet run file.cs` sur un fichier qui sérialise un type anonyme a échoué avec « Reflection-based serialization has been disabled for this application ». Les applications basées sur un fichier sont publiées en AOT natif par défaut, et ce réglage désactive aussi le JSON par réflexion à l'exécution ; `#:property PublishAot=false` dans le fichier le rétablit.
- `JsonHubProtocol` peut s'utiliser sans serveur : `WriteMessage` sur un `InvocationMessage` donne le texte exact qu'envoie SignalR, ce qui a établi ce que le hub de GA met sur le fil sans avoir à le démarrer.
- `RespectNullableAnnotations` et `RespectRequiredConstructorParameters` de `System.Text.Json`, tous deux de .NET 9, sont désactivés par défaut ; avec eux, le record C# est un schéma.

## 2026-09-15 — Les tailles de bundle

- Le même schéma Zod, mis en bundle par esbuild, pèse 442,7 kB minifié avec `import { z } from 'zod'` et 87,4 kB avec `import * as z from 'zod'`. La différence tient au *tree shaking* : `z` est un objet qui référence toutes les fonctions. La leçon 4 garde la forme avec l'espace de noms, qui est aussi celle de la documentation.
- Valibot, 4,8 kB minifié, est environ 18 fois plus petit que Zod pour ce schéma, et `zod/mini` environ 5 fois.
- Les tailles sont mesurées sous Windows. La sortie d'esbuild ne dépend pas de l'OS, et la CI les compare sous Linux et macOS (*à vérifier* une fois que le workflow aura tourné).

## 2026-09-15 — Ce que les leçons ont trouvé dans GuitarAlchemist/ga

Au commit [`32f143c`](https://github.com/GuitarAlchemist/ga/tree/32f143c866c126338b332e384e4a615cd4b44381), dans `ReactComponents/ga-react-components` et `Apps/ga-server/GaApi/Hubs` :

- **Une mise à jour `NodeChanged` perdue** (leçon 4). Le hub envoie `nodeId` ; le client affirme que le message est un `GovernanceNode`, dont la clé est `id` ; `updateNodeHealth` cherche le nœud par `id` et abandonne la mise à jour en silence. Une recherche dans le code ne trouve aucun appelant de `BroadcastNodeChanged`, donc le bug est latent.
- **Aucun contrat partagé entre le hub et le client** (leçon 1). Le hub dérive de `Hub`, pas de `Hub<T>`, et envoie les noms de méthodes sous forme de chaînes ; le client enregistre dix handlers avec des chaînes. Le commentaire de documentation du hub liste un événement `HealthUpdate` qu'il n'envoie jamais, et l'option `onScreenshotRequest` du client gère l'événement `RequestScreenshot`.
- **`ViewerInfo.displayName`** (leçon 2) est déclaré `displayName?: string` en TypeScript et envoyé comme `null` par le record C# ; le code fonctionne parce que chaque lecture utilise `?.` ou `??`.
- **Deux numérotations des cordes** (leçon 3) : quatre interfaces nommées `FretboardPosition`, toutes avec `string: number` ; `InstrumentConfig.ts` et `GuitarFretboard.tsx` comptent les cordes à partir de 0, tandis que `VexTabViewer.tsx` et `InverseKinematics.tsx` prennent des numéros de corde à partir de 1.
- **L'état vocal de `ChatWidget.tsx`** (leçon 3) : `isListening` et `voiceState` peuvent se contredire ; `startListening` lit `voiceState` sans le lister dans les dépendances de son `useCallback`, donc ses vérifications `voiceState === 'listening'` voient une valeur périmée ; `sendMessage(…).then(…)` n'a pas de `catch`, et une requête échouée peut laisser l'état à `'processing'`.
- **Des frontières non vérifiées** (leçon 4) : 42 appels à `JSON.parse`, 55 lignes qui affirment le type de `response.json()` avec `as`, et 34 `as unknown as`, en dehors des tests.

Je n'ai pas signalé ces points au dépôt de GA ; ils sont listés ici tels que je les ai trouvés.

## À vérifier

- Le chemin de `NodeChanged` sur un serveur en marche, si quelque chose se met à appeler `BroadcastNodeChanged`.
- Le `voiceState` périmé dans `ChatWidget.tsx`, dans un navigateur avec reconnaissance vocale : une erreur pendant l'écoute devrait laisser l'indicateur sur `'listening'`.
- Les sorties du cours sous Linux et macOS, une fois que le workflow de CI aura tourné.
