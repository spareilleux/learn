---
title: Journal
description: Notes de progression datées du cours V — l'installation de V 0.5.2, la CI sur trois OS, les surprises du compilateur et de la documentation, et les points à vérifier.
sidebar:
  order: 99
---

## Progression

- [x] V 0.5.2 installé sous Windows, et en CI sous Linux, Windows et macOS
- [x] CI : exemples, snippets rejetés et panics comparés à leur sortie attendue sur trois OS
- [x] Leçon 1 : installation, `v run`, modules et projets
- [x] Leçon 2 : types, variables immuables, structs et méthodes
- [x] Leçon 3 : erreurs, `?`, `!` et `or { }`
- [x] Leçon 4 : tableaux, maps, slices et mémoire
- [x] Leçon 5 : interfaces et génériques
- [x] Leçon 6 : enums, types somme et `match`
- [x] Leçon 7 : concurrence, `spawn`, canaux et `shared`
- [x] Leçon 8 : tests, `v fmt`, `v vet` et `v doc`
- [ ] Leçon 9 : appeler du C

## 2026-09-14 — Installation de V 0.5.2

- [0.5.2](https://github.com/vlang/v/releases/tag/0.5.2) est la dernière release, publiée le 2026-07-12 ; son tag pointe vers le commit [`7647ce1`](https://github.com/vlang/v/commit/7647ce1c6fad63b5578bc07883139906de74b2f8). La dernière release hebdomadaire est `weekly.2026.08`, de février.
- Windows : `v_windows.zip` fait 23 745 972 octets. Je l'ai décompressé dans `C:\Users\spare\tools\v-0.5.2`, hors du `PATH`. `v version` affiche `V 0.5.2 7647ce1` ; `v doctor` affiche `V 0.5.2 45ae01d23168b6372f734eeb38a77360bbcf184a.7647ce1`. J'ai aussi essayé les commandes de la leçon 1 dans un dossier de test : `Invoke-WebRequest` a téléchargé l'archive en 3 s, `Expand-Archive` a mis 53 s à la décompresser.
- Les trois archives (`v_windows.zip`, `v_linux.zip`, `v_macos_arm64.zip`) contiennent toutes TCC sous le nom `thirdparty/tcc/tcc.exe`, avec le `.exe` sous Linux et macOS aussi, et conservent les bits d'exécution de `v` et de `tcc.exe`.
- Le premier `v run hello.v` a compilé et s'est exécuté en 1,6 s, avec TCC et aucun autre compilateur C installé.
- [docs.vlang.io](https://docs.vlang.io/introduction.html) suit `master`, pas la release. Sa page [The default compiler](https://docs.vlang.io/the-default-compiler.html) n'est pas dans [le `docs.md` de 0.5.2](https://github.com/vlang/v/blob/0.5.2/doc/docs.md), et elle n'est même pas d'accord avec `master` : la page web (générée depuis le commit `5db92f0`) dit que l'exécutable `v` "contains only the experimental V3 C compiler", alors que [`doc/docs.md` sur `master`](https://github.com/vlang/v/blob/master/doc/docs.md) dit désormais qu'il "contains the default compiler whose source lives in `vlib/v`". Les leçons vérifient chaque comportement avec 0.5.2 elle-même.

## 2026-09-14 — La CI

- [`v-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/v-examples.yml) télécharge l'archive de release de chaque OS, ajoute son dossier à `GITHUB_PATH`, et exécute [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/v-for-csharp-java/check.sh). Le premier push est passé sur les trois OS : les sorties et les messages du compilateur capturés sous Windows sont identiques sous Linux et macOS.
- `check.sh` compare la sortie standard *et* la sortie d'erreur de chaque exemple, donc un nouvel avertissement ou une nouvelle notice fait échouer le job. Les snippets rejetés sont compilés depuis leur dossier, pour que les messages affichent `e02_immutable.v:3:2` plutôt qu'un chemin qui différerait d'un OS à l'autre.
- Un panic affiche son message, puis `v hash`, les identifiants du processus et du thread, et une backtrace dont les lignes dépendent de l'OS et du compilateur C. `check.sh` compare la première ligne et le code de sortie, 1 sur les trois OS.
- `v fmt -verify` échoue sur les snippets rejetés, parce qu'il en vérifie les types : `check.sh` formate tous les dossiers sauf `compile_fail`.
- Compilateurs C, d'après `v -showcc` dans la CI : TCC pour les builds de développement sous Windows et Linux ; `cc` (Apple clang 21) pour les builds de développement sous macOS, bien que `v doctor` y liste aussi TCC ; `gcc` (MinGW 15.2) pour `-prod` sur le runner Windows, `cc` (gcc 13.3) sous Linux, `cc` sous macOS.
- Sur ma machine, `v doctor` indique `msvc version N/A`, et pourtant `v -showcc -prod` compile avec le `cl.exe` des Visual Studio 2022 Build Tools.

## 2026-09-14 — Surprises en écrivant les leçons 1-4

**`v new` sans entrée écrit `<EOF>` dans `v.mod`.** Avec l'entrée standard fermée (`v new hello < /dev/null`), `v new` ne s'arrête pas et écrit `description: '<EOF>'`, `version: '<EOF>'` et `license: '<EOF>'`. [`os.input`](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/os/os.v#L436-L441) renvoie `'<EOF>'` à la fin de l'entrée, et [`vcreate.v`](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/cmd/tools/vcreate/vcreate.v#L170-L181) ne remplace par la valeur par défaut qu'une chaîne vide. La CI envoie trois réponses par un pipe.

**`-autofree` désactive le ramasse-miettes.** La documentation dit qu'*autofree* libère la plupart des objets et que "the remaining small percentage of objects is freed via GC". En 0.5.2, [`pref.v`, lignes 807-811](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/pref/pref.v#L807-L811) fixe `gc_mode = .no_gc` pour `-autofree`, et `gc_is_enabled()` renvoie `false` dans l'exemple de la leçon 4. Ce qu'*autofree* manque fuit.

**`-prod` avec MSVC désactive le ramasse-miettes.** [`default.v`, lignes 369-381](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/pref/default.v#L369-L381) passe à `no_gc` quand le compilateur C est MSVC sous Windows et qu'aucune option `-gc` n'est donnée. Sur ma machine, `v -prod run examples/l04_memory.v` affiche `GC enabled: false` et atteint 542 Mo après 50 tours, contre 20 Mo pour `v run` ; `v -prod -gc boehm run` reste à 30 Mo. Le runner Windows utilise `gcc` pour `-prod`, et ne le montre pas. Je n'ai pas trouvé cette règle dans la documentation.

**Un tableau entier est partagé, une slice est clonée.** `alias := original` partage la mémoire d'un tableau `mut` sans notice, jusqu'à ce que `original` dépasse sa capacité ; `first := lines[..2]` sur le même tableau est cloné, avec une notice. Le checker ne s'intéresse qu'aux slices ([`assign.v`, lignes 845-855](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/checker/assign.v#L845-L855)). La leçon 4 montre les deux.

**Deux fonctions du même nom : l'erreur dépend de l'appel.** Avec `fn describe(lines int)` et `fn describe(title string)`, appeler `describe('Mission')` donne `builder error: redefinition of function describe`, l'erreur de la leçon 2. Appeler plutôt `describe(474)` donne seulement `cannot use int literal as string in argument 1 to describe` : le checker signale l'erreur de type, et le build s'arrête avant que le doublon ne soit signalé.

**Le type de `7.0 / 2` est `float literal`.** La documentation dit qu'un littéral flottant devient un `f64` quand son type doit être fixé. Pourtant :

```v
y := 7.0 / 2
println(typeof(y).name) // float literal
z := 3.5
println(typeof(z).name) // f64
```

L'expression garde le type du littéral, que nomme [`types.v`, ligne 1278](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/ast/types.v#L1278). `println(y)` affiche quand même `3.5`.

**Une erreur ayant subi un *smart cast* s'interpole comme une struct.** Après `if err is ParseError`, `${err}` affiche toute la struct au lieu de `msg()` :

```text
line_no 7
interpolated: &ParseError{
    Error: Error{}
    line_no: 7
}
```

Sans le cast, `${err}` sur un `IError` affiche le message, et `error_with_code('negative', 99)` affiche `negative; code: 99`. La leçon 3 appelle `err.msg()` explicitement.

**Un type d'erreur privé peut être testé depuis un autre module.** `csv.EndOfFileError` n'a pas de `pub` ([`reader.v`, lignes 25-31](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/encoding/csv/reader.v#L25-L31)), et pourtant `err is csv.EndOfFileError` compile dans `module main`.

**Une option peut être stockée sans être déballée.** `z := find_course('java')` compile, et `println(z)` affiche `Option(none)`. Le compilateur ne se plaint que lorsque `z` est utilisée comme une `string`, comme dans le `name.to_upper()` de la leçon 3.

**`main` ne peut pas renvoyer d'erreur.** `return err` dans un bloc `or` de `main` donne `unexpected argument, current function does not return anything` ; l'exemple de la leçon 3 utilise `panic(err)`.

**La conversion de chaîne en nombre n'échoue jamais.** `'12abc'.int()` vaut 12, `'abc'.int()` vaut 0, `'99999999999'.int()` vaut 2147483647. `strconv.atoi` signale les trois.

**Une expression de tri ne voit pas les variables locales.** `courses.sort(lines[a] > lines[b])` donne quatre erreurs, en commençant par `can not access external variable lines` ; la troisième et la quatrième révèlent que `a` et `b` sont des `&string`.

**Une erreur, deux messages.** Une erreur de type dans `println(…)` est suivie de `println can not print void expressions` sur la même ligne (leçons 2 et 3).

**Le parseur CSV naïf échoue sur 50 lignes.** `pages.csv` met entre guillemets les titres qui contiennent des virgules : `line.split(',')` donne 6 champs sur 50 des 319 lignes. Un script `awk` sur le même fichier confirme les nombres de la leçon 4 : 117 pages en anglais, 101 en français et 101 en espagnol, et les lignes anglaises par cours.

## 2026-09-14 — Leçons 5-8 : le plan et les données

- La leçon 8 était « tests, `v fmt`, `v vet`, docs et packages ». Les tests, les trois outils et leurs bizarreries en CI ont rempli une leçon ; les packages (`v install`, `vpm`) passent à la leçon 12, à côté de la compilation croisée et du déploiement.
- Les leçons 5 à 8 utilisent les projets .NET de [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga) au commit [`a26a7893`](https://github.com/GuitarAlchemist/ga/commit/a26a7893), copiés du cours LadybugDB dans [`data/ga`](https://github.com/spareilleux/learn/tree/main/code/v-for-csharp-java/data/ga). Aucun champ ne contient de virgule, donc `split(',')` suffit.
- [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/v-for-csharp-java/check.sh) affiche désormais sans les comparer les lignes d'un exemple qui commencent par `# `, comme le fait le cours LadybugDB pour sa leçon 8 : des durées, des nombres de CPU, le résultat d'une *data race*. Les runners de CI signalent 4 CPU logiques sous Linux et Windows, 3 sous macOS.
- Le premier push du code de la leçon 8 a échoué sur les trois OS, pour la même raison : `v test` masque les lignes `OK` en CI (voir plus bas).

## 2026-09-14 — Ce que montrent les données de ga

Ce sont des observations sur ga à `a26a7893`, à l'appréciation de ses mainteneurs ; rien n'a été signalé en amont.

- **Deux versions flottantes.** `Apps/demerzel-bridge/DemerzelBridge/DemerzelBridge.csproj` référence `ModelContextProtocol` en version `0.*`, et `Experiments/React/ReactApp1.Server/ReactApp1.Server.csproj` référence `Microsoft.AspNetCore.SpaProxy` en version `8.*-*`, préversions comprises. Sans fichier de verrouillage NuGet, deux restaurations du même commit peuvent choisir des packages différents (leçon 6).
- **Une version en quatre parties.** `GaCLI/GaCLI.csproj` référence `Microsoft.KernelMemory.Core` `0.91.241101.1` : valide pour NuGet, mais la seule des 478 versions qui ne soit pas `major.minor.patch` avec une étiquette optionnelle.
- **Deux paires de noms similaires.** Deux projets s'appellent `GaApi.Tests` (`Tests/Apps/GaApi.Tests` et `Tests/GaApi.Tests`, le cours LadybugDB les a trouvés aussi), et deux ne diffèrent que par la casse : `GaCLI/GaCLI.csproj` (C#, absent de la solution) et `Apps/GaCli/GaCli.fsproj` (F#). Une map indexée par nom, comme dans la leçon 5, perd un `GaApi.Tests` ; avec une clé insensible à la casse, elle fusionnerait aussi les deux CLI.
- **Six projets web hors de la solution.** `FloorManager`, `GA.DocumentProcessing.Service`, `ScenesService`, `GA.Business.AI`, `FretboardExplorer` et `GA.WebBlazorApp` utilisent `Microsoft.NET.Sdk.Web` et ne sont pas listés dans `AllProjects.slnx` (leçon 6). `GA.Business.AI` est pourtant référencé par des projets de la solution.

## 2026-09-14 — Surprises en écrivant les leçons 5-8

**V envoie par défaut les erreurs du compilateur C à un serveur.** Pendant que j'écrivais la leçon 7, un programme a rencontré le bug du compilateur ci-dessous, et V a affiché `Sent C compiler bug report to https://bugs.vlang.io/bug-report.`, avec un identifiant de rapport et une commande `curl -X DELETE`. Le rapport contient le C généré fautif et les lignes de source V, avec des chemins de ma machine. [`c_error_report.v`, lignes 485-506](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/builder/c_error_report.v#L485-L506) l'envoie sauf si `V_C_ERROR_BUG_REPORT_DISABLED` est définie, et s'en abstient dans la CI GitHub. La seule mention que j'ai trouvée est dans `v help build-c`, pas dans le `docs.md` de 0.5.2. Le `check.sh` du cours définit la variable, et mes exécutions locales aussi depuis.

**Une fonction anonyme avec `return` à l'intérieur de `lock` génère du C invalide.** V 0.5.2 accepte :

```v
shared usage := Usage{}
rlock usage {
	count := fn () int {
		return 1
	}
	println(count())
}
```

puis TCC échoue avec `'usage' undeclared` : le C généré de la fonction anonyme contient `sync__RwMutex_runlock(&usage->mtx);return _t1;`, le déverrouillage du bloc englobant. Cela arrive aussi avec `lock`, et que `usage` soit capturée ou non. [`compiler_bugs/b07_return_in_lock.v`](https://github.com/spareilleux/learn/blob/main/code/v-for-csharp-java/compiler_bugs/b07_return_in_lock.v) est vérifié en CI, donc le cours remarquera quand une version le corrigera. Je n'ai pas cherché ce bug dans les issues de V, ni ne l'ai signalé.

**Une méthode d'interface `mut:` accepte un receveur immuable.** La documentation dit qu'avec `fn (s MyStruct) write(a string) string`, `MyStruct` "implements the interface Foo, but *not* interface Bar", où `Bar` déclare `write` sous `mut:`. L'exemple même de la documentation, avec `fn fn2(mut s Bar)` décommenté et appelé avec `fn2(mut s2)`, compile et affiche `Bar`. [`table.v`, lignes 280-294](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/ast/table.v#L280-L294) ne rejette que l'inverse, un receveur `mut` pour une méthode d'interface immuable. Le `Tally.total()` de la leçon 5 s'appuie dessus.

**Un champ que seul un variant possède est un `as` implicite.** Sur `type Version = Floating | Release`, `v.parts` compile bien que seul `Release` ait `parts`, et déclenche un panic `as cast: cannot cast main.Floating to main.Release` quand `v` contient un `Floating`. [`checker.v`, lignes 3180-3201](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/checker/checker.v#L3180-L3201) réécrit l'accès au champ en `AsCast`. La CI le vérifie avec `panics/p06_variant_field.v`.

**Le *smart cast* d'un type somme `mut` n'a pas besoin de `mut`.** La documentation dit que pour une variable mutable, `if mut w is Mars` est obligatoire, "otherwise `w` would keep its original type". Avec `mut v := Version(Release{[9, 5, 1]})`, `if v is Release { println(v.major()) }`, où `major` est une méthode de `Release` seulement, compile et affiche `9`. Je n'ai pas cherché le cas contre lequel la règle protège.

**L'erreur d'une fonction générique ne nomme pas l'appel.** Avec `largest[T]` appelée sur une struct sans `<`, la seule erreur est `cannot use > as <= operator method is not defined`, sur le `>` à l'intérieur de la fonction générique ([`infix.v`, lignes 831-833](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/checker/infix.v#L831-L833)) : ni le type ni la ligne de l'appel n'apparaissent, et `<`, la méthode à définir, n'est pas nommée.

**`go` est `spawn`.** La documentation présente `go` comme un thread léger géré par le runtime V. Sans `-use-coroutines`, le parseur produit un `spawn` ([`parser.v`, lignes 1391-1405](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/parser/parser.v#L1391-L1405)) ; même avec, un `go` dont le handle est utilisé se rabat sur un thread ([`spawn_and_go.v`, lignes 20-30](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/gen/c/spawn_and_go.v#L20-L30)).

**Un canal fermé ne déclenche pas de panic.** La documentation dit qu'envoyer sur un canal fermé provoque un panic à l'exécution. `ch <- x` sur un canal fermé ne fait rien : le `pushval` généré appelle `try_push_priv` et ignore le `.closed` qu'il renvoie, et `popval` renvoie une valeur zéro sur un canal fermé et vide ([`cgen.v`, lignes 2492-2501](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/vlib/v/gen/c/cgen.v#L2492-L2501)). Avec `or`, les deux opérations signalent `channel closed`. La leçon 7 montre les quatre cas.

**`fn [mut x]` modifie une copie.** Une closure lancée avec `spawn fn [mut total] (n int) { total += n }(i)` dans une boucle compile, laisse `total` à 0 dans `main`, et le seul indice est `warning: unused variable: total` sur la liste de capture.

**Une map écrite par plusieurs threads plante.** L'exercice 3 de la leçon 7, le comptage des packages avec une référence `mut` au lieu de `shared` : sur 20 exécutions, 8 résultats faux, 4 panics `array.get: index out of range`, 8 `Unhandled Exception`. Le compilateur l'accepte, comme le feraient C# et Java.

**`v test` masque les fichiers qui passent en CI.** Quand `CI` ou `GITHUB_JOB` est définie, [`common.v`, lignes 37-43](https://github.com/vlang/v/blob/7647ce1c6fad63b5578bc07883139906de74b2f8/cmd/tools/modules/testing/common.v#L37-L43) masque les lignes `OK` sauf si `VTEST_HIDE_OK=0`. La première exécution en CI de la leçon 8 a échoué sur les trois OS à cause de cela.

**Les nombres d'un rapport de test.** `Left value (len: 6): [9, 5]` donne la longueur du texte affiché, pas du tableau. Avec `-stats`, une fonction marquée `@[assert_continues]` dont les asserts ont échoué est listée comme `OK` avec `1 assert`, et le résumé `3 failed, 3 passed, 6 total` compte des asserts, pas des fonctions de test. Le code de sortie est juste : 1.

**`v doc` montre un champ privé.** `v doc -comments deps` omet les fonctions privées, mais affiche `struct Graph` avec son champ privé `mut: refs`.

**Arithmétique sur les enums, deux messages.** `sdk < Sdk.web` donne `only == and != are defined on enum, use an explicit cast to int if needed` ; `sdk + 1` donne `infix expr: cannot use int literal (right expression) as Sdk`, qui ne dit pas que `+` est refusé.

## À vérifier

- `v symlink` sous Windows, et s'il modifie le `PATH` de l'utilisateur.
- Une distribution Linux minimale sans les en-têtes C : TCC trouve-t-il ce dont il a besoin ?
- macOS : l'attribut de quarantaine sur une archive téléchargée avec un navigateur, et les builds de développement avec TCC au lieu de `cc`.
- `v -prod -cc gcc` sur une machine Windows qui a à la fois MSVC et MinGW.
- [`.vvmrc`](https://docs.vlang.io/project-local-compiler-versions-with-.vvmrc.html), qui fixe la version du compilateur d'un projet comme `global.json` : documenté dans le `docs.md` de 0.5.2, pas encore essayé.
- `go` avec `-use-coroutines` : quels OS le prennent en charge en 0.5.2, et si une instruction `go` évite alors vraiment un thread de l'OS.
- La *data race* sur la map de l'exercice 3 de la leçon 7 sous Linux et macOS, où je n'ai exécuté que la *race* du compteur (en CI).
- Si le suivi des issues de V connaît déjà le bug du `return` à l'intérieur de `lock`, et le canal fermé qui ne déclenche pas de panic.
