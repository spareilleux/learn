---
module_id: vc-007-weave-seams-as-scene-contracts
department: visual-computing
course: "Préserver les croisements du tissage à travers une frontière de scène Godot"
level: intermediate
prerequisites: [vc-005-craft-details-through-blender-to-godot]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
research_cycle: visual-computing-2026-10-12-007
version: "0.1.0"
---

# Préserver les croisements du tissage à travers une frontière de scène Godot

> **Périmètre du brouillon et des traductions.** Le texte technique ci-dessous est un brouillon daté. Les mentions historiques de traductions, d’intégration dans Learn ou de vérifications de publication encore à faire concernent cette étape antérieure ; ce [dossier de traduction](../../../../code/streeling/evidence/locale-completion-2026-10-22/README.md) recense les brouillons actuels et les contrôles effectués. Les essais en conditions réelles encore non réalisés le restent. Les revues humaines du contenu et de la langue, ainsi que l’essai avec un apprenant, restent à effectuer.

> **Département d'informatique visuelle** | Intermédiaire | 40 minutes | Brouillon français ; fixture synthétique de croisements, aucun import Godot, essai d'apprenant, révision humaine ou publication ; approbation par une personne maîtrisant le français en attente

## Objectifs et question du projet

Après cette leçon, vous saurez distinguer l'ordre des croisements d'un tissage de son apparence rendue, repérer une erreur de composition à la jonction de motifs, donner aux croisements des identités stables et concevoir une condition de scène Godot capable de rejeter un échantillon visuellement séduisant mais incorrect. **Question du projet :** si un détail tissé devient un objet de l'observatoire Godot proposé, comment sa structure dessus/dessous peut-elle survivre à la répétition et au rendu ? C'est un modèle de tissage toile volontairement restreint, pas une simulation de tension des fils, une affirmation d'histoire textile ou une fonctionnalité Godot terminée.

[VC-005](vc-005-craft-details-through-blender-to-godot.md) demande si le nettoyage de maillage Blender peut effacer un petit détail artisanal. Cette leçon vérifie ce qui survit au pipeline d'asset. Ici, la défaillance peut survenir plus tôt : un motif peut être composé en un arrangement erroné avant qu'un maillage existe. Un [plan d'intégration Godot GA figé](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/docs/plans/parked/2026-03-28-feat-godot-integration-plan.md) esquisse un observatoire, mais sa scène proposée ne prouve pas l'importation de cet échantillon. La [fixture et l'évaluateur](https://github.com/GuitarAlchemist/Demerzel/tree/f23ccae6c049d9066a1be2221c68f3b0bcf48373/state/streeling/fixtures/visual-computing/vc-007) de ce cours sont exécutables, synthétiques et indépendants d'un moteur de rendu.

## 1. Placer la sémantique artisanale avant les pixels

La fixture commence par un motif de 3 par 3 croisements. Un fil de chaîne suit une direction déclarée et un fil de trame l'autre. Aux coordonnées globales `(x, y)`, la règle simplifiée place la chaîne au-dessus de la trame lorsque `(x + y + phase) % 2 == 0` ; sinon, la trame passe au-dessus de la chaîne. `phase = 0`. Cette règle est une abstraction choisie pour l'exercice. Structures textiles, matériaux et pratiques réels peuvent être plus variés. Le contrat exige seulement que l'alternance toile *déclarée* reste vraie après composition.

La fixture répète le motif deux fois dans chaque direction, donnant six positions de chaîne, six de trame et `6 × 6 = 36` croisements. La paire `(x, y)` reçoit l'ID `w<x>-f<y>`. Les ID sont globaux : `w3-f0` désigne donc le même croisement avant et après génération d'un maillage ou d'une scène. Couleur du matériau, position de caméra et hauteur apparente des fils peuvent aider, mais ne remplacent ni cette identité ni sa valeur dessus/dessous. Le moteur devrait recevoir le manifeste validé ; il ne devrait pas inventer une nouvelle règle à partir d'un prompt ou d'un shader.

### Exercice 1 : nommer le croisement

À phase nulle, quels sont les ID et valeurs dessus/dessous à `(2, 0)` et `(3, 0)` ? Pourquoi faut-il attribuer les ID avant le rendu de scène ?

> **Réponse :** Les ID sont `w2-f0` et `w3-f0`. Puisque `2 + 0` est pair, la chaîne passe dessus à `w2-f0` ; puisque `3 + 0` est impair, la trame passe dessus à `w3-f0`. Des ID stables permettent au test d'import de comparer la scène au manifeste source et de situer un croisement erroné. Une capture seule ne permet pas d'établir quel croisement représente une surbrillance visible.

## 2. Trouver la jonction qu'un test local de motif manque

Il existe deux façons de répéter le motif. La **parité globale** évalue la règle sur toutes les coordonnées 6 par 6. La **parité redémarrée par motif** évalue `x % 3` et `y % 3` dans chaque copie. Chaque motif de 3 par 3 alterne localement selon la règle redémarrée. Mais sa largeur étant impaire, sa dernière colonne et la première du motif suivant indiquent toutes deux chaîne-dessus sur la première ligne. La jonction verticale présente un défaut analogue. C'est une erreur de composition, pas un problème de texture.

Exécutez `python state/streeling/fixtures/visual-computing/vc-007/evaluate_weave.py` depuis la racine Demerzel avec l'[entrée d'essai locale](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/visual-computing/vc-007/weave-trial.json). Il énumère les 36 croisements selon chaque règle, vérifie les paires adjacentes horizontalement et verticalement et rapporte les ID précis en violation. Pour cette fixture, la parité globale produit 0 violation d'adjacence ; la parité redémarrée en produit 12. Six sont des paires de jonction horizontale et six de jonction verticale. À l'intersection des jonctions, deux paires adjacentes distinctes sont rapportées ; on compte des *relations* violées, pas des pixels fautifs ou des ID de croisements uniques. L'évaluateur rejette aussi un échantillon dont le diamètre des fils est supérieur ou égal à leur espacement. Son rapport espacement/diamètre `5 / 2 = 2.5` est un simple contrôle de cohérence d'entrée ; ce n'est pas une preuve de jeu physique ou d'absence de collision.

### Exercice 2 : situer le premier contre-exemple

La première ligne du résultat redémarré est `warp, weft, warp, warp, weft, warp`. Quelle paire adjacente échoue et quelle devrait être la quatrième valeur selon la règle globale ? Un aperçu correct de 3 par 3 valide-t-il l'échantillon de 6 par 6 ?

> **Réponse :** `w2-f0` et `w3-f0` indiquent tous deux chaîne-dessus ; la paire viole donc l'alternance. En parité globale, `w3-f0` devrait indiquer trame-dessus. Un aperçu local correct ne valide pas la composition, car il n'examine jamais la frontière entre motifs.

## 3. Distinguer identité, sémantique et géométrie

Un manifeste d'export d'essai devrait porter empreinte du programme source, ID d'échantillon, dimensions, convention d'échelle physique, ID stables des croisements et leurs valeurs dessus/dessous. Le JSON fourni est une *spécification d'essai* dont l'évaluateur dérive ces valeurs ; ce n'est pas un manifeste Godot exporté. Un futur adaptateur peut utiliser le résultat pour construire des segments de maillage ou instancier des nœuds, mais doit préserver ID et valeurs. Si une texture visuellement correcte n'offre aucune correspondance avec les croisements, les réviseurs ne peuvent déterminer si elle suit le programme ou lui ressemble seulement.

Utilisez trois conditions. La **condition sémantique** vérifie l'unicité des ID, les 36 croisements attendus et zéro violation d'adjacence. La **condition géométrique** vérifie l'existence des deux fils à chaque croisement, la traduction de la relation dessus/dessous en coordonnées de maillage ou de scène et la cohérence d'échelle. La **condition perceptive** donne à un observateur une caméra fixe et lui demande d'identifier un croisement et le fil supérieur. Réussir une condition n'implique pas les autres. Un manifeste peut être correct alors que les cylindres s'interpénètrent ou que la caméra masque la relation. À l'inverse, une image convaincante peut cacher une parité redémarrée à une jonction.

### Exercice 3 : classer la preuve

Une future capture Godot semble tissée. Le manifeste comporte 36 ID uniques et zéro violation d'adjacence. Un clic sur `w3-f0` met `w2-f0` en évidence, et aucun relevé de coordonnées de maillage n'a été consigné. Quelles conditions ont des preuves et lesquelles restent ouvertes ?

> **Réponse :** Le manifeste étaye la condition sémantique pour ce motif déclaré. La mauvaise surbrillance fait échouer le rattachement d'identité de scène, et l'absence de relevé laisse la géométrie non évaluée. La capture seule ne certifie ni ordre des croisements ni compréhension. Corrigez la correspondance, consignez les coordonnées dessus/dessous et rejouez l'interaction avant de considérer l'essai de scène réussi.

## 4. Comparer la règle à une solution de scène moins coûteuse

L'objet Godot proposé doit être comparé à un diagramme ou libellé simple, pas seulement à une scène vide. Si le but est uniquement d'expliquer une dépendance de gouvernance, une grille 2D étiquetée peut la transmettre plus sûrement qu'un tissage 3D. Un échantillon 3D ne mérite son coût de maintenance que s'il améliore une tâche d'apprentissage ou d'inspection prédéclarée. Gardez caméra, éclairage, libellés, formulation de tâche et dimensions fixes. Préservez JSON du programme, manifeste dérivé, journal d'import, captures brutes, traces de clics et réponses par apprenant. Mesurez séparément le temps par image ; le nombre de triangles seul ne mesure pas la compréhension.

Un DSL n'est utile que s'il réduit erreurs ou effort de rédaction par rapport à un manifeste simple et un petit validateur. La fixture actuelle démontre un invariant de composition et un contre-exemple, pas qu'il faut adopter un nouveau langage. Les coûts cachés comprennent unités, ID au fil des modifications, correspondance croisements-maillage, validation d'export, accessibilité et explication du lien entre segment visible et relation sémantique. L'obtention d'une correction égale et d'une rédaction plus rapide avec un manifeste JSON ordinaire et un validateur court sur une tâche répétée réfuterait la proposition de DSL.

### Exercice 4 : concevoir la comparaison

A utilise la parité globale, une caméra fixe et un matériau simple. B redémarre la parité à chaque motif, change la caméra et ajoute des couleurs très contrastées. Cinq observateurs préfèrent B. Que conclure et quelle nouvelle exécution à variable unique faire d'abord ?

> **Réponse :** La préférence ne prouve ni que la jonction est correcte ni que la caméra ou couleur modifiée l'a causée. B possède 12 relations adjacentes violées dans la fixture. Comparez d'abord les deux règles de croisement avec les mêmes caméra, matériau, libellés et tâche ; conservez le résultat du validateur et la réponse de chaque observateur. Faites ensuite varier caméra ou matériau indépendamment. Si la condition sémantique est obligatoire, B est rejeté même s'il paraît meilleur.

## 5. Définir une condition de publication capable d'échouer

Avant de placer l'échantillon dans un observatoire, exigez programme source et manifeste dérivé versionnés, import Godot avec correspondance stable ID-objet, trace d'interaction rejouable pour au moins un croisement de chaque côté d'une jonction de motifs et capture brute à point de vue fixe. Définissez une tâche d'apprenant et un plafond de coût avant l'exécution. Un échantillon avec croisement non rattaché ou jonction rompue échoue même si sa capture est séduisante. Une topologie correcte accompagnée d'une compréhension inférieure à une référence 2D devrait conduire à une révision, pas à une annonce d'amélioration pédagogique.

Cette condition est volontairement plus stricte que l'exécution de l'évaluateur Python. Aucun import Godot, capture GPU, mesure de temps par image ou comparaison d'apprenants n'est inclus dans ce cours. La fixture exécutable prouve uniquement que les deux règles spécifiées diffèrent selon un vérificateur déclaré. Elle ne prouve ni le comportement d'un tissu réel ni la qualité du rendu. Gardez cette limite visible dans les comptes rendus concernant ComfyUI, Blender, Godot ou une publication ultérieure.

### Exercice 5 : décider à partir de preuves mixtes

Supposons qu'un adaptateur exporte les 36 ID, qu'un autotest Godot confirme zéro violation de manifeste et qu'une capture soit claire. Un clic de jonction renvoie le mauvais croisement une fois sur dix rejeux. Trois apprenants sur quatre identifient le fil supérieur, contre quatre sur quatre sur un diagramme 2D étiqueté ; le temps par image respecte le budget. Faut-il accepter l'échantillon 3D selon cette leçon ?

> **Réponse :** Non. Le clic erroné fait échouer l'exigence de rattachement d'identité, et le petit essai d'apprenants ne surpasse pas la référence 2D déclarée. Conservez empreintes source et sortie, révision de scène, journal d'import, dix traces brutes de clics, captures, réponses individuelles et échantillons de temps par image. Corrigez le rattachement et testez à nouveau l'explication avec la même tâche. Ces nombres sont des données hypothétiques d'exercice, pas des résultats mesurés du projet.

## Preuves et limites

- La fixture au commit Demerzel `f23ccae6c049d9066a1be2221c68f3b0bcf48373` donne des nombres reproductibles pour une règle de parité synthétique. C'est un vérificateur pédagogique, pas un simulateur textile ni un moteur de rendu Godot.
- Le plan GA figé motive un usage possible dans l'observatoire ; il n'établit pas un import de scène actif pour ce tissage. VC-005 pose une question de nettoyage d'asset ; cette leçon teste la composition avant export.
- Les nombres d'observateurs, l'erreur de clic et le résultat de temps par image des exercices 4 et 5 sont inventés. Aucune révision humaine, tentative d'apprenant, capture de scène, publication ou consultation publique anonyme n'est revendiquée. Le cycle source anglais antérieur ne revendiquait pas non plus de traduction ; ce brouillon français attend une révision par une personne maîtrisant le français.
