---
module_id: inf-008-keep-phase-when-waveform-identity-matters
department: information-theory
course: "Conservar la fase cuando importa la identidad de las formas de onda"
level: intermediate
prerequisites: ["inf-005-quantization-and-indistinguishable-renders", "aud-008-measure-a-filter-with-paired-input-and-output"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Conservar la fase cuando importa la identidad de las formas de onda

> **Alcance del borrador.** Contraejemplos didácticos de transformadas finitas e inspección de código público fijado a una revisión. Quedan pendientes las revisiones humanas técnica, lingüística, musical y de estudiantes, así como la verificación del HTML del curso desplegado. No se ejecutaron un nuevo renderizado de audio, una prueba de escucha ni una interfaz de producción.

## La pregunta del proyecto

Dos agentes intercambian solo módulos espectrales y concluyen que sus ataques de guitarra son idénticos. ¿Qué información respalda esa conclusión? [INF-005](inf-005-quantization-and-indistinguishable-renders.md) examina cuantización; aquí la información descartada es la fase compleja. [AUD-008](../../audio-engineering/en/aud-008-measure-a-filter-with-paired-input-and-output.md) establece transformadas emparejadas.

## 1. Construir una ambigüedad exacta

Toma dos respuestas impulsionales didácticas de dos coeficientes y rellena cada una con ceros hasta longitud N = 8:

```text
A = [3/4, 1/4, 0, 0, 0, 0, 0, 0]
B = [1/4, 3/4, 0, 0, 0, 0, 0, 0]
H_A(omega) = 3/4 + (1/4)*exp(-i*omega)
H_B(omega) = 1/4 + (3/4)*exp(-i*omega)
|H_A(omega)|^2 = |H_B(omega)|^2 = 5/8 + (3/8)*cos(omega)
```

La igualdad de módulos se cumple para toda frecuencia real, no solo los ocho índices de DFT. Las formas de onda difieren en ambas muestras no nulas. Es más que una ambigüedad de desplazamiento circular entero: el [caso de prueba](../../../../code/streeling/evidence/filter-phase-2026-10-22/phase-pair.json) comprueba cada desplazamiento de 0 a 7 y ninguno transforma A en B.

### Ejercicio 1 — Demostrar igualdad sin reconstruir la forma de onda

Desarrolla el módulo al cuadrado de cada respuesta de dos coeficientes. ¿Demuestra un módulo igual muestras iguales, incluso permitiendo un desplazamiento circular entero?

> **Respuesta:** Cada módulo al cuadrado es 9/16 + 1/16 + (6/16)cos(omega) = 5/8 + (3/8)cos(omega). Las muestras difieren. Solo el desplazamiento circular cero conserva el soporte en posiciones 0 y 1 para esta longitud, y ese desplazamiento no intercambia sus valores desiguales. Por tanto, ninguno de los desplazamientos enteros permitidos las hace idénticas.

## 2. La fase distingue lo que el módulo olvida

Usa la [DFT directa sin escalar](https://www.dsprelated.com/freebooks/mdft/DFT_Definition.html) con exponencial negativa. En k = 2, omega = pi/2:

| Respuesta | Coeficiente complejo | Módulo, aproximadamente | Fase, radianes, aproximadamente |
| --- | --- | --- | --- |
| A | 0.75 - 0.25i | 0.790569415 | -0.321750554 |
| B | 0.25 - 0.75i | 0.790569415 | -1.249045772 |

En continua ambos coeficientes son +1. En Nyquist son +0.5 y -0.5: los módulos siguen coincidiendo mientras difiere el signo. Convertir módulo a decibelios no recupera fase ni signo.

### Ejercicio 2 — Identificar un campo ausente

Un agente envía el número 0.790569415 para k = 2. ¿Qué fila identifica? ¿Qué valor adicional distinguiría estos dos candidatos en ese índice de frecuencia?

> **Respuesta:** No identifica ninguna de forma única: ambas tienen ese módulo. Su coeficiente complejo o fase las distinguiría ahí, con la convención de transformada y alineación declaradas. La fase de un coeficiente de módulo cero necesitaría su propia política de valor indefinido; esta pareja concreta no tiene ceros en el círculo unidad.

## 3. Reconstruir requiere los coeficientes complejos

La [DFT inversa](https://www.dsprelated.com/freebooks/mdft/Inverse_DFT.html) usa exponencial positiva y factor 1/N. Invertir cada espectro complejo completo reconstruye su propia secuencia rellenada dentro de tolerancia numérica. Invertir los módulos tras asignar fase cero da una tercera secuencia periódica; no recupera la elección original entre A y B.

### Ejercicio 3 — Rechazar la fase inventada

¿Por qué sustituir cada coeficiente por su módulo antes de la transformada inversa es una hipótesis nueva? ¿Puede este contraejemplo establecer que todo espectrograma de módulos solapado es imposible de invertir bajo cualquier restricción?

> **Respuesta:** Asigna fase cero en lugar de conservar los valores complejos medidos; la forma de onda resultante sigue esa elección inventada de fase. No. Este ejemplo trata la aplicación de módulo de la transformada completa para las secuencias finitas declaradas. Las tramas solapadas y restricciones adicionales cambian las preguntas de recuperación de fase; su unicidad debe investigarse bajo sus hipótesis reales.

## 4. La misma energía total puede ocultar redistribución temporal

Ambas secuencias tienen energía 5/8. Define el centroide de energía en unidades de muestra como la suma de n por la muestra al cuadrado, dividida entre energía total. A tiene centroide 0.1 muestras; B tiene centroide 0.9 muestras. Son descriptores numéricos de los impulsos didácticos, no calidad de ataque medida, temporización percibida ni una curva de retardo de grupo.

### Ejercicio 4 — Calcular una distinción temporal

Calcula ambos centroides y su diferencia. ¿Demuestra esto que un oyente pueda distinguir los filtros o que alguno mejore un ataque de guitarra?

> **Respuesta:** A da (1/16)/(10/16) = 0.1; B da (9/16)/(10/16) = 0.9. La diferencia es 0.8 muestras. Demuestra una diferencia temporal en este descriptor, no audibilidad, un retardo puro, preferencia de oyentes ni una mejora satisfactoria en producción.

## 5. Especificar tanto la transformada como su dominio de entrada

En el commit de IX `bd1336b7c4045e427dcdbe80b102790e45da5ce1`, [stft y spectrogram](https://github.com/GuitarAlchemist/ix/blob/bd1336b7c4045e427dcdbe80b102790e45da5ce1/crates/ix-signal/src/spectral.rs#L7-L54) exponen representaciones distintas: coeficientes complejos frente a módulos escalares o decibelios. Conserva los primeros si una operación posterior requiere su fase original.

GA también aplica una transformada de Fourier a otro dominio. En el commit `76efbffd5af82b46c3146957a6bd4504008eeb89`, [SetClass](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Domain.Core/Theory/Atonal/SetClass.cs#L150-L223) transforma el vector de clases de altura de la forma prima espectral y después ofrece vistas de módulo y fase. Conservar la fase de ese vector canónico no recupera una transposición original ya eliminada por la canonicalización.

El componente separado [SpectralPhaseAlignment](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Common/GA.Domain.Core/Theory/Atonal/SpectralPhaseAlignment.cs#L75-L139) usa chroma real y productos cruzados complejos para rotaciones de prueba. Sus [pruebas](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Tests/Common/GA.Business.Core.Tests/Atonal/SpectralPhaseAlignmentTests.cs) incluyen alineación de transposición de tríada mayor. Es lectura de código y pruebas, no una ejecución nueva de C#. Rotación de clases de altura no es retardo temporal de audio; un índice de Fourier necesita su dominio de entrada declarado.

### Ejercicio 5 — Diseñar un traspaso defendible entre agentes

Escribe los campos y límites de afirmaciones para un agente que compare identidad de formas de onda y otro que compare alineación de clases de altura. Explica por qué «conservamos la fase» no basta por sí solo.

> **Respuesta:** Conserva dominio de entrada y su normalización o canonicalización, identidad de fuente, signo y escalado de transformada, longitud, ejes, frecuencia de muestreo para audio, alineación temporal y coeficientes complejos o datos originales según haga falta. Indica si se comparan módulo, muestras exactas, un desplazamiento temporal especificado o rotación de clases de altura. La fase de una entrada canónica no restaura información borrada antes de la transformada. Un adaptador entre estas representaciones sigue siendo un diseño propuesto, no un contrato implementado.

## Tarea del estudiante con acceso a las fuentes

Prepara un informe de contraejemplo para una afirmación de «mismo ataque de guitarra» basada solo en módulos. Incluye identidad de módulos, un coeficiente complejo que los distinga, la hipótesis de transformada inversa, ambos centroides de energía y la distinción de dominios de entrada en las dos rutas de GA. Registra ayuda y cuestiones sin resolver. La [rúbrica de revisión](../../../../code/streeling/evidence/filter-phase-2026-10-22/reviewer-rubric.json) está preparada, sin ninguna decisión de estudiante registrada.

El [comprobante de fuentes](../../../../code/streeling/evidence/filter-phase-2026-10-22/primary-readback.json) vincula los archivos inmutables. De estos cálculos no se deriva ningún resultado perceptivo, teorema completo de recuperación de fase, adaptador desplegado ni éxito de estudiantes.
