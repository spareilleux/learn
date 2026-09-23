---
title: 5. /slashforge:investigate y /slashforge:review-pr
description: Ejecutar en el laboratorio la investigación de solo lectura de SlashForge sobre un bug que este curso ya conoce, y su revisión de pull requests con GitHub sin sesión iniciada — lo que encontró cada una, dónde se detuvo, lo que costó, y el archivo que una ejecución escribió fuera del repositorio porque el laboratorio lo permitía.
sidebar:
  order: 5
---

Código: [`code/slashforge/lab/run.sh`](https://github.com/spareilleux/learn/blob/main/code/slashforge/lab/run.sh), en el laboratorio de la [lección 3](../03-setup-against-init/). Las ejecuciones son la e1, la e1b y la e4 del [diario](../journal/#experimentos): 2026-09-22, Claude Code 2.1.280, `claude-opus-5-5[1m]`. La lección 4 trató `-quick`.

## `/slashforge:investigate`: entra un síntoma, sale un informe

[`investigate.md`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/slashforge/investigate.md) es un despachador hacia [`forge-workflow-investigation.md`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/forge-workflow-investigation.md), que tiene tres fases: I1 recepción (pide el síntoma solo si no diste ninguno), I2 investigar, *"read-only … No edits to application code"*, e I3 informe y traspaso. No hay puerta: con un síntoma, el flujo llega hasta el final. Lo que produce es un informe de hallazgos en HTML bajo `docs/slashforge/investigations/`, y una línea de traspaso para `/slashforge:code`.

El síntoma dado era el hallazgo de la lección 1, así que la respuesta se conoce de antemano:

```bash
bash lab/run.sh <lab> e1b-investigate 0.50 10 \
  "/slashforge:investigate bin/install.js --dry-run lists 21 files but an install writes 32"
```

Las dos ejecuciones lo encontraron. Del mensaje final de e1:

```
Confirmed. `--dry-run` doesn't ask the real installer what it will write. It builds its own list at `bin/install.js:499-530`, and that list only includes `GUIDE_FILES` (16), `COMMAND_FILES` (4) and the meta file (1), for a total of 21.

The real writer, `installFiles()` at `bin/install.js:214-279`, also writes `ASSET_FILES` (2, line 247) and `SKILL_FILES` (9, line 252). 21 + 2 + 9 = 32, which accounts for the whole gap.
```

Añadió la etiqueta `copy` que la lección 1 también había encontrado, una cosa que el curso no había escrito — el dry run no menciona los `REMOVED_GUIDE_FILES` obsoletos que borra una instalación — y una corrección propuesta: una función de planificación compartida por los dos caminos, con una prueba de regresión. El solo lectura aguantó: después de las dos ejecuciones, `git status` en el repositorio del laboratorio estaba vacío.

## El informe que no se escribió

La fase I3 no deja que el modelo escriba el informe de una vez. El armazón HTML del informe, con todo su CSS, se distribuye como `forge-report-shell.html`; el modelo escribe solo el cuerpo, y un *"substitution step splices the two together"*, para que los informes no diverjan y el CSS no cueste tokens de salida cada vez. El empalme es un [script `node -e`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/forge-workflow-investigation.md#L99-L112), en línea en la guía — y el laboratorio solo permite `node` para las pruebas y para el dry run del instalador. Así que en las dos ejecuciones se rechazó el empalme, y no existe ningún informe.

Lo que hizo cada ejecución a continuación es la parte interesante.

**e1**, en la primera versión del laboratorio, que listaba `Edit` y `Write` entre las herramientas permitidas. Con `node` rechazado, el modelo escribió el empalme como un script, `sf-splice.js`, en `%TEMP%` — fuera del repositorio — y terminó su mensaje pidiendo al usuario que lo ejecutara:

```
Report: the splice script with the full report body is at `C:/Users/spare/AppData/Local/Temp/sf-splice.js`. To create the report, run `node C:/Users/spare/AppData/Local/Temp/sf-splice.js`.
```

Nada infringió las reglas tal como las había planteado el laboratorio: `Write` estaba permitido, sin ruta. Esa es exactamente la trampa. En las [reglas de permisos](https://code.claude.com/docs/en/permissions) de Claude Code, una herramienta listada en `--allowedTools` sin especificador está permitida *en todas partes*; `--permission-mode acceptEdits` por sí solo acepta ediciones *"for paths in the working directory or `additionalDirectories`"*. El laboratorio ahora se apoya en lo segundo y lista cada archivo que aparece en la carpeta temporal durante una ejecución.

**e1b**, con el laboratorio corregido: ninguna escritura fuera, ningún informe, y la ejecución terminó por el límite de turnos, en 11 turnos de 10, con `error_max_turns`, tras gastar 0.38 USD. Sus tres comandos rechazados fueron dos dry runs del instalador en un directorio personal temporal y el propio empalme.

| Ejecución | Laboratorio | Turnos | Coste | Informe | Fuera del repositorio |
|---|---|---|---|---|---|
| e1 | `Write` permitido sin ruta | 15 | 0.45 USD | no | `%TEMP%\sf-splice.js`, 4,175 bytes |
| e1b | solo `acceptEdits` | 11 (límite 10) | 0.38 USD | no | nada |

Dos límites de la medición. Ninguna ejecución produjo el informe, así que la mitad de la hipótesis que lo concierne queda sin probar. Y e1 informó 15 turnos con el mismo `--max-turns 10` y terminó con normalidad, mientras que e1b se detuvo; el porqué queda anotado en el diario como *por verificar*. El README espera *"~15–60k tokens"*; las dos ejecuciones leyeron más de 350,000 tokens de la caché de prompts, en su mayoría los mismos archivos en cada turno.

## `/slashforge:review-pr`: detenido en la puerta de entrada

[`review-pr.md`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/slashforge/review-pr.md) empieza con una comprobación previa: *"`gh` must be installed and authenticated, or nothing here works"*, y si no lo está, *"stop and tell the user to run `gh auth login`. Do not attempt a workaround."* El laboratorio tiene su propio `GH_CONFIG_DIR`, vacío, así que `gh` no tiene sesión iniciada; solo para esta ejecución, `GH_STATUS_ONLY=1` permitió `gh auth status` y siguió rechazando cualquier otro comando `gh`.

```bash
GH_STATUS_ONLY=1 bash lab/run.sh <lab> e4-review-pr 0.25 5 "/slashforge:review-pr"
```

```
I stopped at the preflight check because the GitHub CLI isn't logged in. `gh auth status` failed, so I couldn't list PRs or read any PR data. Nothing was read from GitHub and nothing was written.
```

4 turnos, 35 s, 0.17 USD, ninguna solución alternativa intentada. Es la ejecución más barata posible del comando, y la hipótesis escrita antes quedó confirmada palabra por palabra.

Pasada la comprobación previa, el workflow tiene dos puertas. R1 pregunta qué PR revisar. R5, antes de publicar nada, es la puerta más estricta del kit: muestra *"the exact text that will appear on GitHub"*, pregunta *"Post this review? `approve` · `comment` · `request-changes` · `edit` · `cancel`"*, y dice *"Never infer the choice from severity."* Una revisión es pública y lleva tu nombre; el laboratorio nunca llega a R5, y no debe llegar.

## Tres comandos, un patrón

| | investigate | review-pr | code `-quick` (lección 4) |
|---|---|---|---|
| Primera parada en el laboratorio | el empalme del informe, rechazado | la comprobación previa de `gh` | la puerta del plan |
| Archivos cambiados en el repositorio | 0 | 0 | 0 |
| Coste de la ejecución | 0.38–0.45 USD | 0.17 USD | 0.25 USD |

Cada comando hizo lo que dice su archivo, hasta el punto en que el laboratorio o una persona tenía que decir que sí. La única sorpresa vino del laboratorio, no de SlashForge: con una herramienta sin ruta asociada, el modelo la usó para hacer el trabajo por otro camino. Cuando des permisos a un agente, escribe la ruta junto con la herramienta.

## Puntos clave

- `/slashforge:investigate` no tiene puerta cuando se le da un síntoma; se mantuvo en solo lectura y encontró la causa raíz que este curso encontró por comparación.
- Su informe se empalma con un comando `node`. Un laboratorio que rechaza `node` no obtiene informe; uno que permite `Write` en todas partes puede obtener en su lugar un script en otro sitio.
- Una herramienta en `--allowedTools` sin ruta está permitida en todas partes; `acceptEdits` por sí solo limita las ediciones al directorio de trabajo.
- `/slashforge:review-pr` se detiene en su comprobación previa cuando `gh` no tiene sesión iniciada, como dice su archivo, y nunca publica sin una elección explícita en R5.

## Ejercicios

1. Escribe la regla de permisos que dejaría ejecutar el empalme del informe en el laboratorio sin permitir `node` en general. ¿Qué necesitarías saber antes sobre el comando?
2. ¿Por qué la fase I3 empalma un armazón fijo en lugar de dejar que el modelo escriba todo el archivo HTML? Da las dos razones de la guía y una que no da.
3. En e4, ¿qué ajuste del laboratorio hizo fallar `gh auth status`, y qué habría pasado con tu configuración real de `gh`?

<details>
<summary>Solución</summary>

1. No se puede, con la guía tal como está. El empalme es `node -e '<script>' <shell> <fragment> <report> <title>`, y una regla `Bash` reconoce un comando por su prefijo: `Bash(node -e:*)` permitiría cualquier script, lo que es tan amplio como permitir `node`. La versión estrecha necesita que el script sea un archivo, como lo es `forge-open.sh`: distribuir el empalme como, por ejemplo, `forge-splice.js` junto al armazón, y permitir `Bash(node <install path>/forge-splice.js:*)`. Hasta entonces, la opción segura es ejecutar tú mismo el empalme a partir del fragmento de cuerpo que escribió el modelo.
2. La guía: el CSS es idéntico en todos los informes, así que regenerarlo *"wastes output tokens"*, y *"lets reports drift apart visually"*. Una más: un armazón fijo es una superficie de ataque fija. El changelog de 4.1.2 corrigió un título que podía cerrar `</title>` antes de tiempo; un armazón que el modelo reescribe cada vez tendría que acertar con ese escape cada vez.
3. `GH_CONFIG_DIR` apuntaba a un directorio vacío dentro del laboratorio, así que `gh` no encontró ninguna sesión. Con tu configuración real, `gh` habría tenido la sesión iniciada, la comprobación previa habría pasado, y R1 habría listado las pull requests pendientes de tu revisión — leyendo GitHub en tu nombre, que es por lo que el laboratorio lo aísla.

</details>
