---
title: "Apéndice A: todos los instrumentos de Guitar Alchemist"
description: Los 122 instrumentos y las 280 afinaciones del Instruments.yaml de GA, leídos por el programa del curso, y lo que devuelve el propio cargador de configuración de GA para el mismo archivo.
sidebar:
  label: "Apéndice A: todos los instrumentos"
  order: 90
---

La lección 1 usa un instrumento y la lección 8 usa tres. La configuración de GA contiene muchísimos más: [`Instruments.yaml`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/Instruments.yaml) son 1589 líneas de ellos, de la balalaica al pedal steel. Este apéndice los enumera todos, tal como los lee el programa del curso, y lo compara con lo que el propio cargador de GA devuelve al resto de GA.

```bash
dotnet run --project code/music-theory-ga/GaTheory -c Release -- l9
```

## El titular

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

Un instrumento. Dos afinaciones. El archivo con 122 instrumentos y 280 afinaciones se encuentra, se abre y se lee, y luego se descarta.

La razón es un desajuste de forma, y vale la pena seguirle la pista porque nada parece incorrecto en ninguno de los dos extremos. [`InstrumentsConfig`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/InstrumentsConfig.fs) declara el tipo que espera:

```fsharp
type InstrumentsYaml =
    { Instruments: ResizeArray<System.Collections.Generic.IDictionary<string, obj>> }
```

Quiere un documento con una sola clave, `Instruments`, que contiene una **lista**. Cada elemento debería ser un diccionario con un `Name` y una lista `Tunings` de pares `{ Name, Tuning }`. El archivo no tiene esa forma en absoluto: es un **mapa de instrumentos en el nivel superior**, cada uno un mapa de afinaciones.

```yaml
Ukulele:
  DisplayName: "Ukulele"
  SopranoConcertAndTenorC:
    DisplayName: "Soprano Concert And Tenor C"
    Tuning: C6 G4 C4 E4 A4
```

No hay ninguna clave `Instruments` en ninguna parte del archivo, ni ninguna lista `Tunings` tampoco. Por eso [YamlDotNet](https://github.com/aaubry/YamlDotNet) produce o bien un record cuyo único campo es nulo, o bien lanza una excepción por las propiedades que no encajan, y `loadInstrumentsData` trata los dos casos igual:

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

`defaultData ()` es una guitarra con una afinación estándar y una drop D, escrita en el código F# como un "minimal built-in dataset so tests and core features can work". Todos los caminos que atraviesan el cargador llegan hasta ahí, así que `getAllInstruments`, `listAllInstrumentNames`, `listAllInstrumentTunings`, `findInstrumentsByName` y `tryGetInstrument` responden todos a partir de dos afinaciones de guitarra escritas a mano, y siempre lo han hecho. Nada falla, nada se registra, y quien pida la afinación del ukelele recibe `None` en lugar de un error.

:::note[Cómo se ha comprobado esto]
No leyendo el código. El programa del curso referencia `GA.Business.Config` como proyecto y llama directamente a `InstrumentsConfig.getAllInstruments()`; las cifras de la tabla anterior son su valor de retorno, comparado con la lectura que el propio curso hace del mismo archivo en la misma ejecución, en la CI, en tres sistemas operativos.
:::

Esta es la razón de que las afinaciones de cinco alturas del ukelele y la octava equivocada del barítono, en la lección 8, no hayan mordido nunca a nadie: ningún programa las ha leído jamás. También significa que, en este commit, el catálogo es documentación y no configuración.

## Cómo sería un arreglo

Dos opciones, y el archivo no elige ninguna:

- **Cambiar el cargador a la forma del archivo**: deserializar en un `IDictionary<string, IDictionary<string, obj>>`, tratar como afinación cada mapa anidado que tenga una clave `Tuning` y como metadatos todas las demás claves (`DisplayName`, `Icon`). Es más o menos lo que hace el lector de 30 líneas del propio curso, y no exige tocar el archivo de 1589 líneas.
- **Cambiar el archivo a la forma del cargador**: reescribirlo como `Instruments:` seguido de una lista. Es una edición grande, mecánica y propensa a errores sobre unos datos que ya son correctos.

La primera es claramente la más barata. En cualquier caso, el cargador debería avisar cuando recurre al valor por defecto: un valor por defecto silencioso que es 1/122 de los datos reales es peor que una excepción, porque no hay manera de notarlo.

## Siete afinaciones que no son alturas

El lector del curso convierte cada línea `Tuning:` en una lista de alturas. Siete líneas no sobreviven a eso.

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

Cuatro tipos de error:

- **El nombre de una afinación escrito como una altura.** `PedalSteelGuitar.T1` empieza por `C6` y `T2` por `E9`; [C6 y E9](https://en.wikipedia.org/wiki/Pedal_steel_guitar) son los nombres de las dos configuraciones estándar del pedal steel, no notas. El mismo desliz puso `C6` y `D6` al frente de las cuatro afinaciones de ukelele de la lección 8, y esas *sí* se analizan como alturas, así que aquí son invisibles. Las líneas que fallan a gritos son las afortunadas.
- **Una palabra donde debería ir una lista.** `Saz.BaglamaBozukDuzenSevenStrings` empieza por la palabra literal `Tuning`; `Huapanguera.Standard` es una sola palabra, `Huapanguera`, el nombre del propio instrumento, sin ninguna afinación.
- **Una octava que falta.** `Dulcimer.LydianMode` es `Bb C4 C4 F3 Bb2`: el primer `Bb` no lleva número de octava, cuando todos los demás tokens llevan uno.
- **Un separador con un significado.** Las dos entradas de guitarra arpa usan `|` para separar las seis cuerdas pisadas de las tres cuerdas de subgraves. Es una distinción real para la que el formato no tiene ningún campo, así que se escribió dentro del valor.

`PedalSteelGuitar.T2` mezcla además dos grafías dentro de una misma afinación —`G#4` y `Eb4` en la misma lista—, algo que, como muestra la lección 3, GA no puede representar de forma coherente de todos modos.

## Afinaciones que aparecen bajo varios instrumentos

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

La mayoría de ellas son correctas e informativas más que erróneas: un banjo de guitarra está afinado de verdad como una guitarra, una guitarra tenor está afinada de verdad como un banjo tenor, un mandobajo está afinado de verdad como un bajo eléctrico. Leída al revés, la lista es un mapa de qué instrumentos comparten digitación: lo más útil del archivo para quien toca, y justo lo que el esquema de GA no tiene forma de expresar.

La fila del ukelele es la excepción: `Ukulele.SopranoConcertAndTenorC` y `Ukulele.BanjoOrBanjoleteC` son la afinación de un mismo instrumento introducida dos veces, las dos con el mismo error de cinco alturas.

## Cuántas alturas tiene cada afinación

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

El archivo guarda alturas, no cuerdas, y de un instrumento de órdenes dobles guarda todas las cuerdas de todos los órdenes: una mandolina son ocho alturas en cuatro pares, una guitarra de doce cuerdas son doce. Nada en el formato dice qué alturas pertenecen al mismo orden, así que quien lo lea no puede distinguir una mandolina de una guitarra de ocho cuerdas ni —como muestra el tercer ejercicio de la lección 8— un orden doble de una cuerda reentrante. Un campo `Courses:`, o escribir cada orden como un solo token, lo arreglaría.

## Todos los instrumentos y todas las afinaciones

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

## Las cuatro constantes de GA

Cuatro afinaciones están escritas además en C#, en [`Tuning`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Instruments/Tuning.cs#L20-L39), y son las que el código usa de verdad.

```text
== The tunings GA's own constants use
constant               course                   GA                       check
Tuning.Default         E2 A2 D3 G3 B3 E4        E2 A2 D3 G3 B3 E4        ok
Tuning.Ukulele         G4 C4 E4 A4              G4 C4 E4 A4              ok
Tuning.Bass            E1 A1 D2 G2              E1 A1 D2 G2              ok
Tuning.Guitar7String   B1 E2 A2 D3 G3 B3 E4     B1 E2 A2 D3 G3 B3 E4     ok

Four constants against 280 tunings in the file: everything else needs the catalogue.
```

Las cuatro son correctas. Son también todo el soporte de instrumentos que funciona hoy: todo lo demás de este apéndice es un archivo que nadie lee.

## Fuentes

- GuitarAlchemist/ga en [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): [`Instruments.yaml`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/Instruments.yaml), [`InstrumentsConfig.fs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/InstrumentsConfig.fs), [`ConfigFileLocator.fs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/ConfigFileLocator.fs), [`Tuning.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Instruments/Tuning.cs).
- [YamlDotNet](https://github.com/aaubry/YamlDotNet), el deserializador que usa el cargador.
- El programa del curso: [`Lesson9.cs`](https://github.com/spareilleux/learn/blob/main/code/music-theory-ga/GaTheory/Lesson9.cs), [`Instruments.cs`](https://github.com/spareilleux/learn/blob/main/code/music-theory-ga/GaTheory/Instruments.cs), [`expected/l9.txt`](https://github.com/spareilleux/learn/blob/main/code/music-theory-ga/expected/l9.txt).
