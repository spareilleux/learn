---
module_id: vc-010-preserve-packed-texture-channel-contracts
department: visual-computing
course: "Préserver les contrats de canaux des textures regroupées"
level: intermediate
prerequisites: ["vc-005-craft-details-through-blender-to-godot", "phy-009-distinguish-linear-color-from-display-encoding"]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Préserver les contrats de canaux des textures regroupées

> **Portée du brouillon.** Code public du producteur et du consommateur à une révision précise, inspection de deux PNG publics existants et calcul d'un texel conçu pour le cours. La revue technique humaine, la relecture par des personnes maîtrisant la langue, les essais avec des apprenants et la vérification du HTML du cours déployé restent à effectuer. Aucun nouveau précalcul, aucune génération [ComfyUI](https://docs.comfy.org/), aucune exécution de shader ou d'importation ni aucun résultat de déplacement géométrique n'ont été observés.

## La question du projet

Un agent exporte une surface travaillée sous la forme d'« une seule texture RGBA ». Cette description omet le sens de chaque canal. Le [script public de précalcul des textures BRUTAL](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/textures/bake_blender.py) regroupe deux composantes de carte de normales, la rugosité et un indicateur de hauteur. Son [script de génération](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/textures/generate_comfyui.py) décrit un flux de travail [ComfyUI](https://docs.comfy.org/) en amont ; aucun des deux scripts n'a été exécuté pour ce cours. Toutes les observations du projet utilisent la révision publique de GA `76efbffd5af82b46c3146957a6bd4504008eeb89`.

[PHY-009](../../physics/en/phy-009-distinguish-linear-color-from-display-encoding.md) a établi pourquoi les coordonnées de couleur exigent un encodage déclaré. Les données regroupées exigent un contrat supplémentaire : les quatre mêmes nombres stockés peuvent n'avoir aucun sens de couleur ou de transparence.

## 1. Consigner les rôles des canaux du producteur

Le script déclare la sortie regroupée comme Non-Color, tout en déclarant sa sortie d'albédo sRGB. L'ordre de regroupement est explicite :

| Canal | Valeur du producteur | Interprétation prévue |
| --- | --- | --- |
| R | normale X précalculée | composante directionnelle encodée |
| G | normale Y précalculée | composante directionnelle encodée |
| B | premier canal de rugosité précalculée | données de rugosité |
| A | RGB pondéré du tampon d'albédo | indicateur de hauteur |

Le champ alpha n'est pas l'opacité, et le bleu n'est pas la normale Z. La normale Z précalculée est omise. La hauteur est dérivée des valeurs d'image ; aucune épaisseur physique, échelle de déplacement géométrique ou topographie mesurée n'en découle. Les [consignes de gestion des couleurs de Blender 4.5](https://docs.blender.org/manual/en/4.5/render/color_management.html) distinguent également les données non colorimétriques de normales ou de déplacement des images de couleur. Ce cours ne suppose rien de la transformation de visualisation par défaut actuellement utilisée par un environnement.

### Exercice 1 : rejeter le mauvais importateur générique

Un importateur traite RGB comme un vecteur normal complet et alpha comme l'opacité. Quels sont les deux sens de canaux incompatibles avec ce producteur ? La texture regroupée contient-elle la normale Z précalculée ?

> **Réponse:** Le bleu est la rugosité, et non la normale Z ; alpha est un indicateur de hauteur, et non l'opacité. Le producteur ne regroupe pas la normale Z précalculée. Un importateur générique de normales et d'opacité imposerait un autre contrat ; on ne peut pas supposer qu'il préserve cette texture.

## 2. Décoder les données normalisées sans transformation de couleur

Le [texel conçu pour le cours](../../../../code/streeling/evidence/color-contract-2026-10-22/packed-texel-calculations.json) possède les octets 128, 128, 128 et 64. Diviser par 255 donne environ 0.5019607843137255 pour chaque canal RGB et 0.25098039215686274 pour alpha. Décoder RG signé avec `2*v-1` donne environ 0.0039215686274509665 par composante. L'octet 128 est proche du milieu de l'intervalle signé, sans être exactement à ce milieu.

Appliquer d'abord le décodage de couleur sRGB défini par morceaux à RGB donnerait plutôt environ 0.21586050011389926 et un RG signé d'environ -0.5682789997722015. Cela modifie l'interprétation des données. Ce n'est pas une simple correction d'affichage sans conséquence sur une photographie en couleur.

### Exercice 2 : détecter des données transformées

Décodez l'octet rouge pédagogique 128 comme une donnée signée normalisée. Comparez avec un décodage sRGB préalable. L'octet alpha 64 doit-il automatiquement rendre le matériau partiellement transparent ?

> **Réponse:** Le décodage direct des données normalisées donne environ 0.0039215686274509665 ; le décodage de couleur préalable donne environ -0.5682789997722015 après passage à l'intervalle signé. Alpha est l'indicateur de hauteur selon ce contrat ; l'octet 64 ne déclare donc aucune transparence.

## 3. Suivre le consommateur, et pas seulement le nom du fichier

Le [shader de matériau](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs#L587-L655) à la révision fixée lit RG comme un signal de relief signé et B comme la rugosité dans les parcours béton, façade, bardage et machine examinés. Ces parcours ne lisent pas l'alpha regroupé pour déplacer la géométrie et n'y reconstruisent pas la normale Z. Ne présentez pas leur signal de relief comme une reconstruction complète et sans perte d'une normale unitaire.

La façade utilise directement la valeur bleue. Le béton, en ignorant son ajustement de pluie distinct pour ce témoin, transforme le bleu par `0.75+0.2*B`. Le bleu pédagogique donne donc environ 0.850392156862745 pour cette expression du béton. Un décodage sRGB préalable incorrect donnerait environ 0.7931721000227798. L'interprétation des paramètres et la transformation propre au matériau sont des étapes distinctes.

### Exercice 3 : distinguer conservation et utilisation

L'indicateur de hauteur alpha est conservé dans le PNG. Cela établit-il que le shader examiné déplace la géométrie ? Calculez l'expression de rugosité du béton pour le bleu pédagogique selon le témoin sans pluie déclaré.

> **Réponse:** Non. Des données stockées ne prouvent pas leur utilisation par le consommateur ; les parcours examinés ne lisent pas l'alpha regroupé pour le déplacement géométrique. L'expression sans pluie donne environ 0.850392156862745. Cette valeur isolée n'est ni un rendu de matériau observé ni une sortie complète affectée par la pluie.

## 4. Vérifier séparément les métadonnées de l'artefact réel

L'[inspection des fichiers existants](../../../../code/streeling/evidence/color-contract-2026-10-22/public-texture-inspection.json) lit les PNG d'albédo et de données regroupées du béton à la révision fixée. Les deux fichiers mesurent 512 par 512, sont en RGBA sur 8 bits et contiennent tous deux des blocs sRGB, gAMA et cHRM. Les métadonnées de couleur du fichier regroupé ne communiquent donc pas le contrat de données Non-Color déclaré par le script.

Cet écart est une preuve à conserver. Il ne prouve pas que ce script et cet environnement précis ont généré le fichier vérifié, que les valeurs ont déjà subi un décodage de couleur par un environnement particulier ou que tous les actifs du projet partagent les mêmes métadonnées. Le chargeur BRUTAL examiné lit les octets de pixels pris en charge sans interpréter ces blocs de couleur ; d'autres importateurs peuvent suivre des politiques différentes. Une extension de fichier ou une balise ne suffit pas à établir le sens des canaux.

### Exercice 4 : rapprocher une déclaration et un fichier

Le script déclare Non-Color, mais le PNG regroupé à la révision fixée contient un bloc sRGB. Un agent peut-il supposer un nouveau précalcul correct ou supprimer silencieusement cet écart de sa transmission ? Énoncez l'observation limitée.

> **Réponse:** Non. Conservez le fait que le fichier regroupé examiné de 512 par 512 en RGBA sur 8 bits possède des métadonnées de couleur, tandis que le script déclare une sortie non colorimétrique. Aucun nouveau précalcul ni historique exact de génération n'ont été établis. L'interprétation de la destination doit être testée plutôt que déduite de la seule déclaration.

## 5. Préparer une vérification du transfert propre à l'environnement

La [documentation des shaders de Godot 4.6](https://docs.godotengine.org/en/4.6/tutorials/shaders/shader_reference/shading_language.html#using-source-color) distingue les textures de couleur sRGB utilisant `source_color` des données de normales, de rugosité et de hauteur. Ses consignes propres au moteur de rendu comptent ; elles ne prouvent pas qu'une importation particulière a été testée. Appliquer aveuglément un indicateur standard de carte de normales à toute cette texture regroupée ignorerait aussi que le bleu contient la rugosité.

Une transmission proposée devrait identifier la révision de l'actif, les rôles de chaque canal, les plages numériques, la politique de couleur ou de données et les transformations du consommateur. Testez un texel connu après importation et vérifiez indépendamment le canal visé avant de juger la surface complète. Ajouter un canal de hauteur à un fichier n'implémente pas le déplacement géométrique, et reconnaître le contrat n'autorise pas une modification non testée du shader de production.

### Exercice 5 : choisir la prochaine action vérifiable

Un agent propose de traiter toute la texture regroupée comme un albédo avec `source_color`, puis déclare le transfert de la surface terminé. Quel test d'importation plus petit permettrait de distinguer les interprétations, et qu'est-ce qui reste à réaliser ?

> **Réponse:** Utilisez un texel regroupé connu et vérifiez que la destination préserve ses valeurs de données et les rôles RG/B/A déclarés selon une politique délibérée d'importation et d'échantillonnage. Un décodage de couleur de toute la texture de données ne correspond pas au contrat déclaré. L'importation réelle dans l'environnement, l'utilisation par le shader, le déplacement géométrique, la qualité du matériau rendu et les résultats des apprenants restent à évaluer ici.

## Travail de l'apprenant avec accès aux sources

Effectuez le [travail préparé](../../../../code/streeling/evidence/color-contract-2026-10-22/learner-task.md) en suivant un texel à travers le producteur, les métadonnées stockées et le consommateur visé. Gardez l'écart de métadonnées explicite et proposez une vérification concrète dans l'environnement cible.
