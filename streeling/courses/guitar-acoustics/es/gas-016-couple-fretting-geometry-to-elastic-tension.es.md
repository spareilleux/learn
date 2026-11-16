---
module_id: gas-016-couple-fretting-geometry-to-elastic-tension
department: guitar-acoustics
course: "Relacionar la geometría del pisado con la tensión elástica"
level: advanced
prerequisites: ["gas-013-retune-with-an-explicit-tension-assumption"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Relacionar la geometría del pisado con la tensión elástica

> Modelo construido y lectura de fuentes. Siguen pendientes las revisiones técnicas humanas, lingüísticas, musicales y del aprendizaje. No se afirma ninguna nueva interpretación, escucha, ejecución de analizador, renderizado del motor ni adopción en producción.

Acortar y estirar una cuerda son operaciones acopladas cuando el contacto desvía su trayectoria. La predicción de media longitud puede diferir de una predicción elástica incluso antes de considerar la dispersión por rigidez. Esta lección construye una geometría simplificada para explicar el problema en [GA](https://github.com/GuitarAlchemist/ga). Sus dimensiones arbitrarias no son instrucciones de ajuste de un instrumento.

## Leer la evidencia conservada

La fuente de elasticidad limita la proporcionalidad entre esfuerzo y deformación al régimen lineal. Elegimos un resorte axial explícitamente construido. El prerrequisito aporta la dependencia de tensión y longitud; el campo de frecuencia del motor no mide esas magnitudes físicas.

[Prerrequisito](../../guitar-acoustics/en/gas-013-retune-with-an-explicit-tension-assumption.md)

[Artefacto conservado del proyecto](../../../../code/streeling/guitar-runtime/vendor/lib.rs)

[Registro de casos construidos](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Lectura principal](https://openstax.org/books/university-physics-volume-1/pages/12-3-stress-strain-and-elastic-modulus)

[Lectura principal](https://www.phys.unsw.edu.au/jw/strings.html)

## Caso fijo y magnitudes preparadas

```json
{
  "values": {
    "length_m": 1,
    "midpoint_displacement_m": 0.01,
    "axial_stiffness_n_per_m": 1000,
    "initial_tension_n": 10,
    "linear_density_kg_per_m": 0.001
  },
  "formula": "segment=sqrt((L/2)^2+h^2); extension=2*segment-L; tension=T0+K*extension; f=sqrt(tension/mu)/(2*segment); ideal_f=sqrt(T0/mu)/L; cents=1200*log2(f/ideal_f)",
  "expected": {
    "extension_m": 0.0001999800039989008,
    "tension_n": 10.1999800039989,
    "ideal_f_hz": 100,
    "frequency_hz": 100.9747574562156,
    "error_cents": 16.79361678856818
  },
  "negative_control": {
    "values": {
      "length_m": 1,
      "midpoint_displacement_m": 0,
      "axial_stiffness_n_per_m": 1000,
      "initial_tension_n": 10,
      "linear_density_kg_per_m": 0.001
    },
    "expected": {
      "extension_m": 0,
      "tension_n": 10,
      "ideal_f_hz": 100,
      "frequency_hz": 100,
      "error_cents": 0
    }
  }
}
```

## Separar las hipótesis geométricas de las materiales

El cálculo de la trayectoria es geométrico. Convertir extensión en tensión supone una ley material para el resorte elegido. Un dibujo preciso puede coexistir con un modelo material inexacto. Separar las etapas permite rechazar la calibración del resorte y conservar la observación útil de que desplazar el contacto cambia la trayectoria total.

La densidad lineal se mantiene fija para aislar ese acoplamiento. Una cuerda real estirada también redistribuye su masa sobre otra longitud; el contacto puede introducir fricción o tensiones desiguales. Un modelo más detallado tendría que indicar cómo medir o aproximar esos efectos. Añadir detalles sin entradas alargaría el cálculo ocultando la incertidumbre. El resultado presente es deliberadamente condicional a hipótesis sencillas.

La frecuencia comparativa corresponde a la media longitud proyectada con tensión inicial, no al fundamental al aire. Confundir esas referencias fabricaría una diferencia mucho mayor en cents y diagnosticaría mal el aumento de altura. Escriba la referencia junto a la razón antes de evaluar logaritmos. Para una explicación de GA, dibujo y ecuación son la referencia directa. Una calibración física necesitaría además geometría, respuesta axial y altura de salida medidas con incertidumbre; cambiar un campo digital de frecuencia no aporta esas observaciones.

### Ejercicio 1

Calcule la longitud del segmento desviado y la extensión total. ¿Por qué contar ambos segmentos?

<details><summary>Respuesta 1</summary>

La trayectoria contiene la pareja simétrica, aunque solo una mitad se declare vibrante. Omitir el otro segmento subestima la extensión elástica total.

</details>

### Ejercicio 2

Deduzca la tensión a partir de la extensión y la rigidez axial. ¿Es esa rigidez un módulo de Young?

<details><summary>Respuesta 2</summary>

La tensión mostrada sigue la ley del resorte declarado. La rigidez tiene unidades de fuerza por longitud; relacionarla con un módulo de Young exige sección y longitud de referencia.

</details>

### Ejercicio 3

Compare la frecuencia modelada con la de media longitud ideal. ¿Qué efectos compiten?

<details><summary>Respuesta 3</summary>

La tensión adicional aumenta la velocidad de onda, mientras que el segmento desviado supera su proyección. Ambos efectos entran en la fórmula; el error neto en cents corresponde a este caso construido.

</details>

### Ejercicio 4

Aplique desplazamiento nulo. ¿Qué residuo debe desaparecer?

<details><summary>Respuesta 4</summary>

La extensión, el incremento de tensión y el error en cents se anulan. Un residuo no nulo en este control refuta el cálculo geométrico o su referencia.

</details>

### Ejercicio 5

¿Permite el cálculo elegir una altura real de cuerda o validar un control físico de GA?

<details><summary>Respuesta 5</summary>

No. Hay que medir la flexibilidad, el cambio de densidad, el contacto y la respuesta del material. El parámetro de frecuencia del software no aporta esas entradas.

</details>

## Tarea con consulta de fuentes

Dibuje los segmentos y derive los valores a mano; después localice el campo del software que sigue siendo solo una frecuencia solicitada. Formule un criterio de refutación basado en geometría y frecuencia medidas, con incertidumbre declarada antes de proponer una calibración.

Conserve primero su razonamiento sin ayuda, antes de revelar las respuestas. Examine después un pasaje concreto y su revisión, registre toda asistencia y guarde por separado la respuesta inicial y la corregida. Use el resultado manual como referencia para cualquier calculadora, propuesta de DSL o intervención de agente. Una entrada ausente queda sin resolver. El registro contiene un criterio preparado por ejercicio sin decisión del estudiante. Una respuesta correcta solo respalda el caso declarado; la aceptación exige un intento real y su revisión. Formule un criterio de refutación antes de elegir una abstracción e indique la evidencia humana o de ejecución necesaria en la siguiente frontera.
