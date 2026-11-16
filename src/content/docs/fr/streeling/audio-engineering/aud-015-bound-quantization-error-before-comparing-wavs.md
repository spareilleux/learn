---
title: Borner l’erreur de quantification avant de comparer des WAV
description: Borner l’erreur de quantification avant de comparer des WAV — Ingénierie audio
sidebar:
  label: AUD-015 · Borner l’erreur de quantification avant de comparer des WAV
  order: 15
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/audio-engineering/fr/aud-015-bound-quantization-error-before-comparing-wavs.fr.md
---

:::note[Streeling University]
**AUD-015** · Borner l’erreur de quantification avant de comparer des WAV · intermédiaire · 55 minutes

Généré par le département *Ingénierie audio* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/audio-engineering/fr/aud-015-bound-quantization-error-before-comparing-wavs.fr.md) · [Mon journal](../../journal/)

Prérequis: [AUD-005](../../audio-engineering/aud-005-pcm-guards-and-format-boundaries/)
:::

> Exemple construit et lecture de sources. Aucune nouvelle prestation, exécution audio ou de parseur, réponse de participant ni adoption en production n’est revendiquée. Les décisions techniques humaines, linguistiques et pédagogiques restent en attente.

Le programme de guitare conservé garde les échantillons flottants bruts et écrit aussi un WAV entier. Il s’agit de représentations différentes du rendu proposé. Un écart dans les tampons bruts peut disparaître lors de la conversion ; un petit écart décodé peut aussi venir de cette conversion. Avant de conclure à l’équivalence des moteurs, un agent doit identifier le quantificateur, son arrondi et les hypothèses de la borne d’erreur.

## Lire les preuves conservées

Lire l’expression réelle `pcm16Wav` et son décodeur dans l’artefact conservé. L’encodeur multiplie par `32767` et utilise `Math.round` ; le décodeur divise l’entier signé stocké par la même échelle. C’est une observation du code à la révision conservée. La leçon étudie cette convention, sans lui substituer une échelle habituelle ni prétendre couvrir tous les formats WAV.

[Prérequis](../../audio-engineering/aud-005-pcm-guards-and-format-boundaries/)

[Artefact de projet conservé](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/run.mjs)

[Dossier construit fixe](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/journal.md)

### Exercice 1

Définir `q=floor(scale*x+0.5)` avec `scale=32767`, conformément à l’arrondi choisi pour ces cas finis. Deux niveaux décodés adjacents diffèrent de `1/32767`. Si l’arrondi reste représentable et sans écrêtage, l’erreur absolue ne dépasse pas `1/65534`. Cette borne porte sur l’amplitude normalisée, pas sur une fréquence ou une durée.

Quels sont le pas de quantification et la borne de demi-pas ?

<details><summary>Réponse 1</summary>

Ils valent `1/32767` et `1/65534`. La borne concerne la conversion déclarée vers le niveau le plus proche, sans écrêtage, pas des entrées invalides.

</details>

### Exercice 2

Les échantillons construits sont `[0,0.00001,0.5,-0.5]`. Leurs entiers codés sont `[0,0,16384,-16383]`. Les deux demi-amplitudes révèlent la règle aux égalités : les cas médians positifs et négatifs ne produisent pas des entiers symétriques. Remplacer discrètement cette règle par l’arrondi au pair reviendrait à vérifier un autre convertisseur.

Coder les échantillons et expliquer l’asymétrie aux points médians.

<details><summary>Réponse 2</summary>

Les entiers sont `[0,0,16384,-16383]`. L’arrondi des égalités vers l’infini positif donne cette paire ; la règle retenue fait partie du contrat du code.

</details>

### Exercice 3

Décoder en divisant par `32767`. Le petit échantillon positif devient exactement `0`, avec une erreur signée de `-0.00001`. Les demi-amplitudes ont pour erreurs `16384/32767-0.5` et `-16383/32767+0.5`. Elles respectent le demi-pas déclaré. Disparaître après conversion signifie que la représentation entière ne résout pas cette différence, pas que les flottants étaient identiques.

Que perd-on lorsque le petit échantillon devient nul ?

<details><summary>Réponse 3</summary>

Son amplitude flottante non nulle est perdue à cette frontière. L’erreur est `-0.00001` ; l’égalité entière ultérieure ne prouve pas l’égalité flottante antérieure.

</details>

### Exercice 4

Le contrôle négatif fournit `1.1`, hors du contrat normalisé. L’expression donne l’entier `36044`, non représentable dans le champ entier signé de cette largeur. Le contrôle conservé rejette les amplitudes hors plage avant écriture ; la borne au niveau le plus proche ne promet rien sur un débordement ou un écrêtage.

La borne de demi-pas certifie-t-elle la sortie stockée de ce contrôle ?

<details><summary>Réponse 4</summary>

Non. L’entier `36044` dépasse la plage de destination. L’entrée viole le contrat et doit être rejetée avant conversion ; aucun échantillon stocké valide n’est revendiqué.

</details>

### Exercice 5

Le dithering modifierait volontairement l’échantillon avant quantification et exigerait sa propre distribution, son niveau et son périmètre de mesure. Cette leçon n’en ajoute pas et ne promet pas des erreurs inaudibles. Pour comparer natif et Wasm, garder séparément flottants bruts et octets codés, puis préciser si l’on étudie égalité numérique, reproductibilité entière ou écoute.

Quelle preuve réfuterait une égalité brute déduite de WAV identiques ?

<details><summary>Réponse 5</summary>

Deux flottants conservés différents mais codés par le même entier forment un contre-exemple. Le petit échantillon fournit cette construction ; une conclusion auditive exige toujours une écoute réelle.

</details>

## Tâche avec consultation des sources

Rédiger une note de conversion pour le programme existant. Calculer manuellement entiers et erreurs signées selon sa règle, puis inspecter encodeur et décodeur. Inclure le contrôle hors plage et expliquer son statut d’entrée rejetée plutôt que de défaut moteur mesuré. Indiquer les artefacts à conserver lorsque égalité brute et égalité WAV divergent, sans inventer de résultat d’écoute.

Conserver d’abord votre réponse avant de révéler les corrections préparées. Prendre le tableau ou calcul manuel comme référence pour toute calculatrice, consultation ou aide d’agent, et consigner cette aide. Garder réponse initiale et réponse corrigée séparément. Relier chaque exercice à un critère préparé du dossier ; aucune décision d’apprenant n’est encore prise. Noter un passage réellement lu et sa révision, puis distinguer ce qu’il établit de la prochaine étape proposée. Signaler toute entrée manquante comme non résolue. Une réponse mathématique juste soutient cet exemple ; revue humaine, exécution réelle et acceptation de l’apprenant demandent leurs propres observations conservées.
