---
title: Vérifier la fermeture d’un cycle de quintes
description: Vérifier la fermeture d’un cycle de quintes — Musiques et langues du monde
sidebar:
  label: WML-013 · Vérifier la fermeture d’un cycle de quintes
  order: 13
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/world-music-languages/fr/wml-013-check-whether-a-fifth-cycle-closes.fr.md
---

:::note[Streeling University]
**WML-013** · Vérifier la fermeture d’un cycle de quintes · intermédiaire · 55 minutes

Généré par le département *Musiques et langues du monde* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/world-music-languages/fr/wml-013-check-whether-a-fifth-cycle-closes.fr.md) · [Mon journal](../../journal/)

Prérequis: [WML-004](../../world-music-languages/wml-004-preserve-intonation-beyond-pitch-classes/)
:::

> Exemple construit et lecture de sources. Aucune nouvelle prestation, exécution audio ou de parseur, réponse de participant ni adoption en production n’est revendiquée. Les décisions techniques humaines, linguistiques et pédagogiques restent en attente.

Un cercle de noms peut revenir à son étiquette initiale alors qu’une chaîne de rapports manque l’octave correspondante. Un outil qui ne conserve que l’étiquette masque ce résidu. Nous composons une quinte déclarée et vérifions la fermeture par rapport à un nombre d’octaves déclaré. La comparaison individuelle en cents du prérequis devient un calcul cyclique, sans désigner de tempérament culturellement juste ou musicalement préférable.

## Lire les preuves conservées

Lire le rapport construit et la mise en garde sur la projection entière du dossier d’intonation. NIST fournit le rapport du cent ; UNSW distingue rapports harmoniques et approximations tempérées. Nous dérivons le cycle nous-mêmes. Les valeurs sont mathématiques et construites, pas une séance d’accordage, un détecteur ou une preuve de réalisation par GA.

[Prérequis](../../world-music-languages/wml-004-preserve-intonation-beyond-pitch-classes/)

[Artefact de projet conservé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/intonation-listening-2026-10-22/intonation.json)

[Dossier construit fixe](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/journal.md)

[Lecture primaire](https://www.nist.gov/pml/time-and-frequency-division/popular-links/time-frequency-z)

[Lecture primaire](https://www.phys.unsw.edu.au/jw/strings.html)

### Exercice 1

Chaque quinte multiplie la fréquence par `3/2` ; en composer `12` et comparer à `7` octaves de facteur `2`. En classes de hauteur, une quinte avance de `7` pas modulo `12`, revenant à l’étiquette. Cette fermeture discrète ne prouve pas l’égalité des multiplicateurs, puisque les représentations gardent des informations différentes.

Le retour à l’étiquette prouve-t-il la fermeture des rapports ?

<details><summary>Réponse 1</summary>

Non. Le calcul d’étiquettes est modulo `12`, tandis que les rapports comparent `(3/2)^12` et `2^7`. Il faut deux vérifications distinctes.

</details>

### Exercice 2

Diviser le multiplicateur des quintes par celui des octaves. Le résidu `(3/2)^12/2^7=531441/524288` dépasse `1`. Garder la fraction exacte avant arrondi : trop peu de décimales peuvent masquer l’écart. La fraction décrit cette construction pure, pas l’accordage de tout instrument réel.

Quel rapport résiduel exact reste-t-il ?

<details><summary>Réponse 2</summary>

C’est `531441/524288` ; le cycle ne ferme donc pas exactement. La chaîne de quintes arrive au-dessus de la référence équivalente en octaves.

</details>

### Exercice 3

Convertir avec `1200*log2(531441/524288)`, soit environ `23.460010384649` cents. Le signe est positif car le numérateur dépasse le dénominateur. Ce résultat mesure l’écart construit sur une échelle de rapports, sans établir son audibilité ni son intérêt dans un contexte musical donné.

Donner le résidu en cents et son signe.

<details><summary>Réponse 3</summary>

Il vaut environ `23.460010384649` cents, positif parce que l’arrivée des quintes est plus haute que la référence d’octaves. Aucun seuil d’écoute n’a été mesuré.

</details>

### Exercice 4

Le contrôle négatif remplace la quinte par `2^(7/12)`, avec les mêmes comptes. Symboliquement, la puissance `12` donne `2^7`, donc rapport résiduel `1` et écart `0` cents. Une calculatrice flottante peut laisser un très petit résidu numérique : le distinguer de l’égalité exacte plutôt que d’inventer un nouvel écart d’accordage.

Qu’est-ce qui ferme dans le contrôle ?

<details><summary>Réponse 4</summary>

Le cycle de rapports ferme exactement selon la définition symbolique : rapport `1` et `0` cents. La quinte diffère de `3/2` ; cela n’annule pas le résultat principal.

</details>

### Exercice 5

Un transfert fidèle doit conserver définition d’intervalle, référence, nombre de compositions et approximation. Un masque de classes reste utile à la recherche mais ne reconstruit pas le cycle de rapports. Avant de proposer DSL ou agent, montrer qu’il garde le résidu manuel et distingue le contrôle tempéré.

Qu’est-ce qui réfuterait la conservation de cette distinction dans un simple ensemble de classes ?

<details><summary>Réponse 5</summary>

Mapper les deux constructions vers le même enregistrement sans rapports ni cents empêche de retrouver le résidu voulu. Les deux cas témoignent de cette perte d’information.

</details>

## Tâche avec consultation des sources

Calculer fraction et cents à la main, puis le contrôle tempéré symbolique. Inspecter l’exemple de projection et expliquer pourquoi les étiquettes ne récupèrent pas le rapport perdu. Rédiger une note consultative gardant référence et définition d’intervalle, avec réfutateur de fermeture. Laisser réalisation instrumentale, interprétation culturelle, préférence et prestation réelle à des preuves distinctes.

Conserver d’abord votre réponse avant de révéler les corrections préparées. Prendre le tableau ou calcul manuel comme référence pour toute calculatrice, consultation ou aide d’agent, et consigner cette aide. Garder réponse initiale et réponse corrigée séparément. Relier chaque exercice à un critère préparé du dossier ; aucune décision d’apprenant n’est encore prise. Noter un passage réellement lu et sa révision, puis distinguer ce qu’il établit de la prochaine étape proposée. Signaler toute entrée manquante comme non résolue. Une réponse mathématique juste soutient cet exemple ; revue humaine, exécution réelle et acceptation de l’apprenant demandent leurs propres observations conservées.
