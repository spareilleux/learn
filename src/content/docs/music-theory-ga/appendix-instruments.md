---
title: "Appendix A: every instrument in Guitar Alchemist"
description: The 122 instruments and 280 tunings of GA's Instruments.yaml, read by the course program — and what GA's own configuration loader returns for the same file.
sidebar:
  label: "Appendix A: every instrument"
  order: 90
---

Lesson 1 uses one instrument and lesson 8 uses three. GA's configuration holds a great many more: [`Instruments.yaml`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/Instruments.yaml) is 1589 lines of them, from the balalaika to the pedal steel guitar. This appendix lists all of them, as the course program reads them, and compares that with what GA's own loader hands back to the rest of GA.

```bash
dotnet run --project code/music-theory-ga/GaTheory -c Release -- l9
```

## The headline

```text
== Instruments.yaml: what is in the file, and what GA's loader returns
count                  course         GA             check
instruments            122            1              DIFF
tunings                280            2              DIFF

GA returns: Guitar (Standard = E2,A2,D3,G3,B3,E4, Drop D = D2,A2,D3,G3,B3,E4)
That is InstrumentsConfig's built-in fallback, not the file. The file is found and read:
  the loader locates it at a path next to the program
  and then deserialises it into a record with one field, `Instruments`, which the file has no key for,
  so the result is empty or the deserialiser throws, and both paths fall back to the two guitar tunings.
```

One instrument. Two tunings. The file with 122 instruments and 280 tunings is found, opened and read, and then discarded.

The reason is a shape mismatch, and it is worth following because nothing about it looks wrong at either end. [`InstrumentsConfig`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/InstrumentsConfig.fs) declares the type it expects:

```fsharp
type InstrumentsYaml =
    { Instruments: ResizeArray<System.Collections.Generic.IDictionary<string, obj>> }
```

It wants a document with one key, `Instruments`, holding a **list**. Each item should be a dictionary with a `Name` and a `Tunings` list of `{ Name, Tuning }` pairs. The file is not shaped like that at all: it is a **mapping of instruments at the top level**, each one a mapping of tunings.

```yaml
Ukulele:
  DisplayName: "Ukulele"
  SopranoConcertAndTenorC:
    DisplayName: "Soprano Concert And Tenor C"
    Tuning: C6 G4 C4 E4 A4
```

There is no `Instruments` key anywhere in the file, and no `Tunings` list anywhere either. [YamlDotNet](https://github.com/aaubry/YamlDotNet) therefore either produces a record whose only field is null, or throws on the unmatched properties — and `loadInstrumentsData` handles both the same way:

```fsharp
if obj.ReferenceEquals(data, null)
   || obj.ReferenceEquals(data.Instruments, null)
   || data.Instruments.Count = 0
then instrumentsData <- Some(defaultData ())
```

```fsharp
with _ ->
    // On any error, fall back to defaults
    instrumentsData <- Some(defaultData ())
```

`defaultData ()` is a guitar with a standard and a drop D tuning, written in the F# source as a "minimal built-in dataset so tests and core features can work". Every path through the loader reaches it, so `getAllInstruments`, `listAllInstrumentNames`, `listAllInstrumentTunings`, `findInstrumentsByName` and `tryGetInstrument` all answer from two hard-coded guitar tunings, and always have. Nothing fails, nothing logs, and a caller asking for the ukulele's tuning gets `None` rather than an error.

:::note[How this was checked]
Not by reading. The course program references `GA.Business.Config` as a project and calls `InstrumentsConfig.getAllInstruments()` directly; the numbers in the table above are its return value, compared with the course's own reading of the same file on the same run, in CI, on three operating systems.
:::

This is the reason the ukulele's five-pitch tunings and the baritone's wrong octave, in lesson 8, have never bitten anyone: no program has ever read them. It also means the catalogue is, at this commit, documentation rather than configuration.

## What a fix would look like

Two options, and the file picks neither:

- **Change the loader to the file's shape** — deserialise into `IDictionary<string, IDictionary<string, obj>>`, treat every nested mapping that has a `Tuning` key as a tuning and every other key (`DisplayName`, `Icon`) as metadata. This is roughly what the course's own 30-line reader does, and it needs no change to the 1589-line file.
- **Change the file to the loader's shape** — rewrite it as `Instruments:` followed by a list. This is a large, mechanical, error-prone edit of data that is already right.

The first is clearly the cheaper. Either way the loader should say so when it falls back: a silent default that is 1/122 of the real data is worse than an exception, because it cannot be noticed.

## Seven tunings that are not pitches

The course's reader turns each `Tuning:` line into a list of pitches. Seven lines do not survive that.

```text
== Tunings the course cannot read as pitches
entry                              tuning as written                      not a pitch
Dulcimer.LydianMode                Bb C4 C4 F3 Bb2                        Bb
Huapanguera.Standard               Huapanguera                            Huapanguera
PedalSteelGuitar.T1                C6 C2 F2 2 C3 E3 G3 A3 C4 E4 G4        2
PedalSteelGuitar.T2                E9 B2 D3 3 F#3 G#3 B3 E4 G#4 Eb4 F#4   3
Saz.BaglamaBozukDuzenSevenStrings  Tuning G2 G3 D2 D3 A2 A3 A3            Tuning
HarpGuitar.Standard6PlusSubs       E2 A2 D3 G3 B3 E4 | A1 G1 F1           |
HarpGuitar.DADGADPlusSubs          D2 A2 D3 G3 A3 D4 | A1 G1 F1           |
```

Four kinds of mistake:

- **A tuning's name written as a pitch.** `PedalSteelGuitar.T1` begins with `C6` and `T2` with `E9`; [C6 and E9](https://en.wikipedia.org/wiki/Pedal_steel_guitar) are the names of the two standard pedal steel setups, not notes. The same slip put `C6` and `D6` at the head of the four ukulele tunings in lesson 8 — and those *do* parse as pitches, so they are invisible here. Lines that fail loudly are the lucky ones.
- **A word where a list should be.** `Saz.BaglamaBozukDuzenSevenStrings` begins with the literal word `Tuning`; `Huapanguera.Standard` is the single word `Huapanguera`, the instrument's own name, with no tuning at all.
- **A missing octave.** `Dulcimer.LydianMode` is `Bb C4 C4 F3 Bb2`: the first `Bb` has no octave number where every other token has one.
- **A separator with a meaning.** The two harp guitar entries use `|` to divide the six fretted strings from the three sub-bass strings. That is a real distinction the format has no field for, so it was written into the value.

`PedalSteelGuitar.T2` also mixes spellings inside one tuning — `G#4` and `Eb4` in the same list — which lesson 3 shows GA cannot represent consistently anyway.

## Tunings that appear under several instruments

```text
== Instruments with two entries for the same tuning name
tuning                           entries
C3 G3 G3 C4 C4 E4 E4 G4 G4       Waldzither.Hamburger, Waldzither.Thüringer, Zister.Thüringer
E1 A1 D2 G2                      BassGuitar.Standard, Mandobass.Standard, BassGuitarExtended.FretlessStandard
E2 A2 D3 G3 B3 E4                Guitar.Standard, GuitarBanjo.Standard, Mandore.French
G3 D4 G4 D5                      Liuqin.Standard, Mandore.ModalG, YuehChinOrYuehQin.Standard
G3 G3 D4 D4 A4 A4 E5 E5          Bandola.Oriental, Bandolim.Standard, Mandolin.Standard
A3 A2 D4 D2 F#4 F#3 A3 A3 D4 D4  Viola.Caipira, Viola.Sertaneja
B1 E2 A2 D3 G3 B3 E4             ViolãoDeSeteCordas.Standard, ElectricGuitar7.StandardB
B4 E5 A5                         Balalaika.Piccolo, Domra.Piccolo
C2 C2 G2 G2 D3 D3 A3 A3          Lavta.Standard, Mandocello.Standard
C2 G2 D3 A3                      Banjo.Cello, Ruan.Tenor
C3 G3 D4 A4                      Banjo.TenorJazz, TenorGuitar.Standard
C6 G4 C4 E4 A4                   Ukulele.SopranoConcertAndTenorC, Ukulele.BanjoOrBanjoleteC
```

Most of these are correct and informative rather than wrong: a guitar banjo really is tuned like a guitar, a tenor guitar really is tuned like a tenor banjo, a mandobass really is tuned like a bass guitar. Read the other way, the list is a map of which instruments share a fingering — the most useful thing in the file for a player, and the thing GA's schema has no way to express.

The ukulele row is the exception: `Ukulele.SopranoConcertAndTenorC` and `Ukulele.BanjoOrBanjoleteC` are the same instrument's tuning entered twice, both with the same five-pitch error.

## How long the tunings are

```text
== How many pitches each tuning lists
pitches  tunings  first three
1        1        Huapanguera.Standard
3        22       Balalaika.Alto, Balalaika.Bass, Balalaika.Contrabass
4        60       Bandola.Llanera, Banjo.Cello, Banjo.TenorJazz
5        24       Banjo.Bluegrass5Strings, Banjo.CTuning5Strings, Banjourine.Standard
6        43       Baglama.Greek, BaritoneGuitar.Standard1, BaritoneGuitar.Standard2
7        10       Bandora.Standard, Guitar.Renaissance, RussianGuitar.Standard
8        29       Bandola.Central, Bandola.Guayanesa, Bandola.Oriental
9        7        Cittern.16th/17thCentury, Cittern.FrenchTuning, TaroPatch.Standard
10       40       Bajo.Quinto, Bordonua.Standard, Charango.Standard
11       7        Charangon.Tuning1, Charangon.Tuning2, PedalSteelGuitar.T1
12       20       Bajo.Sexto, Bandurria.Standard, Cistre.Standard
13       1        BaroqueLute.Standard
14       4        Bandurria.Phillipines, Archlute.14Course, LaudPhillipines.Standard
15       5        Bandolin.Ecuadorean, SwedishLute.Standard, TheorboFifteenCourse.Standard
16       5        Bandola.AndinaColombiana, Bandurria.Peruvian, Angelique(Theorbo).Standard
24       1        GuitarrónChileno.Standard
27       1        LiutoAttiorbatoTheorbo.Standard
```

The file stores pitches, not strings, and for a doubled-course instrument it stores every string of every course: a mandolin is eight pitches in four pairs, a twelve-string guitar is twelve. Nothing in the format says which pitches belong to the same course, so a reader cannot tell a mandolin from an eight-string guitar, or — as lesson 8's third exercise shows — a doubled course from a re-entrant string. A `Courses:` field, or writing a course as one token, would fix it.

## Every instrument and every tuning

```text
== Every instrument and every tuning
instrument             tuning                             pitches
Baglama                Greek                              D4 D5 A4 A4 D5 D5
Bajo                   Quinto                             A2 A1 D3 D2 G2 G2 C3 C3 F3 F3
                       Sexto                              E2 E1 A2 A1 D3 D2 G2 G2 C3 C3 F3 F3
Balalaika              Alto                               E3 E3 A3
                       Bass                               E2 A2 D3
                       Contrabass                         E1 A1 D2
                       Piccolo                            B4 E5 A5
                       Prima                              E4 E4 A4
                       Sekunda                            A3 A3 D4
Bandola                Central                            E3 E4 A3 A3 D3 D4 G3 G4
                       AndinaColombiana                   F#3 F#3 B3 B3 E4 E4 E4 A4 A4 A4 D5 D5 D5 G5 G5 G5
                       Guayanesa                          G3 G4 D3 D4 A4 A4 E5 E5
                       Llanera                            A3 D4 F#4 B4
                       Oriental                           G3 G3 D4 D4 A4 A4 E5 E5
Bandolim               Standard                           G3 G3 D4 D4 A4 A4 E5 E5
Bandora                Standard                           G4 C2 D2 G2 C3 E3 A3
Bandurria              Standard                           G#3 G#3 C#4 C#4 F#4 F#4 B4 B4 E5 E5 A5 A5
                       Peruvian                           D5 D4 D5 D5 G4 G3 G4 G4 B4 B4 B4 B4 E5 E5 E5 E5
                       Phillipines                        F#3 B3 B3 E4 E4 A4 A4 A4 D5 D5 D5 G5 G5 G5
Banjo                  Cello                              C2 G2 D3 A3
                       TenorJazz                          C3 G3 D4 A4
                       TenorIrish                         G2 D3 A3 E3
                       Plectrum                           C3 G3 B3 D4
                       Bluegrass5Strings                  G4 D3 G3 B3 D4
                       CTuning5Strings                    G4 C3 G3 B3 D4
Banjolin               Standard                           G3 D4 A5 E5
Banjourine             Standard                           C5 G3 C4 E3 G4
BaritoneGuitar         Standard1                          B1 E2 A2 D3 F#3 B3
                       Standard2                          A1 D2 G2 C3 E3 A3
                       OctaveLower                        E1 A1 D2 G2 B2 E3
BassGuitar             Standard                           E1 A1 D2 G2
                       FiveStrings                        B0 E1 A1 D2 G2
                       SixStrings                         B0 E1 A1 D2 G2 C3
Bordonua               Standard                           A2 A3 D4 D3 F#3 F#4 B3 B3 E4 E4
Bouzouki               GreekTetrachordo                   C3 C4 F3 F4 A3 A3 D4 D4
                       GreekTrichordo                     D3 D4 A3 A3 D4 D4
                       IrishGDADOctave                    G3 G2 D4 D3 A3 A3 D4 D4
                       IrishGDADPairs                     G2 G2 D3 D3 A3 A3 D4 D4
                       IrishFifthsOctave                  G3 G2 D4 D3 A3 A3 E4 E4
                       IrishFifthsPairs                   G2 G2 D3 D3 A3 A3 E4 E4
                       IrishModalDOctaves                 A3 A2 D4 D3 A3 A3 D4 D4
                       IrishModalD(UnisonPairs            A2 A2 D3 D3 A3 A3 D4 D4
Braguinha              Standard                           D4 G4 B4 D5
Cavaquinho             Standard                           D4 G4 B4 D5
                       AMajor                             A4 A4 C#5 E5
                       AMajorV2                           E4 A4 C#5 E5
                       CMajor                             G4 C5 E5 G5
                       GMajor                             G4 G4 B4 D5
Chanzy                 Standard                           F2 C3 F3
Charango               Standard                           G4 G4 C4 C4 E5 E4 A4 A4 E5 E5
                       Ranka                              D4 D4 A4 A4 G4 G4 C5 C5 G5 G6
Charangon              Tuning1                            F6 C4 C4 F4 F4 A5 A4 D5 D5 A5 A5
                       Tuning2                            G6 D4 D4 G4 G4 B5 B4 E5 E5 B5 B5
ChitarraBattente       Standard                           A3 D4 G3 B3 E4
Chonguri               DMinor                             D2 F2 D3 A2
                       FMajor                             F3 A3 F4 C4
Cistre                 Standard                           E2 A2 D3 D3 E3 E3 A3 A3 C#4 C#4 E4 E4
Cittern                Bell                               B3 B3 D4 D4 F4 F4 A4 A4 D5 D5
                       Celtic5thsLongscale                C2 C2 G2 G2 D3 D3 A3 A3 E4 E4
                       CelticLongscale1                   C2 C2 G2 G2 D3 D3 G3 G3 D4 D4
                       CelticLongscale2                   D2 D2 A2 A2 E3 E3 A3 A3 E4 E4
                       CelticShortscale                   G2 G2 D3 D3 A3 A3 D4 D4 A4 A4
                       Celtic5thsShortscale               G2 G2 D3 D3 A3 A3 E4 E4 B4 B4
                       CelticIrish                        D2 D2 G2 G2 D3 D3 A3 A3 D4 D4
                       CelticMandocelloLongscale          C2 C2 G2 G2 D3 D3 A3 A3 D4 D4
                       CelticMandocelloShortscale         G2 G2 D3 D3 A3 A3 E4 E4 A4 A4
                       CelticModalCLongscale              C2 C2 G2 G2 C3 C3 G3 G3 C4 C4
                       CelticModalCShortscale             G2 G2 C3 C3 G3 G3 C4 C4 G4 G4
                       CelticModalDLongscale              D2 D2 A2 A2 D3 D3 A3 A3 D4 D4
                       CelticModalDShortscale             A2 A2 D3 D3 A3 A3 D4 D4 A4 A4
                       CelticModalFShortscale             F2 F2 C3 C3 F3 F3 C4 C4 F4 F4
                       CelticModalGLongscale              D2 D2 G2 G2 D3 D3 G3 G3 D4 D4
                       CelticModalGShortscale             G2 G2 D3 D3 G3 G3 D4 D4 G4 G4
                       CelticModalALongscale              E2 E2 A2 A2 E3 E3 A3 A3 E4 E4
                       16th/17thCentury                   B3 B3 G4 G4 G3 D4 D4 E4 E4
                       FrenchTuning                       A4 A4 G4 G4 G3 D4 D4 E4 E4
Cuatro                 PuertoRican                        B3 B2 E4 E3 A3 A3 D4 D4 G4 G4
                       Venezuelan                         A3 D4 F#4 B3
Cumbus                 DanTyba                            G3 C4 D4 G4
DobroorResophonic      Standard                           G2 B2 D3 G3 B3 D4
Domra                  Alto                               E3 A3 D4
                       Bass                               E2 A2 D3
                       ContrabassMajor                    A1 D2 G2
                       ContrabassMinor                    E1 A1 D2
                       Mezzosoprano                       B3 E4 A4
                       Piccolo                            B4 E5 A5
                       Prima                              E4 A4 D5
                       Tenor                              B2 E3 A3
                       UkrainianPrima                     G3 D4 A4 E5
Dulcimer               AeolianModeDMinor                  C4 C4 A3 D3
                       AeolianModeCMinor                  Bb3 Bb3 G3 C3
                       DorianModeDMinor                   G3 G3 A3 D3
                       DorianModeEMinor                   A3 A3 B3 E3
                       IonianKeyOfD                       A3 A3 A3 D3
                       IonianKeyOfC                       G3 G3 G3 C3
                       LocrianModeOfCSharpMinor           A3 A3 G#3 C#3
                       LocrianModeDMinor                  Bb3 Bb3 A3 D3
                       LydianModeCAndMore                 D4 D4 G3 C3
                       LydianMode                         Bb C4 C4 F3 Bb2
                       MixolydianMode                     D4 D4 A3 D3
                       PhrygianMode                       Eb4 Eb4 G3 C3
EnglishGuittar         Standard                           C3 E3 G3 G3 C4 C4 E4 E4 G4 G4
Gekkin                 Standard                           A3 D4 D4 D5
Ghita                  Standard                           C3 F3 C4 G4 C5
Gittern                Standard                           D4 G4 D5 G5
Grajappi               Standard                           F2 F2 B2 B2
Guitar                 Standard                           E2 A2 D3 G3 B3 E4
                       DADGAD                             D2 A2 D3 G3 A3 D4
                       DoubleDropD                        D2 A2 D3 G3 B3 D4
                       DropD                              D2 A2 D3 G3 B3 E4
                       OpenCMajor                         C2 G2 C3 G3 C3 E4
                       OpenDMajor                         D2 A2 D3 F#3 A3 D4
                       OpenEMajorV1                       E2 B2 E3 G#3 B3 E4
                       OpenEMajorV2                       E2 B2 E3 G3 B3 E4
                       OpenGMajorV1                       D2 G2 D3 G3 B3 D4
                       OpenGMinorV2                       D2 G2 D3 G3 Bb3 D4
                       OpenAMajor                         E2 A2 E3 A3 C#3 E4
                       Renaissance                        G3 G4 C4 C4 E4 E4 A4
                       Baroque1                           A3 A3 D4 D4 G3 G3 B3 B3 E4 E4
                       Baroque2                           A3 A3 D4 D3 G3 G3 B3 B3 E4 E4
                       TwelveStrings                      E2 E3 A2 A3 D3 D4 G3 G4 B3 B3 E4 E4
GuitarBanjo            Standard                           E2 A2 D3 G3 B3 E4
GuitarDecacorde        Standard                           C2 D2 E2 F2 G2 A2 D3 G3 B3 E4
GuitarradeGolpe        Standard                           D3 G3 C4 E3 A3
GuitarroorGuitarrico   Standard                           B4 F#4 D5 A5 E5
Guitarrón              Standard                           A1 D2 G2 C3 E3 A2
Halszither             Krienser                           G2 G2 D3 D3 G3 G3 B3 B3 D4 D4
Harzzither             Standard                           G3 G3 C4 C4 E4 E4 G4 G4
HawaiianGuitar         Tuning1                            E2 A2 E3 A3 C#4 E4
                       Tuning2                            G2 B2 D3 G3 B3 D4
Huapanguera            Standard                           Huapanguera
Jarana                 Huasteca                           G3 B3 D4 F#4 A4
                       Jarocha                            A3 D4 D4 G3 G4 B3 B3 E4
Laud                   Standard                           G#2 G#2 C#3 C#3 F#3 F#3 B3 B3 E4 E4 A4 A4
Lavta                  Standard                           C2 C2 G2 G2 D3 D3 A3 A3
Liuqin                 Standard                           G3 D4 G4 D5
Lute                   BaroqueDMinor                      A2 D3 F3 A3 D4 F4
                       Medieval                           G2 G2 C3 C3 F3 F3 A3 A3 D4 D4 G4 G4
                       RenaissanceTenor                   D2 F2 G2 C3 F3 A3 D4 G4
Mandobass              Standard                           E1 A1 D2 G2
Mandocello             Standard                           C2 C2 G2 G2 D3 D3 A3 A3
Mandola                Tenor                              C3 C3 G3 G3 D4 D4 A4 A4
Mandolin               Standard                           G3 G3 D4 D4 A4 A4 E5 E5
                       FiveCourse                         C3 C3 G3 G3 D4 D4 A4 A4 E5 E5
                       ElectricFiveStrigs                 C3 G3 D4 A4 E5
                       Cremona                            G3 D4 A4 E5
                       Genuese                            E3 E3 A3 A3 D3 D4 G4 G4 B4 B4 E5 E5
                       Neopolitan                         G3 G4 D4 D4 A4 A4 E5 E5
                       Piccolo                            C4 C4 G4 G4 D5 D5 A5 A5
                       Banjo                              G3 G3 D4 D4 A5 A5 E5 E5
Mandolino              Standard                           G3 G3 B3 B3 E4 E4 A4 A4 D5 D5 G5 G5
                       Lombardo                           G3 B3 E4 A4 D5 G5
Mandore                ModalC                             C4 G4 C5 G5
                       ModalG                             G3 D4 G4 D5
                       French                             E2 A2 D3 G3 B3 E4
MandriolaOrTricordia   Standard                           G2 G3 G3 D3 D4 D4 A3 A4 A4 E4 E5 E5
                       Unisonpairs                        G3 G3 G3 D4 D4 D4 A4 A4 A4 E5 E5 E5
Mejorana               Standard                           D4 A4 A3 B3 E4
Mondol                 Standard                           E2 E2 A2 A2 D3 D3 G3 G3 B3 B3
OctaveGuitar           Standard                           E3 A3 D4 G4 B5 E5
Panduri                E                                  E3 B3 A4
                       G                                  G3 A3 C4
PedalSteelGuitar       T1                                 C6 C2 F2 2 C3 E3 G3 A3 C4 E4 G4
                       T2                                 E9 B2 D3 3 F#3 G#3 B3 E4 G#4 Eb4 F#4
                       UniversalTwelveStrings             Bb2 Eb2 G2 Bb2 D3 F3 G3 Bb3 D4 F4 G4 E4
Phin                   Standard                           G4 D4 A4
Pipa                   Standard                           A2 D2 G3 A3
PortugueseGuitarra     Coimbra                            C3 C2 G3 G2 A3 A2 D3 D3 G3 G3 A3 A3
                       Lisboa                             D3 D2 A3 A2 B3 B2 E3 E3 A3 A3 B3 B3
Rajão                  Standard                           D4 G4 C4 E4 A4 A4
Ramkie                 Standard                           C3 F3 A3 C4
Requinto               Standard                           A2 D3 G3 C4 E4 A4
                       FourStringsV1                      G2 A2 D3 G3
                       FourStringsV2                      C2 D2 G2 C3
                       FiveStrings                        E2 A2 D3 G3 C3
Ronroco                Standard                           G3 G3 C3 C3 E4 E3 A3 A3 E4 E4
Ruan                   Soprano                            G2 D3 A3 E4
                       Tenor                              C2 G2 D3 A3
                       Zhong                              G2 D2 G3 D3
RussianGuitar          Standard                           D2 G2 B2 D3 G3 B3 D4
Saz                    AzeriOrQopuz                       D4 D4 D4 G3 G3 C4 C4 C4
                       BaglamaBozukDuzenSixStrings        G2 G3 D2 D3 A2 A3
                       BaglamaBozukDuzenSevenStrings      Tuning G2 G3 D2 D3 A2 A3 A3
Seis                   PuertoRican                        F#3 F#2 B3 B2 E4 E3 A3 A3 D4 D4 G4 G4
                       PuertoRicanGuitarTuning            F#3 F#2 B3 B2 E4 E3 A3 A3 C#4 C#4 F#4 F#4
Setar                  Standard                           C3 C4 G3 C4
Sitar                  Standard                           C5 C4 G3 C2 G2 C3 F3
SopranoGuitar          Standard                           E3 A4 D4 G4 B4 E5
Sovacon                Standard                           G2 D3 A3 B2
Strumstick             Standard                           G3 D4 G4
Tambur                 Yali                               D2 D2 A2 A2 D3 D3
Tamburitza             Brac                               E2 A2 D3 G3
                       Bugarija                           G2 B2 D3 G3 G3
Tar                    Standard                           C3 C4 G3 G3 C4 C4
                       TarAzeriOrCaucasus                 C4 C4 C5 C5 G2 C3 C4 G3 G3 C4 C4
TaroPatch              Standard                           G3 G4 C4 C3 C4 E4 E4 A4 A4
TenorGuitar            Standard                           C3 G3 D4 A4
                       Irish                              G2 D3 A3 E3
Timple                 Standard                           G4 C5 E4 A4 D5
Tiple                  Chilean                            D4 D3 D4 G4 G3 G4 B3 B3 B3 E4 E4 E4
                       Columbian                          D4 D3 D4 G4 G3 G4 B3 B3 B3 E4 E4 E4
                       Doliente                           E3 A3 D4 G4 C5
                       MartinStyle                        A3 A4 D4 D3 D4 F#4 F#3 F#4 B4 B4
                       Requinto                           D4 D4 G4 G4 G4 B4 B4 B4 E4 E4
TresCubano             CMajor                             G4 G3 C4 C4 E4 E3
                       DMajor                             A4 A3 D4 D4 F#4 F#4
Tzouras                Standard                           D3 D4 A3 A3 D4 D4
Ukulele                SopranoConcertAndTenorC            C6 G4 C4 E4 A4
                       SopranoConcertAndTenorD            D6 A4 D4 F#4 B4
                       Baritone                           D4 G3 B4 E4
                       Tahitian                           G4 G4 C5 C5 E5 E5 A4 A4
                       BanjoOrBanjoleteC                  C6 G4 C4 E4 A4
                       BanjoOrBanjoleteD                  D6 A4 D4 F#4 B4
Vihuela                Standard                           A3 D4 G4 B3 E4
Viola                  Amarantina                         D3 D2 A3 A2 B3 B2 E3 E3 A3 A3
                       Beiroa                             D3 D3 A3 A2 D3 D2 G3 G2 B3 B3 D3 D3
                       Braguesa                           C3 C2 G3 G2 A3 A2 D3 D3 G3 G3
                       Caipira                            A3 A2 D4 D2 F#4 F#3 A3 A3 D4 D4
                       Campaniça                          C3 C2 F3 F2 C3 C3 E3 E3 G3 G3
                       DaTerra                            A4 A4 A4 D4 D4 D3 G3 G3 B3 B3 D4 D4
                       DeArame                            G3 G2 D3 D2 G3 G3 B3 D3 D3
                       DeCocho1                           G3 D3 E3 A3 D4
                       DeCocho2                           G3 C3 E3 A3 D4
                       DeDizCordas                        A3 A3 D3 D4 G3 G3 B3 B3 E4 E4
                       Sertaneja                          A3 A2 D4 D2 F#4 F#3 A3 A3 D4 D4
                       Toeira                             A3 A3 A3 D3 D3 D2 G3 G2 B3 B3 E3 E3
ViolãoDeSeteCordas     Standard                           B1 E2 A2 D3 G3 B3 E4
Walaycho               StandardF                          F6 C4 C4 F4 F4 A5 A4 D5 D5 A5 A5
                       StandardG                          G6 D4 D4 G4 G4 B5 B4 E5 E5 B5 B5
Waldzither             Hamburger                          C3 G3 G3 C4 C4 E4 E4 G4 G4
                       Thüringer                          C3 G3 G3 C4 C4 E4 E4 G4 G4
YuehChinOrYuehQin      Standard                           G3 D4 G4 D5
Zister                 Thüringer                          C3 G3 G3 C4 C4 E4 E4 G4 G4
Angelique(Theorbo)     Standard                           D2 E2 F2 G2 A2 B2 C3 D3 E3 F3 G3 A3 B3 C4 D4 E4
Archlute               14Course                           F2 G2 A2 Bb2 C3 D3 E3 F3 G3 C4 F4 A4 D5 G5
Bandolin               Ecuadorean                         E5 E4 E5 A5 A4 A5 D5 D4 D5 F5 F5 F5 B5 B5 B5
BaroqueLute            Standard                           A2 B2 C3 D3 E3 F3 G3 A3 D4 F4 A4 D5 F5
GuitarrónChileno       Standard                           F#5 A4 D4 D4 D3 D3 D2 G4 G4 G4 G3 G3 C4 C4 C3 C2 E4 E4 E4 A4 A4 A4 G4 B4
LaudPhillipines        Standard                           F#2 B2 B2 E3 E3 A3 A3 A3 D4 D4 D4 G4 G4 G4
LiutoAttiorbatoTheorbo Standard                           F1 F2 G1 G2 A1 A2 B1 B2 C2 C3 D2 D3 E2 E3 F2 F2 G2 G2 C3 C3 F3 F3 A3 A3 D4 D4 G4
Octavina               Standard                           F#2 B2 B2 E3 E3 A3 A3 A3 D4 D4 D4 G4 G4 G4
SächsischeTheorbenzister Standard                           B2 C2 D3 E3 F3 G3 A3 B3 C4 C4 F4 F4 A4 A4 C4 C4
SwedishLute            Standard                           A2 B2 C#3 D3 E3 F#3 G3 A3 B3 C#4 D4 E4 A4 C#5 E5
TheorboFifteenCourse   Standard                           F2 G2 A2 B2 C3 D3 E3 F3 G3 A3 D4 G4 B4 E4 A4
ViolaDaTerceiraFifteenStrings Standard                           E3 E3 E2 A3 A3 A2 D3 D3 D2 G3 G2 B3 B3 E3 E3
ElectricGuitar7        StandardB                          B1 E2 A2 D3 G3 B3 E4
                       DropA                              A1 E2 A2 D3 G3 B3 E4
                       AllFourths                         B1 E2 A2 D3 G3 C4 F4
                       OpenG                              B1 G2 D3 G3 B3 D4 G4
ElectricGuitar8        StandardF#                         F#1 B1 E2 A2 D3 G3 B3 E4
                       DropE                              E1 B1 E2 A2 D3 G3 B3 E4
                       LowEStandard                       E1 A1 D2 G2 C3 F3 A3 D4
GuitarExtendedTunings  Nashville                          E3 A3 D4 G4 B3 E4
                       CStandard                          C2 F2 Bb2 Eb3 G3 C4
                       OpenC6                             C2 G2 C3 G3 A3 E4
                       AllFourths                         E2 A2 D3 G3 C4 F4
BassGuitarExtended     DropD                              D1 A1 D2 G2
                       BEAD                               B0 E1 A1 D2
                       Tenor                              A1 D2 G2 C3
                       Piccolo                            E2 A2 D3 G3
                       FretlessStandard                   E1 A1 D2 G2
BaritoneUkulele        Standard                           D4 G3 B3 E4
                       LowGReentrant                      D4 G4 B3 E4
SopraninoUkulele       Standard                           D5 G4 B4 E5
OctaveMandolin         Standard                           G2 G2 D3 D3 A3 A3 E4 E4
                       GDAD                               G2 G2 D3 D3 A3 A3 D4 D4
IrishTenorBanjo        GDAE                               G2 D3 A3 E4
Oud                    Arabic                             C2 F2 A2 D3 G3 C4
                       Turkish                            C#2 F#2 B2 E3 A3 D4
Shamisen               Honchoshi                          C4 G4 C5
                       Niagari                            C4 G4 D5
                       Sansagari                          C4 F4 C5
Ngoni                  Pentatonic                         D3 A3 D4 E4 A4
Kora                   Standard                           G2 A2 C3 D3 E3 G3 A3 C4 D4 E4 F4 G4 A4 C5 D5
Sarod                  Standard                           C#2 G#2 C#3 F#3 B3 E4
Gayageum               HeptatonicG                        G2 A2 B2 D3 E3 G3 A3
Santoor                Kashmir                            C3 C3 D3 D3 E3 E3 F3 F3 G3 G3 A3 A3 Bb3 Bb3 C4 C4
HarpGuitar             Standard6PlusSubs                  E2 A2 D3 G3 B3 E4 | A1 G1 F1
                       DADGADPlusSubs                     D2 A2 D3 G3 A3 D4 | A1 G1 F1
AllFourthsguitar       EADGCF                             E2 A2 D3 G3 C4 F4
```

## GA's four constants

Four tunings are also written in C#, in [`Tuning`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Instruments/Tuning.cs#L20-L39), and those are the ones the code actually uses.

```text
== The tunings GA's own constants use
constant               course                   GA                       check
Tuning.Default         E2 A2 D3 G3 B3 E4        E2 A2 D3 G3 B3 E4        ok
Tuning.Ukulele         G4 C4 E4 A4              G4 C4 E4 A4              ok
Tuning.Bass            E1 A1 D2 G2              E1 A1 D2 G2              ok
Tuning.Guitar7String   B1 E2 A2 D3 G3 B3 E4     B1 E2 A2 D3 G3 B3 E4     ok

Four constants against 280 tunings in the file: everything else needs the catalogue.
```

All four are correct. They are also the whole of the instrument support that works today: everything else in this appendix is a file nothing reads.

## Sources

- GuitarAlchemist/ga at [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): [`Instruments.yaml`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/Instruments.yaml), [`InstrumentsConfig.fs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/InstrumentsConfig.fs), [`ConfigFileLocator.fs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/ConfigFileLocator.fs), [`Tuning.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Instruments/Tuning.cs).
- [YamlDotNet](https://github.com/aaubry/YamlDotNet), the deserialiser the loader uses.
- The course program: [`Lesson9.cs`](https://github.com/spareilleux/learn/blob/main/code/music-theory-ga/GaTheory/Lesson9.cs), [`Instruments.cs`](https://github.com/spareilleux/learn/blob/main/code/music-theory-ga/GaTheory/Instruments.cs), [`expected/l9.txt`](https://github.com/spareilleux/learn/blob/main/code/music-theory-ga/expected/l9.txt).
