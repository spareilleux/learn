---
title: 10. Escribir tu propia acción
description: Una acción JavaScript sin dependencias y una acción de contenedor — los inputs como variables INPUT_, las salidas, lo que el runner comprueba y lo que no, y tres fallos reales.
sidebar:
  order: 10
---

## Tres tipos de acciones

La [lección 6](../06-reuse/) escribió una acción compuesta: steps de YAML. Los otros dos tipos ejecutan **código**:

| | Compuesta | JavaScript | Contenedor Docker |
|---|---|---|---|
| `runs.using` | `composite` | `node24` (o `node20`) | `docker` |
| Ejecuta | steps en el job del llamador | `node` en el runner | un contenedor construido o descargado en el runner |
| Sistemas operativos | todos | todos | «solo pueden ejecutarse en runners con un sistema operativo Linux» |
| Inputs | `${{ inputs.x }}` | variables de entorno `INPUT_X` | variables `INPUT_X` y `args` |
| Coste de arranque | ninguno | ninguno | construir o descargar la imagen |
| Analogía con C# | un método hecho de llamadas a otros métodos | una pequeña aplicación de consola | una aplicación de consola que trae su propio sistema operativo |
| Azure Pipelines | plantilla de step | tarea personalizada (Node) | job de contenedor |

Los dos ejemplos siguientes viven en este repositorio y los prueba [`.github/workflows/gha-10-action.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-10-action.yml).

## Una acción JavaScript sin dependencias

La misma función de slug que el código .NET y Java de la [lección 2](../02-build-and-test/), como acción. [`.github/actions/slugify/action.yml`](https://github.com/spareilleux/learn/blob/main/.github/actions/slugify/action.yml):

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

[`index.js`](https://github.com/spareilleux/learn/blob/main/.github/actions/slugify/index.js):

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

- El runner pasa cada input como variable de entorno: «convierte los nombres de los inputs a letras mayúsculas y reemplaza los espacios por caracteres `_`». Los guiones se quedan: `max-length` pasa a ser `INPUT_MAX-LENGTH`, un nombre que bash no puede leer como `$INPUT_MAX-LENGTH`, pero Node sí.
- Las salidas usan el mismo archivo `$GITHUB_OUTPUT` que los steps `run:` ([lección 4](../04-expressions-and-outputs/)); los errores, el mismo comando de workflow `::error::`.
- La mayoría de las acciones reales usan para esto el paquete [`@actions/core`](https://github.com/actions/toolkit/tree/main/packages/core) (`core.getInput`, `core.setOutput`, `core.setFailed`), y entonces deben incluir en el commit `node_modules` o un bundle `dist/index.js`: el runner no ejecuta `npm install`. Sin dependencias, no hay nada que empaquetar.

Como la acción es solo un script, pruébala en local antes de cualquier push, con las variables que definiría el runner:

```powershell
$env:INPUT_TEXT = "C# 14 & .NET 10"; $env:GITHUB_OUTPUT = "out.txt"; node .github/actions/slugify/index.js
```

```text
slug of "C# 14 & .NET 10" is "c-14-net-10"
```

Los mismos tres casos que las pruebas de .NET y Java dieron `hello-world`, `github-actions` y `c-14-net-10`; un texto vacío dio `::error::Input required and not supplied: text` y el código de salida 1.

### Usarla

```yaml
      - id: slug
        uses: ./.github/actions/slugify
        with:
          text: GitHub Actions course, lesson 10 — Wörld!
          max-length: 30
      - shell: bash
        run: echo "slug output = ${{ steps.slug.outputs.slug }}"
```

En los tres sistemas operativos:

```text
javascript (ubuntu-latest)  | slug of "GitHub Actions course, lesson 10 — Wörld!" is "github-actions-course-lesson-1"
javascript (windows-latest) | slug of "GitHub Actions course, lesson 10 — Wörld!" is "github-actions-course-lesson-1"
javascript (macos-latest)   | slug of "GitHub Actions course, lesson 10 — Wörld!" is "github-actions-course-lesson-1"
javascript (ubuntu-latest)  | slug output = github-actions-course-lesson-1
```

El mismo resultado en todas partes, y el step de la acción tardó menos de un segundo. Fíjate en el `1`: `max-length: 30` partió `10` por la mitad. El código hace exactamente lo que dice; si un slug debe cortarse al final de una palabra es una pregunta de especificación que la prueba no hizo.

## Una acción de contenedor

[`.github/actions/hello-container`](https://github.com/spareilleux/learn/tree/main/.github/actions/hello-container) tiene tres archivos:

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

```dockerfile
# GitHub Actions course, lesson 10: the image of the container action, built on the runner at every run
FROM alpine:3.22
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
```

```sh
#!/bin/sh
# GitHub Actions course, lesson 10: runs inside the container; the workspace is mounted at /github/workspace
set -e
echo "hello $1 from $(. /etc/os-release && echo "$PRETTY_NAME")"
echo "workdir: $(pwd)"
echo "INPUT_WHO=$INPUT_WHO"
echo "greeting=hello $1" >> "$GITHUB_OUTPUT"
```

### Primera ejecución: permiso denegado

```text
##[command]/usr/bin/docker build -t 128b89:7c5dc9951c794fae826f3098f2786173 -f "/home/runner/work/learn/learn/./.github/actions/hello-container/Dockerfile" "/home/runner/work/learn/learn/.github/actions/hello-container"
...
docker: Error response from daemon: failed to create task for container: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: error during container init: exec: "/entrypoint.sh": permission denied
```

El archivo se escribió en Windows, donde Git no registra el bit de ejecución (`git config core.filemode` → `false`), así que se incluyó en el commit como `100644` — se dejó así a propósito, para capturar este error, con el que todo autor de una acción de contenedor en Windows se encuentra una vez. La corrección está en Git, no en el Dockerfile:

```powershell
git update-index --chmod=+x .github/actions/hello-container/entrypoint.sh
git diff --cached --summary
```

```text
 mode change 100644 => 100755 .github/actions/hello-container/entrypoint.sh
```

### Segunda ejecución

```text
hello Grace from Alpine Linux v3.22
workdir: /github/workspace
INPUT_WHO=Grace
greeting output = hello Grace
```

El comando `docker run` del runner muestra cómo ve el contenedor el job:

```text
-v "/var/run/docker.sock":"/var/run/docker.sock"
-v "/home/runner/work/_temp":"/github/runner_temp"
-v "/home/runner/work/_temp/_github_home":"/github/home"
-v "/home/runner/work/_temp/_github_workflow":"/github/workflow"
-v "/home/runner/work/_temp/_runner_file_commands":"/github/file_commands"
-v "/home/runner/work/learn/learn":"/github/workspace"
```

El workspace está montado, así que el contenedor puede leer el código obtenido con el checkout, y `$GITHUB_OUTPUT` apunta a la carpeta montada `file_commands`, así que las salidas funcionan. El step tardó 5 segundos, casi todo en construir la imagen — frente a menos de un segundo para la acción JavaScript. Una acción de contenedor publicada suele apuntar `image:` a una imagen ya construida (`docker://ghcr.io/…`) para evitar la construcción.

## Publicar, en resumen

Una acción en su propio repositorio público, con `action.yml` en la raíz, se usa como `owner/repo@v1`. Las convenciones, según [Gestionar acciones personalizadas](https://docs.github.com/actions/how-tos/create-and-publish-actions/manage-custom-actions): publicar versiones con tags de versionado semántico (`v1.2.0`) y mover un tag mayor (`v1`) a la última versión compatible — el tag móvil del que la [lección 7](../07-security/) aconseja a los consumidores no fiarse a ciegas. Listarla en el Marketplace es opcional. *No se hace en este curso*: las acciones de aquí se quedan en local.

## Puntos clave

- Las acciones JavaScript se ejecutan en todos los runners y arrancan al instante; las acciones de contenedor traen su propio Linux y solo se ejecutan en runners Linux.
- Los inputs llegan como variables `INPUT_<NAME>` (en mayúsculas, con los guiones); las salidas y los errores usan `$GITHUB_OUTPUT` y los comandos de workflow, como cualquier step.
- El runner no impone `required: true`: la acción tiene que comprobarlo.
- Incluye en el commit lo que la acción necesita para ejecutarse: nada de `npm install` en el runner, bits de ejecución para los scripts, y cuidado con el `package.json` del repositorio.

## Ejercicios

1. Un workflow pasa `txt: Hello` en lugar de `text: Hello` a la acción slugify. ¿Qué hace el runner con el input desconocido, y con el obligatorio que falta?

<details>
<summary>Solución</summary>

Según [`gha-10-exercises.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-10-exercises.yml):

```text
##[warning]Unexpected input(s) 'txt', valid inputs are ['text', 'max-length']
##[error]Input required and not supplied: text
```

El input desconocido solo produce una **advertencia**, y el step se ejecutó de todos modos. El error viene del propio código de la acción: «Las acciones que usan `required: true` no devolverán automáticamente un error si el input no se especifica». Sin la comprobación en `index.js`, la acción habría producido un slug vacío y un step en verde.

</details>

2. ¿Qué pasa cuando se usa `hello-container` en un job `windows-latest`?

<details>
<summary>Solución</summary>

```text
##[error]Container action is only supported on Linux
```

El step falla inmediatamente, antes de construir nada. Una acción pensada para los tres sistemas operativos tiene que ser JavaScript o compuesta.

</details>

3. La primera versión de `index.js` empezaba con `const fs = require("node:fs");`, Node.js válido. ¿Se ejecutaría en el runner?

<details>
<summary>Solución</summary>

```text
ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and '/home/runner/work/learn/learn/package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
```

Node busca el `package.json` más cercano por encima del script, y en este repositorio es el del sitio Astro, que declara `"type": "module"`. No. El error de arriba viene del runner, al ejecutar la copia [`exercise-commonjs`](https://github.com/spareilleux/learn/tree/main/.github/actions/exercise-commonjs); el mismo error había aparecido antes en local. Soluciones: la sintaxis `import` (la elegida aquí), un archivo `index.cjs`, o un `package.json` en la carpeta de la acción. En un repositorio dedicado a la acción, ese archivo lo controlas tú.

</details>

## Fuentes

- [Acerca de las acciones personalizadas](https://docs.github.com/actions/concepts/workflows-and-actions/custom-actions)
- [Referencia de la sintaxis de metadatos: inputs y `runs`](https://docs.github.com/actions/reference/workflows-and-actions/metadata-syntax)
- [Crear una acción JavaScript](https://docs.github.com/actions/tutorials/create-actions/create-a-javascript-action)
- [Gestionar acciones personalizadas](https://docs.github.com/actions/how-tos/create-and-publish-actions/manage-custom-actions)
- [Publicar acciones en GitHub Marketplace](https://docs.github.com/actions/how-tos/create-and-publish-actions/publish-in-github-marketplace)
- [`actions/toolkit`](https://github.com/actions/toolkit)
