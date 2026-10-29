---
module_id: phy-017-budget-thermal-growth-at-a-metal-joint
department: physics
course: "Prévoir la dilatation thermique à un joint métallique"
level: intermediate
prerequisites: ["phy-015-bound-clearance-after-thickening-a-panel"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Prévoir la dilatation thermique à un joint métallique

> Brouillon soumis à une revue technique et linguistique. Chaque scène, nombre, température, durée et résultat introduit ci-dessous est un exemple construit. La lecture des sources et les calculs ne constituent ni un essai physique, ni un import [Godot](https://docs.godotengine.org/en/4.5/), ni un rendu [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), ni une exécution [ComfyUI](https://docs.comfy.org/), ni une observation d’apprentissage. Les décisions humaines et celles liées à l’exécution restent en attente.

## Question du projet

Une bande de métal ciselé d’une sculpture envisagée laisse un jeu visible devant une butée fixe. Un agent peut conserver ce jeu dans le maillage en oubliant la température de référence. Cette leçon ajoute une référence thermique au prérequis sur le dégagement statique. Nous calculons une dilatation libre avec un coefficient explicitement inventé, puis distinguons un jeu prédit négatif d’une défaillance mesurée sur un joint réel.

## Lire la limite conservée

Atlas règle l’aspect métallique et la rugosité dans un utilitaire de matériau. Ces paramètres d’apparence ne précisent ni alliage ni coefficient de dilatation. La propriété physique absente reste une donnée pédagogique, sans être déduite d’un rendu brillant.

Lisez le prérequis et l’artefact conservé avant d’interpréter le modèle. La source a sa propre révision et son propre objectif ; elle fournit la limite décrite ici, pas les nouvelles données pédagogiques. Dressez un tableau distinguant un champ inspecté, une hypothèse, une quantité calculée et un effet envisagé dans la scène. Le résumé d’un agent doit renvoyer au champ interprété. Un nom de fichier ne suffit pas à établir un résultat antérieur.

## Interpréter le modèle

OpenStax présente une approximation linéaire de la dilatation. Ici, la longueur est celle de la température de référence, la variation thermique est une différence en kelvins et le coefficient s’exprime en kelvins inverses. La bande peut croître librement vers une butée immobile ; les efforts de retenue sont exclus. Soustrayez la dilatation au jeu initial, pas une température absolue. Un matériau visuel peut évoquer le métal sans fournir de loi mécanique. Le témoin ne change que la variation thermique et montre pourquoi un maillage identique ne garantit pas un dégagement identique sous une interprétation physique différente.

La référence directe est un croquis légendé et un calcul manuel, réalisés sans ouvrir les réponses. Conservez les valeurs intermédiaires et les unités, puis appliquez l’entrée modifiée du témoin négatif. Un désaccord est instructif : cherchez s’il provient de la définition, du calcul, de la représentation ou de la tâche avant de modifier le modèle. Un accord sur le seul cas principal n’établit pas une règle universelle. Ces exemples finis rendent explicite une hypothèse qu’un aperçu fluide pourrait masquer.

```text
{"length_mm":200,"alpha_per_K":2e-05,"delta_K":50,"gap_mm":0.3}
growth_mm=alpha_per_K*length_mm*delta_K; remaining_gap_mm=gap_mm-growth_mm
```

## Exercices corrigés

### Exercice 1

Calculez la dilatation libre. Quelles unités s’annulent ?

<details><summary>Réponse 1</summary>

La dilatation vaut `0.2 mm`. Les kelvins inverses annulent les kelvins ; il reste l’unité de longueur. Le coefficient est une entrée, pas une estimation tirée de l’apparence.

</details>

### Exercice 2

Quel jeu reste-t-il et quelle conclusion limitée en découle ?

<details><summary>Réponse 2</summary>

Le jeu restant vaut `0.1 mm`. Le modèle de dilatation libre prédit une séparation pour ces données ; aucune bande ni aucun contact réel n’ont été observés.

</details>

### Exercice 3

Appliquez le témoin à variation thermique plus élevée. Que signifie le jeu négatif ?

<details><summary>Réponse 3</summary>

La dilatation vaut `0.4 mm` et le jeu restant `-0.1 mm`. La géométrie libre chevauche la butée ; le modèle ne calcule pas la contrainte due à la retenue.

</details>

### Exercice 4

Un paramètre métallique de shader peut-il remplacer le coefficient de dilatation ?

<details><summary>Réponse 4</summary>

Non. Les paramètres d’apparence règlent un matériau visuel. Ils n’identifient ni l’alliage, ni la dépendance thermique, ni la retenue, ni le coefficient physique requis.

</details>

### Exercice 5

Qu’est-ce qui réfuterait l’application du modèle à une pièce artisanale précise ?

<details><summary>Réponse 5</summary>

Une dilatation mesurée hors de la marge d’erreur déclarée, une butée mobile, de forts gradients ou une croissance empêchée invalideraient une prémisse. Conservez l’écart au lieu de certifier la pièce.

</details>

## Tâche avec consultation des sources

Préparez une fiche du joint indiquant température de référence, longueur, jeu, provenance du coefficient et direction de croissance. Prenez un croquis manuel avant-après comme référence. Repérez les paramètres de matériau d’Atlas et signalez le champ physique absent, sans modifier le code.

Conservez séparément votre réponse initiale, les passages consultés, l’historique de l’aide reçue et les corrections ultérieures. Énoncez le résultat observable qui réfuterait votre recommandation avant de proposer une automatisation. Comparez la réponse assistée par les sources à votre référence manuelle, en précisant l’incertitude supplémentaire. Le dossier contient cinq critères préparés ; chaque décision reste nulle jusqu’à une véritable tentative suivie d’une revue. Les corrigés servent de vérification ; ils ne prouvent pas qu’un apprenant a effectué la tâche.

## Sources et journal de validation

- [Prérequis: phy-015-bound-clearance-after-thickening-a-panel](../../physics/en/phy-015-bound-clearance-after-thickening-a-panel.md)
- [Artefact du projet conservé](../../../../code/blender/scripts/atlas/kit.py)
- [Source primaire](https://openstax.org/books/university-physics-volume-2/pages/1-3-thermal-expansion)
- [Dossier fixe des exemples](../../../../code/streeling/evidence/batch50-2026-10-24/unit-c.json)
- [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
