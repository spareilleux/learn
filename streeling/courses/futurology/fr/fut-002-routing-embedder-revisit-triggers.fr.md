---
module_id: fut-002-routing-embedder-revisit-triggers
department: futurology
course: Conditions de réexamen de l’embedder de routage de GA
level: early-intermediate
prerequisites: [fut-001-thinking-about-tomorrow]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
research_cycle: futurology-2026-10-11-002
version: "0.1.0"
---

# Quand GA devrait-il réexaminer son embedder de routage ?

> **Périmètre de la source et du transfert.** Le texte technique ci-dessous provient d’un brouillon archivé. Les mentions historiques de traductions encore à rédiger, d’une absence d’importation ou de compilation dans Learn concernent cette étape antérieure ; ce [dossier de transfert](../../../../code/streeling/evidence/representation-release-2026-10-22/README.md) décrit les brouillons de traduction actuels, l’importation et ses vérifications. Les autres expériences indiquées comme non réalisées le restent. Les revues humaines du contenu et de la langue, ainsi que l’essai avec un apprenant, restent à effectuer.

> **Département de futurologie** | Niveau : début intermédiaire | Durée estimée : 35 minutes | Statut : brouillon français ; révision du contenu, essai par un apprenant, révision linguistique humaine et révision avant publication en attente

## Objectifs

Après cette leçon, vous saurez :

- Distinguer un choix historique de modèle, sa méthode d'évaluation et une condition future qui justifierait son réexamen.
- Calculer la marge par rapport à un seuil déclaré sans présenter un petit benchmark comme une prévision de déploiement.
- Expliquer pourquoi un changement de modèle exige son propre balayage des seuils de confiance et pourquoi huit prompts hors périmètre donnent un taux peu précis.
- Rédiger une réponse à un scénario de portée limitée : quoi mesurer, quelle branche sélectionner et quelle observation réfuterait la branche privilégiée.

## La question du projet

Au commit GA figé [`dc2e74cbd992a298f67efb928b5b3754615e1924`](https://github.com/GuitarAlchemist/ga/tree/dc2e74cbd992a298f67efb928b5b3754615e1924), la configuration de routage du chatbot nomme `bge-large` avec `MinConfidence: 0.64`. Le [plan d'évaluation](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/docs/plans/2026-06-16-ml-text-embedder-evaluation-plan.md) décrit ce remplacement pour le routage comme livré à sa date historique et réversible en rétablissant deux valeurs de configuration. Il diffère un éventuel remplacement global de l'embedder du magasin mémoire, qui exigerait des preuves distinctes et une migration de l'index persistant. Le [fichier appsettings figé](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Apps/GaChatbot.Api/appsettings.json) corrobore le modèle de routage et son seuil ; il ne constitue pas une vérification d'un déploiement actif.

La question utile pour l'avenir n'est pas « quel modèle gagnera l'an prochain ? », mais : **quelle nouvelle observation rendrait ce choix précis de routage digne d'être réexaminé ?** Cette leçon construit un petit registre de déclencheurs à partir du benchmark et du relevé de validation figés. [FUT-001](fut-001-thinking-about-tomorrow.md) enseigne les horizons larges et les scénarios 2×2. Ici, un scénario est une branche délimitée **si une condition est mesurée, alors effectuer le prochain test**. Il n'a ni probabilité inventée ni échéance calendaire. La branche peut être erronée ; les preuves nécessaires pour la rejeter font partie de sa conception.

## 1. Figer la décision et les deux étapes d'évaluation

Le [rapport comparatif Phase 0](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/embedder-bakeoff/bakeoff-latest.md) a évalué 166 prompts dans le périmètre, répartis entre 16 intentions. Son résultat de validation croisée à cinq plis, avec cosinus et un plus proche voisin, est un **indicateur indirect du mécanisme de routage**, pas toute la pile de routage de production. Il rapporte aussi la silhouette des intentions et la latence d'un **seul embedding**. L'[artefact numérique du comparatif](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/embedder-bakeoff/bakeoff-latest.json) donne pour `bge-large` une latence p95 de `238.27479999454226 ms` et pour la référence nomic de `101.44889999355655 ms`. Le rapport choisit un budget p95 de 500 ms pour le parcours de chat et indique que les candidats le respectent. Comparer un embedding unique à ce budget ne prouve pas un p95 de chat mesuré de bout en bout.

| Modèle Phase 0 | Exactitude de validation croisée indirecte | p95 pour un seul embedding | Rôle dans la décision |
|---|---:|---:|---|
| `nomic-embed-text` | 0.644 | 101.449 ms | Référence de routage précédente |
| `bge-large` | 0.705 | 238.275 ms | Gagnant de l'indicateur indirect ; à soumettre au harness complet |

La [validation Phase 2 ultérieure](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/embedder-bakeoff/phase2-validation-2026-06-16.md) a exécuté le `RoutingEvalHarness` complet, avec descriptions, renforcements par indices et seuil de confiance. Ses chiffres d'exactitude ne doivent **pas** être soustraits aux chiffres indirects de Phase 0 comme s'il s'agissait des mêmes tests. Sur le harness complet, la référence nomic au seuil `0.55` obtenait une exactitude dans le périmètre de `0.934` et un taux de refus hors périmètre (OOS) de `0.875`. `bge-large` au même seuil `0.55` conservait une exactitude dans le périmètre de `0.946`, mais ne refusait que `0.375` des prompts OOS. Après recalibrage à `0.64`, il conservait `0.946` dans le périmètre et refusait `1.000` des prompts OOS **dans cette exécution de validation**.

Le changement dépendait donc d'une **paire**, modèle et seuil. Un nouvel embedder peut modifier l'échelle des scores cosinus ; recopier le seuil du modèle précédent peut donc imposer un routage aux prompts inconnus. Le plan figé demande de répéter le balayage des seuils prompt par prompt lors des futurs changements et de garder les réglages du harness alignés sur ceux de production. Ni un meilleur score indirect ni un seuil recopié ne suffisent à une promotion.

### Exercice pratique 1 : calculer la marge de latence

À partir de l'artefact numérique Phase 0, soustrayez le p95 d'un seul embedding de `bge-large` du budget de 500 ms du rapport. De combien ce p95 mesuré était-il plus lent que celui de nomic ? Quelle affirmation reste sans fondement ?

> **Réponse :** La marge arithmétique est `500 - 238.27479999454226 = 261.72520000545774 ms`, soit environ **261.7 ms**. L'écart avec nomic est `238.27479999454226 - 101.44889999355655 = 136.8259000009857 ms`, soit environ **136.8 ms**. Les deux sont des comparaisons portant sur un seul embedding lors de cette exécution fixe. Elles n'établissent ni le p95 du chat de bout en bout, ni le comportement sur un autre hôte ou sous une autre charge, ni une garantie future de latence.

### Exercice pratique 2 : comparer des mesures comparables

De combien l'exactitude dans le périmètre sur le harness complet a-t-elle augmenté entre nomic à `0.55` et `bge-large` recalibré à `0.64` ? Pourquoi `0.946 - 0.705` est-il une mauvaise comparaison pour cette question ?

> **Réponse :** `0.946 - 0.934 = 0.012`, soit **1.2 point de pourcentage**, dans la comparaison sur le harness complet. Le chiffre `0.705` est l'exactitude indirecte de `bge-large` en Phase 0, obtenue par un plus proche voisin selon une autre méthode. Le soustraire à la Phase 2 mélangerait des mesures différentes et ne donnerait pas une amélioration du modèle.

## 2. Transformer le balayage des seuils en branches délimitées

Partez d'une référence consignée et écrivez **quelle nouvelle mesure change l'action**. Utilisez le résultat historique dans le périmètre de `0.934` comme seuil de promotion du plan. Suivez séparément le refus OOS comme garde-fou ; le rapport Phase 2 prévient que seuls **huit prompts OOS** ont été étiquetés. Un seul prompt change ce taux de `1/8 = 12.5` points de pourcentage. Le budget de 500 ms a été appliqué à la mesure d'un seul embedding du comparatif ; une nouvelle mesure comparable de latence a donc sa place dans le registre. Une mesure distincte de bout en bout est nécessaire avant de promettre un niveau de service de chat.

| Branche future | Observation à recueillir | Prochaine action délimitée |
|---|---|---|
| **Conserver et surveiller** | Le résultat comparable dans le périmètre sur le harness complet franchit toujours le seuil historique ; les preuves OOS ne montrent pas de régression stable ; la latence respecte le budget choisi | Conserver provisoirement la paire de routage et élargir l'ensemble OOS étiqueté. Consigner date, corpus, seuil, hôte et version du modèle. |
| **Recalibrer** | L'exactitude dans le périmètre se maintient, mais le refus OOS baisse après un changement de modèle, de mélange de prompts ou de distribution des scores | Examiner les scores prompt par prompt, balayer les seuils et relancer le harness complet avant de modifier la paire configurée. Ne pas supposer que l'ancien `0.64` convient à un autre modèle. |
| **Comparer ou revenir en arrière** | Une exécution comparable échoue au seuil historique dans le périmètre, ou une nouvelle mesure échoue au seuil de latence | Reproduire le résultat, comparer au modèle précédent dans les mêmes conditions et utiliser la configuration de routage réversible du plan si un retour arrière est justifié. |

Ce sont des **règles de décision pour enquêter**, pas des affirmations selon lesquelles une branche s'est réalisée. Les preuves OOS doivent être examinées avec la taille de leur échantillon et le type d'erreur, plutôt qu'avec un seuil universel recopié depuis huit exemples. Un nouveau modèle exige aussi de distinguer les périmètres du routage et de la mémoire : le plan figé a délibérément découplé le routage de l'embedder de mémoire persistante. Étendre une victoire de routage au magasin mémoire serait une autre décision, lourde en migration.

### Exercice pratique 3 : voir ce que le calibrage a changé

Dans le balayage des seuils Phase 2, qu'a changé le passage de `bge-large` de `T=0.55` à `T=0.64` pour le refus OOS et l'exactitude dans le périmètre ? Convertissez les taux OOS en nombres de prompts à partir des huit prompts OOS du rapport.

> **Réponse :** Le refus OOS est passé de `0.375 = 3/8` à `1.000 = 8/8`, soit un gain de **cinq prompts refusés** ou de **62.5 points de pourcentage** dans cet échantillon de validation. L'exactitude dans le périmètre est restée à `0.946`. Cela n'établit pas combien de futurs prompts OOS, distribués autrement, seront refusés.

### Exercice pratique 4 : tester un seuil trop strict

À `T=0.72`, le balayage rapporte `0.934` dans le périmètre ; à `T=0.75`, il rapporte `0.916`. Lequel dépasse le résultat historique nomic de `0.934` dans le périmètre, et de combien `0.75` le manque-t-il ?

> **Réponse :** Aucun ne dépasse `0.934` : `0.72` ne fait que **l'égaler**, tandis que `0.75` est inférieur de `0.934 - 0.916 = 0.018`, soit **1.8 point de pourcentage**. Les deux seuils rapportent un refus OOS de `1.000` sur le petit ensemble de validation, ce qui montre pourquoi la réussite OOS seule ne suffit pas à décider du routage.

## 3. Énoncer le contre-argument et le critère de réfutation

Le contre-argument le plus fort contre l'idée que `bge-large` resterait durablement le meilleur choix est concret. Son p95 mesuré pour un seul embedding était environ 136.8 ms plus lent que celui de nomic en Phase 0. Le taux de validation OOS provenait de huit prompts, et le [statut daté du plan](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/docs/plans/2026-06-16-ml-text-embedder-evaluation-plan.md#L124-L146) consigne une **réexécution locale de 7/8**, et non les 8/8 de la validation. Un décideur pourrait raisonnablement préférer le modèle précédent, moins coûteux, si une nouvelle charge comparable montre que le gain de qualité mesuré a disparu ou que le coût en latence dépasse le budget pertinent. Les artefacts figés ne montrent pas, à eux seuls, que cela s'est produit.

Un critère de réfutation utile est donc un nouveau résultat versionné du harness complet, au seuil réellement configuré, qui tombe **sous le seuil historique de 0.934 dans le périmètre**, ou un p95 mesuré comparable qui dépasse le seuil de latence convenu. Un ensemble OOS plus vaste révélant un problème de refus reproductible imposerait aussi de comparer seuils et candidats. Consignez le dénominateur, l'identité des prompts ou une révision stable du corpus, l'hôte et les versions des outils ; sinon, une variation apparente peut provenir de la mesure. Ne déduisez pas de tendance monotone de deux exécutions sur huit exemples OOS et n'extrapolez pas linéairement la latence avec la concurrence sans la mesurer.

### Exercice pratique 5 : interpréter un petit dénominateur

La validation Phase 2 rapportait un refus OOS de `8/8` ; la réexécution locale ultérieure rapportait `7/8`. Quels sont les deux taux et leur écart ? Cela établit-il que la qualité du routage s'est dégradée après livraison ?

> **Réponse :** `8/8 = 1.000` et `7/8 = 0.875`, soit un écart de **0.125**, ou de **12.5 points de pourcentage**, causé par un prompt sur huit. Les relevés seuls n'établissent pas de tendance à la dégradation : ce sont deux exécutions datées sur un très petit ensemble OOS, et la leçon n'a pas établi que les prompts et conditions étaient identiques. La prochaine vérification utile est une évaluation OOS plus vaste et versionnée, accompagnée du harness complet dans le périmètre.

## Limites et suivi du projet

C'est un exercice de décision historique lié à une révision. La configuration figée témoigne de l'intention du dépôt, pas de ce qu'un processus GA actif sert aujourd'hui. La Phase 0 est un indicateur indirect du routage, la Phase 2 un harness plus complet, et aucune n'est une prévision à long terme. Les huit exemples OOS rendent les taux peu précis. La comparaison aux 500 ms repose sur la mesure rapportée d'un seul embedding face à un budget choisi ; une affirmation de niveau de service pour le parcours de chat exige sa propre mesure. Un futur candidat nécessiterait aussi un calibrage, la parité des seuils entre harness et production, et un déploiement réversible. Rien ici n'autorise un recalcul global des embeddings de mémoire.

Si de nouvelles preuves arrivent, mettez à jour le registre des déclencheurs avant de changer de modèle. Une bonne entrée nomme l'observation, sa révision source, la branche qu'elle sélectionne, un contre-argument et la mesure qui pourrait inverser la décision. Cela crée une réponse future vérifiable sans prétendre savoir quand ou si la branche se réalisera. Cette leçon française reste un brouillon ; révision du contenu, essai par un apprenant, révision linguistique humaine et vérification de publication restent en attente.

## Sources figées

- [Rapport et méthode du comparatif GA Phase 0](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/embedder-bakeoff/bakeoff-latest.md) et [résultats numériques](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/embedder-bakeoff/bakeoff-latest.json), tous deux au commit `dc2e74cbd992a298f67efb928b5b3754615e1924`.
- [Balayage des seuils sur le harness complet GA Phase 2](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/embedder-bakeoff/phase2-validation-2026-06-16.md), [plan de décision](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/docs/plans/2026-06-16-ml-text-embedder-evaluation-plan.md) et [configuration du chatbot](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Apps/GaChatbot.Api/appsettings.json), au même commit.
