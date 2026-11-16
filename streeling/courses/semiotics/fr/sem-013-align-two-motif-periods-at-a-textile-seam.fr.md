---
module_id: sem-013-align-two-motif-periods-at-a-textile-seam
department: semiotics
course: "Aligner deux périodes de motifs à une couture textile"
level: intermediate
prerequisites: ["sem-008-interpret-layer-order-relative-to-the-reference-normal"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Aligner deux périodes de motifs à une couture textile

> Brouillon soumis à une revue technique et linguistique. Chaque scène, nombre, température, durée et résultat introduit ci-dessous est un exemple construit. La lecture des sources et les calculs ne constituent ni un essai physique, ni un import [Godot](https://docs.godotengine.org/en/4.5/), ni un rendu [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), ni une exécution [ComfyUI](https://docs.comfy.org/), ni une observation d’apprentissage. Les décisions humaines et celles liées à l’exécution restent en attente.

## Question du projet

Un panneau tissé répète son ordre de croisements tandis qu’un repère brodé suit un autre cycle. Une jonction qui aligne le seul repère peut rompre le tissage. Nous composons deux contrats périodiques sur une même grille entière. La leçon ajoute une condition de phase pour plusieurs motifs au-delà de l’interprétation du fil supérieur dans un croisement isolé.

## Lire la limite conservée

Le jeu conservé indique une variante à parité globale et des coordonnées de grille. Il motive une adresse périodique des croisements, mais ne fournit aucun cycle de repères brodés. La seconde période est une hypothèse pédagogique explicite, pas une propriété cachée du jeu historique.

Lisez le prérequis et l’artefact conservé avant d’interpréter le modèle. La source a sa propre révision et son propre objectif ; elle fournit la limite décrite ici, pas les nouvelles données pédagogiques. Dressez un tableau distinguant un champ inspecté, une hypothèse, une quantité calculée et un effet envisagé dans la scène. Le résumé d’un agent doit renvoyer au champ interprété. Un nom de fichier ne suffit pas à établir un résultat antérieur.

## Interpréter le modèle

Une copie translatée conserve la phase d’un motif lorsque le déplacement est divisible par sa période. Les deux restes doivent être nuls pour conserver les deux motifs. Leur plus petit commun multiple donne la première répétition positive sous ces hypothèses. Distinguez période et phase : des périodes identiques peuvent avoir des origines différentes. Ici, les phases initiales sont nulles et seule une translation intervient. Retourner le textile, échanger chaîne et trame ou réfléchir le motif exigerait une autre interprétation. Une bordure visuellement proche ne remplace pas l’égalité d’adresses si l’identité sert aux requêtes de scène.

La référence directe est un croquis légendé et un calcul manuel, réalisés sans ouvrir les réponses. Conservez les valeurs intermédiaires et les unités, puis appliquez l’entrée modifiée du témoin négatif. Un désaccord est instructif : cherchez s’il provient de la définition, du calcul, de la représentation ou de la tâche avant de modifier le modèle. Un accord sur le seul cas principal n’établit pas une règle universelle. Ces exemples finis rendent explicite une hypothèse qu’un aperçu fluide pourrait masquer.

```text
{"periods_cells":[2,3],"shift_cells":6}
phase_remainders=[shift % p for p in periods]; compatible=all(remainder==0); joint_period=lcm(periods)
```

## Exercices corrigés

### Exercice 1

Vérifiez les restes des motifs pour le déplacement principal.

<details><summary>Réponse 1</summary>

Les restes de phase sont `[0,0]` : les deux phases déclarées sont conservées. Il s’agit d’une égalité d’adresses, pas d’une inspection visuelle.

</details>

### Exercice 2

Trouvez le premier déplacement positif conservant les deux motifs.

<details><summary>Réponse 2</summary>

La période commune vaut `6` cellules. Tout multiple commun convient ; le plus petit donne la première répétition avec les phases initiales nulles.

</details>

### Exercice 3

Appliquez le témoin au déplacement plus court.

<details><summary>Réponse 3</summary>

Les restes deviennent `[1,0]` : le repère est aligné mais l’autre cycle échoue. La compatibilité est donc fausse malgré un motif correctement aligné.

</details>

### Exercice 4

Les périodes seules définissent-elles complètement une couture ?

<details><summary>Réponse 4</summary>

Non. Il faut aussi origines ou déphasages, directions de grille et transformation de jonction. Le calcul suppose ici des phases initiales nulles.

</details>

### Exercice 5

La condition modulaire certifie-t-elle un tissu ou une texture sans raccord ?

<details><summary>Réponse 5</summary>

Non. Elle vérifie uniquement les phases discrètes déclarées. Géométrie, épaisseur, échantillonnage, continuité du matériau et fabrication restent distincts.

</details>

## Tâche avec consultation des sources

Dessinez les deux cycles sur une bande numérotée et vérifiez les déplacements manuellement. Repérez l’identité de grille et signalez le cycle brodé comme hypothèse ajoutée. Une couture alignant un seul cycle réfute une règle de compatibilité fondée sur un seul motif.

Conservez séparément votre réponse initiale, les passages consultés, l’historique de l’aide reçue et les corrections ultérieures. Énoncez le résultat observable qui réfuterait votre recommandation avant de proposer une automatisation. Comparez la réponse assistée par les sources à votre référence manuelle, en précisant l’incertitude supplémentaire. Le dossier contient cinq critères préparés ; chaque décision reste nulle jusqu’à une véritable tentative suivie d’une revue. Les corrigés servent de vérification ; ils ne prouvent pas qu’un apprenant a effectué la tâche.

## Sources et journal de validation

- [Prérequis: sem-008-interpret-layer-order-relative-to-the-reference-normal](../../semiotics/en/sem-008-interpret-layer-order-relative-to-the-reference-normal.md)
- [Artefact du projet conservé](../../../../code/streeling/evidence/weave-scene-2026-10-22/crossings.json)
- [Source primaire](https://docs.godotengine.org/en/4.5/tutorials/3d/using_transforms.html)
- [Dossier fixe des exemples](../../../../code/streeling/evidence/batch50-2026-10-24/unit-c.json)
- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
