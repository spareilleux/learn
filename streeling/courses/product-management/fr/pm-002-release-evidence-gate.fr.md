---
module_id: pm-002-release-evidence-gate
department: product-management
course: "Une condition de publication fondée sur les preuves pour les cours Streeling"
level: beginner
prerequisites: [pm-001-shipping-vs-talking]
estimated_duration: "30 minutes"
produced_by: codex-project-pilot
research_cycle: product-management-2026-10-11-002
version: "0.1.0"
---

# Une condition de publication fondée sur les preuves pour les cours Streeling

> **Périmètre de la source et du transfert.** Le texte technique ci-dessous provient d’un brouillon archivé. Les mentions historiques d’une absence d’importation ou de compilation dans Learn concernent cette étape antérieure ; ce [dossier de transfert](../../../../code/streeling/evidence/agentic-composition-2026-10-22/README.md) décrit l’importation actuelle et ses vérifications. Les autres expériences indiquées comme non réalisées le restent. Les revues humaines du contenu et de la langue, ainsi que l’essai avec un apprenant, restent à effectuer.

> **Périmètre des sources actuelles.** L'inventaire, la file de révision et les exemples d'importation ci-dessous sont des observations historiques des sources Demerzel et de leur ancien parcours d'importation dans Learn. La rédaction actuelle EN/FR/ES relève de Learn `streeling/courses/`, dont les pages sont générées par `npm run sync:streeling`. PT/IT/DE et les cycles de recherche restent dans Demerzel. Les anciens indicateurs et décomptes de production n'établissent ni la révision, ni le débit, ni la publication des blobs Learn modifiés.

> **Département de gestion de produits et de projets** | Niveau : débutant | Durée estimée : 30 minutes | Statut : brouillon source français ; révision et publication en attente

## Objectifs

Après cette leçon, vous saurez :

- Classer un module Streeling comme rédigé, enregistré, révisé, construit localement ou consultable publiquement, à l'aide de l'artefact qui prouve chaque état.
- Nommer les preuves manquantes avant d'annoncer une publication.
- Rédiger une note de publication donnant au lecteur un chemin reproductible vers la source et la page déployée.

## La question du projet

Un agent rédige une leçon Streeling utile dans Demerzel. Un autre crée un enregistrement de production JSON. Learn génère une page lors d'un build local. L'équipe peut-elle annoncer le cours comme révisé et publié ? **Non.** Ces actions répondent à des questions différentes. Un fichier source prouve qu'un texte a été rédigé ; un enregistrement conforme au schéma prouve que les champs et types requis respectent un schéma ; une page locale prouve qu'une exécution du générateur et du build a produit une sortie. Aucune ne consigne un essai d'apprenant ni ne prouve qu'un lecteur anonyme peut récupérer la leçon déployée.

Cette leçon utilise le **pilote DV-001** daté comme cas fixe. Les pièces justificatives sont figées au commit pilote Demerzel `6bc584d7ca1cd9eb1b1481e1100eeeb74e983863`, sauf le générateur Learn, lu au commit Learn `fe8e38444d882c28691dce9f12c21ac2ad404ec0`. Elles décrivent un travail observé le 11 octobre 2026, pas le site public actuel. [PM-001](pm-001-shipping-vs-talking.md) demande si une affirmation produit est précise et réfutable. Ici, l'élément réfutant l'affirmation est une pièce de publication absente ou en échec.

### Exercice pratique 1 : classer la source

DV-001 possède une leçon Markdown en anglais et cinq exercices corrigés. L'[enregistrement de production](https://github.com/GuitarAlchemist/Demerzel/blob/6bc584d7ca1cd9eb1b1481e1100eeeb74e983863/state/streeling/course-productions/cp-data-visualization-2026-10-04-001.json) indique `review.completed: false` et `publish.completed: false`. Que peut affirmer une note de publication sans dépasser les preuves ?

> **Réponse :** « Un brouillon source anglais DV-001 comportant cinq exercices corrigés existe dans Demerzel. » Elle ne peut pas dire « révisé » ou « publié ». L'examen de la source est nécessaire pour juger son contenu ; les deux indicateurs de phase à faux excluent explicitement ces affirmations ultérieures.

## 1. Une affirmation, un responsable de preuve

Utilisez une fiche de contrôle comportant l'**affirmation**, l'**artefact**, la **révision ou date**, le **résultat** et le **prochain responsable**. Les cinq lignes ci-dessous sont des décisions distinctes, pas des synonymes de « terminé ».

| Affirmation | Preuve minimale pour ce pilote | Ce que la preuve n'établit pas |
|---|---|---|
| Source rédigée | Chemin de leçon Demerzel, ID de module, révision source, exercice corrigé | Exactitude ou utilité pour l'apprenant |
| Enregistrement de production conforme | Fichier JSON validé selon le [schéma `course-production`](https://github.com/GuitarAlchemist/Demerzel/blob/6bc584d7ca1cd9eb1b1481e1100eeeb74e983863/schemas/course-production.schema.json) de Demerzel, avec les ID source/recherche et des indicateurs de phase honnêtes | Que les événements décrits dans l'enregistrement ont eu lieu |
| Révisé | Verdict humain disciplinaire consigné, verdicts de personnes maîtrisant les langues requises et essai d'apprenant avec corrections prises en compte | Une page déployée et accessible |
| Intégration Learn | Sortie de synchronisation liée à un commit source Demerzel, `streeling.lock.json` et build du site réussi avec vérification des routes générées | Déploiement ou accès anonyme |
| Consultation publique | Après déploiement, GET anonyme des routes prévues des leçons et index EN/FR/ES, contenu et provenance corrects | Que le contenu a été approuvé si les preuves de révision sont absentes |

Le [dossier de révision DV-001](https://github.com/GuitarAlchemist/Demerzel/blob/6bc584d7ca1cd9eb1b1481e1100eeeb74e983863/state/streeling/reviews/dv-001-review-brief.md) consigne une vérification disciplinaire indépendante par IA et une comparaison multilingue par IA, mais laisse ouvertes la révision humaine disciplinaire, la révision linguistique et celle par un apprenant. L'indicateur `review.completed: false` de l'enregistrement de production respecte cette limite. Une vérification par IA peut réduire la file sans devenir silencieusement le résultat d'une révision humaine. La [règle du cursus](https://github.com/GuitarAlchemist/Demerzel/blob/6bc584d7ca1cd9eb1b1481e1100eeeb74e983863/docs/specs/streeling-project-curriculum-2026-10-04.md) distingue aussi les décomptes de modules prêts, révisés et publiés.

### Exercice pratique 2 : lire un enregistrement valide

Supposons qu'un validateur JSON accepte l'enregistrement de production DV-001. Un collègue dit : « Le cours a passé la production, donc la révision est terminée. » Quels champs et quelle preuve absente réfutent cette conclusion ?

> **Réponse :** L'acceptation du schéma porte sur la structure de l'enregistrement. Celui-ci indique `status: review_pending`, `review.completed: false` et `publish.completed: false`. Le dossier de révision ne comporte aucun verdict terminé de révision humaine disciplinaire, linguistique ou par un apprenant. La validation ne peut pas transformer ces valeurs fausses en travail accompli.

## 2. Rendre la révision observable

Une révision exige une personne et un résultat, pas un titre de checklist. Pour l'exactitude disciplinaire, demandez à un réviseur de reproduire les affirmations datées et toutes les réponses aux exercices à partir des fichiers source nommés. Pour les traductions, demandez à une personne maîtrisant la langue de vérifier le sens technique et le naturel du texte dans chaque langue requise. Pour la condition concernant l'apprenant, donnez-lui une tâche sans réponses, recueillez sa réponse, évaluez-la ensuite et consignez difficultés et modifications. Le [dossier de révision DV-001](https://github.com/GuitarAlchemist/Demerzel/blob/6bc584d7ca1cd9eb1b1481e1100eeeb74e983863/state/streeling/reviews/dv-001-review-brief.md) décrit ces tests ; le dossier lui-même n'est pas un test réalisé. Sa pièce de vérification disciplinaire par IA n'approuve que la vérification factuelle délimitée en anglais.

### Exercice pratique 3 : distinguer les réviseurs

DV-001 possède six brouillons linguistiques et une comparaison sémantique par IA. Un collègue propose de cocher la case « révisé ». Donnez les preuves minimales manquantes.

> **Réponse :** Consignez la révision humaine disciplinaire des affirmations et réponses anglaises, la révision et le verdict d'une personne maîtrisant chaque langue requise, ainsi qu'un essai observé d'apprenant utilisant la tâche sans réponses et dont les corrections ont été prises en compte. Les brouillons et vérifications par IA existants ne fournissent pas ces résultats ; laissez `review.completed` à faux jusqu'à ce qu'ils existent.

## 3. La sortie Learn locale est une vérification préalable

Au commit Learn figé `fe8e384`, [`scripts/sync-streeling.mjs`](https://github.com/spareilleux/learn/blob/fe8e38444d882c28691dce9f12c21ac2ad404ec0/scripts/sync-streeling.mjs) lit les fichiers de cours Demerzel et écrit les pages EN/FR/ES générées et `streeling.lock.json` ; il préserve les journaux. La [pièce de vérification préalable DV-001](https://github.com/GuitarAlchemist/Demerzel/blob/6bc584d7ca1cd9eb1b1481e1100eeeb74e983863/state/streeling/reviews/dv-001-learn-preflight-2026-10-11.md) rapporte une synchronisation et un build Astro réussis dans un worktree Learn isolé, avec du HTML DV-001 généré dans les trois langues. Elle rapporte aussi des entrées de journal manquantes et une révision toujours ouverte. Le verrou fixe l'entrée Demerzel de cette exécution, pas un déploiement public. Une modification ultérieure de la source nécessite une nouvelle preuve de synchronisation et de build.

### Exercice pratique 4 : évaluer le build

Un tableau de publication indique : « Build Astro : réussi ; les fichiers DV-001 EN/FR/ES existent sous `dist/`. » L'affirmation « DV-001 est en ligne » est-elle étayée ? Nommez la prochaine vérification possible.

> **Réponse :** Non. Ce sont des sorties de vérification préalable locales. Après synchronisation et déploiement de la source approuvée, demandez chaque URL prévue de leçon et d'index sans identifiants, vérifiez le contenu retourné et la provenance source, puis consignez le résultat et l'heure. Un build local réussi ne suffit pas à établir l'accessibilité publique.

## 4. Fermer la boucle publique sans exagérer l'affirmation

L'[état public de référence du 11 octobre](https://github.com/GuitarAlchemist/Demerzel/blob/6bc584d7ca1cd9eb1b1481e1100eeeb74e983863/state/streeling/reviews/public-baseline-2026-10-11.md) a relevé des réponses 404 pour les routes de leçon DV-001 EN, FR et ES, alors que la vérification préalable locale avait produit leurs fichiers HTML. Ces deux observations sont compatibles : la vérification préalable testait la sortie locale ; l'état de référence testait le site alors public. Il rapporte aussi que l'index public signalait que ses modules générés par IA n'avaient été ni révisés ni testés par l'auteur du site. Une présence publique ne constituerait toujours pas un verdict de révision.

Une condition de publication pratique comporte une règle d'arrêt : si une pièce requise manque, formulez l'affirmation plus restreinte la plus forte que les preuves permettent et attribuez la condition manquante à un responsable. Après déploiement, recommencez la consultation anonyme à partir du nouveau commit source public ; un résultat du 11 octobre ne peut pas certifier un déploiement ultérieur. Conservez les dates de révision et de consultation publique à côté du verdict afin qu'un futur éditeur voie quelle version a été vérifiée.

### Exercice pratique 5 : rédiger la note de publication

Rédigez deux phrases pour le pilote DV-001 en utilisant uniquement ces pièces : six brouillons linguistiques source ; vérifications délimitées par IA ; aucune révision humaine ou par un apprenant terminée ; build EN/FR/ES local réussi ; réponses 404 des routes publiques EN/FR/ES le 11 octobre.

> **Réponse :** « DV-001 possède six brouillons linguistiques et des vérifications délimitées par IA ; une synchronisation et un build Learn locaux ont généré ses pages EN/FR/ES à partir d'une source Demerzel figée. Les révisions humaine disciplinaire, linguistique et par un apprenant restent ouvertes, et les requêtes anonymes vers ces trois routes publiques ont reçu des réponses 404 le 11 octobre 2026 ; ces pièces n'établissent donc pas un cours révisé ou publié. »

## Points à retenir

- Une affirmation de publication exige une preuve de sa limite précise ; conformité JSON, révision, build et accès public sont des étapes différentes.
- Indiquez la révision source et la date d'observation. Une vérification préalable datée n'est pas une promesse concernant le site actuel.
- Lorsqu'une condition manque, communiquez l'état exact plus restreint et la prochaine vérification, sans annoncer un verdict terminé.

## Preuves du projet et limites

- Commit pilote Demerzel `6bc584d7ca1cd9eb1b1481e1100eeeb74e983863` : [enregistrement de production DV-001](https://github.com/GuitarAlchemist/Demerzel/blob/6bc584d7ca1cd9eb1b1481e1100eeeb74e983863/state/streeling/course-productions/cp-data-visualization-2026-10-04-001.json), [dossier de révision](https://github.com/GuitarAlchemist/Demerzel/blob/6bc584d7ca1cd9eb1b1481e1100eeeb74e983863/state/streeling/reviews/dv-001-review-brief.md), [vérification disciplinaire](https://github.com/GuitarAlchemist/Demerzel/blob/6bc584d7ca1cd9eb1b1481e1100eeeb74e983863/state/streeling/reviews/dv-001-subject-review-2026-10-11.md), [vérification préalable Learn locale](https://github.com/GuitarAlchemist/Demerzel/blob/6bc584d7ca1cd9eb1b1481e1100eeeb74e983863/state/streeling/reviews/dv-001-learn-preflight-2026-10-11.md) et [état public de référence](https://github.com/GuitarAlchemist/Demerzel/blob/6bc584d7ca1cd9eb1b1481e1100eeeb74e983863/state/streeling/reviews/public-baseline-2026-10-11.md). Ce sont des pièces datées du pilote, pas des preuves de révision de PM-002.
- Commit Learn `fe8e38444d882c28691dce9f12c21ac2ad404ec0` : [script de synchronisation](https://github.com/spareilleux/learn/blob/fe8e38444d882c28691dce9f12c21ac2ad404ec0/scripts/sync-streeling.mjs). La vérification préalable DV-001 utilisait aussi une correction locale du générateur ; son build réussi ne certifie pas ce brouillon PM-002.
- Les cinq réponses de cette leçon suivent les pièces figées. Lors du cycle source anglais antérieur, aucune révision disciplinaire, linguistique ou par un apprenant, synchronisation/build Learn, mise en ligne ou consultation publique anonyme n'avait été réalisée pour PM-002. Ce brouillon français attend encore l'approbation d'une personne maîtrisant le français ; sa traduction n'établit aucun de ces résultats.
