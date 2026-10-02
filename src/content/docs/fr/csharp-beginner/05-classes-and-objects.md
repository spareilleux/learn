---
title: 5. Classes et objets
description: Réunir données et comportement dans une classe, créer des objets, les initialiser avec un constructeur et contrôler l'accès par les champs et propriétés.
sidebar:
  order: 5
---

Dans la leçon 4, les méthodes recevaient des valeurs séparées : le nom d'une corde, sa fréquence à vide et un numéro de frette. Quand un programme grandit, transmettre toujours les mêmes valeurs à chaque méthode devient encombrant. Une [classe](https://learn.microsoft.com/dotnet/csharp/fundamentals/types/classes) réunit les données et les opérations qui vont ensemble. Un **objet** est une instance concrète de cette classe. `GuitarString` ci-dessous est une classe ; la corde de mi grave et la corde de la sont deux objets qui portent des données différentes.

Exécute le programme de [`code/csharp-beginner`](https://github.com/spareilleux/learn/tree/main/code/csharp-beginner) avec [`dotnet run`](https://learn.microsoft.com/dotnet/core/tools/dotnet-run) `examples/l05_objects.cs`. Sa sortie est vérifiée par `check.sh`. Le programme utilise [`Console.WriteLine`](https://learn.microsoft.com/dotnet/api/system.console.writeline) pour afficher du texte, [`Math.Pow`](https://learn.microsoft.com/dotnet/api/system.math.pow) pour calculer la fréquence sur une frette et [`CultureInfo.InvariantCulture`](https://learn.microsoft.com/dotnet/api/system.globalization.cultureinfo.invariantculture) pour conserver le même point décimal sur toutes les machines.

```csharp
using System.Globalization;

GuitarString lowE = new GuitarString("E2", 82.41);
GuitarString a = new GuitarString("A2", 110.0);

Console.WriteLine($"{lowE.Name}: {lowE.FrequencyAt(12).ToString("F2", CultureInfo.InvariantCulture)} Hz");
Console.WriteLine($"Created: {GuitarString.CreatedCount}");

GuitarString sameString = lowE;
sameString.Rename("E2 (retuned)");
Console.WriteLine(lowE.Name);
Console.WriteLine(a.Name);

sealed class GuitarString
{
    private readonly double _openHz;

    public string Name { get; private set; }
    public double OpenHz => _openHz;
    public static int CreatedCount { get; private set; }

    public GuitarString(string name, double openHz)
    {
        Name = name;
        _openHz = openHz;
        CreatedCount++;
    }

    public void Rename(string name) => Name = name;

    public double FrequencyAt(int fret) => _openHz * Math.Pow(2, fret / 12.0);
}
```

```text
E2: 164.82 Hz
Created: 2
E2 (retuned)
A2
```

## De la classe à l'objet

La déclaration `class` définit un nouveau type. `new GuitarString("E2", 82.41)` crée un objet et appelle son **constructeur**. Le second `new` crée un autre objet. Le constructeur porte le nom de la classe, n'a pas de type de retour et reçoit les valeurs initiales en paramètres. Ici, chaque objet possède un nom et une fréquence à vide dès sa création. Le [guide des constructeurs](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/constructors) présente d'autres formes d'initialisation.

`lowE.FrequencyAt(12)` appelle une **méthode d'instance** : elle emploie le champ `_openHz` de cet objet. `a.FrequencyAt(12)` utiliserait plutôt les 110 Hz de la corde de la. Une méthode placée dans une classe peut lire ses champs et propriétés sans recevoir l'objet entier en paramètre.

`sameString = lowE` ne crée **pas** une troisième corde. Une variable de type classe contient une référence vers un objet : les deux variables désignent maintenant le même objet. Le changement de nom fait par `sameString` est donc visible via `lowE`. L'objet `a`, distinct, conserve son nom. C'est différent du paramètre `int` copié dans la leçon 4 ; la leçon 6 approfondit la différence entre types valeur et référence.

## Champs, propriétés et accès

Le [champ](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/fields) privé `_openHz` stocke une valeur dans chaque objet. `private` empêche le code extérieur à `GuitarString` d'accéder à ce nom. `readonly` permet au constructeur d'initialiser le champ, mais interdit ensuite aux méthodes de lui attribuer une nouvelle valeur. La [propriété](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/properties) publique `OpenHz` permet de lire la valeur sans exposer le champ en écriture.

`Name` est une **propriété automatique**. Son `get` est public, mais son `set` est privé. Le code appelant peut lire `lowE.Name` ; il doit appeler `Rename` pour le modifier. Ainsi, la classe décide quelles opérations ont du sens, au lieu d'autoriser la modification directe de toutes ses données. Le modificateur `sealed` indique qu'on ne peut pas dériver de cette classe d'introduction ; l'héritage vient à la leçon 7.

Essaie d'accéder au champ privé depuis l'extérieur. Cet exemple minimal, indépendant du premier, donne à `GuitarString` un constructeur à un paramètre :

```csharp
GuitarString lowE = new GuitarString(82.41);
Console.WriteLine(lowE._openHz);
```

Le programme rejeté `compile_fail/l05_private_field.cs` produit ce vrai diagnostic du compilateur :

```text
l05_private_field.cs(2,24): error CS0122: 'GuitarString._openHz' is inaccessible due to its protection level
```

Attribuer une valeur de l'extérieur à la propriété accessible en lecture seule échoue aussi. Le programme `compile_fail/l05_get_only_property.cs` contient `lowE.OpenHz = 110.0;` et produit :

```text
l05_get_only_property.cs(2,1): error CS0200: Property or indexer 'GuitarString.OpenHz' cannot be assigned to -- it is read only
```

Ces erreurs aident à comprendre l'interface de la classe : utilise ses opérations publiques, ou modifie délibérément sa conception. Ne rends pas tous les champs publics uniquement pour faire taire le compilateur.

## Un membre partagé par tous les objets

`CreatedCount` porte le [modificateur `static`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/static). Il appartient à la classe `GuitarString`, pas à une corde particulière. Chaque appel au constructeur augmente le même compteur ; le programme le lit avec `GuitarString.CreatedCount`, et non `lowE.CreatedCount`. À l'inverse, `_openHz`, `Name` et `FrequencyAt` appartiennent chacun à un objet.

Ce compteur sert ici à apprendre : il compte les constructions, pas les objets encore présents en mémoire.

## Exercice 1 — prévoir les références

Sans lancer le programme, prévois la valeur de `lowE.Name`, `sameString.Name` et `a.Name` juste après `sameString.Rename("E2 (retuned)")`. Quelles variables désignent le même objet ? Lance ensuite `examples/l05_objects.cs` pour vérifier.

<details>
<summary>Solution</summary>

`lowE.Name` et `sameString.Name` valent tous deux `E2 (retuned)` : ces variables désignent un seul objet. `a.Name` vaut toujours `A2` : c'est un autre objet. Le programme affiche la première et la troisième de ces valeurs dans ses deux dernières lignes.

</details>

## Exercice 2 — une séance de travail

Crée une classe `PracticeSession` avec un constructeur qui reçoit un sujet, une propriété `Topic` en lecture seule, un champ privé pour les minutes, une méthode `AddMinutes(int)` et une méthode `Summary()`. Crée deux séances ; ajoute 20 puis 15 minutes à la première, et 10 à la seconde. Affiche les deux résumés. La première doit toujours indiquer 35 minutes après la modification de la seconde. Pour l'instant, suppose que les minutes sont positives ou nulles ; la leçon 8 montrera comment refuser une entrée invalide. La solution testée se trouve dans `exercises/l05_ex_practice.cs`.

<details>
<summary>Solution</summary>

```csharp
PracticeSession scales = new PracticeSession("Scales");
scales.AddMinutes(20);
scales.AddMinutes(15);

PracticeSession chords = new PracticeSession("Chords");
chords.AddMinutes(10);

Console.WriteLine(scales.Summary());
Console.WriteLine(chords.Summary());
Console.WriteLine(scales.Summary());

sealed class PracticeSession
{
    private int _minutes;

    public string Topic { get; }

    public PracticeSession(string topic)
    {
        Topic = topic;
    }

    public void AddMinutes(int minutes)
    {
        _minutes += minutes;
    }

    public string Summary() => $"{Topic}: {_minutes} min";
}
```

```text
Scales: 35 min
Chords: 10 min
Scales: 35 min
```

Les deux objets ont chacun leur propre champ `_minutes`. Le constructeur fixe `Topic`, que le code appelant ne peut plus changer directement.

</details>

## Ce qu'il faut retenir

- Une classe définit un type ; `new` crée un objet de ce type.
- Le constructeur donne son état initial à chaque nouvel objet.
- Un champ privé est une donnée interne ; une propriété ou méthode publique constitue un accès choisi.
- Un membre d'instance appartient à un objet ; un membre `static` appartient au type.
- Affecter une variable de type classe à une autre copie la référence, pas l'objet.

La suite, [records, structures et énumérations](../#plan), comparera les classes aux types pensés comme des valeurs.
