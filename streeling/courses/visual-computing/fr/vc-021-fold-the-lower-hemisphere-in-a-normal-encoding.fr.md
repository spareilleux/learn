---
module_id: "vc-021-fold-the-lower-hemisphere-in-a-normal-encoding"
department: "visual-computing"
course: "Replier l’hémisphère inférieur dans un encodage de normales"
level: "advanced"
prerequisites: ["phy-008-keep-surface-normals-perpendicular"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Replier l’hémisphère inférieur dans un encodage de normales

> Brouillon pour révision technique et linguistique. Entrées numériques, étiquettes et résultats attendus sont des cas pédagogiques construits. Ils ne constituent ni nouveaux essais matériels physiques, ni exécutions natives de scène, ni observations d’apprentissage, ni résultats de production. Les décisions humaines et d’apprentissage restent indécises.

## Opération du projet et interprétation

Un relief ciselé possède des normales orientées vers un axe de référence et à l’opposé. Ne stocker que les premières coordonnées après normalisation perd l’hémisphère. Le transfert compact proposé exige donc une application et son inverse explicites, sans supposer qu’une texture de normales regarde toujours vers l’avant. Ce cours dérive un encodage octaédrique réel. Il s’arrête avant quantification entière, échantillonnage de shader ou affirmation de performances mémoire.

Divisez d’abord par la somme des valeurs absolues des composantes : la direction se place sur un octaèdre. Dans l’hémisphère inférieur, repliez la paire vers l’extérieur avec les deux composantes originales. Le décodage reconstruit la profondeur depuis la somme absolue et déplie la paire lorsque cette profondeur est négative. La normalisation euclidienne finale rétablit la longueur unitaire. Une mise à jour en place est dangereuse : employer la première coordonnée déjà changée pour calculer la seconde modifierait l’application déclarée.

Le témoin sans repli conserve direction initiale et décodeur. Sa longueur unitaire plausible ne détecte pas l’erreur d’hémisphère ; le produit scalaire avec la direction initiale la révèle. Pour un futur asset de [ComfyUI](https://docs.comfy.org/) vers [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md) ou [Godot](https://docs.godotengine.org/en/4.5/), conservez convention d’encodage et interprétation de texture avec les données. La longueur unitaire ne certifie ni direction, ni repère tangent, ni apparence de fibres brodées. Le réviseur assisté doit identifier le prédicat qui détecte réellement ce témoin.

Pour une composante exactement nulle, l’application construite utilise `sign(0)=1`. Les coordonnées repliées utilisent simultanément la paire initiale ; la profondeur négative est testée avant normalisation euclidienne.

Lisez le prérequis commité et le passage primaire délimité avant de calculer. Préparez un relevé séparant définition de source, prémisse construite, résultat dérivé et observation future. Une documentation ne soutient que l’affirmation située dans son périmètre lu. Paramètre de source, réponse mathématique et observation d’exécution ont des rôles de preuve différents ; un résumé assuré d’assistant ne peut les échanger. Le paquet conserve révision et périmètre de lecture pour permettre de contester une affirmation précise.

Travaillez d’abord réponses fermées. Dessinez la table ou le schéma requis et conservez les quantités intermédiaires, avec unités ou conventions d’identité. Cette dérivation manuscrite est la référence manuelle directe. Consultez seulement ensuite un assistant ou une aide à la traduction. Gardez la question, l’emplacement cité, la suggestion reçue et la modification acceptée ou rejetée. Comparez le résultat assisté à la première tentative conservée sur les mêmes entrées. Une réponse plus courte ne constitue pas un progrès si elle omet une condition ou invente un essai terminé.

## Modèle fixe et témoin à entrée modifiée

```json
{
  "values": {
    "vector": [
      1,
      2,
      -1
    ],
    "fold_lower": true
  },
  "formula": "p=v/(abs(x)+abs(y)+abs(z)); uv=(p.x,p.y); if p.z<0 and fold_lower: uv=((1-abs(p.y))*sign(p.x),(1-abs(p.x))*sign(p.y)); q=(u,v,1-abs(u)-abs(v)); if q.z<0 unfold xy using old coordinates; decoded=q/length(q); agreement=dot(decoded,original/length(original))",
  "expected": {
    "encoded": [
      0.5,
      0.75
    ],
    "decoded_normal": [
      0.4082482904638631,
      0.8164965809277261,
      -0.4082482904638631
    ],
    "agreement": 1
  },
  "negative_control": {
    "values": {
      "vector": [
        1,
        2,
        -1
      ],
      "fold_lower": false
    },
    "expected": {
      "encoded": [
        0.25,
        0.5
      ],
      "decoded_normal": [
        0.4082482904638631,
        0.8164965809277261,
        0.4082482904638631
      ],
      "agreement": 0.6666666666666666
    }
  }
}
```

### Exercice 1

Trouvez les coordonnées sur l’octaèdre.

<details><summary>Réponse 1</summary>

Elles valent `[0.25,0.5,-0.25]`. La composante finale négative exige la branche inférieure avant stockage.

</details>

### Exercice 2

Calculez la paire stockée.

<details><summary>Réponse 2</summary>

Elle vaut `[0.5,0.75]`. Calculez les composantes depuis la paire initiale, sans écrasement séquentiel.

</details>

### Exercice 3

Vérifiez la direction décodée.

<details><summary>Réponse 3</summary>

Sa profondeur reste négative et l’accord vaut `1`. La normalisation change la norme en préservant la direction décodée.

</details>

### Exercice 4

Évaluez le témoin sans repli.

<details><summary>Réponse 4</summary>

La paire devient `[0.25,0.5]` ; la profondeur décodée devient positive et l’accord tombe à `0.6666666666666666`. La longueur unitaire reste satisfaite.

</details>

### Exercice 5

Cela établit-il un format de texture moteur ?

<details><summary>Réponse 5</summary>

Non. Le modèle ne définit ni quantification entière, ni convention de canaux, ni exécution de shader. Ces éléments doivent être liés séparément.

</details>

## Travail avec sources et référence manuelle directe

Préparez une trace papier d’encodage et décodage d’une normale de relief. Comparez contrôle de longueur seule et contrôle de direction originale, puis proposez les métadonnées de texture manquantes au transfert.

Traitez le témoin comme un enregistrement distinct. Préservez le cas principal, écrivez une prédiction pour l’entrée modifiée et expliquez quelle prémisse change. En cas d’écart avec la première réponse, distinguez erreur de calcul, erreur d’interprétation et limite du modèle. Gardez tentative échouée et correction côte à côte. Le travail demande une note vérifiable avant de proposer un nœud DSL ou un flux d’agents ; une table manuelle peut déjà répondre au besoin.

Soumettez ensemble référence initiale, emplacements de sources, explication corrigée, résultat du témoin et critère de réfutation. Les critères préparés ci-dessous s’adressent à une révision future ; ils ne sont pas des apprentissages acceptés. Réponse réelle, historique d’aide, correction et décision restent vides jusqu’à conservation d’une tentative. Révision technique, révision linguistique, exécution, adoption en production et publication exigent chacune leurs preuves applicables. Un calcul fini réussi établirait seulement l’opération déclarée dans ses hypothèses.

## Critère de réfutation annoncé

L’affirmation que supprimer la profondeur préserve cette direction est réfutée par le changement d’hémisphère et de produit scalaire du témoin.

## Critères d’apprentissage préparés

- Pour l’exercice 1: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 2: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 3: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 4: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 5: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.

## Sources et périmètre des affirmations

- [Prérequis commité: phy-008-keep-surface-normals-perpendicular](../../physics/en/phy-008-keep-surface-normals-perpendicular.md)
- [Source de projet conservée](../../../../code/blender/scripts/atlas/kit.py)
- [Lecture primaire](https://pbr-book.org/4ed/Geometry_and_Transformations/Spherical_Geometry)
- [Paquet construit](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-c.json)
- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
