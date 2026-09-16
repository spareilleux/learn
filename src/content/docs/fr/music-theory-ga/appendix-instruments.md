---
title: "Annexe A : tous les instruments de Guitar Alchemist"
description: Les 122 instruments et 280 accordages de l'Instruments.yaml de GA, lus par le programme du cours — et ce que le chargeur de configuration de GA lui-même renvoie pour le même fichier.
sidebar:
  label: "Annexe A : tous les instruments"
  order: 90
---

La leçon 1 utilise un instrument et la leçon 8 en utilise trois. La configuration de GA en contient beaucoup d'autres : [`Instruments.yaml`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/Instruments.yaml) en aligne 1589 lignes, de la balalaïka à la pedal steel guitar. Cette annexe les liste tous, tels que le programme du cours les lit, et compare cela avec ce que le chargeur de GA lui-même rend au reste de GA.

```bash
dotnet run --project code/music-theory-ga/GaTheory -c Release -- l9
```

## Le chiffre clé

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

Un instrument. Deux accordages. Le fichier aux 122 instruments et 280 accordages est trouvé, ouvert et lu, puis jeté.

La raison est une inadéquation de forme, et elle vaut la peine d'être suivie parce que rien n'a l'air faux à l'une ou l'autre extrémité. [`InstrumentsConfig`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/InstrumentsConfig.fs) déclare le type qu'il attend :

```fsharp
type InstrumentsYaml =
    { Instruments: ResizeArray<System.Collections.Generic.IDictionary<string, obj>> }
```

Il veut un document avec une seule clé, `Instruments`, contenant une **liste**. Chaque élément devrait être un dictionnaire avec un `Name` et une liste `Tunings` de paires `{ Name, Tuning }`. Le fichier n'a pas du tout cette forme : c'est une **correspondance d'instruments au niveau racine**, chacun étant une correspondance d'accordages.

```yaml
Ukulele:
  DisplayName: "Ukulele"
  SopranoConcertAndTenorC:
    DisplayName: "Soprano Concert And Tenor C"
    Tuning: C6 G4 C4 E4 A4
```

Il n'y a nulle part de clé `Instruments` dans le fichier, ni de liste `Tunings` nulle part non plus. [YamlDotNet](https://github.com/aaubry/YamlDotNet) produit donc soit un record dont l'unique champ est null, soit une exception sur les propriétés non appariées — et `loadInstrumentsData` traite les deux cas de la même façon :

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

`defaultData ()`, c'est une guitare avec un accordage standard et un drop D, décrite dans la source F# comme un "minimal built-in dataset so tests and core features can work". Tous les chemins du chargeur y aboutissent, si bien que `getAllInstruments`, `listAllInstrumentNames`, `listAllInstrumentTunings`, `findInstrumentsByName` et `tryGetInstrument` répondent tous à partir de deux accordages de guitare écrits en dur, et l'ont toujours fait. Rien n'échoue, rien n'est journalisé, et un appelant qui demande l'accordage du ukulélé reçoit `None` plutôt qu'une erreur.

:::note[Comment cela a été vérifié]
Pas par la lecture. Le programme du cours référence `GA.Business.Config` comme projet et appelle `InstrumentsConfig.getAllInstruments()` directement ; les nombres du tableau ci-dessus sont sa valeur de retour, comparée à la lecture que le cours fait lui-même du même fichier, sur la même exécution, en CI, sur trois systèmes d'exploitation.
:::

C'est la raison pour laquelle les accordages à cinq hauteurs du ukulélé et la mauvaise octave du baryton, dans la leçon 8, n'ont jamais gêné personne : aucun programme ne les a jamais lus. Cela veut dire aussi que le catalogue est, à ce commit, de la documentation plutôt que de la configuration.

## À quoi ressemblerait un correctif

Deux options, et le fichier n'en choisit aucune :

- **Adapter le chargeur à la forme du fichier** — désérialiser vers `IDictionary<string, IDictionary<string, obj>>`, traiter chaque correspondance imbriquée qui a une clé `Tuning` comme un accordage et toute autre clé (`DisplayName`, `Icon`) comme des métadonnées. C'est à peu près ce que fait le lecteur de 30 lignes du cours, et cela ne demande aucun changement au fichier de 1589 lignes.
- **Adapter le fichier à la forme du chargeur** — le réécrire avec `Instruments:` suivi d'une liste. C'est une modification vaste, mécanique et propice aux erreurs, sur des données déjà justes.

La première est nettement la moins chère. Dans les deux cas, le chargeur devrait le dire quand il retombe sur les valeurs par défaut : un défaut silencieux qui représente 1/122 des données réelles est pire qu'une exception, parce qu'il ne peut pas être remarqué.

## Sept accordages qui ne sont pas des hauteurs

Le lecteur du cours transforme chaque ligne `Tuning:` en une liste de hauteurs. Sept lignes n'y survivent pas.

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

Quatre sortes d'erreurs :

- **Le nom d'un accordage écrit comme une hauteur.** `PedalSteelGuitar.T1` commence par `C6` et `T2` par `E9` ; [C6 et E9](https://en.wikipedia.org/wiki/Pedal_steel_guitar) sont les noms des deux configurations standard de pedal steel, pas des notes. Le même glissement a mis `C6` et `D6` en tête des quatre accordages de ukulélé de la leçon 8 — et ceux-là, eux, s'analysent *bel et bien* comme des hauteurs, donc ils sont invisibles ici. Les lignes qui échouent bruyamment sont les chanceuses.
- **Un mot là où devrait être une liste.** `Saz.BaglamaBozukDuzenSevenStrings` commence par le mot `Tuning` lui-même ; `Huapanguera.Standard` est le seul mot `Huapanguera`, le nom de l'instrument, sans aucun accordage.
- **Une octave manquante.** `Dulcimer.LydianMode`, c'est `Bb C4 C4 F3 Bb2` : le premier `Bb` n'a pas de numéro d'octave là où tous les autres jetons en ont un.
- **Un séparateur porteur de sens.** Les deux entrées de guitare-harpe utilisent `|` pour séparer les six cordes frettées des trois cordes sous-basses. C'est une vraie distinction pour laquelle le format n'a pas de champ, alors elle a été écrite dans la valeur.

`PedalSteelGuitar.T2` mélange aussi les orthographes à l'intérieur d'un même accordage — `G#4` et `Eb4` dans la même liste — ce que la leçon 3 montre que GA ne sait de toute façon pas représenter de manière cohérente.

## Des accordages qui apparaissent sous plusieurs instruments

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

La plupart sont correctes et instructives plutôt que fausses : un banjo-guitare est bien accordé comme une guitare, une guitare ténor est bien accordée comme un banjo ténor, une mandobasse est bien accordée comme une basse. Lue dans l'autre sens, la liste est une carte des instruments qui partagent un doigté — la chose la plus utile du fichier pour un joueur, et celle que le schéma de GA n'a aucun moyen d'exprimer.

La ligne du ukulélé est l'exception : `Ukulele.SopranoConcertAndTenorC` et `Ukulele.BanjoOrBanjoleteC` sont l'accordage d'un même instrument saisi deux fois, tous deux avec la même erreur des cinq hauteurs.

## La longueur des accordages

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

Le fichier stocke des hauteurs, pas des cordes, et pour un instrument à chœurs doublés il stocke chaque corde de chaque chœur : une mandoline, ce sont huit hauteurs en quatre paires, une guitare douze cordes en compte douze. Rien dans le format ne dit quelles hauteurs appartiennent au même chœur, si bien qu'un lecteur ne peut pas distinguer une mandoline d'une guitare huit cordes ni — comme le montre le troisième exercice de la leçon 8 — un chœur doublé d'une corde rentrante. Un champ `Courses:`, ou l'écriture d'un chœur en un seul jeton, réglerait la question.

## Tous les instruments et tous les accordages

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

## Les quatre constantes de GA

Quatre accordages sont aussi écrits en C#, dans [`Tuning`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Instruments/Tuning.cs#L20-L39), et ce sont ceux que le code utilise réellement.

```text
== The tunings GA's own constants use
constant               course                   GA                       check
Tuning.Default         E2 A2 D3 G3 B3 E4        E2 A2 D3 G3 B3 E4        ok
Tuning.Ukulele         G4 C4 E4 A4              G4 C4 E4 A4              ok
Tuning.Bass            E1 A1 D2 G2              E1 A1 D2 G2              ok
Tuning.Guitar7String   B1 E2 A2 D3 G3 B3 E4     B1 E2 A2 D3 G3 B3 E4     ok

Four constants against 280 tunings in the file: everything else needs the catalogue.
```

Tous les quatre sont corrects. Ils sont aussi la totalité du support d'instruments qui fonctionne aujourd'hui : tout le reste de cette annexe est un fichier que rien ne lit.

## Sources

- GuitarAlchemist/ga au commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) : [`Instruments.yaml`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/Instruments.yaml), [`InstrumentsConfig.fs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/InstrumentsConfig.fs), [`ConfigFileLocator.fs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/ConfigFileLocator.fs), [`Tuning.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Instruments/Tuning.cs).
- [YamlDotNet](https://github.com/aaubry/YamlDotNet), le désérialiseur qu'utilise le chargeur.
- Le programme du cours : [`Lesson9.cs`](https://github.com/spareilleux/learn/blob/main/code/music-theory-ga/GaTheory/Lesson9.cs), [`Instruments.cs`](https://github.com/spareilleux/learn/blob/main/code/music-theory-ga/GaTheory/Instruments.cs), [`expected/l9.txt`](https://github.com/spareilleux/learn/blob/main/code/music-theory-ga/expected/l9.txt).
