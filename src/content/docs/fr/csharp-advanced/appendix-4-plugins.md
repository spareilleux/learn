---
title: "Annexe 4 : des plugins sans MEF"
description: "Quatre modules chargés par un même hôte, chacun dans son propre AssemblyLoadContext déchargeable, qui inscrivent leurs services dans un seul conteneur d'injection de dépendances — deux versions de Newtonsoft.Json côte à côte, un module qui utilise le service d'un autre sans le référencer, un assembly qui donne deux types, et un minuteur qui garde son module chargé ou non selon ce que capture son rappel. Sept scénarios, chacun prédit avant d'être exécuté, dans une sortie vérifiée sur trois systèmes."
sidebar:
  label: "Annexe 4 : plugins sans MEF"
  order: 92
---

[MEF](https://learn.microsoft.com/dotnet/framework/mef/), le Managed Extensibility Framework, est la façon dont les applications .NET Framework 4 trouvaient leurs plugins : des parties marquées `[Export]` et `[Import]`, un catalogue qui parcourt un dossier, et un conteneur qui relie les parties entre elles. Il est toujours maintenu — sa version allégée, [`System.Composition`](https://www.nuget.org/packages/System.Composition), en est à la 10.0.13 — mais un hôte récent construit en général la même chose avec deux pièces de .NET lui-même :

- un [`AssemblyLoadContext`](https://learn.microsoft.com/dotnet/api/system.runtime.loader.assemblyloadcontext) par module, qui tient les dépendances du module à l'écart de celles des autres et peut être déchargé ;
- le [conteneur d'injection de dépendances](../13-dependency-injection-options/) que l'hôte possède déjà, dans lequel chaque module inscrit ce qu'il offre et dont il reçoit ce dont il a besoin.

L'isolation et le déchargement viennent de la première pièce, pas de l'abandon de MEF : rien n'empêche un hôte MEF de charger lui aussi ses parties dans des contextes déchargeables (non essayé ici). Ce que le conteneur remplace, ce sont les attributs et les catalogues de MEF.

| Rôle | MEF | Ici |
|---|---|---|
| Trouver les parties | un `DirectoryCatalog` parcourt un dossier | l'hôte reçoit l'assembly principal de chaque module et crée son `IModule` |
| Dire ce qu'une partie offre | `[Export(typeof(ITool))]` | `services.AddSingleton<ITool, Spell>()` dans `IModule.Register` |
| Dire ce dont une partie a besoin | `[Import]`, `[ImportingConstructor]` | les paramètres du constructeur |
| Relier les parties | `CompositionContainer` | `ServiceProvider` |
| Tenir à l'écart les dépendances de chaque partie | hors de MEF | un `AssemblyLoadContext` par module |
| Décharger une partie | hors de MEF ; en .NET Framework, un `AppDomain` entier | un contexte déchargeable, dès que plus rien ne le retient |

Cette annexe construit un tel hôte avec quatre petits modules et exécute sept scénarios. Chaque hypothèse a été écrite avant la première exécution, et le [journal](../journal/) les garde. Toutes les prédictions se sont vérifiées ; une mesure, le nombre de collectes qu'un déchargement demande, a fait changer l'hôte.

## L'exécuter

```bash
bash code/csharp-advanced/check.sh       # toutes les leçons et annexes, comparées à expected/
cd code/csharp-advanced
dotnet build Plugins/Plugins.slnx -c Release
dotnet Plugins/Host/bin/Release/net10.0/Host.dll \
  Plugins/ModuleA/bin/Release/net10.0/ModuleA.dll Plugins/ModuleB/bin/Release/net10.0/ModuleB.dll \
  Plugins/ModuleC/bin/Release/net10.0/ModuleC.dll Plugins/ModuleD/bin/Release/net10.0/ModuleD.dll
```

L'hôte ne référence aucun module : il reçoit leurs assemblies principaux sur la ligne de commande, comme un fichier de configuration les lui donnerait. Le code est dans [`code/csharp-advanced/Plugins`](https://github.com/spareilleux/learn/tree/main/code/csharp-advanced/Plugins) :

```text
Plugins/
├── Plugins.slnx  compile l'hôte et les modules
├── Contracts/    IModule, ITool, IChordSpeller : les seuls types qui passent d'un contexte à l'autre
├── Host/         Program.cs : un contexte par module, un conteneur, les sept scénarios
├── ModuleA/      un épeleur d'accords, et un outil qui s'en sert, avec Newtonsoft.Json 13.0.3
├── ModuleB/      un outil qui prend l'épeleur du module A, avec Newtonsoft.Json 13.0.1
├── ModuleC/      un métronome dont l'outil fait tourner un minuteur
└── ModuleD/      le même métronome, avec un rappel qui ne capture rien
```

```mermaid
flowchart LR
  subgraph default["Contexte par défaut : celui de l'hôte"]
    Host
    Contracts["Contracts : IModule, ITool, IChordSpeller"]
    DI["Injection de dépendances"]
  end
  subgraph ca["Contexte ModuleA"]
    ModuleA --> NA["Newtonsoft.Json 13.0.3"]
  end
  subgraph cb["Contexte ModuleB"]
    ModuleB --> NB["Newtonsoft.Json 13.0.1"]
  end
  ModuleA -- "implémente IChordSpeller" --> Contracts
  ModuleB -- "demande IChordSpeller" --> Contracts
```

## Les deux côtés d'une frontière de module

Le fichier projet d'un module décide de ce qui va dans son dossier :

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <!-- Copie les dépendances propres au module à côté de lui et écrit le .deps.json que lit AssemblyDependencyResolver -->
    <EnableDynamicLoading>true</EnableDynamicLoading>
  </PropertyGroup>
  <ItemGroup>
    <!-- Les contrats viennent de l'hôte à l'exécution, jamais du dossier du module -->
    <ProjectReference Include="../Contracts/Contracts.csproj" Private="false" ExcludeAssets="runtime" />
    <PackageReference Include="Newtonsoft.Json" Version="13.0.3" />
  </ItemGroup>
</Project>
```

Après une compilation, `ModuleA/bin/Release/net10.0` contient `ModuleA.dll`, `ModuleA.deps.json`, `ModuleA.runtimeconfig.json`, `ModuleA.pdb` et `Newtonsoft.Json.dll`, et pas de `Contracts.dll`. Ces trois réglages viennent du [tutoriel de Microsoft sur les plugins](https://learn.microsoft.com/dotnet/core/tutorials/creating-app-with-plugin-support).

L'hôte donne à chaque module un contexte à lui :

```csharp
sealed class PluginLoadContext(string mainAssembly)
    : AssemblyLoadContext(Path.GetFileNameWithoutExtension(mainAssembly), isCollectible: true)
{
    // Chargés une seule fois, par l'hôte : un module qui apporterait sa propre copie aurait son propre type ITool,
    // que le conteneur de l'hôte ne reconnaîtrait pas
    static readonly HashSet<string> Shared = ["Contracts", "Microsoft.Extensions.DependencyInjection.Abstractions"];

    readonly AssemblyDependencyResolver resolver = new(mainAssembly);

    // null envoie la demande au contexte par défaut, celui de l'hôte
    protected override Assembly? Load(AssemblyName name) =>
        Shared.Contains(name.Name!) ? null
        : resolver.ResolveAssemblyToPath(name) is { } path ? LoadFromAssemblyPath(path)
        : null;
}
```

Le runtime appelle `Load` pour chaque assembly que le module référence et que son contexte n'a pas encore chargé. [`AssemblyDependencyResolver`](https://learn.microsoft.com/dotnet/api/system.runtime.loader.assemblydependencyresolver) lit le `.deps.json` du module et répond par un chemin dans le dossier du module. Renvoyer `null` transmet la demande au contexte par défaut : c'est ainsi que les contrats et les abstractions de l'injection de dépendances se chargent une seule fois, pour tout le monde.

Puis un seul conteneur pour tous les modules :

```csharp
// Hors ligne, pour qu'aucune variable locale de l'appelant ne retienne le type ou le contexte d'un module après le retour
[MethodImpl(MethodImplOptions.NoInlining)]
static List<WeakReference> Run(string[] paths, bool dispose)
{
    var services = new ServiceCollection();
    var contexts = new List<PluginLoadContext>();
    foreach (var path in paths)
    {
        var context = new PluginLoadContext(path);
        contexts.Add(context);
        foreach (var type in context.LoadFromAssemblyPath(path).GetTypes().Where(t => typeof(IModule).IsAssignableFrom(t) && !t.IsAbstract))
        {
            ((IModule)Activator.CreateInstance(type)!).Register(services);
            Console.WriteLine($"   loaded {type.FullName} in context {context.Name}");
        }
    }

    try
    {
        // ValidateOnBuild : un service qu'aucun module ne fournit échoue ici, au chargement des modules, pas au premier usage
        var provider = services.BuildServiceProvider(new ServiceProviderOptions { ValidateOnBuild = true });
        foreach (var tool in provider.GetServices<ITool>())
            Console.WriteLine($"   {tool.Name}: {tool.Run("""{"chord":"Cmaj7"}""")}");
        if (dispose)
            provider.Dispose();
    }
    catch (AggregateException e)
    {
        Console.WriteLine($"   {e.InnerExceptions.Single().InnerException!.Message}");
    }

    var weak = contexts.Select(c => new WeakReference(c)).ToList();
    contexts.ForEach(c => c.Unload());
    return weak;
}
```

La méthode `NoInlining` et les références faibles suivent l'article [How to use and debug assembly unloadability in .NET](https://learn.microsoft.com/dotnet/standard/assembly/unloadability) : un contexte, ou un type qui en vient, resté dans une variable locale de l'appelant garderait le contexte chargé.

## 1. Deux versions d'une même bibliothèque

```text
1. Modules A and B: two versions of one library, and a service that B takes from A
   loaded ModuleA.Module in context ModuleA
   loaded ModuleB.Module in context ModuleB
   A: Cmaj7 = C E G B (Newtonsoft.Json 13.0.3, assembly version 13.0.0.0)
   B: Cmaj7 descending = B G E C (Newtonsoft.Json 13.0.1, assembly version 13.0.0.0)
   unloaded 2 of 2 module contexts; still loaded: []
```

Chaque module exécute le Newtonsoft.Json avec lequel il a été compilé. Il leur faut pour cela deux contextes : selon [About `AssemblyLoadContext`](https://learn.microsoft.com/dotnet/core/dependency-loading/understanding-assemblyloadcontext), « a single AssemblyLoadContext instance is limited to loading exactly one version of an Assembly per simple assembly name », et une référence est résolue vers un assembly déjà chargé quand « the loaded version is equal or higher to the requested version ». Les deux paquets portent la version d'assembly 13.0.0.0, comme le montre la sortie. Dans un seul contexte, la demande du module B serait donc satisfaite par la 13.0.3 déjà chargée : pas d'erreur, simplement pas le code avec lequel B a été compilé et testé. Cette dernière phrase découle de la règle documentée ; cette annexe ne l'exécute pas.

## 2. Un module qui utilise le service d'un autre

```csharp
// Prend l'épeleur d'accords qu'inscrit le module A : le module B ne référence jamais le module A, seulement le contrat
sealed class Descend(IChordSpeller speller) : ITool
```

Le scénario 1 montre `Descend` qui reçoit l'épeleur du module A : `B G E C`, c'est l'épellation de A, à l'envers. Cela fonctionne parce que `IChordSpeller` est un seul type pour tout le monde (le scénario 3 montre pourquoi c'est important) et que chaque module s'inscrit dans le même conteneur. Sans le module A :

```text
2. Module B without module A
   loaded ModuleB.Module in context ModuleB
   Unable to resolve service for type 'Contracts.IChordSpeller' while attempting to activate 'ModuleB.Descend'.
   unloaded 1 of 1 module contexts; still loaded: []
```

Avec [`ValidateOnBuild`](https://learn.microsoft.com/dotnet/api/microsoft.extensions.dependencyinjection.serviceprovideroptions.validateonbuild), la dépendance manquante arrête `BuildServiceProvider`, au chargement des modules, plutôt que la première demande d'un outil. L'`AggregateException` levée contient une exception par service impossible à construire ; ce message est celui de l'exception interne. La construction ratée ne retient rien, et le contexte se décharge quand même.

## 3. Un assembly, deux types

```csharp
[MethodImpl(MethodImplOptions.NoInlining)]
static void TwoCopies(string path)
{
    PluginLoadContext first = new(path), second = new(path);
    var a = first.LoadFromAssemblyPath(path).GetType("ModuleA.Module")!;
    var b = second.LoadFromAssemblyPath(path).GetType("ModuleA.Module")!;
    Console.WriteLine($"   ModuleA.Module: same name {a.FullName == b.FullName}, same type {a == b}");
    Console.WriteLine($"   the IModule both implement: same type {a.GetInterface("IModule") == b.GetInterface("IModule")}, the host's {a.GetInterface("IModule") == typeof(IModule)}");
    first.Unload();
    second.Unload();
}
```

```text
3. Module A loaded in two contexts
   ModuleA.Module: same name True, same type False
   the IModule both implement: same type True, the host's True
```

Un type, c'est son nom *et* le contexte qui l'a chargé. Le même fichier, chargé deux fois, donne deux types `ModuleA.Module` ; l'`IModule` qu'ils implémentent est un seul type, celui de l'hôte, parce que les deux contextes ont transmis `Contracts` au contexte par défaut. C'est à cela que sert la liste `Shared` : un module qui chargerait son propre `Contracts.dll` implémenterait un `IModule` que le transtypage de l'hôte et son conteneur n'ont jamais vu.

## 4 à 7. Le déchargement, et ce qui retient un module

L'article sur le déchargement le dit « cooperative » : `Unload` ne fait que le lancer, et il se termine quand plus aucun thread n'exécute le code du contexte et que plus rien hors du contexte ne référence ses assemblies, ses types ou leurs instances. L'outil du module C démarre un [`Timer`](https://learn.microsoft.com/dotnet/api/system.threading.timer) et l'arrête quand le conteneur le libère :

```csharp
// Démarre un minuteur quand le conteneur le crée, et ne l'arrête que quand le conteneur le libère
sealed class Metronome : ITool, IDisposable
{
    readonly Timer timer;
    int ticks;

    public Metronome() => timer = new Timer(_ => Interlocked.Increment(ref ticks), null, 0, 10);

    public string Name => "C";

    public string Run(string json) => "metronome started";

    public void Dispose() => timer.Dispose();
}
```

Le `Pulse` du module D est la même classe, à une différence près : le compteur est statique et le rappel est `static _ => Interlocked.Increment(ref ticks)`, il ne capture donc rien.

```text
4. Module C, whose tool runs a timer, with the container disposed
   loaded ModuleC.Module in context ModuleC
   C: metronome started
   unloaded 1 of 1 module contexts; still loaded: []
5. Modules A and B, with the container dropped without being disposed
   loaded ModuleA.Module in context ModuleA
   loaded ModuleB.Module in context ModuleB
   A: Cmaj7 = C E G B (Newtonsoft.Json 13.0.3, assembly version 13.0.0.0)
   B: Cmaj7 descending = B G E C (Newtonsoft.Json 13.0.1, assembly version 13.0.0.0)
   unloaded 2 of 2 module contexts; still loaded: []
6. Module D, whose timer callback captures nothing, with the container dropped without being disposed
   loaded ModuleD.Module in context ModuleD
   D: pulse started
   unloaded 1 of 1 module contexts; still loaded: []
7. Module C, with the container dropped without being disposed
   loaded ModuleC.Module in context ModuleC
   C: metronome started
   unloaded 0 of 1 module contexts; still loaded: [ModuleC]
```

| # | Conteneur | Rappel du minuteur | Résultat | Collectes |
|---|---|---|---|---|
| 4 | libéré | capture le métronome | déchargé | 2 |
| 5 | abandonné | pas de minuteur : le témoin | déchargé | 2 |
| 6 | abandonné | ne capture rien | déchargé | 3 |
| 7 | abandonné | capture le métronome | toujours chargé | 100, puis l'hôte abandonne |

La documentation de `Timer` explique la différence entre 6 et 7 : « As long as you are using a Timer, you must keep a reference to it », et « the fact that a Timer is still active does not prevent it from being collected. » Une fois le conteneur abandonné, le `Pulse` du module D et son minuteur sont inaccessibles ; le minuteur est collecté et s'arrête, et le contexte s'en va, une collecte après les autres. Le rappel du module C incrémente un champ du `Metronome` : il retient donc le `Metronome`, qui retient le minuteur, pendant que le runtime retient le rappel tant que le minuteur tourne. Le minuteur se garde lui-même en vie à travers son propre rappel, et avec lui le type, l'assembly et le contexte. Le scénario 5 écarte l'autre lecture : un conteneur abandonné sans `Dispose` n'est pas, à lui seul, ce qui garde un module chargé.

La liste de l'article sur ce qui retient un contexte nomme les threads et les rappels de `RegisteredWaitHandle`, pas `Timer` ; ce cas relève de son premier point, une référence venue de l'extérieur du contexte. Deux sorties possibles : libérer le conteneur avant de décharger, puisqu'il libère les singletons qu'il a créés (scénario 4, et [leçon 13](../13-dependency-injection-options/)), ou laisser le module arrêter son propre travail dans l'événement [`Unloading`](https://learn.microsoft.com/dotnet/api/system.runtime.loader.assemblyloadcontext.unloading) du contexte.

La dernière colonne a fait changer l'hôte. La boucle d'attente de l'article s'arrête après dix collectes enchaînées. Le module D s'est déchargé en moins de dix dans 36 exécutions sur 40 ; dans les quatre autres, son contexte était encore vivant quand la boucle a abandonné. Avec 10 ms entre deux collectes, trois ont suffi dans 40 exécutions sur 40 : ce que D attend, c'est du temps, pas des collectes. L'hôte collecte maintenant jusqu'à cent fois, à 10 ms d'intervalle, et imprime le compte sur une ligne qui commence par `# `, que `check.sh` affiche sans la comparer.

## La même chose en Java

- [`ServiceLoader`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/ServiceLoader.html), « a facility to load implementations of a service », trouve les fournisseurs : il joue le rôle du catalogue, et de la méthode `Register` du module.
- Un [`URLClassLoader`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/net/URLClassLoader.html) par plugin joue le rôle du contexte. Le [`ClassLoader`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/ClassLoader.html) de Java interroge d'abord son parent : un plugin qui a besoin de sa propre version d'une bibliothèque que l'hôte possède aussi demande donc un chargeur qui cherche d'abord chez lui ; ici, c'est `Load` qu'on interroge d'abord, et la liste partagée fait exception.
- L'identité suit la même règle : la [spécification de la JVM, §5.3](https://docs.oracle.com/javase/specs/jvms/se25/html/jvms-5.html#jvms-5.3), dit qu'une classe est « determined not by its name alone, but by a pair: its binary name … and its defining class loader ». La forme Java du scénario 3 est une `ClassCastException` entre deux classes de même nom.
- Le déchargement y est coopératif lui aussi : selon la [Java Language Specification, §12.7](https://docs.oracle.com/javase/specs/jls/se25/html/jls-12.html#jls-12.7), une classe « may be unloaded if and only if its defining class loader may be reclaimed by the garbage collector ».

## Ce que cette annexe ne couvre pas

- Un fichier de configuration qui liste les modules, et le remplacement d'un module pendant que l'hôte tourne : non essayés.
- Les dépendances natives, par `LoadUnmanagedDll` : non essayées.
- Des parties MEF chargées dans des contextes déchargeables : non essayé.
- La chaîne de références qui retient le module C n'a pas été vidée avec le `gcroot` de `dotnet-dump` : la page la déduit des scénarios 6 et 7. *À vérifier.*
- Les comptes ont été mesurés sur la machine Windows de l'auteur, puis retrouvés à l'identique lors de la première exécution de la CI sous Linux, macOS et Windows (2, 2, 2, 2, 3 et 100 collectes) : une exécution chacun, un exécuteur plus lent pourrait donc encore en demander davantage.
