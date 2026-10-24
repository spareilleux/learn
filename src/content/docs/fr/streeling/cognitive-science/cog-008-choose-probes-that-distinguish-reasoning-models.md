---
title: Choisir des questions qui distinguent les modèles de raisonnement
description: Choisir des questions qui distinguent les modèles de raisonnement — Sciences cognitives
sidebar:
  label: COG-008 · Choisir des questions qui distinguent les modèles de raisonnement
  order: 8
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/cognitive-science/fr/cog-008-choose-probes-that-distinguish-reasoning-models.fr.md
---

:::note[Streeling University]
**COG-008** · Choisir des questions qui distinguent les modèles de raisonnement · intermédiaire · 45 minutes

Généré par le département *Sciences cognitives* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/cognitive-science/fr/cog-008-choose-probes-that-distinguish-reasoning-models.fr.md) · [Mon journal](../../journal/)

Prérequis: [COG-007](../../cognitive-science/cog-007-separate-unaided-recall-from-assisted-success/), [PHY-012](../../physics/phy-012-rotate-directional-stiffness-with-the-material/)
:::

> **Périmètre du brouillon.** Lois candidates, signatures de prédiction et un profil de réponses fictif conçus pour le cours. Aucun participant, instrument de diagnostic validé, intervention pédagogique ou expérience sur un matériau n’a été observé. Les revues humaines techniques, artisanales, linguistiques par des personnes maîtrisant la langue et pédagogiques avec des apprenants restent à effectuer ; la vérification du HTML du cours déployé est distincte.

## La question du projet

Si un apprenant prédit correctement une force, pouvons-nous savoir comment il a raisonné sur le repère du matériau ? [PHY-012](../../physics/phy-012-rotate-directional-stiffness-with-the-material/) fournit un modèle abordable pour concevoir des questions dont les prédictions se distinguent. [COG-007](../../cognitive-science/cog-007-separate-unaided-recall-from-assisted-success/) conserve séparément l’assistance reçue et l’historique des tentatives. Ici, il s’agit de choisir des questions informatives avant d’attribuer un score total ou de proposer un tutorat adaptatif.

Le [résumé de Scott et Schumayer publié par l’éditeur](https://journals.aps.org/prper/abstract/10.1103/PhysRevPhysEducRes.14.010106) traite de l’information contenue dans les réponses incorrectes à une évaluation des concepts de force. Le [résumé d’auteur de Persson](https://arxiv.org/abs/1504.06099v1) souligne la nécessité de vérifier la fidélité et le pouvoir discriminant d’une évaluation dans un nouveau contexte. Seuls ces résumés ont été lus. Ils invitent à la prudence et à conserver des relevés de réponses plus riches ; ils ne valident pas notre nouvelle tâche matricielle, n’établissent pas la fréquence de ses distracteurs et ne fournissent aucun effet d’apprentissage.

## 1. Définir un catalogue fini de candidats

Utilisez la rigidité locale de ressort `diag(4,1)` N/mm conçue pour le cours. Considérez quatre lois de prédiction idéales, pas quatre populations d’apprenants mesurées :

| Loi | Calcul énoncé |
| --- | --- |
| T | Faire tourner la rigidité complète avec le matériau. |
| F | Maintenir la rigidité d’origine fixe dans les axes globaux. |
| D | Faire tourner la rigidité, puis supprimer ses termes hors diagonale. |
| I | Utiliser la rigidité isotrope `2.5*I` à tous les angles. |

Une question de sondage précise l’angle du matériau et le déplacement dans le repère global. Observez le vecteur de force prédit en N et l’énergie en N*mm. La question P0 utilise un angle de 0 degrés et un déplacement de `[1,0]` mm. Les lois T, F et D prédisent toutes `[4,0]` N ; I prédit `[2.5,0]` N. Une réponse correcte ici ne peut pas départager les trois premières lois.

### Exercice 1 : repérer une réussite non informative

Déduisez les prédictions de P0. Une réponse fictive correspond à `[4,0]` N. Quelles entrées du catalogue restent compatibles, et cette réponse prouve-t-elle une bonne compréhension de la rotation ?

> **Réponse:** À l’angle 0, les matrices complète, fixe et limitée à la diagonale coïncident ; T, F et D prédisent donc `[4,0]` N ; I prédit `[2.5,0]` N. La réponse fictive est compatible avec T, F et D. Elle ne permet pas de distinguer leurs règles de rotation et ne constitue pas une observation d’un apprenant réel.

## 2. Combiner des questions complémentaires

La question P1 utilise une rotation du matériau de 90 degrés et un déplacement de `[1,0]` mm. La question P2 utilise une rotation de 45 degrés et le même déplacement dans le repère global. Leurs prédictions exactes de force sont :

| Loi | Force P1, N | Force P2, N |
| --- | --- | --- |
| T | `[1,0]` | `[2.5,1.5]` |
| F | `[4,0]` | `[4,0]` |
| D | `[1,0]` | `[2.5,0]` |
| I | `[2.5,0]` | `[2.5,0]` |

P1 seule regroupe T avec D ; P2 seule regroupe D avec I. Ensemble, leurs signatures sont uniques parmi ces quatre lois stipulées. Il s’agit de l’identifiabilité dans un catalogue fini sous des prédictions exactes, pas d’une identification psychologique de la manière dont une personne réelle pense.

### Exercice 2 : interpréter une signature fictive

Un profil de réponses conçu pour le cours donne la force P1 `[1,0]` et la force P2 `[2.5,0]` N. Quelle loi du catalogue correspond aux deux ? Pourquoi utiliser seulement P2 ne suffit-il pas ?

> **Réponse:** Seule D correspond aux deux dans ce catalogue. P2 seule est compatible avec D et I. La signature à deux vecteurs sépare les lois déterministes répertoriées, mais une erreur arithmétique, une réponse au hasard ou une autre règle absente du catalogue pourrait produire les mêmes réponses. Aucun apprenant réel n’a fait l’objet d’un diagnostic.

## 3. Conserver l’observation qui porte la distinction

À P2, les énergies de T, D et I valent toutes 1.25 N*mm ; F donne 2 N*mm. L’énergie seule perd la distinction de force transversale entre T et D pour ce déplacement particulier. Ne conserver que « correct » ou « incorrect » peut faire perdre encore davantage d’informations sur le calcul.

Cela ne signifie pas que des observations scalaires ne peuvent jamais distinguer les entrées du catalogue. Une autre question P3, à 45 degrés avec un déplacement de `[1,-1]` mm, donne une énergie de 1 pour T et de 2.5 pour F, D et I. Combinée aux énergies de P1, P3 peut distinguer les quatre entrées du catalogue. L’utilité d’une projection dépend des sondages choisis et de la question posée.

### Exercice 3 : comparer les éléments vectoriels et énergétiques

Déduisez l’énergie de P2 pour T et D, en expliquant pourquoi la force transversale n’y contribue pas. Montrez ensuite comment les énergies de P1 et P3 distinguent T de D.

> **Réponse:** Pour le déplacement `[1,0]`, l’énergie est la moitié de son produit scalaire avec la force ; `[2.5,1.5]` et `[2.5,0]` donnent donc toutes deux 1.25 N*mm. Le second déplacement nul élimine la contribution transversale. P1 donne une énergie de 0.5 pour T comme pour D, mais P3 donne 1 pour T et 2.5 pour D. La paire scalaire choisie les sépare ; l’énergie de P2 seule ne le fait pas.

## 4. Mettre le catalogue lui-même à l’épreuve

Définissons une autre loi M pour le cours : utiliser T sauf à l’angle de 60 degrés, où elle utilise à la place une rigidité isotrope. M concorde avec T sur P0, P1, P2 et P3. Ces sondages en nombre fini ne prouvent donc pas qu’une règle de réponse est égale à T à tous les angles.

Le [relevé fixé des signatures](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/constraint-feedback-2026-10-22/probe-signatures.json) conserve les partitions du catalogue et ce contre-exemple réservé à la vérification. Il ne contient aucune étiquette de participant, prévalence, coefficient de fidélité ou estimation de précision diagnostique. Les lois idéales supposent aussi une arithmétique exacte et cohérente ; le raisonnement réel peut dépendre du contexte ou être incomplet.

### Exercice 4 : énoncer la limite de l’identification

Une signature semblable à T sur les quatre sondages exclut-elle M ? Que faudrait-il avant de qualifier l’exercice d’outil validé de détection des conceptions erronées ?

> **Réponse:** Non. M a été construite pour concorder sur ces sondages et différer à un angle réservé à la vérification. Le résultat d’unicité dépend du catalogue fini. Une validation nécessiterait des réponses réelles de la population cible, le raisonnement et l’assistance documentés, une revue appropriée des items et des éléments sur la fidélité, le pouvoir discriminant et l’interprétation. Une table mathématique de prédictions ne fournit à elle seule aucune de ces propriétés empiriques.

## 5. Préparer une évaluation avant d’automatiser l’adaptation

### Exercice 5 : rédiger un protocole pour apprenants avec l’aide des sources

Lisez les deux résumés, PHY-012 et le relevé fixé des signatures. Proposez une tentative réelle délimitée qui conserve les erreurs utiles tout en évitant une étiquette de modèle mental ou une affirmation de gain d’apprentissage sans fondement.

> **Réponse:** Conservez, avant tout retour, l’angle, le repère, le déplacement, les unités, le vecteur et l’énergie prédits, l’explication, la confiance et l’assistance pour chaque consigne. Vérifiez le corrigé de manière indépendante, variez les angles et les cas réservés à la vérification, et demandez pourquoi une réponse a été choisie au lieu d’attribuer une étiquette stable de modèle mental à partir d’une seule correspondance. Consignez les réponses manquantes ou incohérentes. Examinez l’interprétation réelle avec des apprenants et un spécialiste du domaine avant de tester un retour adaptatif par rapport à une comparaison déclarée et à un critère d’évaluation différé. Comparez d’abord un simple retour écrit avant d’ajouter un tuteur agentique. Aucune validité auprès de participants, aucun bénéfice causal ni aucun déploiement n’a été établi ici.
