---
title: 7. Interfaces et héritage
description: Construire une classe sur une autre par héritage, remplacer des méthodes virtuelles avec override, les exiger avec une classe abstraite et partager un contrat entre types sans lien avec une interface.
sidebar:
  order: 7
---

Les classes des leçons 5 et 6 étaient toutes `sealed` : on ne pouvait rien construire dessus. Pourtant, une guitare et un ukulélé sont tous deux des instruments à cordes, avec le même genre de données, un nom et un accordage, et presque le même comportement. C# permet à une classe d'[**hériter**](https://learn.microsoft.com/dotnet/csharp/fundamentals/object-oriented/inheritance) d'une autre et de ne changer que ce qui diffère. Cette leçon présente l'héritage, `virtual` et `override`, les classes abstraites et les interfaces. Une idée les relie, le [**polymorphisme**](https://learn.microsoft.com/dotnet/csharp/fundamentals/object-oriented/polymorphism) : le même appel, `instrument.Describe()`, exécute un code différent selon l'objet.

Tous les programmes de cette leçon sont dans [`code/csharp-beginner`](https://github.com/spareilleux/learn/tree/main/code/csharp-beginner) ; lance-en un avec [`dotnet run`](https://learn.microsoft.com/dotnet/core/tools/dotnet-run) suivi de son chemin, par exemple `examples/l07_inheritance.cs`. `check.sh` compare leurs sorties, et les erreurs du compilateur pour les extraits refusés, aux fichiers de `expected/`.

## L'héritage : une classe construite sur une autre

```csharp
// Guitar et Ukulele dérivent de StringInstrument : ils héritent de ses membres
List<StringInstrument> instruments = [new Guitar(), new Ukulele()];

foreach (StringInstrument instrument in instruments)
{
    // La variable est de type StringInstrument ; la classe de l'objet choisit le Describe exécuté
    Console.WriteLine(instrument.Describe());
}

Guitar guitar = new Guitar();
Console.WriteLine($"{guitar.Name} has {guitar.StringCount} strings and {guitar.FretCount} frets");
Console.WriteLine(guitar);                  // Console.WriteLine appelle la redéfinition de ToString

class StringInstrument
{
    public string Name { get; }
    public string[] Tuning { get; }

    public StringInstrument(string name, string[] tuning)
    {
        Name = name;
        Tuning = tuning;
    }

    public int StringCount => Tuning.Length;

    public virtual string Describe() => $"{Name}: {string.Join(" ", Tuning)}";

    public override string ToString() => $"{Name} ({StringCount} strings)";
}

sealed class Guitar : StringInstrument
{
    public int FretCount => 22;

    public Guitar() : base("Guitar", ["E2", "A2", "D3", "G3", "B3", "E4"])
    {
    }
}

sealed class Ukulele : StringInstrument
{
    public Ukulele() : base("Ukulele", ["G4", "C4", "E4", "A4"])
    {
    }

    public override string Describe() => base.Describe() + ", re-entrant: G4 is above C4";
}
```

```text
Guitar: E2 A2 D3 G3 B3 E4
Ukulele: G4 C4 E4 A4, re-entrant: G4 is above C4
Guitar has 6 strings and 22 frets
Guitar (6 strings)
```

`class Guitar : StringInstrument` indique que `Guitar` **dérive** de `StringInstrument`, sa **classe de base**. Une `Guitar` possède tout ce que possède un `StringInstrument`, `Name`, `Tuning`, `StringCount`, `Describe` et `ToString`, plus sa propre `FretCount`. Les constructeurs font exception : ils ne s'héritent pas. Le constructeur `Guitar()` appelle celui de la classe de base avec [`base(...)`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/base) et lui transmet le nom et l'accordage dont il a besoin.

[`virtual`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/virtual) signale une méthode que les classes dérivées peuvent remplacer, et [`override`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/override) la remplace. `Ukulele` redéfinit `Describe` et appelle la version qu'il remplace avec `base.Describe()` : il complète le texte au lieu de tout réécrire. `Guitar` ne la redéfinit pas et garde la version de base.

La boucle montre le polymorphisme. Sa variable est un `StringInstrument`, et pourtant, pour l'ukulélé, `instrument.Describe()` exécute la version de `Ukulele` : c'est la classe de l'objet qui décide, pas le type de la variable. Une `List<StringInstrument>` peut contenir une `Guitar` et un `Ukulele` parce que chacun *est* un `StringInstrument`.

Toute classe dérive d'[`object`](https://learn.microsoft.com/dotnet/api/system.object), même quand elle ne nomme aucune classe de base. `object` a une méthode virtuelle [`ToString`](https://learn.microsoft.com/dotnet/api/system.object.tostring), qui renvoie par défaut le nom du type et que `Console.WriteLine` appelle pour afficher un objet. `StringInstrument` la redéfinit ; `Console.WriteLine(guitar)` affiche donc `Guitar (6 strings)`. Les records de la leçon 6 écrivent cette redéfinition à ta place.

`Guitar` et `Ukulele` restent [`sealed`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/sealed) : rien n'en dérive. `StringInstrument` ne l'est pas, puisque tout l'intérêt est d'en dériver.

### Trois erreurs avec l'héritage

`override` ne fonctionne que sur une méthode que la classe de base permet de remplacer. Sans `virtual`, l'extrait refusé `compile_fail/l07_override_not_virtual.cs` échoue :

```csharp
class StringInstrument
{
    public string Describe() => "a string instrument";
}

sealed class Ukulele : StringInstrument
{
    public override string Describe() => "a ukulele";
}
```

```text
l07_override_not_virtual.cs(11,28): error CS0506: 'Ukulele.Describe()': cannot override inherited member 'StringInstrument.Describe()' because it is not marked virtual, abstract, or override
```

L'erreur inverse compile, avec un simple avertissement. Dans `examples/l07_hiding_warning.cs`, la méthode de base est `virtual`, mais `Ukulele` oublie `override` :

```csharp
StringInstrument uke = new Ukulele();
Console.WriteLine(uke.Describe());   // la version de base s'exécute : la méthode de Ukulele ne fait que la masquer

Ukulele sameKind = new Ukulele();
Console.WriteLine(sameKind.Describe());   // une variable de type Ukulele trouve la méthode qui masque

class StringInstrument
{
    public virtual string Describe() => "a string instrument";
}

sealed class Ukulele : StringInstrument
{
    public string Describe() => "a ukulele";   // il manque override
}
```

```text
l07_hiding_warning.cs(14,19): warning CS0114: 'Ukulele.Describe()' hides inherited member 'StringInstrument.Describe()'. To make the current member override that implementation, add the override keyword. Otherwise add the new keyword.
a string instrument
a ukulele
```

Sans `override`, la méthode de `Ukulele` ne remplace pas celle de la base ; elle la **masque**, et seule une variable de type `Ukulele` la trouve. Par une variable `StringInstrument`, le programme affiche `a string instrument` : le polymorphisme est perdu, sans erreur. Le [modificateur `new`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/new-modifier) que cite l'avertissement rend le masquage volontaire ; le guide [savoir quand utiliser override et new](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/knowing-when-to-use-override-and-new-keywords) compare les deux. Quand tu débutes et que tu vois [CS0114](https://learn.microsoft.com/dotnet/csharp/misc/cs0114), tu as presque toujours oublié `override`.

Enfin, une classe `sealed` refuse d'être une classe de base. `compile_fail/l07_sealed_base.cs` fait dériver `TwelveString` d'une `Guitar` scellée :

```text
l07_sealed_base.cs(8,22): error CS0509: 'TwelveString': cannot derive from sealed type 'Guitar'
```

## Les classes abstraites : une base qui n'est jamais un objet

Que joue « un instrument » ? Rien : une guitare pince ses cordes, un piano frappe ses touches, un violon se joue à l'archet. Une [**classe abstraite**](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/abstract) décrit une idée générale de ce genre, que seules ses classes dérivées rendent concrète :

```csharp
// Instrument est abstraite : un objet est une Guitar, un Piano ou un Violin, jamais un simple Instrument
Instrument[] band = [new Guitar(), new Piano(), new Violin()];

foreach (Instrument instrument in band)
{
    Console.WriteLine(instrument.Play("A4"));
}

abstract class Instrument
{
    public string Name { get; }

    protected Instrument(string name) => Name = name;

    // Chaque classe dérivée doit dire comment elle joue une note
    public abstract string Play(string note);
}

sealed class Guitar : Instrument
{
    public Guitar() : base("Guitar")
    {
    }

    public override string Play(string note) => $"{Name}: pluck {note}";
}

sealed class Piano : Instrument
{
    public Piano() : base("Piano")
    {
    }

    public override string Play(string note) => $"{Name}: strike the {note} key";
}

sealed class Violin : Instrument
{
    public Violin() : base("Violin")
    {
    }

    public override string Play(string note) => $"{Name}: bow {note}";
}
```

```text
Guitar: pluck A4
Piano: strike the A4 key
Violin: bow A4
```

`public abstract string Play(string note);` n'a pas de corps, seulement un point-virgule. Une méthode abstraite est implicitement virtuelle, et toute classe dérivée qui n'est pas elle-même abstraite doit la redéfinir. `Name` et le constructeur, en revanche, sont écrits une seule fois, dans `Instrument`, et partagés par les trois instruments. Le constructeur est [`protected`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/protected) : seules les classes dérivées peuvent l'appeler.

Le compilateur tient les deux bouts de la règle. `compile_fail/l07_new_abstract.cs` essaie `new Instrument("Kazoo")` :

```text
l07_new_abstract.cs(1,20): error CS0144: Cannot create an instance of the abstract type or interface 'Instrument'
```

Et `compile_fail/l07_missing_override.cs` déclare une `Flute` qui oublie `Play` :

```text
l07_missing_override.cs(9,14): error CS0534: 'Flute' does not implement inherited abstract member 'Instrument.Play(string)'
```

Les modèles d'accords de Guitar Alchemist suivent ce schéma, avec un record. Au commit `5c3a52a`, [`ChordTemplate`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Domain.Core/Theory/Harmony/ChordTemplate.cs#L15-L18) est un `public abstract record` doté d'un `abstract string Name`, et ses deux records dérivés, [`TonalModal`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Domain.Core/Theory/Harmony/ChordTemplate.cs#L44-L46) et [`Analytical`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Domain.Core/Theory/Harmony/ChordTemplate.cs#L66-L68), redéfinissent chacun `Name`.

## Les interfaces : un contrat que tout type peut signer

Un instrument et un chanteur n'ont rien de commun en tant que classes, mais tous deux ont une tessiture, d'une note la plus grave à une note la plus aiguë. Une [**interface**](https://learn.microsoft.com/dotnet/csharp/fundamentals/types/interfaces) énonce un tel contrat, sans code, et n'importe quel type peut le signer :

```csharp
// Une interface est un contrat : une classe et un record le signent, sans classe de base commune
List<IHasRange> performers =
[
    new FrettedInstrument("Guitar", 40, 64, 22),    // cordes à vide de mi2 à mi4, 22 frettes
    new FrettedInstrument("Ukulele", 60, 69, 12),   // cordes à vide de do4 à la4, 12 frettes
    new Voice("Alto", 53, 77),                      // de fa3 à fa5
];

foreach (IHasRange performer in performers)
{
    Console.WriteLine($"{performer.Name}: MIDI {performer.LowestMidi} to {performer.HighestMidi}");
}

foreach (int midi in new[] { 40, 55, 69, 84 })
{
    List<string> names = [];
    foreach (IHasRange performer in performers)
    {
        if (CanPlay(performer, midi))
        {
            names.Add(performer.Name);
        }
    }
    Console.WriteLine($"MIDI {midi}: {string.Join(", ", names)}");
}

bool CanPlay(IHasRange performer, int midi) => midi >= performer.LowestMidi && midi <= performer.HighestMidi;

interface IHasRange
{
    string Name { get; }
    int LowestMidi { get; }
    int HighestMidi { get; }
}

sealed class FrettedInstrument : IHasRange
{
    public string Name { get; }
    public int LowestMidi { get; }
    public int HighestMidi { get; }

    public FrettedInstrument(string name, int lowestOpen, int highestOpen, int frets)
    {
        Name = name;
        LowestMidi = lowestOpen;
        HighestMidi = highestOpen + frets;
    }
}

record Voice(string Name, int LowestMidi, int HighestMidi) : IHasRange;
```

```text
Guitar: MIDI 40 to 86
Ukulele: MIDI 60 to 81
Alto: MIDI 53 to 77
MIDI 40: Guitar
MIDI 55: Guitar, Alto
MIDI 69: Guitar, Ukulele, Alto
MIDI 84: Guitar
```

[`interface IHasRange`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/interface) énumère trois propriétés et aucun code. Un type qui écrit `: IHasRange` après son nom **implémente** l'interface : il doit fournir chacun de ses membres. `FrettedInstrument` calcule sa note la plus aiguë à partir de sa corde à vide la plus aiguë et de son nombre de frettes. Les propriétés positionnelles de `Voice` ont déjà les bons noms et les bons types : le record n'a besoin de rien d'autre. Les deux types n'ont aucune classe de base commune hormis `object`, et pourtant une `List<IHasRange>` les contient tous les deux, et `CanPlay` accepte l'un comme l'autre : elle ne s'appuie que sur le contrat. Les numéros MIDI comptent les demi-tons, 12 par octave, comme les do de la leçon 4 ; les commentaires donnent le nom des notes.

Une classe ne dérive que d'une seule classe de base, mais elle peut implémenter autant d'interfaces qu'elle veut, séparées par des virgules. Le [`PositionLocation`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Domain.Core/Instruments/Positions/PositionLocation.cs#L5) de Guitar Alchemist, le record struct de la leçon 6, en implémente trois : `IStr` et `IFret`, deux interfaces de GA à une seule propriété (par exemple, [`IStr`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Domain.Core/Instruments/Primitives/IStr.cs#L3-L6) ne demande qu'un `Str Str { get; }`), et l'interface .NET [`IComparable<T>`](https://learn.microsoft.com/dotnet/api/system.icomparable-1), qui permet de trier les positions. Les noms d'interfaces commencent par `I`, une convention des [règles de nommage de .NET](https://learn.microsoft.com/dotnet/standard/design-guidelines/names-of-classes-structs-and-interfaces).

Le compilateur vérifie le contrat. Dans `compile_fail/l07_missing_interface_member.cs`, `record Voice(string Name, int LowestMidi) : IHasRange;` n'a pas de `HighestMidi` :

```text
l07_missing_interface_member.cs(11,45): error CS0535: 'Voice' does not implement interface member 'IHasRange.HighestMidi'
```

Alors, classe abstraite ou interface ? Une classe abstraite partage du code et des données : `Name` et son constructeur n'existent qu'une fois, dans `Instrument`, et une classe ne peut avoir que cette seule base. Une interface ne partage qu'un contrat, mais des types qui n'ont rien d'autre en commun, records compris, peuvent tous la signer, en plus d'autres interfaces.

## Exercices

### Exercice 1 — quelle méthode s'exécute ?

Sans le lancer, prévois les quatre lignes qu'affiche `exercises/l07_ex_predict.cs`.

```csharp
StringInstrument a = new Ukulele();
Ukulele b = new Ukulele();
StringInstrument c = new StringInstrument();

Console.WriteLine(a.Describe());
Console.WriteLine(b.Describe());
Console.WriteLine(c.Describe());
Console.WriteLine(a.Family());

class StringInstrument
{
    public virtual string Describe() => "strings";

    public string Family() => "chordophone";
}

sealed class Ukulele : StringInstrument
{
    public override string Describe() => "ukulele, " + base.Describe();
}
```

<details>
<summary>Solution</summary>

```text
ukulele, strings
ukulele, strings
strings
chordophone
```

`a` et `b` désignent des objets `Ukulele` : la redéfinition s'exécute dans les deux cas, quel que soit le type de la variable, et complète le texte de base avec `base.Describe()`. `c` est un simple `StringInstrument`. `Family` n'est pas virtuelle et n'est pas remplacée : tous les objets utilisent la version de base.

</details>

### Exercice 2 — un pédalier

Écris une classe abstraite `Effect` avec un `Name` et une méthode abstraite `string Apply(string sound)`, et deux effets : `Distortion`, qui transforme `E2` en `distortion(E2)`, et `Delay`, qui reçoit un nombre de répétitions et transforme `E2` en `delay(E2, 3)`. Écris ensuite une méthode qui fait passer un son par une `List<Effect>`, dans l'ordre, et renvoie le nom des effets et le résultat. Essaie les deux ordres. La solution testée est `exercises/l07_ex_pedals.cs`.

<details>
<summary>Solution</summary>

```csharp
List<Effect> distortionFirst = [new Distortion(), new Delay(3)];
List<Effect> delayFirst = [new Delay(3), new Distortion()];

Console.WriteLine(Run(distortionFirst, "E2"));
Console.WriteLine(Run(delayFirst, "E2"));

string Run(List<Effect> pedalboard, string sound)
{
    List<string> names = [];
    foreach (Effect effect in pedalboard)
    {
        sound = effect.Apply(sound);
        names.Add(effect.Name);
    }
    return $"{string.Join(" -> ", names)}: {sound}";
}

abstract class Effect
{
    public string Name { get; }

    protected Effect(string name) => Name = name;

    public abstract string Apply(string sound);
}

sealed class Distortion : Effect
{
    public Distortion() : base("Distortion")
    {
    }

    public override string Apply(string sound) => $"distortion({sound})";
}

sealed class Delay : Effect
{
    private readonly int _repeats;

    public Delay(int repeats) : base("Delay") => _repeats = repeats;

    public override string Apply(string sound) => $"delay({sound}, {_repeats})";
}
```

```text
Distortion -> Delay: delay(distortion(E2), 3)
Delay -> Distortion: distortion(delay(E2, 3))
```

`Run` ne sait rien de la distorsion ni du delay : il appelle `Apply` sur chaque `Effect`, et la redéfinition de chaque objet fait le travail. Ajouter un troisième effet, c'est écrire une classe de plus, sans toucher à `Run`. `Delay` garde son nombre de répétitions dans un champ privé, comme à la leçon 5.

</details>

### Exercice 3 — un clavier signe le contrat

Copie `IHasRange` et `Voice` depuis l'exemple sur les interfaces, et ajoute un record `MidiKeyboard(int Keys, int LowestMidi)` qui implémente `IHasRange` : son `Name` vaut `Keyboard (25 keys)` pour 25 touches, et son `HighestMidi` se calcule à partir des deux autres. Affiche la tessiture d'une alto (53 à 77) et d'un clavier de 25 touches qui commence au do3 (48), puis qui peut jouer les notes MIDI 50, 60 et 75. La solution testée est `exercises/l07_ex_keyboard.cs`.

<details>
<summary>Solution</summary>

```csharp
List<IHasRange> performers =
[
    new Voice("Alto", 53, 77),
    new MidiKeyboard(25, 48),       // 25 touches à partir de do3
];

foreach (IHasRange performer in performers)
{
    Console.WriteLine($"{performer.Name}: MIDI {performer.LowestMidi} to {performer.HighestMidi}");
}

foreach (int midi in new[] { 50, 60, 75 })
{
    List<string> names = [];
    foreach (IHasRange performer in performers)
    {
        if (midi >= performer.LowestMidi && midi <= performer.HighestMidi)
        {
            names.Add(performer.Name);
        }
    }
    Console.WriteLine($"MIDI {midi}: {string.Join(", ", names)}");
}

interface IHasRange
{
    string Name { get; }
    int LowestMidi { get; }
    int HighestMidi { get; }
}

record Voice(string Name, int LowestMidi, int HighestMidi) : IHasRange;

record MidiKeyboard(int Keys, int LowestMidi) : IHasRange
{
    public string Name => $"Keyboard ({Keys} keys)";
    public int HighestMidi => LowestMidi + Keys - 1;
}
```

```text
Alto: MIDI 53 to 77
Keyboard (25 keys): MIDI 48 to 72
MIDI 50: Keyboard (25 keys)
MIDI 60: Alto, Keyboard (25 keys)
MIDI 75: Alto
```

`LowestMidi` vient des parenthèses du record, `Name` et `HighestMidi` de propriétés calculées entre ses accolades : l'interface ne se soucie pas de la façon dont un membre est écrit, seulement de son existence. 25 touches à partir de 48 s'arrêtent à 72, pas à 73, car la première touche compte.

</details>

## Ce qu'il faut retenir

- Une classe dérivée hérite des membres de sa classe de base, sauf des constructeurs ; elle appelle le constructeur de base avec `base(...)`.
- `virtual` permet à une classe dérivée de remplacer une méthode, `override` la remplace, et `base.Methode()` appelle la version remplacée.
- C'est la classe de l'objet, et non le type de la variable, qui décide quelle redéfinition s'exécute : c'est le polymorphisme.
- Oublier `override` masque la méthode au lieu de la remplacer (avertissement CS0114).
- Une classe abstraite ne peut pas être instanciée, et ses membres abstraits doivent être redéfinis.
- Une interface est un contrat sans code ; une classe a une seule classe de base mais peut implémenter plusieurs interfaces.

La suite, [exceptions et sécurité face à null](../#plan), traitera des cas où une méthode ne peut pas faire ce qu'on lui demande.

## Sources

- [Héritage](https://learn.microsoft.com/dotnet/csharp/fundamentals/object-oriented/inheritance), [polymorphisme](https://learn.microsoft.com/dotnet/csharp/fundamentals/object-oriented/polymorphism), [`System.Object`](https://learn.microsoft.com/dotnet/api/system.object), [`Object.ToString`](https://learn.microsoft.com/dotnet/api/system.object.tostring)
- Mots-clés : [`virtual`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/virtual), [`override`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/override), [`base`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/base), [`abstract`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/abstract), [`sealed`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/sealed), [`protected`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/protected), [`interface`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/interface), [le modificateur `new`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/new-modifier)
- [Classes abstraites et scellées](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/abstract-and-sealed-classes-and-class-members), [savoir quand utiliser override et new](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/knowing-when-to-use-override-and-new-keywords), [interfaces](https://learn.microsoft.com/dotnet/csharp/fundamentals/types/interfaces), [`IComparable<T>`](https://learn.microsoft.com/dotnet/api/system.icomparable-1)
- [Noms des classes, structures et interfaces](https://learn.microsoft.com/dotnet/standard/design-guidelines/names-of-classes-structs-and-interfaces), [avertissement du compilateur CS0114](https://learn.microsoft.com/dotnet/csharp/misc/cs0114)
