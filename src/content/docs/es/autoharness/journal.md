---
title: Diario
description: Notas fechadas del curso de AutoHarness — el commit fijado, una lectura estática del plugin, seis fixtures prerregistradas ejecutadas en aislamiento, los defectos que reprodujeron, los errores del propio arnés, el veredicto y lo que queda por verificar.
sidebar:
  order: 99
---

## Progreso

- [x] AutoHarness fijado en `ca39a72`, leído de forma estática: eventos del ciclo de vida, métrica de uso, propiedad, robustez, autoridad, costes, pruebas; 14 hipótesis escritas
- [x] Seis fixtures prerregistradas y luego ejecutadas en subprocesos aislados, sin modelo ni instalación: `code/autoharness/fixtures.py`, hasheado antes de la primera ejecución
- [x] Evaluación escrita, con la evidencia separada de las afirmaciones: [`evaluation.md`](https://github.com/spareilleux/learn/blob/main/code/autoharness/results/evaluation.md), veredicto **no adoptar** en `ca39a72`
- [x] Lección 1: un laboratorio de fixtures, seis promesas probadas sin instalar
- [ ] Lección 2: el bucle y sus fronteras de autoridad (H4, H12, H14)
- [ ] Lección 3: por qué el uso no es calidad — contadores, madurez, capacidad (H1, H5)
- [ ] Lección 4: caídas, concurrencia e historial (H8, H9, H11)
- [ ] Lección 5: la evaluación y una lista de comprobación de adopción
- [x] Las fixtures en Linux y macOS: los mismos resultados, y la CI las ejecuta ahora en los tres sistemas

## QA

Cada fila la reproduce [`fixtures.py`](https://github.com/spareilleux/learn/blob/main/code/autoharness/fixtures.py) o [`redact_probe.py`](https://github.com/spareilleux/learn/blob/main/code/autoharness/redact_probe.py) en el commit `ca39a72` en Windows 11 con Python 3.14.2, con entradas sintéticas, salvo cuando el estado dice *leído*. Todavía no se ha informado nada upstream; es una decisión aparte.

| Esperado | Qué ocurre | Dónde | Medida | Estado |
|---|---|---|---|---|
| Las skills escritas a mano nunca se tocan (README, líneas 10, 23 y 229-230) | Un `create` con el nombre de una skill escrita a mano sustituye su cuerpo, no guarda copia y marca la skill como del agente. Un `update` de la misma skill se rechaza | [`promoter.py#L51-L53`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/hook/promoter.py#L51-L53), [`#L158`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/hook/promoter.py#L158), [`#L129-L133`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/hook/promoter.py#L129-L133) | F1: `sentinel_survives: false`, `agent_created_after: true`, `archived_copy: false`; control `self_produced` | Reproducido, no informado ([2026-09-26](#2026-09-26--seis-fixtures-ejecutadas-en-aislamiento)) |
| El barrido de inicio quita los restos de AutoHarness | Borra todos los `*.tmp` bajo la carpeta de skills, incluido el `draft.tmp` de un usuario dentro de una skill escrita a mano, en un vaciado en vacío | [`skill_store.py#L82-L90`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/lib/skill_store.py#L82-L90) | F5: `tmp_survives: false`, el control `draft.txt` sobrevive | Reproducido, no informado ([2026-09-26](#2026-09-26--seis-fixtures-ejecutadas-en-aislamiento)) |
| Una línea inválida en la cola de intenciones cuesta esa línea | Una sola línea truncada hace que cada vaciado lance `JSONDecodeError` antes de escribir nada, y la cola nunca se vacía | [`intent_queue.py#L29-L33`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/lib/intent_queue.py#L29-L33), [`promoter.py#L231-L240`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/hook/promoter.py#L231-L240) | F2: 2 vaciados, 2 `JSONDecodeError`, 0 de 2 intenciones válidas escritas, `queue_left: true`; el control escribe 2 | Reproducido, no informado ([2026-09-26](#2026-09-26--seis-fixtures-ejecutadas-en-aislamiento)) |
| Los secretos se redactan antes de que una ventana llegue al reflector | Una clave escrita en JSON, `{"api_key": "…"}`, y el cuerpo de una clave privada PEM pasan; `{"password": "…"}` también | [`redaction_rules.toml#L10-L11`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/lib/redaction_rules.toml#L10-L11), [`#L25-L27`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/lib/redaction_rules.toml#L25-L27) | F3: el canario sobrevive en 2 de 3 formas; el control `api_key = …` se redacta. Sonda: el `password` en JSON sobrevive | Reproducido, no informado ([2026-09-26](#2026-09-26--seis-fixtures-ejecutadas-en-aislamiento)) |
| Una redacción dice qué regla se activó | Una etiqueta puede volver a redactarse con `api_key_assignment`, porque contiene `secret:`: `[REDACTED:[REDACTED:secret:api_key_assignment]]` | [`redaction_rules.toml#L25-L27`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/lib/redaction_rules.toml#L25-L27) | La cabecera PEM de F3, y `Bearer …` en la sonda | Reproducido, exploratorio (no prerregistrado) |
| Las credenciales en una URL se redactan | Ninguna regla apunta a ellas. En `postgres://admin:…@db.example.com/prod`, la regla de correo quita contraseña y host juntos, por accidente, y deja el usuario | [`redaction_rules.toml#L29-L31`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/lib/redaction_rules.toml#L29-L31) | Sonda: `postgres://admin:[REDACTED:pii:email]/prod` | Reproducido, exploratorio |
| Una skill que AutoHarness escribe, puede volver a leerla | En Windows con configuración regional cp1252, un cuerpo no ASCII se escribe en UTF-8 y se relee con el códec regional: `UnicodeDecodeError` en el byte 0x81 | [`atomic.py#L31-L32`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/lib/atomic.py#L31-L32), [`skill_store.py#L26-L28`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/lib/skill_store.py#L26-L28) | F4: lanza la excepción sin el modo UTF-8; el control `PYTHONUTF8=1` lo relee igual | Reproducido solo en Windows, que el badge de plataformas del README no incluye; reproducido de nuevo en el runner `windows-latest` de GitHub ([2026-09-27](#2026-09-27--las-fixtures-en-linux-windows-y-macos)) |
| Las skills escritas por la herramienta llevan *«a `self-authored` ledger marker»* (README, líneas 85-86) | La propiedad es un `.sidecar.json` con `"created_by": "agent"`; el registro (*ledger*) nunca se consulta para eso | [`sidecar.py#L47-L51`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/lib/sidecar.py#L47-L51), [`#L75-L76`](https://github.com/tigerless-labs/autoharness/blob/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b/src/autoharness/lib/sidecar.py#L75-L76) | — | Leído en el código, no ejecutado ([2026-09-26](#2026-09-26--leer-el-código-fijado)) |

## Experimentos

Cada hipótesis se escribió en [`preregistration.md`](https://github.com/spareilleux/learn/blob/main/code/autoharness/results/preregistration.md) antes de la primera ejecución. El archivo se hasheó a las 15:29:21 EDT (SHA-256 `b9dc7b7d…`), y los cambios posteriores a la ejecución figuran al final. Cada fixture se ejecutó en un subproceso nuevo con un entorno construido desde cero y un directorio personal desechable; ninguna escribió en ese directorio, y el `~/.claude/autoharness` real no existía ni antes ni después. La segunda ejecución es igual a la primera.

| Pregunta | Hipótesis (escrita antes de la ejecución) | Resultado | Veredicto | Entrada, código |
|---|---|---|---|---|
| F0 — ¿El arnés llega al promotor? | Un `create` válido con un nombre nuevo se escribe, marcado `created_by: agent` | `ok: true`, `agent_created: true` | Control positivo superado | [2026-09-26](#2026-09-26--seis-fixtures-ejecutadas-en-aislamiento), [`fixtures.py`](https://github.com/spareilleux/learn/blob/main/code/autoharness/fixtures.py) |
| F1 (H2) — ¿`create` se apropia de una skill escrita a mano con el mismo nombre? | La comprobación de propiedad solo cubre `update`, `patch`, `remove_file` y `delete`, así que un `create` sustituye el cuerpo y se apropia de la skill; el control `update` se rechaza | Control: rechazado, `self_produced`, cuerpo sin cambios. `create`: `ok`, centinela desaparecido, sidecar `agent`, sin archivo | Confirmada | [2026-09-26](#2026-09-26--seis-fixtures-ejecutadas-en-aislamiento), [`fixtures-run.jsonl`](https://github.com/spareilleux/learn/blob/main/code/autoharness/results/fixtures-run.jsonl) |
| F2 (H10) — ¿Una línea truncada en la cola bloquea la ejecución? | `read` analiza cada línea antes de promover y `clear` va al final, así que los dos vaciados lanzan una excepción y la cola se queda | Control: 2 escritas, luego 0, cola vaciada. Tratamiento: `JSONDecodeError` dos veces, 0 escritas, la cola se queda | Confirmada | ídem |
| F3 (H13) — ¿El redactor detecta una clave JSON entre comillas y un cuerpo PEM? | No: la regla no admite comillas antes de los dos puntos, y la regla PEM solo reconoce la cabecera | Control redactado; el canario sobrevive en `json_quoted` y en `pem` | Confirmada | ídem |
| F4 (nueva) — ¿Una skill no ASCII sobrevive a un viaje de ida y vuelta en Windows? | No: escrita en UTF-8, leída en cp1252, `UnicodeDecodeError` en 0x81; el control `PYTHONUTF8=1` la relee igual | Exactamente eso | Confirmada, solo Windows | ídem |
| F5 (H3) — ¿El barrido borra el `*.tmp` de un usuario? | Sí: todos los `*.tmp` bajo la carpeta de skills, sea quien sea su autor; el control `draft.txt` sobrevive | `draft.tmp` borrado; `draft.txt` y `SKILL.md` intactos | Confirmada | ídem |
| F0–F5 en Linux y macOS — ¿los mismos resultados? | Sí para F0–F3 y F5; la primera ejecución de F4 relee igual, como su control, con una configuración regional UTF-8 | WSL Ubuntu, Python 3.14.4: 0 diferencias, F4 igual con `utf8_mode: 1`. Ejecución de CI [36364810915](https://github.com/spareilleux/learn/actions/runs/36364810915): `check.py` pasa en `ubuntu-latest`, `windows-latest` y `macos-latest` | Confirmada; la razón era incompleta: el entorno de la fixture no tiene configuración regional, y Python activa el modo UTF-8 en la configuración regional C | [2026-09-27](#2026-09-27--las-fixtures-en-linux-windows-y-macos), [`check.py`](https://github.com/spareilleux/learn/blob/main/code/autoharness/check.py) |

## 2026-09-26 — Leer el código fijado

El encargo fijó [`ca39a72`](https://github.com/tigerless-labs/autoharness/tree/ca39a72e4353ebef11b7de13c1fc7fa5f4df421b), la cabeza de `main` el 2026-09-25: 71 archivos versionados, unas 7000 líneas, licencia MIT. Durante esta lectura no se ejecutó nada de su código.

Lo que muestra el código, en el orden que sigue la evaluación:
- **El bucle funciona sin nadie.**
  - Cuatro hooks llaman a un mismo despachador.
  - Cada 50 llamadas a herramientas, y al final de la sesión, un `claude -p --agent autoharness:reflector --dangerously-skip-permissions` en segundo plano con Haiku lee una ventana redactada y encola intenciones mediante una herramienta MCP.
  - El promotor las escribe cuando termina cada reflector y en cada `Stop` de la sesión principal.
- **La propiedad es un simple archivo JSON.** Un `.sidecar.json` con `"created_by": "agent"` marca una skill como del agente. El README habla de un marcador en el registro; el registro no interviene.
- **No hay bloqueos en ningún sitio.** Comentarios en cuatro módulos los dejan para más adelante.
- **El índice no está acotado por los ajustes de capacidad.** Las skills en periodo de prueba, y las leídas pero nunca invocadas, quedan fuera del grupo con tope pero siguen recibiendo una línea en el índice.
- **El redactor tiene diez expresiones regulares.** Ninguna apunta a claves `sk-ant-`, JWT ni credenciales en una URL.
- **El *42% → 78% on CORE-Bench* del README** se atribuye al [artículo HAL](https://arxiv.org/abs/2510.11977). El repositorio no contiene código de benchmark, y su README dice que el proyecto se valida *«in use, not on a benchmark»* (en uso, no con un benchmark). Las carpetas `experiments/` y `docs/plans/` que citan el README y algunos comentarios no están en el árbol en este commit.

De la lectura salieron catorce hipótesis, de H1 a H14. Las que no necesitan ni modelo ni hook eran candidatas a fixtures; las demás figuran en el §2 de la evaluación, para lecciones posteriores.

Las pruebas de upstream no usan ni red ni modelo: `claude` siempre se sustituye por un doble. Dos requieren cuidado:
- `test_layer.py` lee el directorio personal real y ejecuta `git` en el directorio de trabajo real;
- `test_spawn.py` necesita un shebang POSIX.

No ejecuté la suite de upstream.

## 2026-09-26 — Seis fixtures, ejecutadas en aislamiento

La prerregistración se hasheó a las 15:29:21 EDT. Dos minutos después, el arnés ejecutó cada fixture en su propio subproceso:
- un entorno construido desde cero: `PATH` limitado a la carpeta del intérprete, `PYTHONPATH` en el clon, y `HOME`, `USERPROFILE`, `TEMP` y `TMP` en una carpeta desechable;
- raíces de skills explícitas en cada llamada;
- ningún import del módulo que lanza `claude`.

La ejecución tardó 14 segundos en Windows 11 con Python 3.14.2 (codificación regional: cp1252).

Se **confirmaron** cinco hipótesis, cada una frente a un control que se comportó como se pretendía, y el control positivo se superó. El detalle está en la [lección 1](../01-fixture-lab/). En resumen:
- un `create` se apropia de una skill escrita a mano (F1);
- una línea inválida en la cola detiene la promoción (F2);
- las claves JSON y los cuerpos PEM escapan al redactor (F3);
- una skill no ASCII no se puede releer en Windows (F4);
- un vaciado en vacío borra el `*.tmp` de un usuario (F5).

**Exploratorio, no prerregistrado:**
- Una etiqueta de redacción puede volver a redactarse, lo que pierde el nombre de la regla que se activó primero.
- Una sonda del redactor encontró que `{"password": "…"}` sobrevive, y que la contraseña de una URL solo desaparece porque la regla de correo reconoce por casualidad `password@host`.

Ambos están en la tabla de QA, marcados como exploratorios.

El propio arnés tenía el error de F4. Su stdout redirigido usaba cp1252, lo que desfiguró una cadena al mostrar la primera ejecución. Se corrigió con `sys.stdout.reconfigure(encoding="utf-8")` y quedó registrado como cambio posterior a la medición 1. La segunda ejecución se decodifica en las mismas ocho líneas.

**Veredicto: no adoptar en `ca39a72`,** ni en sesiones reales de Claude Code ni en un directorio personal real. Los motivos están medidos, no leídos: F1 y F5 rompen la promesa central, F2 detiene el bucle y F3 filtra. Los arreglos parecen pequeños:
- una comprobación de existencia para `create`;
- un barrido limitado a los nombres temporales de AutoHarness;
- un manejo de errores línea por línea;
- claves entre comillas en la regla.

La [evaluación](https://github.com/spareilleux/learn/blob/main/code/autoharness/results/evaluation.md) enumera lo que cambiaría el veredicto. Primero, una versión que vuelva a pasar estas fixtures; después, un piloto en un directorio personal desechable con un reflector falso o con presupuesto limitado.

## 2026-09-26 — Un arnés que salía con 0 sin haber medido nada

A las 23:20, se repitieron los comandos del README del código desde un clon nuevo, tal como los teclearía un lector, con `--clone autoharness-ca39a72` como ruta relativa. Todos los hijos fallaron con `ModuleNotFoundError`: `PYTHONPATH` era relativo, y el directorio de trabajo del hijo es una carpeta temporal. El padre mostró los fallos como resultados y **salió con 0**.

Los arreglos:
- la ruta del clon se vuelve absoluta;
- la línea de un hijo que falló sigue nombrando su fixture;
- el padre sale con 1 si algún hijo sale con un código distinto de cero.

`redact_probe.py` recibió el mismo arreglo de ruta. La nueva ejecución, con una ruta relativa y luego absoluta, es idéntica byte a byte a la salida registrada. La ruta de fallo se comprobó a propósito: un clon inexistente da ahora `exit: 1`. Es el cambio posterior a la medición 3. Los resultados no cambiaron; lo que cambió es que una ejecución rota ya no puede pasar por una medición.

## 2026-09-27 — Las páginas del curso

La misión, la lección 1 y este diario se escribieron en inglés, francés y español a partir de las salidas registradas, y el curso se añadió a la barra lateral y a las páginas de inicio. `fixtures.py --hashes` se volvió a ejecutar y dio las seis huellas prerregistradas. `redact_probe.py` fija ahora `sys.dont_write_bytecode` antes de importar `fixtures.py`, para no dejar una carpeta `__pycache__` en el directorio del curso; su nueva ejecución es idéntica byte a byte a `redact-probe.jsonl`. No se volvió a ejecutar ninguna fixture, y ningún resultado cambió.

## 2026-09-27 — Las fixtures en Linux, Windows y macOS

La revisión de Codex sobre la PR pedía que el código del curso se ejecutara en CI en los tres sistemas, como exigen las convenciones del repositorio. [`check.py`](https://github.com/spareilleux/learn/blob/main/code/autoharness/check.py) vuelve a ejecutar `fixtures.py` y compara cada línea con `fixtures-run.jsonl`. La única excepción se escribió antes de cualquier ejecución en otro sistema: fuera de Windows, la primera ejecución de F4 debe releer igual, como predecía la lista «Por verificar».

- **Esta máquina.** En Windows 11 con Python 3.14.2: 0 diferencias. En WSL, en Ubuntu con Python 3.14.4: 0 diferencias, y la primera ejecución de F4 releyó igual con el modo UTF-8 activo (`utf8_mode: 1`).
- **El control negativo.** Una copia del fichero esperado con un valor cambiado (`tmp_survives`) hace que `check.py` imprima esa diferencia y salga con 1.
- **La CI.** El workflow [`autoharness-examples`](https://github.com/spareilleux/learn/blob/main/.github/workflows/autoharness-examples.yml) pasa en `ubuntu-latest`, `windows-latest` y `macos-latest` ([ejecución 36364810915](https://github.com/spareilleux/learn/actions/runs/36364810915)). Obtiene AutoHarness por su SHA fijado, no instala nada y no llama a ningún modelo. En el runner de Windows de GitHub, F4 se reproduce exactamente: el mismo `UnicodeDecodeError` en el byte 0x81.

La predicción se cumplió, pero su razón era incompleta. El entorno de la fixture se construye desde cero, así que no tiene configuración regional, y en la configuración regional C Python activa el modo UTF-8 ([PEP 540](https://peps.python.org/pep-0540/)). Se midió en WSL. El valor del runner de macOS está en su registro, que no se leyó aquí.

## Por verificar

- Por qué F4 relee igual en el runner de macOS: el modo UTF-8, como en WSL, o el códec de la configuración regional. `check.py` lo imprime en el registro del job.
- F4 en Windows con Python 3.15, donde la [PEP 686](https://peps.python.org/pep-0686/) hace del modo UTF-8 el predeterminado.
- Las hipótesis aún no ejecutadas:
  - H1: el índice no está acotado por la capacidad;
  - H4: un repositorio que incluye un `.sidecar.json` convierte una skill en «gestionada»;
  - H5: un solo sidecar mal formado detiene el índice durante una sesión;
  - H8, H9: una intención perdida entre la lectura y el vaciado, y ventanas de reflexión que se solapan;
  - H11: un segundo archivo borra el primero;
  - H12: el transporte *fork* deja disponible `Bash`;
  - H14: un `interactive.jsonl` con commit se vacía en el primer `Stop`.
- Si `rglob("*.tmp")` entra en una carpeta de skill que es un enlace simbólico, lo que depende de la versión de Python.
- La suite de pruebas de upstream, ejecutada en aislamiento.

## Preguntas abiertas

- ¿Con qué frecuencia propondría el reflector un `create` cuyo nombre choque con una skill existente? F1 muestra que nada lo impide; solo una ejecución con un modelo, falso o con presupuesto limitado, puede decir cuán probable es.
- AutoHarness cuenta una skill como *usada* cuando el modelo llama a la herramienta `Skill`, antes de que la llamada se autorice o se ejecute. ¿Qué distancia hay de ahí a *útil*, y qué le hace eso a una skill de seguridad que se usa poco?
- ¿Un diario llevado a mano y skills actualizadas a mano, comprobados con pruebas reservadas, lo harían tan bien como el bucle, con un coste conocido?
- ¿Hay que informar de estos hallazgos upstream, y de qué forma? Aún no está decidido.
