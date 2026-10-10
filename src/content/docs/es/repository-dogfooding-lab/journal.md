---
title: Diario
description: Evidencia detallada del laboratorio de dogfooding, incluido su método, matrices y decisiones de promoción.
sidebar:
  order: 99
---

## Progreso

- [x] Registro machine-readable y renderer determinista
- [x] Cinco matrices generadas
- [x] Invariantes de promoción y prueba de salida obsoleta
- [x] Primeras oportunidades clásicas y agénticas
- [x] Método del curso como oportunidad
- [x] Checks CI de paridad y estructura del diario
- [ ] Primera revisión adversaria independiente
- [x] Primer candidato promovido o rechazado con evidencia de repositorio
- [x] Pruebas de mutación y de propiedades sobre un archivo real de GA, prerregistradas ([lección 6](../06-mutation-property-testing/))

## Experimentos

| Pregunta | Hipótesis previa | Resultado medido | Veredicto | Evidencia |
|---|---|---|---|---|
| ¿Puede un registro generar vistas sin que una puntuación otorgue autoridad? | Renderer e invariantes separan prioridad y promoción | 4 oportunidades, 5 matrices, 6/6 pruebas en 0,002 s; sin cambiar estado ni autoridad | confirmado para el tracer local | [entrada](#2026-09-20--primer-tracer-de-matrices), [`code/repository-dogfooding-lab`](https://github.com/spareilleux/learn/tree/main/code/repository-dogfooding-lab) |
| ¿Puede Jev reducir un 50 % el coste posterior a igual calidad? | Un gate tipado resuelve casos sin falsos soportes | Sigue sin medirse. La calibración de 13 llamadas se ejecutó en vivo el 2026-09-23 y no llamó a ningún modelo posterior, así que no puede responderla | inconcluso | [entrada](#2026-09-23--el-banco-en-vivo-mide-algo-distinto-de-su-pregunta), [`evidence/jev-live.json`](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/evidence/jev-live.json) |
| ¿Agrupar 12 preguntas sobre un estado compartido reduce los tokens de entrada sin cambiar ninguna respuesta? | El plan sin red predecía un 79 % menos de bytes; si los tokens siguen a los bytes, el ahorro supera el 50 %, con la calidad sin probar | 2487 tokens de entrada frente a 14939, un 83,4 % menos, y la misma elección en los 12 casos: exactitud 0,9167 en ambos, cero falsos soportes, Brier 0,1657 frente a 0,1645, 453 ms frente a 4451 ms | confirmado para este corpus con n=12, una sola ejecución | [entrada](#2026-09-23--el-banco-en-vivo-mide-algo-distinto-de-su-pregunta), [benchmark TypeSafe](../../typesafe-ai-system-one/04-token-cost-benchmark/) |
| ¿Las puertas llamadas «exige pruebas» y «veredicto confirmado» rechazan un candidato fabricado? | Comprueban la prueba, así que una entrada con campos vacíos y un artefacto inexistente se rechaza | No rechazaron nada: la entrada llegó a `adopted`/`confirmed` con cero errores. Las puertas comprobaban que las claves estuvieran presentes, nunca su contenido | refutada, luego corregida | [entrada](#2026-09-23--una-lectura-adversaria-rompe-las-puertas-del-laboratorio), [`dogfood.py`](https://github.com/spareilleux/learn/blob/main/code/repository-dogfooding-lab/dogfood.py) |
| ¿Una red de Petri encuentra en un repositorio defectos de concurrencia que su propia suite de pruebas no ve? | Buscar marcados muertos en un grafo de alcanzabilidad encuentra al menos un defecto real, solo de lectura | Tres encontrados en GA en el commit `a826864`, cada uno confirmado línea por línea antes de publicarlo, y una afirmación retirada antes de publicarla; reportados en [ga#700](https://github.com/GuitarAlchemist/ga/issues/700), [#701](https://github.com/GuitarAlchemist/ga/issues/701), [#702](https://github.com/GuitarAlchemist/ga/issues/702) | prometedor — ningún mantenedor las ha triado aún | [`petri-nets`](../../petri-nets/), [entrada](#2026-09-23--una-lectura-adversaria-rompe-las-puertas-del-laboratorio) |
| ¿Expone un oráculo Petri sin conexión el salto inseguro de consejo Jev a autoridad? | El flujo basado solo en consejo alcanza un efecto; el protegido exige evidencia independiente y concesión de implementación | Soporte falso sintético de 0,98; pasan 3/3 pruebas C# y 1/1 prueba de paridad de la fixture; sin replay en un repositorio real | prometedor localmente, no integrado | [entrada fechada](#jev-petri-2026-09-22), [lección](../05-jev-petri-authority/), [`JevEvidenceGateTests.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/Tests/JevEvidenceGateTests.cs) |
| ¿Es Jev un anotador consultivo utilizable para los seis valores de Demerzel? | ≥ 75 % exacto en casos sintéticos de acuerdo ciego, ≤ 1 T falso, ≤ 1 ausencia leída como refutación, en ambos órdenes | Ningún T falso en 240 llamadas; pero ausencia leída como refutación 7/10, luego 4–5/10 con una regla explícita que además empujó P hacia U 6/10 | inconclusive — `experimenting` | [entrada](#2026-09-25--demerzel-y-jev-el-prerregistro-atrapa-lo-que-el-modelo-esconde), [`opportunities.json`](https://github.com/spareilleux/learn/blob/main/code/repository-dogfooding-lab/opportunities.json) |
| ¿Dejan vivos las pruebas de GA mutantes de `PitchParser.cs`, y una pequeña suite de propiedades a través de la API pública elimina alguno? | H1: algunos mutantes quedan Survived o NoCoverage. H2: las propiedades eliminan al menos uno. H3: ninguna entrada lanza excepción en 10 000 casos | B: 25 Killed, 5 NoCoverage, 0 Survived de 39 (83,33 %). T con las propiedades: exactamente igual. P exploratoria, solo propiedades: los mismos 25. Ninguna excepción; el control negativo falla y se reproduce idéntico | H1 confirmada, H2 refutada, H3 se cumple para una semilla | [entrada](#2026-09-26--pruebas-de-mutación-y-de-propiedades-sobre-pitchparser-de-ga), [`test-quality`](https://github.com/spareilleux/learn/tree/main/code/repository-dogfooding-lab/test-quality) |

## 2026-09-20 — Primer tracer de matrices

Se implementaron `opportunities.json`, validador y renderer con la biblioteca estándar de Python. El registro contiene Jev, el método Learn, auditoría hexagonal y frontera RabbitMQ.

```text
python dogfood.py write
python dogfood.py check
python -m unittest -v
```

Resultado: `validated=4 matrices=current mirrors=current`; 6/6 pruebas en 0,002 s. Se rechaza promoción sin artefactos y adopción sin veredicto confirmado, y se comprueba paridad EN/FR/ES y estructura del diario. Sin red externa ni mutación de repositorios.

<a id="jev-petri-2026-09-22"></a>

## 2026-09-22 — Límite de autoridad Jev × Petri sintético

Hipótesis previa: si una clasificación Jev muy confiada conduce directamente a un efecto, un falso `supported` puede autorizar trabajo; tokens separados de evidencia verificada y concesión de implementación bloquean esa ruta. Baseline: el caso sintético fijado `gaia_design_authority` devuelve `supported` con 0,98 cuando se espera `contradicted`.

La prueba Python vincula la fixture JSON compartida a la respuesta sintética. La prueba C# reproduce `classify → authorize_from_advisory` en la red insegura y explora completamente la red protegida para las tres combinaciones donde falta al menos uno de los tokens independientes. Una ruta válida sigue siendo posible con ambos tokens. Resultado local: pasan 3/3 pruebas C# y 1/1 prueba de paridad; tras regenerar, `dogfood.py check` informa `validated=5 matrices=current mirrors=current`. Sin llamadas al proveedor, tokens facturados, efectos en producción ni replay de Gaia/IX sobre una revisión exacta. Veredicto: experimento de especificación prometedor, todavía no apto para incubación.

## 2026-09-23 — Una lectura adversaria rompe las puertas del laboratorio

Otro modelo revisó el esquema y las puntuaciones con una sola consigna: romperlos. Lo consiguió dos veces, y ambos exploits son ahora pruebas de no regresión en `test_dogfood.py`.

**Las puertas comprobaban la presencia, no la prueba.** Esta entrada validaba sin un solo error antes de hoy:

```json
{ "id": "malicious-fabricated-adoption", "status": "adopted", "verdict": "confirmed",
  "artifacts": ["does-not-exist.txt"],
  "baseline": "", "success_metric": "", "falsifier": "", "result": "", "authority": "" }
```

Un candidato sin prueba, sin resultado y con un artefacto ausente del disco llegaba a `adopted`. Bastaba con que `artifacts` fuera una lista no vacía y que `verdict` valiera la cadena `confirmed`; ningún otro campo se comprobaba por su contenido. El nombre de esas puertas prometía una verificación semántica que el código no hacía, en contra de la lección 2, que pide que un lector juzgue un experimento *sin confiar en el autor*.

**Un rechazo podía no probar nada.** `rejected` quedaba fuera de la exigencia de artefactos: un candidato podía descartarse sin prueba ni resultado, en contra de la lección 1, que conserva los rechazos precisamente para que nadie repita la idea.

**Lo que cambia.** Todo campo de texto debe ser no vacío; toda ruta de artefacto debe existir en el disco, aceptando los enlaces por confianza; `rejected` se une a los estados que exigen prueba y requiere un veredicto refutado o inconcluso; un candidato promovido exige al menos un artefacto en este repositorio, no solo enlaces. Las tablas de promoción y de resultados se ordenan ahora por estado de promoción y no por puntuación: el revisor no encontró ningún camino de la puntuación al estado en los datos, pero una tabla que siempre muestra primero la mejor puntuada ejerce la misma autoridad sobre la atención del lector.

La prueba anterior llamada «la puntuación no muta la autoridad» afirmaba que una suma pura no modificaba su argumento, cierto por construcción y por tanto prueba de nada. Ahora comprueba la tabla de promoción generada.

Resultado medido: `validated=6 matrices=current mirrors=current`, 9/9 pruebas en 0,004 s. Se añadieron dos candidatos: la técnica de redes de Petri que produjo [ga#700 a #702](https://github.com/GuitarAlchemist/ga/issues/700), en `incubating`/`promising`, y un contraste entre las redes de Petri de GA y las cinco reglas `ga.*` del ecosistema de gramáticas TARS, en `discovered`.

**Un hallazgo de la revisión que no se corrige aquí.** La oportunidad que describe este curso es la menos falsable del registro: su métrica de éxito es «tiempo de autoría no peor que la referencia», y ninguna referencia está registrada en ninguna parte. Un criterio cuya referencia nunca se midió no puede refutarse. Queda en *Por verificar* en lugar de reformularse en silencio.

**Y el candidato añadido hoy pasó por las puertas antiguas.** Su estado `incubating` lo otorgó una comprobación que igualmente habría sellado la entrada fabricada de arriba. Lo que lo sostiene es la verificación línea por línea contra la fuente de GA, no la aprobación de este registro, que es justamente el argumento para endurecer las puertas antes de confiar en ninguna, incluida la nuestra.

## 2026-09-23 — El banco en vivo mide algo distinto de su pregunta

Las trece llamadas aprobadas salieron contra `jev-1.13.0`. Devuelven un resultado limpio y amplio, y ese resultado no responde a la pregunta que el registro había escrito encima.

**Lo que se midió.** Los mismos doce casos etiquetados, planteados una vez como un solo lote sobre un estado compartido y luego doce veces de uno en uno sobre el estado idéntico byte a byte:

| | Tokens de entrada | Exactitud | Falsos soportes | Brier | Latencia |
|---|---:|---:|---:|---:|---:|
| Lote, 1 llamada | 2487 | 0,9167 | 0 | 0,1657 | 453 ms |
| Aisladas, 12 llamadas | 14939 | 0,9167 | 0 | 0,1645 | 4451 ms |

Agrupar cuesta un **83,4 % menos de tokens de entrada**, muy por encima del 79 % que el plan sin red predecía a partir de los bytes, y no cambió **ninguna respuesta**: las doce elecciones coinciden caso por caso, no solo en agregado. Cero reintentos, cero falsos soportes por ambos lados, y toda la ejecución se mantuvo bajo el techo proxy de 0,0021 $.

**Lo que no se midió, y la entrada daba a entender que sí.** El `next_gate` del registro decía «ejecutar la calibración acotada de 13 llamadas y luego un A/B posterior con modelo fijo solo si la calidad pasa» — escrito como si superar la calibración pesara sobre la hipótesis. No es así. La hipótesis dice que un gate tipado *reduce lo que se envía a un modelo posterior caro*. El banco nunca llama a un modelo posterior; llama a Jev trece veces y solo varía cómo se empaquetan las preguntas. Amortizar un estado compartido entre doce preguntas es un ahorro real y útil, y es una magnitud distinta de la que nombra el criterio de éxito.

Así que la fila de Jev sigue **inconclusa** para su propia pregunta, y una segunda fila registra la afirmación realmente probada. La oportunidad pasa a `incubating` con esa evidencia, no a `adopted`: su `next_gate` es ahora el A/B posterior, nombrado como aquello que la calibración no sustituye.

**Un error, y ambos brazos lo cometieron.** `demerzel_immutable` afirma que un artefacto está direccionado por contenido donde la evidencia ofrece una ruta y una marca de tiempo pero ningún digest — la etiqueta esperada es `insufficient`, y tanto el lote como la llamada aislada respondieron `contradicted`. La ausencia de digest se leyó como conflicto y no como silencio. Idéntico en ambos brazos, así que el empaquetado no es la causa; es el caso de doce que explica el 0,9167.

La ejecución completa, cada hash de petición y cada respuesta, está commiteada en `code/typesafe-ai-system-one/evidence/jev-live.json`, para que las cifras de arriba puedan recalcularse sin confiar en esta entrada.

## 2026-09-25 — Demerzel y Jev: el prerregistro atrapa lo que el modelo esconde

La octava oportunidad pasó de una línea del curso TypeSafe («Demerzel — clasificar evidencia sin interpretar la constitución») a dos ejecuciones medidas en un día. Las cifras están en el [diario de TypeSafe](../../typesafe-ai-system-one/journal/#2026-09-25--lógica-hexavalente-de-demerzel-con-jev); esta entrada registra lo que hizo el método.

- **La regla se escribió antes que los datos, y se sostuvo.** El modelo parecía bueno en conjunto (41/58, 71 %, cero T falsos); sin el límite de ausencia prerregistrado, eso se lee como un éxito con reservas. Con él, la ejecución es INCONCLUSIVE, porque el prerregistro nombraba el fallo buscado: la ausencia leída como refutación. Estaba ahí, en 7/10.
- **Dos anotadores, no uno.** Las etiquetas del autor las revisó un segundo agente que no las vio. Discrepan en 2 de 60 casos (ambos D frente a U, justo la frontera en prueba), que se excluyeron en lugar de arbitrarse a posteriori.
- **El segundo paso respondió otra pregunta de la esperada.** La corrección debía mostrar si la falla estaba en el modelo o en las definiciones de Demerzel. Mostró ambas cosas: la frase sobre conflictos corrigió C por completo, y la de ausencia reveló una ambigüedad en las propias definiciones, porque los casos P tampoco tienen ejecución directa.
- **Una prueba barata hizo más que la ejecución en vivo.** Una prueba unitaria «una suma de exactamente 0,99 se acepta» falló antes de cualquier llamada. Era la trampa del error de coma flotante que ya había tumbado un brazo de IX.

Registro: `jev-demerzel-hexavalent-annotator`, `experimenting`, veredicto `inconclusive`. La siguiente compuerta es una definición U con una cláusula complementaria para indicios que inclinan, prerregistrada aparte. No se modificó ningún archivo de Demerzel: una frase propuesta para `logic/hexavalent-logic.md` necesita antes una prueba con archivos de creencias reales.

## 2026-09-25 — Seguir una oportunidad de un repositorio a otro hasta que cada uno responda

La instrucción del usuario era asegurarse de que la oportunidad se implementara, se verificara y quedara en el diario en todos los lugares donde aplicaba. Preguntar a las sesiones propietarias respondió más de lo que habría respondido leer su código:

| Repositorio | Pregunta | Respuesta, y quién la verificó | Resultado |
|---|---|---|---|
| Demerzel | ¿Algún cambio de definición corrige la ausencia leída como refutación? | Esta sesión: tres pasos prerregistrados más 8 creencias reales, 376 llamadas, unos 0,009 $ calculados | No. La regla entra en Demerzel como un reparto de papeles ([PR de Demerzel](https://github.com/GuitarAlchemist/Demerzel/pull/1127), corregida en [#1128](https://github.com/GuitarAlchemist/Demerzel/pull/1128)) |
| Gaia | ¿Un veredicto de modelo sobre evidencia decide una ruta? | La sesión de Gaia, en main `8ed4dfc` | No; el invariante ya se cumple, y la regla para pasos futuros quedó registrada como [gaia#159](https://github.com/GuitarAlchemist/gaia/issues/159) |
| IX | ¿Toca Jev valores hexavalentes, y está activa la trampa del 0,99? | La sesión de IX, con grep sobre `crates/` | No, y no: la tolerancia es 1e-3 |

La lección de método: una oportunidad no queda «adoptada» porque un repositorio la haya medido. Aquí el resultado honesto es una regla escrita (Demerzel), una guarda registrada para un paso que aún no existe (Gaia) y una no-utilización explícita (IX). La entrada del registro sigue en `experimenting`/`inconclusive`: la regla obtenida es una frontera que mantiene fuera al modelo, no una adopción del modelo.

## 2026-09-26 — Pruebas de mutación y de propiedades sobre `PitchParser` de GA

La pregunta: ¿dejan las pruebas deterministas de GA fallos sin detectar en un parser real y pequeño, y detecta alguno una pequeña prueba generativa a través de la API pública? La costura la confirmó el usuario: solo `PitchParser.TryParse`, a través de `Pitch.Sharp.TryParse` y `Pitch.Flat.TryParse`, sin cambios de producción.

Prerregistro: [`results/preregistration.md`](https://github.com/spareilleux/learn/blob/main/code/repository-dogfooding-lab/test-quality/results/preregistration.md), escrito y con su hash calculado a las 12:19 EDT antes de la primera compilación (SHA-256 `fd86962a…`, guardado fuera del repositorio). Tres cambios posteriores figuran en su propia sección:
- un error del generador detectado antes de cualquier ejecución (anteponer `b` da `bb3`, un bemol válido);
- el `[Property]` de FsCheck.NUnit 3.4.0 ignora el `[Explicit]` de NUnit, lo que hizo correr el control negativo con los demás; ahora vive en una categoría;
- la ejecución P, declarada exploratoria antes de lanzarla.

GA en `aa22f91`, extracción parcial de 12 MB. SDK de .NET 10.0.112, Stryker.NET 5.0.0, FsCheck 3.4.0, Windows 11. Cada ejecución mutó solo `PitchParser.cs`, con concurrencia 2, bajo el cerrojo pesado compartido.

| Ejecución | Killed | Survived | NoCoverage | Ignored | Timeout | Puntuación | Duración |
|---|---:|---:|---:|---:|---:|---:|---:|
| Línea base determinista, `dotnet test` | 706/706 superadas | | | | | | 35 s |
| B — pruebas de GA | 25 | 0 | 5 | 9 | 0 | 83,33 % | 109 s |
| T — pruebas de GA + 6 pruebas de propiedades | 25 | 0 | 5 | 9 | 0 | 83,33 % | 142 s |
| P — solo las 6 pruebas de propiedades (exploratoria) | 25 | 0 | 5 | 9 | 0 | 83,33 % | 93 s |

Los cinco mutantes NoCoverage cambian `return false` a `return true` en las ramas defensivas que siguen a una coincidencia correcta de la regex (líneas 38, 43, 49, 58, 67). Ninguna entrada descrita por el contrato público los alcanza. Leer `FlatAccidental.TryParse`, que pasa a minúsculas antes de comparar, sugiere que ni siquiera `CB4` alcanza la línea 58. No se ha ejecutado.

Propiedades: 10 000 casos cada una con la semilla fija `(20260926,7)`, y ningún contraejemplo. Control negativo (sostenidos y bemoles aceptan los mismos textos): `Falsifiable, after 2 tests (2 shrinks)`, reducido a `a#-1`, y una salida idéntica en dos ejecuciones.

Veredicto: H1 confirmada; H2 refutada; H3 se cumple para esta semilla. La lectura honesta es que las pruebas de GA ya eliminan todo mutante de este archivo alcanzable desde fuera. Seis propiedades las igualaron en este archivo, lo que es una constatación sobre un pequeño parser guiado por una regex, no sobre las pruebas de propiedades en general. Ningún cambio de producción ni issue en GA: mantener las ramas defensivas es decisión del mantenedor.

## Por verificar

- Ejecutar el laboratorio test-quality en Linux y macOS, y conectarlo a la CI; hasta ahora solo ha corrido en Windows 11, a mano.
- Ejecutar `Pitch.Flat.TryParse("CB4")` para confirmar que la línea 58 de `PitchParser.cs` es inalcanzable; conciliar las 710 pruebas del informe de Stryker de T con 706 + 6.
- Mutar un segundo archivo de GA, cuyo contrato dependa menos de una regex, antes de sacar conclusiones sobre las pruebas de propiedades allí.
- Fusionar la regla de reparto de papeles en Demerzel ([Demerzel#1127](https://github.com/GuitarAlchemist/Demerzel/pull/1127)); volver a Jev sobre evidencia solo si un repositorio construye un paso donde un modelo juzgue evidencia ([gaia#159](https://github.com/GuitarAlchemist/gaia/issues/159)).
- Confirmar la primera ejecución CI alojada para matrices, paridad y diarios.
- Medir tiempo de autoría antes de afirmar menor coste. No existe ningún valor de referencia, así que la métrica de éxito actual de `learn-evidence-first-course-method` es irrefutable tal como está escrita.
- Leer el cuerpo de las cinco reglas TARS `ga.*`, no solo sus pesos, antes de afirmar que los dos codificados coinciden o divergen.
- Que un mantenedor tríe ga#700, #701 y #702; el agente automático falló en las cinco issues, así que ninguna ha sido juzgada.
- Ejecutar el A/B posterior con modelo fijo antes de afirmar que Jev reduce el coste posterior. La calibración en vivo no llamó a ningún modelo posterior, y n=12 en un corpus y una ejecución no sostiene ninguna cifra general.
- Asociar la red protegida con un seam público Gaia o IX en una revisión exacta, reproducir el testigo inseguro y comparar con una prueba determinista sencilla.
- Elegir un seam hexagonal exacto o rechazar la oportunidad.

## Preguntas abiertas

- ¿Qué métricas predicen que un hallazgo sobrevivirá la integración?
- ¿Deben separarse siempre ownership y autoridad de merge?
- ¿Cuándo revisar un rechazo en vez de retirarlo?
