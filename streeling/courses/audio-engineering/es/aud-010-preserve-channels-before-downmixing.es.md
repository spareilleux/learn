---
module_id: aud-010-preserve-channels-before-downmixing
department: audio-engineering
course: "Conservar los canales antes de reducir a mono"
level: intermediate
prerequisites: ["aud-005-pcm-guards-and-format-boundaries", "aud-009-declare-alignment-before-a-null-test"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---


# Conservar los canales antes de reducir a mono

> **Borrador y límites de la evidencia.** Este curso presenta un modelo construido y lecturas de fuentes. Las decisiones técnicas humanas, musicales, lingüísticas y de alumnos siguen pendientes. No se afirma ningún nuevo renderizado, ejecución de analizador, interpretación, escucha ni observación de alumnos. Los fallos históricos mantienen su estado.

## La pregunta del proyecto

Una persona que revisa GA recibe una referencia de guitarra estéreo y una síntesis mono. Promediar antes de comprobar los canales puede borrar la señal que se pretende comparar. Este curso explicita la matriz de reducción, conserva el soporte original e identifica lo que ya no puede recuperarse. Se estudia la conservación de datos, sin nuevas grabaciones ni juicios auditivos.

## Leer la evidencia del proyecto

Lea el prerrequisito y el artefacto conservado antes de aplicar el modelo. Localice la representación, transformación o exclusión pertinente. El paquete fijo conserva identidad de fuentes, alcance de lectura y valores construidos; una fuente documenta su contenido en esa revisión, sin demostrar despliegue actual. Separe observación derivada del texto y propuesta inferida. Cuando haya referencia primaria, respete su alcance declarado sin extenderlo a casos no admitidos.

[Prerrequisito: aud-005-pcm-guards-and-format-boundaries](../../audio-engineering/en/aud-005-pcm-guards-and-format-boundaries.md)

[Prerrequisito: aud-009-declare-alignment-before-a-null-test](../../audio-engineering/en/aud-009-declare-alignment-before-a-null-test.md)

[Artefacto del proyecto conservado](../../../../code/streeling/guitar-runtime/run.mjs)

[Paquete de datos construidos](../../../../code/streeling/evidence/batch50-2026-10-23/unit-a.json)

[Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)

[Referencia primaria](https://www.w3.org/TR/webaudio-1.0/#channel-up-mixing-and-down-mixing)

## 1. Ejercicio 1

Tomemos muestras izquierdas `[1,-1,1,-1]` y derechas `[-1,1,-1,1]`, sobre el mismo soporte de cuatro tramas. La suma de cuadrados es 4 en cada canal. Una trama reúne las muestras simultáneas de los canales: cuatro tramas estéreo contienen ocho valores escalares. Confundir estas cantidades altera el razonamiento sobre duración y tamaño.

¿Cuántas tramas y valores escalares hay, y qué energía tiene cada canal?

> **Respuesta.** Hay 4 tramas y 8 valores escalares. La suma de cuadrados de cada canal es 4; no es energía calibrada en julios.

## 2. Ejercicio 2

Apliquemos la reducción declarada `m[n]=(L[n]+R[n])/2`. Todas las muestras resultantes son cero porque los canales tienen signos opuestos. La entrada multicanal no es nula. Un búfer reducido silencioso no demuestra que los canales originales fueran silenciosos; una prueba de cancelación mono tampoco certifica su igualdad.

Calcule el vector mono y explique por qué sería engañosa la etiqueta « silencio ».

> **Respuesta.** El vector mono es `[0,0,0,0]`, con suma de cuadrados 0. La cancelación en la matriz elegida explica ese resultado; los canales originales siguen siendo no nulos.

## 3. Ejercicio 3

Conservemos otro control con canales idénticos: `L=R=[1,-1,1,-1]`. El promedio conserva ahora ese vector y su suma de cuadrados. La comparación aísla el signo relativo entre canales. No describe todas las captaciones ni permite diagnosticar un cableado defectuoso sin conocer la adquisición.

¿Qué produce el control de canales idénticos y qué variable aísla?

> **Respuesta.** El mono es `[1,-1,1,-1]`, con suma de cuadrados 4. El control cambia la relación entre canales; no diagnostica una instalación real.

## 4. Ejercicio 4

La salida mono no distingue canales opuestos no nulos de dos canales nulos. Es una aplicación que asigna varias entradas a una misma salida. Conserve orden de canales, frecuencia de muestreo, bytes originales y matriz. Un ajuste posterior de ganancia no recupera la diferencia descartada; estos registros permiten repetir la transformación.

¿Puede recuperarse de forma única la pareja de entradas a partir del mono nulo?

> **Respuesta.** No. Los canales opuestos y dos canales nulos comparten la misma salida. Conserve los originales y la matriz declarada; el búfer reducido no basta.

## 5. Ejercicio 5

Lea el contrato mono del ejecutor conservado antes de proponer estéreo. Sus cantidades de muestras describen ese contrato, no este ejemplo nuevo. La referencia W3C sobre mezcla de altavoces define un promedio para reducir estéreo; aun así debe declararse la interpretación de canales. El informe debe distinguir lectura de código y ejecución de un decodificador.

¿Qué refutaría un informe que afirmara que el mono nulo demuestra una entrada nula?

> **Respuesta.** El caso construido de canales opuestos ya lo refuta. El informe debe conservar los valores por canal e indicar que el ejecutor se leyó, sin ejecutarlo ni ampliarlo.

## Tarea con consulta de fuentes

Prepare una breve nota de revisión a partir del caso fijo antes de abrir las soluciones. Reproduzca primero manualmente el cálculo o la tabla, conservando unidades, soporte y supuestos. Ese resultado directo es la referencia de cualquier respuesta asistida por fuentes o agentes. Examine después el artefacto enlazado e identifique un límite preciso relevante. Registre el fragmento o campo realmente utilizado, su revisión, su respuesta y toda ayuda recibida. Se permiten calculadora y consulta; indíquelas en lugar de presentar el resultado como recuerdo sin ayuda.

Aplique el control negativo además del caso principal. Escriba qué resultado observable refutaría su conclusión e indique si el control lo aporta realmente. Si falta una entrada, mantenga el resultado sin resolver en vez de elegir un valor plausible. Compare toda abstracción propuesta con la referencia manual antes de recomendar otro flujo de agentes o DSL. La clave prepara una comprobación; no registra su intento. Conserve la respuesta anterior a la revelación, cualquier corrección posterior y su motivo.

El paquete contiene cinco criterios de alumnos preparados que corresponden a los ejercicios. Sus decisiones siguen nulas hasta conservar respuestas reales, ayuda y revisión. Una aritmética correcta solo respalda el modelo declarado. Una decisión útil para el proyecto requiere todavía el juicio humano o la observación de ejecución en su ámbito correspondiente. Registre comprobaciones reales, errores y refinamientos en el diario enlazado; distinga pruebas ejecutadas de pruebas previstas.
