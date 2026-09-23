---
title: 4. /slashforge:code — diez fases y cuatro puertas
description: Leer las diez fases del workflow de desarrollo de SlashForge y los cuatro lugares donde espera a una persona, y después ejecutar su modo ligero en modo headless sobre una corrección real en el laboratorio y ver dónde se detiene — una ejecución capturada, con su coste, y la única regla que dobló.
sidebar:
  order: 4
---

Código: [`code/slashforge/lab/run.sh`](https://github.com/spareilleux/learn/blob/main/code/slashforge/lab/run.sh), en el laboratorio que construye la [lección 3](../03-setup-against-init/). La ejecución es la e3 del [diario](../journal/#experimentos): una ejecución el 2026-09-22, Claude Code 2.1.280, `claude-opus-5-5[1m]`.

## Diez fases, cuatro puertas

[`forge-workflow.md`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/forge-workflow.md) es la guía que `/slashforge:code` manda leer al modelo. Tiene diez fases; cuatro de ellas están marcadas *(Gate)*, lo que significa que el modelo pregunta y espera:

| Fase | Qué ocurre | Puerta |
|---|---|---|
| 1 Recepción libre | la petición; `slashforge:brainstorm` escribe una especificación de diseño salvo que el cambio sea trivial | |
| 2 Proponer el plan | `slashforge:plan` escribe el plan | |
| 3 Confirmar el plan | | **sí** |
| 4 Decisión de rama | | **sí** |
| 5 Implementar | TDD, depuración, subagentes en paralelo según haga falta | |
| 6 Verificar (lint, pruebas, compilación) | `slashforge:verify`: *"no success claims without evidence"* | |
| 7 Revisión de código | un agente `code-reviewer` | |
| 8 Push y PR | | **sí** |
| 9 Comentarios de la revisión de la PR | `slashforge:review-feedback` | |
| 10 Limpieza tras el merge | | **sí** |

En términos de .NET o Java, las puertas 3 y 4 son lo que un equipo resuelve en un ticket y en una política de nombres de rama, y la puerta 8 es la propia pull request. La diferencia que importa es la que señala la [página de la misión](../): una política de rama la aplica el servidor, y una puerta es una frase que se le pide obedecer al modelo. [`code.md`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/slashforge/code.md) insiste en ello — *"You MUST follow every phase in order. Do not skip phases. Do not combine phases."* — y una instrucción, por enfática que sea, sigue siendo solo una instrucción.

## El modo ligero

`-quick` carga encima [`forge-workflow-quick.md`](https://github.com/rajdeepratan/SlashForge/blob/bd75a4f770bb2e323551c05fab0d3f326c72ae98/templates/forge-workflow-quick.md), que sustituye fases en una tabla: la fase 1 se omite, el plan conserva solo *Changes* y *Test strategy*, la fase 5 usa como mucho una skill, y la revisión por agente de la fase 7 se convierte en una checklist en línea. Las cuatro puertas están todas marcadas **KEEP**, y también la fase 6. El README da al modo ligero *"~40–70k tokens per change"*, frente a 100–250k para el workflow completo.

## La ejecución: una corrección real, hasta la primera puerta

El cambio pedido es el que este curso encontró en la lección 1 y que `/slashforge:investigate` diagnosticó en la [lección 5](../05-investigate-and-review-pr/): hacer que el dry run liste todo lo que escribe la instalación.

```bash
bash lab/run.sh <lab> e3-code-quick 0.75 20 \
  "/slashforge:code -quick make bin/install.js --dry-run list every file that installFiles writes, including the skills and the two assets"
```

```
exit:      0
wall:      57 s
turns:     6
tokens:    in 10, cache write 23433, cache read 158847, out 1710
cost:      0.2534734 USD (as computed by Claude Code)
denials:   0
changed:   0 path(s) in the lab repository
```

Leyó el instalador y sus pruebas, escribió un plan escueto y se detuvo:

```
Plan (lean)

Changes — `bin/install.js` only:
- Add an exported `plannedWrites(target, { guideFiles, assetFiles, commandFiles, skillFiles })` that returns `{ kind, src, dest }` entries in the same order `installFiles` writes them: guides (rendered), the 2 assets (copied), commands + skills (rendered), then `meta.json`.
- Replace the inline list in the `--dry-run` branch (`bin/install.js:499-527`) with a call to `plannedWrites`. …

Test strategy (TDD, `test/install.test.js`):
- Install into a temp dir and check that the `dest` list from `plannedWrites` equals the list `installFiles` returns. This keeps the two from drifting apart again.
- …

Two things I need from you before I start:
1. Plan: OK as written?
2. Branch: you're on `lab`. Should I work here, or create a new branch (for example `fix/dry-run-lists-all-writes` off `lab`)?
```

El plan es el correcto. Es la corrección que sugería la lección 1 por comparación con el `ShouldProcess` de PowerShell: una sola lista, usada por la vista previa y por la acción, y una prueba que las compara para que no puedan volver a divergir. Y ningún archivo cambió: la puerta aguantó.

Aunque aguantó con una forma algo distinta de la de la guía. La ejecución hizo la pregunta de la fase 3 y la de la fase 4 en un solo mensaje, cuando `code.md` dice *"Do not combine phases"*. Aquí eso no cuesta nada — las dos respuestas hacen falta antes de cualquier edición, y una ejecución headless se habría detenido en la primera de todos modos. Pero muestra que el orden de las fases es algo que el modelo interpreta, no algo que se aplica. Si el orden te importa, tiene que vivir en algún sitio donde se aplique, como un hook o una regla del lado del servidor; el [curso de programación agéntica](../../agentic-coding/03-hooks-skills-subagents/) traza esa línea.

## Lo que costó la ejecución, y lo que no midió

La ejecución se detuvo después de la fase 2, así que mide el coste fijo de llegar a la primera decisión: 0.25 USD, 57 s. Frente a los *"~40–70k tokens"* del README, la respuesta depende de lo que se cuente: 1,720 tokens de entrada y salida nuevas, 23,433 escritos en la caché de prompts, 158,847 leídos de ella. La mayor parte de lo que lee el modelo son las mismas guías y los mismos archivos otra vez en cada turno, lo que la caché abarata pero no hace gratuito.

Más allá de las puertas, el laboratorio no puede ir. La fase 5 editaría y ejecutaría las pruebas, cosa que el laboratorio permite. La fase 8 haría push y abriría una pull request, cosa que el laboratorio rechaza, ya que el clon no tiene remote y `gh` está bloqueado, y debe rechazar: es una decisión con tu nombre. Responder a las puertas de una en una, con `claude -p --resume` y un tope para cada respuesta, es la manera de medir el resto; el diario lo recoge como una decisión del autor, con su presupuesto.

## Puntos clave

- `/slashforge:code` tiene diez fases; la 3 (plan), la 4 (rama), la 8 (push y PR) y la 10 (limpieza) esperan a una persona, y `-quick` conserva las cuatro.
- Una puerta es una instrucción al modelo. La ejecución respetó la puerta y dobló el orden de las fases, haciendo dos puertas en un solo mensaje.
- En modo headless, el workflow se detiene en su primera puerta sin ningún archivo cambiado. Aquí eso llevó 6 turnos, 57 s y 0.25 USD.
- Los rangos de tokens del README no dicen cómo cuentan la entrada en caché, que aquí es la mayor parte de la entrada.

## Ejercicios

1. El plan propone un `plannedWrites` exportado en lugar de un flag en `installFiles` que omita las escrituras. Da un argumento a favor de cada diseño.
2. Responde a las dos preguntas de la ejecución con `claude -p --resume`, de una en una, cada una con su propio tope. ¿Qué fase detiene la ejecución a continuación, y la deja pasar el laboratorio?
3. El README dice que el modo ligero no escala por sí mismo: *"if the plan reveals more than 2 files or a new abstraction, it stops and tells you to restart with `/slashforge:code`"*. ¿Entra este plan en ese caso?

<details>
<summary>Solución</summary>

1. Un `plannedWrites` separado es una función pura del destino y de las cuatro listas: fácil de probar, y el dry run y la instalación la llaman los dos, así que comparten una sola lista por construcción. Un flag `dryRun` dentro de `installFiles` comparte todavía más — el mismo bucle decide y actúa — pero mezcla imprimir y escribir en una sola función, y cada nuevo tipo de archivo necesita las dos ramas. La prueba del plan, que compara la lista planificada con lo que devuelve `installFiles`, protege el primer diseño contra la divergencia.
2. Tras *"OK"* y *"work here on `lab`"*, la fase 5 edita `bin/install.js` y `test/install.test.js` y ejecuta `npm test`, cosa que el laboratorio permite (un `git commit` no está en su lista de permitidos, así que cualquier commit se rechaza); la fase 6 verifica; sigue la revisión en línea de la fase 7; la fase 8 es la siguiente puerta, y el laboratorio rechaza el push. Anota el coste de cada ejecución reanudada.
3. El plan toca dos archivos, `bin/install.js` y `test/install.test.js`, que no son *more than 2*, y añade una función exportada. Si una función que sustituye a una lista en línea cuenta como *new abstraction* lo juzga el modelo; en esta ejecución juzgó que no y se quedó en modo ligero.

</details>
