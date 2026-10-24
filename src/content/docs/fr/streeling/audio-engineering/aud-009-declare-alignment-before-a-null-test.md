---
title: Déclarer l’alignement avant un test d’annulation
description: Déclarer l’alignement avant un test d’annulation — Ingénierie audio
sidebar:
  label: AUD-009 · Déclarer l’alignement avant un test d’annulation
  order: 9
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/audio-engineering/fr/aud-009-declare-alignment-before-a-null-test.fr.md
---

:::note[Streeling University]
**AUD-009** · Déclarer l’alignement avant un test d’annulation · intermédiaire · 45 minutes

Généré par le département *Ingénierie audio* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/audio-engineering/fr/aud-009-declare-alignment-before-a-null-test.fr.md) · [Mon journal](../../journal/)

Prérequis: [AUD-005](../../audio-engineering/aud-005-pcm-guards-and-format-boundaries/), [AUD-008](../../audio-engineering/aud-008-measure-a-filter-with-paired-input-and-output/)
:::

> **Périmètre du brouillon.** Échantillons pédagogiques en nombre fini et lecture du code à une révision fixée. Les revues humaines techniques, musicales, linguistiques par des personnes maîtrisant la langue et pédagogiques avec des apprenants, ainsi que la vérification du HTML du cours déployé, restent à effectuer. Aucun nouveau rendu du moteur, aucune capture dans le navigateur ni aucun essai d’écoute n’ont été réalisés.

## La question du projet

Deux tampons s’annulent après qu’un agent a décalé et remis à l’échelle l’un d’eux. Les tampons d’origine étaient-ils identiques ? [AUD-005](../../audio-engineering/aud-005-pcm-guards-and-format-boundaries/) distingue les garde-fous et les formats PCM ; [AUD-008](../../audio-engineering/aud-008-measure-a-filter-with-paired-input-and-output/) conserve les paires entrée-sortie. Ici, la comparaison doit préserver ses transformations comme des résultats.

## 1. Déclarer l’horloge, le sens du retard et le support complet

Les [échantillons fixés](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/audio-comparison-2026-10-23/null-comparison.json) sont des valeurs réelles conçues pour le cours :

```text
x = [0, .25, -.25, .5, -.5, .25, 0, -.25]
y = [0, 0] + .5*x
Fs = 8000 Hz
y[n+2] = .5*x[n] for n = 0..7
```

La référence comporte 8 trames ; le signal retardé en comporte 10. La cible de référence déclarée comprend la totalité des 8 trames, appariées aux trames 2 à 9 de y. Le retard vaut 2/8000 secondes = .25 ms. Cette horloge pédagogique n’est ni une fréquence de navigateur mesurée ni une latence matérielle.

### Exercice 1 — Rendre l’appariement reproductible

Indiquez la cible, la correspondance des trames et le sens du retard. Les .25 ms représentent-elles une amélioration observée de la latence ?

> **Réponse:** Appariez la trame n de x à la trame n+2 de y pour chaque trame de référence de 0 à 7. Le y pédagogique est retardé de 2 trames. Cela couvre la totalité de la cible de référence déclarée et traite séparément les deux trames initiales. La valeur de .25 ms découle de l’horloge stipulée ; ce n’est ni une latence mesurée ni une amélioration.

## 2. Rapporter les résidus avant et après ajustement

Pour tout vecteur de résidu r déclaré, la valeur RMS est la racine carrée de la moyenne de ses carrés. La valeur RMS de référence est d’environ .306186218. Comparer x aux 8 premières trames de y à l’origine initiale donne un résidu RMS d’environ .275992527. Aligner le retard déclaré tout en conservant un gain unitaire donne environ .153093109.

La première comparaison est un diagnostic explicitement tronqué à l’origine initiale, pas une couverture complète du signal retardé. Elle ne doit pas devenir silencieusement la cible finale alignée.

### Exercice 2 — Expliquer le changement de question

Pourquoi le résidu après alignement du retard peut-il être plus petit alors qu’aucun échantillon d’origine n’a changé ?

> **Réponse:** L’appariement des trames a changé. Après alignement, le signal vaut la moitié de la référence ; la différence possède donc la moitié de la valeur RMS de référence. Cela retire le décalage stipulé de la question de comparaison, pas de l’historique du signal d’origine. Conservez les deux résidus, leurs supports et le retard au lieu d’affirmer que l’alignement a préservé le placement temporel d’origine.

## 3. Une annulation après ajustement ne prouve pas l’égalité d’origine

Sur la cible alignée complète, ajustez un scalaire réel avec la référence comme prédicteur :

```text
g_hat = sum(x[n]*y[n+2])/sum(x[n]*x[n]) = .5
residual[n] = y[n+2] - g_hat*x[n] = 0
20*log10(g_hat) = -6.020599913 dB
```

Le modèle déclaré de retard et de gain s’ajuste exactement en arithmétique réelle. Il a éliminé deux différences qui peuvent compter pour l’utilisateur : le placement temporel et le niveau. Cela ne dit rien sur l’identité des octets flottants natifs/Wasm, l’identité PCM16 ou une préférence d’écoute.

### Exercice 3 — Formuler un verdict fidèle

Peut-on présenter le résidu nul après ajustement comme un « audio inchangé » ? Incluez le retard et le gain dans un verdict de remplacement.

> **Réponse:** Rapportez une concordance exacte des échantillons pédagogiques après l’alignement déclaré de 2 trames et l’ajustement du gain à .5, soit environ -6.020599913 dB. Les signaux d’origine diffèrent par leur support, leur placement temporel et leur niveau. Un résidu nul après ajustement n’établit que la comparaison transformée énoncée sur sa cible complète. Il ne démontre ni audio d’origine inchangé, ni identité des bits, ni réduction mesurée de latence.

## 4. Le silence et les fins tronquées nécessitent des statuts distincts

Pour deux vecteurs silencieux de 8 trames, le résidu brut est nul, mais le dénominateur d’ajustement du gain est nul : le gain est indéfini. L’égalité brute des silences reste un énoncé valide.

Pour un contrôle de fin de signal, partez du signal aligné .5*x et ajoutez .125 à sa dernière trame. Avec le gain prescrit de .5, les 6 premières trames ont un résidu nul, mais seulement 6/8 = .75 de la cible déclarée a été vérifié. Le résidu RMS complet est d’environ .044194174. C’est une vérification à gain prescrit ; ne réajustez pas silencieusement le gain sur la fin modifiée.

### Exercice 4 — Rejeter deux validations invalides

Un gain ajusté indéfini doit-il rendre fausse l’égalité brute de deux silences ? Le résidu nul des 6 premières trames peut-il certifier la cible complète de 8 trames ?

> **Réponse:** Non dans les deux cas. L’ajustement du gain sur le silence est indéfini, tandis qu’une comparaison brute directe reste pertinente. Dans le cas de la fin de signal, la différence omise rend le résidu complet non nul. Conservez le nombre de trames vérifiées, le nombre de trames cibles, les données manquantes et la politique de transformation. Cette cible exige la totalité des 8 trames ; l’exemple n’établit pas de seuil universel de couverture minimale pour d’autres tâches.

## 5. Lire le programme d’exécution existant avant de proposer un pipeline

Le [programme d’exécution de Learn](https://github.com/spareilleux/learn/blob/49ad4cf7db680f031b3a3fb5b6ee118464ad099f/code/streeling/guitar-runtime/run.mjs) à la révision fixée traite séparément les octets flottants bruts, le PCM16 et les fenêtres RMS semi-ouvertes à bornes arrondies. Il utilise des décalages d’attaque connus pour sa comparaison de décroissance ; il n’implémente pas cette nouvelle procédure d’ajustement du retard et du gain. Sa [provenance](https://github.com/spareilleux/learn/blob/49ad4cf7db680f031b3a3fb5b6ee118464ad099f/code/streeling/guitar-runtime/source.json) fixe un moteur plus ancien que le code GA nouvellement inspecté. Le critère de décroissance non satisfait conservé reste inchangé.

### Exercice 5 — Définir une comparaison avec l’aide des sources

De quoi un relevé de comparaison native/Wasm réelle aurait-il besoin avant que ces idées deviennent un DSL agentique ?

> **Réponse:** Préservez les révisions du moteur et du programme d’exécution, le format des échantillons, l’organisation des canaux, les horloges, l’excitation, l’étendue complète des tampons, le support cible, le sens du retard, le gain ajusté ou prescrit, les mesures brutes, les mesures ajustées, les trames manquantes et le coût de calcul. Inspectez les endroits où le programme actuel sérialise les flottants et convertit en PCM16. Comparez d’abord un petit relevé explicite et une soustraction directe. L’identité des octets, la concordance après transformation, la latence et l’écoute exigent des éléments distincts. Aucun pipeline de production, aucune nouvelle exécution du moteur ni aucun bénéfice utilisateur n’ont été démontrés ici.

## Travail à transmettre par l’apprenant

Conservez le travail réellement effectué et l’assistance reçue dans la [tâche avec l’aide des sources](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/audio-comparison-2026-10-23/learner-task.md). La [grille préparée](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/audio-comparison-2026-10-23/reviewer-rubric.json) ne contient aucun verdict d’apprenant. [INF-009](../../information-theory/inf-009-keep-level-when-normalizing-waveform-shape/) montre une autre manière dont une comparaison peut effacer les différences de niveau.
