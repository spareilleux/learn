---
title: "7. Seguridad: permisos, secretos, fijación de versiones, OIDC"
description: GITHUB_TOKEN con privilegios mínimos, lo que hace el enmascaramiento y lo que no, actions fijadas a un SHA de commit, tokens OIDC en lugar de secretos de la nube, y una inyección de script ejecutada de verdad.
sidebar:
  order: 7
---

## Lo que puede hacer un workflow

Un workflow ejecuta código — el tuyo y el de las actions — con un token que puede actuar sobre el repositorio, a veces secretos y a veces credenciales de la nube. Cuatro preguntas estructuran esta lección:

| Pregunta | Herramienta | Azure Pipelines |
|---|---|---|
| ¿Qué puede hacer el token automático? | `permissions:` | ámbito de autorización de los jobs, permisos del proyecto |
| ¿Dónde van los secretos y quién los ve? | `secrets`, enmascaramiento | variables secretas, grupos de variables |
| ¿La action que ejecuto es la que revisé? | fijación a un SHA de commit | versiones de las tareas |
| ¿Cómo llego a una nube sin una contraseña guardada? | OpenID Connect (`id-token: write`) | conexiones de servicio con federación de identidades de carga de trabajo |

Todo lo que sigue viene de [`.github/workflows/gha-07-security.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-07-security.yml). Sus primeras líneas ([líneas 15-16](https://github.com/spareilleux/learn/blob/93f6f82/.github/workflows/gha-07-security.yml#L15-L16)):

```yaml
permissions:
  contents: read
```

## Permisos de `GITHUB_TOKEN`

Cada job recibe un `GITHUB_TOKEN`, válido solo para ese job. Sus permisos por defecto dependen de una configuración del repositorio (o de la organización); el step *Set up job* de cada ejecución de la [lección 1](../01-first-workflow/) los listó para este repositorio: `Contents: read`, `Metadata: read`, `Packages: read`. No dependas de esa configuración: declara lo que el workflow necesita, como arriba, y añade más por job.

Dos jobs llaman a la misma API — crear una etiqueta con un nombre **vacío**, para que no se pueda crear nada —, uno sin `issues: write` y otro con él ([líneas 28-38](https://github.com/spareilleux/learn/blob/93f6f82/.github/workflows/gha-07-security.yml#L28-L38)):

```yaml
  token-with-issues-write:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      issues: write
    steps:
      - name: Create a label with an empty name, token with issues:write
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          gh api --method POST "repos/$GITHUB_REPOSITORY/labels" -f name= || echo "gh exit code: $?"
```

```text
token-without-issues-write | Contents: read
token-without-issues-write | Metadata: read
token-without-issues-write | gh: Resource not accessible by integration (HTTP 403)

token-with-issues-write    | Contents: read
token-with-issues-write    | Issues: write
token-with-issues-write    | Metadata: read
token-with-issues-write    | gh: Validation Failed (HTTP 422)
```

- 403, *Resource not accessible by integration*: el token no tiene permiso. Es el mensaje que hay que reconocer cuando a un workflow le falta de repente un permiso.
- 422, *Validation Failed*: el permiso se concedió, solo la petición era incorrecta.
- Mi primer intento usaba `gh run list`, que necesita `actions: read`, desde un job con solo `contents: read`. **Funcionó**: en un repositorio público, leer datos públicos no necesita el permiso. Prueba los permisos con una llamada de escritura.

La regla que hay que recordar, según la referencia de la sintaxis de los workflows: «Si especificas el acceso para cualquiera de estos permisos, todos los que no se especifican se establecen en `none`» — ejercicio 1.

## Secretos y enmascaramiento

Los secretos se guardan en la configuración del repositorio, del entorno o de la organización, y se leen con `${{ secrets.NAME }}`. La [lección 4](../04-expressions-and-outputs/) mostró que sus valores se reemplazan por `***` en los logs. Dos hechos más, probados en el job `masking`:

```text
echo "value=''"
value=''
```

Un secreto que no existe es una **cadena vacía**, sin error ni aviso — «Si un secreto no se ha establecido, el valor devuelto por una expresión que hace referencia al secreto … será una cadena vacía». Una errata en el nombre de un secreto produce un job que se ejecuta con una contraseña vacía; compruébalo al principio del job (`test -n "$TOKEN"`).

Un valor **derivado** de un secreto no se enmascara. Regístralo con el comando de workflow `add-mask`:

```text
before add-mask: 849f6dc993e40726
after add-mask:  ***
```

La primera línea ya está en el log para siempre: el enmascaramiento solo se aplica a lo que se imprime después del comando.

Y los forks: «Con la excepción de `GITHUB_TOKEN`, los secretos no se pasan al runner cuando un workflow se desencadena desde un repositorio bifurcado. El `GITHUB_TOKEN` tiene permisos de solo lectura en los pull requests de repositorios bifurcados.» Por eso un pull request desde un fork no puede desplegar — y por eso el evento `pull_request_target`, que se ejecuta con los secretos del repositorio base y un token de lectura/escritura, nunca debe descargar el código del pull request ni ejecutarlo.

## La inyección de script, de verdad

La [lección 4](../04-expressions-and-outputs/) explicó por qué `${{ }}` no debe pegar texto que no es de confianza en un script. Esto es lo que ocurre en un runner. El job `injection` ([líneas 84-94](https://github.com/spareilleux/learn/blob/93f6f82/.github/workflows/gha-07-security.yml#L84-L94)):

```yaml
  injection:
    runs-on: ubuntu-latest
    steps:
      - name: Unsafe, the expression is pasted into the script
        run: |
          echo "Title: ${{ inputs.title }}"
      - name: Safe, the value goes through the environment
        env:
          TITLE: ${{ inputs.title }}
        run: |
          echo "Title: $TITLE"
```

```powershell
gh workflow run gha-07-security.yml --field 'title=$(whoami)'
```

```text
Unsafe | echo "Title: $(whoami)"
Unsafe | Title: runner
Safe   | echo "Title: $TITLE"
Safe   |   TITLE: $(whoami)
Safe   | Title: $(whoami)
```

El step inseguro **ejecutó** `whoami`: el input pasó a formar parte del script antes de que bash lo leyera. El step seguro imprimió el texto. Sustituye `inputs.title` por el título de un pull request, un comentario de una issue o un nombre de rama, y cualquiera que pueda abrir un pull request ejecutará comandos con tu token.

## Fijar las actions

`uses: actions/checkout@v7` apunta a un **tag**, y quien controle el repositorio de la action puede mover un tag a otro commit. La documentación: «Fijar una action a un SHA de commit completo es actualmente la única forma de usar una action como una versión inmutable.»

Encuentra el commit que hay detrás de un tag con la API:

```powershell
gh api repos/actions/checkout/commits/v7 --jq .sha
```

```text
3d3c42e5aac5ba805825da76410c181273ba90b1
```

De [`.github/workflows/gha-07-security.yml`, líneas 53-57](https://github.com/spareilleux/learn/blob/93f6f82/.github/workflows/gha-07-security.yml#L53-L57):

```yaml
  pinned:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - run: git log -1 --format='%h %s'
```

```text
Download action repository 'actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1' (SHA:3d3c42e5aac5ba805825da76410c181273ba90b1)
```

El step *Set up job* de una ejecución sin fijar también registra el SHA que resolvió — `Download action repository 'actions/checkout@v7' (SHA:3d3c42e5…)` en las ejecuciones de la [lección 5](../05-caches-and-artifacts/) —, lo que te dice qué se ejecutó, pero no qué se ejecutará la próxima vez. El comentario `# v7.0.1` mantiene legible la fijación, y herramientas como [Dependabot](https://docs.github.com/code-security/dependabot/working-with-dependabot/keeping-your-actions-up-to-date-with-dependabot) actualizan el SHA y el comentario a la vez. Las demás lecciones mantienen tags para que el YAML siga siendo legible; en los workflows que manejan secretos o despliegan, fija.

## OpenID Connect en lugar de secretos de la nube

Para desplegar en Azure, AWS o Google Cloud, la forma antigua guarda una clave de larga duración como secreto. Con [OIDC](https://docs.github.com/actions/concepts/security/openid-connect), el job pide a GitHub un token firmado que describe **quién** es, y la nube lo cambia por credenciales de corta duración si su política de confianza coincide. El job necesita un solo permiso ([líneas 59-63](https://github.com/spareilleux/learn/blob/93f6f82/.github/workflows/gha-07-security.yml#L59-L63)):

```yaml
  oidc:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write
```

El job `oidc` pide un token para la audiencia `learn-course` e imprime sus claims — nunca el token en sí:

```text
iss: https://token.actions.githubusercontent.com
aud: learn-course
sub: repo:spareilleux@6644695/learn@1368550922:ref:refs/heads/main
repository: spareilleux/learn
ref: refs/heads/main
event_name: push
job_workflow_ref: spareilleux/learn/.github/workflows/gha-07-security.yml@refs/heads/main
runner_environment: github-hosted
lifetime: 300 s
```

- `sub` es lo que suele comparar una política de confianza de la nube. Contiene los **ID** del propietario y del repositorio (`@6644695`, `@1368550922`): «los repositorios creados después del 15 de julio de 2026 usan ahora un formato de sujeto predeterminado inmutable que incluye tanto el ID del propietario como el ID del repositorio». Este repositorio se creó el 2026-09-13. Los repositorios más antiguos conservan `repo:owner/repo:ref:…` salvo que activen el nuevo formato, y una política de confianza escrita para un formato no coincide con el otro.
- El token vive 5 minutos (`exp - iat`).
- Sin `id-token: write`, el job `no-oidc` imprimió `ACTIONS_ID_TOKEN_REQUEST_URL is not set`: no hay forma de pedir un token.

Configurar el lado de la nube (una credencial federada de Azure, por ejemplo) queda fuera de este curso; *por verificar* en un curso de despliegue.

## Puntos clave

- Declara `permissions:` al principio de cada workflow y añade más por job; un 403 *Resource not accessible by integration* significa que falta un permiso.
- Un secreto que falta es una cadena vacía; los valores derivados necesitan `::add-mask::`; los forks no reciben secretos.
- Nunca pegues `${{ }}` que no sea de confianza en `run:` — la inyección ejecutó `whoami` en un runner real.
- Un tag puede moverse, un SHA de commit no.
- OIDC sustituye a las claves de la nube guardadas: `id-token: write`, un token de 5 minutos, un claim `sub` en el que confiar — en el formato inmutable para los repositorios nuevos.

## Ejercicios

1. El workflow declara `permissions: contents: read`. Un job declara `permissions: actions: read` y ejecuta `actions/checkout`. ¿Qué permisos tiene el token del job, y funciona el checkout en este repositorio público?

<details>
<summary>Solución</summary>

El bloque a nivel de job **sustituye** al de nivel de workflow; los permisos no especificados pasan a `none`. De [`gha-07-exercises.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/gha-07-exercises.yml):

```text
GITHUB_TOKEN Permissions
Actions: read
Metadata: read
93a0ea8 GitHub Actions course: lesson 7 workflows (permissions, masking, pinning, OIDC, injection)
```

Ya no hay `Contents`, y el checkout funcionó igualmente: cualquiera puede clonar un repositorio público. En un repositorio privado, el mismo job no podría descargar el código — *por verificar*. Repite cada permiso que necesite un job, incluido `contents: read`.

</details>

2. Ejecuta el job de inyección con el título `x"; echo INJECTED; echo "y`. ¿Qué imprimen los dos steps?

<details>
<summary>Solución</summary>

```text
Unsafe | echo "Title: x"; echo INJECTED; echo "y"
Unsafe | Title: x
Unsafe | INJECTED
Unsafe | y
Safe   | Title: x"; echo INJECTED; echo "y
```

La comilla del input cerró la cadena del step inseguro, y `echo INJECTED` se convirtió en un comando aparte. El step seguro imprimió el valor sin cambios, comillas incluidas.

</details>

3. Fija `actions/setup-dotnet@v6`. ¿Qué comando da el SHA, y qué línea hay que escribir?

<details>
<summary>Solución</summary>

```powershell
gh api repos/actions/setup-dotnet/commits/v6 --jq .sha
```

```text
a98b56852c35b8e3190ac28c8c2271da59106c68
```

```yaml
      - uses: actions/setup-dotnet@a98b56852c35b8e3190ac28c8c2271da59106c68 # v6
```

Es el SHA que el runner registró para `actions/setup-dotnet@v6` en la lección 5: `Download action repository 'actions/setup-dotnet@v6' (SHA:a98b56852c35b8e3190ac28c8c2271da59106c68)`. Prefiere el tag de versión completo en el comentario (`# v6.x.y`) para que la herramienta de actualización conozca la versión exacta.

</details>

## Fuentes

- [Referencia de uso seguro](https://docs.github.com/actions/reference/security/secure-use)
- [Sintaxis de los workflows: `permissions`](https://docs.github.com/actions/reference/workflows-and-actions/workflow-syntax#permissions)
- [Usar secretos en GitHub Actions](https://docs.github.com/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets)
- [Inyecciones de script](https://docs.github.com/actions/concepts/security/script-injections)
- [OpenID Connect](https://docs.github.com/actions/concepts/security/openid-connect) y la [referencia de OIDC](https://docs.github.com/actions/reference/security/oidc)
- [Eventos que desencadenan workflows: `pull_request_target`](https://docs.github.com/actions/reference/workflows-and-actions/events-that-trigger-workflows#pull_request_target)
