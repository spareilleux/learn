---
title: "Apéndice 4: plugins sin MEF"
description: Cuatro módulos cargados por un mismo host, cada uno en su propio AssemblyLoadContext descargable, que registran sus servicios en un único contenedor de inyección de dependencias — dos versiones de Newtonsoft.Json lado a lado, un módulo que usa el servicio de otro sin referenciarlo, un ensamblado que da dos tipos, y un temporizador que mantiene cargado su módulo o no según lo que capture su callback. Siete escenarios, cada uno predicho antes de ejecutarse, en una salida comprobada en tres sistemas.
sidebar:
  label: "Apéndice 4: plugins sin MEF"
  order: 92
---

[MEF](https://learn.microsoft.com/dotnet/framework/mef/), el Managed Extensibility Framework, es la forma en que las aplicaciones de .NET Framework 4 encontraban sus plugins: partes marcadas con `[Export]` e `[Import]`, un catálogo que recorre una carpeta y un contenedor que conecta las partes entre sí. Sigue mantenido — su versión ligera, [`System.Composition`](https://www.nuget.org/packages/System.Composition), va por la 10.0.13 —, pero un host reciente suele construir lo mismo con dos piezas del propio .NET:

- un [`AssemblyLoadContext`](https://learn.microsoft.com/dotnet/api/system.runtime.loader.assemblyloadcontext) por módulo, que mantiene las dependencias del módulo separadas de las de los demás y puede descargarse;
- el [contenedor de inyección de dependencias](../13-dependency-injection-options/) que el host ya tiene, en el que cada módulo registra lo que ofrece y del que recibe lo que necesita.

El aislamiento y la descarga vienen de la primera pieza, no de dejar MEF: nada impide que un host MEF cargue también sus partes en contextos descargables (no se prueba aquí). Lo que sustituye el contenedor son los atributos y los catálogos de MEF.

| Tarea | MEF | Aquí |
|---|---|---|
| Encontrar las partes | un `DirectoryCatalog` recorre una carpeta | el host recibe el ensamblado principal de cada módulo y crea su `IModule` |
| Decir lo que ofrece una parte | `[Export(typeof(ITool))]` | `services.AddSingleton<ITool, Spell>()` en `IModule.Register` |
| Decir lo que necesita una parte | `[Import]`, `[ImportingConstructor]` | los parámetros del constructor |
| Conectar las partes | `CompositionContainer` | `ServiceProvider` |
| Separar las dependencias de cada parte | fuera de MEF | un `AssemblyLoadContext` por módulo |
| Descargar una parte | fuera de MEF; en .NET Framework, un `AppDomain` entero | un contexto descargable, en cuanto nada lo retiene |

Este apéndice construye un host así con cuatro módulos pequeños y ejecuta siete escenarios. Cada hipótesis se escribió antes de la primera ejecución, y el [diario](../journal/) las guarda. Todas las predicciones se cumplieron; una medida, el número de recolecciones que pide una descarga, hizo cambiar el host.

## Ejecutarlo

```bash
bash code/csharp-advanced/check.sh       # todas las lecciones y apéndices, comparados con expected/
cd code/csharp-advanced
dotnet build Plugins/Plugins.slnx -c Release
dotnet Plugins/Host/bin/Release/net10.0/Host.dll \
  Plugins/ModuleA/bin/Release/net10.0/ModuleA.dll Plugins/ModuleB/bin/Release/net10.0/ModuleB.dll \
  Plugins/ModuleC/bin/Release/net10.0/ModuleC.dll Plugins/ModuleD/bin/Release/net10.0/ModuleD.dll
```

El host no referencia ningún módulo: recibe sus ensamblados principales en la línea de comandos, como se los daría un archivo de configuración. El código está en [`code/csharp-advanced/Plugins`](https://github.com/spareilleux/learn/tree/main/code/csharp-advanced/Plugins):

```text
Plugins/
├── Plugins.slnx  compila el host y los módulos
├── Contracts/    IModule, ITool, IChordSpeller: los únicos tipos que pasan de un contexto a otro
├── Host/         Program.cs: un contexto por módulo, un contenedor, los siete escenarios
├── ModuleA/      un deletreador de acordes, y una herramienta que lo usa, con Newtonsoft.Json 13.0.3
├── ModuleB/      una herramienta que toma el deletreador del módulo A, con Newtonsoft.Json 13.0.1
├── ModuleC/      un metrónomo cuya herramienta hace correr un temporizador
└── ModuleD/      el mismo metrónomo, con un callback que no captura nada
```

```mermaid
flowchart LR
  subgraph default["Contexto por defecto: el del host"]
    Host
    Contracts["Contracts: IModule, ITool, IChordSpeller"]
    DI["Inyección de dependencias"]
  end
  subgraph ca["Contexto ModuleA"]
    ModuleA --> NA["Newtonsoft.Json 13.0.3"]
  end
  subgraph cb["Contexto ModuleB"]
    ModuleB --> NB["Newtonsoft.Json 13.0.1"]
  end
  ModuleA -- "implementa IChordSpeller" --> Contracts
  ModuleB -- "pide IChordSpeller" --> Contracts
```

## Los dos lados de una frontera de módulo

El archivo de proyecto de un módulo decide qué va a su carpeta:

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <!-- Copia las dependencias propias del módulo junto a él y escribe el .deps.json que lee AssemblyDependencyResolver -->
    <EnableDynamicLoading>true</EnableDynamicLoading>
  </PropertyGroup>
  <ItemGroup>
    <!-- Los contratos vienen del host en tiempo de ejecución, nunca de la carpeta del módulo -->
    <ProjectReference Include="../Contracts/Contracts.csproj" Private="false" ExcludeAssets="runtime" />
    <PackageReference Include="Newtonsoft.Json" Version="13.0.3" />
  </ItemGroup>
</Project>
```

Después de compilar, `ModuleA/bin/Release/net10.0` contiene `ModuleA.dll`, `ModuleA.deps.json`, `ModuleA.runtimeconfig.json`, `ModuleA.pdb` y `Newtonsoft.Json.dll`, y ningún `Contracts.dll`. Estos tres ajustes vienen del [tutorial de Microsoft sobre plugins](https://learn.microsoft.com/dotnet/core/tutorials/creating-app-with-plugin-support).

El host da a cada módulo un contexto propio:

```csharp
sealed class PluginLoadContext(string mainAssembly)
    : AssemblyLoadContext(Path.GetFileNameWithoutExtension(mainAssembly), isCollectible: true)
{
    // Cargados una sola vez, por el host: un módulo que trajera su propia copia tendría su propio tipo ITool,
    // que el contenedor del host no reconocería
    static readonly HashSet<string> Shared = ["Contracts", "Microsoft.Extensions.DependencyInjection.Abstractions"];

    readonly AssemblyDependencyResolver resolver = new(mainAssembly);

    // null envía la petición al contexto por defecto, el del host
    protected override Assembly? Load(AssemblyName name) =>
        Shared.Contains(name.Name!) ? null
        : resolver.ResolveAssemblyToPath(name) is { } path ? LoadFromAssemblyPath(path)
        : null;
}
```

El runtime llama a `Load` para cada ensamblado que el módulo referencia y que su contexto aún no ha cargado. [`AssemblyDependencyResolver`](https://learn.microsoft.com/dotnet/api/system.runtime.loader.assemblydependencyresolver) lee el `.deps.json` del módulo y responde con una ruta en la carpeta del módulo. Devolver `null` pasa la petición al contexto por defecto: así los contratos y las abstracciones de la inyección de dependencias se cargan una sola vez, para todos.

Después, un único contenedor para todos los módulos:

```csharp
// Fuera de línea, para que ninguna variable local del llamador retenga el tipo o el contexto de un módulo al volver
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
        // ValidateOnBuild: un servicio que ningún módulo ofrece falla aquí, al cargar los módulos, no en el primer uso
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

El método `NoInlining` y las referencias débiles siguen el artículo [How to use and debug assembly unloadability in .NET](https://learn.microsoft.com/dotnet/standard/assembly/unloadability): un contexto, o un tipo que venga de él, que quedara en una variable local del llamador mantendría el contexto cargado.

## 1. Dos versiones de una misma biblioteca

```text
1. Modules A and B: two versions of one library, and a service that B takes from A
   loaded ModuleA.Module in context ModuleA
   loaded ModuleB.Module in context ModuleB
   A: Cmaj7 = C E G B (Newtonsoft.Json 13.0.3, assembly version 13.0.0.0)
   B: Cmaj7 descending = B G E C (Newtonsoft.Json 13.0.1, assembly version 13.0.0.0)
   unloaded 2 of 2 module contexts; still loaded: []
```

Cada módulo ejecuta el Newtonsoft.Json con el que se compiló. Para ello necesitan dos contextos: según [About `AssemblyLoadContext`](https://learn.microsoft.com/dotnet/core/dependency-loading/understanding-assemblyloadcontext), «a single AssemblyLoadContext instance is limited to loading exactly one version of an Assembly per simple assembly name», y una referencia se resuelve contra un ensamblado ya cargado cuando «the loaded version is equal or higher to the requested version». Los dos paquetes llevan la versión de ensamblado 13.0.0.0, como muestra la salida. En un solo contexto, la petición del módulo B quedaría satisfecha por la 13.0.3 ya cargada: ningún error, simplemente no el código con el que B se compiló y probó. Esa última frase se deduce de la regla documentada; este apéndice no la ejecuta.

## 2. Un módulo que usa el servicio de otro

```csharp
// Toma el deletreador de acordes que registra el módulo A: el módulo B nunca referencia al módulo A, solo el contrato
sealed class Descend(IChordSpeller speller) : ITool
```

El escenario 1 muestra a `Descend` recibiendo el deletreador del módulo A: `B G E C` es el deletreo de A, al revés. Funciona porque `IChordSpeller` es un único tipo para todos (el escenario 3 muestra por qué importa) y cada módulo se registra en el mismo contenedor. Sin el módulo A:

```text
2. Module B without module A
   loaded ModuleB.Module in context ModuleB
   Unable to resolve service for type 'Contracts.IChordSpeller' while attempting to activate 'ModuleB.Descend'.
   unloaded 1 of 1 module contexts; still loaded: []
```

Con [`ValidateOnBuild`](https://learn.microsoft.com/dotnet/api/microsoft.extensions.dependencyinjection.serviceprovideroptions.validateonbuild), la dependencia que falta detiene `BuildServiceProvider`, al cargar los módulos, en lugar de la primera petición de una herramienta. La `AggregateException` que lanza contiene una excepción por cada servicio que no se puede construir; este mensaje es el de la excepción interna. La construcción fallida no retiene nada, y el contexto se descarga igualmente.

## 3. Un ensamblado, dos tipos

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

Un tipo es su nombre *y* el contexto que lo cargó. El mismo archivo, cargado dos veces, da dos tipos `ModuleA.Module`; el `IModule` que implementan es un único tipo, el del host, porque los dos contextos pasaron `Contracts` al contexto por defecto. Para eso sirve la lista `Shared`: un módulo que cargara su propio `Contracts.dll` implementaría un `IModule` que la conversión del host y su contenedor nunca han visto.

## 4 a 7. La descarga, y lo que retiene un módulo

El artículo sobre la descarga la llama «cooperative»: `Unload` solo la inicia, y termina cuando ningún hilo ejecuta ya código del contexto y nada fuera del contexto referencia sus ensamblados, sus tipos ni sus instancias. La herramienta del módulo C arranca un [`Timer`](https://learn.microsoft.com/dotnet/api/system.threading.timer) y lo detiene cuando el contenedor la libera:

```csharp
// Arranca un temporizador cuando el contenedor lo crea, y solo lo detiene cuando el contenedor lo libera
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

El `Pulse` del módulo D es la misma clase con una diferencia: el contador es estático y el callback es `static _ => Interlocked.Increment(ref ticks)`, así que no captura nada.

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

| # | Contenedor | Callback del temporizador | Resultado | Recolecciones |
|---|---|---|---|---|
| 4 | liberado | captura el metrónomo | descargado | 2 |
| 5 | abandonado | sin temporizador: el control | descargado | 2 |
| 6 | abandonado | no captura nada | descargado | 3 |
| 7 | abandonado | captura el metrónomo | sigue cargado | 100, y el host se rinde |

La documentación de `Timer` explica la diferencia entre 6 y 7: «As long as you are using a Timer, you must keep a reference to it», y «the fact that a Timer is still active does not prevent it from being collected.» Una vez abandonado el contenedor, el `Pulse` del módulo D y su temporizador son inalcanzables; el temporizador se recolecta y se detiene, y el contexto se va, una recolección después que los demás. El callback del módulo C incrementa un campo del `Metronome`: retiene, pues, el `Metronome`, que retiene el temporizador, mientras el runtime retiene el callback mientras el temporizador corre. El temporizador se mantiene vivo a sí mismo a través de su propio callback, y con él el tipo, el ensamblado y el contexto. El escenario 5 descarta la otra lectura: un contenedor abandonado sin `Dispose` no es, por sí solo, lo que mantiene cargado un módulo.

La lista del artículo sobre lo que retiene un contexto nombra los hilos y los callbacks de `RegisteredWaitHandle`, no `Timer`; este caso cae en su primer punto, una referencia desde fuera del contexto. Dos salidas: liberar el contenedor antes de descargar, ya que libera los singletons que creó (escenario 4, y la [lección 13](../13-dependency-injection-options/)), o dejar que el módulo detenga su propio trabajo en el evento [`Unloading`](https://learn.microsoft.com/dotnet/api/system.runtime.loader.assemblyloadcontext.unloading) del contexto.

La última columna hizo cambiar el host. El bucle de espera del artículo se detiene tras diez recolecciones seguidas. El módulo D se descargó en menos de diez en 36 ejecuciones de 40; en las otras cuatro, su contexto seguía vivo cuando el bucle se rindió. Con 10 ms entre recolecciones, tres bastaron en 40 ejecuciones de 40: lo que D espera es tiempo, no recolecciones. El host recolecta ahora hasta cien veces, con 10 ms de intervalo, e imprime el recuento en una línea que empieza por `# `, que `check.sh` muestra sin compararla.

## Lo mismo en Java

- [`ServiceLoader`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/ServiceLoader.html), «a facility to load implementations of a service», encuentra los proveedores: hace el papel del catálogo, y del método `Register` del módulo.
- Un [`URLClassLoader`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/net/URLClassLoader.html) por plugin hace el papel del contexto. El [`ClassLoader`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/ClassLoader.html) de Java pregunta primero a su padre, así que un plugin que necesita su propia versión de una biblioteca que el host también tiene necesita un cargador que busque primero en sí mismo; aquí se pregunta primero a `Load`, y la lista compartida es la excepción.
- La identidad sigue la misma regla: la [especificación de la JVM, §5.3](https://docs.oracle.com/javase/specs/jvms/se25/html/jvms-5.html#jvms-5.3), dice que una clase está «determined not by its name alone, but by a pair: its binary name … and its defining class loader». La forma Java del escenario 3 es una `ClassCastException` entre dos clases con el mismo nombre.
- La descarga también es cooperativa: según la [Java Language Specification, §12.7](https://docs.oracle.com/javase/specs/jls/se25/html/jls-12.html#jls-12.7), una clase «may be unloaded if and only if its defining class loader may be reclaimed by the garbage collector».

## Lo que este apéndice no cubre

- Un archivo de configuración que liste los módulos, y sustituir un módulo mientras el host corre: no probados.
- Las dependencias nativas, mediante `LoadUnmanagedDll`: no probadas.
- Partes MEF cargadas en contextos descargables: no probado.
- La cadena de referencias que retiene el módulo C no se volcó con el `gcroot` de `dotnet-dump`: la página la deduce de los escenarios 6 y 7. *Por verificar.*
- Los recuentos se midieron en la máquina Windows del autor y se encontraron idénticos en la primera ejecución de la CI en Linux, macOS y Windows (2, 2, 2, 2, 3 y 100 recolecciones): una ejecución en cada uno, así que un runner más lento aún podría necesitar más.
