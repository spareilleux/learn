---
title: "Leçon 8 : l'examen maison du chatbot"
description: "Le corpus de prompts de Guitar Alchemist, les invariants sur lesquels on teste son chatbot, exécuté sans modèle sur l'hôte du cours, puis testé à son tour : les vérifications de chaque prompt appliquées aux réponses des autres prompts et à sa propre réponse un demi-ton plus haut. Des sous-chaînes insensibles à la casse, dont plus d'un tiers ne font qu'une lettre, acceptent un message d'erreur, la mauvaise famille de modes et une réponse sur un autre accordage ; une lecture plus stricte des mêmes chaînes fait passer les réponses étrangères acceptées de 169 à 69."
sidebar:
  label: 8. L'examen maison du chatbot
  order: 8
---

Les leçons 5 à 7 notaient les réponses du chatbot avec des oracles que le cours avait écrits à partir des manuels et des standards. GA a son propre oracle. [`prompts.yaml`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Tests/Apps/GaChatbot.Api.Tests/Corpus/prompts.yaml) liste des questions qu'un utilisateur pourrait poser, chacune avec les chaînes que sa réponse doit contenir ou ne doit pas contenir, et [`PromptCorpusTests`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Tests/Apps/GaChatbot.Api.Tests/Corpus/PromptCorpusTests.cs) envoie chacune d'elles à GaChatbot.Api et vérifie la réponse. Le test se présente lui-même comme « the safety net under ongoing skill refactors », le filet de sécurité tendu sous les refactorisations de skills en cours, et comme « the oracle for the autonomous improvement loop », l'oracle de la boucle d'amélioration autonome ; le workflow [`chatbot-qa-snapshot.yml`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.github/workflows/chatbot-qa-snapshot.yml#L43) l'exécute chaque jour à 6 h UTC. Cette leçon exécute le corpus sans modèle, comme le cours exécute tout, puis teste le test : que doit rater une réponse pour que la barrière s'en aperçoive ?

Tous les liens vers GA pointent sur le commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), le commit épinglé du cours. Sur le `main` de GA au commit [`fc76ad6`](https://github.com/GuitarAlchemist/ga/commit/fc76ad63cb70073330b6868d6e3c39307c5e262c), vérifié le 2026-09-29, `PromptCorpusTests.cs` et les skills que cite cette leçon sont inchangés ; le corpus est passé de 68 prompts à 75, et les entrées que cite la leçon sont les mêmes. Les sorties viennent de :

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l8
```

## La barrière

Une entrée nomme la question, l'intention qui doit y répondre, et les chaînes :

```yaml
  - prompt: "What notes are in a G7 chord"
    category: chord-tones
    routes_to: skill.chordinfo
    contains: ["G", "B", "D", "F"]
    not_contains: ["Mixolydian", "solo over", "scale has"]
    min_length: 25
    max_elapsed_ms: 20000
    retry: 0
```

`EvaluatePromptAsync` les vérifie dans un ordre fixe : une réponse vide, les marqueurs de backend dégradé, la longueur minimale, huit phrases interdites dans toutes les réponses, puis `not_contains`, `contains` et `contains_any`, et pour finir la route, l'ancrage et la forme de la trace ([lignes 313-484](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Tests/Apps/GaChatbot.Api.Tests/Corpus/PromptCorpusTests.cs#L313-L484)). Chaque chaîne est cherchée de la même façon ([lignes 367-379](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Tests/Apps/GaChatbot.Api.Tests/Corpus/PromptCorpusTests.cs#L367-L379)) :

```csharp
        if (entry.Contains is not null)
        {
            foreach (var must in entry.Contains)
                if (!answer.Contains(must, StringComparison.OrdinalIgnoreCase))
                    return ($"{label} → missing required substring: \"{must}\"", null);
        }

        if (entry.ContainsAny is not null && entry.ContainsAny.Count > 0)
        {
            var hit = entry.ContainsAny.Any(s => answer.Contains(s, StringComparison.OrdinalIgnoreCase));
            if (!hit)
                return ($"{label} → none of contains_any matched: [{string.Join(", ", entry.ContainsAny)}]", null);
        }
```

Une sous-chaîne, et la casse ne compte pas. GA connaît la limite : le commentaire du test à juge dit que les invariants de sous-chaîne « stay green even when the chat model is replaced with a bogus one (measured: 50 of 52 still passed) », restent verts même quand le modèle de chat est remplacé par un faux (mesuré : 50 sur 52 passaient encore), et les trois prompts dont la réponse est de la prose portent à la place une grille d'évaluation destinée à un modèle juge ([lignes 204-210](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Tests/Apps/GaChatbot.Api.Tests/Corpus/PromptCorpusTests.cs#L204-L210)). Les marqueurs de backend dégradé ont eux aussi une histoire : pendant un mois, l'instantané quotidien a publié un taux de réussite de 7.69 % pour un chatbot qui obtenait 98.08 % avec un modèle, parce que les réponses d'un backend privé de modèle échouaient comme de simples écarts ([lignes 54-75](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Tests/Apps/GaChatbot.Api.Tests/Corpus/PromptCorpusTests.cs#L54-L75)). Depuis, une réponse qui contient l'une de deux phrases, « The chatbot can't serve a request right now » ou « right now. Please try again. », compte comme « no signal », une absence de signal, et non comme un échec.

## Sans modèle

Le corpus ne fait pas partie du clone clairsemé du cours : [`fetch-ga.sh`](https://github.com/spareilleux/learn/blob/main/code/ga-ai/fetch-ga.sh) l'extrait donc du clone avec `git show`, comme il le fait pour les fichiers de #749 à la leçon 7. `Lesson8.cs` le lit avec YamlDotNet et les mêmes réglages que le test, et porte ligne à ligne les vérifications de texte dans `Evaluate`.

Sans modèle, le routeur d'intentions ne peut pas calculer l'embedding d'une question, et la leçon 4 a montré où cela mène : HTTP 500. Un prompt qui nomme son intention dans `routes_to` est donc envoyé directement à cette intention, par l'`IIntent` enregistré sous cet identifiant, et les autres vont à `POST /api/chatbot/chat`. Pour un appel direct, les vérifications de route, d'ancrage et de trace ne s'appliquent pas ; celles du texte, si.

La préparation de cette leçon a révélé deux lacunes dans l'hôte du cours lui-même :

- **Le dossier `skills/` de GA manquait.** [`SkillMdPlugin.ResolveSkillsPath`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Plugins/SkillMdPlugin.cs#L113-L151) le cherche à la racine du dépôt git qui contient le programme en cours d'exécution. En remontant depuis le programme du cours, le premier `.git` rencontré est celui du dépôt du cours, pas celui du clone. Le cours récupère maintenant `skills/` et fait pointer `SKILLMD_SKILLS_PATH` sur la copie du clone ; la méthode n'accepte cette surcharge qu'à l'intérieur du dépôt qu'elle a trouvé, et le clone se trouve dans le dépôt du cours. Les sorties des leçons 1 à 7 restent les mêmes avec ce changement.
- **Une clé présente dans l'environnement aurait été utilisée.** Les skills qui suivent un SKILL.md appellent l'API d'Anthropic dès qu'ils trouvent une clé, dans la configuration ou dans `ANTHROPIC_API_KEY` ([`AnthropicProvider.cs` lignes 113-114](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Providers.Anthropic/AnthropicProvider.cs#L113-L114)). Lancé avec une fausse clé, l'hôte de cette leçon a envoyé la requête et reçu `AnthropicUnauthorizedException`. L'hôte du cours fixe maintenant `Anthropic:ApiKey` à une chaîne vide, que le fournisseur lit en premier.

```text
== GA's prompt corpus at a826864 (Tests/Apps/GaChatbot.Api.Tests/Corpus/prompts.yaml)
prompts 68, skipped 5, with a judge rubric 3, naming the intent that must answer 39
expected strings 224, of one character 84

== Each prompt without a model, checked as PromptCorpusTests checks it
#   prompt                                         answered by                verdict
1   What are the modes of the major scale          skill.modes                pass
2   What are the modes of melodic minor            skill.modes                pass
3   What are the modes of harmonic minor           skill.modes                pass
4   What is Lydian dominant                        skill.modes                pass
5   Phrygian dominant                              skill.modes                pass
6   Tell me about Hijaz                            skill.modes                pass
7   What are the byzantine modes                   skill.modes                pass
8   Show me the notes in C major                   chat: HTTP 500
9   What is the relative minor of G major          chat: HTTP 500
10  What are the diatonic chords in G major        skill.diatonicchords       too short (65 < 100 chars)
11  What are the diatonic chords in D major        skill.diatonicchords       too short (65 < 100 chars)
12  Explain the circle of fifths                   chat: HTTP 500
13  What is the difference between major and min…  chat: HTTP 500
14  why does F sound outside over Cmaj7            skill.outsidenotes         pass
15  is A a tension or a chord tone over Cmaj7      skill.outsidenotes         pass
16  Transpose C E G to D                           chat: HTTP 500
17  What are the common tones between Cmaj7 and …  chat: HTTP 500
18  Are 0146 and 0137 z-related                    chat: algebra              pass
19  Identify the key of Am F C G                   chat: HTTP 500
20  Suggest substitutions for G7 in a ii-V-I       chat: HTTP 500
21  give me a ii-V-I progression in Bb             skill.diatonicchords       missing "Cm"
22  ii-V-I in Bb                                   skill.diatonicchords       missing "Cm"
23  Show me some easy beginner chords              chat: HTTP 500
24  List atonal modal families                     skill.modes                pass
25  What is the interval class vector of C E G     chat: HTTP 500
26  modes of melodi minor                          skill.modes                pass
27  diatnic chords in G major                      chat: HTTP 500
28  What is dorian                                 skill.modes                pass
29  tell me about phrygian                         skill.modes                pass
30  notes in c major                               skill.scaleinfo            pass
31  DIATONIC CHORDS IN G MAJOR                     skill.diatonicchords       pass
32  What is the relative major of A minor          chat: HTTP 500
33  What is the parallel minor of C major          chat: HTTP 500
34  Diatonic chords in F major                     skill.diatonicchords       too short (65 < 80 chars)
35  Diatonic chords in A minor                     skill.diatonicchords       too short (65 < 80 chars)
36  What is the altered scale                      skill.modes                pass
37  What is Hungarian minor                        skill.modes                pass
38  What is the whole tone scale                   skill.modes                pass
39  What is the diminished scale                   skill.modes                pass
40  What is Locrian                                skill.modes                pass
41  What is Mixolydian                             skill.modes                pass
42  What is Forte number 4-Z29                     chat: algebra              pass
43  List symmetric atonal families                 chat: HTTP 500
44  Transpose C major to E                         chat: HTTP 500
45  Common tones between G7 and Dm7                chat: HTTP 500
46  What key is Cm Ab Eb Bb in                     chat: HTTP 500
47  Show me a Cmaj9 chord                          skill.chordinfo            pass
48  What is C7b9                                   skill.chordinfo            pass
49  which arpeggio fits Am F C G                   skill.improvisation        pass
50  what arpeggios work over Dm7 G7 Cmaj7          skill.improvisation        pass
51  How do I tune to drop C                        skill.alternatetunings     pass
52  Give me a Cadd9 in DADGAD                      skipped
53  What's the easiest A minor in drop-D           skipped
54  Transpose this progression to capo 3           skipped
55  What's the smoothest voice leading from Cmaj…  skipped
56  What chord is C E G                            skill.chordinfo            pass
57  What chord is F A C E                          skill.chordinfo            pass
58  What chord is C E G Bb D                       skill.chordinfo            pass
59  What chord is D F A C E                        skill.chordinfo            pass
60  Transpose A minor to C minor                   chat: HTTP 500
61  Are pitch classes 0,1,4 and 0,1,6 equivalent…  chat: HTTP 500
62  What notes are in a G7 chord                   skill.chordinfo            pass
63  Explain why a tritone substitution works       chat: HTTP 500
64  What is the difference between a major seven…  chat: HTTP 500
65  Why does the Lydian mode sound brighter than…  chat: HTTP 500
66  What is the relative minor of E-flat major     skipped
67  What notes are in a C major triad              skill.chordinfo            pass
68  which notes form a B minor triad               skill.chordinfo            pass

68 prompts: 5 skipped, 22 end in an HTTP error, 41 answered: 35 pass, 6 fail, 0 of them flagged as a degraded backend
```

Les 22 erreurs HTTP sont l'échec de la leçon 4 : pas de `routes_to`, aucune garde qui attrape la question, et un repli qui a besoin du modèle. La garde d'algèbre en traite deux, #18 et #42, sans modèle. Des 39 prompts envoyés à une intention, les sept envoyés à `DiatonicChordsSkill` sont les seuls qui ont besoin d'un modèle : ils comptent pour les six échecs et pour l'une des réussites.

## Un skill qui a besoin d'un modèle

`DiatonicChordsSkill` est ce que GA appelle un skill Path B : un modèle lit [`skills/diatonic-chords/SKILL.md`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/diatonic-chords/SKILL.md) et doit calculer les accords en appelant l'outil `ga_dsl_eval` avec la closure `domain.diatonicChords`. Son client de chat vient toujours d'Anthropic, quel que soit le modèle qu'utilise le reste du chatbot ([`DefaultChatClientFactory.cs` lignes 45-49](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Extensions/DefaultChatClientFactory.cs#L45-L49)). Sans clé, la création du client lève une exception :

```text
== #10 What are the diatonic chords in G major: the intent's answer and the skills' log lines
  | I encountered an error processing your request. Please try again.
Error SkillMdDrivenSkill: SkillMdDrivenSkill [diatonic-chords] failed — tools=15, message head="What are the diatonic chords in G major" (InvalidOperationException)
Warning DiatonicChordsSkill: DiatonicChordsSkill: LLM produced an answer without invoking ga_dsl_eval. Closure domain.diatonicChords should have been called. Evidence: (no exception)
```

Deux couches traitent l'échec, et elles ne s'accordent pas sur ce qui s'est passé :

- Le [`SkillMdDrivenSkill`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SkillMdDrivenSkill.cs#L204-L226) intérieur intercepte l'exception, la journalise, et renvoie « I encountered an error processing your request. Please try again. » (une erreur s'est produite pendant le traitement de votre demande, veuillez réessayer) avec une confiance de 0.
- L'enveloppe (*wrapper*), [`SkillMdDrivenWrapperBase`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SkillMdDrivenWrapperBase.cs#L98-L152), reçoit ce texte comme une réponse normale. Elle ne trouve aucun appel à `ga_dsl_eval` dans les preuves et journalise que le modèle « produced an answer », a produit une réponse, sans l'outil ; aucun modèle n'a pourtant été atteint. Son propre texte de dégradation, « I couldn't list the diatonic chords for that key right now. Please try again. », vient de son bloc catch, qui s'exécute quand la construction du skill intérieur échoue ou quand le skill intérieur lève une exception ([lignes 154-176](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SkillMdDrivenWrapperBase.cs#L154-L176)) ; ici, le skill intérieur a rendu la main normalement.

C'est pour ce texte de l'enveloppe que le marqueur de dégradation de GA a été écrit : le commentaire de `BackendDegradedMarkers` le cite comme source. Le texte intérieur n'est pas un marqueur : la barrière compte donc les sept prompts comme six échecs et une réussite, au lieu de sept « no signal ». Avant que le cours ne récupère `skills/`, la construction du skill intérieur échouait faute de SKILL.md, le bloc catch de l'enveloppe renvoyait son propre texte, et les sept étaient signalés comme dégradés ; avec le fichier en place, le détecteur les rate. Le workflow quotidien de GA fournit un point d'accès Ollama et aucune clé Anthropic : ses exécutions devraient donc prendre le même chemin pour ces prompts (*à vérifier* : les instantanés du 2026-09-25 au 2026-09-29 sont tous marqués dégradés, et aucun ne détaille ses échecs prompt par prompt).

## Ce que prouve une réussite

Le commentaire de GA dit ce que les invariants ne voient pas : la qualité. Le cours mesure ce qu'ils voient bel et bien, avec deux tests de la barrière elle-même :

- **Les autres réponses.** Chaque prompt qui passe voit ses invariants appliqués aux 31 autres réponses distinctes de l'exécution. Une réponse à une autre question n'est pas toujours fausse pour celle-ci, mais un invariant qui en accepte beaucoup dit peu de chose de la sienne.
- **Un demi-ton plus haut.** Quand le prompt nomme une note ou un accord, sa réponse est vérifiée une seconde fois, avec chaque nom de note et chaque fondamentale d'accord montés d'un demi-ton : `Cmaj7` devient `C#maj7`, `Bb` devient `B`. On obtient une réponse sur une autre hauteur, fausse pour la question posée. Pour un prompt qui ne nomme aucune hauteur, comme « What is Dorian », la réponse transposée serait encore juste, et la colonne affiche n/a. Le cours ne reconnaît un nom de note dans la question que s'il commence par une majuscule, parce que « a » est aussi un mot anglais : #30, « notes in c major », nomme C majeur en minuscules et obtient n/a, un raté du test du cours.

```text
== GA's invariants applied to the other answers, and to the same answer a semitone higher
#   prompt                                     other answers pass         a semitone higher
1   What are the modes of the major scale      0 of 31                    n/a
2   What are the modes of melodic minor        0 of 31                    n/a
3   What are the modes of harmonic minor       0 of 31                    n/a
4   What is Lydian dominant                    1 of 31 (#1)               n/a
5   Phrygian dominant                          1 of 31 (#3)               n/a
6   Tell me about Hijaz                        1 of 31 (#3)               n/a
7   What are the byzantine modes               1 of 31 (#37)              n/a
14  why does F sound outside over Cmaj7        0 of 31                    pass
15  is A a tension or a chord tone over Cmaj7  3 of 31 (#49, #50, #51)    pass
18  Are 0146 and 0137 z-related                0 of 31                    n/a
24  List atonal modal families                 0 of 31                    n/a
26  modes of melodi minor                      5 of 31 (#2, #3, #4, …)    n/a
28  What is dorian                             4 of 31 (#1, #2, #3, …)    n/a
29  tell me about phrygian                     3 of 31 (#1, #3, #5)       n/a
30  notes in c major                           21 of 31 (#1, #2, #3, …)   n/a
31  DIATONIC CHORDS IN G MAJOR                 21 of 31 (#1, #2, #3, …)   pass
36  What is the altered scale                  1 of 31 (#2)               n/a
37  What is Hungarian minor                    0 of 31                    n/a
38  What is the whole tone scale               1 of 31 (#24)              n/a
39  What is the diminished scale               1 of 31 (#24)              n/a
40  What is Locrian                            3 of 31 (#1, #2, #3)       n/a
41  What is Mixolydian                         3 of 31 (#1, #2, #50)      n/a
42  What is Forte number 4-Z29                 1 of 31 (#18)              n/a
47  Show me a Cmaj9 chord                      23 of 31 (#1, #2, #3, …)   missing "E"
48  What is C7b9                               8 of 31 (#1, #2, #3, …)    missing "E"
49  which arpeggio fits Am F C G               5 of 31 (#1, #2, #3, …)    pass
50  what arpeggios work over Dm7 G7 Cmaj7      6 of 31 (#1, #2, #3, …)    pass
51  How do I tune to drop C                    1 of 31 (#14)              pass
56  What chord is C E G                        7 of 31 (#1, #2, #3, …)    missing "C major"
57  What chord is F A C E                      0 of 31                    missing "F major 7"
58  What chord is C E G Bb D                   0 of 31                    missing "C dominant 9"
59  What chord is D F A C E                    0 of 31                    missing "D minor 9"
62  What notes are in a G7 chord               17 of 31 (#3, #4, #5, …)   missing "B"
67  What notes are in a C major triad          24 of 31 (#1, #2, #3, …)   missing "E"
68  which notes form a B minor triad           7 of 31 (#1, #2, #3, …)    missing "B"

35 passing prompts; other answers accepted: 169; accepted a semitone higher: 6 of 15 that name a pitch
```

Certaines acceptations sont justifiées. Hijaz, un maqam de la musique arabe, est généralement approché, en tempérament égal à douze notes, par la gamme que les ouvrages occidentaux appellent phrygien dominant, et la famille de la mineure harmonique, la réponse #3, la liste. La plupart ne le sont pas. « What notes are in a C major triad » accepte 24 des 31 autres réponses, et « What notes are in a G7 chord » 17, parce que leurs listes `contains` sont des lettres de notes, et qu'un `"E"` insensible à la casse se trouve dans « the », un `"D"` dans « and » et un `"F"` dans « of ». 84 des 224 chaînes attendues du corpus ne font qu'un caractère, et 81 d'entre elles sont des lettres de notes.

La colonne du demi-ton dit la même chose, vue de l'autre côté. Les réponses de #56 à #59 échouent parce que leurs invariants contiennent un nom d'accord, de « C major » à « D minor 9 ». Les autres échouent par un hasard d'orthographe : transposée, la réponse sur G7 devient « G# dominant 7 chord contains G#, C, D#, and F# », et elle n'échoue que parce qu'aucun de ses mots ne contient de `b`. Et #51 passe :

```text
== #51 How do I tune to drop C, the answer a semitone higher: GA pass, strict missing "C"
  | **Drop C# tuning** (low → high): **C# – G# – C# – F# – A# – D#**
  |
  | | String | Note | vs Standard |
```

`"C"` est dans `C#`, et `"Drop C"` dans `Drop C#`. Quatre autres passent un demi-ton plus haut parce que leurs invariants ne nomment aucune hauteur : « avoid » et « 11 » pour #14, une tension ou un 13 pour #15, et « Aeolian » ou « arpeggio » pour les deux prompts d'arpèges. Le message d'erreur de #31 n'a aucune note à transposer.

## Des réponses que la barrière accepte

Cinq des réponses qui ont passé, avec la chaîne qui a laissé passer chacune. Les trois premières sont des réponses fausses. Les deux dernières donnent les bonnes notes avec une formule fausse, et la barrière ne lit que le nom de la gamme.

```text
== #26 modes of melodi minor: pass
  | The **Major Scale** family has 7 modes:
  |
  | 1. **Ionian** — on C: `C D E F G A B` — characteristic: `2`, `3`, `6`, `7`
  | 2. **Dorian** — on C: `C D Eb F G A Bb` — characteristic: `2`, `b3`, `6`, `b7`
  | 3. **Phrygian** — on C: `C Db Eb F G Ab Bb` — characteristic: `b2`, `b3`, `b6`, `b7`
  | 4. **Lydian** — on C: `C D E F# G A B` — characteristic: `#4`, `2`, `3`, `6`, `7`
  | … 5 more lines
"Melodic Minor" matches "melodic minor" on line 11
```

Le prompt se trouve dans la catégorie `typo-tolerance` du corpus, sous le commentaire « Real users misspell. The router should still get them home. » : les vrais utilisateurs font des fautes de frappe, et le routeur doit quand même les ramener à bon port. `ModesSkill` ne reconnaît pas « melodi minor » : il prend donc sa branche par défaut et liste les modes de la gamme majeure, sans dire qu'il n'a pas reconnu la famille ([`ModesSkill.cs` lignes 202-207](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ModesSkill.cs#L202-L207)). Chaque réponse sur une famille se termine par la même suggestion, « Ask about a specific family ("modes of melodic minor", "harmonic major modes") or a single mode ("what is Lydian dominant?") » ([ligne 449](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ModesSkill.cs#L449)), et c'est cette ligne qui satisfait le `contains_any` de l'entrée ([`prompts.yaml` lignes 270-276](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Tests/Apps/GaChatbot.Api.Tests/Corpus/prompts.yaml#L270-L276)).

```text
== #31 DIATONIC CHORDS IN G MAJOR: pass
  | I encountered an error processing your request. Please try again.
"G" matches "processing" on line 1
```

Le texte d'erreur de la section « Un skill qui a besoin d'un modèle », accepté comme les accords diatoniques de G majeur ([lignes 316-322](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Tests/Apps/GaChatbot.Api.Tests/Corpus/prompts.yaml#L316-L322)).

```text
== #49 which arpeggio fits Am F C G: pass
  | Over **Am – F – C – G**, for each chord:
  |
  | - **Am** → arpeggio **Am**, play **A Aeolian (natural minor)** (diatonic minor — fits most i chords).
  | - **F** → arpeggio **F**, play **F Ionian (major)** (diatonic, includes the 7 — careful on the IV chord).
  | - **C** → arpeggio **C**, play **C Ionian (major)** (diatonic, includes the 7 — careful on the IV chord).
  | - **G** → arpeggio **G**, play **G Ionian (major)** (diatonic, includes the 7 — careful on the IV chord).
  | … 2 more lines
"Aeolian" matches "Aeolian" on line 3
```

La réponse aveugle à la tonalité de la [leçon 5](../05-improvisation-skill/) et du ticket de GA [#744](https://github.com/GuitarAlchemist/ga/issues/744) : F ionien contient un B♭ et G ionien un F♯, et aucune de ces deux notes n'est dans la tonalité de la progression, A mineur ou C majeur. L'entrée accepterait aussi « arpeggio », un mot de la question. Sur `main`, le corpus a gagné depuis une entrée pour « which arpeggio fits C A Dm G » avec `not_contains: ["A Aeolian"]`, écrite après le tracer du 2026-09-28 à l'origine de #744 : une chaîne que contient une réponse fausse fait une vérification plus fine qu'une chaîne que devrait contenir une réponse juste.

```text
== #38 What is the whole tone scale: pass
  | **Whole Tone** is mode 1 of the **Whole Tone** family; on C its notes are `C D E F# G# Bb` (formula `1 2 3 #4 #5 #6`).
"Whole Tone" matches "Whole Tone" on line 1

== #39 What is the diminished scale: pass
  | **Diminished (Half-Whole)** is mode 1 of the **Diminished** family; on C its notes are `C Db Eb E F# G A Bb` (formula `1 b2 b3 b4 b5 bb6 bb7 bb8`).
"Diminished" matches "Diminished" on line 1
```

Rien ne vérifie que la formule concorde avec les notes ; l'exercice 4 s'en charge.

## Une lecture plus stricte

On peut lire les mêmes chaînes plus strictement, sans toucher au corpus. `StrictContains`, dans [`Lesson8.cs`](https://github.com/spareilleux/learn/blob/main/code/ga-ai/GaAi/Lesson8.cs), applique deux règles : une chaîne qui commence par un nom de note, comme `G`, `F#`, `Bb`, `Cm` ou `C major`, doit correspondre avec la même casse ; et toute chaîne doit être isolée, sans lettre, chiffre ni altération accolés à l'une ou l'autre de ses extrémités : `"C"` ne correspond donc plus à `C#` ni à `Cmaj7`, et `"G"` ne correspond plus à « processing ».

```csharp
static bool StrictContains(string answer, string s)
{
    var comparison = NoteToken.IsMatch(s.Split(' ')[0]) ? StringComparison.Ordinal : StringComparison.OrdinalIgnoreCase;
    for (var i = answer.IndexOf(s, comparison); i >= 0; i = answer.IndexOf(s, i + 1, comparison))
    {
        var end = i + s.Length;
        if ((i == 0 || !IsTokenChar(answer[i - 1])) && (end == answer.Length || !IsTokenChar(answer[end])))
            return true;
    }
    return false;
}
```

```text
== The same invariants, read strictly: each prompt's own answer
#31 DIATONIC CHORDS IN G MAJOR: GA pass, strict none of contains_any

== The strict reading applied to the other answers, and to the same answer a semitone higher
#   prompt                                     other answers pass         a semitone higher
1   What are the modes of the major scale      0 of 31                    n/a
2   What are the modes of melodic minor        0 of 31                    n/a
3   What are the modes of harmonic minor       0 of 31                    n/a
4   What is Lydian dominant                    1 of 31 (#1)               n/a
5   Phrygian dominant                          1 of 31 (#3)               n/a
6   Tell me about Hijaz                        1 of 31 (#3)               n/a
7   What are the byzantine modes               1 of 31 (#37)              n/a
14  why does F sound outside over Cmaj7        0 of 31                    pass
15  is A a tension or a chord tone over Cmaj7  1 of 31 (#51)              pass
18  Are 0146 and 0137 z-related                0 of 31                    n/a
24  List atonal modal families                 0 of 31                    n/a
26  modes of melodi minor                      5 of 31 (#2, #3, #4, …)    n/a
28  What is dorian                             4 of 31 (#1, #2, #3, …)    n/a
29  tell me about phrygian                     3 of 31 (#1, #3, #5)       n/a
30  notes in c major                           3 of 31 (#1, #2, #3)       n/a
36  What is the altered scale                  1 of 31 (#2)               n/a
37  What is Hungarian minor                    0 of 31                    n/a
38  What is the whole tone scale               1 of 31 (#24)              n/a
39  What is the diminished scale               1 of 31 (#24)              n/a
40  What is Locrian                            3 of 31 (#1, #2, #3)       n/a
41  What is Mixolydian                         3 of 31 (#1, #2, #50)      n/a
42  What is Forte number 4-Z29                 1 of 31 (#18)              n/a
47  Show me a Cmaj9 chord                      4 of 31 (#1, #2, #3, …)    missing "E"
48  What is C7b9                               5 of 31 (#1, #2, #3, …)    missing "C"
49  which arpeggio fits Am F C G               5 of 31 (#1, #2, #3, …)    pass
50  what arpeggios work over Dm7 G7 Cmaj7      6 of 31 (#1, #2, #3, …)    pass
51  How do I tune to drop C                    0 of 31                    missing "C"
56  What chord is C E G                        2 of 31 (#30, #47)         missing "C major"
57  What chord is F A C E                      0 of 31                    missing "F major 7"
58  What chord is C E G Bb D                   0 of 31                    missing "C dominant 9"
59  What chord is D F A C E                    0 of 31                    missing "D minor 9"
62  What notes are in a G7 chord               1 of 31 (#3)               missing "G"
67  What notes are in a C major triad          12 of 31 (#1, #2, #3, …)   missing "C"
68  which notes form a B minor triad           4 of 31 (#1, #2, #3, …)    missing "B"

34 passing prompts; other answers accepted: 69; accepted a semitone higher: 4 of 14 that name a pitch
```

La lecture stricte change un seul verdict sur les réponses de l'exécution elles-mêmes, celui du message d'erreur de #31, et ce changement est justifié. Les réponses étrangères qu'elle accepte tombent de 169 à 69, et #51, transposé d'un demi-ton, échoue maintenant pour la bonne raison : aucun `C` n'y est isolé. Le prompt sur G7 accepte une réponse au lieu de 17 : celle sur la famille de la mineure harmonique, dont les notes comprennent G, B, D et F.

Ce qu'elle ne peut pas faire, c'est lire ce que les invariants ne nomment pas. #14, #15, #49 et #50 passent encore un demi-ton plus haut, et #26 accepte toujours la mauvaise famille, parce que leurs chaînes ne contiennent aucune hauteur qui manquerait à une réponse fausse. #67 accepte encore 12 réponses : C, E et G sont isolés dans n'importe quelle liste des notes de C majeur. Un invariant qui vérifie les notes d'un accord doit comparer des ensembles, « la réponse nomme exactement C, E et G », ce que des vérifications de sous-chaînes ne savent pas exprimer. Et une lecture stricte a ses propres faux échecs : « tension » ne correspond plus à « tensions ». Aucun ne s'est produit dans cette exécution, ce qui est un fait sur 41 réponses, pas une garantie.

## Où le cours s'arrête

- **Le routage n'est pas testé.** Le cours appelle chaque intention directement : `routes_to`, `routing_method`, l'ancrage et les vérifications de trace, la moitié de la barrière qui attrape les erreurs de routage, ne sont donc pas mis à l'épreuve. Pas plus que les 22 prompts qui ont besoin du routeur ou d'un modèle, dont les trois prompts notés par un juge.
- **Le test du demi-ton ne couvre qu'une sorte de réponse fausse.** Il laisse les mots tranquilles et déplace les hauteurs ; il ne dit rien d'une réponse qui nomme les bonnes notes et en tire la mauvaise conclusion.
- **« Les autres réponses » mesure la spécificité d'un invariant, pas la justesse d'une réponse.** Une réponse étrangère acceptée peut être acceptable, comme pour Hijaz.
- **La lecture stricte est une proposition du cours**, mesurée sur cette seule exécution. L'adopter demanderait une modification dans `EvaluatePromptAsync` et une relecture des 224 chaînes du corpus.

## Signalé en amont

- Pas encore signalés en amont au moment de l'écriture de cette leçon : le détecteur de dégradation qui rate l'erreur d'un skill Path B, la ligne de journal trompeuse de l'enveloppe, la faute de frappe qui reçoit en silence la gamme majeure, les formules positionnelles de #38 et #39, et les sous-chaînes insensibles à la casse. Ils sont listés dans le [journal](../journal/).

## Exercices

1. Ajoute « I encountered an error processing your request » à `BackendDegradedMarkers` dans le portage du cours. Qu'affiche la ligne de résumé du premier tableau, et que devient #31 ?
2. Réécris les invariants de #26 pour que la réponse sur la gamme majeure échoue et que celle sur la famille de la mineure mélodique, la réponse #2, passe. Quelles autres réponses ta version accepte-t-elle ?
3. Le prompt #61 demande « Are pitch classes 0,1,4 and 0,1,6 equivalent under inversion », les classes de hauteurs 0,1,4 et 0,1,6 sont-elles équivalentes par inversion ? Réponds-y, puis dis quelles chaînes de son `contains_any`, `["yes", "no", "Z", "equivalent", "inversion", "transposition", "different", "same", "related"]`, une réponse fausse satisferait.
4. Compare les formules de #38 et #39 à leurs notes, lettre par lettre. Quels degrés ne concordent pas, et quelle formule rend les notes de chaque gamme telles qu'elles sont écrites ? Lis [`ComputeFormulaFromNotes`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ModesSkill.cs#L779-L811) et dis pourquoi elle se trompe sur ces deux gammes.

<details>
<summary>Solutions</summary>

1. `68 prompts: 5 skipped, 22 end in an HTTP error, 41 answered: 34 pass, 7 fail, 7 of them flagged as a degraded backend`. Les sept prompts d'accords diatoniques, #31 compris, deviennent `BACKEND_DEGRADED`, et l'exécution les compte comme « no signal » au lieu de six échecs et une réussite. Vérifié avec le programme du cours le 2026-09-29, en ajoutant le marqueur le temps d'une exécution.
2. `contains: ["Melodic Minor", "Lydian Dominant", "Altered"]`, les chaînes de #2, toutes exigées. La ligne de suggestion nomme les deux premières mais pas la gamme altérée : la réponse sur la gamme majeure échoue donc avec `missing "Altered"`, et la réponse de #2 passe. Des autres réponses de l'exécution, seule celle de #2 passe. Vérifié avec le programme du cours le 2026-09-29, en remplaçant l'entrée le temps d'une exécution. Une lecture stricte n'aiderait pas ici : la ligne de suggestion contient « melodic minor » en mots entiers.
3. Non. L'inversion de {0,1,4} est {0,11,8}, qui se transpose en {0,3,4} ; ni elle ni {0,1,4} n'est une transposition de {0,1,6}. Les deux ensembles appartiennent à des classes d'ensembles différentes, 3-3 (014) et 3-5 (016) dans la liste de Forte, avec les vecteurs d'intervalles <101100> et <100011>. Une réponse fausse, « Yes, they are equivalent », satisfait « yes » et « equivalent », et « no » se trouve dans « not », « note » et « know » : n'importe quelle réponse qui atteint le `min_length` de l'entrée, 50 caractères, a donc de bonnes chances de passer. Résolu à la main : sans modèle, le prompt finit en HTTP 500, et le cours n'a donc aucune réponse à vérifier.
4. #38 : `#6` est A♯, et la note est B♭ ; les notes telles qu'elles sont écrites donnent `1 2 3 #4 #5 b7`. #39 : `b4` est F♭ là où la note est E, `b5` G♭ là où elle est F♯, `bb6` A𝄫 là où elle est G, `bb7` B𝄫 là où elle est A, et `bb8`, un degré que personne n'écrit, C𝄫 là où elle est B♭. Les classes de hauteurs concordent toutes ; les lettres, non. Les notes telles qu'elles sont écrites donnent `1 b2 b3 3 #4 5 6 b7` ; les textes de jazz écrivent généralement le E♭ sous la forme D♯, `1 b2 #2 3 #4 5 6 b7`, la formule qu'utilise l'oracle de la leçon 5. `ComputeFormulaFromNotes` compare la i-ième note au i-ième degré de C majeur, par position : cela fonctionne pour une gamme de sept notes écrite sur sept lettres, et donne de faux numéros de degrés à une gamme de six ou huit notes. Dériver chaque degré de la lettre de la note donnerait les formules ci-dessus. Résolu à la main à partir de la sortie et du code de la méthode ; non compilé contre GA (*à vérifier*).

</details>

## À retenir

- Une suite de tests est elle-même une affirmation sur le programme, et on peut la tester : appliquer ses vérifications à des réponses pour lesquelles elles n'ont pas été écrites, et à des réponses fausses exprès, puis compter ce qui passe.
- Le corpus de GA vérifie des sous-chaînes insensibles à la casse. Plus d'un tiers de ses chaînes attendues ne font qu'un caractère, des lettres de notes pour l'essentiel, que contiennent la plupart des phrases anglaises ; ses invariants ont accepté 169 réponses étrangères, un message d'erreur et la mauvaise famille de modes.
- Une réponse sur une autre hauteur passe quand les invariants ne contiennent aucune hauteur, ou en contiennent une qui est une sous-chaîne d'une autre : « C » est dans « C# ».
- Une dégradation en douceur doit être reconnue par la barrière. Sans modèle, un skill Path B répond avec un texte que les marqueurs de dégradation de GA ne connaissent pas : ses échecs sont donc comptés comme ceux du chatbot.
- Lire les mêmes chaînes comme des éléments isolés, en respectant la casse des noms de notes, ramène les réponses étrangères acceptées à 69 sans changer ici aucun verdict juste. Ce que les sous-chaînes ne savent pas exprimer, comme « exactement ces notes », demande une vérification qui analyse la réponse.

## Sources

- GuitarAlchemist/ga au commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) : `Tests/Apps/GaChatbot.Api.Tests/Corpus/prompts.yaml`, `Tests/Apps/GaChatbot.Api.Tests/Corpus/PromptCorpusTests.cs`, `.github/workflows/chatbot-qa-snapshot.yml`, `Common/GA.Business.ML/Agents/Skills/ModesSkill.cs`, `SkillMdDrivenSkill.cs`, `SkillMdDrivenWrapperBase.cs`, `DiatonicChordsSkill.cs`, `Common/GA.Business.ML/Agents/Plugins/SkillMdPlugin.cs`, `Common/GA.Business.ML/Extensions/DefaultChatClientFactory.cs`, `Common/GA.Providers.Anthropic/AnthropicProvider.cs`.
- Le `main` de GA au commit [`fc76ad6`](https://github.com/GuitarAlchemist/ga/commit/fc76ad63cb70073330b6868d6e3c39307c5e262c) (2026-09-29) : les nouvelles entrées du corpus, dont « which arpeggio fits C A Dm G », ajoutée par le commit [`503d70d`](https://github.com/GuitarAlchemist/ga/commit/503d70d3bed961e71fa82c35dd35066a301040d5) ; l'instantané `state/quality/chatbot-qa/2026-09-29.json`.
- Allen Forte, *The Structure of Atonal Music* (Yale University Press, 1973), pour les noms des classes d'ensembles de l'exercice 3.
