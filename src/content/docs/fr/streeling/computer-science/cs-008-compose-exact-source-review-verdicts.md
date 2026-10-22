---
title: Composer des verdicts de révision liés aux sources exactes
description: Composer des verdicts de révision liés aux sources exactes — Informatique
sidebar:
  label: CS-008 · Composer des verdicts de révision liés aux sources exactes
  order: 8
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/computer-science/fr/cs-008-compose-exact-source-review-verdicts.fr.md
---

:::note[Streeling University]
**CS-008** · Composer des verdicts de révision liés aux sources exactes · intermédiaire · 45 minutes

Généré par le département *Informatique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/computer-science/fr/cs-008-compose-exact-source-review-verdicts.fr.md) · [Mon journal](../../journal/)

Prérequis: [CS-005](../../computer-science/cs-005-agent-handoff-evidence-contract/), [CS-007](../../computer-science/cs-007-typed-agent-evidence-and-backpressure/)
:::

> **Périmètre de la source et du transfert.** Le texte technique ci-dessous provient d’un brouillon archivé. Les mentions historiques d’une absence d’importation ou de compilation dans Learn concernent cette étape antérieure ; ce [dossier de transfert](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/agentic-composition-2026-10-22/README.md) décrit l’importation actuelle et ses vérifications. Les autres expériences indiquées comme non réalisées le restent. Les revues humaines du contenu et de la langue, ainsi que l’essai avec un apprenant, restent à effectuer.

> **Département d'informatique** | Niveau intermédiaire | 45 minutes | Brouillon français ; révision du contenu, essai par un apprenant et révision par une personne maîtrisant le français en attente

## Objectifs et question du projet

Vous apprendrez à déduire un statut de révision d'une révision des sources et d'un verdict humain de portée limitée, à déterminer quelles modifications invalident quels verdicts et à distinguer un badge généré d'une autorisation de publication. **Question du projet :** comment Streeling peut-il afficher des preuves de révision utiles pour des centaines de cours sans laisser un verdict périmé ou automatisé passer pour une approbation humaine ? L'exercice utilise un véritable projet de contrat et un véritable générateur Learn testé localement. Aux révisions citées, tous deux étaient des expériences à l'état de brouillon ; aucun n'établit qu'une révision humaine a été achevée ou qu'un déploiement public a eu lieu.

Le besoin est concret. La [fiche de révision d'AUD-001](https://github.com/GuitarAlchemist/Demerzel/blob/2e1766e524e4e7900b380823006a8192cf6aa493/state/streeling/reviews/aud-001-review-brief.md) fixe un cours audio anglais et cinq blobs Git traduits. Elle demande à un spécialiste de vérifier les affirmations DSP et les réponses, à des personnes maîtrisant chaque langue de vérifier les traductions et à un apprenant de tenter une tâche sans réponses fournies. Un contrôle statique préalable est utile, mais n'accomplit aucun de ces travaux humains. L'utilisateur a indiqué qu'il désignerait un réviseur ; cette leçon ne dispose d'aucun résultat de révision à rapporter.

**Périmètre de l'implémentation historique.** L'utilitaire Learn au commit `02fc08c` est une expérience de brouillon archivée, absente de l'arbre actuel des sources Learn. Les PR Demerzel #1211/#1207 et Learn #170 citées ont été fermées sans fusion le 2026-10-21 ; leur code et leurs tests immuables restent des preuves pour cette étude de cas, et non des capacités actuelles du générateur ou des approbations humaines. La rédaction actuelle EN/FR/ES se fait dans Learn `streeling/courses/` ; les pages sont générées à partir de ces sources. Utilisez `git rev-parse <learn-commit>:streeling/courses/<department>/<locale>/<filename>` pour obtenir un blob Learn actuel. Les commandes Demerzel historiques ci-dessous conservent leurs chemins `state/streeling` d'origine. Un validateur de reçus maintenu et ses propres tests d'acceptation seraient nécessaires avant d'adopter l'utilitaire historique dans cette architecture.

## 1. Donner à chaque affirmation ses propres preuves

Le [schéma de reçu Demerzel proposé au commit `5d7c1d1`](https://github.com/GuitarAlchemist/Demerzel/blob/5d7c1d1bd9972fe9d6d2e7a90ab3cdddabb8ed44/schemas/streeling-review-receipt.schema.json) enregistre un `module_id`, une `locale`, un `kind`, un `source_blob`, un `reviewed_commit`, un `reviewer`, un `reviewed_at`, un `verdict` et des `evidence`. Les types autorisés sont `subject`, `language` et `learner` ; les verdicts autorisés sont `approved`, `changes_requested` et `not_assessed`. Un reçu de contenu porte sur le fichier anglais. Un reçu linguistique porte à la fois sur le fichier traduit et sur `source_english_blob`, le texte anglais par rapport auquel la traduction a été vérifiée. Un reçu est une affirmation de portée limitée, pas un certificat pour tout le cours. Le [guide des reçus](https://github.com/GuitarAlchemist/Demerzel/blob/5d7c1d1bd9972fe9d6d2e7a90ab3cdddabb8ed44/state/streeling/review-receipts/README.md) précise explicitement que le répertoire ne contient encore aucun reçu d'approbation.

Git identifie le *contenu* d'un fichier par l'empreinte de son blob. Pour un commit figé `C`, `git rev-parse C:state/streeling/courses/audio-engineering/en/aud-001-eq-compression-order.md` donne le blob anglais à ce commit. `reviewed_commit` est un pointeur d'audit ; `source_blob` indique les octets jugés par le réviseur. La correspondance d'une empreinte n'authentifie pas le réviseur, ne prouve pas que le lien de preuve a été consulté et ne transforme pas un contrôle préalable par IA en révision humaine. Ce sont des contrôles de gouvernance distincts.

Considérons le tableau **synthétique** suivant ; `E1`, `E2`, `F1` et `F2` représentent des empreintes de blobs Git distinctes de 40 caractères, et non les valeurs réelles d'AUD-001.

| Artefact | Blob anglais | Blob français | Reçu |
|---|---|---|---|
| Révision A des sources | `E1` | `F1` | aucun |
| Révision du contenu anglais | `E1` | — | `approved` |
| Révision linguistique française | `E1` | `F1` | `approved` |
| Tâche de l'apprenant en français | — | `F1` | `not_assessed` |

La page française à la révision A dispose d'un reçu d'approbation du contenu anglais correspondant et d'un reçu d'approbation linguistique française correspondant. Le résultat de l'apprenant est **non évalué**. Il s'agit toujours d'une fixture pédagogique : le véritable schéma exige des valeurs hexadécimales SHA-1 réelles et des métadonnées de révision. Une structure JSON valide ne prouverait pas à elle seule qu'une véritable personne a approuvé ces affirmations.

### Exercice pratique 1

Peut-on réduire les deux enregistrements `approved` du tableau à un seul indicateur `course_approved: true` ? Donnez un échec concret qu'un tel indicateur masquerait.

> **Réponse :** Non. Le reçu de contenu couvre le contenu anglais ; le reçu linguistique couvre son rendu français par rapport à cet anglais. Un indicateur unique masquerait le fait que la tâche de l'apprenant reste `not_assessed`, et pourrait rester vrai après une modification du seul texte français. Il ne peut pas non plus authentifier un réviseur. Gardez les affirmations distinctes et liez chacune aux octets de ses sources.

## 2. Composer les prédicats, puis conserver le verdict

L'[utilitaire de révision Learn au commit `02fc08c`](https://github.com/spareilleux/learn/blob/02fc08c8f73e017412d1a623415ac4ab08645eb0/scripts/streeling-review-status.mjs) lit les identifiants des blobs des cours avec `git ls-tree` au commit des sources importées. Son critère central est simple : le `source_blob` du reçu doit être égal au blob du fichier concerné et, pour un reçu linguistique, `source_english_blob` doit aussi être égal au blob anglais actuel. Pour un reçu correspondant, il vérifie également que `reviewed_commit` contient les blobs de fichiers déclarés aux chemins nommés. Il renvoie le *reçu correspondant*, pas un booléen. Un reçu `changes_requested` peut donc être affiché sans être compté comme approbation. Un ancien reçu qui ne correspond plus produit un affichage en attente pour cette affirmation. Les [tests de synchronisation Learn au même commit](https://github.com/spareilleux/learn/blob/02fc08c8f73e017412d1a623415ac4ab08645eb0/scripts/tests/sync-streeling.test.mjs) couvrent l'absence de reçu, la correspondance exacte, l'anglais périmé, la traduction périmée, la mauvaise locale, les modifications demandées, le reçu mal formé et le commit contradictoire.

Pour la discussion, écrivons la composition sous forme de prédicats. Cette notation décrit l'utilitaire à l'état de brouillon ; ce n'est pas de la syntaxe IXQL :

```text
match_subject  = receipt.kind == subject
                 && receipt.locale == en
                 && receipt.source_blob == current_english_blob
match_language = receipt.kind == language
                 && receipt.locale == page_locale
                 && receipt.source_blob == current_translation_blob
                 && receipt.source_english_blob == current_english_blob
approved_claim = matching_receipt != null
                 && matching_receipt.verdict == approved
```

Cela rend les dépendances visibles. Un verdict linguistique dépend de deux sources, tandis qu'un verdict sur le contenu anglais n'en dépend que d'une. L'utilitaire valide aussi la structure des champs, le nom du fichier, l'horodatage UTC, les valeurs autorisées et les blobs de fichiers concernés au commit révisé avant de générer les pages. Un reçu correspondant mal formé ou contradictoire fait échouer l'importation au lieu d'être ignoré en silence. Ce contrôle du commit provient de l'utilisation de cette leçon sur elle-même : le premier brouillon ne vérifiait que la syntaxe du commit, permettant à son pointeur d'audit de contredire le blob déclaré. La validation ne peut toujours pas authentifier une personne ; un réviseur du dépôt doit examiner l'identité déclarée et les preuves. Le projet de contrat des reçus est soumis à un contrôle humain distinct parce qu'il touche à `schemas/`.

### Exercice pratique 2

À la révision A, lesquelles des trois affirmations du tableau sont comptées comme approuvées ? Si le reçu de l'apprenant français passe de `not_assessed` à `changes_requested` sans nouvel essai de l'apprenant, le nombre d'approbations augmente-t-il ?

> **Réponse :** Le contenu anglais et la langue française correspondent à leurs blobs et portent `approved` ; l'affirmation concernant l'apprenant correspond, mais reste `not_assessed`. Remplacer son verdict par `changes_requested` n'augmente pas le nombre d'approbations. Cela signalerait un problème d'apprenant non résolu, pas une tâche réussie. Lors d'une véritable révision, modifier l'enregistrement exige aussi une décision réelle du réviseur et des preuves.

## 3. Les révisions n'invalident que les affirmations qu'elles touchent

Supposons que la révision B modifie le cours anglais en `E2` et laisse le fichier français à `F1`. L'ancien reçu de contenu nomme `E1` ; il ne correspond donc plus. Le reçu linguistique français nomme encore `F1`, mais son `source_english_blob` est `E1` ; il ne correspond donc plus non plus. Le reçu de l'apprenant, qui concerne la page française inchangée `F1`, correspond toujours et indique toujours `not_assessed`. Si seul le français passe à `F2` tandis que l'anglais reste `E1`, le reçu de contenu anglais reste applicable ; les reçus français de langue et d'apprenant liés à `F1` ne correspondent plus. C'est un calcul de dépendances, pas une décision déclarant le nouveau texte mauvais. Un réviseur peut examiner le nouveau diff et émettre un nouveau verdict.

Effectuez le calcul avec de vrais octets lors de la révision d'un cours :

```text
git rev-parse <source-commit>:state/streeling/courses/<department>/en/<module-id>.md
git rev-parse <source-commit>:state/streeling/courses/<department>/fr/<module-id>.fr.md
```

Utilisez un *SHA de commit* et le véritable chemin du cours, puis comparez les sorties au reçu. La fiche AUD-001 figée fournit de vrais chemins et identifiants de blobs pour un pilote de portée limitée. N'utilisez pas `E1` et `F1` comme arguments de commande ; ce sont des valeurs fictives. Une modification des sources après révision peut préserver le sens, mais un agent ne peut pas reporter silencieusement l'approbation sur le nouveau blob. Le réviseur humain décide si le diff justifie une nouvelle révision complète ou une extension plus ciblée.

### Exercice pratique 3

À partir de la révision A, calculez les trois statuts affichés après (a) une modification du seul anglais en `E2`, et (b) une modification du seul français en `F2`. Expliquez pourquoi `reviewed_commit` ne suffit à lui seul à aucun des deux calculs.

> **Réponse :** (a) Contenu en attente, langue française en attente, apprenant français `not_assessed` ; le reçu de l'apprenant lié à `F1` inchangé correspond toujours. (b) Contenu anglais approuvé, langue française en attente, apprenant français en attente. Un commit identifie un arbre, pas les octets de fichier couverts par un verdict précis. Les identifiants de blobs concernés et, pour une traduction, la dépendance envers l'anglais déterminent l'applicabilité. L'utilitaire Learn fait correspondre ces blobs ; il ne considère pas tout commit plus récent comme automatiquement approuvé.

## 4. Garder la publication comme effet distinct

Le [brouillon de l'implémentation de synchronisation Learn](https://github.com/spareilleux/learn/blob/02fc08c8f73e017412d1a623415ac4ab08645eb0/scripts/sync-streeling.mjs) affiche séparément les statuts de contenu, de langue et d'apprenant sur les pages générées, et ne compte dans les vues d'ensemble que les reçus `approved` correspondants. Une compilation locale du commit précédent a généré 1,603 pages et affiché une révision en attente pour AUD-001 en anglais, français et espagnol ; les tests de synchronisation ciblés du commit suivant ont réussi après l'ajout de la protection sur le commit révisé. Ces vérifications ne prouvent ni qu'un humain a révisé AUD-001, ni que chaque cours traduit a été vérifié, ni que le site public sert cette compilation.

Traitez la publication comme une transition distincte avec ses propres contrôles : preuves humaines approuvées pour les affirmations visées, sources révisées et fusionnées, site généré depuis le commit choisi, déploiement, puis relecture anonyme de la page visée et de la révision des sources. Si un de ces contrôles manque, gardez à faux l'indicateur `review.completed` ou `publish.completed` du cours, selon le cas. Un badge déduit d'un reçu est une vue sur les preuves, pas une autorisation de fusionner ou déployer. Cette séparation est utile à un workflow agentique, car elle donne à chaque agent une petite fonction vérifiable : examiner une source, enregistrer un verdict, calculer son applicabilité, afficher un statut et vérifier la sortie publique. Elle fournit aussi une raison de retenir une étape de publication en aval lorsqu'une affirmation en amont n'est pas résolue. Cette dernière politique reste une proposition de conception tant qu'un pipeline testé ne l'impose pas.

### Exercice pratique 4

Une page française générée indique « traduction approuvée » à partir d'un reçu correspondant, mais la révision du contenu anglais est en attente. Un agent peut-il marquer l'ensemble du cours comme révisé et publié ? Quelles preuves manquent ?

> **Réponse :** Non. Le reçu linguistique ne couvre que le rendu français par rapport à sa source anglaise ; il n'approuve pas le contenu anglais audio ou informatique. Il manque le verdict de contenu correspondant. La publication exige aussi une intégration des sources révisée, un déploiement et une relecture anonyme de la révision choisie. Le statut de traduction affiché est exact pour son affirmation limitée, mais ne peut pas autoriser la transition plus large.

### Exercice pratique 5

Un fichier nommé `aud-001.en.subject.json` contient un `source_blob` actuel et `verdict: "approved"`, mais un champ inconnu supplémentaire le rend invalide selon le projet de schéma. Un collègue propose d'ignorer ce fichier et d'afficher tous les badges existants. Que devrait faire le brouillon de synchronisation, et quel test détecterait une sortie partielle accidentelle ?

> **Réponse :** Rejeter l'importation avant d'écrire les pages générées. L'utilitaire Learn rejette les champs inconnus, et son test de synchronisation place un reçu invalide dans une fixture, attend une erreur et vérifie que le fichier de verrouillage précédent est inchangé. Ignorer des preuves mal formées pourrait faire paraître actuelle une sortie périmée ; générer certaines pages avant l'échec pourrait laisser un mélange de révisions. Un test réussi n'établit ce comportement que pour l'implémentation de brouillon testée, pas pour un site public déployé.

## Sources, limites et prochaine vérification

Les sources du projet sont la [fiche de révision limitée AUD-001](https://github.com/GuitarAlchemist/Demerzel/blob/2e1766e524e4e7900b380823006a8192cf6aa493/state/streeling/reviews/aud-001-review-brief.md), le [projet de schéma Demerzel](https://github.com/GuitarAlchemist/Demerzel/blob/5d7c1d1bd9972fe9d6d2e7a90ab3cdddabb8ed44/schemas/streeling-review-receipt.schema.json), le [brouillon de l'utilitaire Learn](https://github.com/spareilleux/learn/blob/02fc08c8f73e017412d1a623415ac4ab08645eb0/scripts/streeling-review-status.mjs) et le [test de fixture Learn](https://github.com/spareilleux/learn/blob/02fc08c8f73e017412d1a623415ac4ab08645eb0/scripts/tests/sync-streeling.test.mjs). L'instantané cite les PR Demerzel #1211, Learn #170 et Demerzel #1207 comme travaux historiques à l'état de brouillon ; toutes trois ont ensuite été fermées sans fusion. Ces références identifient la provenance, pas une implémentation ou une approbation actuelle. La structure du schéma de révision ne peut pas authentifier un humain ; les tests locaux ne peuvent pas établir le déploiement du site. Aucun verdict humain, essai d'apprenant, traduction de ce cours ou relecture publique n'était consigné dans le cycle anglais d'origine. Ce brouillon français attend une révision par une personne maîtrisant le français ; il n'ajoute aucun verdict humain, résultat d'apprenant ou constat de déploiement. La prochaine vérification utile consiste à faire remplir par le spécialiste désigné pour AUD-001 un verdict lié aux sources exactes avec des constats cités, puis à réaliser un essai d'apprenant et une relecture anonyme de la page après une mise en ligne autorisée.
