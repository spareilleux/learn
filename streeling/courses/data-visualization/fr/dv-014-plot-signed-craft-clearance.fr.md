---
module_id: dv-014-plot-signed-craft-clearance
department: data-visualization
course: "Tracer le dégagement signé d’un assemblage artisanal"
level: intermediate
prerequisites: ["dv-006-position-length-area-comparisons"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Tracer le dégagement signé d’un assemblage artisanal

> Brouillon soumis à une revue technique et linguistique. Chaque scène, nombre, température, durée et résultat introduit ci-dessous est un exemple construit. La lecture des sources et les calculs ne constituent ni un essai physique, ni un import [Godot](https://docs.godotengine.org/en/4.5/), ni un rendu [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), ni une exécution [ComfyUI](https://docs.comfy.org/), ni une observation d’apprentissage. Les décisions humaines et celles liées à l’exécution restent en attente.

## Question du projet

Un tableau de bord donne une amplitude moyenne de dégagement et présente un fil en chevauchement comme un fil séparé. Le signe manquant change la décision de scène. Nous concevons une vue de positions divergentes avec ligne de contact visible, en conservant les lignes construites. La leçon prolonge l’échelle commune en traitant le zéro comme frontière d’interprétation physique, pas seulement comme origine d’axe.

## Lire la limite conservée

Le jeu de croisements conservé stocke des positions en millimètres et un indicateur de dessus lié aux rôles. Il ne contient pas de dégagements mesurés. Les valeurs signées sont pédagogiques ; le jeu motive le maintien des unités et de l’identité dans une annotation de scène envisagée.

Lisez le prérequis et l’artefact conservé avant d’interpréter le modèle. La source a sa propre révision et son propre objectif ; elle fournit la limite décrite ici, pas les nouvelles données pédagogiques. Dressez un tableau distinguant un champ inspecté, une hypothèse, une quantité calculée et un effet envisagé dans la scène. Le résumé d’un agent doit renvoyer au champ interprété. Un nom de fichier ne suffit pas à établir un résultat antérieur.

## Interpréter le modèle

Définissez une direction de dégagement avant de tracer. Dans cette coupe déclarée, une valeur négative indique un chevauchement, zéro un contact et une valeur positive une séparation. Placez chaque croisement identifié sur un axe signé commun avec ligne de contact légendée. L’amplitude décrit la distance au contact mais pas son côté. Une moyenne ne certifie pas non plus tous les croisements : un grand jeu positif peut masquer un chevauchement. Conservez le minimum et les effectifs par état. Cette table déterministe n’a pas d’incertitude de mesure ; toute barre d’erreur exigerait un modèle distinct.

La référence directe est un croquis légendé et un calcul manuel, réalisés sans ouvrir les réponses. Conservez les valeurs intermédiaires et les unités, puis appliquez l’entrée modifiée du témoin négatif. Un désaccord est instructif : cherchez s’il provient de la définition, du calcul, de la représentation ou de la tâche avant de modifier le modèle. Un accord sur le seul cas principal n’établit pas une règle universelle. Ces exemples finis rendent explicite une hypothèse qu’un aperçu fluide pourrait masquer.

```text
{"clearance_mm":[-0.4,0,0.2,0.8]}
minimum=min(clearance); overlap_count=count(c<0); contact_count=count(c==0); mean_absolute=sum(abs(c))/len(c)
```

## Exercices corrigés

### Exercice 1

Classez chaque ligne du cas principal par rapport au contact.

<details><summary>Réponse 1</summary>

Il y a `1` ligne en chevauchement, `1` en contact et `2` séparées. Les catégories suivent le signe déclaré, pas une préférence de couleur.

</details>

### Exercice 2

Calculez le minimum et la moyenne des valeurs absolues.

<details><summary>Réponse 2</summary>

Le minimum vaut `-0.4 mm` et la moyenne absolue `0.35 mm`. Cette dernière ne permet pas, seule, d’identifier un chevauchement.

</details>

### Exercice 3

Appliquez le témoin au signe modifié. Quelle statistique cache le changement ?

<details><summary>Réponse 3</summary>

Le minimum devient `0 mm`, le nombre de chevauchements `0` et la moyenne absolue reste `0.35 mm`. L’agrégation absolue masque le changement de côté.

</details>

### Exercice 4

Proposez une vue qui conserve la question sans dépendre de la couleur.

<details><summary>Réponse 4</summary>

Utilisez des lignes identifiées, des positions signées, une ligne de contact légendée, des valeurs exactes et des états textuels. La couleur ne doit pas porter seule le signe.

</details>

### Exercice 5

Un minimum non négatif prouve-t-il l’absence de collision pendant le mouvement ?

<details><summary>Réponse 5</summary>

Non. Les lignes décrivent une coupe fixe déclarée. Géométrie complète, mouvement, tolérances et croisements non observés exigent leurs propres preuves.

</details>

## Tâche avec consultation des sources

Dessinez manuellement les points signés et reliez chaque ligne à son identité de scène. Comparez cette vue à un résumé d’amplitudes et conservez le témoin. Un chevauchement invisible dans une vue censée garantir le dégagement réfute son aptitude revendiquée à soutenir cette tâche.

Conservez séparément votre réponse initiale, les passages consultés, l’historique de l’aide reçue et les corrections ultérieures. Énoncez le résultat observable qui réfuterait votre recommandation avant de proposer une automatisation. Comparez la réponse assistée par les sources à votre référence manuelle, en précisant l’incertitude supplémentaire. Le dossier contient cinq critères préparés ; chaque décision reste nulle jusqu’à une véritable tentative suivie d’une revue. Les corrigés servent de vérification ; ils ne prouvent pas qu’un apprenant a effectué la tâche.

## Sources et journal de validation

- [Prérequis: dv-006-position-length-area-comparisons](../../data-visualization/en/dv-006-position-length-area-comparisons.md)
- [Artefact du projet conservé](../../../../code/streeling/evidence/weave-scene-2026-10-22/crossings.json)
- [Source primaire](https://docs.godotengine.org/en/4.5/tutorials/3d/using_transforms.html)
- [Dossier fixe des exemples](../../../../code/streeling/evidence/batch50-2026-10-24/unit-c.json)
- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
