---
module_id: dv-004-uncertainty-in-small-qa-suites
department: data-visualization
course: L'incertitude dans les petites suites de contrôle qualité
level: beginner
prerequisites: [dv-002-denominators-and-test-populations]
estimated_duration: "30 minutes"
produced_by: codex-project-pilot
research_cycle: data-visualization-2026-10-11-004
version: "0.1.0"
---

# L'incertitude dans les petites suites de contrôle qualité

> **Département de visualisation des données** | Niveau : débutant | Durée estimée : 30 minutes | Statut : brouillon de traduction ; relecture humaine du fond, relecture linguistique par une personne maîtrisant le français et essai par un apprenant en attente

Données pour les exercices hors ligne : [six instantanés GA figés](../../../../code/streeling/fixtures/data-visualization/historical-ga/README.md). Ces données sont historiques ; le comportement actuel du service n'est pas évalué.

## Objectifs

À la fin de ce cours, vous saurez :

- calculer l'effet, en points de pourcentage, d'un résultat modifié dans une suite ou une catégorie ;
- afficher les nombres exacts à côté des pourcentages arrondis sans prétendre disposer des résultats bruts par prompt ;
- distinguer la résolution d'une suite finie de tests d'un intervalle de confiance statistique ;
- préciser les éléments qui rendraient une comparaison de qualité GA reproductible.

## La question du projet

Un tableau de bord GA affiche un taux historique de réussite du contrôle qualité du chatbot de 98.08%. Quelle précision ce chiffre principal a-t-il lorsque l'exécution contient 52 prompts, et que reste-t-il inconnu même si le calcul est juste ? Utilisez les instantanés du [15 juin](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/chatbot-qa/2026-06-15.json) et du [19 juillet](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/chatbot-qa/2026-07-19.json) au commit GA épinglé [`dc2e74c`](https://github.com/GuitarAlchemist/ga/tree/dc2e74cbd992a298f67efb928b5b3754615e1924). Ce sont des données historiques pour l'apprentissage, et non l'état du service aujourd'hui.

Les deux fichiers indiquent `total_prompts: 52` et `degraded: false`. Juin indique `pass_pct: 75.0` ; juillet, `pass_pct: 98.08`. Les nombres globaux de réussites sont **reconstitués** à 39/52 et 51/52 à partir des pourcentages arrondis. Les instantanés ne fournissent ni l'identité des prompts, ni les verdicts bruts par prompt, ni la révision de l'évaluateur. [DV-002](dv-002-denominators-and-test-populations.md) explique pourquoi des totaux identiques ne prouvent pas une population de test identique.

### Exercice

Rédigez un libellé de graphique pour juillet qui donne le chiffre et sa limite en une ligne.

> **Réponse :** « Contrôle qualité historique du chatbot GA, 19 juillet : taux publié de 98.08% sur 52 prompts (environ 51 réussites reconstituées) ; les verdicts par prompt et la révision de l'évaluateur ne figurent pas dans cet instantané. »

## 1. Montrer le pas derrière les décimales

Avec 52 résultats binaires, un résultat modifié fait varier le taux global de `100 / 52 ≈ 1.92` point de pourcentage. Un taux affiché à deux décimales peut donc sembler bien plus continu que les pas sous-jacents. Pour juillet, `51 / 52 × 100 ≈ 98.08%` ; une réussite de moins donnerait `50 / 52 × 100 ≈ 96.15%`. Aucun de ces calculs ne prédit l'exécution suivante. Ils montrent seulement l'effet d'un verdict sur ce dénominateur fixe.

Les taux publiés de juin et de juillet diffèrent de 23.08 points de pourcentage, ce qui équivaut à douze réussites reconstituées si le dénominateur reste fixé à 52. C'est une comparaison arithmétique, et non la preuve que douze prompts précis ont changé de verdict. Les instantanés ne donnent pas l'identité des prompts ni la provenance de la notation.

### Exercice

Si exactement un des 13 échecs reconstitués de juin devenait une réussite **dans une suite fixe hypothétique de 52 prompts**, quel taux le calcul produirait-il ? Peut-on le tracer comme une nouvelle exécution GA ?

> **Réponse :** `(39 + 1) / 52 × 100 ≈ 76.92%`, soit une hausse d'environ 1.92 point de pourcentage. Il s'agit d'un calcul hypothétique de sensibilité ; aucune nouvelle exécution GA n'a été observée.

## 2. Les petites catégories ont de plus grands pas

La catégorie `operations` de juillet indique 85.71% pour sept prompts, ce qui correspond à six réussites reconstituées. Un verdict modifié dans cette catégorie fait varier son taux de `100 / 7 ≈ 14.29` points de pourcentage. La catégorie `getting-started` indique 100% pour **un seul** prompt. Un badge de 100% pour un prompt et un badge de 100% pour treize prompts (`modes`) couvrent des périmètres très différents, même si les deux barres se terminent au même endroit.

Pour un graphique par catégorie, placez la fraction reconstituée près du pourcentage et triez ou regroupez selon la question précise de comparaison. Un libellé utile serait « Opérations : 6/7 reconstituées, 85.71% publié ». Ne qualifiez pas les sept prompts de la catégorie d'échantillon aléatoire à moins que le protocole de test n'établisse un échantillonnage aléatoire. Un intervalle de confiance classique répondrait à une question statistique d'échantillonnage dont ces fichiers ne documentent pas les hypothèses.

### Exercice

Comparez l'effet d'un verdict modifié dans la suite globale, dans `operations` et dans `getting-started`. Quel chiffre principal est le plus sensible à un verdict ?

> **Réponse :** Les pas sont d'environ 1.92 point de pourcentage pour 52 prompts, de 14.29 pour sept et de 100 pour un. La catégorie `getting-started`, qui ne contient qu'un prompt, est la plus sensible. Ce sont les effets exacts des dénominateurs, et non des intervalles de confiance.

## 3. Distinguer trois limites dans l'affichage

D'abord, **l'arrondi** : 98.08% est un résultat publié arrondi ; 51/52 est un nombre entier déduit, et non un nombre global de réussites stocké. Ensuite, **la couverture** : 52 prompts peuvent omettre d'autres besoins utilisateurs, langues ou modes d'échec. Enfin, **la comparabilité** : les deux fichiers donnent des totaux égaux, mais pas d'identifiants stables de prompts, de réponses attendues, de versions d'évaluateur ou de configuration du backend. Ajouter des décimales ou une barre d'erreur sans explication ne résout aucune de ces limites.

Utilisez un graphique principal pour le taux publié et un tableau proche indiquant la date, le dénominateur, les effectifs des catégories, l'état de l'exécution et la mention « base de comparaison inconnue ». Liez le JSON historique exact. Si l'exécution est dégradée ou si `pass_pct` vaut `null`, [DV-001](dv-001-observed-degraded-stale-quality.md) impose une lacune, et non un zéro. Si des éléments ultérieurs établissent des prompts appariés et des exécutions répétées, une analyse séparée pourra alors quantifier la variabilité entre exécutions ; distinguez cette mesure du pas lié à un seul verdict.

### Exercice

Un tableau de bord affiche « confiance : 98.08% ± 1.92% », car un prompt vaut 1/52. Corrigez cette affirmation.

> **Réponse :** Affichez « Taux publié de 98.08% sur 52 prompts ; environ 51 réussites reconstituées ; un verdict fait varier le taux de cette suite d'environ 1.92 point de pourcentage ». Ne présentez pas 1/52 comme une confiance : aucun modèle d'échantillonnage ni aucune variabilité entre exécutions répétées n'a été fourni.

## 4. Rendre la prochaine comparaison reproductible

Un enregistrement futur utile du contrôle qualité conserverait une révision du corpus de prompts et de l'évaluateur, l'identifiant de chaque prompt, son critère attendu, le verdict, la configuration du backend/modèle et l'horodatage. Une comparaison pourrait alors aligner les mêmes identifiants, lister séparément les prompts ajoutés et retirés, et montrer les verdicts modifiés. Répéter une suite inchangée dans des conditions enregistrées révélerait aussi une variabilité qu'un seul instantané ne peut pas mesurer.

Pour cette paire historique, la phrase la plus solide est : « Le taux publié est passé de 75% sur 52 le 15 juin à 98.08% sur 52 le 19 juillet ; l'équivalence des prompts et de l'évaluateur n'est pas vérifiée. » Cela apporte des éléments utiles sans inventer de cause ni de probabilité de réussite de l'exécution suivante.

### Exercice

Nommez deux champs à ajouter à un futur enregistrement GA pour pouvoir vérifier que « douze prompts se sont améliorés ». Que doit faire la comparaison des prompts présents dans une seule exécution ?

> **Réponse :** Ajoutez un `prompt_id` stable et un verdict `pass` par prompt, ainsi qu'une révision épinglée de l'évaluateur pour interpréter le verdict. Comparez les identifiants appariés ; présentez les prompts ajoutés ou retirés comme une cohorte distincte plutôt que de les compter comme des réponses modifiées.

## À retenir

- Un verdict représente environ 1.92 point de pourcentage dans une suite de 52 prompts, mais 100 points dans une catégorie d'un seul prompt.
- Les dénominateurs exacts et les nombres reconstitués rendent visible la résolution d'un taux.
- Le pas lié à un verdict n'est pas un intervalle de confiance.
- Des totaux de prompts égaux n'établissent ni l'appariement des prompts, ni la couverture, ni les règles de notation.
- Une future comparaison appariée exige les identifiants des prompts, les verdicts et la provenance de l'évaluateur.

## Sources et éléments du projet

- GA : [instantané historique du 15 juin](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/chatbot-qa/2026-06-15.json) et [instantané du 19 juillet](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/state/quality/chatbot-qa/2026-07-19.json).
- [DV-002](dv-002-denominators-and-test-populations.md) pour reconstituer les nombres et vérifier l'évolution des populations de test.
- [DV-001](dv-001-observed-degraded-stale-quality.md) pour les observations indisponibles.

*Recherche : `data-visualization-2026-10-11-004`. Brouillon de traduction ; relecture humaine du fond, essai par un apprenant, relecture linguistique par une personne maîtrisant le français et vérification publique en attente.*
