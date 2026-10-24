---
module_id: dv-009-compare-spectrogram-color-scales
department: data-visualization
course: "Comparer des spectrogrammes sans masquer un changement de gain"
level: intermediate
prerequisites: ["dv-007-optick-partition-small-multiples", "aud-006-calibrate-spectral-amplitudes", "cs-013-preserve-spectral-axes-and-units"]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Comparer des spectrogrammes sans masquer un changement de gain

> **Portée du brouillon.** Analyse mesurée d'affichage à partir de WAV conservés et d'un témoin de gain construit. La revue technique humaine, la révision par des personnes maîtrisant la langue, les essais des apprenants, l'écoute et la vérification du HTML public du cours restent à effectuer. Aucun nouveau rendu de guitare ni aucune exécution de binaire IX n'ont été réalisés.

## La question du projet

Un agent d'amélioration de GA place deux spectrogrammes côte à côte et affirme qu'ils ont la même intensité. Si chaque image a été normalisée par son propre pic, qu'a réellement testé cette comparaison ? Un affichage peut préserver un motif tout en effaçant une différence de gain. Cette leçon rend cet échec visible avec des entrées connues, en prolongeant le principe d'échelle commune de [DV-007](dv-007-optick-partition-small-multiples.md).

Ouvrez la [figure à six panneaux](../../../../code/streeling/evidence/spectral-views-2026-10-22/spectrogram-reference-comparison.png) et son [relevé numérique](../../../../code/streeling/evidence/spectral-views-2026-10-22/display-comparison.json). Le [modèle de normalisation de Matplotlib](https://matplotlib.org/stable/users/explain/colors/colormapnorms.html) associe des limites numériques à des couleurs. Partager une palette et des limites numériques ne suffit qu'en partie à rendre les vues comparables : les valeurs qui leur sont fournies doivent aussi partager la référence voulue.

## 1. Identifier les traitements avant de comparer les couleurs

Les colonnes portent les étiquettes `B`, `C` et `0.5B`. Les deux premières sont la référence conservée et le véritable candidat de décroissance de l'expérience native de guitare précédente. La troisième est une copie construite de la référence décodée, multipliée par 0.5. C'est un témoin d'affichage, pas un autre rendu physique de guitare ni le véritable candidat. Les échantillons sont des entiers PCM16 décodés et divisés par 32768 ; [AUD-006](../../audio-engineering/en/aud-006-calibrate-spectral-amplitudes.md) explique l'estimateur d'amplitude appliqué avant le tracé.

La figure montre les fréquences jusqu'à 2000 Hz. Les coordonnées horizontales utilisent le temps de début de trame et des cellules d'affichage de la largeur d'un pas ; chaque trame analysée couvre toujours 2048 échantillons. [CS-013](../../computer-science/en/cs-013-preserve-spectral-axes-and-units.md) explique ce contrat de coordonnées. Les lettres et les étiquettes de formules sont communes aux langues ; ce texte en donne l'interprétation.

### Exercice 1 : identifier le témoin

Quelle paire isole un changement de gain exact et quelle paire compare les traitements de décroissance précédents ? Pourquoi qualifier les trois colonnes de rendus distincts du moteur affaiblirait-il le compte rendu de l'expérience ?

> **Réponse:** `B` comparé à `0.5B` isole le multiplicateur de gain construit de 0.5. `B` comparé à `C` compare la référence et le candidat de décroissance précédents. Le tableau à demi-gain a été créé à partir des échantillons décodés de référence sans autre exécution du moteur. Le qualifier de rendu distinct identifierait mal l'intervention et exagérerait les preuves d'exécution.

## 2. Donner une référence à la barre de couleurs, pas seulement une plage

La rangée supérieure utilise `20*log10(max(A/1,1e-4))`, avec une référence fixe d'amplitude crête de 1. Tous les panneaux utilisent des limites de couleur de -80 à 0 dB. La rangée inférieure divise d'abord chaque matrice complète par son propre maximum, puis utilise `20*log10(max(A/max(A),1e-4))` avec les mêmes limites numériques de couleur. Sa référence est le propre pic de chaque panneau. Les maxima sont calculés sur la matrice complète avant de recadrer la plage de fréquences visible.

Ce sont deux questions distinctes. La rangée supérieure conserve les différences d'amplitude par rapport à la référence commune déclarée lorsque l'écrêtage ne les masque pas. La rangée inférieure expose un motif relatif au pic de chaque matrice. Une même couleur dans des rangées différentes ne signifie donc pas nécessairement la même amplitude. Aucune rangée ne constitue un score de sonie, de réalisme ou de préférence, et l'estimateur d'amplitude n'est pas une mesure universelle des partiels individuels de guitare.

### Exercice 2 : interpréter une couleur identique

Deux cellules de la rangée inférieure ont la même couleur et la même valeur numérique. Quelle égalité cela peut-il établir avec la normalisation déclarée ? Cela établit-il l'égalité des amplitudes originales ou justifie-t-il de comparer directement cette couleur à celle de la rangée supérieure ?

> **Réponse:** Cela peut établir l'égalité du niveau affiché par rapport au maximum propre de chaque panneau, sous réserve de l'écrêtage au plancher. Cela n'établit pas l'égalité des amplitudes originales. La rangée supérieure utilise la référence commune de 1, tandis que la rangée inférieure utilise les maxima des panneaux ; une égalité de couleur entre rangées ne prouve donc pas une égalité d'amplitude selon une référence commune.

## 3. Utiliser un témoin qui doit disparaître sous la normalisation

Avant l'application du plancher, diviser l'amplitude par deux change sa valeur logarithmique de `20*log10(0.5)`, soit environ -6.02059991 dB. Le témoin calculé contient 6359 cellules dont les deux valeurs à référence fixe sont égales ou supérieures au plancher de -80 dB. Leurs différences mesurées concordent avec ce décalage à `1e-10` dB près. Les cellules masquées par le plancher ne peuvent pas démontrer que cette différence reste inchangée.

Pour la rangée relative, `max(0.5*A) = 0.5*max(A)` pour cette matrice non nulle. Diviser par le maximum du panneau annule le gain. La différence maximale calculée entre les vues relatives de référence et à demi-gain est de 0 dB. La normalisation réussit donc un test d'invariance du motif et ne permet pas de prouver que le gain d'entrée est resté inchangé. Le plancher est appliqué après le rapport ; l'appliquer plus tôt modifie ce raisonnement.

### Exercice 3 : prédire et vérifier la différence

Calculez le décalage attendu à référence fixe pour le multiplicateur 0.5 et expliquez pourquoi les images relatives coïncident. Quelles cellules faut-il exclure pour affirmer que chaque différence affichée à référence fixe vaut ce décalage ?

> **Réponse:** Le décalage est `20*log10(0.5)`, soit environ -6.02059991 dB. Dans la vue relative, le numérateur et le maximum sont tous deux divisés par deux ; leur rapport reste donc identique avant le plancher commun. Excluez les cellules écrêtées par le plancher dans l'un ou l'autre panneau à référence fixe ; leur différence affichée ne conserve pas nécessairement le décalage initial. Ce résultat concerne le témoin construit, pas le véritable candidat de décroissance.

## 4. Expliciter l'ordre du recadrage et de la normalisation

Si un affichage recalcule son maximum après chaque recadrage fréquentiel, zoomer peut recolorer des données inchangées. S'il conserve le maximum de la matrice complète comme cette figure, le recadrage modifie la visibilité en gardant cette référence fixe. Les deux choix peuvent avoir leur utilité, mais le lecteur doit savoir lequel a été utilisé. Sinon, un agent peut prendre une manipulation de la vue pour un changement dans un rendu de guitare.

### Exercice 4 : auditer un affichage changeant

Une personne chargée de la revue zoome sur une plage de fréquences plus étroite et voit les cellules conservées devenir plus claires, alors que les valeurs sources sont inchangées. Quel comportement de normalisation peut l'expliquer ? Énoncez la politique de cette figure et ce qu'un compte rendu de comparaison doit consigner ensemble.

> **Réponse:** Recalculer le maximum du panneau à partir de la plus petite région visible peut changer la référence et éclaircir des valeurs inchangées. Cette figure utilise le maximum de chaque matrice complète avant le recadrage fréquentiel. Associez les valeurs sources et leurs empreintes, l'estimateur de grandeur, le domaine de référence, le recadrage, le plancher et les limites de couleur pour qu'un autre lecteur puisse distinguer un changement de données d'un changement d'affichage.

## 5. Revenir à la mesure d'acceptation déclarée

Le [résultat précédent du critère de décroissance](../../../../code/streeling/evidence/guitar-runtime-2026-10-22/results.json) du véritable candidat reste un échec : amélioration d'environ 0.11416615 dB, amélioration requise de 1 dB. Ce nombre est une amélioration d'erreur selon la mesure de décroissance précédente ; le décalage du témoin d'environ -6.02059991 dB est une grandeur différente issue d'une intervention différente. Ne les combinez pas en un nouveau score d'acceptation.

### Exercice 5 : écrire une décision défendable

Un agent affirme : « Les images inférieures coïncident, donc le candidat est équivalent, le gain est inchangé et le critère de décroissance est réussi. » Remplacez cette affirmation par une décision étayée par cette expérience et précisez les preuves à recueillir ensuite pour une affirmation musicale plus large.

> **Réponse:** La référence et le témoin construit à demi-gain ont des vues relatives à leur panneau identiques avec la transformée et la normalisation déclarées, même si leurs amplitudes à référence fixe diffèrent. Cela n'établit ni l'équivalence du véritable candidat, ni un gain d'entrée inchangé, ni la réussite du critère de décroissance. Conservez l'échec du critère. Une affirmation musicale plus large exige une caractéristique ou une question d'écoute déclarée séparément, des entrées contrôlées et une comparaison exécutée adaptée à cette question.

## Limites des preuves

Le [compte rendu d'analyse](../../../../code/streeling/evidence/spectral-views-2026-10-22/execution.json) consigne les versions installées, l'empreinte de la figure et les vérifications des calculs. Le [protocole](../../../../code/streeling/evidence/spectral-views-2026-10-22/experiment-plan.md) distingue les prédictions, l'audio conservé et les témoins construits. Il s'agit d'un artefact d'affichage scientifique appuyé sur des preuves numériques, pas d'une extension d'éditeur déployée, d'un résultat d'écoute humaine ni d'un bénéfice d'apprentissage mesuré.
