---
title: Journal
description: Preuves détaillées du laboratoire de dogfooding, y compris sa propre méthode, ses matrices et ses décisions de promotion.
sidebar:
  order: 99
---

## Progression

- [x] Registre machine-readable et renderer déterministe
- [x] Cinq matrices générées
- [x] Invariants de promotion et test de sortie périmée
- [x] Premières opportunities classiques et agentiques
- [x] Méthode du cours traitée comme opportunity
- [x] Checks CI de parité des langues et de structure du journal
- [ ] Première revue contradictoire indépendante
- [ ] Premier candidat promu ou rejeté sur preuve de dépôt

## Expériences

| Question | Hypothèse avant mesure | Résultat mesuré | Verdict | Preuve |
|---|---|---|---|---|
| Un registre peut-il générer plusieurs vues sans laisser un score accorder l'autorité? | Renderer déterministe et invariants séparent priorité et promotion | 4 opportunities, 5 matrices, 6/6 tests en 0,002 s; score sans effet sur statut ni autorité | confirmé pour le tracer local | [entrée](#2026-09-20--premier-tracer-de-matrices), [`code/repository-dogfooding-lab`](https://github.com/spareilleux/learn/tree/main/code/repository-dogfooding-lab) |
| Jev peut-il réduire de 50 % le coût aval à qualité égale? | Un gate typé résout assez de cas sans faux support | Plan hors ligne : 12 cas, 13 appels, zéro retry, plafond 0,0021 $; aucun résultat live | inconclusif | [benchmark TypeSafe](../../typesafe-ai-system-one/04-token-cost-benchmark/) |
| Les portes nommées « exige des preuves » et « verdict confirmé » refusent-elles un candidat fabriqué? | Elles vérifient la preuve, donc une entrée aux champs vides et à l'artefact inexistant est refusée | Elles n'ont rien refusé : l'entrée a atteint `adopted`/`confirmed` avec zéro erreur. Les portes vérifiaient la présence des clés, jamais leur contenu | réfutée, puis corrigée | [entrée](#2026-09-23--une-relecture-adverse-casse-les-portes-du-labo), [`dogfood.py`](https://github.com/spareilleux/learn/blob/main/code/repository-dogfooding-lab/dogfood.py) |
| Un réseau de Petri trouve-t-il dans un dépôt des défauts de concurrence que sa propre suite de tests manque? | Chercher les marquages morts d'un graphe d'accessibilité trouve au moins un défaut réel, en lecture seule | Trois trouvés dans GA au commit `a826864`, chacun confirmé ligne par ligne avant dépôt, et une affirmation retirée avant dépôt ; signalés en [ga#700](https://github.com/GuitarAlchemist/ga/issues/700), [#701](https://github.com/GuitarAlchemist/ga/issues/701), [#702](https://github.com/GuitarAlchemist/ga/issues/702) | prometteur — aucun mainteneur ne les a encore triées | [`petri-nets`](../../petri-nets/), [entrée](#2026-09-23--une-relecture-adverse-casse-les-portes-du-labo) |

## 2026-09-20 — Premier tracer de matrices

Implémentation de `opportunities.json`, du validateur et du renderer avec la bibliothèque standard Python. Le registre contient Jev, la méthode Learn, un audit de seam hexagonal et une frontière RabbitMQ.

```text
python dogfood.py write
python dogfood.py check
python -m unittest -v
```

Résultat : `validated=4 matrices=current mirrors=current`; 6/6 tests en 0,002 s. Les tests refusent une promotion sans artefacts et une adoption sans verdict confirmé, et vérifient la parité EN/FR/ES ainsi que la structure des journaux. Aucun réseau externe ni mutation de dépôt.

## 2026-09-23 — Une relecture adverse casse les portes du labo

Un autre modèle a relu le schéma et les scores, avec une seule consigne : les casser. Il y est arrivé deux fois, et les deux exploits sont désormais des tests de non-régression dans `test_dogfood.py`.

**Les portes vérifiaient la présence, pas la preuve.** Cette entrée validait sans une seule erreur avant aujourd'hui :

```json
{ "id": "malicious-fabricated-adoption", "status": "adopted", "verdict": "confirmed",
  "artifacts": ["does-not-exist.txt"],
  "baseline": "", "success_metric": "", "falsifier": "", "result": "", "authority": "" }
```

Un candidat sans preuve, sans résultat et avec un artefact absent du disque atteignait `adopted`. Il suffisait que `artifacts` soit une liste non vide et que `verdict` vaille la chaîne `confirmed` ; aucun autre champ n'était contrôlé sur son contenu. Le nom de ces portes promettait une vérification sémantique que le code ne faisait pas — à rebours de la leçon 2, qui demande qu'un lecteur juge une expérience *sans faire confiance à l'auteur*.

**Un rejet pouvait ne rien prouver.** `rejected` était exclu de l'exigence d'artefacts : un candidat pouvait être écarté sans preuve ni résultat — à rebours de la leçon 1, qui conserve les rejets précisément pour que personne ne refasse l'idée.

**Ce qui change.** Tout champ texte doit désormais être non vide ; tout chemin d'artefact doit exister sur le disque, les liens restant pris sur parole ; `rejected` rejoint les états qui exigent une preuve et demande un verdict réfuté ou non concluant ; un candidat promu exige au moins un artefact dans ce dépôt, pas seulement des liens. Les tables de promotion et de résultats sont maintenant triées par état de promotion et non par score : le relecteur n'a trouvé aucun chemin du score vers le statut dans les données, mais une table qui montre toujours le mieux noté en premier exerce la même autorité sur l'attention du lecteur.

L'ancien test nommé « le score ne mute pas l'autorité » affirmait qu'une somme pure ne modifiait pas son argument — vrai par construction, donc preuve de rien. Il contrôle désormais la table de promotion rendue.

Résultat mesuré : `validated=6 matrices=current mirrors=current`, 9/9 tests en 0,004 s. Deux candidats ajoutés : la technique des réseaux de Petri qui a produit [ga#700 à #702](https://github.com/GuitarAlchemist/ga/issues/700), en `incubating`/`promising`, et un recoupement entre les réseaux de Petri de GA et les cinq règles `ga.*` de l'écosystème de grammaires TARS, en `discovered`.

**Une trouvaille de la relecture qui n'est pas corrigée ici.** L'opportunité qui décrit ce cours est la moins falsifiable du registre : son critère de succès est « temps d'écriture pas pire que la référence », et aucune valeur de référence n'est enregistrée nulle part. Un critère dont la référence n'a jamais été mesurée ne peut pas être réfuté. Il reste dans *À vérifier* plutôt que d'être discrètement reformulé.

**Et le candidat ajouté aujourd'hui est passé par les anciennes portes.** Son statut `incubating` a été accordé par un contrôle qui aurait tout aussi bien tamponné l'entrée fabriquée ci-dessus. Ce sur quoi il repose, c'est la vérification ligne par ligne contre la source de GA, pas l'approbation de ce registre — ce qui est l'argument même pour durcir les portes avant de faire confiance à l'une d'elles, y compris la nôtre.

## À vérifier

- Confirmer le premier run CI hébergé des matrices, de la parité et des journaux.
- Mesurer le temps d'écriture avant d'affirmer que la méthode coûte moins cher. Aucune valeur de référence n'existe, donc le critère de succès actuel de `learn-evidence-first-course-method` est irréfutable tel qu'il est écrit.
- Lire le corps des cinq règles TARS `ga.*`, pas seulement leurs poids, avant d'affirmer que les deux encodages s'accordent ou divergent.
- Faire trier ga#700, #701 et #702 par un mainteneur ; l'agent automatique a échoué sur les cinq issues, donc aucune n'a été jugée.
- Exécuter la calibration Jev seulement avec approbation explicite de la dépense.
- Choisir un seam hexagonal exact ou rejeter l'opportunity.

## Questions ouvertes

- Quelles mesures prédisent qu'une découverte survivra à l'intégration?
- Ownership de l'opportunity et autorité de merge doivent-ils toujours être séparés?
- Quand réexaminer un rejet plutôt que le retirer définitivement?
