---
module_id: wml-003-term-preservation-and-cultural-review
department: world-music-languages
course: Auditer les termes de guitare dans six langues
level: intermediate
prerequisites: ["wml-001-guitar-around-the-world", "wml-002-dadgad-layout-and-cultural-claims"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
research_cycle: world-music-languages-2026-10-12-003
version: "0.1.0"
---

# Auditer les termes de guitare dans six langues

> **Périmètre de la source et du transfert.** Le texte technique ci-dessous provient d’un brouillon archivé. Les mentions historiques d’une absence d’importation ou de compilation dans Learn concernent cette étape antérieure ; ce [dossier de transfert](../../../../code/streeling/evidence/voicing-learning-2026-10-22/README.md) décrit l’importation actuelle et ses vérifications. Les autres expériences indiquées comme non réalisées le restent. Les revues humaines du contenu et de la langue, ainsi que l’essai avec un apprenant, restent à effectuer.

> **Département des musiques du monde et des langues** | Intermédiaire | 40 minutes | Brouillon français ; révisions culturelle et linguistique et évaluation auprès d'apprenants en attente

## Objectifs et question du projet

Vous reproduirez un inventaire de termes dans six langues à partir de sources Git précises, distinguerez l'orthographe littérale du sens traduit et déterminerez ce qu'une vérification automatique peut affirmer sans risque à propos d'une leçon de musique culturellement située. **Question du projet :** comment Streeling peut-elle développer la localisation de ses cours de guitare sans transformer une recherche de chaînes réussie en une affirmation non étayée selon laquelle toutes les traductions seraient correctes ou publiées ? Cette leçon utilise un cours existant et un audit déterministe. Elle ne contient aucun verdict culturel ou linguistique approuvé.

[WML-001 au commit Demerzel `f5b040a`](https://github.com/GuitarAlchemist/Demerzel/blob/f5b040ae040a5a7f1fe6c3f609f878c00a3a1859/state/streeling/courses/world-music-languages/en/wml-001-guitar-around-the-world.md) présente plusieurs traditions de guitare. Ses fichiers source existent en anglais, français, espagnol, portugais, italien et allemand. [WML-002 au même commit](https://github.com/GuitarAlchemist/Demerzel/blob/f5b040ae040a5a7f1fe6c3f609f878c00a3a1859/state/streeling/courses/world-music-languages/en/wml-002-dadgad-layout-and-cultural-claims.md) montre pourquoi une table d'accordage peut établir des noms de notes alors qu'une association culturelle exige un autre type de source. Ici, nous auditons une question mécanique plus restreinte : sept termes sélectionnés dans WML-001 figurent-ils littéralement dans chacun de ses six fichiers source ? Ces sept termes constituent un **échantillon pédagogique**, et non un glossaire complet ou une liste de traductions obligatoires.

## 1. Reproduire l'inventaire lexical

Le [script de vérification des termes à la révision fixée](https://github.com/GuitarAlchemist/Demerzel/blob/882d5284426ea230d08f067f74e1f95ca56fb90d/state/streeling/fixtures/world-music-languages/wml-003/check_terms.py) lit les **objets Git** au commit source complet, et non les fichiers qui se trouvent à un moment donné dans un arbre de travail. Pour chaque langue, il enregistre le chemin du fichier, l'identifiant du blob Git et un booléen de présence littérale sans distinction de casse pour `rasgueado`, `picado`, `alzapúa`, `compás`, `golpe`, `batidas` et `la pompe`. Son [relevé JSON versionné](https://github.com/GuitarAlchemist/Demerzel/blob/882d5284426ea230d08f067f74e1f95ca56fb90d/state/streeling/fixtures/world-music-languages/wml-003/term-presence-f5b040a.json) peut être reproduit avec cette commande à la racine du dépôt Demerzel :

```text
python state/streeling/fixtures/world-music-languages/wml-003/check_terms.py --ref f5b040ae040a5a7f1fe6c3f609f878c00a3a1859
```

Le résultat à cette révision comprend **42 couples terme-langue** (`7 × 6`). Quarante sont des correspondances exactes sans distinction de casse. Les deux formes littérales absentes sont `fr:alzapúa` et `fr:compás`. La [source française de WML-001 à ce commit](https://github.com/GuitarAlchemist/Demerzel/blob/f5b040ae040a5a7f1fe6c3f609f878c00a3a1859/state/streeling/courses/world-music-languages/fr/wml-001-guitar-around-the-world.fr.md) affiche à leur place `Alzapua` et `Compas`, sans accents, dans sa liste de techniques. Une recherche antérieure plus permissive portant sur `alzap` et `comp.s` avait renvoyé six fichiers pour chacun ; elle masquait cette différence d'orthographe exacte. C'est le résultat de l'utilisation du projet sur ses propres contenus qui a motivé cette leçon.

Le script renvoie délibérément un relevé d'audit même lorsque des formes sont absentes. Son option `--require-exact` provoque une sortie avec le code 1 pour un contrôle lexical strict. Aucun de ces modes ne déclare le fichier français erroné. Un musicien maîtrisant le français peut juger acceptable un emprunt sans accent ou préférer l'orthographe de la langue source ; un remplacement aveugle pourrait dégrader le texte ou laisser subsister une erreur de traduction plus profonde. L'audit indique au réviseur des lignes précises à examiner.

### Exercice pratique 1

Calculez le nombre total de couples et de correspondances exactes à partir du relevé portant sur sept termes et six langues. Nommez les deux couples littéraux manquants et les deux chaînes qui apparaissent à leur place en français.

> **Réponse :** Sept termes multipliés par six fichiers donnent 42 couples. Quarante correspondent littéralement sans distinction de casse. Les deux couples absents sont `alzapúa` en français et `compás` en français ; la source française utilise `Alzapua` et `Compas`. Ce calcul ne dit encore rien de l'acceptabilité de ces graphies dans la terminologie française de la guitare.

## 2. Respecter les limites des preuves

La vérification actuelle utilise la méthode Unicode `casefold()` ; `Rasgueado` correspond donc à `rasgueado`, mais `Alzapua` ne correspond pas à `alzapúa`. Une comparaison ignorant les accents pourrait être ajoutée **séparément**, par décomposition Unicode et suppression des signes combinatoires. Elle ne doit pas remplacer la colonne des formes exactes : une correspondance normalisée et une correspondance exacte répondent à des questions différentes. Le terme source peut être un emprunt, un nom propre ou un mot dont l'accent distingue des sens. Une politique terminologique doit être établie avec l'expertise linguistique et musicale appropriée avant de donner à une règle orthographique une portée normative.

La présence littérale constitue aussi une preuve limitée de la couverture du contenu. Un terme peut n'apparaître que dans un glossaire, alors que le corps de la leçon omet le concept sous-jacent. Une traduction peut conserver un titre et modifier l'affirmation qui le suit. À l'inverse, une traduction juste peut employer une expression différente et échouer au contrôle exact. Pour évaluer le sens, comparez la phrase, l'exemple, la réponse et le contexte musical à la source anglaise ; pour évaluer l'autorité culturelle, consultez des musiciens ou des travaux de recherche en rapport avec la tradition précise. Le script ne fait rien de cela. Il ne compare pas les définitions des termes et ne vérifie pas si un lecteur francophone peut exécuter une technique.

Le paragraphe anglais de WML-001 sur le flamenco décrit le `compás`, puis évoque des cycles de 12 temps. L'audit lexical peut confirmer si le mot apparaît dans chaque fichier. Il ne peut établir ni que le paragraphe représente fidèlement toutes les pratiques du flamenco ni qu'une traduction en préserve la nuance voulue. Considérez ce paragraphe comme une **affirmation du cours à réviser**, et non comme un fait prouvé par les décomptes de termes de cette leçon. [L'exercice de WML-002 sur DADGAD](https://github.com/GuitarAlchemist/Demerzel/blob/f5b040ae040a5a7f1fe6c3f609f878c00a3a1859/state/streeling/courses/world-music-languages/en/wml-002-dadgad-layout-and-cultural-claims.md) applique la même distinction aux données de notes et aux propos culturels généraux d'un skill de GA.

### Exercice pratique 2

Si un nouvel outil supprime les accents avant la comparaison, quel serait son résultat en français pour ces deux termes ? Son résultat doit-il remplacer celui de la vérification de l'orthographe exacte ? Donnez une raison pour chaque réponse.

> **Réponse :** Il ferait probablement correspondre `Alzapua` à `alzapúa` et `Compas` à `compás`, soit deux correspondances supplémentaires sans distinction d'accent, à condition d'appliquer la même normalisation aux deux chaînes. Il devrait ajouter une colonne normalisée distincte, et non remplacer la colonne exacte, car l'écart initial est utile au réviseur qui doit décider si l'orthographe de la langue source compte. Aucune des deux comparaisons ne détermine la justesse du sens.

### Exercice pratique 3

Le relevé indique qu'un blob français contient `Compas`. Un commit ultérieur modifie ce fichier sans changer le fichier anglais. L'ancien relevé peut-il prouver que le nouveau fichier français contient toujours ce terme ? Quelles sont les deux valeurs Git qu'un réviseur doit comparer avant de réutiliser l'audit ?

> **Réponse :** Non. Le relevé est lié au blob Git français à `f5b040a` ; une modification française ultérieure produit un blob différent, même si le mot demeure. Comparez les anciens et nouveaux identifiants de blob français ainsi que le commit source fixé ; relancez la vérification au nouveau commit au lieu de lui attribuer l'ancien audit. Pour la révision d'une traduction, il faut aussi savoir à quel blob anglais la version française a été comparée.

## 3. Articuler la révision linguistique et la publication sur le site

Les six fichiers *source* de WML-001 constituent un état donné. Le [code provisoire de synchronisation de Learn à `02fc08c`](https://github.com/spareilleux/learn/blob/02fc08c8f73e017412d1a623415ac4ab08645eb0/scripts/sync-streeling.mjs) génère actuellement les pages de cours en anglais, français et espagnol ; un import isolé de Demerzel `f5b040a` a signalé 113 pages EN, 80 FR et 80 ES sur l'ensemble du site. Il s'agit de preuves locales concernant les données d'entrée de la compilation, et non d'une lecture publique anonyme. Les fichiers source portugais, italiens et allemands de WML-001 ne suffisent pas à établir que ces routes du site existent. Même une page générée peut encore attendre une révision du fond, une révision de la traduction et une évaluation auprès d'apprenants ; un déploiement doit être inspecté séparément.

**Périmètre actuel des sources Learn.** L'expérience d'import précédente est historique. Les [conventions des sources Learn à `09b13e7f`](https://github.com/spareilleux/learn/blob/09b13e7f9eddc2b4ddbd87356001c1da2eec6b58/AGENTS.md) placent les fichiers de rédaction EN/FR/ES dans `streeling/courses/` au sein de Learn ; les pages générées sont synchronisées à partir de cette copie. PT/IT/DE et les cycles de recherche restent dans Demerzel. Le relevé de termes dans six langues présenté ci-dessus demeure lié à ses blobs Demerzel historiques et ne peut approuver une traduction Learn modifiée. Avant de réutiliser une révision lexicale ou sémantique ultérieure, rattachez-la aux blobs Learn réels de l'anglais et de la langue concernée.

Une chaîne de révision sûre peut s'exprimer par de petites fonctions : `read_source(commit, path)` renvoie les octets et le blob ; `check_terms(bytes, glossary)` renvoie des observations lexicales ; `review_meaning(locale_blob, english_blob, evidence)` renvoie un verdict humain ; `render_status(receipts, imported_commit)` indique le statut de la page générée ; `read_public_page(url, expected_commit)` vérifie ce que reçoivent les lecteurs anonymes. Chaque fonction produit un résultat plus limité que « cours approuvé ». Le [contrat provisoire de relevé lié aux sources exactes](https://github.com/GuitarAlchemist/Demerzel/blob/5d7c1d1bd9972fe9d6d2e7a90ab3cdddabb8ed44/schemas/streeling-review-receipt.schema.json) exige le blob de la traduction et sa dépendance anglaise. Son schéma est encore soumis à révision humaine ; cette leçon ne crée aucun relevé et ne contourne pas ce contrat.

### Exercice pratique 4

Les sept termes passent une vérification sans distinction d'accent en français, mais personne n'a examiné le paragraphe sur le `compás` ni son exercice. Quel statut l'agent peut-il annoncer : contrôle lexical réussi, sens français approuvé ou leçon française publiée ? Donnez les preuves minimales requises pour chaque statut ultérieur.

> **Réponse :** Il peut seulement annoncer que le contrôle lexical indiqué a réussi pour le fichier à la révision fixée. L'approbation du sens français exige une révision humaine des blobs français et anglais concernés, du paragraphe, des exemples et des exercices, avec un verdict consigné et des preuves. La publication publique exige une révision source acceptée, une page générée et déployée et une lecture anonyme liée à cette révision. La présence de termes n'autorise aucune de ces étapes ultérieures.

### Exercice pratique 5

Une personne chargée de la planification constate six langues source pour WML-001, les trois langues générées par l'import local de Learn et l'absence de relevé de révision. Combien de versions linguistiques de WML-001 peut-elle honnêtement déclarer révisées par une personne ? Peut-elle affirmer qu'il existe six routes publiques ? Déterminez la prochaine vérification utile pour un apprenant francophone.

> **Réponse :** Aucune version linguistique ne dispose d'un verdict humain consigné dans cette leçon. Le nombre de fichiers source ne peut prouver l'existence de six routes publiques ; l'import local étaye uniquement la génération EN/FR/ES et ne prouve même pas que ces pages ont été déployées. Pour un apprenant francophone, obtenez d'abord une révision du fond et une révision du français liées aux blobs anglais et français exacts, puis proposez une tâche sans fournir la réponse, consignez le résultat, déployez la révision acceptée et lisez la page publique française de manière anonyme.

## Sources, limites et prochaine vérification

Les données source sont [WML-001 EN](https://github.com/GuitarAlchemist/Demerzel/blob/f5b040ae040a5a7f1fe6c3f609f878c00a3a1859/state/streeling/courses/world-music-languages/en/wml-001-guitar-around-the-world.md) et [FR](https://github.com/GuitarAlchemist/Demerzel/blob/f5b040ae040a5a7f1fe6c3f609f878c00a3a1859/state/streeling/courses/world-music-languages/fr/wml-001-guitar-around-the-world.fr.md) à `f5b040a`, ainsi que les quatre autres blobs linguistiques nommés dans le relevé reproductible. Le script vérifie la présence littérale sans distinction de casse n'importe où dans un fichier, à partir de sept termes sélectionnés. Il ne peut juger la traduction, les affirmations culturelles, la performance des apprenants ou la publication. Aucun réviseur maîtrisant la langue ni spécialiste du sujet n'a approuvé ce cours ou WML-001 pendant ce cycle. La prochaine vérification consiste à demander à un guitariste francophone et à une personne maîtrisant le français d'évaluer les deux différences d'accent et les définitions qui les entourent par rapport aux blobs anglais et français fixés ; leurs conclusions pourront justifier des modifications et un nouvel audit lié aux sources exactes.
