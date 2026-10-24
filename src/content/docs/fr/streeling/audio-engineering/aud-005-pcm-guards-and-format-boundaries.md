---
title: Contrôles PCM et frontières de format dans le laboratoire de guitare
description: Contrôles PCM et frontières de format dans le laboratoire de guitare — Ingénierie audio
sidebar:
  label: AUD-005 · Contrôles PCM et frontières de format dans le laboratoire de guitare
  order: 5
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/audio-engineering/fr/aud-005-pcm-guards-and-format-boundaries.fr.md
---

:::note[Streeling University]
**AUD-005** · Contrôles PCM et frontières de format dans le laboratoire de guitare · intermédiaire · 45 minutes

Généré par le département *Ingénierie audio* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/audio-engineering/fr/aud-005-pcm-guards-and-format-boundaries.fr.md) · [Mon journal](../../journal/)

Prérequis: [AUD-002](../../audio-engineering/aud-002-level-matched-guitar-comparison/)
:::

Un fichier audio qui s'ouvre correctement peut masquer une chaîne de mesure défectueuse. Une conversion peut effacer de petites différences, un décodeur d'entrée peut supposer le mauvais encodage et un processus terminé avec succès peut signaler l'échec d'un candidat. Ce cours s'appuie sur l'expérience réelle du moteur de guitare GA pour transformer ces risques en contrôles vérifiables avant de soumettre un autre réglage de décroissance à une comparaison à l'écoute.

À la fin, vous saurez suivre les échantillons bruts jusqu'au WAV, expliquer chaque contrôle, distinguer une erreur de format d'entrée d'un défaut du moteur et rédiger une conclusion aux limites explicites. Le livrable est une courte note de revue citant les preuves fournies, avec une décision sur le candidat et la liste des validations restantes.

## Définir le périmètre de l'expérience

Le [README du laboratoire](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/README.md) décrit la compilation pédagogique. [Rust](https://doc.rust-lang.org/rustc/command-line-arguments.html) compile le moteur épinglé, sans modification, pour une exécution native et pour la [cible WebAssembly](https://doc.rust-lang.org/rustc/platform-support/wasm32-unknown-unknown.html) ; [Node.js](https://nodejs.org/en/learn/getting-started/nodejs-with-webassembly) héberge cette dernière. Consultez le [manifeste des sources](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/source.json) et la [vérification des entrées publiques](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/guitar-runtime-2026-10-22/public-input-readback.json) avant de prendre un nom de fichier pour une preuve de provenance. Le code du moteur et sa licence sont épinglés ; les options de compilation pédagogiques ne reproduisent pas le profil de livraison amont.

L'expérience démarre un profil neuf sur E2, avec une fréquence demandée de 82.4069 Hz et une vélocité de 0.1. La décroissance de référence vaut 0.9978 ; celle du candidat vaut 0.9976. Les deux produisent un signal mono de 4 secondes à 44100 Hz. Ces réglages définissent l'observation, sans constituer une promesse pour chaque note, vélocité, profil, compilateur ou hôte audio. Windows x64 a été testé. Linux/WSL et macOS restent à vérifier.

## Contrôler les échantillons avant de réduire leur précision

Suivez [le programme d'exécution](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/run.mjs) depuis le rendu, en passant par `pcmGuard`, jusqu'à `pcm16Wav`. Chaque tampon brut principal doit contenir 176400 échantillons. Un échantillon occupe 4 octets en virgule flottante, en ordre petit-boutiste ; la taille brute attendue est donc de 705600 octets. Le contrôle compare d'abord le nombre exact d'octets, exige ensuite `Number.isFinite(sample)`, puis vérifie `Math.abs(sample) <= 1`. Cet ordre signale un défaut de structure dans un tampon tronqué avant la boucle et rend les valeurs numériques invalides visibles avant la conversion entière.

L'encodeur utilise `Math.round(sample * 32767)`. Les données entières mono occupent 352800 octets ; l'en-tête de 44 octets porte le WAV généré à 352844 octets. Le décodeur lit ces échantillons entiers avec `payload.readInt16LE(i * 2) / 32767`. Consignez cette convention : conversion et décodage font partie de la méthode de mesure. Les empreintes brutes et les empreintes WAV répondent à des questions différentes.

Le code source termine le rendu par un écrêtage strict. C'est un élément utile, mais cet écrêtage ne suffit pas à établir que des entrées `NaN` arbitraires produisent une sortie finie. Ici, l'observation repose sur la vérification de chaque échantillon produit dans l'expérience définie. Élargir les entrées couvertes demande un autre test explicite, plutôt qu'une extrapolation à partir d'un commentaire sur la normalisation de la sortie.

Les [résultats](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/guitar-runtime-2026-10-22/results.json) donnent des crêtes brutes de 0.4601604640483856 pour la référence et de 0.46006888151168823 pour le candidat dans les deux environnements d'exécution. Elles sont inférieures à la marge de 0.95 proposée dans GAS-003. Cela étaye le contrôle de crête pour ce rendu ; cela ne démontre ni un son réaliste ou agréable, ni l'absence de tout défaut audible.

## Vérifier que le contrôle rejette effectivement

La réussite sur des tampons ordinaires montre seulement qu'ils sont acceptés. Le programme fournit aussi des entrées volontairement invalides et impose leur rejet par des assertions. Un échantillon `NaN` atteint le contrôle de finitude. Un échantillon de 1.01 atteint le contrôle de plage normalisée. Un tampon tronqué de 3 octets échoue au contrôle du nombre attendu. Ces témoins négatifs rendent chaque voie d'échec observable ; ils ne couvrent pas toutes les corruptions possibles.

Les sondes de silence sur des instances neuves contiennent 4096 échantillons et ont une crête de 0 en natif comme en WASM. Cela constitue une preuve pour ces instances sans événement de note. Cela ne certifie ni un hôte audio complet, ni l'ordonnancement du navigateur, la durée de vie de la mémoire, l'annulation ou le silence après une activité quelconque. Indiquez l'état initial de la sonde dans la note de revue.

## Laisser l'entrée mettre le décodeur à l'épreuve

L'enregistrement de référence a révélé une erreur concrète de préparation : le décodeur initial n'acceptait que le WAV PCM16 entier et rejetait le WAV IEEE float32 fourni, dont l'identifiant de format est 3. La correction ajoute une branche de format explicite tout en conservant les contrôles de canal, de fréquence d'échantillonnage, de blocs et de valeurs finies. Le code du moteur n'a pas changé. Qualifier ce problème d'échec de synthèse aurait orienté l'enquête vers la mauvaise couche.

L'enregistrement reste dans un cache externe et n'est pas copié dans le dépôt. Crédit : **collegefishiesd**, avec la révision du jeu de données et l'attribution dans le manifeste ; sa licence est [CC BY-SA4.0](https://creativecommons.org/licenses/by-sa/4.0/). L'[attribution épinglée](https://github.com/GuitarAlchemist/Demerzel/blob/5c4967454ddc740ed937c87719ca4d71a3522e4b/state/streeling/fixtures/guitar-acoustics/gas-001/README.md) décrit la donnée de test. Son SHA256 est `03a1965f275f0858be70476dab2bf55d2cbf2272ef7a50c61453d45e7f38b248`. Préservez cette identité en corrigeant le décodeur ; remplacer discrètement l'enregistrement change l'expérience.

## Distinguer un artefact valide d'un candidat accepté

Les échantillons bruts natifs et WASM diffèrent, alors que les octets WAV PCM16 sont identiques pour chacun des réglages. La quantification peut associer des flottants distincts au même entier. Des empreintes WAV identiques ne prouvent donc ni l'égalité des échantillons d'origine ni leur équivalence perceptive. Le WAV de référence généré correspond aussi à l'empreinte de l'ancienne donnée publique, ce qui établit la continuité de cet artefact précis.

Lisez la [reprise des mesures primaires](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/guitar-runtime-2026-10-22/primary-measurement-replay.json), les [mesures de référence](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/guitar-runtime-2026-10-22/baseline-primary-measurements.json) et les [mesures du candidat](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/guitar-runtime-2026-10-22/candidate-primary-measurements.json). La méthode primaire inchangée a été réexécutée sur les WAV natifs générés. Le candidat améliore l'erreur de décroissance de 0.11416614959438576 dB pour un minimum requis de 1 dB ; `candidate_passes_decline_gate` vaut donc `false`. Le code de sortie 0 signifie que l'exécution et les assertions sont terminées ; il ne vaut pas acceptation du produit. La revue humaine et la publication restent en attente, sans résultat d'écoute ni capture du navigateur.

Pour une reproduction ultérieure avec les outils documentés déjà installés, exécutez depuis la racine du dépôt :

```text
node code/streeling/guitar-runtime/run.mjs <new-output-directory> <recorded-wav-path>
```

Remplacez les deux paramètres fictifs. La commande s'écrit de la même façon sur les systèmes pris en charge, mais seule la plateforme consignée a été testée. Lisez les preuves avant de décider de relancer l'expérience.

## Exercices

### Exercice A — Auditer le contrat du tampon

Expliquez la taille brute et celle du WAV généré, puis repérez le rejet d'un tampon trop court.

> **Réponse :** Le rendu contient 176400 échantillons, soit 705600 octets bruts. La conversion entière produit 352800 octets de données ; l'en-tête de 44 octets donne 352844 octets WAV. `pcmGuard` rejette un nombre d'octets inattendu avant de lire les échantillons.

### Exercice B — Expliquer un rejet

Associez les témoins `NaN`, 1.01 et 3 octets aux contrôles prévus. Pourquoi tous les conserver ?

> **Réponse :** Ils vérifient respectivement la finitude, la plage normalisée et le nombre exact. Chacun protège une hypothèse différente avant l'encodage ; le seul succès du témoin de plage laisserait les autres voies sans test.

### Exercice C — Rédiger le diagnostic de format

L'entrée échoue avec le décodeur initial. Décrivez la correction sans prétendre réparer le moteur.

> **Réponse :** L'enregistrement est un WAV IEEE float32 portant l'identifiant de format 3. Ajoutez le décodage explicite du format fourni et conservez la validation ainsi que l'empreinte d'entrée. La sortie générée est du PCM16 entier ; les échantillons des deux conteneurs doivent être interprétés différemment.

### Exercice D — Interpréter des octets WAV identiques

Des empreintes WAV natives/WASM identiques permettent-elles de clore un signalement de différences brutes ?

> **Réponse :** Elles établissent l'égalité après cette conversion. La quantification perd de l'information ; la différence brute reste donc réelle. Ni l'égalité des octets ni la faible différence brute ne constituent un verdict d'écoute.

### Exercice E — Rédiger la décision

Formulez le verdict du candidat à partir du statut du processus, de la crête et du critère de décroissance.

> **Réponse :** L'exécution s'est terminée et les contrôles d'échantillons testés ont réussi, mais le candidat a échoué au critère déclaré d'amélioration de la décroissance. Ne l'acceptez pas. Demandez les revues humaines et perceptives restantes avant publication ; la sonde de silence ne certifie pas un hôte audio entier.
