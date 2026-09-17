---
title: Journal
description: Notes datées du Laboratoire Guitar Alchemist — d'où viennent les données de chaque prototype, les hypothèses écrites avant de mesurer, ce qu'ont dit les mesures, et ce que le code de GA fait vraiment.
sidebar:
  order: 99
---

## Avancement

- [x] Squelette du laboratoire : mission, plan de sept prototypes, workflow de CI
- [x] P1, explorateur de l'espace des voicings : étape de construction, page, mesures, leçon
- [x] P2, joue un accord, vois l'univers
- [ ] P3, pochettes d'album
- [ ] P4, passe de rendu IA
- [ ] P5, bracelets imprimables en 3D
- [ ] P6, chaîne complète
- [ ] P7, modèle de jouabilité

## QA

Ce que le laboratoire a trouvé dans GuitarAlchemist/ga en mesurant, pas en lisant. Les numéros de ligne pointent sur [`66bdd049`](https://github.com/GuitarAlchemist/ga/tree/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e), le commit d'où l'index a été exporté. Aucun de ces points n'est encore un rapport de bogue : c'est ce que les mesures ont montré.

| Attendu | Ce qui se passe | Où | Mesure | État |
|---|---|---|---|---|
| L'index et les deux `FretDiagram` s'accordent sur la corde qui vient en premier | L'index écrit le diagramme mi aigu en premier ; les deux rendus le lisent mi grave en premier | [`FretDiagram.cs:14`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/Common/GA.Business.ML/Agents/FretDiagram.cs#L14), [`FretDiagram.tsx:8-11`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/ReactComponents/ga-react-components/src/components/FretDiagram.tsx#L8-L11) | La ligne 1000 donne `1-2-x-5-x-1` pour les notes MIDI 65, 61, 55, 41 ; 30 000 lignes échantillonnées se lisent mi aigu en premier, 0 désaccord | Reproduit, correction en préparation |
| Le `FretDiagram` React affiche toutes les notes frettées | Il perd un point quand la grille part du sillet et que le voicing atteint une case au-delà de la dernière rangée | [`FretDiagram.tsx`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/ReactComponents/ga-react-components/src/components/FretDiagram.tsx#L31), lignes 31 et 104 | 15 853 voicings de guitare sur 297 910, soit 5,32 % | Reproduit, correction en préparation |
| Le résumé d'`OptickIndexReader` décrit les vecteurs qu'il renvoie | Il dit « L2-normalized » ; chaque partition est normalisée, puis multipliée par la racine carrée de son poids | [`OptickIndexReader.cs`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/Common/GA.Business.ML/Search/OptickIndexReader.cs) | Norme au carré de 1,15 ou 1,05, jamais 1 | Reproduit. La documentation est fausse, le comportement est juste : le produit scalaire donne le cosinus pondéré par partition dont la recherche a besoin |
| Deux voicings qui sonnent et se doigtent différemment font deux points | Les voicings de mêmes classes de hauteur, de même note aiguë et de forme voisine s'effondrent sur un seul vecteur | [`OptickIndexWriter.cs`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/Demos/Music%20Theory/FretboardVoicingsCLI/OptickIndexWriter.cs) | 121 768 vecteurs de guitare sur 297 910 sont des copies bit à bit d'un autre, soit 40,9 % ; le plus gros groupe contient 12 voicings de fa dièse diminué avec la en haut | Reproduit. Conséquence du plongement plus que défaut évident — à arbitrer avant de changer quoi que ce soit |
| Le même commit exporte le même index | La déduplication garde le voicing le moins coûteux de chaque groupe, la génération est parallèle, et les égalités vont au premier arrivé | [`OptickIndexWriter.cs`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/Demos/Music%20Theory/FretboardVoicingsCLI/OptickIndexWriter.cs) | Deux exports d'une même construction : tous les vecteurs communs identiques, 70 voicings présents dans l'un et absents de l'autre | Reproduit. C'est l'empreinte du fichier qui fixe les données, pas le commit |
| `--export-max N` échantillonne l'index | L'option garde les N premiers voicings bruts dans l'ordre de génération, qui commence haut sur le manche | [`OptickIndexWriter.cs`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/Demos/Music%20Theory/FretboardVoicingsCLI/OptickIndexWriter.cs) | `--export-max 3000` a produit 2 641 vecteurs, dont 0 dans l'index complet | Reproduit. Un export partiel ne peut pas vérifier un export complet |
| Un accord avec basse nomme sa basse avec l'orthographe de la tonalité | Certains noms prennent la mauvaise enharmonie, par exemple `Gmaj7/Gb` au lieu de `Gmaj7/F♯` | noms d'accords de l'index | Vu en lisant les plus gros groupes de doublons | Reproduit, pas encore compté |

## Expériences

Chaque prototype écrit ses hypothèses avant que le script de mesure existe, et elles sont commitées les premières. Une hypothèse réfutée reste ici : c'est le résultat qui a coûté le plus cher à obtenir.

| Question | Hypothèse, écrite avant de mesurer | Résultat | Verdict |
|---|---|---|---|
| De combien de dimensions l'espace des voicings a-t-il vraiment besoin ? | Commitées dans [`hypotheses.md`](https://github.com/spareilleux/learn/blob/03f2bbb/code/ga-protos/p1-voicing-explorer/results/hypotheses.md) à `03f2bbb` ; le fichier dit laquelle n'était pas aveugle | 3 composantes expliquent 22,2 % de la variance, 10 en expliquent 48,0 %, 32 en expliquent 84,7 %, 64 en expliquent 99,9 % | Les deux premiers axes sont surtout MORPHOLOGY, le troisième STRUCTURE, CONTEXT ne pèse rien (2026-09-17) |
| Une vue 3D garde-t-elle les voisins que la recherche exacte trouve ? | H2 fixait un seuil de rappel@10 à 0,15 ; H3 prédisait que l'index complet ferait moins bien que l'échantillon | Rappel@10 de 0,168 dans l'échantillon de 30 000, 0,348 sur tous les voicings de guitare ; avec 32 composantes, 0,693 et 0,787 | H2 a manqué son seuil, H3 avait tort — les deux réfutées (2026-09-17) |
| WebGPU est-il plus rapide que WebGL 2 pour 300 000 points ? | Une première série disait 3,5 ms contre 0,5 ms et ressemblait à une découverte | Avec `trackTimestamp`, la passe de rendu prend 0,066 ms en WebGPU et 0,071 ms en WebGL 2 à 30 000 points, 0,26 ms pour les 297 910, 2,3 ms pour 3 millions de points aléatoires | La première série était une erreur de mesure : les 3,5 ms sont le temps que met `onSubmittedWorkDone` à se résoudre, pas du travail GPU. La leçon cite la seconde série (2026-09-17) |
| La sélection au CPU tient-elle à la taille de l'index complet ? | H6 attendait plus de 16 ms à 297 910 points | 0,2 ms pour 30 000, 1,4 ms pour 297 910, 14 ms pour 3 millions | H6 réfutée (2026-09-17) |
| Le navigateur peut-il tenir l'index entier ? | — | 156 Mo chargés et décodés en 341 ms, 180 Mo de tas JavaScript, 28 ms pour trouver les dix voisins exacts | Oui, et la leçon livre ce mode (2026-09-17) |
| Un chromagramme dans une page peut-il nommer l'accord que vous jouez ? | Huit chiffres prédits avant le moindre enregistrement | 79,3 % des 624 grattés de synthèse nommés exactement — 89,1 % à l'état fondamental, 50 % pour les renversements — et 11 des 17 enregistrements CC0 ; estimer les notes avant le chromagramme valait 39 points | Sept des huit chiffres ont tenu ; l'oracle, les conditions de bruit et les échecs enregistrés, non (2026-09-17) |

## 2026-09-16 — P1 : d'où viennent les données

- La branche `main` de GA était à [`66bdd049`](https://github.com/GuitarAlchemist/ga/tree/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e) (« chore(quality): snapshot 2026-09-16 »). L'index n'est pas dans le dépôt : `FretboardVoicingsCLI --export-embeddings` le génère dans `state/voicings/optick.index`.
- Je ne l'ai pas reconstruit. La session qui mesure les performances de GA avait compilé `FretboardVoicingsCLI` dans un clone propre à ce commit et exporté l'index entre 23 h 00 et 23 h 02, heure locale, en 149 secondes. Son journal dit « 688,351 raw, 313,047 unique ». J'ai copié ce fichier et je l'ai épinglé par son empreinte : 183 770 270 octets, SHA-256 `1e91e4695bab8aa4bb451fdd1f199a4afaa4c4ad913f08acc5163c6ab07caa23`, 313 047 voicings (297 910 pour la guitare, 7 795 pour la basse, 7 342 pour le ukulélé), 124 dimensions, empreinte de schéma `0x37cd8ecf`, celle que donne mon CRC-32 de `EmbeddingSchema.CompactLayoutV4`.
- La ligne 1000 tranche l'ordre des cordes. Son diagramme est `1-2-x-5-x-1` et ses notes MIDI sont 65, 61, 55, 41 : la corde 1 se lit en premier (mi aigu + 1 = fa 4, 65), pas le mi grave. Sur une grille d'accords, cette forme s'écrit `1x5x21`. L'étape de construction vérifie de la même façon les 30 000 lignes de l'échantillon : 0 écart.
- GA n'est pas d'accord avec lui-même sur ce point. [`FretDiagram.cs`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/Common/GA.Business.ML/Agents/FretDiagram.cs#L14) et le composant React [`FretDiagram.tsx`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/ReactComponents/ga-react-components/src/components/FretDiagram.tsx#L8-L11) prennent les cases mi grave en premier ; l'index les écrit mi aigu en premier. Le [cours sur l'IA de GA](../../ga-ai/02-optic-k-embeddings/) a trouvé la même divergence dans l'exemple d'un outil MCP.
- Les vecteurs de l'index ne sont pas de longueur 1, alors que le résumé d'`OptickIndexReader` dit « L2-normalized » : chaque partition est normalisée, puis multipliée par la racine carrée de son poids, si bien que le carré de la longueur d'un vecteur vaut la somme des poids de ses partitions non vides, 1,15 ou 1,05. Le produit scalaire reste le cosinus pondéré par partition, et c'est ce dont la recherche a besoin.

## 2026-09-16 — P1 : hypothèses

- Écrites dans [`results/hypotheses.md`](https://github.com/spareilleux/learn/blob/03f2bbb/code/ga-protos/p1-voicing-explorer/results/hypotheses.md) et commitées dans `03f2bbb`, avant que le script de mesure n'existe.
- L'une d'elles n'est pas aveugle, et le fichier le dit : un test rapide de l'étape de construction sur 2 000 voicings avait déjà affiché que trois composantes expliquent 22,2 % de la variance.

## 2026-09-17 — P1 : mesures

- Trois composantes principales expliquent 22,2 % de la variance, dix 48,0 %, 32 84,7 %, 64 99,9 %. Les deux premiers axes sont surtout MORPHOLOGY, le troisième STRUCTURE ; CONTEXT ne pèse rien.
- Rappel à 10 de la vue 3D face aux voisins exacts : 0,168 dans l'échantillon de 30 000, 0,348 face à toutes les voicings de guitare. Avec 32 composantes : 0,693 et 0,787. H2 a manqué son seuil de 0,15 ; H3, qui prédisait un résultat pire sur l'index complet, était fausse.
- 121 768 des 297 910 vecteurs de guitare sont des copies bit à bit du vecteur d'une autre voicing. Le plus grand groupe compte 12 voicings de fa dièse diminué avec la en haut. Des voicings aux mêmes classes de hauteur, à la même note aiguë et à la forme proche sont le même point pour OPTIC-K.
- Le composant React `FretDiagram` de GA perd un point pour 15 853 voicings de guitare (5,32 %) : la grille commence au sillet quand la note frettée la plus basse est en case 2, et une voicing qui monte jusqu'à la case 6 demande une sixième rangée.

## 2026-09-17 — P1 : deux exports, un seul commit

- La session de performance a exporté l'index une deuxième fois avec la même compilation. En appariant par instrument et par diagramme, chaque vecteur commun est identique, mais 70 voicings d'un export manquent dans l'autre : la déduplication garde la voicing la moins coûteuse de chaque groupe, le générateur tourne en parallèle, et à coût égal, la première arrivée gagne. C'est l'empreinte du fichier qui épingle les données, pas le commit.
- J'ai essayé de confirmer la provenance en régénérant 3 000 voicings de guitare avec l'outil de GA (`--export-max 3000`, 4,1 s sous le verrou des travaux lourds). Aucun de leurs 2 641 vecteurs ne se trouve dans l'index complet. La limite garde les 3 000 premières voicings brutes dans l'ordre de génération, qui commençait en case 19 ; dans ce petit ensemble, la déduplication a gardé des voicings haut sur le manche, qui perdent face à des formes moins coûteuses dans l'export complet. Un export partiel ne peut pas vérifier un export complet.

## 2026-09-17 — P1 : les temps d'image, mesurés deux fois

- Première série : `render()` plus `onSubmittedWorkDone`, 120 images en 1280 × 720 dans Chromium 153 sans interface, sur la RTX 5080. WebGPU donnait 3,5 ms pour 30 000 points et WebGL 2 0,5 ms. Cela ressemblait à une découverte, et c'était une erreur de mesure : le chiffre de WebGPU ne changeait pas entre 30 000 et 3 millions de points.
- Deuxième série, avec `trackTimestamp` et `resolveTimestampsAsync` de three.js : la passe de rendu prend 0,066 ms sur WebGPU et 0,071 ms sur WebGL 2 pour 30 000 points, 0,26 ms pour les 297 910, 2,3 ms pour 3 millions de points aléatoires. Les 3,5 ms sont le temps que met `onSubmittedWorkDone` à se résoudre, pas du travail du GPU.
- `renderer.info.render.drawCalls` affichait 434 puis des valeurs négatives dans la sonde, parce que three.js le remet à zéro à chaque image d'animation et que la sonde attend d'une image à l'autre. La leçon ne le cite pas.
- La sélection par projection de chaque point sur le CPU : 0,2 ms pour 30 000, 1,4 ms pour 297 910, 14 ms pour 3 millions. H6 attendait plus de 16 ms pour 297 910.
- Mode local sur l'index complet : 156 Mo chargés et décodés en 341 ms, 180 Mo de tas JavaScript, 28 ms pour trouver les dix voisins exacts d'une voicing dans le navigateur.

## 2026-09-17 — P1 : publication

- Le site n'avait pas encore de chaîne pour les démos en direct. `scripts/publish.mjs` construit la page avec Vite (`base: './'`) dans `public/ga-lab/p1/`, qu'Astro copie tel quel : 3,65 Mo, plus une capture d'écran de 241 Ko. La leçon montre la capture et un bouton, et ne charge la page dans une iframe qu'au clic, grâce à un petit composant `LazyDemo` qui ajoute le chemin de base du site.
- `scripts/check-published.mjs` sert `public/` sous `/learn/` comme GitHub Pages et ouvre la page publiée : WebGPU, 30 000 points, aucune erreur.

## 2026-09-17 — P2 : joue un accord, vois l'univers

- **P2 publié.** Le reconnaisseur nomme exactement 79,3 % de 624 grattés synthétiques (89,1 % à l'état fondamental, 50 % pour les renversements) et 11 enregistrements CC0 sur 17 ; estimer les notes avant le chromagramme vaut 39 points. Sept chiffres prédits sur huit ont tenu ; l'oracle, les conditions de bruit et les échecs enregistrés non. Le son ne quitte jamais la page (connect-src 'none'). [Leçon](../02-chord-universe/)

## À vérifier

- L'explorateur sous Safari et Firefox sur macOS, avec et sans WebGPU : testé seulement dans Chromium sous Windows.
- Le son sur les navigateurs mobiles, qui peuvent bloquer l'`AudioContext` jusqu'à un toucher.
