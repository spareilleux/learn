---
title: Perte d’information lors des transmissions entre agents
description: Perte d’information lors des transmissions entre agents — Théorie de l'information
sidebar:
  label: INF-004 · Perte d’information lors des transmissions entre agents
  order: 4
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/information-theory/fr/inf-004-information-loss-in-agent-handoffs.fr.md
---

:::note[Streeling University]
**INF-004** · Perte d’information lors des transmissions entre agents · intermédiaire · 35 minutes

Généré par le département *Théorie de l'information* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/information-theory/fr/inf-004-information-loss-in-agent-handoffs.fr.md) · [Mon journal](../../journal/)

Prérequis: [INF-002](../../information-theory/inf-002-optick-compact-vector-information-loss/)
:::

> **Périmètre de la source et du transfert.** Le texte technique ci-dessous provient d’un brouillon archivé. Les mentions historiques d’une absence d’importation ou de compilation dans Learn concernent cette étape antérieure ; ce [dossier de transfert](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/agentic-composition-2026-10-22/README.md) décrit l’importation actuelle et ses vérifications. Les autres expériences indiquées comme non réalisées le restent. Les revues humaines du contenu et de la langue, ainsi que l’essai avec un apprenant, restent à effectuer.

> **Département de théorie de l'information** | Niveau : intermédiaire | Durée estimée : 35 minutes | Statut : brouillon français ; révision du contenu, essai par un apprenant, révision linguistique humaine et révision avant publication en attente

## Objectifs

Après cette leçon, vous saurez :

- Déterminer quels faits une note de transmission GA garantit et lesquels restent des affirmations en texte libre.
- Démontrer une collision avec perte d'information entre des états de livraison distincts.
- Calculer une perte de décision pour une petite fixture de transmission explicitement synthétique.
- Concevoir une transmission compacte qui conserve les preuves nécessaires à une décision nommée, tout en respectant les limites des sources et de l'autorité.

## La question du projet

Le [pont Antigravity de GA figé](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Scripts/antigravity-bridge.ps1) permet à une interface IA de laisser une note à une autre sous `state/handoffs/`. Le script enregistre `from`, un horodatage, la branche, un identifiant Git court de head, le nombre de lignes de l'arbre de travail signalées comme modifiées et une chaîne de transmission libre. Il présente le système de fichiers comme espace partagé entre les deux IA. C'est utile pour s'orienter, mais le script ne vérifie ni les tests, ni la révision, ni la responsabilité d'écriture, ni la publication. La chaîne libre peut les mentionner ; le pont n'impose ni leur présence ni leur véracité.

La question pratique est : **une transmission courte peut-elle préserver assez d'information pour que le prochain agent décide si une modification est prête à être intégrée ?** Cette question est plus restreinte que celle de savoir si la note résume bien toute une session. La réponse dépend de la décision et des preuves que le destinataire peut vérifier. Une branche et un titre peuvent situer le travail, tandis qu'un test échoué ou un autre rédacteur actif modifie la décision d'intégration.

INF-002 a montré une application plusieurs-vers-un des vecteurs bruts OPTIC-K vers les vecteurs compacts. La même forme mathématique apparaît ici : deux états de livraison différents peuvent donner le même titre court. Nous utilisons la théorie de l'information pour examiner la **perte pertinente pour la décision**, sans affirmer que le pont GA implémente un code entropique, que l'échantillon pédagogique estime un véritable taux d'incident ou qu'un champ de transmission accorde à lui seul une autorisation de fusion.

## 1. Distinguer la localisation des preuves

Lisez la [branche `Handoff`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Scripts/antigravity-bridge.ps1#L102-L129) du script figé. Elle écrit un fichier Markdown horodaté et capture avec Git la branche, un identifiant court de head et le nombre de lignes modifiées. Un identifiant court aide à retrouver une révision, mais un artefact révisé précis exige un commit complet immuable et, lorsque le contenu évolue indépendamment, un blob de fichier. Un compte de zéro ligne modifiée ne dit que ce que la commande Git locale a compté à ce moment-là ; il n'établit pas qu'un test a été exécuté ou réussi. Le corps de la note est ce que l'appelant fournit à `-Handoff`.

L'exemple du pont indique qu'une tâche a été intégrée et renvoie à des tests. Cet exemple guide un rédacteur humain ; ce n'est pas un reçu de réussite vérifié par une machine. Si la décision de l'agent destinataire est *ouvrir le bon fichier*, la branche, head et un chemin peuvent suffire. Si la décision est *intégrer cette modification*, il lui faut aussi la source exacte, le périmètre d'écriture, un résultat de test lié à cette source, un résultat de révision et une voie d'intégration autorisée. Ce sont des questions différentes pour le destinataire ; il n'existe donc pas de résumé d'une ligne universellement suffisant.

### Exercice pratique 1 : nommer les preuves manquantes

Une note contient `branch=feature/audio`, `head=abc1234`, `working_tree_dirty_lines=0` et `Audio work ready`. Parmi les éléments suivants, lesquels le pont prouve-t-il : le nom de la branche, un test audio réussi, la responsabilité d'un seul rédacteur et une approbation de révision ?

> **Réponse :** La valeur de branche est capturée depuis Git local lorsque le script écrit la note. Le script n'enregistre aucun verdict de test, aucune déclaration de responsabilité ni aucun verdict de révision ; `ready` est du texte non vérifié. L'identifiant court de head et le compte de zéro ligne modifiée ne comblent pas ces lacunes. Même la valeur de branche n'est qu'une observation locale, pas la preuve que la branche distante ou les sources révisées ont le même état plus tard.

## 2. Une petite collision avec une conséquence mesurable

La [fixture INF-004 fixe](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/information-theory/inf-004/handoff-cases.json) contient quatre cas inventés, tous avec le titre `ready`. Chaque cas porte trois faits booléens : `tests_passed`, `single_writer` et `review_approved`. Pour cette **décision pédagogique uniquement**, un cas est admissible si les trois sont vrais. Un véritable projet exigerait aussi de vérifier les sources exactes et l'autorisation ; le modèle simplifié les omet pour isoler un mécanisme de perte d'information.

| Cas | Titre | Tests réussis | Un seul rédacteur | Révision approuvée | Admissibilité du modèle |
|---|---|---|---|---|---|
| A | ready | oui | oui | oui | oui |
| B | ready | non | oui | oui | non |
| C | ready | oui | non | oui | non |
| D | ready | oui | oui | non | non |

L'encodeur de titres transforme quatre états de preuve différents en une même sortie. Un destinataire qui ne voit que `ready` ne peut pas distinguer A de B, C ou D. Cela prouve une collision dans la fixture ; cela ne prouve pas à quelle fréquence une véritable transmission GA est trompeuse. L'[évaluateur local](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/information-theory/inf-004/evaluate_handoffs.py) reproduit le tableau et les coûts :

```powershell
python state/streeling/fixtures/information-theory/inf-004/evaluate_handoffs.py
```

### Exercice pratique 2 : construire le contre-exemple

Quelle paire de cas suffit à réfuter l'affirmation « le titre `ready` détermine l'admissibilité de manière unique » ? Quelle information a été perdue ?

> **Réponse :** A et B ont le même titre, mais A passe les trois contrôles du modèle alors que B échoue au contrôle des tests. Leur valeur encodée identique correspond à des admissibilités différentes ; le titre ne peut donc pas déterminer la décision. A et C ou A et D conviennent aussi. Au moins la valeur du contrôle qui les distingue a été perdue.

## 3. Chiffrer la mauvaise décision, puis contester le modèle

La fixture attribue un coût inventé de 10 unités à l'acceptation d'un cas inadmissible et de 1 unité au rejet d'un cas admissible. Ce sont des poids pédagogiques, pas des coûts de défaut observés. Un destinataire qui n'a que le titre doit prendre la même décision pour les quatre cas. `accept all` produit trois fausses acceptations : coût total `3 × 10 = 30`, coût moyen `30/4 = 7.5`. `reject all` produit un faux rejet : coût total `1`, coût moyen `1/4 = 0.25`. Pour cet échantillon et ces coûts asymétriques, l'action constante la moins coûteuse est de tout rejeter. Le but n'est pas de recommander le rejet systématique, mais de montrer pourquoi un message compressé peut imposer un mauvais choix.

Lorsque les trois booléens de preuve sont disponibles et fiables **dans le cadre de la fixture simplifiée**, le destinataire applique la règle du modèle à chaque cas et ne commet aucune erreur de classement, pour un coût moyen nul. Dans un véritable workflow, ajouter du texte booléen ne suffirait pas à le rendre fiable. Les tests devraient renvoyer à une commande, à un résultat et à une révision exacte ; la responsabilité d'écriture, à une déclaration ou à un périmètre convenu ; la révision, à un verdict identifiable sur le blob exact. Le destinataire peut alors vérifier chaque lien au lieu de croire un statut autodéclaré.

### Exercice pratique 3 : calculer la perte de décision

Pour les quatre lignes et les coûts affichés, calculez la perte moyenne de `accept all`, de `reject all` et de la règle simplifiée disposant de toutes les preuves. Quelle action constante coûte le moins cher ici ?

> **Réponse :** `accept all` : trois fausses acceptations coûtent 30 au total, soit `7.5` par cas. `reject all` : seul A est un faux rejet, pour un coût total de 1, soit `0.25` par cas. La règle disposant de toutes les preuves classe correctement les quatre lignes du modèle et coûte `0`. Tout rejeter est l'action **constante** la moins coûteuse pour cet échantillon inventé et ce choix de coûts, pas une politique générale de projet.

### Exercice pratique 4 : tester la sensibilité

Gardez les quatre cas, mais remplacez le coût d'une fausse acceptation de 10 par `0.1`, en laissant celui d'un faux rejet à 1. Ce cas de sensibilité est un calcul à la main : l'évaluateur figé n'accepte que des coûts à valeur entière et rejettera une fixture JSON contenant `0.1` sans modification de l'évaluateur. Quelle action constante a le coût moyen le plus faible ? Que nous apprend l'inversion du résultat ?

> **Réponse :** `accept all` coûte maintenant `3 × 0.1 / 4 = 0.075` ; `reject all` reste à `1/4 = 0.25`, donc tout accepter coûte moins cher avec les nouveaux poids. La meilleure action dépend du modèle de perte associé à la décision. Aucun des deux jeux de coûts inventés n'estime le coût réel d'une mauvaise intégration ni ne prouve ce que GA devrait automatiser.

## 4. Garder la transmission vérifiable minimale

Pour une décision d'intégration, proposez un enregistrement de transmission contenant un commit **complet** et les identifiants des blobs concernés ; le dépôt, la branche et le worktree ; le rédacteur unique et son périmètre d'écriture ; la commande de test, son résultat de sortie et la révision des sources ; le verdict de révision et le blob révisé ; ainsi que la prochaine action exacte demandée. Le destinataire devrait comparer indépendamment ces références au checkout actuel et à l'état de révision. C'est un contrat de transmission candidat, pas l'affirmation que le pont GA actuel l'émet ou le valide. Il est volontairement propre à une tâche : une transmission de navigation visuelle peut nécessiter une capture d'écran ou une ligne de fichier plutôt qu'un verdict de révision.

Pourquoi ne pas copier une transcription complète ? Elle peut contenir beaucoup de contexte inutile, des affirmations périmées et du contenu que le destinataire ne peut pas vérifier rapidement. La meilleure question de conception est de savoir quels faits sont **suffisants pour la prochaine action nommée** et quelles incertitudes doivent rester explicites. Un enregistrement compact peut renvoyer à des artefacts immuables plus volumineux. Si les références sont introuvables ou si le blob révisé diffère, la décision d'intégration devrait s'arrêter en attendant de nouvelles preuves, sans déduire silencieusement une réussite du mot `ready`.

### Exercice pratique 5 : rédiger une transmission réfutable

Vous recevez `GA audio change ready; tests pass`. Rédigez les champs complémentaires minimaux nécessaires pour décider de l'intégration. Nommez une observation qui réfuterait l'état `ready` annoncé.

> **Réponse :** Demandez le commit GA complet et les identifiants des blobs modifiés, le worktree et la branche, le périmètre d'écriture d'un seul rédacteur, la commande exacte de test audio et son résultat liés à ce commit, le verdict de révision lié à ces blobs et l'action d'intégration ou l'autorité demandée. Si le test consigné a porté sur un autre commit, si un réviseur a vu un autre blob ou si un autre rédacteur est responsable des mêmes fichiers, l'état annoncé de préparation à l'intégration est réfuté. La note n'a pas à prouver la qualité audio ; celle-ci exige son propre protocole d'écoute et d'évaluation du signal.

## Limites et prochaine vérification

Le script GA figé au commit `dc2e74cbd992a298f67efb928b5b3754615e1924` établit ce que le pont écrit, pas la vérité d'une transmission passée. Les quatre lignes et les coûts sont synthétiques. L'évaluateur vérifie l'arithmétique et la structure élémentaire de la fixture ; il ne mesure ni la compression en bits, ni les taux d'erreur réels des agents, ni la provenance des tests, ni la sûreté des fusions. La prochaine expérience de portée limitée consisterait à échantillonner de véritables transmissions autorisées, à définir à l'avance la décision du destinataire, à comparer chaque note aux reçus immuables de tests, de révision et de sources, puis à compter les faits critiques manquants pour la décision. La confidentialité et les autorisations encadreraient cet échantillonnage. L'absence de réduction des décisions erronées ou retardées par rapport au pont existant conduirait à rejeter le format enrichi proposé.
