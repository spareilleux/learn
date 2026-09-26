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
- [x] Tests de mutation et de propriétés sur un vrai fichier de GA, pré-inscrits ([leçon 6](../06-mutation-property-testing/))

## Expériences

| Question | Hypothèse avant mesure | Résultat mesuré | Verdict | Preuve |
|---|---|---|---|---|
| Un registre peut-il générer plusieurs vues sans laisser un score accorder l'autorité? | Renderer déterministe et invariants séparent priorité et promotion | 4 opportunities, 5 matrices, 6/6 tests en 0,002 s; score sans effet sur statut ni autorité | confirmé pour le tracer local | [entrée](#2026-09-20--premier-tracer-de-matrices), [`code/repository-dogfooding-lab`](https://github.com/spareilleux/learn/tree/main/code/repository-dogfooding-lab) |
| Jev peut-il réduire de 50 % le coût aval à qualité égale? | Un gate typé résout assez de cas sans faux support | Toujours non mesuré. La calibration de 13 appels a tourné en live le 2026-09-23 et n'a appelé aucun modèle aval, donc elle ne peut pas y répondre | inconclusif | [entrée](#2026-09-23--le-banc-live-mesure-autre-chose-que-sa-question), [`evidence/jev-live.json`](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/evidence/jev-live.json) |
| Grouper 12 questions sur un état partagé réduit-il les tokens d'entrée sans changer une seule réponse? | Le plan hors ligne prédisait 79 % d'octets en moins; si les tokens suivent les octets, le gain dépasse 50 %, la qualité restant non testée | 2487 tokens d'entrée contre 14939, soit 83,4 % de moins, et le choix identique sur les 12 cas : exactitude 0,9167 des deux côtés, zéro faux support, Brier 0,1657 contre 0,1645, 453 ms contre 4451 ms | confirmé pour ce corpus à n=12, une seule exécution | [entrée](#2026-09-23--le-banc-live-mesure-autre-chose-que-sa-question), [benchmark TypeSafe](../../typesafe-ai-system-one/04-token-cost-benchmark/) |
| Les portes nommées « exige des preuves » et « verdict confirmé » refusent-elles un candidat fabriqué? | Elles vérifient la preuve, donc une entrée aux champs vides et à l'artefact inexistant est refusée | Elles n'ont rien refusé : l'entrée a atteint `adopted`/`confirmed` avec zéro erreur. Les portes vérifiaient la présence des clés, jamais leur contenu | réfutée, puis corrigée | [entrée](#2026-09-23--une-relecture-adverse-casse-les-portes-du-labo), [`dogfood.py`](https://github.com/spareilleux/learn/blob/main/code/repository-dogfooding-lab/dogfood.py) |
| Un réseau de Petri trouve-t-il dans un dépôt des défauts de concurrence que sa propre suite de tests manque? | Chercher les marquages morts d'un graphe d'accessibilité trouve au moins un défaut réel, en lecture seule | Trois trouvés dans GA au commit `a826864`, chacun confirmé ligne par ligne avant dépôt, et une affirmation retirée avant dépôt ; signalés en [ga#700](https://github.com/GuitarAlchemist/ga/issues/700), [#701](https://github.com/GuitarAlchemist/ga/issues/701), [#702](https://github.com/GuitarAlchemist/ga/issues/702) | prometteur — aucun mainteneur ne les a encore triées | [`petri-nets`](../../petri-nets/), [entrée](#2026-09-23--une-relecture-adverse-casse-les-portes-du-labo) |
| Un oracle de Pétri hors ligne expose-t-il le saut dangereux entre avis Jev et autorité ? | Le flux fondé sur le seul avis atteint un effet ; le flux protégé exige preuve indépendante et mandat d'implémentation | Faux support synthétique à 0,98 ; 3/3 tests C# ciblés et 1/1 test de parité de la fixture passent ; aucun replay sur un vrai dépôt | prometteur localement, non intégré | [entrée datée](#jev-petri-2026-09-22), [leçon](../05-jev-petri-authority/), [`JevEvidenceGateTests.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/Tests/JevEvidenceGateTests.cs) |
| Jev est-il un annotateur consultatif utilisable pour les six valeurs de Demerzel ? | ≥ 75 % exact sur des cas synthétiques d'accord aveugle, ≤ 1 faux T, ≤ 1 absence lue comme réfutation, dans les deux ordres | Aucun faux T sur 240 appels ; mais absence lue comme réfutation 7/10, puis 4–5/10 avec une règle explicite qui a aussi poussé P vers U 6/10 | inconclusive — `experimenting` | [entrée](#2026-09-25--demerzel-et-jev--la-pré-inscription-attrape-ce-que-le-modèle-cache), [`opportunities.json`](https://github.com/spareilleux/learn/blob/main/code/repository-dogfooding-lab/opportunities.json) |
| Les tests de GA laissent-ils des mutants de `PitchParser.cs` en vie, et une petite suite de propriétés passant par l'API publique en tue-t-elle ? | H1 : des mutants restent Survived ou NoCoverage. H2 : les propriétés en tuent au moins un. H3 : aucune entrée ne lève d'exception sur 10 000 cas | B : 25 Killed, 5 NoCoverage, 0 Survived sur 39 (83,33 %). T avec les propriétés : exactement pareil. P exploratoire, propriétés seules : les mêmes 25. Aucune exception ; le témoin négatif échoue et se rejoue à l'identique | H1 confirmée, H2 réfutée, H3 tient pour une graine | [entrée](#2026-09-26--tests-de-mutation-et-de-propriétés-sur-pitchparser-de-ga), [`test-quality`](https://github.com/spareilleux/learn/tree/main/code/repository-dogfooding-lab/test-quality) |

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

## 2026-09-25 — Demerzel et Jev : la pré-inscription attrape ce que le modèle cache

La huitième opportunité est passée d'une ligne du cours TypeSafe (« Demerzel — trier les preuves sans interpréter la constitution ») à deux exécutions mesurées en une journée. Les chiffres sont dans le [journal TypeSafe](../../typesafe-ai-system-one/journal/#2026-09-25--logique-hexavalente-de-demerzel-avec-jev) ; cette entrée consigne ce qu'a fait la méthode.

- **La règle a été écrite avant les données, et elle a tenu.** Le modèle paraissait bon en agrégé (41/58, 71 %, zéro faux T) ; sans la limite d'absence pré-enregistrée, cela se lit comme un succès avec réserve. Avec elle, l'exécution est INCONCLUSIVE, parce que la pré-inscription nommait l'échec cherché : l'absence lue comme réfutation. Il était là, à 7/10.
- **Deux annotateurs, pas un.** Les étiquettes de l'auteur ont été contrôlées par un second agent qui ne les voyait pas. Ils divergent sur 2 cas sur 60 (tous deux D contre U, précisément la frontière testée), exclus plutôt qu'arbitrés après coup.
- **La seconde étape a répondu à une autre question que prévu.** Le correctif devait montrer si la faute venait du modèle ou des définitions de Demerzel. Il a montré les deux : la phrase sur les conflits a entièrement corrigé C, et celle sur l'absence a révélé une ambiguïté dans les définitions elles-mêmes, puisque les cas P n'ont pas non plus d'exécution directe.
- **Un test bon marché a fait plus que l'exécution live.** Un test unitaire « une somme d'exactement 0,99 est acceptée » a échoué avant tout appel. C'était le piège de l'erreur flottante qui avait déjà fait tomber un bras IX.

Registre : `jev-demerzel-hexavalent-annotator`, `experimenting`, verdict `inconclusive`. La prochaine gate est une définition U avec une clause complémentaire pour les indices qui penchent, pré-enregistrée à part. Aucun fichier de Demerzel n'a été modifié : une phrase proposée pour `logic/hexavalent-logic.md` doit d'abord être testée sur de vrais fichiers de croyances.

## 2026-09-25 — Suivre une opportunité d'un dépôt à l'autre jusqu'à ce que chacun réponde

La consigne de l'utilisateur était de s'assurer que l'opportunité soit implémentée, vérifiée et journalisée partout où elle s'appliquait. Interroger les sessions propriétaires a donné plus de réponses que la lecture de leur code ne l'aurait fait :

| Dépôt | Question | Réponse, et qui a vérifié | Résultat |
|---|---|---|---|
| Demerzel | Un changement de définition corrige-t-il l'absence lue comme réfutation ? | Cette session : trois étapes pré-enregistrées plus 8 croyances réelles, 376 appels, environ 0,009 $ calculés | Non. La règle entre dans Demerzel sous la forme d'une répartition des rôles ([PR Demerzel](https://github.com/GuitarAlchemist/Demerzel/pull/1127), corrigée par [#1128](https://github.com/GuitarAlchemist/Demerzel/pull/1128)) |
| Gaia | Un verdict de modèle sur des preuves décide-t-il d'une route ? | La session Gaia, sur main `8ed4dfc` | Non ; l'invariant tient déjà, et la règle pour les étapes futures est déposée en [gaia#159](https://github.com/GuitarAlchemist/gaia/issues/159) |
| IX | Jev touche-t-il des valeurs hexavalentes, et le piège du 0,99 est-il actif ? | La session IX, par grep sur `crates/` | Non, et non : la tolérance est de 1e-3 |

La leçon de méthode : une opportunité n'est pas « adoptée » parce qu'un dépôt l'a mesurée. Ici, le résultat honnête est une règle écrite (Demerzel), une garde déposée pour une étape qui n'existe pas encore (Gaia) et une non-utilisation explicite (IX). L'entrée du registre reste `experimenting`/`inconclusive` : la règle obtenue est une frontière qui tient le modèle à l'écart, pas une adoption du modèle.

## 2026-09-26 — Tests de mutation et de propriétés sur `PitchParser` de GA

La question : les tests déterministes de GA laissent-ils des fautes non détectées dans un petit parseur réel, et un petit test génératif passant par l'API publique en détecte-t-il ? La jointure a été confirmée par l'utilisateur : `PitchParser.TryParse` seulement, via `Pitch.Sharp.TryParse` et `Pitch.Flat.TryParse`, sans modification de production.

Pré-inscription : [`results/preregistration.md`](https://github.com/spareilleux/learn/blob/main/code/repository-dogfooding-lab/test-quality/results/preregistration.md), écrite et hachée à 12 h 19 EDT avant la première compilation (SHA-256 `fd86962a…`, conservé hors du dépôt). Trois modifications ultérieures sont listées dans sa propre section :
- un bogue de générateur attrapé avant toute exécution (préfixer `b` donne `bb3`, un bémol valide) ;
- le `[Property]` de FsCheck.NUnit 3.4.0 ignore le `[Explicit]` de NUnit, ce qui a fait tourner le témoin négatif avec les autres ; il vit désormais dans une catégorie ;
- l'exécution P, déclarée exploratoire avant son lancement.

GA à `aa22f91`, extraction partielle de 12 Mo. SDK .NET 10.0.112, Stryker.NET 5.0.0, FsCheck 3.4.0, Windows 11. Chaque exécution ne mutait que `PitchParser.cs`, en concurrence 2, sous le verrou lourd partagé.

| Exécution | Killed | Survived | NoCoverage | Ignored | Timeout | Score | Durée |
|---|---:|---:|---:|---:|---:|---:|---:|
| Référence déterministe, `dotnet test` | 706/706 réussis | | | | | | 35 s |
| B — tests de GA | 25 | 0 | 5 | 9 | 0 | 83,33 % | 109 s |
| T — tests de GA + 6 tests de propriétés | 25 | 0 | 5 | 9 | 0 | 83,33 % | 142 s |
| P — 6 tests de propriétés seuls (exploratoire) | 25 | 0 | 5 | 9 | 0 | 83,33 % | 93 s |

Les cinq mutants NoCoverage changent `return false` en `return true` dans les branches défensives qui suivent une correspondance réussie de la regex (lignes 38, 43, 49, 58, 67). Aucune entrée décrite par le contrat public ne les atteint. La lecture de `FlatAccidental.TryParse`, qui met en minuscules avant de comparer, suggère que même `CB4` n'atteint pas la ligne 58. Ce n'est pas exécuté.

Propriétés : 10 000 cas chacune avec la graine fixe `(20260926,7)`, et aucun contre-exemple. Témoin négatif (dièses et bémols acceptent les mêmes textes) : `Falsifiable, after 2 tests (2 shrinks)`, réduit à `a#-1`, et une sortie identique sur deux exécutions.

Verdict : H1 confirmée ; H2 réfutée ; H3 tient pour cette graine. La lecture honnête est que les tests de GA tuent déjà tout mutant de ce fichier atteignable depuis l'extérieur. Six propriétés les ont égalés sur ce fichier, ce qui est un constat sur un petit parseur piloté par une regex, pas sur les tests de propriétés en général. Aucune modification de production ni issue chez GA : garder les branches défensives relève du mainteneur.

## À vérifier

- Exécuter le labo test-quality sous Linux et macOS, et le brancher en CI ; il n'a tourné que sous Windows 11, à la main.
- Exécuter `Pitch.Flat.TryParse("CB4")` pour confirmer que la ligne 58 de `PitchParser.cs` est inatteignable ; réconcilier les 710 tests du rapport Stryker de T avec 706 + 6.
- Muter un second fichier de GA, dont le contrat dépend moins d'une regex, avant toute conclusion sur les tests de propriétés à cet endroit.
- Fusionner la règle de répartition des rôles dans Demerzel ([Demerzel#1127](https://github.com/GuitarAlchemist/Demerzel/pull/1127)) ; ne revenir à Jev sur des preuves que si un dépôt construit une étape où un modèle juge des preuves ([gaia#159](https://github.com/GuitarAlchemist/gaia/issues/159)).
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
