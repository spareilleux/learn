---
title: Éviter l’accumulation intégrale en saturation
description: Éviter l’accumulation intégrale en saturation — Cybernétique
sidebar:
  label: CYB-011 · Éviter l’accumulation intégrale en saturation
  order: 11
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/cybernetics/fr/cyb-011-prevent-integral-accumulation-under-saturation.fr.md
---

:::note[Streeling University]
**CYB-011** · Éviter l’accumulation intégrale en saturation · intermédiaire · 45 minutes

Généré par le département *Cybernétique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/cybernetics/fr/cyb-011-prevent-integral-accumulation-under-saturation.fr.md) · [Mon journal](../../journal/)

Prérequis: [CYB-008](../../cybernetics/cyb-008-check-convergence-before-repeating-a-correction/)
:::

> **Portée du brouillon.** Modèles fixes construits à partir de sources inspectées. Les décisions humaines techniques, linguistiques et d’apprentissage restent en attente. Aucun résultat de flotte active, contrôleur de production, télémétrie utilisateur ou progrès d’apprentissage n’est revendiqué. Le journal distingue tests réellement exécutés, lectures et contrôles prévus.

## Sources à examiner

- [cyb-008-check-convergence-before-repeating-a-correction.md](../../cybernetics/cyb-008-check-convergence-before-repeating-a-correction/)
- [anti-windup-control-using-a-pid-controller.html](https://www.mathworks.com/help/simulink/slref/anti-windup-control-using-a-pid-controller.html)

Un contrôleur d'agent proposé accumule l'erreur alors que l'action demandée est plafonnée. Lorsque l'erreur change de signe, sa demande mémorisée peut encore pointer fortement dans l'ancienne direction. Le prérequis sur la convergence ne contient aucune saturation. Ce cours ajoute une limite explicite et compare l'état intégral stocké à la commande appliquée. Aucune suite n'est une trace mesurée d'un contrôleur GA.

La documentation primaire distingue la limitation de sortie des mécanismes qui agissent sur l'intégrateur interne. Lisez sa discussion de l'intégration conditionnelle. Notre règle construite est volontairement plus stricte qu'un contrôleur réglé en pratique : rejeter tout l'incrément si son candidat dépasse une limite et si l'erreur pousse davantage vers l'extérieur. Ce choix facilite l'audit et rend son coût visible. Il ne reproduit pas exactement l'implémentation du produit.

La version naïve mémorise chaque candidat et borne seulement la commande appliquée. Le plafond empêche cette commande de dépasser la plage fixée, mais l'état interne continue à croître. Une erreur négative ultérieure réduit cet état sans nécessairement changer la sortie saturée. Conserver uniquement la sortie cacherait l'écart entre quantité demandée et quantité appliquée. L'opérateur a besoin des deux pour comprendre le maintien à la limite.

La version conditionnelle rejette les incréments vers l'extérieur et évite donc l'excès stocké dans cet exemple. Son pas grossier laisse toutefois une partie de la plage utilisable inexploitée : le premier candidat dépasse le plafond et la règle le rejette entièrement. Cette limite est conservée, pas dissimulée sous une déclaration de succès. Une autre règle pourrait projeter l'état à la limite, employer un retour de calcul ou choisir une autre mise à jour ; elle demanderait une nouvelle récurrence explicite.

Pour le travail avec les sources, comparez l'itération sans contrainte du prérequis à la discussion de saturation. Construisez un tableau manuel séparant candidat, état stocké et commande appliquée. Demandez à un assistant de le calculer et d'expliquer l'objection de la plage inutilisée. Rejetez un contrôleur proposé s'il déduit la stabilité du seul plafonnement, remplace discrètement la règle ou présente ces valeurs construites comme des mesures de ressources actives.

## Cas fixe et calculs attendus

```json
{
  "values": {
    "initial_integral": 0,
    "errors": [
      3,
      3,
      3,
      -1
    ],
    "dt_seconds": 1,
    "gain": 1,
    "lower_limit": 0,
    "upper_limit": 2
  },
  "formula": "candidate=I+gain*error*dt; naive stores candidate; conditional stores candidate unless beyond a limit and error drives farther outward; command=clip(I,lower,upper)",
  "expected": {
    "naive_integrals": [
      3,
      6,
      9,
      8
    ],
    "naive_commands": [
      2,
      2,
      2,
      2
    ],
    "conditional_integrals": [
      0,
      0,
      0,
      0
    ],
    "conditional_commands": [
      0,
      0,
      0,
      0
    ]
  },
  "negative_control": "With sufficiently wide limits both rules integrate the same error sequence.",
  "assumptions": [
    "Integral-only teaching controller, no proportional term or plant dynamics, update then output, outward-increment rejection."
  ],
  "limits": "The deliberately strict rule is not a tuned production anti-windup controller and may fail to use available actuator range."
}
```

## Conserver une tentative d’apprenant avec ses sources

Travaillez à partir des entrées épinglées ci-dessus. Avant de demander de l’aide, écrivez votre prédiction pour le cas fixe et son contrôle négatif, avec l’unité de chaque quantité et la frontière exacte de comparaison. Un petit tableau sur papier constitue la référence manuelle directe. Gardez les valeurs intermédiaires, surtout celles qui contredisent votre première prédiction. Cette tâche d’explication utilise des sources existantes et des données fixes ; elle ne demande ni installation, ni service payant, ni nouveau programme.

Utilisez ensuite un assistant pour retrouver le passage pertinent et critiquer votre calcul. Conservez la consigne initiale, la réponse, l’emplacement cité et les modifications acceptées ou rejetées. Une citation est utile seulement si le contenu inspecté étaye l’affirmation précise. Une étape déclarée, un type de données et un commentaire n’apportent pas les mêmes preuves qu’un résultat exécuté. Expliquez cette frontière dans votre réponse finale plutôt que d’emprunter l’autorité d’une étiquette rassurante.

Remettez ensemble référence manuelle, résultat corrigé, résultat du contrôle, critère de réfutation et historique d’aide. Les critères préparés demandent si la portée est identifiée, le calcul correct, le contre-exemple conservé, l’explication étayée et la conclusion limitée à ses preuves. Ils restent indécidés sans réponse réelle d’un apprenant. Les corrigés ci-dessous sont préparés : ils ne prouvent aucun apprentissage. L’évaluateur doit garder un critère échoué et sa cause avant la correction, puis juger séparément la tentative révisée. Les preuves d’exécution et de publication, recueillies ultérieurement, exigent leurs propres relevés liés à la version.

### Exercice 1

Calculez les états et commandes naïfs.

<details>
<summary>Réponse 1</summary>

États `[3,6,9,8]` ; commandes `[2,2,2,2]`.

</details>

### Exercice 2

Calculez les états conditionnels.

<details>
<summary>Réponse 2</summary>

`[0,0,0,0]` ; la règle déclarée rejette chaque incrément proposé vers l’extérieur.

</details>

### Exercice 3

Pourquoi l’erreur inversée laisse-t-elle la sortie naïve au plafond ?

<details>
<summary>Réponse 3</summary>

L’intégrale stockée passe de `9` à `8`, encore au-dessus de la limite `2`.

</details>

### Exercice 4

Indiquez la faiblesse conservée de la règle conditionnelle.

<details>
<summary>Réponse 4</summary>

Rejeter entièrement un incrément excessif laisse une plage utilisable inexploitée.

</details>

### Exercice 5

Évaluez le contrôle à limites larges.

<details>
<summary>Réponse 5</summary>

Si aucun candidat n’atteint une limite, les deux règles stockent la même suite intégrale.

</details>

[Dossier de preuves fixes](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)
