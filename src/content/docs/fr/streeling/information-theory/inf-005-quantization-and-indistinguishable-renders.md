---
title: Quantification et rendus indiscernables
description: Quantification et rendus indiscernables — Théorie de l'information
sidebar:
  label: INF-005 · Quantification et rendus indiscernables
  order: 5
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/information-theory/fr/inf-005-quantization-and-indistinguishable-renders.fr.md
---

:::note[Streeling University]
**INF-005** · Quantification et rendus indiscernables · intermédiaire · 45 minutes

Généré par le département *Théorie de l'information* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/information-theory/fr/inf-005-quantization-and-indistinguishable-renders.fr.md) · [Mon journal](../../journal/)

Prérequis: [INF-004](../../information-theory/inf-004-information-loss-in-agent-handoffs/), [AUD-005](../../audio-engineering/aud-005-pcm-guards-and-format-boundaries/)
:::

Un ingénieur reçoit des fichiers PCM16 identiques et conclut que deux moteurs de guitare ont produit les mêmes échantillons en virgule flottante. Cette conclusion efface une distinction essentielle à l'expérience. Ce cours apprend à déterminer précisément quelle égalité subsiste après conversion et quelles informations sur la source sont devenues irrécupérables.

Lisez [INF-004](../../information-theory/inf-004-information-loss-in-agent-handoffs/) sur la perte d'information dans les handoffs et [AUD-005](../../audio-engineering/aud-005-pcm-guards-and-format-boundaries/) sur les contrôles des échantillons et les frontières entre formats. Le livrable est ici un bref raisonnement sur une application déterministe plusieurs-à-un. Utilisez le [dossier de preuves](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/feedback-projections-2026-10-22/README.md) et la [tâche apprenante](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/feedback-projections-2026-10-22/learner-task.md). Statut : brouillon source rédigé par IA ; les validations humaines du contenu, de la langue, des apprentissages et de la publication HTML publique restent à faire.

## 1. Repérer l'application qui perd de l'information

L'[analyse de quantification](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/feedback-projections-2026-10-22/quantization.json) réutilise les buffers conservés, dont les empreintes ont été vérifiées, de l'[expérience d'exécution enregistrée](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/guitar-runtime-2026-10-22/results.json). C'est une nouvelle analyse, pas un nouveau rendu. Dans chaque variante, 176400 échantillons float32 natifs et WASM ont été comparés. La référence présente 2918 échantillons bruts différents ; la candidate en présente 2926. Après conversion, chaque variante présente 0 échantillon PCM16 différent. Ces comparaisons opposent natif et WASM au sein de chaque variante ; elles n'établissent pas l'égalité entre référence et candidate.

Le [programme de l'expérience](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/run.mjs) accepte les valeurs float32 décodées finies dans `[-1,1]`. Il applique [`Math.round`](https://tc39.es/ecma262/multipage/numbers-and-dates.html#sec-math.round) dans [Node.js](https://nodejs.org/en/learn/getting-started/introduction-to-nodejs), après lecture de chaque valeur source par [`readFloatLE`](https://nodejs.org/docs/latest-v24.x/api/buffer.html#bufreadfloatleoffset) :

```text
Q(x) = Math.round(x * 32767)
```

La sérialisation en int16 signé suit. À la trame 646 de la référence, numérotée à partir de zéro, la valeur native `0.000552888261154294` a pour octets petit-boutistes `b4ef103a` ; la valeur WASM `0.0005528881447389722` a pour octets `b2ef103a`. Les deux produisent le code 18. La sortie a effacé une distinction réelle entre les sources.

### Exercice 1 — Réfuter l'égalité des sources

Quelle observation réfute « même PCM16 implique même float32 » ?

> **Réponse :** La trame 646 fournit des valeurs float32 et des octets distincts qui donnent le même code 18. Un seul contre-exemple réfute l'implication universelle ; aucune conclusion d'écoute n'est nécessaire.

## 2. Interpréter un code comme une classe d'équivalence

Définissons `x ~ y` lorsque leurs codes PCM16 sérialisés sont égaux. L'égalité des sorties rend cette relation réflexive, symétrique et transitive. Une **fibre** est l'ensemble des entrées acceptées qui partagent un code. Observer le code situe une fibre ; cela ne sélectionne généralement pas un de ses éléments.

En arithmétique réelle idéale, avec les demi-entiers arrondis vers l'infini positif, la fibre de l'entier `k` est :

```text
[(k - 0.5) / 32767, (k + 0.5) / 32767) intersect [-1,1]
```

La borne inférieure appartient à la cellule ; la borne supérieure appartient à la suivante. Les entrées réellement acceptées sont des valeurs float32 traitées par l'arithmétique JavaScript. Près d'une borne, évaluez l'encodeur exact au lieu de supposer que tous les seuils idéaux sont représentés exactement. `Math.round` tranche les égalités vers l'infini positif : `Math.round(0.5)` vaut 1, `Math.round(-1.5)` vaut -1 et `Math.round(-0.5)` vaut zéro négatif. La sérialisation fusionne zéro négatif et zéro positif en octets entiers identiques.

L'analyse contient aussi un **exemple construit**, et non un échantillon de guitare capturé : `0.25` et `0.2500000298023224` donnent tous deux 8192. Un décodeur qui choisit `k / 32767` renvoie un représentant, pas une preuve de l'entrée originale.

### Exercice 2 — Inverser l'exemple construit

Avec le seul code 8192, pouvez-vous choisir de manière unique entre les deux entrées construites ?

> **Réponse :** Non. Les deux appartiennent à sa fibre. Une inverse qui renvoie l'une échoue pour l'autre. La reconstruction unique exige des informations supplémentaires sur la source ou des restrictions permettant de les distinguer.

## 3. Compter l'alphabet de l'encodeur

Le domaine accepté et le facteur d'échelle donnent un code émis minimal de -32767 et maximal de 32767. En incluant les deux extrémités, on obtient `32767 - (-32767) + 1 = 65535` codes entiers possibles. Le format int16 signé peut stocker 65536 codes, dont -32768, mais cet encodeur n'émet jamais ce code supplémentaire pour les entrées acceptées.

Ce nombre de symboles n'est pas une entropie mesurée. L'entropie nécessite un modèle de probabilité sur les sorties ; les nombres déterministes d'échantillons et les collisions observées n'en fournissent pas. De même, 2918 échantillons différents dénombrent des positions dans une comparaison, pas des bits d'information perdus.

### Exercice 3 — Expliquer le code manquant

Pourquoi un conteneur de 16 bits n'implique-t-il pas 65536 sorties accessibles à l'encodeur ?

> **Réponse :** Le stockage autorise -32768, tandis que `Q(-1)` vaut -32767. Cet encodeur ne produit que les codes de -32767 à 32767 : 65535 codes. La capacité du conteneur et l'image de l'application répondent à des questions différentes.

## 4. Distinguer erreur de reconstruction et distance entre sources

En arithmétique réelle idéale, reconstruire une source par `Q(x) / 32767` donne une erreur absolue au plus égale à `1 / (2 * 32767)`, soit environ 0.000015259254737998596. Cette borne d'un demi-pas concerne une source et son représentant choisi. Deux entrées d'une même fibre intérieure peuvent être séparées de presque un pas entier, `1 / 32767`. Le demi-pas n'est donc pas une borne générale de leur distance mutuelle.

Les erreurs maximales mesurées de reconstruction native sont 0.000015258982790783415 pour la référence et 0.00001525887933261083 pour la candidate. Les deux différences maximales brutes natif/WASM valent 2.9802322387695312e-8. Ces mesures comparent des paires de grandeurs différentes. Leur faible valeur ne suffit pas à garantir des codes égaux : dans le modèle idéal, des valeurs de part et d'autre d'un seuil peuvent être arbitrairement proches.

### Exercice 4 — Associer chaque erreur à sa question

La différence brute maximale mesure-t-elle l'erreur de reconstruction ? La borne d'un demi-pas établit-elle l'égalité PCM ?

> **Réponse :** Non dans les deux cas. La différence brute compare les sorties de deux moteurs ; l'erreur de reconstruction compare une source à son représentant décodé. L'égalité PCM nécessite de comparer les sorties encodées. La position par rapport au seuil compte autant que la distance.

## 5. Conserver le handoff le plus solide que permettent les preuves

L'analyse vérifie, pour chaque variante, les empreintes des charges utiles PCM16 complètes par rapport à la charge utile du WAV versionné. Avec les comparaisons directes des codes, cela établit l'égalité après cette conversion précise sur toutes les trames conservées de chaque variante. Les empreintes brutes diffèrent. Conserver ces buffers préserve des distinctions que le WAV ne peut pas restituer.

Rédigez une note de revue nommant l'encodeur, le domaine, la variante, le nombre de trames et les preuves. Cette expérience fixe hors ligne n'établit ni équivalence perceptive ou de timbre, ni modèle de bruit, SNR, entropie, performances, comportement dans le navigateur ou reproductibilité sur toutes les plateformes. Aucun essai apprenant ni test d'écoute n'a eu lieu dans cette analyse.

### Exercice 5 — Formuler l'affirmation valide

Remplacez « les moteurs sont identiques » par un handoff vérifiable.

> **Réponse :** Sur 176400 trames conservées par variante, natif et WASM diffèrent à 2918 positions brutes pour la référence et à 2926 pour la candidate, mais présentent 0 différence de code PCM16 sous `Q(x) = Math.round(x * 32767)` et sérialisation int16 signée. Chaque charge utile complète correspond à celle de son WAV versionné. Cela établit l'égalité après conversion pour ces entrées ; la reconstruction float32 unique et l'équivalence auditive restent sans preuve. Soumettez ce dossier apprenant réalisé avec les sources aux validations en attente.
