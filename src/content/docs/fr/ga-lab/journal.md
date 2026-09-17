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
- [x] P7, modèle de jouabilité

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
| `barreRequired` est vrai pour un accord barré | Il demande la même frette sur trois cordes *adjacentes*, donc le barré de fa en forme de mi `133211` — cordes 1, 2 et 6 à la frette 1 — n'est pas un barré, alors que la forme de la `x13331` en est un | [`VoicingPhysicalAnalyzer.cs:219-233`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/Common/GA.Domain.Services/Fretboard/Voicings/Analysis/VoicingPhysicalAnalyzer.cs#L219-L233) | `133211` et le `xx3211` à quatre cordes sortent tous deux à exactement 4.50 | Reproduit (P7) |
| `minimumFingers` compte des doigts | Il compte des *frettes distinctes*, plafonnées à 4 | [`VoicingPhysicalAnalyzer.cs:102-103`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/Common/GA.Domain.Services/Fretboard/Voicings/Analysis/VoicingPhysicalAnalyzer.cs#L102-L103) | Am `x02210` et Am7 `x02010` sortent tous deux à 2.29 ; idem pour E contre E7 et D contre Dsus4 | Reproduit (P7) |
| L'étiquette `Difficulty` et le `DifficultyScore` s'accordent | La plage « Beginner » de l'étiquette demande un écart d'au plus 64 mm, moins de deux frettes près du sillet, si bien que l'accord de do à vide est « Intermediate » ; et `141404`, étiqueté « Advanced », sort à 4.65, le 26e centile de l'index | [`VoicingPhysicalAnalyzer.cs:105-112`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/Common/GA.Domain.Services/Fretboard/Voicings/Analysis/VoicingPhysicalAnalyzer.cs#L105-L112) | 3.50 et « Intermediate » pour `x32010` | Reproduit (P7) |
| Un voicing que personne ne peut jouer obtient un score élevé | 101 967 voicings de guitare sur 297 883 (34.2 %) n'ont aucun doigté légal sous un modèle de main à quatre doigts, et le score le plus élevé que GA donne à l'un d'eux est 7.73, dans la plage des accords ordinaires, donc `maxDifficulty: 8` les renvoie | [`VoicingFilterService.cs:53-70`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/Apps/ga-server/GaApi/Services/VoicingFilterService.cs#L53-L70) | La recherche de [`fingering.mjs`](https://github.com/spareilleux/learn/blob/main/code/ga-protos/p7-playability/src/lib/fingering.mjs) sur tout l'index | Reproduit (P7). Le modèle de main est le mien et n'a pas de pouce, donc 34.2 % est une borne supérieure |

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
| Un petit modèle entraîné sur un seul cœur de CPU peut-il battre le coût de jouabilité écrit à la main de GA ? | Douze chiffres commités dans [`hypotheses.md`](https://github.com/spareilleux/learn/blob/c6a9937/code/ga-protos/p7-playability/results/hypotheses.md) à `c6a9937` | Le boosting de gradient atteint un Spearman de 0.964 contre la cible et une exactitude par paires de 0.921, là où le score de GA atteint 0.596 et 0.715 ; une droite des moindres carrés sur le seul écart physique atteint 0.794 | Oui, mais la découverte est que les trois indicateurs supplémentaires de GA lui coûtent plus qu'ils ne lui rapportent (2026-09-17) |
| Combien des voicings de guitare de GA quatre doigts peuvent-ils jouer ? | H11 : plus de 98 % | 65.8 % : la recherche ne trouve aucun doigté légal pour 101 967 voicings sur 297 883 | Gravement réfutée, et cela a coupé le prototype en deux : une tâche de classement sur ce qui se joue, une question par oui ou non sur le reste (2026-09-17) |
| Séparer par voicing plutôt que par accord flatte-t-il le modèle ? | H6 : la séparation naïve surestime les arbres boostés de 0.005 à 0.05 de Spearman | 0.0005 ; la séparation par forme transposée le déplace de 0.002 | Réfutée. La séparation par groupe ne vous coûte quelque chose que si le groupe porte une information que les variables n'ont pas, et ici les deux côtés se lisent sur le même diagramme (2026-09-17) |
| La recherche de doigté est-elle assez coûteuse pour valoir la peine d'être remplacée par un modèle ? | H12 : le modèle note un voicing au moins 50 fois plus vite | 3.8 fois : 0.0145 ms contre 0.0558 ms | Réfutée. La prémisse du prototype était fausse ; ce que le modèle achète, ce sont 949 Ko qui s'embarquent sans le modèle de main (2026-09-17) |

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

## 2026-09-17 — P7 : l'étiquette qui n'existe pas

- La question est de savoir si un modèle bat le `DifficultyScore` de GA, et le score de GA ne peut pas être en même temps le corrigé. P7 construit donc une cible : [`fingering.mjs`](https://github.com/spareilleux/learn/blob/main/code/ga-protos/p7-playability/src/lib/fingering.mjs) énumère toutes les façons légales de poser les doigts 1 à 4 sur les notes frettées — n'importe quel doigt peut barrer, un barré peut ne tenir qu'une partie d'une frette et passer sous des notes plus hautes — et garde la moins chère. La géométrie des frettes et des cordes est celle de GA ; chaque poids est une constante que j'ai choisie et listée dans `WEIGHTS`.
- Trois vérifications sur cette cible, dont aucune n'est une preuve : 32 jugements par paires sur des formes canoniques dans [`annotations.json`](https://github.com/spareilleux/learn/blob/main/code/ga-protos/p7-playability/results/annotations.json), dont le fichier nomme l'annotateur (ce modèle-ci, à partir de règles écrites, pas un guitariste) ; une grille de ce que disent les méthodes ; et le score de GA lui-même. La recherche est d'accord avec les 25 paires à confiance élevée sur 25, GA avec 22, la grille avec 19. Le score parfait de la recherche mesure une cohérence interne — la même tête a écrit le modèle de main et le protocole — et le fichier le dit.
- Lire les cinq lignes de GA avant toute mesure a trouvé quatre choses, toutes dans le tableau QA ci-dessus : l'indicateur de barré rate le barré de fa, `minimumFingers` compte des frettes, un barré complet et un fa à quatre cordes sortent au même score, et l'étiquette `Difficulty` contredit le `DifficultyScore`.

## 2026-09-17 — P7 : hypothèses

- Douze prédictions numérotées dans [`results/hypotheses.md`](https://github.com/spareilleux/learn/blob/c6a9937/code/ga-protos/p7-playability/results/hypotheses.md), commitées dans `c6a9937` avant que `train.mjs` ait tourné sur la moindre donnée, synthétique ou réelle.
- H0 est marquée « vue, pas aveugle » : la vérification des annotations avait déjà tourné quand le fichier a été écrit, et ses trois nombres y sont consignés comme des mesures, pas comme des prédictions. Ils n'ont pas bougé quand la recherche a ensuite été généralisée.

## 2026-09-17 — P7 : ce que la recherche rejette

- La première version de la recherche n'autorisait que l'index à barrer, et seulement sur toutes les notes de la frette la plus basse. Elle rejetait 61.9 % de l'index guitare. En laissant n'importe quel doigt barrer, sur une partie d'une frette, en passant sous des notes plus hautes, on tombe à 34.2 % — 101 967 voicings sur 297 883 sans aucun doigté légal.
- Ce qui reste est vraiment injouable : `x12345` demande cinq doigts sur cinq frettes, et `103212` a deux notes à la frette 1 de part et d'autre d'une corde à vide, si bien qu'aucun des deux barrés qu'il faudrait n'est possible.
- Ces lignes n'ont pas de rang, donc l'expérience se coupe en deux : la tâche de classement les écarte, et un second modèle répond à la question de savoir si un voicing peut être doigté du tout. Séparation par accord, le boosting de gradient atteint une exactitude de 0.903 contre une référence majoritaire de 0.663, et une AUC de 0.973 ; le score de GA, lu comme un classement pour la même question, atteint 0.677.

## 2026-09-17 — P7 : mesures

- Un cœur d'un Intel Core Ultra 9 285K, Node.js v24.12.0, sans GPU, sans dépendances. 297 883 voicings, dont 195 916 doigtables, séparés par accord en 118 243 / 38 287 / 39 386. L'exécution complète — trois séparations, six prédicteurs chacune, intervalles par bootstrap sur 200 tours rééchantillonnés par accord, et le modèle de faisabilité — a pris 302 secondes ; construire le jeu de données depuis l'index de 183 Mo a pris 7.8 secondes.
- Spearman contre la cible, lignes réservées : boosting de gradient 0.964, MLP 0.959, forêt aléatoire 0.957, ridge 0.906, une droite sur le seul écart physique 0.794, le score de GA 0.596, la grille de règles 0.449, la moyenne 0. Exactitude par paires entre accords : 0.921 contre les 0.715 de GA.
- Les arbres boostés mettent 0.723 de leur gain sur `diagonalMm`, la paire de notes frettées la plus large mesurée *en travers* des cordes autant que le long du manche — et non l'écart le long du manche de GA, qui en détient 0.028. L'indicateur de barré de GA en détient 0.011 ; le modèle reconstruit les barrés à partir de `maxAtMinFret`, qui compte les cordes de la frette la plus basse sans demander si elles sont adjacentes, exactement le test que l'indicateur de GA rate.
- Tailles : 949 Ko pour 300 arbres boostés, 11.9 Mo pour 60 arbres de forêt profonds, 15.4 Ko pour le MLP, 1.24 Ko pour la ridge.
- Quatre prédictions fausses (H2, H6, H11, H12), deux à moitié justes (H9, H10). [Leçon](../07-playability-model/)
- Un bogue à retenir, trouvé par une séparation qui échouait : le premier hachage de groupe était un FNV-1a simple, dont les bits de poids fort bougent à peine entre `chord0` et `chord39`. Une séparation lit précisément ces bits de poids fort, si bien que les quarante accords atterrissaient dans le jeu d'apprentissage et que le jeu de test sortait vide. Un finaliseur murmur3 a corrigé cela, et un test vérifie désormais que les trois côtés reçoivent 60/20/20 de trois mille clés presque identiques.

## À vérifier

- L'explorateur sous Safari et Firefox sur macOS, avec et sans WebGPU : testé seulement dans Chromium sous Windows.
- Le son sur les navigateurs mobiles, qui peuvent bloquer l'`AudioContext` jusqu'à un toucher.
- La cible de P7 : les 32 jugements par paires ont été faits par ce modèle à partir de règles écrites, pas par un guitariste, et les constantes du modèle de main — écarts confortables, pénalités de barré et d'étouffement — sont choisies, pas mesurées sur un joueur. Un guitariste classant quelques centaines de paires remplacerait les deux.
- Les 34.2 % de voicings indoigtables de P7 sont une borne supérieure : la recherche n'a pas de pouce par-dessus le manche, pas de corde étouffée par la main gauche, et aucune note tenue par deux doigts.
