---
title: Rééchantillonner sans simplement changer l’horloge
description: Rééchantillonner sans simplement changer l’horloge — Ingénierie audio
sidebar:
  label: AUD-013 · Rééchantillonner sans simplement changer l’horloge
  order: 13
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/audio-engineering/fr/aud-013-resample-without-relabeling-the-clock.fr.md
---

:::note[Streeling University]
**AUD-013** · Rééchantillonner sans simplement changer l’horloge · intermédiaire · 55 minutes

Généré par le département *Ingénierie audio* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/audio-engineering/fr/aud-013-resample-without-relabeling-the-clock.fr.md) · [Mon journal](../../journal/)

Prérequis: [AUD-011](../../audio-engineering/aud-011-count-valid-frames-separately-from-block-padding/)
:::

> Exemple construit et lecture de sources. Aucune nouvelle prestation, exécution audio ou de parseur, réponse de participant ni adoption en production n’est revendiquée. Les décisions techniques humaines, linguistiques et pédagogiques restent en attente.

Une référence de guitare et un rendu Wasm hors ligne peuvent avoir des fréquences d’échantillonnage différentes. La comparaison devient trompeuse si un agent change cette étiquette tout en conservant les échantillons. Le signal suit alors une autre horloge, même si son empreinte binaire reste identique. Cette leçon établit un contrat de conversion qui conserve la durée avant de choisir une implémentation. Le prérequis comptait les trames valides du dernier bloc ; ici, on étudie leur rapport au temps physique lorsque la fréquence change.

## Lire les preuves conservées

Dans le programme conservé, lire ensemble la fréquence fixe et l’écriture de l’en-tête WAV. La fréquence déclarée règle la génération comme l’interprétation. La spécification Web Audio définit la durée par le nombre de trames divisé par la fréquence et décrit le rééchantillonnage vers celle du contexte. Ces règles définissent des grandeurs sans certifier un filtre d’interpolation. Le cas suivant est construit ; aucun convertisseur n’a été exécuté.

[Prérequis](../../audio-engineering/aud-011-count-valid-frames-separately-from-block-padding/)

[Artefact de projet conservé](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/run.mjs)

[Dossier construit fixe](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/journal.md)

[Lecture primaire](https://www.w3.org/TR/2026/WD-webaudio-1.1-20260922/)

### Exercice 1

Partir de `44100` trames à `44100 Hz`, contenant un son supposé à `1000 Hz`. La durée vaut `N_in/F_in`. Le nombre de trames seul ne permet pas de savoir si l’extrait représente une seconde entière. Conserver la fréquence d’origine avec les échantillons avant qu’une comparaison ou un nœud de workflow ne change leur représentation.

Quelle est la durée d’entrée et quels champs la déterminent ?

<details><summary>Réponse 1</summary>

Elle vaut `1 s`, déterminée par `44100` trames et `44100 Hz`. Ni le nom du fichier ni son empreinte ne fournit cette relation temporelle.

</details>

### Exercice 2

La fréquence de destination demandée est `48000 Hz`. Conserver la durée impose `N_out=duration*F_out`, soit `48000` trames de sortie. Ce nombre décrit le support temporel voulu, sans définir les valeurs entre les échantillons existants. Un véritable convertisseur doit encore préciser l’interpolation, la limitation de bande et le traitement des extrémités du tampon.

Combien de trames de sortie conservent la durée déclarée ?

<details><summary>Réponse 2</summary>

Il faut `48000` trames pour `1 s`. Ce nombre constitue un contrat à vérifier, pas une preuve de la justesse des échantillons produits par un filtre.

</details>

### Exercice 3

Dans le cas d’échec, garder les `44100` échantillons d’origine en les déclarant à `48000 Hz`. La lecture dure alors `0.91875 s`. Le son supposé passe à `1088.43537414966 Hz` selon `f*F_out/F_in`. C’est une erreur d’horloge, pas une guitare jouée trop haut ; normaliser le niveau ne rétablit pas le temps perdu.

Donner la durée et la fréquence après réétiquetage, puis diagnostiquer la modification.

<details><summary>Réponse 3</summary>

Elles valent `0.91875 s` et `1088.43537414966 Hz`. Le réétiquetage comprime le temps et augmente la fréquence ; il ne conserve pas la durée par rééchantillonnage.

</details>

### Exercice 4

Le contrôle négatif structuré emploie une sortie à `44100 Hz`. Le nombre requis devient `44100` ; conserver les échantillons donne `1 s` et `1000 Hz`. Une suite limitée aux fréquences identiques tolérerait donc le raccourci erroné. Le contrôle doit solliciter précisément le décalage que l’opération prétend traiter.

Pourquoi ce contrôle accepte-t-il le raccourci sans le valider ?

<details><summary>Réponse 4</summary>

Des fréquences identiques suppriment le décalage. Le résultat est `1 s` à `1000 Hz` ; ce cas ne distingue donc pas le réétiquetage d’une véritable conversion.

</details>

### Exercice 5

Pour réduire la fréquence d’échantillonnage, conserver la durée ne suffit pas : le contenu au-dessus de la limite de Nyquist de destination exige une politique de filtrage déclarée. Distinguer cette exigence du calcul d’horloge. Un futur transfert ComfyUI ou audio doit conserver fréquence, trames valides, portée de l’interpolation et du filtre, puis une observation réelle de sortie avant d’affirmer la fidélité.

Quel résultat réfuterait la conversion censée conserver la durée ?

<details><summary>Réponse 5</summary>

Une durée nombre-de-trames/fréquence différente de l’entrée, ou un son étalon déplacé comme dans le cas réétiqueté, réfuterait cette affirmation. Le rejet du repliement spectral exige une observation distincte.

</details>

## Tâche avec consultation des sources

Rédiger une revue d’une comparaison entre référence et Wasm. Calculer manuellement les chronologies principale et de contrôle, puis retrouver la fréquence et le champ d’en-tête du programme. Proposer un enregistrement de transfert contenant les deux horloges et un contrôle de durée. Préciser quelle fréquence ou quel nombre de trames observé ferait rejeter la proposition. Laisser la qualité d’interpolation indécise jusqu’à l’inspection d’un convertisseur réel et de sa sortie.

Conserver d’abord votre réponse avant de révéler les corrections préparées. Prendre le tableau ou calcul manuel comme référence pour toute calculatrice, consultation ou aide d’agent, et consigner cette aide. Garder réponse initiale et réponse corrigée séparément. Relier chaque exercice à un critère préparé du dossier ; aucune décision d’apprenant n’est encore prise. Noter un passage réellement lu et sa révision, puis distinguer ce qu’il établit de la prochaine étape proposée. Signaler toute entrée manquante comme non résolue. Une réponse mathématique juste soutient cet exemple ; revue humaine, exécution réelle et acceptation de l’apprenant demandent leurs propres observations conservées.
