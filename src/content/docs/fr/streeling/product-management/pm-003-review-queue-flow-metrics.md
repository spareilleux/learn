---
title: Mesurer la file de révision Streeling sans compter les brouillons comme du débit
description: Mesurer la file de révision Streeling sans compter les brouillons comme du débit — Gestion de produit et de projet
sidebar:
  label: PM-003 · Mesurer la file de révision Streeling sans compter les brouillons comme du débit
  order: 3
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/product-management/fr/pm-003-review-queue-flow-metrics.fr.md
---

:::note[Streeling University]
**PM-003** · Mesurer la file de révision Streeling sans compter les brouillons comme du débit · débutant · 30 minutes

Généré par le département *Gestion de produit et de projet* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/product-management/fr/pm-003-review-queue-flow-metrics.fr.md) · [Mon journal](../../journal/)

Prérequis: [PM-002](../../product-management/pm-002-release-evidence-gate/)
:::

> **Périmètre de la source et du transfert.** Le texte technique ci-dessous provient d’un brouillon archivé. Les mentions historiques d’une absence d’importation ou de compilation dans Learn concernent cette étape antérieure ; ce [dossier de transfert](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/agentic-composition-2026-10-22/README.md) décrit l’importation actuelle et ses vérifications. Les autres expériences indiquées comme non réalisées le restent. Les revues humaines du contenu et de la langue, ainsi que l’essai avec un apprenant, restent à effectuer.

> **Périmètre des sources actuelles.** L'inventaire, la file de révision et les exemples d'importation ci-dessous sont des observations historiques des sources Demerzel et de leur ancien parcours d'importation dans Learn. La rédaction actuelle EN/FR/ES relève de Learn `streeling/courses/`, dont les pages sont générées par `npm run sync:streeling`. PT/IT/DE et les cycles de recherche restent dans Demerzel. Les anciens indicateurs et décomptes de production n'établissent ni la révision, ni le débit, ni la publication des blobs Learn modifiés.

> **Département de gestion de produits et de projets** | Niveau : débutant | Durée estimée : 30 minutes | Statut : brouillon français ; conditions disciplinaires, pédagogiques, linguistiques et de publication ouvertes

## Objectifs

Après cette leçon, vous saurez :

- Nommer l'unité, la limite et la fenêtre temporelle du travail de révision en cours (WIP) et du débit de révisions terminées.
- Utiliser l'inventaire source Streeling comme un instantané daté sans qualifier son nombre de brouillons de taux de flux.
- Calculer le bilan d'une file à partir d'un petit journal d'événements et identifier les mesures que les artefacts actuels ne permettent pas d'obtenir.

## La question du projet

L'équipe veut savoir si la file de révision humaine Streeling grossit plus vite que les réviseurs ne terminent les cours. Un tableau de bord affiche **81 modules source anglais**. Combien de révisions ont été terminées la semaine dernière ? Ce nombre ne permet **pas de le savoir**. Un décompte source est un stock de fichiers à une révision donnée. Le débit de révision compte les modules qui ont franchi une limite d'achèvement convenue pendant un intervalle déterminé. [PM-002](../../product-management/pm-002-release-evidence-gate/) explique les conditions distinctes de publication ; cette leçon mesure les mouvements entre elles.

Utilisez le [script de progression Demerzel](https://github.com/GuitarAlchemist/Demerzel/blob/0220ca84a25f59973bd6b9236cc00b7f68631a50/scripts/streeling_course_progress.py) et l'[inventaire daté du cursus](https://github.com/GuitarAlchemist/Demerzel/blob/0220ca84a25f59973bd6b9236cc00b7f68631a50/docs/specs/streeling-project-curriculum-2026-10-04.md) comme cas du projet. Dans un instantané propre de l'arbre source au commit Demerzel `0220ca84a25f59973bd6b9236cc00b7f68631a50` le 11 octobre 2026, `python scripts/streeling_course_progress.py` rapportait **81** modules EN rédigés dans **21** répertoires de cours, **16** modules avec tous les fichiers des langues actives et **0** module doté d'une révision approuvée dans un enregistrement de production. Le script trouvait aussi **23** enregistrements de définition de départements. Ces nombres sont liés à cette révision et à ce périmètre fondé sur les répertoires ; une nouvelle exécution sur une copie ultérieure peut les changer.

Le cursus indique **78** modules source EN dans 21 répertoires à un état pilote antérieur du 11 octobre. La différence, `81 - 78 = 3`, est une **variation nette de l'inventaire source entre ces observations**. Elle ne correspond pas à trois révisions terminées. Même un dénominateur inchangé ne révélerait pas si des fichiers ont été ajoutés, supprimés, renommés ou révisés entre les instantanés.

### Exercice pratique 1 : nommer les unités

Une carte d'état indique « 78 → 81 modules le 11 octobre, donc le débit était de 3 cours ». Corrigez la carte en utilisant l'unité exacte et la limite manquante.

> **Réponse :** « L'inventaire source anglais a augmenté de trois fichiers de modules nets entre les deux observations datées. » On ne peut pas parler de débit de révision : aucun des deux nombres ne compte un événement d'approbation dans une fenêtre définie. Le premier nombre, 78, est une observation datée du cursus ; 81 est l'instantané figé du script à `0220ca8`.

## 1. Définir la file avant de la compter

Pour cet exercice, comptez **un ID de module une seule fois**, même si son cours possède six traductions ou plusieurs tâches de révision. L'entrée a lieu lorsqu'un coordinateur enregistre le module comme prêt pour révision et attribue le travail correspondant. La sortie a lieu lorsque les remarques disciplinaires, linguistiques et pédagogiques requises sont résolues et qu'une révision de production approuvée est consignée, ou lorsque le coordinateur le retire explicitement. Un brouillon retourné reste dans le WIP jusqu'à l'une de ces sorties ; autrement, une boucle de corrections pourrait donner l'impression de réduire la file sans réduire le travail inachevé. Consignez l'ID du module, l'heure d'entrée, l'heure de sortie, son motif et la révision source dans un journal d'événements.

Le [script de progression actuel](https://github.com/GuitarAlchemist/Demerzel/blob/0220ca84a25f59973bd6b9236cc00b7f68631a50/scripts/streeling_course_progress.py) examine les fichiers source et les JSON de production. Son décompte `authored_en` inclut les modules Markdown anglais. Son signal `pipeline_review_approved` exige `review.completed: true` **et** `verdict: approved` dans un enregistrement de production correspondant. Il ne reconstitue pas les dates d'entrée ou de sortie d'une révision dans une file. À l'instantané figé `0220ca8`, les 12 enregistrements de production contiennent un statut `review_pending`, pour [DV-001](https://github.com/GuitarAlchemist/Demerzel/blob/0220ca84a25f59973bd6b9236cc00b7f68631a50/state/streeling/course-productions/cp-data-visualization-2026-10-04-001.json), et onze statuts `in_progress`. Ce seul enregistrement `review_pending` est un **indicateur indirect de statut**, pas un recensement mesuré de la file : il n'y a ni événement d'entrée obligatoire, ni horodatage d'attribution, ni garantie que tous les brouillons prêts pour révision possèdent déjà un enregistrement.

Le [dossier de révision DV-001](https://github.com/GuitarAlchemist/Demerzel/blob/0220ca84a25f59973bd6b9236cc00b7f68631a50/state/streeling/reviews/dv-001-review-brief.md) illustre cette distinction. Il indique que les conditions de révision humaine disciplinaire, linguistique et par un apprenant restent ouvertes. Ses vérifications délimitées par IA et ses six brouillons linguistiques rendent visible le travail de révision sans le terminer. Un module dont le travail reste ouvert peut constituer un contenu source utile tout en contribuant zéro révision approuvée terminée.

### Exercice pratique 2 : lire honnêtement l'instantané

À `0220ca8`, le script indique 81 modules EN rédigés, 16 complets dans les langues actives et 0 révision de production approuvée ; le relevé des statuts trouve un module `review_pending`. Lequel constitue un WIP vérifié et lequel un débit hebdomadaire ?

> **Réponse :** Aucun ne constitue un recensement vérifié du WIP de la file de révision ni un débit hebdomadaire. Le module `review_pending` est un indicateur indirect de statut d'enregistrement à une révision donnée. Les nombres 81 et 16 comptent des états de fichiers source, et 0 compte les modules approuvés à cet instantané. Sans heures d'événements et règle cohérente d'entrée dans la file, aucun taux hebdomadaire d'arrivée ou d'achèvement n'en découle.

## 2. Compter les mouvements dans une fenêtre explicite

Le journal suivant est un **jeu de données pédagogique synthétique**, pas un historique Streeling observé. Sa fenêtre est `[2026-10-05 00:00 UTC, 2026-10-12 00:00 UTC)` : début inclus, fin exclue, exactement sept jours. Au début, les modules A et B sont dans le WIP de révision. Un module reste dans le WIP pendant les corrections demandées. Le journal utilise cinq ID de modules distincts ; un module peut figurer dans plusieurs événements.

| Heure (UTC) | Module | Événement | Effet sur le WIP de révision |
|---|---|---|---:|
| 6 oct., 09:00 | C | Prêt pour révision ; entre dans la file | +1 |
| 7 oct., 16:00 | A | Révisions requises approuvées ; sort | -1 |
| 8 oct., 11:00 | D | Brouillon anglais rédigé ; aucune entrée en révision | 0 |
| 9 oct., 14:00 | B | Retourné pour correction ; reste attribué | 0 |
| 10 oct., 12:00 | E | Prêt pour révision ; entre dans la file | +1 |
| 11 oct., 18:00 | C | Retiré explicitement ; sort | -1 |

Le WIP initial est de 2. Deux entrées, une sortie approuvée et un retrait donnent un WIP final de `2 + 2 - 1 - 1 = 2` : B et E. **Le débit de révisions terminées est d'un module par fenêtre de sept jours**, A. Le retrait de C est une sortie pour le bilan de file, mais pas une révision terminée. Le nouveau brouillon D est un événement de rédaction, pas une arrivée en révision. Ne mélangez pas les nombres de ce jeu de données avec l'instantané réel de 81 modules.

### Exercice pratique 3 : rapprocher les comptes de la file

À partir du seul journal synthétique, calculez le WIP de révision final et listez ses ID. Déplacer B vers « à réviser » en dehors du tableau de révision changerait-il le travail inachevé ?

> **Réponse :** Le WIP final vaut `2 opening + 2 entries - 1 approval - 1 withdrawal = 2`, soit B et E. Changer l'étiquette de B ne le terminerait pas. Selon la règle de file de cette leçon, il reste dans le WIP pendant les corrections demandées ; toute autre règle de tableau doit être déclarée avant de comparer les nombres.

### Exercice pratique 4 : calculer le flux terminé

Pour la fenêtre de sept jours du jeu de données, rapportez séparément les révisions approuvées terminées, les retraits et les brouillons rédigés. Que se passe-t-il si un tableau de bord traite chaque sortie comme une « révision livrée » ?

> **Réponse :** On relève une révision approuvée terminée (A), un retrait (C) et un brouillon rédigé sans entrée en révision (D). Appeler les deux sorties « révisions livrées » en compterait deux et surestimerait d'une unité le débit de révisions approuvées. Le journal ne consigne aucune publication publique dans Learn.

## 3. Montrer les heures manquantes et les changements de périmètre

Le délai de traversée exige les horodatages d'entrée en file et de sortie approuvée d'un module. L'entrée de A précède la fenêtre du jeu de données, mais son heure exacte n'est pas précisée ; son délai de révision ne peut donc pas être calculé. À l'instant de clôture, E est dans cette file définie depuis **36 heures**, du 10 octobre à 12:00 UTC au 12 octobre à 00:00 UTC. L'âge de B est inconnu, car son heure d'entrée n'est pas fournie. Ne calculez pas une moyenne à partir d'un âge connu et d'un âge inconnu et n'attribuez pas silencieusement à B le début de la fenêtre.

Pour le vrai travail Streeling, sauvegardez un journal d'événements immuable avant de représenter les taux d'arrivée, le débit de révisions terminées, l'âge ou le délai de traversée. Figez une révision source, conservez la même unité d'ID de module et les mêmes règles d'entrée/sortie pendant toute comparaison, puis indiquez l'intervalle UTC. Distinguez les étapes disciplinaire, linguistique, apprenant, build Learn et consultation publique si leurs files ont des responsables différents. Un `timestamp` dans un enregistrement JSON de production indique la dernière écriture de cet enregistrement ; il n'identifie pas à lui seul l'heure d'une transition. L'[état public de référence daté](https://github.com/GuitarAlchemist/Demerzel/blob/0220ca84a25f59973bd6b9236cc00b7f68631a50/state/streeling/reviews/public-baseline-2026-10-11.md) concerne l'accès anonyme à Learn, pas le flux de révision.

### Exercice pratique 5 : rédiger une légende de tableau de bord utilisable

Rédigez deux phrases utilisant l'instantané de projet figé `0220ca8` et le jeu de données synthétique sans présenter ce dernier comme un résultat observé de l'équipe. Incluez une prochaine action de mesure.

> **Réponse :** « À Demerzel `0220ca8`, l'analyse des sources a trouvé 81 modules anglais et zéro module doté d'une révision de production approuvée ; un enregistrement portait le statut `review_pending`, mais ce n'est pas un recensement horodaté de la file. Dans un journal synthétique distinct de sept jours, le WIP de révision se clôt à deux et le débit de révisions approuvées vaut un ; pour mesurer le vrai flux Streeling, consignez par module les événements d'entrée en révision, de sortie approuvée et de retrait avec des horodatages UTC et des règles stables. »

## Points à retenir

- L'inventaire source et la couverture linguistique sont des stocks. Un taux de révisions terminées exige des événements de transition datés et une fenêtre déclarée.
- Le bilan de file compte les arrivées et toutes les sorties ; le débit de révisions terminées compte uniquement les sorties approuvées selon la règle de cette leçon.
- Un champ de statut et l'horodatage de dernière écriture sont des signaux de triage utiles, mais ne permettent pas de reconstituer le WIP historique, le délai de traversée ou le débit.

## Preuves du projet et limites

- Commit Demerzel `0220ca84a25f59973bd6b9236cc00b7f68631a50` : [script de progression](https://github.com/GuitarAlchemist/Demerzel/blob/0220ca84a25f59973bd6b9236cc00b7f68631a50/scripts/streeling_course_progress.py), [inventaire daté du cursus](https://github.com/GuitarAlchemist/Demerzel/blob/0220ca84a25f59973bd6b9236cc00b7f68631a50/docs/specs/streeling-project-curriculum-2026-10-04.md), [enregistrement de production DV-001](https://github.com/GuitarAlchemist/Demerzel/blob/0220ca84a25f59973bd6b9236cc00b7f68631a50/state/streeling/course-productions/cp-data-visualization-2026-10-04-001.json) et [dossier de révision ouvert](https://github.com/GuitarAlchemist/Demerzel/blob/0220ca84a25f59973bd6b9236cc00b7f68631a50/state/streeling/reviews/dv-001-review-brief.md). La sortie du script sur arbre propre et l'analyse des enregistrements de production décrites ci-dessus ont été observées pour ce commit ; un arbre de travail ultérieur peut différer.
- Le journal de six événements A–E est inventé pour s'exercer au calcul. Il ne fournit aucune preuve sur les réviseurs Streeling réels, leur temps de cycle ou la publication.
- PM-003 est ici un brouillon français. Lors du cycle source anglais antérieur, la révision humaine disciplinaire, un essai d'apprenant, les révisions linguistiques par des personnes maîtrisant les langues, la synchronisation/build Learn et la consultation publique anonyme n'avaient pas été réalisés. Ce brouillon attend encore l'approbation d'une personne maîtrisant le français ; sa traduction n'établit aucun de ces résultats.
