---
title: 10. Écrire sa propre action
description: Une action JavaScript sans dépendances et une action conteneur — les inputs en variables INPUT_, les outputs, ce que le runner vérifie et ce qu'il ne vérifie pas, et trois vrais échecs.
sidebar:
  order: 10
---

## Trois sortes d'actions

La [leçon 6](../06-reuse/) a écrit une action composite : des steps YAML. Les deux autres sortes exécutent du **code** :

| | Composite | JavaScript | Conteneur Docker |
|---|---|---|---|
| `runs.using` | `composite` | `node24` (ou `node20`) | `docker` |
| Exécute | des steps dans le job de l'appelant | `node` sur le runner | un conteneur construit ou téléchargé sur le runner |
| Systèmes d'exploitation | tous | tous | « ne peuvent s'exécuter que sur des runners dotés d'un système d'exploitation Linux » |
| Inputs | `${{ inputs.x }}` | variables d'environnement `INPUT_X` | variables `INPUT_X` et `args` |
| Coût de démarrage | aucun | aucun | la construction ou le téléchargement de l'image |
| Analogie C# | une méthode faite d'appels à d'autres méthodes | une petite application console | une application console livrée avec son propre OS |
| Azure Pipelines | template de step | tâche personnalisée (Node) | job conteneur |

Les deux exemples ci-dessous vivent dans ce dépôt et sont testés par [`.github/workflows/gha-10-action.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-10-action.yml).

## Une action JavaScript sans dépendances

La même fonction de slug que le code .NET et Java de la [leçon 2](../02-build-and-test/), sous forme d'action. [`.github/actions/slugify/action.yml`](https://github.com/spareilleux/learn/blob/main/.github/actions/slugify/action.yml) :

```yaml
# GitHub Actions course, lesson 10: a JavaScript action without dependencies
name: Slugify
description: Turns a title into a URL slug, like the sample code of lesson 2.

inputs:
  text:
    description: The text to turn into a slug
    required: true
  max-length:
    description: Maximum length of the slug, 0 for no limit
    default: '0'

outputs:
  slug:
    description: The slug

runs:
  using: node24
  main: index.js
```

[`index.js`](https://github.com/spareilleux/learn/blob/main/.github/actions/slugify/index.js) :

```js
// GitHub Actions course, lesson 10: inputs arrive as INPUT_<NAME> variables, outputs go to the GITHUB_OUTPUT file
import fs from "node:fs";

function input(name, { required = false } = {}) {
  const variable = `INPUT_${name.replace(/ /g, "_").toUpperCase()}`;
  const value = (process.env[variable] ?? "").trim();
  if (required && value === "") {
    throw new Error(`Input required and not supplied: ${name}`);
  }
  return value;
}

function slugify(text) {
  return text
    .normalize("NFD")
    .replace(/\p{Mn}/gu, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

try {
  const text = input("text", { required: true });
  const maxLength = Number(input("max-length") || "0");
  let slug = slugify(text);
  if (maxLength > 0) {
    slug = slug.slice(0, maxLength).replace(/-+$/, "");
  }
  console.log(`slug of "${text}" is "${slug}"`);
  fs.appendFileSync(process.env.GITHUB_OUTPUT, `slug=${slug}\n`);
} catch (error) {
  console.log(`::error::${error.message}`);
  process.exitCode = 1;
}
```

- Le runner passe chaque input en variable d'environnement : il « convertit les noms des inputs en lettres majuscules et remplace les espaces par des caractères `_` » ([`Runner.Worker/Handlers/Handler.cs`](https://github.com/actions/runner/blob/v2.337.0/src/Runner.Worker/Handlers/Handler.cs#L181-L187)). Les tirets restent : `max-length` devient `INPUT_MAX-LENGTH`, un nom que bash ne peut pas lire avec `$INPUT_MAX-LENGTH`, mais Node si.
- Les outputs utilisent le même fichier `$GITHUB_OUTPUT` que les steps `run:` ([leçon 4](../04-expressions-and-outputs/)) ; les erreurs, la même commande de workflow `::error::`.
- La plupart des vraies actions passent pour cela par le paquet [`@actions/core`](https://github.com/actions/toolkit/tree/193fa46c20fde8b0ed54194bc08b841c78c0776d/packages/core) (`core.getInput`, `core.setOutput`, `core.setFailed`), et doivent alors commiter `node_modules` ou un bundle `dist/index.js` : le runner n'exécute pas `npm install`. Sans dépendances, il n'y a rien à bundler.

Comme l'action n'est qu'un script, teste-la en local avant tout push, avec les variables que le runner définirait :

```powershell
$env:INPUT_TEXT = "C# 14 & .NET 10"; $env:GITHUB_OUTPUT = "out.txt"; node .github/actions/slugify/index.js
```

```text
slug of "C# 14 & .NET 10" is "c-14-net-10"
```

Les trois mêmes cas que les tests .NET et Java ont donné `hello-world`, `github-actions` et `c-14-net-10` ; un texte vide a donné `::error::Input required and not supplied: text` et le code de sortie 1.

### L'utiliser

Extrait de [`.github/workflows/gha-10-action.yml`, lignes 23-29](https://github.com/spareilleux/learn/blob/93f6f82/.github/workflows/gha-10-action.yml#L23-L29) :

```yaml
      - id: slug
        uses: ./.github/actions/slugify
        with:
          text: GitHub Actions course, lesson 10 — Wörld!
          max-length: 30
      - shell: bash
        run: echo "slug output = ${{ steps.slug.outputs.slug }}"
```

Sur les trois systèmes d'exploitation :

```text
javascript (ubuntu-latest)  | slug of "GitHub Actions course, lesson 10 — Wörld!" is "github-actions-course-lesson-1"
javascript (windows-latest) | slug of "GitHub Actions course, lesson 10 — Wörld!" is "github-actions-course-lesson-1"
javascript (macos-latest)   | slug of "GitHub Actions course, lesson 10 — Wörld!" is "github-actions-course-lesson-1"
javascript (ubuntu-latest)  | slug output = github-actions-course-lesson-1
```

Même résultat partout, et le step de l'action a pris moins d'une seconde. Remarque le `1` : `max-length: 30` a coupé `10` en deux. Le code fait exactement ce qu'il dit ; qu'un slug doive s'arrêter à la fin d'un mot est une question de spécification que le test n'a pas posée.

## Une action conteneur

[`.github/actions/hello-container`](https://github.com/spareilleux/learn/tree/main/.github/actions/hello-container) contient trois fichiers :

[`.github/actions/hello-container/action.yml`](https://github.com/spareilleux/learn/blob/main/.github/actions/hello-container/action.yml) :

```yaml
# GitHub Actions course, lesson 10: a container action (Linux runners only)
name: Hello from a container
description: Prints the operating system of the container it runs in.

inputs:
  who:
    description: Who to greet
    default: world

runs:
  using: docker
  image: Dockerfile
  args:
    - ${{ inputs.who }}
```

[`.github/actions/hello-container/Dockerfile`](https://github.com/spareilleux/learn/blob/main/.github/actions/hello-container/Dockerfile) :

```dockerfile
# GitHub Actions course, lesson 10: the image of the container action, built on the runner at every run
FROM alpine:3.22
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
```

[`.github/actions/hello-container/entrypoint.sh`](https://github.com/spareilleux/learn/blob/main/.github/actions/hello-container/entrypoint.sh) :

```sh
#!/bin/sh
# GitHub Actions course, lesson 10: runs inside the container; the workspace is mounted at /github/workspace
set -e
echo "hello $1 from $(. /etc/os-release && echo "$PRETTY_NAME")"
echo "workdir: $(pwd)"
echo "INPUT_WHO=$INPUT_WHO"
echo "greeting=hello $1" >> "$GITHUB_OUTPUT"
```

### Première exécution : permission refusée

```text
##[command]/usr/bin/docker build -t 128b89:7c5dc9951c794fae826f3098f2786173 -f "/home/runner/work/learn/learn/./.github/actions/hello-container/Dockerfile" "/home/runner/work/learn/learn/.github/actions/hello-container"
...
docker: Error response from daemon: failed to create task for container: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: error during container init: exec: "/entrypoint.sh": permission denied
```

Le fichier a été écrit sous Windows, où Git ne suit pas le bit exécutable (`git config core.filemode` → `false`), il a donc été commité en `100644` — laissé ainsi exprès, pour capturer cette erreur, que tout auteur Windows d'une action conteneur rencontre une fois. La correction se fait dans Git, pas dans le Dockerfile :

```powershell
git update-index --chmod=+x .github/actions/hello-container/entrypoint.sh
git diff --cached --summary
```

```text
 mode change 100644 => 100755 .github/actions/hello-container/entrypoint.sh
```

### Deuxième exécution

```text
hello Grace from Alpine Linux v3.22
workdir: /github/workspace
INPUT_WHO=Grace
greeting output = hello Grace
```

La commande `docker run` du runner montre comment le conteneur voit le job :

```text
-v "/var/run/docker.sock":"/var/run/docker.sock"
-v "/home/runner/work/_temp":"/github/runner_temp"
-v "/home/runner/work/_temp/_github_home":"/github/home"
-v "/home/runner/work/_temp/_github_workflow":"/github/workflow"
-v "/home/runner/work/_temp/_runner_file_commands":"/github/file_commands"
-v "/home/runner/work/learn/learn":"/github/workspace"
```

Le workspace est monté, donc le conteneur peut lire le code récupéré par le checkout, et `$GITHUB_OUTPUT` pointe dans le dossier monté `file_commands`, donc les outputs fonctionnent. Le step a pris 5 secondes, surtout pour construire l'image — contre moins d'une seconde pour l'action JavaScript. Une action conteneur publiée fait en général pointer `image:` vers une image déjà construite (`docker://ghcr.io/…`) pour éviter la construction.

## Publier, en bref

Une action dans son propre dépôt public, avec `action.yml` à la racine, s'utilise avec `owner/repo@v1`. Les conventions, d'après [Gérer les actions personnalisées](https://docs.github.com/actions/how-tos/create-and-publish-actions/manage-custom-actions) : publier des releases avec des tags de version sémantique (`v1.2.0`) et déplacer un tag majeur (`v1`) vers la dernière release compatible — le tag mobile auquel la [leçon 7](../07-security/) conseille aux utilisateurs de ne pas se fier aveuglément. La référencer sur la Marketplace est facultatif. *Pas fait dans ce cours* : les actions d'ici restent locales.

## À retenir

- Les actions JavaScript s'exécutent sur tous les runners et démarrent instantanément ; les actions conteneurs apportent leur propre Linux et ne s'exécutent que sur des runners Linux.
- Les inputs arrivent en variables `INPUT_<NAME>` (en majuscules, tirets conservés) ; les outputs et les erreurs passent par `$GITHUB_OUTPUT` et les commandes de workflow, comme pour n'importe quel step.
- Le runner n'impose pas `required: true` : c'est à l'action de vérifier.
- Commite ce dont l'action a besoin pour s'exécuter : pas de `npm install` sur le runner, les bits exécutables des scripts, et attention au `package.json` du dépôt.

## Exercices

1. Un workflow passe `txt: Hello` au lieu de `text: Hello` à l'action slugify. Que fait le runner de l'input inconnu, et de l'input obligatoire manquant ?

<details>
<summary>Solution</summary>

D'après [`gha-10-exercises.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-10-exercises.yml) :

```text
##[warning]Unexpected input(s) 'txt', valid inputs are ['text', 'max-length']
##[error]Input required and not supplied: text
```

L'input inconnu ne produit qu'un **avertissement**, et le step s'est exécuté quand même. L'erreur vient du code de l'action elle-même : « Les actions qui utilisent `required: true` ne renvoient pas automatiquement d'erreur si l'input n'est pas spécifié. » Sans la vérification dans `index.js`, l'action aurait produit un slug vide et un step vert.

</details>

2. Que se passe-t-il quand `hello-container` est utilisée dans un job `windows-latest` ?

<details>
<summary>Solution</summary>

```text
##[error]Container action is only supported on Linux
```

Le step échoue immédiatement, avant toute construction. Une action destinée aux trois systèmes d'exploitation doit être JavaScript ou composite.

</details>

3. La première version d'`index.js` commençait par `const fs = require("node:fs");`, du Node.js valide. S'exécuterait-elle sur le runner ?

<details>
<summary>Solution</summary>

```text
ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and '/home/runner/work/learn/learn/package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
```

Node cherche le `package.json` le plus proche au-dessus du script, et dans ce dépôt c'est celui du site Astro, qui déclare `"type": "module"`. Non, donc. L'erreur ci-dessus vient du runner, qui exécutait la copie [`exercise-commonjs`](https://github.com/spareilleux/learn/tree/main/.github/actions/exercise-commonjs) ; la même erreur était d'abord apparue en local. Corrections possibles : la syntaxe `import` (choisie ici), un fichier `index.cjs`, ou un `package.json` dans le dossier de l'action. Dans un dépôt dédié à l'action, c'est toi qui maîtrises ce fichier.

</details>

## Sources

- [À propos des actions personnalisées](https://docs.github.com/actions/concepts/workflows-and-actions/custom-actions)
- [Référence de la syntaxe des métadonnées : inputs et `runs`](https://docs.github.com/actions/reference/workflows-and-actions/metadata-syntax)
- [Créer une action JavaScript](https://docs.github.com/actions/tutorials/create-actions/create-a-javascript-action)
- [Gérer les actions personnalisées](https://docs.github.com/actions/how-tos/create-and-publish-actions/manage-custom-actions)
- [Publier des actions sur GitHub Marketplace](https://docs.github.com/actions/how-tos/create-and-publish-actions/publish-in-github-marketplace)
- [`actions/toolkit`](https://github.com/actions/toolkit)
