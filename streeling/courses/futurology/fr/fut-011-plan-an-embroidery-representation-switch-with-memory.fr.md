---
module_id: fut-011-plan-an-embroidery-representation-switch-with-memory
department: futurology
course: "Préparer un changement de représentation de broderie avec mémoire"
level: intermediate
prerequisites: ["fut-005-value-a-renderer-pilot-before-running-it","cyb-005-stop-render-policy-flapping"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Préparer un changement de représentation de broderie avec mémoire

> Brouillon soumis à une revue technique et linguistique. Chaque scène, nombre, température, durée et résultat introduit ci-dessous est un exemple construit. La lecture des sources et les calculs ne constituent ni un essai physique, ni un import [Godot](https://docs.godotengine.org/en/4.5/), ni un rendu [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), ni une exécution [ComfyUI](https://docs.comfy.org/), ni une observation d’apprentissage. Les décisions humaines et celles liées à l’exécution restent en attente.

## Question du projet

Le cours antérieur CYB005 enseigne déjà hystérésis, persistance, temps de maintien et comparaison avec une règle sans mémoire. Rejouer cette idée dans un visualiseur de broderie sert seulement de référence. Nous ajoutons une autre question : si l’empreinte projetée d’un point est donnée par un intervalle, quelles transitions sont imposées et quels états de la règle à largeur exacte restent possibles ? La nouvelle opération propage des ensembles d’états admissibles au lieu de masquer l’incertitude dans un milieu d’intervalle.

## Lire la limite conservée

L’argument de résolution du pipeline ne fournit ni ces intervalles ni un changement de représentation. Godot4.5 documente l’hystérésis avec des marges de distance. Nos intervalles sont des ensembles admissibles de pixels construits pour une vue envisagée ; ce ne sont ni des bornes mesurées, ni des distributions, ni des intervalles de confiance calibrés. Le cours compagnon VC014 calcule une empreinte ponctuelle avec une caméra déclarée ; sa lecture est facultative et ne constitue pas un prérequis antérieur.

Lisez le prérequis et l’artefact conservé avant d’interpréter le modèle. La source a sa propre révision et son propre objectif ; elle fournit la limite décrite ici, pas les nouvelles données pédagogiques. Dressez un tableau distinguant un champ inspecté, une hypothèse, une quantité calculée et un effet envisagé dans la scène. Le résumé d’un agent doit renvoyer au champ interprété. Un nom de fichier ne suffit pas à établir un résultat antérieur.

## Interpréter le modèle

Distinguez trois interprétations. Rejouez d’abord les largeurs ponctuelles fournies, situées dans leurs intervalles sans être nécessairement leurs milieux avec la règle d’hystérésis antérieure. Définissez ensuite une politique prudente : depuis la texture, passez au maillage seulement si tout l’intervalle fermé atteint ou dépasse le seuil d’entrée ; depuis le maillage, quittez-le seulement si la borne supérieure est strictement sous le seuil de sortie ; sinon conservez l’état. Ce choix de politique ne révèle pas l’état réel de la règle à largeur exacte inconnue.

Enfin, partez de l’état initial déclaré et propagez tous les états atteignables. Depuis la texture, le maillage est possible si la borne supérieure atteint l’entrée, et la texture reste possible si la borne inférieure est sous l’entrée. Depuis le maillage, la texture est possible si la borne inférieure est sous la sortie, et le maillage reste possible si la borne supérieure atteint la sortie. Prenez l’union sur tous les états précédents. Un intervalle chevauchant un seuil peut créer deux possibilités ; des intervalles suivants dans la bande peuvent conserver les deux. Ne propagez pas seulement l’état prudent et ne remplacez pas silencieusement l’intervalle par son milieu. Bornes fermées et sortie strictement inférieure fixent les cas d’égalité. Les ensembles admissibles sont indépendants à chaque échantillon, sans contrainte cachée sur la vitesse de variation.

La référence directe est un croquis légendé et un calcul manuel, réalisés sans ouvrir les réponses. Conservez les valeurs intermédiaires et les unités, puis appliquez l’entrée modifiée du témoin négatif. Un désaccord est instructif : cherchez s’il provient de la définition, du calcul, de la représentation ou de la tâche avant de modifier le modèle. Un accord sur le seul cas principal n’établit pas une règle universelle. Ces exemples finis rendent explicite une hypothèse qu’un aperçu fluide pourrait masquer.

```text
{"widths_px":[2.5,1.9,2.1,1.8,1.1,1.4,2.5],"enter_mesh_px":2.4,"exit_mesh_px":1.2,"initial_mesh":false,"width_intervals_px":[[2.3,2.5],[1.8,2],[2,2.2],[1.7,1.9],[1.1,1.3],[1.3,1.5],[2.4,2.6]]}
Start state=initial_mesh; if state is false and width>=enter_mesh set true; else if state is true and width<exit_mesh set false; emit state; count transitions including from initial state; for closed interval[lo,hi], robust false->true only if lo>=enter, true->false only if hi<exit, otherwise retain; separately propagate reachable states from initial state: from false include true if hi>=enter and false if lo<enter; from true include false if lo<exit and true if hi>=exit; union across preceding reachable states; sort false before true; ambiguous sample numbers are1-based
```

Le témoin conserve les mêmes intervalles et largeurs ponctuelles fournies, avec les deux seuils fixés à `2 px`.

## Exercices corrigés

### Exercice 1

Rejouez les largeurs ponctuelles fournies avec seuils distincts puis confondus. Quelle partie est déjà enseignée par CYB005 ?

<details><summary>Réponse 1</summary>

Les séquences des valeurs ponctuelles fournies sont `[true,true,true,true,false,false,true]` avec `3` changements et `[true,false,true,false,false,false,true]` avec `5` changements. Hystérésis, état conservé et comparaison sans mémoire viennent de CYB005 ; ce rejeu est une référence, pas le nouveau résultat.

</details>

### Exercice 2

Appliquez la politique prudente aux intervalles avec seuils distincts. Comptez les changements depuis l’état initial déclaré.

<details><summary>Réponse 2</summary>

La séquence prudente est `[false,false,false,false,false,false,true]`, avec `1` changement. Le premier intervalle chevauche l’entrée et ne l’impose donc pas ; à l’échantillon7, la borne inférieure atteint l’entrée et l’impose. La borne supérieure doit être strictement sous la sortie pour imposer le départ.

</details>

### Exercice 3

Propagez tous les états compatibles avec les seuils distincts et les intervalles. Une observation dans la bande supprime-t-elle l’ambiguïté antérieure ?

<details><summary>Réponse 3</summary>

Les états possibles sont `[false,true]` aux échantillons `1,2,3,4,5,6`, puis `[true]` à l’échantillon7. L’ambiguïté du premier intervalle persiste dans la bande. On propage les deux états antérieurs au lieu de décider par le milieu ou par le seul état prudent.

</details>

### Exercice 4

Appliquez le témoin aux seuils confondus aux deux interprétations par intervalles. Expliquez l’égalité à l’échantillon2.

<details><summary>Réponse 4</summary>

La séquence prudente du témoin est `[true,true,true,false,false,false,true]`, avec `3` changements. Les ensembles atteignables sont `[[true],[false,true],[true],[false],[false],[false],[true]]` ; seul l’échantillon2 est ambigu. Cet intervalle atteint `2 px`, soit la sortie : partir exige une valeur strictement inférieure ; l’égalité conserve le maillage.

</details>

### Exercice 5

L’accord des trajectoires ponctuelles, moins de changements prudents ou moins d’états atteignables autorisent-ils cette politique ?

<details><summary>Réponse 5</summary>

Non. Ces intervalles sont des ensembles admissibles construits, pas une incertitude mesurée ni une confiance calibrée. La règle prudente est une autre politique, pas l’état connu de la règle à largeur exacte. Reconnaissance, transitions visibles, coût, validité des intervalles et correspondance avec l’hôte restent non testés. Godot4.5 documente des marges de distance ; nos intervalles en pixels ne les configurent pas.

</details>

## Tâche avec consultation des sources

Avant les corrigés, dessinez les sept intervalles fermés et deux tables distinctes : la politique prudente à état unique et tous les états atteignables de la règle à largeur exacte. Conservez les deux branches dans la bande, comparez le témoin et nommez une mesure future qui réfuterait la couverture supposée. Citez CYB005 et le compagnon facultatif VC014 ; aucun moteur n’est configuré et aucun essai de reconnaissance n’est revendiqué.

Conservez séparément votre réponse initiale, les passages consultés, l’historique de l’aide reçue et les corrections ultérieures. Énoncez le résultat observable qui réfuterait votre recommandation avant de proposer une automatisation. Comparez la réponse assistée par les sources à votre référence manuelle, en précisant l’incertitude supplémentaire. Le dossier contient cinq critères préparés ; chaque décision reste nulle jusqu’à une véritable tentative suivie d’une revue. Les corrigés servent de vérification ; ils ne prouvent pas qu’un apprenant a effectué la tâche.

## Sources et journal de validation

- [Prérequis: fut-005-value-a-renderer-pilot-before-running-it](../../futurology/en/fut-005-value-a-renderer-pilot-before-running-it.md)
- [Prérequis: cyb-005-stop-render-policy-flapping](../../cybernetics/en/cyb-005-stop-render-policy-flapping.md)
- [Compagnon facultatif: vc-014-predict-an-embroidered-stitch-pixel-footprint](../../visual-computing/en/vc-014-predict-an-embroidered-stitch-pixel-footprint.md)
- [Artefact du projet conservé](../../../../code/blender/scripts/glb_pipeline.py)
- [Source primaire](https://docs.godotengine.org/en/4.5/tutorials/3d/visibility_ranges.html)
- [Dossier fixe des exemples](../../../../code/streeling/evidence/batch50-2026-10-24/unit-c.json)
- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
