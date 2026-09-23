---
title: "5. Jev × Pétri : qualifier la preuve, jamais accorder un effet"
description: Un tracer hors ligne et exécutable qui expose le chemin dangereux entre avis et autorité, puis vérifie un modèle protégé.
sidebar:
  order: 5
---

Cette expérience relie deux cours sans placer le modèle sur le chemin de contrôle en production. [Jev](https://docs.typesafe.ai/models) fournit une **classification consultative synthétique** dans notre [labo du confidence gate](../../typesafe-ai-system-one/05-confidence-gate-stress/) ; le [moteur de réseaux de Pétri](../../petri-nets/14-on-our-systems/) énumère ce qu'un contrôle proposé permettrait. Aucun des deux ne vérifie à lui seul une transition réelle de Gaia ou d'IX.

## Question et baseline

Un seuil de confiance peut-il autoriser une implémentation ? Le cas épinglé [`gaia_design_authority`](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/benchmark-corpus.json) attend `contradicted` : un Design Receipt approuvé existe, mais aucun mandat d'implémentation. Le banc de stress synthétique renvoie volontairement `supported` à 0,98. Ce n'est **ni** une réponse de l'API Jev **ni** une erreur mesurée du modèle.

Le réseau non protégé consomme ce jeton consultatif pour produire `effect`. Son plus court témoin est `classify → authorize_from_advisory`. Le réseau protégé dirige l'avis vers une revue, puis `authorize` exige **à la fois** une preuve vérifiée indépendamment et une autorité d'implémentation. Ces jetons sont à usage unique dans ce petit modèle fini ; la politique réelle peut être différente.

```text
choix Jev synthétique ──> avis ──> revue ──> confirmé ───────┐
                           preuve vérifiée indépendamment ───┤ authorize ──> effet
                           mandat d'implémentation ──────────┘
```

Les deux entrées de droite doivent venir de reçus vérifiés indépendamment, jamais de la confiance Jev ou du modèle lui-même. Un marquage de Pétri décrit des hypothèses ; il ne fabrique pas de vrais reçus.

## Exécuter le tracer borné

À la racine du dépôt :

```bash
python -m unittest discover -s code/typesafe-ai-system-one -p 'test_jev_gate_audit.py' -v
python -m unittest discover -s code/repository-dogfooding-lab -p 'test_jev_petri_fixture.py' -v
dotnet test code/petri-nets/Tests -c Release --filter JevEvidenceGateTests
```

La [fixture](https://github.com/spareilleux/learn/blob/main/code/repository-dogfooding-lab/jev-petri-fixture.json) est comparée à la réponse synthétique Python et lue par les [tests C#](https://github.com/spareilleux/learn/blob/main/code/petri-nets/Tests/JevEvidenceGateTests.cs). La [définition des réseaux](https://github.com/spareilleux/learn/blob/main/code/petri-nets/Examples/JevEvidenceGate.cs) réutilise le moteur du cours. Les tests exigent un graphe d'accessibilité complet : l'effet dangereux est atteignable, l'effet protégé ne l'est pas si l'une des deux conditions manque, et un chemin autorisé reste possible quand elles sont toutes deux présentes.

## Ce que l'expérience ne prouve pas

- Le tracer Pétri initial n'a fait aucun appel TypeSafe et n'a mesuré ni tokens facturés ni qualité Jev. Des essais live synthétiques ultérieurs et un contrôle d'un seam Gaia épinglé figurent dans le [journal daté](../journal/) ; ils ne valident pas la transition de production.
- Aucun état de production Gaia ou IX n'a été lu ou modifié. Le texte du cas est une fixture pédagogique épinglée, pas un reçu d'autorité actuel.
- Le réseau protégé vérifie une abstraction finie. Il ne prouve pas que le code réel impose les mêmes gardes, que les reçus sont authentiques, ni que concurrence et retries les préservent.

## Prochain gate de dogfooding

Épingler une vraie transition Gaia ou IX et sa révision. Associer les champs du reçu faisant autorité aux places du réseau ; injecter une preuve manquante ou falsifiée ; rejouer le témoin dangereux sur un seam public. Comparer avec un simple test de garde déterministe. Incuber seulement si le modèle révèle un défaut que ce test manque et si une revue indépendante accepte la correspondance. Sinon, garder le test simple et rejeter ce modèle supplémentaire.

## Exercice

Dans une copie temporaire du réseau protégé, retirez l'arc `implementation_authority → authorize`. Prédisez quel test de jeton manquant échouera, puis lancez les tests C# ciblés. Restaurez ensuite l'arc.

<details>
<summary>Solution</summary>

Avec une preuve vérifiée mais sans mandat d'implémentation, `authorize` devient activable après `confirm`. Le test qui explore `(verified=true, authority=false)` trouve un `effect` atteignable et échoue. C'est un contre-exemple du modèle, pas un défaut constaté dans Gaia.

</details>
