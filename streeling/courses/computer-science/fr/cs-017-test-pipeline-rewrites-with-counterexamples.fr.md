---
module_id: "cs-017-test-pipeline-rewrites-with-counterexamples"
department: "computer-science"
course: "Tester les réécritures de pipeline avec des contre-exemples"
title: "Tester les réécritures de pipeline avec des contre-exemples"
level: "intermediate"
prerequisites: ["cs-010-compose-fail-fast-ga-computations"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Tester les réécritures de pipeline avec des contre-exemples

> **Portée du brouillon.** Modèles fixes construits à partir de sources inspectées. Les décisions humaines techniques, linguistiques et d’apprentissage restent en attente. Aucun résultat de flotte active, contrôleur de production, télémétrie utilisateur ou progrès d’apprentissage n’est revendiqué. Le journal distingue tests réellement exécutés, lectures et contrôles prévus.

## Sources à examiner

- [cs-010-compose-fail-fast-ga-computations.md](../../computer-science/en/cs-010-compose-fail-fast-ga-computations.md)
- [GaAsync.fs](https://raw.githubusercontent.com/GuitarAlchemist/ga/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Closures/GaAsync.fs)

Un nettoyage proposé du pipeline GA fusionne des étapes voisines et déplace une validation pour réduire les répétitions. Le code peut raccourcir tout en acceptant une entrée auparavant rejetée. Le prérequis explique la composition dépendante et le changement de parenthésage. Ce cours exige autre chose : conserver un témoin capable de réfuter la réécriture avant de modifier l'implémentation. Nos étapes arithmétiques sont des fonctions construites, pas une nouvelle API GA.

Dans la source GA épinglée, la composition traite séparément succès et erreur, sans appeler la fonction suivante en cas d'erreur. Lisez cette branche réelle. Elle matérialise une frontière de contrôle qu'une réécriture informelle pourrait franchir. Changer le parenthésage conserve l'ordre des fonctions dépendantes. Les permuter change le calcul. Déplacer une condition change la valeur qu'elle examine. Ces transformations demandent des justifications distinctes, même si leur présentation utilise la même notation.

Le modèle emploie des entiers exacts afin qu'un arrondi ne puisse expliquer une différence. Appliquez les deux ordres à chaque entrée fournie et gardez les valeurs intermédiaires sur papier. Les vecteurs obtenus diffèrent à chaque position. Cela suffit à réfuter l'équivalence dans ce modèle, sans déterminer l'ordre voulu par la spécification du produit. La correction exige toujours le comportement demandé par le consommateur et une interprétation valide de l'entrée.

Le témoin situé à la frontière est particulièrement utile. La validation initiale examine la valeur de départ ; la proposition l'examine après l'incrément. Une entrée refusée peut alors devenir acceptée sans erreur arithmétique. Un exemple utilisant seulement une entrée nettement positive manquerait ce changement. Le contrôle négatif conserve le pipeline intact : si la comparaison lui attribue une différence, sa procédure est défectueuse.

Pour le travail avec les sources, annotez la discussion du prérequis sur l'associativité et le branchement réel de composition. Décrivez la réécriture par deux tableaux d'entrées et de sorties plutôt que par un nouveau DSL. Demandez ensuite un contre-exemple à un assistant, après avoir conservé votre calcul manuel. La proposition échoue si elle modifie un résultat autorisé, une catégorie d'échec ou un ordre requis. Un tableau fini réussi reste un contrôle limité ; les effets, l'annulation, le temps et tous les entiers nécessitent d'autres arguments.

## Cas fixe et calculs attendus

```json
{
  "values": {
    "inputs": [
      -2,
      0,
      2
    ],
    "f": "x+1",
    "g": "2*x",
    "guard": "x>0"
  },
  "formula": "original=g(f(x)); swapped=f(g(x)); validation-before versus validation-after",
  "expected": {
    "original": [
      -2,
      2,
      6
    ],
    "swapped": [
      -3,
      1,
      5
    ],
    "guard_witness": 0,
    "before": "reject",
    "after": "accept"
  },
  "negative_control": "Identity rewrite must agree for every supplied witness.",
  "assumptions": [
    "Exact integer arithmetic, no effects, guard evaluates its stated input."
  ],
  "limits": "A finite witness set can refute equality but agreement is not a universal proof."
}
```

## Conserver une tentative d’apprenant avec ses sources

Travaillez à partir des entrées épinglées ci-dessus. Avant de demander de l’aide, écrivez votre prédiction pour le cas fixe et son contrôle négatif, avec l’unité de chaque quantité et la frontière exacte de comparaison. Un petit tableau sur papier constitue la référence manuelle directe. Gardez les valeurs intermédiaires, surtout celles qui contredisent votre première prédiction. Cette tâche d’explication utilise des sources existantes et des données fixes ; elle ne demande ni installation, ni service payant, ni nouveau programme.

Utilisez ensuite un assistant pour retrouver le passage pertinent et critiquer votre calcul. Conservez la consigne initiale, la réponse, l’emplacement cité et les modifications acceptées ou rejetées. Une citation est utile seulement si le contenu inspecté étaye l’affirmation précise. Une étape déclarée, un type de données et un commentaire n’apportent pas les mêmes preuves qu’un résultat exécuté. Expliquez cette frontière dans votre réponse finale plutôt que d’emprunter l’autorité d’une étiquette rassurante.

Remettez ensemble référence manuelle, résultat corrigé, résultat du contrôle, critère de réfutation et historique d’aide. Les critères préparés demandent si la portée est identifiée, le calcul correct, le contre-exemple conservé, l’explication étayée et la conclusion limitée à ses preuves. Ils restent indécidés sans réponse réelle d’un apprenant. Les corrigés ci-dessous sont préparés : ils ne prouvent aucun apprentissage. L’évaluateur doit garder un critère échoué et sa cause avant la correction, puis juger séparément la tentative révisée. Les preuves d’exécution et de publication, recueillies ultérieurement, exigent leurs propres relevés liés à la version.

### Exercice 1

Calculez le vecteur initial.

<details>
<summary>Réponse 1</summary>

`[-2,2,6]` avec `2*(x+1)`.

</details>

### Exercice 2

Calculez le vecteur après permutation.

<details>
<summary>Réponse 2</summary>

`[-3,1,5]` avec `2*x+1` ; la réécriture est réfutée.

</details>

### Exercice 3

Appliquez la condition au témoin frontière.

<details>
<summary>Réponse 3</summary>

Pour `x=0`, valider avant l’incrément rejette ; après, cela accepte `1`.

</details>

### Exercice 4

Que doit indiquer le contrôle identique ?

<details>
<summary>Réponse 4</summary>

Des résultats égaux pour chaque entrée ; une différence invalide le contrôle.

</details>

### Exercice 5

L’accord sur ces entrées prouve-t-il une loi ?

<details>
<summary>Réponse 5</summary>

Non. Un contre-exemple réfute une affirmation universelle ; un accord fini ne la prouve pas.

</details>

[Dossier de preuves fixes](../../../../code/streeling/evidence/batch50-2026-10-23/unit-b.json) · [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
