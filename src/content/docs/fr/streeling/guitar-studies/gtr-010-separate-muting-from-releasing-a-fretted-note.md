---
title: Distinguer l’étouffement du relâchement d’une note frettée
description: Distinguer l’étouffement du relâchement d’une note frettée — Études de guitare
sidebar:
  label: GTR-010 · Distinguer l’étouffement du relâchement d’une note frettée
  order: 10
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-studies/fr/gtr-010-separate-muting-from-releasing-a-fretted-note.fr.md
---

:::note[Streeling University]
**GTR-010** · Distinguer l’étouffement du relâchement d’une note frettée · intermédiaire · 45 minutes

Généré par le département *Études de guitare* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-studies/fr/gtr-010-separate-muting-from-releasing-a-fretted-note.fr.md) · [Mon journal](../../journal/)

Prérequis: [GTR-005](../../guitar-studies/gtr-005-plan-which-string-keeps-ringing/)
:::

> **Brouillon et limites des preuves.** Ce cours présente un modèle construit et des lectures de sources. Les décisions techniques humaines, musicales, linguistiques et pédagogiques restent en attente. Aucun nouveau rendu, lancement d’analyseur, jeu, écoute ou essai d’élève n’est revendiqué. Les échecs historiques gardent leur statut.

## La question du projet

Une consigne demande de relâcher une note frettée et suppose que le silence suit. La fin symbolique d'une note et l'arrêt de vibration d'une corde sont des événements distincts. Nous construisons une table qualitative pour une corde, avec transitions stipulées et sans prédiction d'amplitude. Le résultat utile est une exigence d'étouffement explicite à revoir.

## Lire les preuves du projet

Lisez le prérequis et l’artefact conservé avant d’appliquer le modèle. Repérez la représentation, la transformation ou l’exclusion pertinente. Le paquet fixe conserve identité des sources, périmètre de lecture et valeurs construites ; une source renseigne son contenu à cette révision, sans prouver le déploiement actuel. Distinguez observation tirée du texte et proposition déduite. Pour une référence primaire, respectez son périmètre annoncé sans l’étendre aux cas non pris en charge.

[Prérequis: gtr-005-plan-which-string-keeps-ringing](../../guitar-studies/gtr-005-plan-which-string-keeps-ringing/)

[Artefact du projet conservé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/phrase-performance-2026-10-22/string-occupancy.json)

[Paquet de données construites](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-a.json)

[Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)

## 1. Exercice 1

Stipulons une corde à vide 64 et la case 3, donnant la note 67. Relâcher à la pulsation 1 supprime la contrainte frettée, sans prescrire l'amplitude restante. La hauteur possible à vide est pertinente pour la revue, mais ne constitue pas un son enregistré.

Quelle hauteur aurait la corde à vide, et que reste-t-il inconnu ?

> **Réponse.** La hauteur à vide est 64 ; amplitude résiduelle et sortie audible restent inconnues.

## 2. Exercice 2

Ajoutons un événement d'étouffement à 1.25. Dans le modèle, lui seul fait passer à l'état étouffé. Entre relâchement et étouffement, un intervalle demande observation. La table n'affirme ni qu'un relâchement produit toujours la corde à vide, ni qu'une technique réussit systématiquement.

Quelle durée de silence reste non vérifiée ?

> **Réponse.** `1.25-1=.25` pulsation ; conservez-la comme non vérifiée plutôt que d'inventer un enregistrement.

## 3. Exercice 3

Une fin de note peut libérer une ressource dans la table d'occupation alors que le silence acoustique exige encore un geste d'étouffement. Gardez disponibilité et état sonore comme sorties distinctes. Sinon, une affectation paraît sans conflit malgré des résonances indésirables jamais examinées.

Une corde disponible est-elle nécessairement silencieuse ?

> **Réponse.** Non. La disponibilité découle du planning ; le silence exige un modèle propre ou une observation mesurée.

## 4. Exercice 4

Supprimons l'étouffement comme témoin négatif. Le relâchement restant ne suffit pas à atteindre l'état étouffé du modèle. Cela réfute un adaptateur qui transformerait chaque fin de note en silence garanti. Cela ne choisit pas le geste d'un interprète et n'établit aucune recommandation de confort.

Quel statut doit annoncer un adaptateur limité au relâchement ?

> **Réponse.** Il doit conserver l'état acoustique indéterminé et l'absence de consigne d'étouffement, sans déclarer le silence vérifié.

## 5. Exercice 5

Repérez les exclusions explicites du paquet de phrase. Une future tâche devra nommer cordes à laisser sonner, relâchements, étouffements, tempo, sons indésirables observés et assistance. La référence manuelle est la table d'états, sans nouveau simulateur. Un agent peut vérifier sa complétude sans prétendre avoir entendu le résultat.

Quelle preuve résout la question acoustique ?

> **Réponse.** Il faut une observation réelle de jeu ou d'audio selon la tâche visée ; aucun résultat de ce type n'est conservé ici.

## Tâche avec consultation des sources

Préparez une courte note de revue à partir du cas fixe avant d’ouvrir les corrigés. Refaites d’abord manuellement le calcul ou la table, en gardant unités, support et hypothèses. Ce résultat direct sert de référence à toute réponse aidée par des sources ou un agent. Examinez ensuite l’artefact lié et identifiez une limite précise du calcul. Consignez l’extrait ou le champ effectivement utilisé, sa révision, votre réponse et toutes les aides reçues. Calculatrice et consultation sont autorisées ; indiquez-les au lieu de présenter le résultat comme un rappel sans aide.

Appliquez le témoin négatif autant que le cas principal. Écrivez le résultat observable qui réfuterait votre conclusion, puis précisez si le témoin le fournit réellement. Si une entrée manque, conservez un résultat indéterminé plutôt que de choisir une valeur plausible. Comparez toute abstraction proposée à la référence manuelle avant de recommander un nouveau workflow d’agent ou un DSL. Le corrigé prépare une vérification ; il ne constitue pas votre tentative. Gardez votre réponse avant révélation, la correction éventuelle et sa raison.

Le paquet contient cinq critères d’élève préparés correspondant aux exercices. Leurs décisions restent nulles jusqu’à conservation des réponses réelles, des aides et de la revue. L’arithmétique juste ne soutient que le modèle déclaré. Une décision de projet utile exige encore le jugement humain ou l’observation d’exécution propre à sa frontière. Consignez contrôles réels, erreurs et affinements dans le journal lié ; distinguez les tests exécutés des tests prévus.
