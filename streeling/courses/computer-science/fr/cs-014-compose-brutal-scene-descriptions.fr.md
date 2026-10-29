---
module_id: cs-014-compose-brutal-scene-descriptions
department: computer-science
course: "Composer des descriptions de scènes BRUTAL avec des blocs F# typés"
level: intermediate
prerequisites: ["cs-010-compose-fail-fast-ga-computations"]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Composer des descriptions de scènes BRUTAL avec des blocs F# typés

> **Périmètre du brouillon.** Nouvelle compilation et exécution sur CPU du code public de description de scènes, complétées par des calculs fondés sur le code source. La revue technique humaine, la relecture linguistique par une personne maîtrisant la langue, les essais par des apprenants et la vérification du HTML public du cours restent à faire. Aucune fenêtre graphique, aucun moteur de rendu, GPU, dispositif audio ou flux n'a été lancé.

## La question du projet

Un agent de l'Observatory devrait pouvoir demander une colonnade, examiner sa structure, changer la version d'un bloc et recevoir un refus précis avant tout dessin. L'[évaluation BRUTAL](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/README.md) contient une bibliothèque Lego en F# qui sépare les descriptions de leur application de rendu. Son code source public, fixé au commit GA `76efbffd5af82b46c3146957a6bd4504008eeb89`, fournit le cas d'implémentation de cette leçon.

Le [modèle typé](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Model.fs#L87-L122) représente les variantes à l'aide d'[unions discriminées F#](https://learn.microsoft.com/dotnet/fsharp/language-reference/discriminated-unions) : `Box`, `Use`, `Attach`, `Move`, `Group` et décoration de surface. La fonction `Build` d'un bloc reçoit des arguments et un contexte, puis décrit des pièces et des points d'ancrage. Un moteur de rendu peut ensuite consommer la scène obtenue de manière indépendante.

Cette séparation facilite la composition et l'inspection. Elle ne garantit pas que toutes les fonctions de blocs possibles soient mathématiquement pures ou totales : le contexte fournit un générateur aléatoire initialisé par une graine, et le code de génération intercepte les échecs des blocs. Le déterminisme mesuré ci-dessous concerne de nouveaux appels complets de génération avec des entrées fixes, sans couvrir la réutilisation arbitraire d'un contexte aléatoire mutable ni l'exécution parallèle.

## 1. Examiner la structure avant la matérialisation

Le [compte rendu d'exécution sur CPU](../../../../code/streeling/evidence/brutal-composition-2026-10-22/cpu-execution.json) consigne une nouvelle compilation Release avec le SDK 10.0.113, sans avertissement ni erreur, et 20 tests existants réussis. Deux projets F# publics inchangés ont été compilés dans un environnement autonome temporaire, avec les propriétés et cibles de compilation héritées de GA désactivées. Les empreintes du code source et des fichiers de verrouillage sont restées identiques. Ce périmètre diffère de l'exécution d'une application graphique complète.

Les [sélections de descriptions enregistrées](../../../../code/streeling/evidence/brutal-composition-2026-10-22/cpu-descriptions.json) comprennent une colonnade dont le nombre de colonnes vaut 4, l'espacement 3 et la graine 7. Elle contient cinq instances de blocs : la racine et quatre colonnes nommées. Leurs origines sont `(0,0,0)`, `(3,0,0)`, `(6,0,0)` et `(9,0,0)` mètres. Ses 53 boîtes comprennent la géométrie contenue dans ces instances et l'entablement de la racine. Une instance de bloc et une boîte ne sont pas la même unité.

### Exercice 1 : lire l'arbre de composition

Pour un nombre de colonnes de 4 et un espacement de 3, indiquez les origines des colonnes et le nombre d'instances de blocs, racine comprise. Pourquoi serait-il erroné d'assimiler cinq instances à cinq boîtes ?

> **Réponse:** Les origines sont `(0,0,0)`, `(3,0,0)`, `(6,0,0)` et `(9,0,0)` mètres. Les quatre colonnes et la racine donnent cinq instances. Chaque colonne se développe en plusieurs boîtes, et la racine ajoute la géométrie de l'entablement, soit 53 boîtes dans la version enregistrée. Les deux nombres décrivent des niveaux différents de la représentation.

## 2. Fixer la version imbriquée, au-delà du nom de la racine

Les [définitions des blocs](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Blocks.fs#L36-L119) contiennent `column@1` et `column@2`. Avec quatre tambours, elles produisent respectivement 11 et 19 boîtes. La résolution du nom sans version `column` sélectionne la version installée la plus élevée, mais le paramètre `column` de la colonnade vaut explicitement 1 par défaut. Une requête externe sans version ne met donc pas automatiquement à niveau tous les blocs imbriqués.

La colonnade à quatre colonnes apporte neuf boîtes d'entablement : deux éléments horizontaux et sept triglyphes. La version 1 donne donc `4*11+9 = 53` ; sélectionner la version 2 des colonnes imbriquées donne `4*19+9 = 85`. Pour conserver un résultat, fixez la bibliothèque, les choix de versions, les arguments et la graine. Sinon, le même nom convivial peut masquer une description modifiée.

### Exercice 2 : résoudre la version souhaitée

Si `column` est résolu vers la version 2, une colonnade par défaut doit-elle utiliser cette version ? Calculez le nombre total de boîtes lorsque son paramètre de colonne imbriquée vaut 1 puis 2, ainsi que leur différence.

> **Réponse:** Non. La colonnade fixe explicitement à 1 la valeur par défaut de son paramètre de colonne imbriquée. La version 1 donne `4*11+9 = 53` ; la version 2 donne `4*19+9 = 85`, soit 32 boîtes supplémentaires. Consignez le paramètre imbriqué au lieu de le déduire de la résolution d'un nom sans version effectuée ailleurs.

## 3. Attacher à un point d'ancrage plutôt que répéter sa hauteur

La colonnade attache son entablement au point d'ancrage `top` de la première colonne nommée. La colonne calcule cet ancrage à partir de sa hauteur. Dans le cas enregistré, avec une hauteur de 9, un nombre de colonnes de 3 et un espacement de 2, la première boîte de l'entablement est translatée vers `(2,9,0)`. Son centre horizontal dépend de l'étendue de la rangée ; sa position verticale dépend du point d'ancrage.

Il s'agit d'une interface de composition utile : le parent demande un point d'attache au lieu de recopier les détails de construction de l'enfant. Une instance ou un point d'ancrage manquant reste un échec significatif. Utiliser silencieusement l'origine à la place produirait une scène plausible mais incorrecte et ferait disparaître l'exigence manquante du résultat de l'agent.

### Exercice 3 : propager une dimension modifiée

Pour un nombre de colonnes de 3, un espacement de 2 et une hauteur de 9, déduisez le milieu horizontal de la rangée et la translation de la première boîte de l'entablement. Quelle information doit rester visible si le point d'ancrage requis est absent ?

> **Réponse:** La rangée s'étend de X 0 à X 4 ; son milieu est donc X 2. Le point d'ancrage supérieur fournit Y 9 ; la translation de la boîte enregistrée est `(2,9,0)`. Conservez un refus qui nomme l'instance ou le point d'ancrage manquant. Un placement par défaut à l'origine masquerait l'échec de la composition.

## 4. Expliciter l'ordre des transformations

La [convention spatiale](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Space.fs) utilise les mètres, l'axe Y positif vers le haut et un lacet positif qui fait tourner X positif vers Z négatif. Ses [matrices System.Numerics](https://learn.microsoft.com/dotnet/api/system.numerics.matrix4x4) multiplient des vecteurs lignes : la matrice monde d'un enfant est sa matrice locale multipliée par celle de son parent. Une transformation applique une mise à l'échelle, une rotation, puis une translation.

Pour le vecteur unitaire X, une échelle de 2 donne `(2,0,0)` ; un lacet de 90 degrés donne `(0,0,-2)` ; la translation `(1,2,3)` donne `(1,2,1)`. Une translation suivie de la mise à l'échelle et de la rotation donnerait au contraire `(6,4,-4)`. Les tests de transformation existants ont réussi avec leur tolérance déclarée `1e-3` ; le [relevé des calculs](../../../../code/streeling/evidence/brutal-composition-2026-10-22/composition-calculations.json) distingue le calcul à angle droit du contrôle effectué dans le mauvais ordre.

### Exercice 4 : repérer une composition réordonnée

Transformez le vecteur unitaire X par une échelle de 2, un lacet de 90 degrés et la translation `(1,2,3)`, dans l'ordre déclaré. Comparez avec une translation appliquée en premier. Un consommateur de scène peut-il changer de convention matricielle sans convertir les données ?

> **Réponse:** L'ordre déclaré donne `(1,2,1)` ; une translation suivie de la mise à l'échelle et de la rotation donne `(6,4,-4)`. Les opérations ne commutent pas. Un consommateur utilisant une autre convention matricielle doit effectuer une conversion explicite et vérifier un point connu ; recopier les valeurs en les interprétant autrement ne suffit pas.

## 5. Préserver le refus et le déterminisme comme deux propriétés distinctes

La répétition de la requête de colonnade fixe a produit des octets de sortie et une empreinte de scène identiques. Passer la graine d'un temple de 7 à 8 a conservé ses 405 boîtes et le même nombre d'instances tout en changeant son empreinte. Des nombres identiques ne prouvent donc pas que les scènes ont le même contenu. L'empreinte décrit l'arbre de scène sérialisé ; elle ne constitue ni une empreinte d'image rendue ni un résultat de performance.

La [CLI](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego.Cli/Program.fs) émet `lego-scene/1` et le code de sortie 0 pour une scène acceptée. Une requête avec `count=2.5` émet `lego-errors/1` et le code de sortie 2, car le nombre doit être entier. Recevoir du JSON ne suffit pas pour déclarer une réussite. [VC-009](../../visual-computing/en/vc-009-budget-brutal-scene-expansion.md) étend cette frontière aux limites de croissance.

### Exercice 5 : interpréter le résultat de l'agent

Un agent reçoit du JSON et le code de sortie 2 après avoir demandé `count=2.5` ; il arrondit silencieusement le nombre et annonce une scène valide déterministe. Quel résultat a réellement été observé, et que doit conserver une requête corrigée ?

> **Réponse:** Le résultat observé est une requête refusée avec `lego-errors/1`, et non une scène acceptée. Conservez son code de sortie et sa raison. Une requête corrigée doit choisir explicitement un nombre entier et conserver l'identité du code source et de la bibliothèque, les versions, les arguments, la graine et les limites. La répétition peut tester le déterminisme de cette nouvelle requête ; elle ne peut ni transformer rétroactivement le refus en réussite ni établir les performances du rendu.

## Limites des preuves

Seul le [code source public vérifié anonymement](../../../../code/streeling/evidence/brutal-composition-2026-10-22/primary-readback.json) entre dans ce dossier pédagogique. Les vérifications sur CPU exercent la génération, la validation et la description. Elles n'établissent ni l'existence d'un adaptateur IX opérationnel, ni une scène Observatory rendue, ni la libération des ressources GPU, ni le comportement de DLSS, ni l'apprentissage humain, ni la publication déployée.
