---
module_id: aud-008-measure-a-filter-with-paired-input-and-output
department: audio-engineering
course: "Medir un filtro con entrada y salida emparejadas"
level: intermediate
prerequisites: ["aud-006-calibrate-spectral-amplitudes", "cs-013-preserve-spectral-axes-and-units", "gas-007-distinguish-body-poles-from-string-partials"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Medir un filtro con entrada y salida emparejadas

> **Alcance del borrador.** Cálculos didácticos de señales periódicas e inspección de código fijado a una revisión. Quedan pendientes las revisiones humanas técnica, lingüística, musical y de estudiantes, así como la verificación del HTML del curso desplegado. No se capturaron una nueva grabación, un renderizado del motor ni un flujo de [ComfyUI](https://docs.comfy.org/).

## La pregunta del proyecto

Un agente duplica la amplitud de un parcial renderizado y anuncia un mejor filtro de cuerpo. ¿Cambió el filtro o su entrada? [GAS-007](../../guitar-acoustics/en/gas-007-distinguish-body-poles-from-string-partials.md) identifica un límite concreto de entrada y salida anterior a la reverberación. [AUD-006](aud-006-calibrate-spectral-amplitudes.md) trata la calibración de amplitudes. Aquí conservamos juntas excitación y respuesta.

## 1. Declarar el experimento antes de dividir espectros

Usa una respuesta impulsional finita didáctica deliberadamente pequeña, sin relación con ninguna afirmación de realismo medido de guitarra:

```text
h = [3/4, 1/4]
y[n] = (3/4)*x[n] + (1/4)*x[n-1]
H(omega) = 3/4 + (1/4)*exp(-i*omega)
```

Para el siguiente experimento, x es periódica con periodo N = 8; x[-1] significa x[7]. Observa un periodo completo en régimen estacionario. La [convención de DFT](https://www.dsprelated.com/freebooks/mdft/DFT_Definition.html) es la transformada directa sin escalar con exponencial negativa. En el índice de frecuencia k = 2, omega = pi/2, así que H = 0.75 - 0.25i y su módulo es aproximadamente 0.790569415.

Este ejemplo no usa una ventana Hann ni un arranque truncado. [CS-013](../../computer-science/en/cs-013-preserve-spectral-axes-and-units.md) explica los ejes y los metadatos de segmentación en tramas necesarios fuera de este pequeño ejemplo.

### Ejercicio 1 — Identificar las condiciones de medición

¿Por qué importa x[-1] = x[7]? ¿Qué hipótesis permiten Y[k] = H[k]X[k] en los índices de frecuencia seleccionados?

> **Respuesta:** Proporciona la muestra anterior de la misma entrada periódica estacionaria. El sistema es el filtro lineal e invariante en el tiempo declarado y el registro contiene un periodo completo con convenciones de transformada coincidentes. Es filtrado circular de una entrada periódica, no las primeras ocho muestras de una convolución lineal inicializada a cero. Los registros finitos con otros límites necesitan tratamiento separado.

## 2. Una salida mayor puede proceder por completo de una entrada mayor

El [caso de prueba emparejado](../../../../code/streeling/evidence/filter-phase-2026-10-22/paired-transfer.json) usa cosenos en k = 2 con amplitudes de entrada 0.25 y 0.50:

| Amplitud del coseno de entrada | X[2] | Y[2] | Amplitud del coseno de salida, aproximadamente |
| --- | --- | --- | --- |
| 0.25 | 1 | 0.75 - 0.25i | 0.197642354 |
| 0.50 | 2 | 1.50 - 0.50i | 0.395284708 |

Dividir los coeficientes complejos emparejados da la misma respuesta del filtro en ambos ensayos. Dividir módulos de salida entre ensayos da 2, lo que describe escalado de salida, no ganancia de filtro duplicada. No se miden sonoridad ni preferencia.

### Ejercicio 2 — Resolver la aparente mejora

Calcula Y[2]/X[2] en ambos ensayos. ¿Establece la razón de amplitudes de salida 2 un cambio de H?

> **Respuesta:** Ambas razones son 0.75 - 0.25i, con módulo aproximado 0.790569415. El filtro no cambia. Duplicar la excitación duplica la salida de este filtro lineal; comparar solo la salida confunde intensidad de entrada con respuesta.

## 3. Una frecuencia no excitada no es un rechazo medido

En k = 1, el caso de coseno tiene coeficientes de entrada y salida analíticamente cero. Pueden quedar diminutos residuos de DFT en coma flotante en un cálculo numérico. Su razón no establece la respuesta. De hecho, la respuesta teórica del mismo filtro en esa frecuencia es no nula.

La situación también es frágil cerca de cero. Sea X = 0.000001 en k = 2 y añade un coeficiente didáctico de ruido de salida de 0.01. Entonces la razón aparente pasa a ser 10000.75 - 0.25i aunque el verdadero H siga siendo 0.75 - 0.25i. Es un ejemplo de sensibilidad, no un suelo de ruido medido ni un umbral universal de rechazo.

### Ejercicio 3 — Rechazar una razón sin respaldo

Un agente registra X[1] = 0 e Y[1] = 0 y después almacena ganancia de filtro 0. ¿Qué debería almacenar en su lugar? Explica cómo el ejemplo de excitación débil cambia su plan de adquisición.

> **Respuesta:** Guarda la razón como indefinida o no medida con motivo de excitación insuficiente, no como ganancia cero. Usa excitación adecuada y una política explícita de ruido y condicionamiento para las frecuencias de interés. El término de ruido 0.01 dividido entre entrada 0.000001 añade 10000 a la estimación falsa. Un umbral debe derivarse de las condiciones reales de medición.

## 4. Truncar puede cambiar la respuesta incluso con el filtro correcto

Para un control separado, usa amplitud 0.25 y fase inicial pi/4, aún en k = 2. Inicia ahora el filtro con entrada anterior cero y conserva solo N = 8 muestras de salida. La convolución lineal finita completa tiene 9 muestras; se ha descartado la última. Dividir los espectros truncados de ocho puntos da 0.71875 - 0.21875i, no 0.75 - 0.25i.

### Ejercicio 4 — Diagnosticar el desajuste de límites

¿Demuestra la razón truncada que cambió la implementación del filtro? Da dos formas válidas de formular una nueva comparación.

> **Respuesta:** No. El control cambió el límite y descartó una cola no nula. Adquiere un registro declarado de régimen periódico estacionario o conserva la convolución finita completa y rellena con ceros entrada y salida hasta una longitud común de transformada suficiente para convolución lineal. Mantén coherentes alineación de muestras y escalado de transformada. Para respuestas recursivas largas, define tolerancias de estabilización y cola; un recorte corto arbitrario no basta.

## 5. Conservar la representación que requiere la pregunta

En el commit fijado de IX `bd1336b7c4045e427dcdbe80b102790e45da5ce1`, [stft](https://github.com/GuitarAlchemist/ix/blob/bd1336b7c4045e427dcdbe80b102790e45da5ce1/crates/ix-signal/src/spectral.rs#L7-L30) devuelve espectros complejos. La posterior [proyección de espectrograma](https://github.com/GuitarAlchemist/ix/blob/bd1336b7c4045e427dcdbe80b102790e45da5ce1/crates/ix-signal/src/spectral.rs#L32-L54) devuelve módulos o sus valores en decibelios. Esa proyección descarta la fase de cada coeficiente.

Esta distinción del código no garantiza que las razones de tramas STFT transitorias y enventanadas arbitrarias sean funciones de transferencia exactas. Los límites de ventana, memoria del filtro no observada, no linealidades y variación temporal siguen importando. Una estimación estadística de transferencia para datos ruidosos necesita un estimador declarado e hipótesis adicionales al ejemplo sin ruido de aquí.

### Ejercicio 5 — Especificar el siguiente artefacto capturado

Para una prueba propuesta de filtro de cuerpo en GA o ComfyUI, enumera qué conservar para que otro agente distinga cambios de ganancia, fase y excitación. ¿Qué etapa del código debería aislarse y qué sigue sin probarse?

> **Respuesta:** Conserva muestras de entrada y salida emparejadas o sus transformadas complejas coincidentes, frecuencia de muestreo, tiempos y alineación, longitudes de registro y transformada, convenciones de ventana y escala, excitación, parámetros del filtro, revisión del código y decisiones de ruido y estabilización. Aísla el límite de suma normalizada de cuerdas a salida seca previa a reverberación identificado por GAS-007; reverberación y recorte posteriores necesitan ensayos separados. Las salidas de solo módulo pueden respaldar una pregunta acotada de módulo, pero no aportan la fase compleja ausente. Este curso no implementó ninguna captura ni adaptador. [INF-008](../../information-theory/en/inf-008-keep-phase-when-waveform-identity-matters.md) ofrece un contraejemplo exacto de fase.

## Tarea del estudiante con acceso a las fuentes

Escribe un plan de adquisición que pueda refutar «mayor salida significa mayor ganancia del filtro». Incluye ambos ensayos emparejados, un rechazo de índice de frecuencia no excitado, el cálculo de excitación débil, un control de desajuste de límites y la representación necesaria para fase. Registra ayuda y condiciones sin resolver. La [rúbrica de revisión](../../../../code/streeling/evidence/filter-phase-2026-10-22/reviewer-rubric.json) contiene criterios preparados, no resultados de estudiantes.

El [comprobante de fuentes](../../../../code/streeling/evidence/filter-phase-2026-10-22/primary-readback.json) vincula los archivos seleccionados. La aritmética didáctica no establece una respuesta real de guitarra, un grafo de audio funcional, una mejora del motor ni un resultado perceptivo.
