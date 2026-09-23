---
title: "Test de résistance du gate de confiance : quand s'abstenir"
description: Rejouer une réponse synthétique volontairement fausse pour mesurer les faux supports, la charge de revue et les limites d'un seuil de confiance.
sidebar:
  order: 5
---

Cette expérience est **hors ligne et synthétique**. Elle teste notre gate, pas la précision de Jev. Deux étiquettes sont volontairement transformées en réponses `supported` erronées, dont une avec une confiance de 0,98. Aucune action sur un dépôt n'est autorisée.

## Question et hypothèse écrite avant la mesure

> Un seuil de confiance peut-il, à lui seul, empêcher un faux `supported` tout en gardant une couverture utile ?

Nous prévoyons que **non** : relever le seuil devrait réduire la couverture, mais une erreur très confiante peut encore passer. La [documentation TypeSafe sur la confiance](https://docs.typesafe.ai/confidence) décrit une sortie du modèle, pas une preuve. Les [limites documentées de Jev 1.13](https://docs.typesafe.ai/model-jaggedness/jev-1.13) mentionnent notamment l'indirection, l'état non pertinent et la prompt injection comme cas à tester séparément.

## Exécuter la fixture de résistance

Depuis `code/typesafe-ai-system-one/` :

```text
python jev_gate_audit.py synthetic
python -W error::ResourceWarning -m unittest -v
```

Mesures locales sur la fixture :

| Seuil | Passeraient un gate `supported` fondé seulement sur la confiance | Faux supports | Envoyés en revue |
|---:|---:|---:|---:|
| 0,50 | 6 | 2 | 6 |
| 0,90 | 5 | 1 | 7 |
| 0,95 | 1 | 1 | 11 |
| 0,99 | 0 | 0 | 12 |

À 0,95, le **seul** élément qui passe est faux. Un seuil échange de la charge de revue contre de la couverture; il n'établit ni la vérité, ni l'autorité de fusionner, déployer ou implémenter. Le script indique toujours `authority_granted: false` et `provider_called: false`.

## Réutiliser un reçu live terminé, sans nouvel appel

Seulement après qu'un benchmark autorisé séparément a produit un reçu local complet :

```text
python jev_gate_audit.py record --input evidence/jev-live.json
```

L'audit refuse les reçus incomplets et les digests de requête incompatibles avec le corpus épinglé. Il n'affiche que des mesures agrégées. Aucun reçu live ni clé ne doit entrer dans Git. Le seuil d'un vrai modèle doit être choisi sur un jeu tenu à l'écart; l'ajuster sur ces 12 étiquettes serait du surapprentissage.

## Exercice

Pour une route sensible au déploiement, un seuil de 0,99 suffit-il pour transformer un `supported` de Jev en permission de déployer ? Expliquez la frontière entre preuve et autorité.

<details>
<summary>Solution</summary>

Non. Cette fixture envoie simplement les 12 cas en revue à 0,99; elle ne prouve rien sur les réponses futures d'un modèle. Le score est un élément de preuve à considérer, tandis qu'un contrôle déterministe et distinct autorise l'effet. Un faux support au-dessus de n'importe quel seuil fixe reste possible.

</details>

## Prochain falsificateur

Un pilote de qualité autorisé séparément devrait comparer la même question sur un état par cas et sur l'état partagé des 12 cas, avec modèle exact, usage réel, faux supports, latence et tranches linguistiques. La comparaison du coût du seul batching doit garder le même état dans les deux bras, comme dans l'[exemple officiel des questions parallèles](https://docs.typesafe.ai/cookbooks/parallel_questions). La [note de recherche](https://github.com/spareilleux/learn/blob/main/docs/research/2026-09-22-jev-experiment-design-primary-sources.md) décrit le protocole entier. Aucun de ces résultats fournisseur n'a encore été mesuré ici.
