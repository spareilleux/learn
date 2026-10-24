---
module_id: dv-002-denominators-and-test-populations
department: data-visualization
course: Dénominateurs et évolution des populations de test
level: beginner
prerequisites: [dv-001-observed-degraded-stale-quality]
estimated_duration: "30 minutes"
produced_by: codex-project-pilot
research_cycle: data-visualization-2026-10-11-002
version: "0.1.0"
---

# Dénominateurs et évolution des populations de test

> **Département de visualisation des données** | Niveau : débutant | Durée estimée : 30 minutes | Statut : brouillon de traduction ; relecture humaine du fond, relecture linguistique par une personne maîtrisant le français et essai par un apprenant en attente

Données pour les exercices hors ligne : [six instantanés GA figés](../../../../code/streeling/fixtures/data-visualization/historical-ga/README.md). Ces données sont historiques ; le comportement actuel du service n'est pas évalué.

## Objectifs

À la fin de ce cours, vous saurez :

- reconstituer un pourcentage global à partir des effectifs et des taux des catégories, sans faire aveuglément la moyenne des pourcentages ;
- afficher le dénominateur à côté d'un taux de réussite du contrôle qualité et distinguer un changement de résultat d'un changement de population de test ;
- étiqueter un calcul contrefactuel pour qu'il ne puisse pas être confondu avec une exécution GA observée ;
- préciser les éléments supplémentaires nécessaires pour comparer équitablement deux instantanés historiques du contrôle qualité.

## La question du projet

Les instantanés du contrôle qualité du chatbot GA indiquent un pourcentage global de réussite et des totaux par catégorie. Supposons qu'un tableau de bord annonce que le chatbot est passé de 75% à 98.08%. Que comptaient ces chiffres, et portaient-ils sur les mêmes questions ?

Utilisez les instantanés historiques du [15 juin](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/chatbot-qa/2026-06-15.json) et du [19 juillet](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/chatbot-qa/2026-07-19.json) au commit GA [`dc2e74c`](https://github.com/GuitarAlchemist/ga/tree/dc2e74cbd992a298f67efb928b5b3754615e1924). Aucun des deux ne décrit le service d'aujourd'hui. Tous deux indiquent `total_prompts: 52` et `degraded: false`. Celui de juin indique `pass_pct: 75.0` ; celui de juillet, `pass_pct: 98.08`. Les fichiers donnent les totaux et les pourcentages arrondis des catégories, mais ni la liste des identités des prompts ni la révision de l'évaluateur.

### Exercice

Rédigez un sous-titre de graphique en une ligne qui conserve le dénominateur et la portée historique.

> **Réponse :** « Instantanés historiques du contrôle qualité du chatbot GA : 75% sur 52 prompts le 15 juin et 98.08% sur 52 prompts le 19 juillet 2026 ; ces fichiers n'établissent ni l'identité des prompts ni la révision de l'évaluateur. »

## 1. Un pourcentage porte sur une population comptée

Pour un résultat binaire réussite/échec, `pass rate = passed / evaluated`. Dans ces fichiers, 75% sur 52 correspond à 39 réussites. Un taux de 98.08% correspond à 51 sur 52 après arrondi à deux décimales. Les fichiers ne stockent pas directement ces nombres entiers globaux ; on les reconstitue à partir des pourcentages publiés et du dénominateur. Conservez cette distinction dans la trace d'audit.

Le dénominateur est plus qu'un libellé. Il indique combien d'éléments ont été évalués, mais **pas lesquels**. Deux exécutions de 52 prompts chacune peuvent utiliser des prompts différents, des réponses attendues modifiées ou d'autres règles de notation. Un graphique fidèle peut montrer les deux taux publiés tout en signalant que leur comparabilité n'est pas vérifiée.

### Exercice

Calculez le nombre reconstitué de réussites pour chaque exécution, puis évaluez cette phrase : « Les mêmes 52 questions ont gagné 12 réussites. »

> **Réponse :** Juin donne `0.75 × 52 = 39` ; juillet donne `0.9808 × 52 ≈ 51`, soit 12 réussites reconstituées de différence. La phrase citée va trop loin : les fichiers n'établissent pas que les mêmes 52 questions ou le même évaluateur ont été utilisés.

## 2. Pondérer les catégories par leurs effectifs

L'instantané de juin indique `operations: 28.57%` pour 7 prompts et `typo-tolerance: 75%` pour 4. Ces pourcentages arrondis permettent de reconstituer environ 2 et 3 réussites. La moyenne de `28.57%` et `75%` donne `51.785%`, mais elle traite une catégorie de sept prompts comme si elle avait le même effectif qu'une catégorie de quatre. Pour leurs 11 prompts réunis, utilisez les nombres reconstitués : `(2 + 3) / (7 + 4) = 5 / 11 ≈ 45.45%`.

Pour agréger l'ensemble de l'instantané, additionnez les réussites et les effectifs des catégories. Les totaux des onze catégories de juin donnent 52, et leurs réussites reconstituées donnent 39. Cela concorde avec le taux global publié de 75%. Un graphique devrait montrer les effectifs des catégories, surtout lorsqu'une catégorie ne compte qu'une ou deux questions. Un libellé de 100% pour une question n'apporte pas autant d'éléments qu'un taux de 100% pour treize.

| Catégorie du 15 juin | Taux publié | Nombre total de prompts | Réussites reconstituées |
|---|---:|---:|---:|
| Opérations | 28.57% | 7 | 2 |
| Tolérance aux fautes de frappe | 75% | 4 | 3 |
| Deux catégories réunies | **45.45%** | **11** | **5** |

Le mot « reconstituées » compte : ces nombres sont déduits de pourcentages arrondis et de petits dénominateurs entiers, et non copiés depuis un champ brut de nombre de réussites.

### Exercice

Une personne place les deux pourcentages des catégories dans un diagramme en barres, puis appelle leur moyenne simple « taux de réussite combiné ». Corrigez le libellé et le calcul.

> **Réponse :** Indiquez l'effectif de chaque catégorie sur sa barre. Pour le taux combiné, affichez `5/11 ≈ 45.45%`, calculé à partir des réussites reconstituées. N'utilisez pas la moyenne non pondérée de 51.785%.

## 3. Une population différente peut changer le chiffre principal

Les fichiers historiques de juin et de juillet indiquent tous deux 52 prompts, mais ce nombre seul ne prouve pas que la cohorte est fixe. Pour comprendre l'effet de la composition, faites un **exercice contrefactuel**, et non une troisième observation GA : retirez des totaux de juin les sept prompts `operations` et leurs deux réussites reconstituées. Le sous-ensemble obtenu donne `37 / 45 ≈ 82.22%`, contre `39 / 52 = 75%` à l'origine. Aucune réponse ne s'est améliorée dans ce calcul. Seule la population a changé.

Le but n'est pas de recommander de supprimer les prompts difficiles. Il est de montrer comment un tableau de bord peut sembler s'améliorer quand une catégorie difficile disparaît. Une véritable tendance du contrôle qualité doit conserver ou expliciter les prompts utilisés, la composition des catégories, les règles de notation et les cas exclus. Si le système ne fournit pas ces éléments, affichez « le taux publié a changé ; comparabilité des cohortes inconnue », puis un lien vers l'enquête.

### Exercice

Faites un tableau de deux lignes : l'exécution réelle de juin et le sous-ensemble contrefactuel. Quelle ligne peut être tracée comme mesure GA datée ?

> **Réponse :** Juin réel : 39 réussites reconstituées / 52 prompts = 75%. Sous-ensemble contrefactuel : 37 réussites reconstituées / 45 prompts ≈ 82.22%. Seule la ligne de 52 prompts est une mesure GA publiée. Étiquetez le sous-ensemble comme un calcul pédagogique, sans date d'exécution ni point dans une tendance.

## 4. Formuler l'affirmation de comparaison

Une vue utile de la qualité GA présente ensemble le taux et le dénominateur, donne la composition des catégories et renvoie à l'instantané épinglé. Elle doit séparer l'état de l'observation de la qualité, comme dans [DV-001](dv-001-observed-degraded-stale-quality.md). Quand l'identité des prompts et la révision de l'évaluateur ne sont pas disponibles, une mention visible « comparabilité non vérifiée » empêche le graphique en courbe de suggérer silencieusement une expérience contrôlée.

Pour une comparaison future plus solide, enregistrez une révision stable du corpus de prompts, la révision de l'évaluateur, la configuration du backend/modèle et le résultat réussite/échec de chaque prompt. Comparez ensuite les prompts appariés, signalez séparément les ajouts et les retraits, et conservez les instantanés historiques d'origine. Un nombre brut de réussites est utile, mais ne remplace pas ces identités.

### Exercice

Examinez ce titre : « La qualité GA a gagné 23.08 points de pourcentage sur le même jeu de tests. » Proposez une formulation défendable et nommez une prochaine mesure.

> **Réponse :** « Le taux de réussite publié du contrôle qualité du chatbot était de 75% sur 52 prompts le 15 juin et de 98.08% sur 52 le 19 juillet ; l'équivalence des jeux de tests n'est pas vérifiée. » L'écart arithmétique est de 23.08 points de pourcentage, mais « même jeu de tests » exige une révision épinglée du corpus de prompts et une comparaison prompt par prompt.

## À retenir

- Montrez le numérateur et le dénominateur lorsque les données permettent de les reconstituer.
- Combinez les catégories à partir des nombres, et non d'une moyenne non pondérée de leurs pourcentages.
- Un total inchangé ne prouve pas une population de test inchangée.
- Un sous-ensemble contrefactuel sert à expliquer ; ce n'est pas un résultat de contrôle qualité enregistré.
- Une tendance comparable exige l'identité des prompts et la provenance de l'évaluateur, en plus des pourcentages.

## Sources et éléments du projet

- GA : [instantané du contrôle qualité du 15 juin](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/chatbot-qa/2026-06-15.json) et [instantané du 19 juillet](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/chatbot-qa/2026-07-19.json), épinglés au même commit historique.
- [DV-001](dv-001-observed-degraded-stale-quality.md) pour les observations absentes et les anciennes valeurs reportées.

*Recherche : `data-visualization-2026-10-11-002`. Brouillon de traduction ; relecture humaine du fond, essai par un apprenant, relecture linguistique par une personne maîtrisant le français et vérification publique en attente.*
