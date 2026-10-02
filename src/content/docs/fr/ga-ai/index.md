---
title: "L'IA de GA : OPTIC-K, ML, agents et chatbot — Mission"
description: Le côté apprentissage automatique et agents de Guitar Alchemist, pour développeurs C# — l'embedding OPTIC-K, l'index de voicings et sa recherche, le routage et les agents du chatbot, et ce que le chatbot doit devenir, chaque partie exécutée hors ligne contre le code même de GA.
sidebar:
  label: Mission
  order: 0
---

:::note[Comment ce cours est testé]
Chaque tableau de sortie des leçons vient de [`code/ga-ai`](https://github.com/spareilleux/learn/tree/main/code/ga-ai), un programme console .NET 10 qui référence directement trois projets de Guitar Alchemist : `GA.Business.ML`, l'outil en ligne de commande qui écrit l'index de voicings, et l'hôte du chatbot `GaChatbot.Api`. GA est cloné au commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6). Le programme n'a besoin ni de clé d'API, ni de GPU, ni de serveur de modèles : il construit lui-même un petit index, et démarre le chatbot dans son propre processus, avec une adresse de modèle qui pointe vers un port fermé. [`.github/workflows/ga-ai-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/ga-ai-examples.yml) l'exécute sous Linux, Windows et macOS et compare la sortie de chaque leçon avec les fichiers de `expected/`. Les sorties ont été capturées en septembre 2026.
:::

## Pourquoi j'apprends ça

[Guitar Alchemist](https://github.com/GuitarAlchemist/ga) (GA) a un chatbot pour guitaristes. Derrière lui, il y a une description en 240 nombres de chaque forme d'accord à la guitare, appelée OPTIC-K, un index de 313 047 de ces descriptions, un routeur qui décide quel morceau de code répond à une question, et une poignée d'agents qui appellent un modèle de langage. La documentation autour est abondante et en partie périmée, et le code bouge chaque semaine.

Je veux savoir ce qui se passe vraiment : quels nombres reçoit un accord, pourquoi deux accords ressortent comme semblables, ce que contient le fichier d'index, et ce que fait le chatbot d'une question quand aucun modèle n'est joignable. Pour le découvrir, j'appelle les classes de GA depuis un programme, j'affiche ce qu'elles renvoient, et je le compare à ce que disent les commentaires et les documents. Là où les deux divergent, la différence va dans le [journal](journal/).

## À qui s'adresse ce cours

Tu écris du C#. Tu connais `float[]`, LINQ, l'injection de dépendances et ASP.NET Core assez pour lire un `Program.cs`. Tu n'as besoin d'aucune connaissance en apprentissage automatique : le cours utilise trois idées, chacune expliquée là où elle apparaît pour la première fois.

1. **Un embedding** (plongement vectoriel) est un tableau de nombres de longueur fixe qui décrit un objet, de sorte que des objets semblables reçoivent des tableaux semblables.
2. **La similarité cosinus** mesure à quel point deux tels tableaux pointent dans la même direction : 1 pour la même direction, 0 pour rien en commun.
3. **La recherche des plus proches voisins** renvoie les tableaux stockés les plus proches d'un tableau de requête.

Trois autres cours de ce site couvrent les bases, et celui-ci renvoie vers eux au lieu de les répéter :

- [Théorie musicale pour Guitar Alchemist](../music-theory-ga/) : classes de hauteurs, voicings, vecteurs d'intervalles et classes d'ensembles, le vocabulaire qu'encode OPTIC-K ;
- [Apprentissage automatique, appliqué dans IX](../machine-learning-ix/) : caractéristiques, distances, plus proches voisins et partitionnement, écrits à la main ;
- [Programmation agentique avec Claude Code et Codex](../agentic-coding/) : la boucle d'outils, les hooks, les skills et les serveurs MCP, du point de vue d'un développeur qui utilise des agents.

## À la fin de ce cours, je saurai

- dessiner la pile IA de GA : quel projet calcule les embeddings, lequel écrit l'index, lequel route un message de chat, et ce que font ix, Demerzel et TARS autour ;
- lire un vecteur OPTIC-K partition par partition, calculer à la main la similarité pondérée de deux voicings, et dire à quoi le vecteur est invariant et à quoi il ne l'est pas ;
- ouvrir un fichier d'index OPTK, expliquer son en-tête, et prédire ce que renvoie une recherche et pourquoi ;
- suivre un message de chat à travers les hooks, les gardes déterministes, le routeur d'intentions et les agents de GA, et expliquer pourquoi certaines questions fonctionnent sans modèle et d'autres échouent ;
- évaluer les réponses musicales d'un skill déterministe avec un petit oracle écrit de ma main, et dire où cet oracle s'arrête ;
- lire un flux d'événements envoyés par le serveur comme le fait le standard HTML, et vérifier que le texte qu'un client reconstruit est bien celui que le serveur a calculé ;
- exécuter, à côté du code épinglé, un correctif absent du commit épinglé, et tester une garde avec des entrées pour lesquelles elle n'a pas été écrite ;
- tester une suite de tests : appliquer ses vérifications à des réponses pour lesquelles elles n'ont pas été écrites et à des réponses fausses exprès, et lire ce qui passe ;
- tester un skill sur toutes les entrées qu'il peut recevoir, avec le calcul d'un manuel pour oracle, et lui faire passer ses propres prompts d'exemple ;
- distinguer, dans l'IA de GA, ce qui fonctionne aujourd'hui, ce qui est en construction, et ce qui n'est que prévu.

## Plan

| # | Leçon | Dans GA | Si tu écris du C# |
|---|---|---|---|
| 1 | [La carte](01-the-map/) | les cinq couches, le pipeline de l'index, l'hôte du chatbot, les dépôts voisins | lire un conteneur d'injection de dépendances, `WebApplicationFactory` |
| 2 | [Les embeddings OPTIC-K](02-optic-k-embeddings/) | `EmbeddingSchema`, `MusicalEmbeddingGenerator`, `VoicingAnalyzer` | records positionnels, `TensorPrimitives` |
| 3 | [L'index et la recherche](03-index-and-search/) | `OptickIndexWriter`, `OptickIndexReader`, `OptickSearchStrategy`, `MusicalQueryEncoder` | formats binaires, fichiers mappés en mémoire, tas top-k |
| 4 | [Le chatbot et ses agents](04-chatbot-and-agents/) | `ProductionOrchestrator`, `SemanticIntentRouter`, `SemanticRouter`, skills, hooks | services hébergés, replis, tester un hôte dans le processus |
| 5 | [Le skill d'improvisation](05-improvisation-skill/) | `ImprovisationSkill` face à la théorie accord–gamme, ticket #744 | expressions régulières générées par source, lire `AgentResponse.Data`, écrire un oracle de test |
| 6 | [La réponse sur le fil](06-answer-on-the-wire/) | `SseChunker`, les deux `WriteSseLineAsync`, les lecteurs de la page et de ga-client, #743 et #746 | événements envoyés par le serveur, `Regex.Split` et assertions de voisinage, porter un client pour le tester |
| 7 | [Les noms d'accords qu'il ne lit pas](07-chord-names/) | `InvalidChordNames` (#749), les expressions d'accords de `ImprovisationSkill`, ticket #745 | alias extern et CS0436, limites de mot dans les expressions régulières |
| 8 | [L'examen maison du chatbot](08-the-chatbots-own-exam/) | `prompts.yaml` et `PromptCorpusTests`, `DiatonicChordsSkill` (Path B), `ModesSkill` | YamlDotNet, `StringComparison`, tester une suite de tests avec des réponses fausses |
| 9 | [Tous les intervalles, toutes les tonalités](09-every-interval-every-key/) | `IntervalSkill`, `ScaleInfoSkill`, `RelativeKeySkill`, `KeyNaming`, le `DetermineQuality` du domaine | tests exhaustifs, `\b` et assertion avant dans les expressions régulières, branches par défaut des switch |
| 10 | [Ce à quoi le modèle doit se fier](10-what-the-model-is-told-to-trust/) | `ga_dsl_eval`, les closures `domain.diatonicChords`, `domain.transposeChord` et `domain.commonTones`, les fichiers SKILL.md des trois skills Path B | appeler l'outil d'un modèle sans le modèle, une lettre par degré, réutiliser un oracle d'une leçon à l'autre |
| 11 | [Les accords que lit le skill des tonalités](11-the-chords-the-key-skill-reads/) | `KeyIdentificationService` au commit épinglé et sur `main`, `ga_key_identify`, `KeyIdentificationSkill`, le SKILL.md de key-identification | extraire des chiffrages d'un texte, un classement et la sélection bâtie dessus, appeler des méthodes privées par réflexion |
| 12 | [Ce que répondent les skills de progression](12-what-the-progression-skills-answer/) | `ProgressionMoodSkill`, `ProgressionCompletionSkill`, leurs fichiers SKILL.md, `KeyIdentificationService` au commit épinglé et sur `main` | un test sur les mots qui choisit une réponse fixe, un modèle restreint à une liste calculée, le routage de repli par mots-clés |
| 13 | [Ce que répond l'analyse de progression](13-what-the-progression-analysis-answers/) | la closure `domain.analyzeProgression` au commit épinglé et sur `main`, `ga_dsl_list_closures`, le brouillon progression-analysis, `KeyIdentificationService.IsChordDiatonic` | compiler le fichier F# d'un autre commit contre le projet épinglé, les exemples d'un brouillon comme test, des chiffres romains tirés de la gamme et de l'accord |
| 14 | [Ce que répond le skill de substitution](14-what-the-substitution-skill-answers/) | `ChordSubstitutionSkill`, `ga_chord_substitutions` et `ga_chord_compare`, `GrothendieckService.FindNearby`, `GrothendieckDelta`, la closure `domain.chordSubstitutions` | une distance sous laquelle toute une classe d'ensembles est à égalité, une égalité départagée par l'ordre de stockage, des entrées optionnelles qu'un outil exige |
| 15 | [Les notes d'un accord](15-the-notes-of-a-chord/) | `ChordInfoSkill`, `ChordVocabulary`, `ChordSpelling`, `ga_chord_info` et le SKILL.md chord-info | la première correspondance d'une expression régulière, `ToLowerInvariant` au-delà de l'ASCII, un aller-retour comme test |
| 16 | [Les voicings d'un accord](16-the-voicings-of-a-chord/) | `ChordVoicingsSkill`, `TypedMusicalQueryExtractor`, `ChordPitchClasses`, `OptickSearchStrategy` et ADR-0002, au commit épinglé et sur `main` | un second clone d'une dépendance à un autre commit, vérifier une réponse en la jouant, un filtre sur les noms, un filtre abandonné sans un mot dans la réponse |
| 17 | [Le capodastre et les accordages](17-the-capo-and-the-tunings/) | `CapoSkill`, `AlternateTuningsSkill` et le repli hors ligne, au commit épinglé et sur `main` | vérifier un calcul contre un manuel sur chaque tonalité et chaque case, une limite de mot après une altération, un sens de calcul tiré de la formulation, l'orthographe comme partie de la réponse |
| 18 | [La conduite des voix](18-voice-leading/) | `VoiceLeadingSkill` et le repli hors ligne | vérifier contre une recherche exhaustive une réponse qui se dit optimale, une doublure choisie sans recherche, une table de chiffrages derrière une expression plus étroite, une recherche de bémol insensible à la casse |
| 19 | [Les paires de voicings](19-voice-leading-pairs/) | `ga_voice_leading_pair` dans `GaMcpServer`, sa recherche au commit épinglé et sur `main`, et le skill de conduite des voix en attente | un classement qui ne vérifie jamais ce qu'il classe, davantage de candidats qui dégradent la réponse, un appariement trié qui n'est minimal qu'entre tailles égales, un ordre des cordes qu'un consommateur a corrigé et qu'un autre transmet tel quel |
| 20 | [Les progressions générées](20-generated-progressions/) | `ga_generate_progression` dans `GaMcpServer`, les tables à douze tonalités de GA, le raccord avec `ga_voice_leading_pair` au commit épinglé et sur `main`, et le skill de progression en attente | une orthographe tirée de l'armure plutôt que du nom, deux sources qui s'accordent sur un accord faux, un paramètre sans limite, des réponses pour des mouvements isolés qui ne font pas un chemin |
| — | [Journal](journal/) | | |

## Prérequis

- Le [SDK .NET 10](https://dotnet.microsoft.com/download/dotnet/10.0) et [Git](https://git-scm.com/downloads). Sous Windows, lance les scripts du cours depuis Git Bash.
- Environ 20 Mo de disque pour le clone partiel de GA, et environ 1,1 Go une fois les projets de GA et le programme du cours compilés.
- Une connexion réseau pour la première exécution seulement, pour cloner GA et restaurer les paquets NuGet. Ensuite, tout s'exécute hors ligne.
- Pas besoin de guitare, mais les formes d'accords de la leçon 2 sont les premières qu'apprend un guitariste.

## Ressources

- [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga) au commit `a826864`, en particulier son [`CLAUDE.md`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/CLAUDE.md), les [documents du schéma OPTIC-K](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Documentation/Schema) et la [feuille de route du chatbot](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/docs/plans/2026-05-07-chatbot-roadmap.md).
- Clifton Callender, Ian Quinn et Dmitri Tymoczko, ["Generalized Voice-Leading Spaces"](https://doi.org/10.1126/science.1153021), *Science* 320, 2008 : l'article qui a nommé les équivalences OPTIC.
- Jared Updike, [Harmonious](https://harmoniousapp.net/) : une référence exhaustive des accords et des gammes pour piano et guitare. Sa page [Equivalence Groups](https://harmoniousapp.net/p/ec/Equivalence-Groups) illustre chaque équivalence OPTIC par des diagrammes d'accords, et ajoute le K d'OPTIC-K, pour la complémentarité.
- [Tests d'intégration dans ASP.NET Core](https://learn.microsoft.com/aspnet/core/test/integration-tests), pour `WebApplicationFactory`, et [Microsoft.Extensions.AI](https://learn.microsoft.com/dotnet/ai/microsoft-extensions-ai), les abstractions par lesquelles le chatbot de GA appelle les modèles.
