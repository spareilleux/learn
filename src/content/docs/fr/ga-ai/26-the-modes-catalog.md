---
title: "Leçon 26 : le catalogue des modes"
description: "Le ModesSkill de Guitar Alchemist répond aux questions sur les modes à partir de Modes.yaml, sans modèle. 36 des 129 modes dont il se sert ne sont pas la gamme de leur famille jouée depuis leur degré, 8 noms sont coupés à un dièse que YAML lit comme un commentaire, 10 modes sont inaccessibles par leur propre nom, et la formule qu'il calcule par position n'est celle d'un manuel que pour 65 d'entre eux."
sidebar:
  label: 26. Le catalogue des modes
  order: 26
---

La [leçon 8](../08-the-chatbots-own-exam/) a croisé `ModesSkill` au détour d'un prompt du corpus de GA, et trouvé ses formules numérotées par position sur deux gammes, ce qu'a signalé le ticket de GA [#765](https://github.com/GuitarAlchemist/ga/issues/765). Le skill affirme ne contenir aucune théorie musicale à lui : « Zero hardcoded music-theory content — the skill is a thin adapter that classifies the query, calls the domain, and formats the result » ([`ModesSkill.cs`, lignes 8-16](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ModesSkill.cs#L8-L16)). Le domaine, c'est `Modes.yaml`, lu par `ModesConfig`. Cette leçon vérifie donc le catalogue lui-même, mode par mode, puis ce que le skill en fait. Elle n'a besoin d'aucun modèle : le skill est déterministe.

Tous les liens vers GA pointent sur le commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), celui qu'épingle le cours. Sur le `main` de GA, à [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01), `ModesSkill.cs`, `Modes.yaml`, `ModesConfig.fs`, `AtonalModalFamiliesConfig.fs` et `skills/modes/SKILL.md` sont les mêmes fichiers, octet pour octet : le programme ne tourne donc qu'au commit épinglé. La sortie vient de :

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l26
```

## Comment le skill répond

`ExecuteAsync` essaie, dans l'ordre : le catalogue atonal, quand la question nomme un vecteur d'intervalles, un numéro de Forte ou des mots de l'atonalité ; une famille, quand la question demande ses modes ; un mode dont la question contient le nom ; une famille dont elle contient le nom ; un panorama de toutes les familles ; et, à défaut, les modes de la gamme majeure ([lignes 152-211](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ModesSkill.cs#L152-L211)). La réponse sur un mode dit de quelle famille il est le combientième mode, donne ses notes sur C telles que le catalogue les écrit, et ajoute une formule qu'il calcule à partir de ces notes :

```csharp
        var degree = family.Modes.ToList().FindIndex(m => m.Name == mode.Name) + 1;
        sb.Append($"**{mode.Name}** is mode {degree} of the **{StripFamilySuffix(family.Name)}** family");
        if (!string.IsNullOrWhiteSpace(mode.Notes))
        {
            sb.Append($"; on C its notes are `{mode.Notes}`");
            var formula = ComputeFormulaFromNotes(mode.Notes);
            if (!string.IsNullOrEmpty(formula))
                sb.Append($" (formula `{formula}`)");
        }
        sb.Append('.');
```

## Le catalogue face à un manuel

« Le mode 4 de la gamme majeure », c'est la gamme majeure jouée depuis son quatrième degré : sur C, les notes de F majeur de F à F, ramenées sur C. Le programme connaît, pour chacune des 26 familles, le premier mode d'un manuel (`Parents` dans `Lesson26.cs`), et compare chaque mode k d'une famille à son mode 1 joué depuis le degré k :

```text
== The families ModesSkill answers from, and whether mode k is the parent scale from its degree k
family                   modes  notes  mode 1     mode k on degree k  the modes that aren't
Major Scale              7      7      textbook   7 of 7              -
Harmonic Minor           7      7      textbook   6 of 7              7
Melodic Minor            7      7      textbook   7 of 7              -
Major Pentatonic         5      5      textbook   2 of 5              3, 4, 5
Whole Tone               1      6      textbook   1 of 1              -
Diminished               2      8      textbook   2 of 2              -
Blues Scale              1      6      textbook   1 of 1              -
Chromatic                1      12     textbook   1 of 1              -
Perfect Fourth           2      2      textbook   2 of 2              -
Major Third              2      2      textbook   2 of 2              -
Minor Third              2      2      textbook   2 of 2              -
Major Second             2      2      textbook   2 of 2              -
Minor Second             2      2      textbook   2 of 2              -
Harmonic Major           7      7      textbook   7 of 7              -
Double Harmonic          7      7      textbook   6 of 7              7
Neapolitan Minor         7      7      textbook   6 of 7              7
Neapolitan Major         7      7      textbook   3 of 7              4, 5, 6, 7
Dominant Bebop           8      8      textbook   5 of 8              6, 7, 8
Major Bebop              8      8      textbook   3 of 8              4, 5, 6, 7, 8
Prometheus               6      6      textbook   3 of 6              4, 5, 6
Enigmatic                7      7      textbook   2 of 7              3, 4, 5, 6, 7
Hungarian Major          7      7      textbook   1 of 7              2, 3, 4, 5, 6, 7
Hirajoshi                5      5      textbook   5 of 5              -
In Sen                   5      5      textbook   1 of 5              2, 3, 4, 5
Diminished (Octatonic)   8      8      textbook   8 of 8              -
Augmented (Hexatonic)    6      6      textbook   6 of 6              -
families 26; Modes.yaml's that the skill leaves out 5: Major Triad Family, Diminished Triad Family, Augmented Triad Family, Major Seventh Chord Family, All Interval Tetrachord Family
modes 129: mode 1 from their own degree 93, from another degree 2, from no degree 34; notes out of order 3
the modes that aren't:
  Harmonic Minor 7, Ultralocrian: C Db Eb Fb Gb Ab Bb; mode 1 from no degree; from degree 7: C Db Eb Fb Gb Ab Bbb
  Major Pentatonic 3, Blues Minor: C Eb F G Bb; mode 1 from degree 5
  Major Pentatonic 4, Blues Major: C E F A Bb; mode 1 from no degree; from degree 4: semitones 0 2 5 7 9
  Major Pentatonic 5, Minor Pentatonic: C D F G A; mode 1 from degree 4
  Double Harmonic 7, Locrian bb3 bb7: C Dbb Ebb F Gb Ab Bbb; mode 1 from no degree; from degree 7: C Db Ebb F Gb Ab Bbb
  Neapolitan Minor 7, Ultralocrian bb3: C Dbb Eb F Gb Ab Bbb; mode 1 from no degree; from degree 7: C Db Ebb Fb Gb Ab Bbb
  Neapolitan Major 4, Lydian Minor (Lydian b3 b7): C D Eb F# G A Bb; mode 1 from no degree; from degree 4: C D E F# G Ab Bb
  Neapolitan Major 5, Major Locrian: C D Eb F Gb Ab Bb; mode 1 from no degree; from degree 5: C D E F Gb Ab Bb
  Neapolitan Major 6, Altered Dominant n2 (Locrian n2 n7): C D Eb F Gb Ab B; mode 1 from no degree; from degree 6: C D Eb Fb Gb Ab Bb
  Neapolitan Major 7, Altered bb3: C Dbb Eb Fb Gb Ab Bb; mode 1 from no degree; from degree 7: C Db Ebb Fb Gb Ab Bb
  Dominant Bebop 6, Dominant Bebop Mode 6: C Db D Eb F G A Bb; mode 1 from no degree; from degree 6: semitones 0 1 2 3 5 7 8 10
  Dominant Bebop 7, Dominant Bebop Mode 7: C C# D E F G A B; mode 1 from no degree; from degree 7: semitones 0 1 2 4 6 7 9 11
  Dominant Bebop 8, Dominant Bebop Mode 8: C C# D# E F# G# A# B; mode 1 from no degree; from degree 8: semitones 0 1 3 5 6 8 10 11
  Major Bebop 4, Major Bebop Mode 4: C D Eb F G Ab A B; mode 1 from no degree; from degree 4: semitones 0 2 3 4 6 7 9 11
  Major Bebop 5, Major Bebop Mode 5: C Db Eb F Gb G Bb B; mode 1 from no degree; from degree 5: semitones 0 1 2 4 5 7 9 10
  Major Bebop 6, Major Bebop Mode 6: C D E F F# A Bb B; mode 1 from no degree; from degree 6: semitones 0 1 3 4 6 8 9 11
  Major Bebop 7, Major Bebop Mode 7: C D Eb E G Ab A Bb; mode 1 from no degree; from degree 7: semitones 0 2 3 5 7 8 10 11
  Major Bebop 8, Major Bebop Mode 8: C Db D F Gb G Ab B; mode 1 from no degree; from degree 8: semitones 0 1 3 5 6 8 9 10
  Prometheus 4, Prometheus Mode 4: C Eb E G A Bb; mode 1 from no degree; from degree 4: semitones 0 3 4 6 8 10
  Prometheus 5, Prometheus Mode 5: C C# E F# G# A; mode 1 from no degree; from degree 5: semitones 0 1 3 5 7 9
  Prometheus 6, Prometheus Mode 6: C D# F G G# B; mode 1 from no degree; from degree 6: semitones 0 2 4 6 8 11
  Enigmatic 3, Enigmatic Mode 3: C D E Gb G Ab Bb; mode 1 from no degree; from degree 3: C D E F# G Ab Bbb
  Enigmatic 4, Enigmatic Mode 4: C D E F Gb Ab B; mode 1 from no degree; from degree 4: C D E F Gb Abb Bb
  Enigmatic 5, Enigmatic Mode 5: C D Eb F G B Bb; mode 1 from no degree; from degree 5: C D Eb Fb Gbb Ab Bb; notes out of order
  Enigmatic 6, Enigmatic Mode 6: C Db Eb F A G# B; mode 1 from no degree; from degree 6: C Db Ebb Fbb Gb Ab Bb; notes out of order
  Enigmatic 7, Enigmatic Mode 7: C D E G# F# A# B; mode 1 from no degree; from degree 7: C Db Ebb F G A B; notes out of order
  Hungarian Major 2, Hungarian Major Mode 2: C Db Eb F Gb Ab A; mode 1 from no degree; from degree 2: C Db Eb Fb Gb Abb Bbb
  Hungarian Major 3, Hungarian Major Mode 3: C D E F G G# B; mode 1 from no degree; from degree 3: C D Eb F Gb Ab B
  Hungarian Major 4, Hungarian Major Mode 4: C D Eb F F# A Bb; mode 1 from no degree; from degree 4: C Db Eb Fb Gb A Bb
  Hungarian Major 5, Hungarian Major Mode 5: C Db Eb E G Ab Bb; mode 1 from no degree; from degree 5: C D Eb F G# A B
  Hungarian Major 6, Hungarian Major Mode 6: C D D# F# G A B; mode 1 from no degree; from degree 6: C Db Eb F# G A Bb
  Hungarian Major 7, Hungarian Major Mode 7: C C# E F G A Bb; mode 1 from no degree; from degree 7: C D E# F# G# A B
  In Sen 2, In Sen Mode 2: C E F Ab Bb; mode 1 from no degree; from degree 2: semitones 0 4 6 9 11
  In Sen 3, In Sen Mode 3: C Db F G A; mode 1 from no degree; from degree 3: semitones 0 2 5 7 8
  In Sen 4, In Sen Mode 4: C E F G B; mode 1 from no degree; from degree 4: semitones 0 3 5 6 10
  In Sen 5, In Sen Mode 5: C Db Eb G Ab; mode 1 from no degree; from degree 5: semitones 0 2 3 7 9
```

- **Le mode 1 est la gamme du manuel dans les 26 familles, mais 36 des autres modes ne sont pas le mode 1 joué depuis leur degré.** Deux sont le mode 1 joué depuis un autre degré : le « Blues Minor » de la pentatonique majeure (mode 3) part du degré 5, et son « Minor Pentatonic » (mode 5) du degré 4. Les 34 autres ne sont le mode 1 depuis aucun degré : leurs notes forment une autre gamme. Ce sont 4 des 7 modes de la napolitaine majeure, 8 des 16 des deux gammes bebop, 3 des 6 de la gamme de Prométhée, 5 des 7 de la gamme énigmatique, 6 des 7 de la hongroise majeure, 4 des 5 de l'In Sen, le « Blues Major » de la pentatonique majeure, et le septième mode de la mineure harmonique, de la double harmonique et de la napolitaine mineure.
- **L'Ultralocrien a les notes de la gamme altérée.** Le septième mode de la mineure harmonique a une septième diminuée, Bbb sur C ; le catalogue écrit Bb ([`Modes.yaml`, lignes 242-243](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/Modes.yaml#L242-L243)), ce qui donne les notes de la gamme altérée, le mode 7 de la mineure mélodique.
- **Trois septièmes modes n'ont pas de second degré.** « Locrian bb3 bb7 », « Ultralocrian bb3 » et « Altered bb3 » commencent par `C Dbb` : Dbb, c'est de nouveau C, et il manque le Db par lequel ces modes devraient continuer après C. La napolitaine mineure le montre, avec trois autres choses sur lesquelles la leçon reviendra :

```yaml
  - Name: Neapolitan Minor Family
    Modes:
      - Name: Neapolitan Minor
        Notes: C Db Eb F G Ab B
      - Name: Lydian #6
        Notes: C D E F# G A# B
      - Name: Mixolydian Augmented
        Notes: C D E F G# A Bb
      - Name: Aeolian #4 (Lydian Diminished)
        Notes: C D Eb F# G Ab Bb
      - Name: Locrian n3
        Notes: C Db E F Gb Ab Bb
      - Name: Ionian #2
        Notes: C D# E F G A B
      - Name: Ultralocrian bb3
        Notes: C Dbb Eb F Gb Ab Bbb
```

- **Le skill répond à partir de 26 des 31 familles du catalogue.** Il écarte les familles dont le nom contient « Chord Family » ou « Triad Family », pour que les accords ne se mêlent pas aux réponses sur les modes :

```csharp
    private static bool IsChordOrTriadFamilyName(string name) =>
        name.Contains("Chord Family", StringComparison.OrdinalIgnoreCase) ||
        name.Contains("Triad Family", StringComparison.OrdinalIgnoreCase);
```

  Son commentaire compte quatre familles de ce genre ([lignes 515-516](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ModesSkill.cs#L515-L516)) ; la cinquième est « All Interval Tetrachord Family », dont le nom contient « chord Family », et la comparaison ignore la casse.

## Les formules

Un manuel écrit la formule d'une gamme de sept notes avec chaque degré une fois : ses notes, dans l'ordre ascendant, sont 1 à 7, et le lydien s'écrit `1 2 3 #4 5 6 7`. Pour tout autre nombre de notes, chaque chiffre vient de la lettre de la note : la pentatonique majeure, C D E G A, s'écrit `1 2 3 5 6`. Le skill compare la i-ème note au i-ème degré de C majeur, en repartant de 1 après sept, et abandonne une altération qu'il ne sait pas écrire avec deux dièses ou deux bémols :

```csharp
        for (var i = 0; i < tokens.Length; i++)
        {
            if (!PitchSemitone.TryGetValue(tokens[i], out var semi))
                return string.Empty;  // unknown token — bail rather than guess
            // For scales of <=7 notes, position maps directly to degree slot.
            // For 8-note (Bebop) or longer scales, modulo 7 keeps the reference
            // sensible — the formula notation is still recognizable.
            var slot = i % 7;
            var expected = DegreeSemitones[slot];
            var diff = semi - expected;
            // Normalize across octave boundary for late notes in 8+-note scales.
            if (diff > 6) diff -= 12;
            if (diff < -6) diff += 12;
            var acc = diff switch
            {
                -2 => "bb",
                -1 => "b",
                  0 => "",
                  1 => "#",
                  2 => "##",
                  _ => string.Empty  // out of expected range — omit accidental rather than emit garbage
            };
            parts.Add($"{acc}{i + 1}");
        }
```

```text
== Each mode's formula: the one ModesSkill computes from the notes by position, and a textbook's
notes  modes  the skill's   the letters'    the first of the skill's that differs: notes, the skill's formula, a textbook's
2      10     2 right       -               Perfect Fourth: C F; `1 2`, `1 4`
5      15     0 right       -               Major Pentatonic: C D E G A; `1 2 3 ##4 ##5`, `1 2 3 5 6`
6      14     3 right       -               Whole Tone: C D E F# G# Bb; `1 2 3 #4 #5 #6`, `1 2 3 #4 #5 b7`
7      63     60 right      52 right        Enigmatic Mode 5: C D Eb F G B Bb; `1 2 b3 4 5 ##6 b7`, `1 2 b3 4 5 #6 7`
8      26     0 right       -               Diminished (Half-Whole): C Db Eb E F# G A Bb; `1 b2 b3 b4 b5 bb6 bb7 bb8`, `1 b2 b3 3 #4 5 6 b7`
12     1      0 right       -               Chromatic: C C# D D# E F F# G G# A A# B; `1 b2 bb3 bb4 5 6 7 8 9 10 11 12`, `1 #1 2 #2 3 4 #4 5 #5 6 #6 7`
modes 129: the skill's formula is a textbook's 65; of the 63 seven-note modes, a formula read from the letters would be 52
the seven-note modes whose letters give another formula than their degrees:
  Enigmatic Mode 2: C D# F G A Bb B; letters `1 #2 4 5 6 b7 7`, degrees `1 #2 #3 ##4 ##5 #6 7`
  Enigmatic Mode 3: C D E Gb G Ab Bb; letters `1 2 3 b5 5 b6 b7`, degrees `1 2 3 #4 5 b6 b7`
  Enigmatic Mode 5: C D Eb F G B Bb; letters `1 2 b3 4 5 7 b7`, degrees `1 2 b3 4 5 #6 7`
  Enigmatic Mode 6: C Db Eb F A G# B; letters `1 b2 b3 4 6 #5 7`, degrees `1 b2 b3 4 #5 6 7`
  Enigmatic Mode 7: C D E G# F# A# B; letters `1 2 3 #5 #4 #6 7`, degrees `1 2 3 #4 #5 #6 7`
  Hungarian Major Mode 2: C Db Eb F Gb Ab A; letters `1 b2 b3 4 b5 b6 6`, degrees `1 b2 b3 4 b5 b6 bb7`
  Hungarian Major Mode 3: C D E F G G# B; letters `1 2 3 4 5 #5 7`, degrees `1 2 3 4 5 b6 7`
  Hungarian Major Mode 4: C D Eb F F# A Bb; letters `1 2 b3 4 #4 6 b7`, degrees `1 2 b3 4 b5 6 b7`
  Hungarian Major Mode 5: C Db Eb E G Ab Bb; letters `1 b2 b3 3 5 b6 b7`, degrees `1 b2 b3 b4 5 b6 b7`
  Hungarian Major Mode 6: C D D# F# G A B; letters `1 2 #2 #4 5 6 7`, degrees `1 2 b3 #4 5 6 7`
  Hungarian Major Mode 7: C C# E F G A Bb; letters `1 #1 3 4 5 6 b7`, degrees `1 b2 3 4 5 6 b7`
the seven-note modes whose formulas differ:
  Enigmatic Mode 5: C D Eb F G B Bb; `1 2 b3 4 5 ##6 b7`, `1 2 b3 4 5 #6 7`
  Enigmatic Mode 6: C Db Eb F A G# B; `1 b2 b3 4 ##5 b6 7`, `1 b2 b3 4 #5 6 7`
  Enigmatic Mode 7: C D E G# F# A# B; `1 2 3 4 b5 #6 7`, `1 2 3 #4 #5 #6 7`
the other differences, one per family:
  Major Pentatonic: C D E G A; `1 2 3 ##4 ##5`, `1 2 3 5 6`
  Whole Tone: C D E F# G# Bb; `1 2 3 #4 #5 #6`, `1 2 3 #4 #5 b7`
  Diminished (Half-Whole): C Db Eb E F# G A Bb; `1 b2 b3 b4 b5 bb6 bb7 bb8`, `1 b2 b3 3 #4 5 6 b7`
  Blues Scale: C Eb F F# G Bb; `1 #2 #3 #4 5 #6`, `1 b3 4 #4 5 b7`
  Chromatic: C C# D D# E F F# G G# A A# B; `1 b2 bb3 bb4 5 6 7 8 9 10 11 12`, `1 #1 2 #2 3 4 #4 5 #5 6 #6 7`
  Perfect Fourth: C F; `1 2`, `1 4`
  Major Third: C E; `1 ##2`, `1 3`
  Minor Third: C Eb; `1 #2`, `1 b3`
  Minor Seventh: C Bb; `1 2`, `1 b7`
  Major Seventh: C B; `1 2`, `1 7`
  Dominant Bebop: C D E F G A Bb B; `1 2 3 4 5 6 b7 b8`, `1 2 3 4 5 6 b7 7`
  Major Bebop: C D E F G G# A B; `1 2 3 4 5 b6 bb7 b8`, `1 2 3 4 5 #5 6 7`
  Prometheus: C D E F# A Bb; `1 2 3 #4 ##5 #6`, `1 2 3 #4 6 b7`
  Hirajoshi: C D Eb G Ab; `1 2 b3 ##4 #5`, `1 2 b3 5 b6`
  In Sen: C Db F G Bb; `1 b2 #3 ##4 5`, `1 b2 4 5 b7`
  Whole-Half Diminished: C D Eb F Gb Ab A B; `1 2 b3 4 b5 b6 bb7 b8`, `1 2 b3 4 b5 b6 6 7`
  Augmented Scale: C Eb E G Ab B; `1 #2 3 ##4 #5 ##6`, `1 b3 3 5 b6 7`
```

- **Les formules sont justes pour 60 des 63 modes de sept notes, et pour 5 des 66 autres.** Les trois modes de sept notes en défaut sont des modes de la gamme énigmatique dont le catalogue ne range pas les notes dans l'ordre ascendant.
- **Toutes les gammes de cinq et de huit notes reçoivent une formule fausse.** La pentatonique majeure devient `1 2 3 ##4 ##5` : G y devient une quarte double dièse. Les gammes de huit notes finissent sur un huitième degré : `b8` pour la septième majeure du bebop dominant, `bb8` pour la septième mineure de la diminuée demi-ton/ton.
- **Une gamme de deux notes peut recevoir la mauvaise note.** Le catalogue compte cinq familles de « modes » de deux notes. Pour C F, le skill attend D en deuxième position ; F est trois demi-tons au-dessus, l'altération est donc abandonnée et la formule devient `1 2`, qui désigne D. Les septièmes mineure et majeure, C Bb et C B, donnent elles aussi `1 2`.
- **L'écart sur la gamme par tons n'est qu'une affaire d'orthographe.** `#6` et `b7` désignent la même note ; le catalogue l'écrit Bb.
- **Lire chaque chiffre sur la lettre, comme le propose le ticket #765, ne suffit pas non plus.** Pour 52 des 63 modes de sept notes, cela donne la même formule que leurs degrés. Pour les 11 autres, tels que le catalogue les orthographie, cela ne donne pas chaque degré une fois dans l'ordre ascendant : la plupart ont un degré deux fois et en perdent un autre, comme le mode 2 de l'énigmatique, `C D# F G A Bb B`, qui deviendrait `1 #2 4 5 6 b7 7`, et les modes 6 et 7 de l'énigmatique gardent les notes du catalogue dans le désordre. La règle d'un manuel a besoin des deux : les degrés pour sept notes, les lettres sinon.

## Quelques réponses

```text
== A few of ModesSkill's answers, first line
What is Ultralocrian?
  | **Ultralocrian** is mode 7 of the **Harmonic Minor** family; on C its notes are `C Db Eb Fb Gb Ab Bb` (formula `1 b2 b3 b4 b5 b6 b7`).
What is Altered?
  | **Altered** is mode 7 of the **Melodic Minor** family; on C its notes are `C Db Eb Fb Gb Ab Bb` (formula `1 b2 b3 b4 b5 b6 b7`).
What is Major Locrian?
  | **Major Locrian** is mode 5 of the **Neapolitan Major** family; on C its notes are `C D Eb F Gb Ab Bb` (formula `1 2 b3 4 b5 b6 b7`).
What is Major Pentatonic?
  | **Major Pentatonic** is mode 1 of the **Major Pentatonic** family; on C its notes are `C D E G A` (formula `1 2 3 ##4 ##5`).
What is Dominant Bebop?
  | **Dominant Bebop** is mode 1 of the **Dominant Bebop** family; on C its notes are `C D E F G A Bb B` (formula `1 2 3 4 5 6 b7 b8`).
What is Perfect Fourth?
  | **Perfect Fourth** is mode 1 of the **Perfect Fourth** family; on C its notes are `C F` (formula `1 2`).
```

- **L'Ultralocrien et l'altérée reçoivent les mêmes notes et la même formule.** Le locrien majeur reçoit les notes du locrien #2, C D Eb F Gb Ab Bb ; le locrien majeur d'un manuel est C D E F Gb Ab Bb.
- **La quarte juste devient un mode de deux notes, avec une formule qui désigne D.**

## Les noms

En YAML, une valeur s'arrête à une espace suivie de `#` : la suite est un commentaire, sauf si la valeur est entre guillemets. Le programme lit les noms de modes de `Modes.yaml` tels qu'ils sont écrits, et les compare aux noms que lit `ModesConfig` :

```text
== The mode names Modes.yaml writes, and the names ModesConfig reads: the ones that differ
written                            read
Lydian Augmented #2                Lydian Augmented
Lydian #2 #6                       Lydian
Ionian Augmented #2                Ionian Augmented
Lydian #6                          Lydian
Aeolian #4 (Lydian Diminished)     Aeolian
Ionian #2                          Ionian
Lydian Augmented #6                Lydian Augmented
Lydian Dominant #5                 Lydian Dominant
mode names written 165, read 165, read otherwise than written 8
```

- **Huit noms perdent tout à partir de leur premier dièse.** « Lydian #6 » devient « Lydian », « Aeolian #4 (Lydian Diminished) » devient « Aeolian », et « Lydian Dominant #5 » devient « Lydian Dominant ». Les noms de la mineure harmonique sont entre guillemets, `'Locrian #6'` ([`Modes.yaml`, ligne 209](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/Modes.yaml#L209)) ; ceux de la double harmonique, de la napolitaine mineure, de la napolitaine majeure et de la majeure harmonique ne le sont pas (lignes 631 à 681).

Le programme pose ensuite au skill la question `What is <name>?` pour chaque nom et chaque nom alternatif de mode :

```text
== "What is <name>?" for each mode's name and alternate names: the modes ModesSkill answers with another
asked                            the mode named                                    answered
What is Minor Pentatonic?        Minor Pentatonic (Major Pentatonic 5)             Blues Minor (Major Pentatonic 3)
What is Lydian Augmented?        Lydian Augmented (Harmonic Major 6)               Lydian Augmented (Melodic Minor 3)
What is Lydian?                  Lydian (Double Harmonic 2)                        Lydian (Major Scale 4)
What is Ionian Augmented?        Ionian Augmented (Double Harmonic 6)              Ionian #5 (Harmonic Minor 3)
What is Lydian?                  Lydian (Neapolitan Minor 2)                       Lydian (Major Scale 4)
What is Aeolian?                 Aeolian (Neapolitan Minor 4)                      Aeolian (Major Scale 6)
What is Ionian?                  Ionian (Neapolitan Minor 6)                       Ionian (Major Scale 1)
What is Lydian Augmented?        Lydian Augmented (Neapolitan Major 2)             Lydian Augmented (Melodic Minor 3)
What is Lydian Dominant?         Lydian Dominant (Neapolitan Major 3)              Lydian Dominant (Melodic Minor 4)
What is Whole-Half Diminished?   Whole-Half Diminished (Diminished (Octatonic) 1)  Diminished (Whole-Half) (Diminished 2)
mode names 129: answered with their mode 119, with another 10, CanHandle accepts 129; alternate names 68: answered with their mode 68, with another 0, CanHandle accepts 7
```

- **10 des 129 modes sont inaccessibles par leur propre nom.** Huit sont les noms coupés : ils reprennent désormais le nom d'un mode de la gamme majeure, de la mineure mélodique ou de la mineure harmonique, et c'est ce mode-là qui répond. Les deux autres noms figurent vraiment deux fois dans le catalogue : « Minor Pentatonic » est le nom du mode 5 de la pentatonique majeure et un nom alternatif de son mode 3, et « Whole-Half Diminished » désigne le mode 1 de la famille octatonique tout en étant un nom alternatif du mode 2 de la famille diminuée.
- **La première correspondance du catalogue l'emporte.** Le skill trie tous les noms et noms alternatifs par longueur, du plus long au plus court, en gardant l'ordre du catalogue entre noms de même longueur ; le premier que contient la question donne la réponse :

```csharp
        var aliasedModes = families
            .SelectMany(f => f.Modes
                .SelectMany(m => GetAllAliasesForMode(m).Select(a => (Alias: a, Family: f, Mode: m))))
            .OrderByDescending(t => t.Alias.Length)
            .ToList();

        foreach (var (alias, family, mode) in aliasedModes)
        {
            if (string.IsNullOrWhiteSpace(alias)) continue;
            if (lowerQuery.Contains(alias))
                return (family, mode);
        }
```

- **`CanHandle` accepte tous les noms de modes, mais seulement 7 des 68 noms alternatifs.** Il compare la fin de la question aux noms des modes et des familles, pas à leurs noms alternatifs ([lignes 137-144](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ModesSkill.cs#L137-L144)) : parmi les prompts d'exemple ci-dessous, « Tell me about Hijaz » est refusé. Au commit épinglé, l'orchestrateur n'appelle pas `CanHandle` ; sur `main`, c'est ce que le routeur d'intentions demande quand il ne peut pas calculer l'embedding d'une question ([leçon 25](../25-what-reaches-the-transpose-skill/), [`SemanticIntentRouter.cs`, lignes 313-335](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs#L313-L335)). Quel skill répond le premier dépend alors de l'ordre d'enregistrement, que cette leçon n'exécute pas.

## Les prompts d'exemple

```text
== ModesSkill's example prompts: what the first line of the answer is about
prompt                                       CanHandle  answer
What are the modes of the major scale        no         the Major Scale family
List the diatonic modes                      no         the Major Scale family
What are other famous modes                  no         The catalog has **26 mode families** total — these are the named scal…
What are the modes of melodic minor          no         the Melodic Minor family
Modes of harmonic minor                      no         the Harmonic Minor family
What is Lydian dominant                      yes        Lydian Dominant (Melodic Minor 4)
What is Phrygian dominant                    yes        Phrygian Dominant (Harmonic Minor 5)
What is the altered scale                    no         Altered (Melodic Minor 7)
Tell me about Hungarian minor                yes        Hungarian Minor (Double Harmonic 4)
What is the whole tone scale                 no         Whole Tone (Whole Tone 1)
What is the diminished scale                 no         Diminished (Half-Whole) (Diminished 1)
What modes are non-diatonic                  no         The catalog has **26 mode families** total — these are the named scal…
Show me all the mode families                no         The catalog has **26 mode families** total — these are the named scal…
What is Hirajoshi                            yes        Hirajoshi (Hirajoshi 1)
What is Dorian                               yes        Dorian (Major Scale 2)
What is Phrygian                             yes        Phrygian (Major Scale 3)
What is Lydian                               yes        Lydian (Major Scale 4)
What is Mixolydian                           yes        Mixolydian (Major Scale 5)
What is Aeolian                              yes        Aeolian (Major Scale 6)
What is Ionian                               yes        Ionian (Major Scale 1)
What is Locrian                              yes        Locrian (Major Scale 7)
Tell me about Hijaz                          no         Phrygian Dominant (Harmonic Minor 5)
What is Maqam Hijaz                          no         Phrygian Dominant (Harmonic Minor 5)
What is Freygish                             no         Phrygian Dominant (Harmonic Minor 5)
What is Bhairavi                             no         Phrygian (Major Scale 3)
What is the Byzantine scale                  no         Double Harmonic (Byzantine) (Double Harmonic 1)
What is the Spanish Gypsy scale              no         Phrygian Dominant (Harmonic Minor 5)
What is Ahava Rabbah                         no         Phrygian Dominant (Harmonic Minor 5)
What modes have a major 7th                  no         the Major Scale family
Mixolydian versus Ionian differences         no         Mixolydian (Major Scale 5)
Characteristics of Locrian                   no         Locrian (Major Scale 7)
What families have ICV <2 5 4 3 6 1>         no         **Major Scale Family** — ICV `<2 5 4 3 6 1>`, 7-note set, 7 distinct …
What is Forte number 7-29                    no         Forte number **7-29** matches 1 family:
List symmetric families                      no         **6 symmetric / modes-of-limited-transposition families** in the aton…
List atonal modal families                   no         The **atonal modal-families catalog** has **200 families** indexed by…
List unnamed modal families                  no         the Major Scale family
What are modes of limited transposition      no         **6 symmetric / modes-of-limited-transposition families** in the aton…
example prompts 37: CanHandle accepts 11
```

- **« List unnamed modal families » reçoit les modes de la gamme majeure.** La branche atonale cherche « unnamed famil » ([ligne 606](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ModesSkill.cs#L606)), et le prompt dit « unnamed modal families » ; il tombe sur la réponse par défaut ([lignes 202-207](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ModesSkill.cs#L202-L207)), celle qu'avait reçue le « melodi minor » de la leçon 8.
- **« What modes have a major 7th » reçoit aussi les modes de la gamme majeure, et « Mixolydian versus Ionian differences » le seul mixolydien :** le nom le plus long de la question l'emporte, et le skill ne sait pas comparer.
- **`CanHandle` en accepte 11 sur 37.**

## Où le cours s'arrête

- **Le manuel est celui du cours.** `Parents` dans `Lesson26.cs` donne le premier mode de chaque famille tel que le donnent les ouvrages de référence courants ; les noms des modes ne sont pas comparés à un manuel, seules leurs notes le sont au premier mode de leur propre famille.
- **L'orthographe est celle du catalogue.** Les formules sont comparées à la règle d'un manuel appliquée aux notes du catalogue lui-même, et un dièse et un bémol qui désignent la même note ne sont distingués que là où la règle l'exige.
- **Le catalogue atonal et le routage ne sont pas vérifiés.** Les 200 familles atonales ne sont pas comparées à une table de classes d'ensembles, et aucun routeur ne tourne : la leçon appelle le skill directement.

## Signalé en amont

- Signalés après l'écriture de cette leçon, dans le ticket de GA [#813](https://github.com/GuitarAlchemist/ga/issues/813) : les modes qui ne sont pas la gamme de leur famille jouée depuis leur degré, les noms que YAML coupe à « # » et les modes qu'ils rendent inaccessibles, les noms alternatifs que `CanHandle` ignore, le filtre « Chord Family », et les prompts d'exemple qui reçoivent la réponse par défaut. Les comptes des formules ont été ajoutés à [#765](https://github.com/GuitarAlchemist/ga/issues/765) dans [un commentaire](https://github.com/GuitarAlchemist/ga/issues/765#issuecomment-5982283789).

## Exercices

1. Sur quel degré de C D E G A commence le « Minor Pentatonic » du catalogue, C D F G A ? Lequel des modes de la famille porte les notes de la pentatonique mineure ?
2. Pourquoi le skill écrit-il `1 2` pour la quarte juste, C F ?
3. `Modes.yaml` nomme le troisième mode de la napolitaine majeure « Lydian Dominant #5 ». Pourquoi « What is Lydian Dominant? » reçoit-il le mode de la mineure mélodique, et que faudrait-il pour que « What is Lydian Dominant #5? » reçoive celui de la napolitaine majeure ?
4. Pourquoi « List unnamed modal families » reçoit-il les modes de la gamme majeure, alors que « List symmetric families » reçoit le catalogue atonal ?

<details>
<summary>Solutions</summary>

1. Sur le degré 4, G : G A C D E, ramené sur C, donne C D F G A. La pentatonique mineure part du degré 5, A : C Eb F G Bb, les notes du mode 3 du catalogue, « Blues Minor », dont le nom alternatif est « Minor Pentatonic ».
2. F est la deuxième note, donc le skill la compare à D, deuxième degré de C majeur. F est trois demi-tons au-dessus de D, au-delà des deux dièses que sait écrire le `switch` : l'altération est abandonnée (ligne 806) et le chiffre reste 2.
3. Le nom n'est pas entre guillemets, si bien que YAML lit « Lydian Dominant » : le mode 4 de la mineure mélodique porte le même nom, vient plus tôt dans le catalogue et l'emporte à égalité. Entre guillemets, `'Lydian Dominant #5'`, comme les lignes 209 à 280 écrivent les leurs, le nom garde son dièse ; il est alors plus long que « lydian dominant », le skill l'essaie donc en premier, et « What is Lydian Dominant #5? » le contient. Raisonnement fait sur le code : le programme ne pose pas la question avec les noms tels qu'ils sont écrits.
4. « List symmetric families » contient « symmetric famil », l'une des expressions de la branche atonale (ligne 597). « List unnamed modal families » n'en contient aucune : l'expression qu'il lui faudrait est « unnamed famil » (ligne 606), et le mot « modal » s'intercale. Il ne nomme ensuite aucune famille ni aucun mode que le skill connaisse, et reçoit donc la réponse par défaut, les modes de la gamme majeure (lignes 202-207).

</details>

## À retenir

- Un skill sans théorie musicale à lui vaut ce que vaut son catalogue : vérifiez le catalogue, mode par mode.
- « Le mode k » est une affirmation qu'un programme peut vérifier : le premier mode de la famille, joué depuis le degré k.
- Une formule numérotée par position est juste pour une gamme de sept notes dans l'ordre ascendant ; pour les autres tailles, seulement si les notes prennent les lettres dans l'ordre, ce qui est rare.
- En YAML, mettez entre guillemets toute valeur qui contient une espace suivie de `#`.
- Une recherche qui garde la première correspondance a besoin de noms qui n'apparaissent qu'une fois.

## Sources

- GuitarAlchemist/ga au commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) : `Common/GA.Business.ML/Agents/Skills/ModesSkill.cs`, `Common/GA.Business.Config/Modes.yaml`, `Common/GA.Business.Config/ModesConfig.fs`.
- GuitarAlchemist/ga au commit [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/tree/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) : `SemanticIntentRouter.cs` et son repli par mots-clés.
- Le programme du cours : `code/ga-ai/GaAi/Lesson26.cs`.
