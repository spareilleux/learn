---
title: Diario
description: Notas de progreso fechadas del curso de Gaia — la revisión fijada y cómo se ejecutó, lo que la batería de pruebas y el verificador informaron de verdad, las sorpresas (un rechazo que es en sí mismo un evento, un verify que antes imprimía rojo y salía con 0), y la lista de lo que queda por verificar, empezando por la ejecución de la fábrica que gasta turnos reales de modelo.
sidebar:
  order: 99
---

## Progreso

- [x] Revisión fijada elegida y extraída limpia; cada comando se volvió a ejecutar sobre ella
- [x] Lección 1: el problema, los cuatro ejes, la doctrina
- [x] Lección 2: los seis verbos, con un intercambio real entre tres actores
- [x] Lección 3: el registro de eventos, el protocolo de commit, `verify`
- [x] Lección 4: el trazador de coordinación, la fábrica de agentes, los recibos y el digest del árbol
- [x] Lección 5: la escalera de carriles y los veredictos del ecosistema
- [ ] `factory:agent` ejecutado de extremo a extremo con turnos reales de Claude y Codex
- [ ] Versiones en francés y en español
- [ ] Una lección sobre la bomba alojada — el lado de GitHub Actions — que ha crecido en `main` y que este curso no cubre

## 2026-09-15 — Preparación y versiones

- **Gaia** en [`d68e900`](https://github.com/GuitarAlchemist/gaia/tree/d68e90099ae2a6fbbec9d428617bfcd02095aac0), la cabeza de `main` el 2026-09-13. Extraído como worktree enlazado en modo detached, para que el árbol estuviera limpio y nada local se colara en una salida.
- **Node.js** v24.12.0 en Windows 11. Gaia fija una versión exacta — `.node-version` y `engines.node` dicen ambos **26.8.1** — y nada lo impone cuando invocas `node` tú mismo, así que todo lo de estas lecciones se ejecutó con 24.12.0 sin ninguna advertencia ni fallo. Ejecutarlo con la versión fijada está *por verificar*; la ruta de CI es Windows con esa versión, y Ubuntu se describe como exploración de portabilidad, no como una puerta.
- **Cero dependencias**, así que nada de `npm install` antes de todo esto, ni `node_modules` en un checkout limpio. La afirmación no es marketing: `package.json` no tiene ninguna clave `dependencies` ni `devDependencies`, y el ejecutor de pruebas es `node --test`.
- Cada comando del bus se ejecutó sobre un directorio de datos desechable mediante `GAIA_INTERAGENT_DATA_DIR`, así que nada tocó un espacio de trabajo real. Las salidas se pegan sin editar, salvo las rutas absolutas acortadas a `…`.

## 2026-09-15 — Lo que informaron de verdad los comandos

| Comando | Resultado |
|---|---|
| `doctor`, directorio vacío | `ok: true`, salida 0, `supportedMaxLiveLanes: 4`, y una nota que dice que ejecutes `initialize --apply` |
| `initialize` | simulación por defecto; `--apply` añadió exactamente un `actor.registered` |
| `bus-cli tools` | exactamente 6: `register`, `send`, `inbox`, `ack`, `heartbeat`, `handoff` |
| `verify` | **37 comprobaciones superadas, 0 fallidas**, en 8 secciones, `evidenceGatesResult: false` |
| `node --test` | **2075 pruebas, 2074 superadas, 0 fallidas, 1 omitida**, 38.9 s |
| `factory:smoke` | `completed`, punto fijo del registro de evidencias `sha256:256a51d2…` sobre 15 eventos y 6 315 bytes, `evidenceGatesResult: true` |
| `inventory-digest` | 323 archivos, 5 937 493 bytes, `ordinal-path-bytes-sha256/1 dccabe8f…` |

El intercambio completo entre tres actores de la lección 2 ocupó **10 eventos y 3 617 bytes** en disco. Merece la pena tener presente ese número junto al modelo de coste de la lección 5: la reproducción es O(eventos × actores), y una sesión real de coordinación entre varias partes es minúscula.

## 2026-09-15 — Sorpresas

**Un rechazo es un evento.** Dirigirse a un nombre de actor ambiguo devuelve `ok: false`, sale con 1 y añade `command.rejected` al registro. Esperaba que el rechazo fuera un valor de retorno y nada más. Es el detalle que hace que el registro responda a «¿qué intentó esta sesión?» y no solo a «¿qué consiguió?», y una vez visto cuesta aceptar un sistema que solo registra los éxitos.

**`verify` antes imprimía una comprobación en rojo y salía con 0.** El README recoge la corrección: tanto `doctor` como `verify` salían antes con 0 sobre un registro cuyo traspaso había transferido autoridad, *mientras `verify` mostraba su propia comprobación en rojo diciendo lo contrario*. Un lector que se fiara del código de salida, o de `ok`, lo leía como un aprobado. Una herramienta que informa de un fallo y devuelve éxito es exactamente el modo de fallo del que trata la lección 1, encontrado dentro del verificador — lo que es un buen argumento a favor de los controles negativos que ahora siempre bloquean.

**Las comprobaciones de evidencia se dividen en dos regímenes, y es deliberado.** Cinco de ellas — tres actores, más de un tipo de actor, un hilo correlacionado, un acuse de recibo, un traspaso — son legítimamente falsas en un espacio de trabajo vacío y correcto, así que informan sin bloquear, salvo que quien llama afirme que el registro *es* evidencia. Yo suponía que un verificador o comprueba algo o no lo comprueba. Que el eje sea la afirmación de quien llama y no la opinión de la herramienta es un diseño mejor que cualquiera de las dos alternativas.

**`resolveLaneLimit` recibe un objeto de opciones.** Llamada con un argumento posicional devuelve en silencio el valor por defecto, y así fue como lo medí mal la primera vez. `resolveLaneLimit({ requested: 6 })` lanza una excepción con la declaración completa de evidencias; `resolveLaneLimit(6)` devuelve `{ limit: 4 }`. Merece señalarse, dado que todo el argumento del módulo es que recortar en silencio es el error — el rechazo es real, pero solo con la forma de llamada documentada.

**Los residuos se publican, no se entierran.** El documento de diseño de la fábrica afirma que no se puede demostrar que un worker que se ejecuta con el usuario del host haya evitado la red, los secretos o las escrituras en otros sitios, y que un recibo que afirmara contención necesitaría una frontera separada del sistema operativo. La mayoría de los proyectos habrían escrito «ejecuta los agentes en un espacio de trabajo aislado». Este nombra el hueco y la capacidad que lo cerraría.

**`main` ha crecido mucho más allá de lo que cubre este curso.** La bomba de Drafts alojada en GitHub Actions, la red de Petri de drenaje, la sala de control, la búsqueda híbrida, la sonda de capacidades del runner, las rondas gestionadas de entrega de PR, la ingesta de observaciones de pruebas — `docs/` contiene unos cincuenta registros de diseño en la revisión fijada. Las cinco lecciones cubren el bus, el registro, la fábrica y los límites. Es una porción deliberada de bala trazadora, no un mapa completo.

## 2026-09-15 — Correcciones hechas durante la redacción

- Primero cité el `AGENTS.md` del repositorio para la regla de que «el privilegio se impide por ausencia». **Ese archivo no existe en `d68e900`** — era un archivo sin seguimiento en un checkout local de una rama más antigua. La cita se sustituyó por la declaración del `README.md` y por la propia cabecera del módulo del operador, ambas verificadas en la revisión fijada. Por la misma razón, todas las demás citas se volvieron a comprobar contra el árbol fijado.
- La copia de trabajo local de la que partí estaba en una rama del 2026-08-29 cuyo `README.md` difería del de `main`, y que no tenía ni `ARCHITECTURE.md` ni `CONTEXT.md`. Partir de un worktree fijado y limpio, en lugar del checkout que estaba abierto en ese momento, es el hábito que lo detectó.

## Por verificar

- **`factory:agent` de extremo a extremo.** Gasta un turno real de Claude y un turno real de Codex con las suscripciones instaladas. La lección 4 lo describe a partir de `src/factory-agent.mjs`, de su documento de diseño y del esquema de su recibo; ninguna afirmación de esa lección procede de una ejecución observada. Qué capturar cuando se ejecute: la forma del recibo con y sin reparación, las líneas de progreso `(not an ETA)`, y si la comprobación de modificaciones del revisor llega a saltar en la práctica con archivos ignorados.
- **Node 26.8.1**, la versión fijada. Todo lo de aquí se ejecutó con 24.12.0.
- **Linux y macOS.** El protocolo de commit está escrito y probado pensando primero en Windows, y el repositorio dice que Linux es exploración, no una puerta. El enfoque del directorio de cerrojo debería comportarse igual; los reintentos de liberación propios de Windows simplemente no se ejercitarían.
- **Un segundo carril concurrente sobre el mismo directorio de datos.** Todas las salidas de estas lecciones proceden de llamadas secuenciales en una sola shell. La unicidad de los identificadores entre procesos es lo que afirma la batería de pruebas, no lo que yo observé.
- **El indicador `authority-language-detected`.** Lo vi saltar con «Please merge this.». No he mirado qué detecta, y la tasa de falsos negativos de una heurística es el número interesante.

## Preguntas abiertas

- El bus serializa las escrituras y **no tiene autenticación** — la confianza es posicional, así que cualquier proceso capaz de lanzar el servidor puede registrarse como cualquier actor. La lección 5 muestra que es uno de los dos bloqueos nombrados para la integración con IX. ¿Cuál es el mecanismo de identidad de actores más pequeño que no convertiría el bus en un almacén de credenciales?
- La reproducción es O(eventos × actores) sobre un registro que nunca se compacta, e `inbox` escribe un evento. Un carril que sondea hace, por tanto, que cada llamada posterior sea más lenta. ¿Hay una ruta de lectura que conserve `inbox.polled` como evidencia sin pagarla en cada reproducción — una instantánea más la cola, como sugiere el documento de escala?
- La cifra de cuatro carriles es honesta al reconocer que no está replicada con clientes reales. Ejecutar esa sonda requiere cuatro carriles de agentes reales simultáneos, lo que cuesta turnos reales de modelo. ¿Cuál es el experimento más barato que discriminaría de verdad — y una mezcla de un carril real y tres sintéticos demostraría algo, o es otra vez la sonda de workers de Node con pasos adicionales?
