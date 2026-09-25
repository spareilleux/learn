---
title: Journal
description: Notes d'avancement datées — l'épinglage de GA, la compilation hors ligne contre l'hôte du chatbot, les exécutions de CI et une course au préchauffage, et les différences trouvées entre le code d'IA de Guitar Alchemist, ses commentaires et ses documents.
sidebar:
  order: 99
---

## Progression

- [x] Programme du cours : .NET 10, qui référence `GA.Business.ML`, `FretboardVoicingsCLI` et `GaChatbot.Api` à un commit épinglé
- [x] CI : la sortie de chaque leçon comparée à son fichier attendu sur trois systèmes, sans modèle, sans clé d'API et sans GPU
- [x] Leçon 1 : la carte
- [x] Leçon 2 : les embeddings OPTIC-K
- [x] Leçon 3 : l'index et la recherche
- [x] Leçon 4 : le chatbot et ses agents
- [ ] Exécuter le chatbot avec Ollama et capturer ce que répondent les agents (daté, hors CI)

## 2026-09-14 — Pourquoi ce cours

La demande, le 2026-09-14 : un cours sur l'index OPTIC-K, sur tout le code d'apprentissage automatique et d'agents de GA, et sur ce que le chatbot cherche à accomplir. Le cours se range sous *Apprentissage automatique*, à côté d'[IX](../../machine-learning-ix/) : il porte sur la construction et l'usage d'embeddings, d'un index vectoriel et d'un routeur de type classifieur à l'intérieur d'un produit, pas sur l'usage d'agents de programmation, qui relève du *Développement assisté par IA*.

## 2026-09-14 — Épingler GA et compiler contre l'hôte du chatbot

- GA est épinglé sur [`a826864`](https://github.com/GuitarAlchemist/ga/commit/a826864f3a012cad88e415954bf57eca0ce12aa6), le commit qu'utilise le [cours de théorie musicale](../../music-theory-ga/). Le clone local de l'auteur n'est jamais utilisé : [`fetch-ga.sh`](https://github.com/spareilleux/learn/blob/8e335d7/code/ga-ai/fetch-ga.sh) fait un clone sans blobs et clairsemé dans `code/ga-ai/.ga`, ignoré par Git, avec 17 dossiers de projets, et sans les PDF de recherche de GA.
- Sous Windows, le premier checkout a échoué sur des chemins de plus de 260 caractères ; `git config core.longpaths true` avant le checkout règle le problème. Comme dans le cours de théorie musicale, `MSYS_NO_PATHCONV=1` empêche Git Bash de réécrire les motifs du clone clairsemé.
- Le projet du cours référence directement `GaChatbot.Api` et le démarre avec `WebApplicationFactory<Program>`. Deux détails ont été nécessaires : un attribut d'assembly, `WebApplicationFactoryContentRootAttribute`, qui pointe vers le dossier de l'hôte dans le clone ([`GaAi.csproj`](https://github.com/spareilleux/learn/blob/8e335d7/code/ga-ai/GaAi/GaAi.csproj#L20-L28)) ; et pas d'instructions de niveau supérieur dans le programme du cours, dont la classe `Program` générée entrerait en conflit avec celle de l'hôte.
- La machine de l'auteur fait tourner Ollama. Sans intervention, l'hôte l'aurait utilisé, et les sorties auraient différé de celles de la CI. Le cours règle l'adresse d'Ollama sur `http://127.0.0.1:9`, fermé sur la machine de l'auteur comme sur les runners.
- La mémoire du chat de GA est par défaut rangée dans des fichiers sous `~/.ga`. Le cours enregistre ses propres `MemoryStore` et `ChatTranscriptStore` sur un dossier neuf à côté du programme ; on a vérifié que `~/.ga` était inchangé après une exécution.
- Le premier corpus, 5 cases et une fenêtre de 4, avait 77 140 voicings, et le calcul des embeddings prenait 33 secondes. 3 cases et une fenêtre de 3 donnent 15 360 voicings en environ 8 secondes, assez pour chaque point de la leçon 3.
- Les messages d'exception diffèrent d'un système à l'autre (erreurs de socket). La leçon 4 n'affiche que le type d'exception et la frame de GA la plus profonde, `file:line`, dédupliqués et triés.
- Compilation locale des projets de GA et du cours : environ 23 secondes après la première restauration ; une vérification complète des quatre leçons, 40 secondes.

## 2026-09-14 — La CI

- Exécution [34917150100](https://github.com/spareilleux/learn/actions/runs/34917150100), pour le commit `43f009d` : les leçons 1 à 3 ont réussi partout, la leçon 4 a réussi sous Windows et échoué sous Linux et macOS. Sur ces deux systèmes, les avertissements du routeur sémantique d'intentions apparaissaient aussi sous la première requête.
- Cause : `IntentEmbeddingWarmupService` lance en arrière-plan le calcul des embeddings des intentions au démarrage de l'hôte, et ses avertissements atterrissent dans la requête en cours à ce moment-là. Correction dans le commit [`8e335d7`](https://github.com/spareilleux/learn/commit/8e335d7) : le cours attend la dernière ligne de journal du préchauffage avant d'envoyer des requêtes. La leçon 4 raconte l'histoire.
- Exécution [34917602262](https://github.com/spareilleux/learn/actions/runs/34917602262), pour `8e335d7` : vert sur les trois systèmes, 1 min 34 s sous Linux, 1 min 50 s sous macOS, 3 min 2 s sous Windows, clone et compilation compris.

## 2026-09-14 — Différences trouvées dans le code de GA (commit a826864)

Chaque point dit où le programme du cours le montre. Aucun n'a été signalé en amont.

Embeddings (leçon 2) :

1. `VoicingDocumentFactory` fixe `RootPitchClass` et `MidiBassNote` à partir de `MidiNotes[0]` ([lignes 37-38](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Rag/VoicingDocumentFactory.cs#L37-L38)). GA construit les voicings en commençant par la corde 1 (mi aigu) : cette note est donc la note **la plus aiguë**. ROOT, MODAL, la basse de MORPHOLOGY et le renversement sont calculés à partir d'elle ; le filtre de recherche utilise `MidiNotes.Min()`, la vraie basse. Montré par `l2`, « From a chord shape to GA's voicing document » (C ouvert : fondamentale E, renversement 1), et par la recherche de Cmaj7 de `l3`.
2. Le renversement compare cette note au nom de la fondamentale de l'accord, lu par `PitchClass.Parse` ([lignes 43-44](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Rag/VoicingDocumentFactory.cs#L43-L44)), qui lit les noms de notes comme des chiffres : `"A"` vaut 10 et `"E"` vaut 11. Un Em à l'état fondamental, `022000`, reçoit `Inversion = -1`. Reproduit avec un programme séparé qui référence `GA.Business.ML`, hors de la CI du cours : `PitchClass.Parse("E") = 11`, et `022000 Em ChordId.RootPitchClass="E" doc.RootPitchClass=4 inversion=-1`. Le [cours de théorie musicale](../../music-theory-ga/journal/) a trouvé le même comportement du parseur.
3. `VoicingHarmonicAnalyzer` passe `intervalSpread > 12` dans `IsRootless` et `false` dans `IsOpenVoicing` du record positionnel `VoicingCharacteristics` ([lignes 31-43](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Fretboard/Voicings/Analysis/VoicingHarmonicAnalyzer.cs#L31-L43)). Tout voicing qui couvre plus d'une octave est « sans fondamentale ». Montré par `l2`, « VoicingCharacteristics and PerceptualQualities ».
4. `VoicingAnalyzer` construit `new PerceptualQualities(curVoiceChars.Consonance, 0, 0, "Neutral", "Medium")` pour un record déclaré `(Brightness, ConsonanceScore, Roughness, ...)` ([ligne 164](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Fretboard/Voicings/Analysis/VoicingAnalyzer.cs#L164)). `ConsonanceScore` vaut toujours 0, la `Consonance` du document aussi, et la tension de CONTEXT, `1.0 - doc.Consonance`, vaut toujours 1. C'est la dimension constante du ticket [#616](https://github.com/GuitarAlchemist/ga/issues/616), dont l'analyse n'accuse que les littéraux voisins. Même section de `l2`, et la ligne CONTEXT de « Dimensions that never vary » dans `l3`.
5. `EmbeddingSchema.AtonalModalDim` vaut 17 alors que le registre donne 64 emplacements à ATONAL_MODAL ; `ModalVectorService` en alloue 17 ([ligne 116](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/Services/ModalVectorService.cs#L116)) et `WriteInto` ne vérifie pas les longueurs : 47 emplacements sont toujours nuls (`l3`). `HierarchyDim` vaut 8 contre 15 (`l2`, « Loose constants »). Les deux partitions ont un poids de 0 : la recherche n'est pas affectée.
6. STRUCTURE n'est pas invariante par transposition (221 classes d'ensembles sur 222, `l2`), comme le disent le propre balayage de GA et le commentaire de `TheoryVectorService` ; le résumé de `RootVectorService` affirme encore « genuinely O+P+T+I-invariant » ([lignes 3-7](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/Services/RootVectorService.cs#L3-L7)).
7. Les poids de similarité font 1.15 au total ; un vecteur obtient 1.15 contre lui-même (`l2`). Ce n'est pas un bug, mais « cosinus » est trompeur dans les journaux et les seuils.
8. Versions dans les commentaires et les documents : le document de schéma le plus récent est v1.4.1, `OPTIC-K_Embedding_Schema.md` décrit v1.3.1 (109 dimensions), `MusicalEmbeddingGenerator` dit 228 ([ligne 13](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/MusicalEmbeddingGenerator.cs#L13)) et 216 ([ligne 55](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/MusicalEmbeddingGenerator.cs#L55)), le commentaire de `CompactDimension` dit 112, `OptickIndexWriter` et `MusicalQueryEncoder` disent 112, le commentaire de `ExtensionsEnd` dit qu'elle vaut `TotalDimension`. Le code calcule 240 et 124.

Index et recherche (leçon 3) :

9. Neuf des 33 emplacements nommés de MODAL ne sont jamais remplis sur le corpus de 15 360 voicings : LocrianNatural6, DorianSharp4, LydianSharp2, AlteredDoubleFlat7, DorianFlat2, LydianAugmented, MixolydianFlat6, LocrianNatural2, Diminished. `ModalVectorService` cherche les modes par des noms d'affichage comme `"Locrian ♮6"` et repart en silence quand il ne trouve rien ; un nom qui ne correspond pas est la cause probable (*à vérifier*).
10. 37 des 124 dimensions de recherche sont toujours nulles et 4 constantes sur ce corpus (`l3`) ; #616 rapporte 40 dimensions mortes sur l'index en production.
11. `ApplyFilters` compare la qualité comme une sous-chaîne du nom stocké : le filtre `Am7` accepte `Gbm7(shell)/A`, et la qualité vide de `C` accepte tout nom avec C à la basse, y compris `C + E (Major 3rd)` et `Am/C` ([lignes 296-329](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/OptickSearchStrategy.cs#L296-L329)).
12. `OptickSearchStrategy.FindSimilarVoicingsAsync` renvoie toujours une liste vide (connu, commenté aux [lignes 75-92](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/OptickSearchStrategy.cs#L75-L92)). `MusicalQueryEncoder` laisse le vecteur d'intervalles hors des requêtes (connu, commenté).

Diagrammes et outils MCP :

13. Deux ordres pour la même chaîne de diagramme : `VoicingGenerator`, l'index et l'analyseur de l'outil MCP lisent la corde 1 (mi aigu) en premier ; `PlayableNotationFormatter` lit le mi grave en premier ([lignes 31-53](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Notation/PlayableNotationFormatter.cs#L31-L53)). La tablature du chatbot pour `3-0-x-2-3-x` (Cmaj7) est `6/3 5/0 3/2 2/3`, les notes G A A D (`l4`).
14. La description de `ga_generate_voicing_embedding` dit « 228-dim » et donne `'x-3-2-0-1-0' for Cmaj7` ([lignes 42-44](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingEmbeddingTool.cs#L42-L44)) ; l'analyseur de l'outil le lit comme Dsus2/E (`l2`), et lu mi grave en premier, ce serait C, pas Cmaj7.
15. `ga_get_embedding_schema` liste dix partitions, sans ROOT, avec les constantes isolées `HierarchyDim` et `AtonalModalDim` ([lignes 69-91](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingEmbeddingTool.cs#L69-L91)). Lu dans le code, pas exécuté par le cours.

Chatbot (leçons 1 et 4) :

16. Sans serveur d'embeddings, chaque message qu'aucune garde n'attrape finit en HTTP 500. `SemanticRouter.RouteAsync` n'intercepte pas l'exception de `EnsureEmbeddingsInitializedAsync` ([lignes 68-104](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/SemanticRouter.cs#L68-L104)) : son repli par mots-clés est donc inatteignable ; le repli de l'hôte sur un appel direct au modèle lève aussi une exception. « What is the relative minor of C major? » échoue alors que `skill.relativekey` y répond avec une confiance de 1.00 (`l4`).
17. L'ancien chemin `CanHandle` envoie cette même question à `ScaleInfo`, pas au skill des tonalités relatives (`l4`).
18. `skill.fretspan` n'a aucun prompt d'exemple, et `SemanticIntentRouter` ignore les intentions sans exemples : on ne peut jamais y être routé (`l1`).
19. `ProductionOrchestrator.AnswerStreamingAsync` (à partir de la [ligne 154](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Services/ProductionOrchestrator.cs#L154)) a la garde voicing, mais pas le chemin rapide d'algèbre de `AnswerAsync`. Lu dans le code, pas exécuté.
20. `IntentEmbeddingWarmupService` lance son travail sans l'attendre ; c'est bien pour un serveur, mais les journaux d'un hôte dépendent alors du timing (l'échec de CI ci-dessus).

Documents :

21. `docs/architecture/chat-surfaces.md` dit, dans son statut du 2026-05-13, que `GaChatbot.Api` est canonique et sert la démo publique ([lignes 16-21](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/docs/architecture/chat-surfaces.md#L16-L21)), alors que des sections plus loin disent que la page déployée appelle SignalR sur GaApi, et traitent les deux comme parallèles à la version canonique (lignes 215-223 et 262).
22. Le `CLAUDE.md` de GA dit qu'ix produit `optick.index` ; dans le code de GA et dans son skill `optic-k-rebuild`, c'est `FretboardVoicingsCLI` qui l'écrit. `CLAUDE.md` nomme `GA.Business.Core.Harmony` et `GA.Business.Core.Fretboard` comme couche 3 ; le générateur et l'analyseur de voicings vivent dans `GA.Domain.Services`.

Pistes non vérifiées par le cours, notées plus tôt en lisant les documents de GA (*à vérifier*) : `GaChatbotCli` n'arrive peut-être pas à résoudre ses services ; le backlog et la feuille de route divergent sur certains statuts ; les documents de GA donnent plusieurs tailles pour l'index en production (161, 168, 175, 176 et 660 Mo).

## 2026-09-24 — Correctifs en amont

La plupart des 22 différences du 2026-09-14 ont été corrigées en amont par [#689](https://github.com/GuitarAlchemist/ga/pull/689), fusionnée le 2026-09-23, qui porte aussi les commits fusionnés à nouveau par [#686](https://github.com/GuitarAlchemist/ga/pull/686) et [#688](https://github.com/GuitarAlchemist/ga/pull/688) le 2026-09-24. Les correctifs de code viennent avec des tests dans GA. Ce cours ne les a pas relancés : il reste épinglé à `a826864` (*à vérifier*).

- Corrigées : 1 et 4 (documents de voicing construits à partir de la fondamentale de l'accord, de la note la plus grave et des champs nommés de l'analyseur), 2 (fondamentales lues comme des noms de notes), 3 (arguments nommés), 5 (constantes HIERARCHY et ATONAL_MODAL alignées sur les partitions), 6 (le résumé de `RootVectorService`), 8 (les commentaires 112/216/228 et v1.3.1), 9 (cases MODAL cherchées sous les noms du catalogue des modes), 11 (le filtre d'accord compare fondamentale, qualité et basse éventuelle), la moitié « requête » de 12 (le vecteur d'intervalles de la requête est encodé), 13 (l'ordre des cordes des diagrammes est explicite), 14 et 15 (l'outil de schéma lit `EmbeddingSchema`), 16 (repli sur les mots-clés, et une réponse « indisponible » au lieu d'un HTTP 500), 17, 18, 19, 21 et 22.
- Inchangées : 7, qui n'est pas un bogue ; l'autre moitié de 12, `FindSimilarVoicingsAsync`, rend toujours une liste vide, comme le dit son commentaire ; 20, listée par #688 comme trouvée et non modifiée. 10 n'a pas été remesurée, et les correctifs 5 et 9 touchent des dimensions qu'elle comptait.
