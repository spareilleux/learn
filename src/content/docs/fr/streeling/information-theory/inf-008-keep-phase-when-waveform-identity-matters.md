---
title: Conserver la phase lorsque l'identité des formes d'onde compte
description: Conserver la phase lorsque l'identité des formes d'onde compte — Théorie de l'information
sidebar:
  label: INF-008 · Conserver la phase lorsque l'identité des formes d'onde compte
  order: 8
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/information-theory/fr/inf-008-keep-phase-when-waveform-identity-matters.fr.md
---

:::note[Streeling University]
**INF-008** · Conserver la phase lorsque l'identité des formes d'onde compte · intermédiaire · 40 minutes

Généré par le département *Théorie de l'information* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/information-theory/fr/inf-008-keep-phase-when-waveform-identity-matters.fr.md) · [Mon journal](../../journal/)

Prérequis: [INF-005](../../information-theory/inf-005-quantization-and-indistinguishable-renders/), [AUD-008](../../audio-engineering/aud-008-measure-a-filter-with-paired-input-and-output/)
:::

> **Portée du brouillon.** Contre-exemples pédagogiques de transformées finies et inspection du code public à une révision précise. Les revues humaines technique, linguistique, musicale et pédagogique ainsi que la vérification du HTML du cours déployé restent à effectuer. Aucun nouveau rendu audio, test d'écoute ou interface de production n'ont été exécutés.

## La question du projet

Deux agents échangent seulement des modules spectraux et concluent que leurs attaques de guitare sont identiques. Quelles informations étayent cette conclusion ? [INF-005](../../information-theory/inf-005-quantization-and-indistinguishable-renders/) examine la quantification ; ici, l'information éliminée est la phase complexe. [AUD-008](../../audio-engineering/aud-008-measure-a-filter-with-paired-input-and-output/) établit les transformées appariées.

## 1. Construire une ambiguïté exacte

Prenez deux réponses impulsionnelles pédagogiques à deux coefficients et complétez chacune par des zéros jusqu'à la longueur N = 8 :

```text
A = [3/4, 1/4, 0, 0, 0, 0, 0, 0]
B = [1/4, 3/4, 0, 0, 0, 0, 0, 0]
H_A(omega) = 3/4 + (1/4)*exp(-i*omega)
H_B(omega) = 1/4 + (3/4)*exp(-i*omega)
|H_A(omega)|^2 = |H_B(omega)|^2 = 5/8 + (3/8)*cos(omega)
```

L'égalité des modules vaut pour toute fréquence réelle, et non seulement pour les huit indices de TFD. Les formes d'onde diffèrent sur leurs deux échantillons non nuls. Cela dépasse une ambiguïté de décalage circulaire entier : le [jeu d'essai](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/filter-phase-2026-10-22/phase-pair.json) vérifie chaque décalage de 0 à 7, et aucun ne transforme A en B.

### Exercice 1 — Prouver l'égalité sans reconstruire la forme d'onde

Développez le carré du module de chaque réponse à deux coefficients. L'égalité des modules prouve-t-elle l'égalité des échantillons, même en autorisant un décalage circulaire entier ?

> **Réponse:** Chaque carré du module est 9/16 + 1/16 + (6/16)cos(omega) = 5/8 + (3/8)cos(omega). Les échantillons diffèrent. Seul le décalage circulaire nul préserve le support aux positions 0 et 1 pour cette longueur, et ce décalage n'échange pas leurs valeurs inégales. Aucun des décalages entiers autorisés ne les rend donc identiques.

## 2. La phase distingue ce que le module oublie

Utilisez la [TFD directe non normalisée](https://www.dsprelated.com/freebooks/mdft/DFT_Definition.html) avec une exponentielle négative. À k = 2, omega = pi/2 :

| Réponse | Coefficient complexe | Module, environ | Phase, radians, environ |
| --- | --- | --- | --- |
| A | 0.75 - 0.25i | 0.790569415 | -0.321750554 |
| B | 0.25 - 0.75i | 0.790569415 | -1.249045772 |

En continu, les deux coefficients valent +1. À Nyquist, ils valent +0.5 et -0.5 : les modules concordent toujours tandis que le signe diffère. Convertir le module en décibels ne permet pas de retrouver la phase ou le signe.

### Exercice 2 — Identifier un champ manquant

Un agent envoie le nombre 0.790569415 pour k = 2. Quelle ligne cela identifie-t-il ? Quelle valeur supplémentaire distinguerait les deux candidats à cet indice fréquentiel ?

> **Réponse:** Cela n'en identifie aucune de façon unique : les deux ont ce module. Leur coefficient complexe ou leur phase les distinguerait à cet indice, avec les conventions de transformée et l'alignement déclarés. La phase d'un coefficient de module nul exigerait sa propre politique de valeur indéfinie ; cette paire particulière n'a aucun zéro sur le cercle unité.

## 3. La reconstruction exige les coefficients complexes

La [TFD inverse](https://www.dsprelated.com/freebooks/mdft/Inverse_DFT.html) utilise une exponentielle positive et un facteur 1/N. Inverser chaque spectre complexe complet reconstruit sa propre suite complétée de zéros à la tolérance numérique près. Inverser les modules après leur avoir attribué une phase nulle donne une troisième suite périodique ; cela ne retrouve pas le choix original entre A et B.

### Exercice 3 — Rejeter la phase inventée

Pourquoi remplacer chaque coefficient par son module avant la transformée inverse constitue-t-il une nouvelle hypothèse ? Ce contre-exemple peut-il établir que tout spectrogramme de modules à trames chevauchantes est impossible à inverser sous toute contrainte ?

> **Réponse:** Cela attribue une phase nulle au lieu de conserver les valeurs complexes mesurées ; la forme d'onde obtenue découle de ce choix de phase inventé. Non. Cet exemple concerne l'application qui associe aux suites finies déclarées le module de leur transformée complète. Les trames chevauchantes et les contraintes supplémentaires changent les questions de récupération de phase ; leur unicité doit être étudiée selon leurs hypothèses réelles.

## 4. Une énergie totale égale peut masquer une redistribution temporelle

Les deux suites ont une énergie de 5/8. Définissez le centroïde d'énergie en unités d'échantillon comme la somme de n fois l'échantillon au carré, divisée par l'énergie totale. A a un centroïde de 0.1 échantillon ; B, de 0.9 échantillon. Ce sont des descripteurs numériques des impulsions pédagogiques, et non une qualité d'attaque mesurée, un placement temporel perçu ou une courbe de retard de groupe.

### Exercice 4 — Calculer une distinction temporelle

Calculez les deux centroïdes et leur différence. Cela montre-t-il qu'un auditeur peut distinguer les deux filtres ou que l'un d'eux améliore une attaque de guitare ?

> **Réponse:** A donne (1/16)/(10/16) = 0.1 ; B donne (9/16)/(10/16) = 0.9. La différence est de 0.8 échantillon. Cela prouve une différence temporelle dans ce descripteur, et non une audibilité, un retard pur, une préférence d'auditeur ou une amélioration réussie en production.

## 5. Préciser la transformée et son domaine d'entrée

À la révision d'IX `bd1336b7c4045e427dcdbe80b102790e45da5ce1`, [stft et spectrogram](https://github.com/GuitarAlchemist/ix/blob/bd1336b7c4045e427dcdbe80b102790e45da5ce1/crates/ix-signal/src/spectral.rs#L7-L54) exposent des représentations différentes : des coefficients complexes contre des modules scalaires ou des décibels. Préservez les premiers si une opération ultérieure exige leur phase d'origine.

GA applique aussi une transformée de Fourier à un autre domaine. À la révision `76efbffd5af82b46c3146957a6bd4504008eeb89`, [SetClass](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Domain.Core/Theory/Atonal/SetClass.cs#L150-L223) transforme le vecteur de classes de hauteur de la forme première spectrale, puis propose des vues de module et de phase. Conserver la phase de ce vecteur canonique ne permet pas de récupérer une transposition d'origine déjà éliminée par la canonicalisation.

Le composant distinct [SpectralPhaseAlignment](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Domain.Core/Theory/Atonal/SpectralPhaseAlignment.cs#L75-L139) utilise le chroma réel et des produits croisés complexes pour des rotations d'essai. Ses [tests](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Tests/Common/GA.Business.Core.Tests/Atonal/SpectralPhaseAlignmentTests.cs) comprennent l'alignement de transposition d'une triade majeure. C'est une lecture du code et des tests, et non une nouvelle exécution C#. Une rotation de classes de hauteur n'est pas un retard temporel audio ; un indice de Fourier exige son domaine d'entrée déclaré.

### Exercice 5 — Concevoir une transmission défendable entre agents

Rédigez les champs et les limites des affirmations pour un agent comparant l'identité des formes d'onde et un autre comparant l'alignement des classes de hauteur. Expliquez pourquoi « nous avons conservé la phase » ne suffit pas à lui seul.

> **Réponse:** Préservez le domaine d'entrée et sa normalisation ou canonicalisation, l'identité de la source, le signe et la normalisation de la transformée, la longueur, les axes, la fréquence d'échantillonnage pour l'audio, l'alignement temporel et les coefficients complexes ou les données d'origine selon les besoins. Précisez si la comparaison porte sur le module, les échantillons exacts, un décalage temporel spécifié ou une rotation de classes de hauteur. La phase d'une entrée canonique ne peut pas restaurer l'information effacée avant la transformée. Un adaptateur entre ces représentations reste une conception proposée, et non un contrat implémenté.

## Travail de l'apprenant avec accès aux sources

Préparez un rapport de contre-exemple à l'affirmation « même attaque de guitare » fondée sur les seuls modules. Incluez l'identité des modules, un coefficient complexe distinctif, l'hypothèse de transformée inverse, les deux centroïdes d'énergie et la distinction de domaine d'entrée dans les deux parcours de GA. Consignez l'aide et les questions non résolues. La [grille d'évaluation de la revue](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/filter-phase-2026-10-22/reviewer-rubric.json) est préparée, sans décision d'apprenant enregistrée.

Le [relevé des sources](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/filter-phase-2026-10-22/primary-readback.json) lie les fichiers immuables. Aucun résultat perceptif, théorème complet de récupération de phase, adaptateur déployé ou réussite d'apprenant ne découle de ces calculs.
