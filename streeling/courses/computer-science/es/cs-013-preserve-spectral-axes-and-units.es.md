---
module_id: cs-013-preserve-spectral-axes-and-units
department: computer-science
course: "Preservar ejes y unidades al componer salidas espectrales"
level: intermediate
prerequisites: ["cs-012-native-and-wasm-render-boundaries", "aud-006-calibrate-spectral-amplitudes"]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Preservar ejes y unidades al componer salidas espectrales

> **Alcance del borrador.** Análisis de interfaz apoyado en el código fuente y conjuntos de datos numéricos medidos. Quedan pendientes la revisión técnica humana, la revisión por personas que dominen el idioma, los intentos de los estudiantes y la verificación del HTML público del curso. No se ejecutó ni se introdujo ningún binario de IX, nuevo nodo de ComfyUI ni esquema de transferencia de producción.

## La pregunta del proyecto

Un agente pasa una matriz espectral de IX a un nodo de grafo o a una visualización. El receptor comprueba el número total de valores, dibuja una imagen plausible e informa de un éxito. ¿Qué información podría seguir siendo incorrecta? La composición necesita las coordenadas y el significado de los valores, además de su tamaño de almacenamiento. Esta lección examina esa interfaz; [CS-012](cs-012-native-and-wasm-render-boundaries.md) aborda los límites entre renderizados nativos y WASM.

El [gestor de espectrogramas de IX en la revisión fijada](https://github.com/GuitarAlchemist/ix/blob/bd1336b7c4045e427dcdbe80b102790e45da5ce1/crates/ix-agent/src/handlers.rs#L1143-L1189) devuelve `spectrogram`, `n_frames`, `n_bins`, `window_size`, `hop_size` y `db`. Sus datos no incluyen una frecuencia de muestreo ni arreglos de los ejes temporal y frecuencial. El [bucle de tramas del núcleo](https://github.com/GuitarAlchemist/ix/blob/bd1336b7c4045e427dcdbe80b102790e45da5ce1/crates/ix-signal/src/spectral.rs#L6-L54) utiliza tramas temporales como filas, índices frecuenciales como columnas y solo ventanas completas. El texto del código fuente respalda esas afirmaciones, no una respuesta de servicio en directo.

El [conjunto de datos de coordenadas](../../../../code/streeling/evidence/spectral-views-2026-10-22/coordinates.json) reproduce ese encuadre sobre dos WAV conservados mediante un [análisis temporal con NumPy](https://numpy.org/doc/stable/reference/generated/numpy.fft.rfft.html). Su objeto `advisory_handoff` es un ejemplo didáctico para criticar, no un nuevo contrato del ecosistema. Recuperará coordenadas, pondrá de manifiesto un error de paso de almacenamiento e identificará el contexto que el receptor debe obtener de un llamador de confianza.

## 1. Derivar la forma a partir de la regla de encuadre

Para una longitud de señal de 176400, ventana de 2048 y salto de 512, el número de tramas completas es `1 + floor((176400-2048)/512) = 341`. Una transformada real unilateral tiene `2048/2 + 1 = 1025` índices frecuenciales. Por tanto, la matriz organizada por tramas contiene 349525 valores. La última trama comienza en la muestra 174080 y termina en la muestra exclusiva 176128, dejando 272 muestras fuera de las tramas completas.

Esta cola es consecuencia de la regla indicada. No demuestra que el decodificador haya perdido muestras ni permite afirmar que la visualización analiza todas las muestras del archivo original. El relleno y el procesamiento de ventanas parciales son políticas posibles, pero adoptar cualquiera de ellas modificaría este experimento.

### Ejercicio 1: recuperar la forma y la cola

Calcule la forma de la matriz, el total de celdas, los límites de la última trama y la cola sin encuadrar a partir de la entrada indicada. ¿Rellenar la última trama mantendría la misma política de análisis?

> **Respuesta:** La forma es de 341 por 1025, con `341*1025 = 349525` valores. El último inicio es `340*512 = 174080`; el final exclusivo es `174080+2048 = 176128`. La cola es de `176400-176128 = 272` muestras. El relleno introduciría otra política declarada, por lo que sus salidas no deben presentarse como este resultado de tramas completas.

## 2. Asociar el tiempo a un punto declarado de la ventana

Este conjunto de datos etiqueta el inicio de trama como `t[j] = j*512/44100` segundos y la frecuencia del índice como `f[k] = k*44100/2048` hercios. Una ventana abarca aproximadamente 0.046440 segundos; el salto es de aproximadamente 0.011610 segundos. Tanto las etiquetas de inicio de trama como las de centro de ventana son convenciones posibles, pero cambiar silenciosamente entre ellas desplaza un evento mostrado.

El gráfico adjunto dibuja cada columna sobre una celda de visualización del ancho de un salto. Esa celda no describe todas las muestras utilizadas por la transformada: una trama utiliza 2048 muestras aunque las columnas avancen 512 muestras. La última celda de visualización termina cerca de 3.959002 segundos; la extensión de muestras de la última trama termina cerca de 3.993832 segundos. Distinga esas extensiones al comparar un marcador de ataque con la imagen.

### Ejercicio 2: decodificar una celda

Para la trama 50 y el índice frecuencial 32, indique el tiempo de inicio de trama y la frecuencia con las fórmulas declaradas. ¿La columna del ancho de un salto significa que solo contribuyeron 512 muestras? ¿Qué contexto falta si el receptor tiene la matriz y los valores de ventana y salto, pero no la frecuencia de muestreo?

> **Respuesta:** El tiempo de inicio es `50*512/44100`, aproximadamente 0.580499 segundos; la frecuencia es `32*44100/2048 = 689.0625` Hz. Cada transformada completa sigue utilizando 2048 muestras. Sin la frecuencia de muestreo, el receptor puede conservar coordenadas de índices de muestra e índices frecuenciales, pero no puede asignar estos valores absolutos en segundos y hercios.

## 3. Probar la orientación con un centinela no simétrico

El pequeño conjunto de datos define tres filas de tramas y cinco columnas de índices frecuenciales, con `value = 100*frame + bin`. Es deliberadamente no cuadrado para que una forma transpuesta sea visiblemente diferente. En un búfer plano almacenado por filas, el elemento de la trama 2, índice 4, tiene el desplazamiento `2*5+4 = 14` y el valor 204. Usar por error un paso de almacenamiento de 3 lee en cambio el desplazamiento 10 y el valor 200. Ambos búferes pueden seguir conteniendo el mismo número total de valores.

Las bibliotecas de gráficos suelen esperar una imagen de frecuencia por tiempo. En ese caso, transponga la matriz de trama por índice para la visualización y asocie sus ejes en consecuencia. No cambie el orden de los ejes del registro fuente solo para ajustarlo a una llamada de trazado. Comprobar la forma, una celda y las coordenadas aborda fallos diferentes.

### Ejercicio 3: rechazar una comprobación de tamaño satisfactoria

Un receptor tiene 15 valores y lee la trama 2, índice 4, con un paso de almacenamiento de 3. Su autor afirma que comprobar el número de celdas demuestra la corrección. Calcule los desplazamientos y valores correctos e incorrectos y proponga una comprobación más sólida.

> **Respuesta:** El desplazamiento correcto es `2*5+4 = 14`, valor 204. El incorrecto es `2*3+4 = 10`, valor 200. El total de 15 no permite distinguir las disposiciones. Exija una forma de 3 por 5, orden de ejes trama y después índice frecuencial, la convención declarada de almacenamiento por filas y el resultado de la celda centinela, seguidos de una comprobación de coordenadas reales.

## 4. Preservar el significado de los valores

La opción `db` de IX distingue las magnitudes brutas de su conversión logarítmica; no las convierte en una unidad física calibrada. [AUD-006](../../audio-engineering/en/aud-006-calibrate-spectral-amplitudes.md) aplica en cambio un estimador explícito de amplitud corregido por la ganancia coherente de la ventana. Una visualización que reciba esa matriz derivada debe conocer la magnitud recibida, la ventana utilizada, cómo se escalaron los extremos, la referencia de dB si existe y cualquier suelo de visualización.

La propuesta de transferencia vincula un hash del WAV fuente, frecuencia de muestreo, forma, ejes ordenados, referencia temporal de trama, ventana y salto, fórmula de ventana, estimador de amplitud y referencia de visualización. Estos campos expresan la información que necesita este ejemplo. No se han ratificado como esquema ni implementado en un puente IX/ComfyUI. Una integración real necesitaría validación y comportamiento ante fallos en su propio límite; no suponga que un registro propuesto ya los proporciona.

### Ejercicio 4: reparar una transferencia incompleta

Un agente envía una matriz logarítmica y escribe únicamente «349525 celdas; dB; éxito». Enumere la información que falta para reproducir las coordenadas y la interpretación de valores de esta lección. ¿Puede llamar a la matriz una respuesta observada de IX?

> **Respuesta:** Exija identidad de la fuente y convención de decodificación, forma de 341 por 1025, orden de ejes trama/índice frecuencial y convención de almacenamiento, frecuencia de muestreo de 44100 Hz, ventana de 2048, salto de 512, tiempo de inicio de trama, fórmula de ventana, estimador de valores, tratamiento de extremos, referencia de dB y suelo. Los datos conservados se calcularon mediante un análisis numérico temporal siguiendo ecuaciones del código fuente en la revisión fijada, por lo que no deben reetiquetarse como respuesta de un binario IX ejecutado.

## 5. Hacer que un límite de composición rechace la ambigüedad

En un flujo de trabajo de agentes, una imagen plausible aporta pocas pruebas de una transferencia correcta. Antes de comparar candidatos, valide las coordenadas y los supuestos sobre las magnitudes. Cuando falte una frecuencia de muestreo o referencia de valores requerida, devuelva el requisito faltante al productor o conserve explícitamente datos solo en índices. Una unidad supuesta se propaga silenciosamente a todos los juicios posteriores.

### Ejercicio 5: elegir la siguiente acción

Un agente posterior quiere clasificar candidatos de guitarra según una característica espectral mostrada, pero los datos carecen de frecuencia de muestreo y referencia de calibración. ¿Qué puede conservar de forma segura, qué debe solicitar y qué afirmación debe esperar?

> **Respuesta:** Conserve los valores originales, la identidad de la fuente, la forma existente y las coordenadas de índices conocidas. Solicite la frecuencia de muestreo de confianza y el contrato de valores, ventana y referencia; valídelos antes de asignar hercios, segundos o dB calibrados. La clasificación de la característica y su interpretación musical deben esperar a esos requisitos. Registrar el contexto faltante es un resultado útil en ese límite, no una comparación medida ni un protocolo de contrapresión semántica implementado.

## Límites de las pruebas

Lea el [registro del análisis](../../../../code/streeling/evidence/spectral-views-2026-10-22/execution.json) y la [verificación de las fuentes](../../../../code/streeling/evidence/spectral-views-2026-10-22/primary-readback.json) para consultar versiones y hashes de entrada. El conjunto de datos prueba aritmética, orientación e interpretación bajo entradas declaradas. No establece la idoneidad de un esquema general ni una ejecución de la cadena de edición de IX, un adaptador de producción o un resultado de aprendizaje.
