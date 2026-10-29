---
module_id: cs-007-typed-agent-evidence-and-backpressure
department: computer-science
course: Typer les preuves des agents avant de composer les verdicts
level: intermediate
prerequisites: ["cs-005-agent-handoff-evidence-contract", "cs-006-ixql-pipeline-composition"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
research_cycle: computer-science-2026-10-11-007
version: "0.1.0"
---

# Typer les preuves des agents avant de composer les verdicts

> **Périmètre de la source et du transfert.** Le texte technique ci-dessous provient d’un brouillon archivé. Les mentions historiques d’une absence d’importation ou de compilation dans Learn concernent cette étape antérieure ; ce [dossier de transfert](../../../../code/streeling/evidence/agentic-composition-2026-10-22/README.md) décrit l’importation actuelle et ses vérifications. Les autres expériences indiquées comme non réalisées le restent. Les revues humaines du contenu et de la langue, ainsi que l’essai avec un apprenant, restent à effectuer.

> **Département d'informatique** | Niveau intermédiaire | 40 minutes | Brouillon français ; révision du contenu, essai par un apprenant et révision par une personne maîtrisant le français en attente

## Objectifs et question du projet

Vous apprendrez à distinguer un enregistrement conforme à un schéma d'une preuve qui étaye sa conclusion, à transmettre un échec entre agents sans le transformer en réussite, et à évaluer une règle proposée pour différer le travail en aval lorsque les preuves requises manquent. **Question du projet :** avant qu'un agent QA de Demerzel rédige ou transmette un verdict, que doivent fournir ses nœuds en amont pour que le prochain agent distingue une véritable vérification d'un élément provisoire ? Cette leçon utilise un pipeline Phase 0 figé à une révision précise. Son enveloppe typée et sa règle de contre-pression sémantique sont des *propositions pédagogiques*, et non des fonctions vérifiées dans l'exécuteur IXQL.

## 1. Examiner la déclaration et le contrat

Au [commit Demerzel `c3bf622`](https://github.com/GuitarAlchemist/Demerzel/tree/c3bf6224386374fc0f74cfb36643e543b4bdcce2), [`pipelines/qa-architect-cycle.ixql`](https://github.com/GuitarAlchemist/Demerzel/blob/c3bf6224386374fc0f74cfb36643e543b4bdcce2/pipelines/qa-architect-cycle.ixql#L1-L15) se présente comme un **squelette Phase 0**. Ses commentaires excluent explicitement l'analyseur réel du périmètre d'impact, le tribunal de réviseurs, les commentaires de PR ou tickets de suivi, et le signal algédonique dérivé. Il lit le chemin d'un déclencheur avec une cible de repli, fournit un périmètre d'impact vide et utilise une chaîne d'un seul réviseur dont la note précise qu'il n'y a pas d'agrégation de tribunal ([lignes 23–55](https://github.com/GuitarAlchemist/Demerzel/blob/c3bf6224386374fc0f74cfb36643e543b4bdcce2/pipelines/qa-architect-cycle.ixql#L23-L55)). Le verdict assemblé indique `risk_tier: "P3"`, `verdict: "informational"` et contient `evidence: [{kind: "manual_note", name: "phase0.skeleton", outcome: "n/a", ...}]` ([lignes 66–90](https://github.com/GuitarAlchemist/Demerzel/blob/c3bf6224386374fc0f74cfb36643e543b4bdcce2/pipelines/qa-architect-cycle.ixql#L66-L90)). Il s'agit de déclarations dans les sources. Aucun reçu de cette leçon ne montre que le pipeline a été exécuté ou a écrit un fichier.

Le [JSON Schema du verdict QA inclus dans le dépôt](https://github.com/GuitarAlchemist/Demerzel/blob/c3bf6224386374fc0f74cfb36643e543b4bdcce2/schemas/contracts/qa-verdict.schema.json#L14-L30) exige `target`, `risk_tier`, `verdict`, `blast_radius`, `evidence`, `reviewer_chain` et d'autres champs. Sa règle conditionnelle exige `P3` pour un verdict `informational` ([lignes 147–162](https://github.com/GuitarAlchemist/Demerzel/blob/c3bf6224386374fc0f74cfb36643e543b4bdcce2/schemas/contracts/qa-verdict.schema.json#L147-L162)) ; `reviewer_chain` doit contenir au moins une entrée ([lignes 96–102](https://github.com/GuitarAlchemist/Demerzel/blob/c3bf6224386374fc0f74cfb36643e543b4bdcce2/schemas/contracts/qa-verdict.schema.json#L96-L102)). Un élément de preuve peut être une `manual_note` avec le résultat `n/a` ([lignes 260–297](https://github.com/GuitarAlchemist/Demerzel/blob/c3bf6224386374fc0f74cfb36643e543b4bdcce2/schemas/contracts/qa-verdict.schema.json#L260-L297)). Le schéma autorise donc la *structure* du squelette ; il n'affirme ni que la note prouve une véritable vérification de régression ni que l'unique entrée de réviseur représente un tribunal terminé. `schema_version: 1` est un seul champ, et non le schéma complet.

### Exercice pratique 1

Les sources déclarent `informational/P3`, un réviseur d'architecture avec `score: null` et une `manual_note/n/a`. Parmi les affirmations suivantes, lesquelles une vérification de schéma peut-elle étayer : (a) le verdict utilise une combinaison de catégories autorisée, (b) un test de régression a réussi, (c) un tribunal de plusieurs réviseurs a été exécuté ? Expliquez.

> **Réponse :** Seule (a) découle de la règle conditionnelle citée, à condition que l'objet complet passe la validation. Le schéma autorise `manual_note/n/a` et une chaîne d'un seul réviseur ; la structure n'établit donc ni la réussite d'un test ni la tenue d'un tribunal. Le pipeline qualifie explicitement le résultat du périmètre d'impact et la chaîne de réviseurs d'éléments provisoires Phase 0. Même (a) reste une attente déduite des sources tant qu'un validateur n'a pas vérifié un objet effectivement émis.

## 2. Placer un type à chaque frontière entre agents

Pour discuter de la conception, attribuez à un nœud un type de résultat tel que `Result<Output, Error>` et faites accompagner sa sortie de preuves. La notation **proposée** suivante n'est ni de la syntaxe IXQL ni une affirmation concernant son exécution :

```text
TriggerRead = Ok { target, source_path, source_revision }
            | Err { code, source_path, observed_at }
BlastCheck  = Ok { target_revision, result, evidence_receipt }
            | Err { code, target_revision, attempted_check }
VerdictDraft = { target, category, evidence_items, reviewer_receipts, provenance }
```

Le producteur répond de l'affirmation concernant ce qu'il a tenté. Le destinataire vérifie que la révision cible du résultat correspond à celle qu'il entend juger. Un reçu devrait identifier la vérification, la révision d'entrée, le résultat et l'emplacement d'un artefact consultable. Une valeur de schéma telle que `kind: "test_run"` est une étiquette ; le JSON Schema n'authentifie pas un journal de test. Si un nœud n'a aucun résultat, utilisez `Err` ou `Unknown` avec une raison au lieu d'inventer `Ok {result: []}`. Un résultat vide et réussi signifie « la vérification a été exécutée et n'a rien trouvé » ; une vérification indisponible signifie « nous ne savons pas ».

`VerdictDraft` est un type pédagogique interne, pas le format d'échange du verdict QA. Il omet des champs requis par le schéma et utilise d'autres noms de champs. Un compositeur proposé doit le convertir et le compléter en un `QaVerdict` comportant tous les champs d'échange requis avant d'appliquer le JSON Schema figé ; copier directement le brouillon dans un validateur échouerait.

Le pipeline figé contient `trigger_context <- ix.io.read(...) → default({...})`. La grammaire et ces sources ne précisent pas si `default` ne s'applique qu'à un fichier absent, à un JSON mal formé ou à tout échec de lecture. Un **contrat proposé** plus sûr distinguerait `Missing` de `Malformed` et `PermissionDenied` : seul un balayage synthétique explicitement autorisé pourrait convertir `Missing` en repli documenté ; les autres cas entraîneraient un arrêt ou une demande de réparation. Il s'agit d'un choix de conception à tester, pas d'une description du comportement IXQL observé. Le repli nécessite aussi un indicateur de provenance pour qu'un nœud en aval ne confonde jamais sa cible synthétique avec un véritable déclencheur de PR.

### Exercice pratique 2

Un nœud de déclenchement proposé renvoie `Err {code: "PermissionDenied", source_path: "state/qa-architect/trigger.json"}`. Un collègue le remplace par la cible de repli et étiquette celle-ci « lue dans le fichier du déclencheur ». Quelles sont ses deux erreurs, et quelle sortie le prochain nœud devrait-il recevoir selon le contrat proposé ?

> **Réponse :** Il a transformé un refus d'accès en réussite et attribué une cible synthétique à un fichier qui n'a pas été lu. Selon le contrat proposé, le prochain nœud reçoit `Err(PermissionDenied)` avec le chemin tenté et aucune cible de déclencheur fiable ; le calcul QA s'arrête ou demande une correction des permissions. La seule ligne IXQL présente dans le dépôt n'établit pas que son véritable `default` se comporte ainsi.

## 3. Propager l'échec avant un effet irréversible

Les sources Phase 0 déclarent `ix.io.write(verdict_path, verdict) → tars.validate(check: "verdict.schema_version == 1", ...)` ([lignes 93–102](https://github.com/GuitarAlchemist/Demerzel/blob/c3bf6224386374fc0f74cfb36643e543b4bdcce2/pipelines/qa-architect-cycle.ixql#L93-L102)). Dans l'ordre écrit, l'écriture précède la vérification d'un seul champ. Le message de rejet dit refuser de persister une incompatibilité de schéma, mais la vérification affichée ne peut pas établir une conformité complète au JSON Schema, et les sources ne fournissent aucun reçu d'annulation. Nous ne pouvons pas déduire qu'un fichier invalide a réellement été persisté, car cette leçon n'a pas exécuté le pipeline. Nous *pouvons* dire que la déclaration seule ne suffit pas à prouver un contrôle préalable à l'écriture.

Une composition proposée convertirait d'abord `VerdictDraft` en un `QaVerdict` complet conforme à la structure du schéma, validerait cet objet d'échange contre le schéma figé, vérifierait le reçu de preuve exigé par l'affirmation visée, autoriserait l'écriture, puis examinerait son résultat. Chaque étape renvoie `Ok` ou `Err`. La politique de preuve est distincte de la validation JSON Schema : un élément informatif provisoire Phase 0 peut être valide et utile, mais doit rester étiqueté comme tel. Dans cette conception proposée, un échec de conversion, de validation ou d'examen des preuves n'autorise aucune écriture. Un échec d'écriture produit un reçu d'erreur, pas un verdict accepté. Il faut implémenter et tester cette conception avant d'affirmer que le pipeline l'impose.

### Exercice pratique 3

Prenez un **verdict synthétique au format d'échange** identique au verdict Phase 0 sauf pour `schema_version: 2`. Si le `tars.validate` des sources rejette cette version, ce rejet peut-il prouver qu'aucune écriture n'a eu lieu ? Donnez le résultat attendu de la conception proposée qui valide avant d'écrire.

> **Réponse :** Non. Les sources placent `ix.io.write` avant la vérification de `schema_version`, et aucune annulation n'a été observée ; un rejet ultérieur ne suffit donc pas à établir l'absence d'écriture. Dans la conception proposée, après conversion en objet d'échange complet, la validation complète du schéma rejette `schema_version: 2`, car le schéma exige la constante entière `1` ; le résultat est `Err(SchemaMismatch)`, et l'étape d'écriture n'est pas appelée. Un test devrait enregistrer la trace des appels et vérifier l'état des fichiers pour confirmer ce comportement dans une implémentation.

### Exercice pratique 4

Un véritable appel à un réviseur expire, mais un compositeur insère l'entrée Phase 0 de `reviewer_chain` et annonce « tribunal terminé ». Le JSON contient toujours un réviseur et satisfait donc `minItems: 1`. Quel devrait être le résultat typé, et quelle vérification distingue ce cas d'un squelette informatif valide ?

> **Réponse :** L'étape de révision devrait renvoyer `Err(Timeout)` ou un résultat explicitement non résolu indiquant le rôle tenté et la révision cible. Le compositeur ne doit pas promouvoir l'élément provisoire au rang de tribunal terminé. Une vérification de preuve propre à l'affirmation demande les reçus des rôles de réviseurs requis et leurs résultats ; le `minItems: 1` du schéma ne vérifie que la structure du tableau. Un squelette informatif Phase 0 peut rester clairement identifié comme squelette, tandis qu'une affirmation de tribunal terminé exige des preuves d'exécution distinctes.

## 4. La contre-pression sémantique est une hypothèse

La **contre-pression** ralentit habituellement un producteur lorsqu'un consommateur en aval manque de capacité. Une version *sémantique* proposée ralentirait un producteur de verdicts lorsque le consommateur ne peut pas interpréter ou vérifier ses preuves. L'idée est réfutable : exiger une identité de source typée, un reçu de vérification terminée et un reçu de réviseur avant d'inscrire un élément dans une file « prêt pour une décision opérationnelle ». Sinon, le conserver dans une file non résolue avec une raison. Cette règle en trois parties est une **politique pédagogique synthétique**, pas une règle Demerzel ni une fonction IXQL. Elle ne remplace aucune politique existante d'autorité, de révision ou de fusion. La fixture ci-dessous porte sur des décisions liées à un commit ; un balayage planifié avec `sha: null` aurait besoin d'une autre identité cible stable, par exemple une révision nommée d'instantané, plutôt que d'un SHA de commit inventé.

Considérons une fixture fixe avec deux places disponibles en aval et trois lots candidats. `A` contient `sha: null`, `manual_note/n/a` et l'entrée d'architecture du squelette. `B` contient un SHA cible figé, un reçu `test_run/pass` vérifiable et un reçu de réviseur pour ce même SHA. `C` contient un SHA figé et un reçu de test, mais son appel au réviseur a expiré. Selon la règle proposée en trois parties, seul `B` entre dans la file des éléments prêts. `A` et `C` restent non résolus et une place reste libre. Cette place inutilisée est délibérée : la capacité seule n'est pas une preuve. `B` n'est prêt que pour la *décision opérationnelle précise définie par la politique* ; la fixture n'autorise aucune fusion et ne prétend pas qu'un véritable test GA a réussi.

L'hypothèse prédit moins de classements « prêt » sans fondement et peut-être une attente plus longue. Testez-la sur des transmissions historiques étiquetées ou dans une simulation contrôlée : comptez les décisions faussement prêtes, l'ancienneté des éléments non résolus et les corrections manuelles avec et sans la règle. Un bon résultat réduirait les décisions faussement prêtes sans attente indéfinie inacceptable. Un critère de réfutation serait un classement faussement prêt inchangé ou aggravé, ou du travail non résolu qui ne bénéficie jamais d'une voie de réparation. Cette leçon n'a recueilli aucune mesure de ce type.

### Exercice pratique 5

Appliquez la règle proposée à `A`, `B` et `C`. Combien des deux places sont occupées, combien de lots attendent, et quel événement supplémentaire pourrait rendre `C` admissible ? L'exercice démontre-t-il que Demerzel applique actuellement une contre-pression sémantique ?

> **Réponse :** Une place est occupée par `B` ; deux lots (`A` et `C`) attendent ; une place reste libre. Une nouvelle tentative réussie du réviseur, accompagnée d'un reçu lié au SHA cible figé de `C`, pourrait satisfaire ses trois exigences. La fixture ne vérifie que l'arithmétique et le classement de la règle proposée. Elle n'apporte aucune preuve que Demerzel implémente actuellement une contre-pression sémantique ou en tire profit.

## Sources, limites et prochaine vérification

Les preuves du projet sont le [fichier IXQL Phase 0 figé](https://github.com/GuitarAlchemist/Demerzel/blob/c3bf6224386374fc0f74cfb36643e543b4bdcce2/pipelines/qa-architect-cycle.ixql), le [schéma de verdict inclus dans le dépôt](https://github.com/GuitarAlchemist/Demerzel/blob/c3bf6224386374fc0f74cfb36643e543b4bdcce2/schemas/contracts/qa-verdict.schema.json) et le [validateur structurel minimal](https://github.com/GuitarAlchemist/Demerzel/blob/c3bf6224386374fc0f74cfb36643e543b4bdcce2/scripts/ixql-validate.js#L1-L4). Les métadonnées du schéma désignent GA comme source canonique à un autre SHA ([lignes 6–12](https://github.com/GuitarAlchemist/Demerzel/blob/c3bf6224386374fc0f74cfb36643e543b4bdcce2/schemas/contracts/qa-verdict.schema.json#L6-L12)). Le commentaire IXQL nomme `docs/contracts/qa-verdict.schema.json`, tandis que le fichier inclus dans ce checkout se trouve à `schemas/contracts/qa-verdict.schema.json` ; cette différence de chemin est un problème de documentation des sources, pas la preuve qu'une exécution a échoué. Le validateur structurel n'est ni un analyseur complet ni un exécuteur. Aucune émission de verdict, vérification de schéma sur les octets émis, trace d'écriture, invocation de réviseur ou mesure de contre-pression n'a été exécutée pour cette leçon. La prochaine vérification est un test isolé d'implémentation avec un brouillon invalide et un appel de réviseur refusé, enregistrant la trace des appels d'écriture et l'état des artefacts. Dans le cycle anglais d'origine, la révision humaine du contenu, l'essai par un apprenant, la traduction et la publication restaient ouverts. Ce brouillon français attend encore la révision du contenu, un essai par un apprenant, une révision par une personne maîtrisant le français et la révision avant publication.
