---
module_id: inf-005-quantization-and-indistinguishable-renders
department: information-theory
course: "Cuantización y renders indistinguibles"
level: intermediate
prerequisites: ["inf-004-information-loss-in-agent-handoffs", "aud-005-pcm-guards-and-format-boundaries"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Cuantización y renders indistinguibles

Un ingeniero recibe archivos PCM16 idénticos y concluye que dos motores de guitarra produjeron las mismas muestras en coma flotante. Esa conclusión elimina una distinción necesaria para el experimento. Esta lección enseña a identificar exactamente qué igualdad sobrevive a la conversión y qué información de origen ya no puede recuperarse.

Lee [INF-004](inf-004-information-loss-in-agent-handoffs.md) sobre pérdida de información en los relevos y [AUD-005](../../audio-engineering/en/aud-005-pcm-guards-and-format-boundaries.md) sobre controles de muestras y límites entre formatos. Aquí se entrega un argumento breve sobre una aplicación determinista de muchos a uno. Utiliza el [paquete de evidencias](../../../../code/streeling/evidence/feedback-projections-2026-10-22/README.md) y la [tarea del estudiante](../../../../code/streeling/evidence/feedback-projections-2026-10-22/learner-task.md). Estado: borrador fuente de IA; quedan pendientes las revisiones humanas del contenido, del idioma, del aprendizaje y de la publicación HTML pública.

## 1. Localizar la aplicación que pierde información

El [análisis de cuantización](../../../../code/streeling/evidence/feedback-projections-2026-10-22/quantization.json) reutiliza los búferes conservados, con hashes verificados, del [experimento de ejecución registrado](../../../../code/streeling/evidence/guitar-runtime-2026-10-22/results.json). Es un análisis nuevo, no un render nuevo. En cada variante se compararon 176400 muestras float32 nativas y WASM. La referencia tiene 2918 muestras brutas distintas; la candidata tiene 2926. Tras la conversión, cada variante tiene 0 muestras PCM16 distintas. Son comparaciones entre nativo y WASM dentro de cada variante, no igualdad entre referencia y candidata.

El [programa del experimento](../../../../code/streeling/guitar-runtime/run.mjs) acepta valores float32 decodificados finitos en `[-1,1]`. Aplica [`Math.round`](https://tc39.es/ecma262/multipage/numbers-and-dates.html#sec-math.round) en [Node.js](https://nodejs.org/en/learn/getting-started/introduction-to-nodejs), después de que [`readFloatLE`](https://nodejs.org/docs/latest-v24.x/api/buffer.html#bufreadfloatleoffset) lea cada valor de origen:

```text
Q(x) = Math.round(x * 32767)
```

Después se serializa como int16 con signo. En la trama 646 de la referencia, con numeración desde cero, el valor nativo `0.000552888261154294` tiene los bytes little-endian `b4ef103a`; el valor WASM `0.0005528881447389722` tiene `b2ef103a`. Ambos producen el código 18. La salida ha borrado una distinción real entre las fuentes.

### Ejercicio 1 — Refutar la igualdad de las fuentes

¿Qué observación refuta «mismo PCM16 implica mismo float32»?

> **Respuesta:** La trama 646 proporciona valores float32 y patrones de bytes distintos con el mismo código 18. Un contraejemplo basta para refutar la implicación universal; no hace falta ninguna afirmación sobre la escucha.

## 2. Interpretar un código como clase de equivalencia

Define `x ~ y` cuando coincidan sus códigos PCM16 serializados. La igualdad de las salidas hace que esta relación sea reflexiva, simétrica y transitiva. Una **fibra** es el conjunto de entradas aceptadas que comparten un código. Observar el código identifica una fibra; normalmente no selecciona uno de sus elementos.

Para aritmética real ideal con empates hacia infinito positivo, la fibra del entero `k` es:

```text
[(k - 0.5) / 32767, (k + 0.5) / 32767) intersect [-1,1]
```

El límite inferior pertenece a la celda; el superior pertenece a la siguiente. Las entradas aceptadas reales son valores float32 procesados mediante aritmética JavaScript. Cerca de un límite, evalúa el codificador exacto en lugar de suponer que todos los umbrales ideales se representan exactamente. `Math.round` resuelve los empates hacia infinito positivo: `Math.round(0.5)` es 1, `Math.round(-1.5)` es -1 y `Math.round(-0.5)` es cero negativo. La serialización convierte el cero negativo y el positivo en los mismos bytes enteros.

El análisis también incluye un **ejemplo construido**, no una muestra de guitarra capturada: `0.25` y `0.2500000298023224` se convierten ambos en 8192. Un decodificador que elige `k / 32767` devuelve un representante, no una prueba de la entrada original.

### Ejercicio 2 — Invertir el ejemplo construido

Con solo el código 8192, ¿puedes elegir de forma única entre las entradas construidas?

> **Respuesta:** No. Ambas pertenecen a su fibra. Una inversa que devuelva cualquiera de ellas falla para la otra. La reconstrucción única exige información adicional de origen o restricciones que permitan distinguirlas.

## 3. Contar el alfabeto del codificador

El dominio aceptado y la escala dan un código mínimo emitido de -32767 y uno máximo de 32767. Al incluir ambos extremos obtenemos `32767 - (-32767) + 1 = 65535` códigos enteros posibles. El formato int16 con signo puede almacenar 65536 códigos, incluido -32768, pero este codificador nunca emite ese código adicional para sus entradas aceptadas.

Este tamaño del alfabeto no es una entropía medida. La entropía requiere un modelo de probabilidad sobre las salidas; los recuentos deterministas de muestras y las colisiones observadas no lo proporcionan. Del mismo modo, 2918 muestras distintas cuentan posiciones en una comparación, no bits de información perdida.

### Ejercicio 3 — Explicar el código que falta

¿Por qué un contenedor de 16 bits no implica 65536 salidas alcanzables por el codificador?

> **Respuesta:** El almacenamiento permite -32768, mientras que `Q(-1)` es -32767. Este codificador solo produce códigos de -32767 a 32767: 65535 códigos. La capacidad del contenedor y la imagen de la aplicación responden a preguntas diferentes.

## 4. Separar error de reconstrucción y distancia entre fuentes

Con aritmética real ideal, reconstruir una fuente como `Q(x) / 32767` da un error absoluto de como máximo `1 / (2 * 32767)`, aproximadamente 0.000015259254737998596. Esa cota de medio paso se refiere a una fuente y a su representante elegido. Dos entradas de la misma fibra interior pueden acercarse a un paso completo, `1 / 32767`, de separación. Por tanto, el medio paso no es una cota general de su distancia mutua.

Los errores máximos medidos de reconstrucción nativa son 0.000015258982790783415 para la referencia y 0.00001525887933261083 para la candidata. Las dos diferencias máximas brutas entre nativo y WASM son 2.9802322387695312e-8. Estas medidas comparan pares de cantidades diferentes. Su pequeño tamaño no garantiza códigos iguales: en el modelo ideal, los valores a lados opuestos de un umbral pueden estar arbitrariamente cerca.

### Ejercicio 4 — Asociar cada error con su pregunta

¿La diferencia bruta máxima mide el error de reconstrucción? ¿La cota de medio paso establece igualdad PCM?

> **Respuesta:** Ninguna de las dos cosas. La diferencia bruta compara las salidas de dos motores; el error de reconstrucción compara una fuente con su representante decodificado. La igualdad PCM requiere comparar las salidas codificadas. La posición respecto al umbral importa tanto como la distancia.

## 5. Conservar el relevo más sólido que respaldan las pruebas

El análisis verifica los hashes de las cargas útiles PCM16 completas frente a la carga útil del WAV versionado para cada variante. Junto con las comparaciones directas de códigos, esto respalda la igualdad tras esta conversión concreta en todas las tramas conservadas dentro de cada variante. Los hashes brutos difieren. Conservar esos búferes preserva distinciones que el WAV no puede recuperar.

Escribe una nota de revisión que identifique codificador, dominio, variante, número de tramas y evidencias. Este experimento fijo y sin conexión no establece equivalencia perceptiva o tímbrica, un modelo de ruido, SNR, entropía, rendimiento, comportamiento del navegador ni reproducibilidad en todas las plataformas. En este análisis no hubo ensayo con estudiantes ni prueba de escucha.

### Ejercicio 5 — Redactar la afirmación válida

Sustituye «los motores son idénticos» por un relevo verificable.

> **Respuesta:** Para 176400 tramas conservadas por variante, nativo y WASM difieren en 2918 posiciones brutas de la referencia y 2926 de la candidata, pero tienen 0 diferencias de código PCM16 bajo `Q(x) = Math.round(x * 32767)` y serialización int16 con signo. Cada carga útil completa coincide con la de su WAV versionado. Esto establece igualdad tras la conversión para estas entradas; la reconstrucción float32 única y la equivalencia auditiva siguen sin respaldo. Presenta este paquete del estudiante elaborado con las fuentes para las revisiones pendientes.
