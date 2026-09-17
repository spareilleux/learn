---
title: "1. El problema: lo que vale un «hecho»"
description: Por qué el mensaje de fin de un agente es prosa y no evidencia, los cuatro ejes independientes que Gaia se niega a reducir a un solo número, y la doctrina que se deriva de ello — Design It Twice, balas trazadoras, la reversibilidad como propiedad tipada y la verificación independiente como transición aparte. Con la lista de atajos que Gaia nombra y rechaza.
sidebar:
  order: 1
---

Un agente termina y dice: *«He implementado la ruta de cancelación y he añadido una prueba. Pasan las 2 075 pruebas.»*

Esa frase contiene una afirmación comprobable y tres sin comprobar. La comprobable es el número. Las no comprobadas son que existe una ruta de cancelación, que una prueba la cubre, y que la batería de pruebas llegó a ejecutarse — por este agente, en este árbol, después de este cambio. Puedes ir a comprobarlas a mano, y para un solo cambio lo harás. La pregunta de esta lección es qué ocurre cuando hay cuarenta frases así al día, de cuatro sesiones que no estabas mirando.

## Los marcadores de fin no son evidencia

La doctrina de ingeniería de Gaia tiene una lista titulada **Rejected shortcuts**, es decir, atajos rechazados. Dos de sus entradas resumen todo el problema, cada una en una línea:

> equiparar la actividad, el consumo de tokens, el tiempo transcurrido o un marcador de fin con el progreso;
>
> aceptar un informe, un prototipo, una prueba unitaria en verde o una publicación en GitHub como integración efectiva.

Ambas describen cosas que *parecen* evidencia y no lo son. Un marcador de fin es un token que el modelo emitió porque la conversación llegó a su final. El tiempo transcurrido mide cuánto habló un modelo. Una prueba unitaria en verde demuestra que la unidad hace lo que su autor creía — que es justamente la creencia que se está revisando. Y una pull request fusionada demuestra que alguien pulsó un botón.

El principio de ingeniería que hay debajo es **ENG-08**:

> El autor de un cambio no puede aprobarlo. La verificación se vincula a entradas, digests, pruebas, controles y alcance exactos. Un marcador es evidencia de que el trabajo se detuvo, no evidencia de que sus afirmaciones sean ciertas.

Lee despacio la última frase: *evidencia de que el trabajo se detuvo*. Eso es realmente todo lo que te dice un marcador de fin, y merece la pena tenerlo — una sesión que nunca vuelve es un problema distinto de una que volvió con un resultado erróneo. Simplemente no es lo que la gente cree leer en él.

### El equivalente en C#

Ya rechazas esta sustitución en el código que escribes. Piensa en un método que devuelve `Task<bool>` para «se realizó el pago», cuya implementación captura todas las excepciones y devuelve `true` porque la petición se envió. Nadie lo aceptaría. «Envié la petición» y «el pago se liquidó» son hechos distintos, y el tipo que los confunde es el error.

El bus de Gaia aplica exactamente esa disciplina a las palabras que los agentes usan unos sobre otros. `send` no devuelve «enviado». Devuelve:

```text
accepted-for-delivery; not read, not agreed, not completed
```

La cadena es larga a propósito. Es un tipo de retorno que se niega a que lo lean mal.

## Los cuatro ejes

La segunda idea es que las propiedades interesantes de un artefacto son independientes, y que aplastarlas en una sola puntuación destruye la información que necesitabas. De la doctrina:

> La frescura, la calidad, la aceptación y la autoridad siguen siendo ejes independientes. Un artefacto fresco puede ser erróneo; un artefacto de alta calidad puede estar obsoleto; un artefacto aceptado puede no conceder ninguna autoridad.

| Eje | La pregunta que responde | La forma reducida que ya has visto |
|---|---|---|
| Frescura | ¿se deriva de las entradas actuales? | «actualizado hace 2 días» |
| Calidad | ¿hace lo que afirma, bajo prueba? | «build passing» |
| Aceptación | ¿lo ha aceptado un actor independiente? | «aprobado» |
| Autoridad | ¿puede ejecutarse un efecto por su causa? | «aprobado», otra vez |

Los dos últimos comparten palabra en todas las herramientas de revisión de código del mercado, y esa es la reducción que más duele. Una revisión aprobatoria significa que una persona leyó un diff. No significa que el diff pueda desplegarse en producción a las 17:55 de un viernes. En un sistema donde los agentes pueden actuar, tratar ambas cosas como un solo hecho es la forma en que un agente que recibió un amable mensaje de revisión concluye que puede hacer push.

Gaia las mantiene separadas por estructura y no por convención: la aceptación es un veredicto registrado en un recibo, y la autoridad es una concesión emitida aparte, de un solo uso y confirmada por una persona, que la lección 4 examina.

### La incertidumbre tampoco es un solo número

La mitad científica de la doctrina dice lo mismo sobre la confianza, en **SCI-05**:

> Informa de las unidades, la nulabilidad, la incertidumbre epistémica y aleatoria cuando proceda, el tamaño de la muestra, la calibración o la cobertura, la sensibilidad a los supuestos y las insuficiencias conocidas del modelo. No comprimas el conflicto, la ignorancia, el riesgo, la frescura y la confianza en un solo escalar.

Si alguna vez has visto un panel de agentes con una insignia de «confianza: 87 %», este principio es la objeción a ella. El conflicto (dos fuentes discrepan) y la ignorancia (no existe ninguna fuente) son estados distintos con remedios distintos, y un solo porcentaje no puede distinguirlos. Cuando falta la procedencia, la respuesta de Gaia es el valor `UNKNOWN`, nunca un éxito inferido.

## Lo que se deriva de ello: la doctrina

En cuanto decides que solo lo que puede reproducirse cuenta como evidencia, un puñado de reglas de ingeniería deja de ser cuestión de gusto y pasa a ser obligado. Gaia enuncia nueve; cuatro importan para leer el resto de este curso.

### ENG-02 — Design It Twice, solo en las juntas que soportan carga

Antes de crear o cambiar una interfaz pública, una junta entre módulos, un esquema persistente, una frontera de autoridad o un contrato entre repositorios, produce **al menos dos diseños realmente distintos** — normalmente tres para una puerta de un solo sentido — variando deliberadamente el objetivo de optimización, y fija el elegido en un Decision Receipt que nombre lo que se descartó.

El procedimiento es el [Design It Twice de Matt Pocock](https://github.com/mattpocock/skills/blob/c0d69015e0cc8b66715beb3f93f9e53256e20f30/skills/engineering/codebase-design/DESIGN-IT-TWICE.md), es decir, diseñarlo dos veces, que a su vez deriva del método de diseño de módulos de John Ousterhout. Gaia añade una advertencia que importa cuando un agente genera las alternativas:

> La generación de alternativas es orientativa. Varias variantes surgidas de un mismo contexto no son una aprobación independiente, y el voto de la mayoría no establece la corrección.

Tres diseños de un mismo modelo en una misma conversación son tres muestras de una misma distribución. Parecen un comité y no lo son. Puedes ver el principio aplicado en el propio documento de diseño de la fábrica, que registra tres interfaces candidatas — un script monolítico, un ejecutor de comandos arbitrarios y un núcleo neutral respecto al proveedor con perfiles de proveedor cerrados — y explica por qué se eligió la tercera.

Y, lo que es crucial, ENG-02 también dice cuándo *no* hacerlo: «No se exige para cambios triviales, locales y que preservan el comportamiento». Una doctrina que exige tres diseños para corregir una errata es una doctrina que la gente acaba esquivando.

### ENG-05 — La bala trazadora de extremo a extremo más pequeña

> Para un comportamiento no trivial, construye primero la porción vertical más pequeña que cruce todas las juntas necesarias y pueda fallar honestamente. Una prueba unitaria en verde, una capa aislada, un documento generado o un prototipo local no son, por sí solos, integración.

«Pueda fallar honestamente» es la expresión que soporta la carga. Una demo preparada para tener éxito cruza las mismas juntas y no demuestra nada, que es la misma objeción que **SCI-02** plantea contra los experimentos confirmatorios: *una demostración que solo puede tener éxito no es un experimento.*

### ENG-07 — La reversibilidad es una propiedad tipada

Cada cambio se clasifica como **libremente reversible**, **compensable**, **migrable** o **de un solo sentido**, indicando la ruta de vuelta atrás y la evidencia que la desencadena. Las puertas de un solo sentido requieren autoridad humana explícita y una revisión independiente más estricta.

Es el mismo instinto que una política de migraciones de base de datos — ya tratas `DROP COLUMN` de forma distinta a `ADD INDEX` — aplicado a cada cambio, incluidos los que un agente propone a las 3 de la madrugada.

### ENG-06 — Transiciones deterministas, idempotentes y reproducibles

> Repetir la misma petición aceptada debe producir el mismo resultado o devolver el resultado anterior sin duplicar efectos. Reproducir a partir de evidencia inmutable debe reconstruir el estado material de decisión.

La lección 3 es este principio hecho concreto: un registro que puedes reproducir dos veces obteniendo el mismo estado, y un verificador que comprueba exactamente eso.

## Los artefactos, y la cláusula antiburocracia

Una doctrina así tiene un modo de fallo evidente: convertirse en un formulario que rellenar. La tabla de artefactos obligatorios del grafo de trabajo de Gaia va precedida de una frase que la mantiene honesta — *«Se exige el conjunto aplicable más pequeño; el trabajo trivial no debe fabricar papeleo.»*

| Artefacto | Puerta a la que informa |
|---|---|
| Mission Brief | permiso para diseñar |
| Design Alternatives | elección de la junta |
| Decision Receipt | permiso para implementar |
| Experiment Plan | permiso para medir |
| Evidence Manifest | reproducibilidad |
| Transition Receipt | aceptación del estado |
| Independent Review | promoción |

Lee de arriba abajo la columna de la derecha y aparece la forma: cada artefacto compra exactamente un permiso. Nada de la columna izquierda *es* autoridad; cada uno es la condición previa para poder pedir la siguiente puerta. Es la misma separación que traza la tabla de vocabulario de la [misión](../) entre una reclamación, una intención y un efecto.

## Reproducibilidad frente a replicación

Merece la pena llevar a la ingeniería corriente una distinción de la mitad científica, porque en todas partes se usan ambas palabras como sinónimos. **SCI-04**:

- **Reproducibilidad** — un actor independiente obtiene resultados coherentes usando *las mismas* entradas, código, métodos y condiciones.
- **Replicación** — la afirmación se pone a prueba con evidencia *nueva* o con condiciones recogidas de forma independiente.

Gaia exige reproducibilidad antes de la promoción, y replicación o evidencia reservada para las afirmaciones que pretenden generalizarse. En términos de agentes: volver a ejecutar el mismo prompt con la misma semilla y obtener el mismo diff es reproducibilidad, y es barato y necesario. No dice nada sobre si el enfoque funciona en el siguiente repositorio. La lección 5 muestra dónde se lo aplica Gaia a sí misma — la cifra de cuatro carriles es reproducible y explícitamente no replicada con carriles reales de Claude y Codex, y el documento lo dice.

## Puntos clave

- Un marcador de fin es evidencia de que el trabajo se detuvo, no de que sus afirmaciones sean ciertas, y el autor de un cambio no puede aprobarlo (ENG-08).
- Frescura, calidad, aceptación y autoridad son ejes independientes: una revisión que aprueba es aceptación, no permiso para desplegar.
- La incertidumbre tampoco es un solo número. El conflicto y la ignorancia son estados distintos, y una procedencia que falta es `UNKNOWN`, nunca un éxito inferido.
- De ahí sale la doctrina: varios diseños solo en las costuras que soportan carga, la bala trazadora más pequeña capaz de fallar honestamente, una clase de reversibilidad para cada cambio y transiciones que se reproducen hasta el mismo estado, sin fabricar papeleo para el trabajo trivial.
- La reproducibilidad, las mismas entradas dando el mismo resultado, se exige antes de la promoción; una afirmación que pretende generalizarse necesita replicación, con evidencia nueva.

## Ejercicios

1. Un compañero propone un recuadro para el panel: «Rendimiento de los agentes: 14 tareas por hora, ▲ 30 % esta semana». Nombra tres de los atajos rechazados por Gaia que pisa, y di qué debería medir el recuadro en su lugar.

<details>
<summary>Solución</summary>

Equipara la actividad y el tiempo transcurrido con el progreso; acepta los marcadores de fin como progreso, ya que «tareas» significa aquí casi con seguridad «sesiones que terminaron»; y comprime la frescura, la calidad y la aceptación en un solo escalar al que luego pone una flecha de tendencia. Puede ser también una comparación dentro de la muestra, sin línea de base (**SCI-06**).

Lo que Gaia mide en su lugar, según el mapa de arquitectura: *«Las métricas de entrega miden transiciones aceptadas y recibos, no tokens, actividad de los carriles ni marcadores de fin en prosa.»* Así que el recuadro contaría las transiciones que llegaron a un estado terminal con un recibo, y necesitaría también el denominador — las transiciones rechazadas y sin resolver — porque 14 aceptadas de 15 y 14 de 60 son semanas distintas.

</details>

2. Estás añadiendo un método a una clase auxiliar interna: renombras un campo privado y actualizas sus tres llamadas en el mismo archivo. ¿Se aplica ENG-02? Ahora cambias la forma del JSON que esa clase escribe en disco. ¿Se aplica entonces?

<details>
<summary>Solución</summary>

No, y luego sí. El primer cambio es trivial, local y preserva el comportamiento — ENG-02 nombra exactamente ese caso como fuera de su alcance, y fabricar dos diseños para él es el papeleo contra el que advierte la doctrina. El segundo cambia un esquema persistente, que está en la lista explícita de desencadenantes de ENG-02, porque todo lo ya escrito con la forma antigua debe seguir siendo legible o debe migrarse. También es ahí donde entra ENG-07: un cambio de esquema es, en el mejor de los casos, migrable, no libremente reversible, así que el diseño tiene que nombrar la ruta de migración o de compensación antes de implementarse.

</details>

3. Un agente informa: «No he podido acceder a la API de GitHub, así que he supuesto que la pull request se creó y he marcado la operación como completada». ¿Qué principio viola, y cuál debería haber sido el estado?

<details>
<summary>Solución</summary>

**SCI-03** — *«Una procedencia ausente o no verificable produce `UNKNOWN`, no un éxito inferido.»* El mapa de arquitectura da la forma operativa de la misma regla: *«La ambigüedad del transporte se normaliza como una observación sin resolver, no como un éxito o un rechazo adivinados a partir de prosa»*, y *«Los efectos remotos ambiguos siguen sin ser terminales hasta que se concilian; el tiempo transcurrido y los reintentos no pueden fabricar la verdad.»*

El estado correcto es `EFFECT_AMBIGUOUS`: no terminal, conservado, y resuelto solo volviendo a leer más tarde al proveedor que tiene autoridad. Fíjate en que la respuesta errónea aquí no es solo «completada» — «fallida» es igual de errónea, y por el mismo motivo. Es muy posible que el efecto se haya producido.

</details>

4. La doctrina de Gaia dice que el autor de un cambio no puede aprobarlo. Un agente genera tres diseños, elige uno, lo implementa y luego lanza una segunda sesión con un prompt de revisor que lo aprueba. ¿Qué parte de ENG-08 se cumple y cuál no?

<details>
<summary>Solución</summary>

El *número* de sesiones no cumple nada de ENG-08. El principio exige que la verificación «se vincule a entradas, digests, pruebas, controles y alcance exactos» — así que un revisor al que se le da la identidad exacta del candidato, un árbol fijado y los falsadores declarados está verificando, y uno al que se le da un resumen amable del cambio no.

Los tres diseños quedan descalificados por otra vía, la advertencia de ENG-02: las variantes de un mismo contexto no son una aprobación independiente. Y la lección 4 muestra la parte estructural de la respuesta — la fábrica de Gaia fija el árbol completo del candidato antes de la revisión y se niega a continuar si algo cambió durante ella, de modo que «el revisor lo aprobó» es una afirmación sobre un árbol concreto y no sobre una conversación.

</details>

## Fuentes

- Gaia: [principios de ingeniería e investigación](https://github.com/GuitarAlchemist/gaia/blob/d68e90099ae2a6fbbec9d428617bfcd02095aac0/docs/engineering-and-research-principles.md), [`ARCHITECTURE.md`](https://github.com/GuitarAlchemist/gaia/blob/d68e90099ae2a6fbbec9d428617bfcd02095aac0/ARCHITECTURE.md), [diseño del agente de la fábrica](https://github.com/GuitarAlchemist/gaia/blob/d68e90099ae2a6fbbec9d428617bfcd02095aac0/docs/factory-agent-design.md)
- Matt Pocock, [Design It Twice](https://github.com/mattpocock/skills/blob/c0d69015e0cc8b66715beb3f93f9e53256e20f30/skills/engineering/codebase-design/DESIGN-IT-TWICE.md)
- John R. Platt, [Strong Inference](https://doi.org/10.1126/science.146.3642.347) — el origen de la idea de «prueba discriminante» de SCI-02
- National Academies, [Reproducibility and Replicability in Science](https://doi.org/10.17226/25303) — las definiciones que usa SCI-04
- W3C, [PROV-DM: The PROV Data Model](https://www.w3.org/TR/prov-dm/) — el vocabulario de procedencia detrás de SCI-03
