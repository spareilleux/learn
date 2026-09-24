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
- [x] Premier candidat promu ou rejeté sur preuve de dépôt

## Expériences

| Question | Hypothèse avant mesure | Résultat mesuré | Verdict | Preuve |
|---|---|---|---|---|
| Un registre peut-il générer plusieurs vues sans laisser un score accorder l'autorité? | Renderer déterministe et invariants séparent priorité et promotion | 4 opportunities, 5 matrices, 6/6 tests en 0,002 s; score sans effet sur statut ni autorité | confirmé pour le tracer local | [entrée](#2026-09-20--premier-tracer-de-matrices), [`code/repository-dogfooding-lab`](https://github.com/spareilleux/learn/tree/main/code/repository-dogfooding-lab) |
| Jev peut-il réduire de 50 % le coût aval à qualité égale? | Un gate typé résout assez de cas sans faux support | Toujours non mesuré. La calibration de 13 appels a tourné en live le 2026-09-23 et n'a appelé aucun modèle aval, donc elle ne peut pas y répondre | inconclusif | [entrée](#2026-09-23--le-banc-live-mesure-autre-chose-que-sa-question), [`evidence/jev-live.json`](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/evidence/jev-live.json) |
| Grouper 12 questions sur un état partagé réduit-il les tokens d'entrée sans changer une seule réponse? | Le plan hors ligne prédisait 79 % d'octets en moins; si les tokens suivent les octets, le gain dépasse 50 %, la qualité restant non testée | 2487 tokens d'entrée contre 14939, soit 83,4 % de moins, et le choix identique sur les 12 cas : exactitude 0,9167 des deux côtés, zéro faux support, Brier 0,1657 contre 0,1645, 453 ms contre 4451 ms | confirmé pour ce corpus à n=12, une seule exécution | [entrée](#2026-09-23--le-banc-live-mesure-autre-chose-que-sa-question), [benchmark TypeSafe](../../typesafe-ai-system-one/04-token-cost-benchmark/) |
| Les portes nommées « exige des preuves » et « verdict confirmé » refusent-elles un candidat fabriqué? | Elles vérifient la preuve, donc une entrée aux champs vides et à l'artefact inexistant est refusée | Elles n'ont rien refusé : l'entrée a atteint `adopted`/`confirmed` avec zéro erreur. Les portes vérifiaient la présence des clés, jamais leur contenu | réfutée, puis corrigée | [entrée](#2026-09-23--une-relecture-adverse-casse-les-portes-du-labo), [`dogfood.py`](https://github.com/spareilleux/learn/blob/main/code/repository-dogfooding-lab/dogfood.py) |
| Un réseau de Petri trouve-t-il dans un dépôt des défauts de concurrence que sa propre suite de tests manque? | Chercher les marquages morts d'un graphe d'accessibilité trouve au moins un défaut réel, en lecture seule | Trois trouvés dans GA au commit `a826864`, chacun confirmé ligne par ligne avant dépôt, et une affirmation retirée avant dépôt ; signalés en [ga#700](https://github.com/GuitarAlchemist/ga/issues/700), [#701](https://github.com/GuitarAlchemist/ga/issues/701), [#702](https://github.com/GuitarAlchemist/ga/issues/702) | prometteur — aucun mainteneur ne les a encore triées | [`petri-nets`](../../petri-nets/), [entrée](#2026-09-23--une-relecture-adverse-casse-les-portes-du-labo) |
| Un oracle de Pétri hors ligne expose-t-il le saut dangereux entre avis Jev et autorité ? | Le flux fondé sur le seul avis atteint un effet ; le flux protégé exige preuve indépendante et mandat d'implémentation | Faux support synthétique à 0,98 ; 3/3 tests C# ciblés et 1/1 test de parité de la fixture passent ; aucun replay sur un vrai dépôt | prometteur localement, non intégré | [entrée datée](#jev-petri-2026-09-22), [leçon](../05-jev-petri-authority/), [`JevEvidenceGateTests.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/Tests/JevEvidenceGateTests.cs) |

## 2026-09-20 — Premier tracer de matrices

Implémentation de `opportunities.json`, du validateur et du renderer avec la bibliothèque standard Python. Le registre contient Jev, la méthode Learn, un audit de seam hexagonal et une frontière RabbitMQ.

```text
python dogfood.py write
python dogfood.py check
python -m unittest -v
```

Résultat : `validated=4 matrices=current mirrors=current`; 6/6 tests en 0,002 s. Les tests refusent une promotion sans artefacts et une adoption sans verdict confirmé, et vérifient la parité EN/FR/ES ainsi que la structure des journaux. Aucun réseau externe ni mutation de dépôt.

<a id="jev-petri-2026-09-22"></a>

## 2026-09-22 — Frontière d'autorité Jev × Pétri synthétique

Hypothèse posée avant mesure : si une classification Jev très confiante mène directement à un effet, un faux `supported` peut autoriser du travail ; des jetons séparés de preuve vérifiée et de mandat d'implémentation bloquent ce chemin. Baseline : le cas synthétique épinglé `gaia_design_authority` renvoie `supported` à 0,98 alors que l'attendu est `contradicted`.

Le test Python lie la fixture JSON partagée à la réponse synthétique. Le test C# rejoue `classify → authorize_from_advisory` dans le réseau non protégé, puis parcourt complètement le réseau protégé pour les trois combinaisons où manque au moins un jeton indépendant. Un chemin valide reste possible avec les deux jetons. Résultat local : 3/3 tests C# ciblés et 1/1 test de parité passent ; après régénération, `dogfood.py check` annonce `validated=5 matrices=current mirrors=current`. Aucun appel fournisseur, token facturé, effet en production ni replay Gaia/IX sur une révision exacte. Verdict : expérience de spécification prometteuse, pas encore admissible à l'incubation.

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

## 2026-09-23 — Le banc live mesure autre chose que sa question

Les treize appels approuvés sont partis contre `jev-1.13.0`. Ils rendent un résultat net et large, et ce résultat ne répond pas à la question que le registre avait écrite au-dessus.

**Ce qui a été mesuré.** Les mêmes douze cas étiquetés, posés une fois en un seul lot sur un état partagé, puis douze fois un par un sur l'état identique à l'octet près :

| | Tokens d'entrée | Exactitude | Faux supports | Brier | Latence |
|---|---:|---:|---:|---:|---:|
| Lot, 1 appel | 2487 | 0,9167 | 0 | 0,1657 | 453 ms |
| Isolés, 12 appels | 14939 | 0,9167 | 0 | 0,1645 | 4451 ms |

Le groupement coûte **83,4 % de tokens d'entrée en moins**, bien au-delà des 79 % que le plan hors ligne prédisait à partir des octets, et il n'a changé **aucune réponse** : les douze choix concordent cas par cas, pas seulement en agrégat. Zéro retry, zéro faux support des deux côtés, et toute l'exécution est restée sous le plafond proxy de 0,0021 $.

**Ce qui n'a pas été mesuré, alors que l'entrée le laissait croire.** Le `next_gate` du registre disait « exécuter la calibration bornée de 13 appels, puis un A/B aval à modèle fixe seulement si la qualité passe » — écrit comme si réussir la calibration pesait sur l'hypothèse. Ce n'est pas le cas. L'hypothèse dit qu'un gate typé *réduit ce qu'on envoie à un modèle aval coûteux*. Le banc n'appelle jamais de modèle aval ; il appelle Jev treize fois et ne fait varier que l'empaquetage des questions. Amortir un état partagé sur douze questions est un gain réel et utile, et c'est une autre grandeur que celle nommée par le critère de succès.

La ligne Jev reste donc **inconclusive** pour sa propre question, et une seconde ligne enregistre l'affirmation réellement testée. L'opportunity passe en `incubating` sur cette preuve, pas en `adopted` : son `next_gate` est désormais l'A/B aval, nommé comme ce que la calibration ne remplace pas.

**Une erreur, et les deux bras l'ont faite.** `demerzel_immutable` affirme qu'un artefact est adressé par contenu là où la preuve offre un chemin et un horodatage mais aucun digest — l'étiquette attendue est `insufficient`, et le lot comme l'appel isolé ont répondu `contradicted`. L'absence de digest a été lue comme un conflit plutôt que comme un silence. Identique des deux côtés, donc l'empaquetage n'en est pas la cause ; c'est le cas sur douze qui explique le 0,9167.

L'exécution complète, chaque hash de requête et chaque réponse, est commitée dans `code/typesafe-ai-system-one/evidence/jev-live.json`, pour que les chiffres ci-dessus soient recalculables sans faire confiance à cette entrée.

## À vérifier

- Confirmer le premier run CI hébergé des matrices, de la parité et des journaux.
- Mesurer le temps d'écriture avant d'affirmer que la méthode coûte moins cher. Aucune valeur de référence n'existe, donc le critère de succès actuel de `learn-evidence-first-course-method` est irréfutable tel qu'il est écrit.
- Lire le corps des cinq règles TARS `ga.*`, pas seulement leurs poids, avant d'affirmer que les deux encodages s'accordent ou divergent.
- Faire trier ga#700, #701 et #702 par un mainteneur ; l'agent automatique a échoué sur les cinq issues, donc aucune n'a été jugée.
- Exécuter l'A/B aval à modèle fixe avant toute affirmation que Jev réduit le coût aval. La calibration live n'a appelé aucun modèle aval, et n=12 sur un corpus en une exécution ne soutient aucun chiffre général.
- Associer le réseau protégé à un seam public Gaia ou IX sur une révision exacte, rejouer le témoin dangereux et comparer avec un simple test de garde déterministe.
- Choisir un seam hexagonal exact ou rejeter l'opportunity.

## Questions ouvertes

- Quelles mesures prédisent qu'une découverte survivra à l'intégration?
- Ownership de l'opportunity et autorité de merge doivent-ils toujours être séparés?
- Quand réexaminer un rejet plutôt que le retirer définitivement?
