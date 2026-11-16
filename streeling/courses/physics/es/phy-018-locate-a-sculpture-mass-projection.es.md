---
module_id: phy-018-locate-a-sculpture-mass-projection
department: physics
course: "Situar la proyección de masas de una escultura"
level: intermediate
prerequisites: ["phy-013-check-torque-when-moving-a-scene-pivot"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Situar la proyección de masas de una escultura

> Borrador pendiente de revisión técnica y lingüística. Cada escena, cantidad, temperatura, duración y resultado presentado aquí es un ejemplo elaborado. Consultar fuentes y hacer cálculos no constituye un ensayo físico, una importación en [Godot](https://docs.godotengine.org/en/4.5/), un renderizado en [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), una ejecución de [ComfyUI](https://docs.comfy.org/) ni una observación de aprendizaje. Las decisiones humanas y de ejecución siguen pendientes.

## Pregunta del proyecto

Una escultura metálica asimétrica puede parecer equilibrada porque el origen de su malla está centrado. Ese origen es una elección de modelado. Situamos la proyección de un modelo de masas declarado respecto a un intervalo de apoyo para que una futura anotación de Godot distinga centrado visual y premisa mecánica estática. Ampliamos el razonamiento de pivotes ponderando posiciones, sin asignar la misma masa a cada componente o vértice.

## Leer el límite conservado

La utilidad de objetos de Atlas admite una posición y un padre opcional. Son propiedades espaciales, no masas medidas. La utilidad de materiales inspeccionada tampoco aporta densidad. Por ello introducimos masas concentradas explícitas para el ejemplo.

Lea el prerrequisito y el artefacto conservado antes de interpretar el modelo. La fuente tiene su propia revisión y finalidad; aporta el límite descrito aquí, no las nuevas entradas didácticas. Prepare una tabla que distinga un campo inspeccionado, un supuesto, una cantidad calculada y un efecto propuesto para la escena. El resumen de un agente debe remitir al campo que interpreta. Un nombre de archivo no basta para demostrar un resultado anterior.

## Interpretar el modelo

OpenStax define el centro de masa mediante posiciones ponderadas por las masas. Nuestra sección omite la otra coordenada horizontal y supone gravedad vertical. Bajo los supuestos de contacto indicados, la proyección debe quedar dentro del apoyo para tener margen estático positivo. La igualdad es un límite, no una reserva. Ni el centro geométrico ni el origen sustituyen el cálculo. Cambiar algunos vértices puede modificar su promedio sin desplazar material; mover un componente pesado sí altera el modelo aunque una caja envolvente decorativa siga centrada.

La referencia directa consiste en un dibujo rotulado y un cálculo manual con las respuestas cerradas. Conserve los valores intermedios y las unidades; después aplique la entrada modificada del control negativo. Una discrepancia aporta información: identifique si procede de la definición, del cálculo, de la representación o de la tarea antes de cambiar el modelo. Coincidir en el caso principal no establece una regla universal. Estos ejemplos finitos muestran un supuesto que una vista previa fluida podría ocultar.

```text
{"masses_kg":[2,1],"x_m":[0,0.3],"support_m":[-0.12,0.12]}
x_cm=sum(m_i*x_i)/sum(m_i); margin=min(x_cm-support_min,support_max-x_cm)
```

## Ejercicios corregidos

### Ejercicio 1

Obtenga la masa total y el centro proyectado del caso principal.

<details><summary>Respuesta 1</summary>

La masa total es `3 kg` y el centro proyectado es `0.1 m`. El componente en el origen participa en el denominador aunque su posición ponderada sea cero.

</details>

### Ejercicio 2

Calcule el margen al borde de apoyo más cercano. ¿Qué expresa su signo?

<details><summary>Respuesta 2</summary>

El margen es `0.02 m`. Es positivo porque la proyección queda estrictamente dentro del intervalo declarado; no es un factor de seguridad medido.

</details>

### Ejercicio 3

Mueva solo el componente decorativo según el control.

<details><summary>Respuesta 3</summary>

La proyección pasa a `0.2 m` y el margen a `-0.08 m`. Queda fuera del apoyo aunque la masa total y el intervalo de apoyo no cambien.

</details>

### Ejercicio 4

¿El promedio de los vértices proporciona la misma cantidad justificada?

<details><summary>Respuesta 4</summary>

No. La densidad de vértices depende de la teselación, no de la masa. Se necesitan masas de componentes o un modelo de densidad y volumen; el origen no aporta ninguno.

</details>

### Ejercicio 5

¿Qué afirmaciones siguen pendientes incluso con margen positivo?

<details><summary>Respuesta 5</summary>

La respuesta dinámica, el deslizamiento, la resistencia de uniones, la deformación y la estabilidad real no están comprobados. El resultado solo cubre la sección estática declarada.

</details>

## Tarea con consulta de fuentes

Dibuje los componentes y el apoyo, y calcule manualmente la proyección ponderada. Identifique dónde Atlas guarda posiciones y dónde faltan las masas necesarias. Una proyección exterior refuta el margen positivo del modelo; no es una observación de una escultura cayéndose.

Conserve por separado su respuesta inicial, los pasajes consultados, el historial de ayuda y cualquier corrección posterior. Declare el resultado observable que refutaría su recomendación antes de proponer automatización. Compare el resultado asistido por fuentes con su referencia manual, incluida la incertidumbre adicional. El expediente contiene cinco criterios preparados; cada decisión permanece nula hasta disponer de un intento real y su revisión. Las respuestas preparadas permiten comprobar el trabajo; no demuestran que un alumno haya realizado la tarea.

## Fuentes y diario de validación

- [Prerrequisito: phy-013-check-torque-when-moving-a-scene-pivot](../../physics/en/phy-013-check-torque-when-moving-a-scene-pivot.md)
- [Artefacto conservado del proyecto](../../../../code/blender/scripts/atlas/kit.py)
- [Fuente primaria](https://openstax.org/books/university-physics-volume-1/pages/9-6-center-of-mass)
- [Expediente fijo de ejemplos](../../../../code/streeling/evidence/batch50-2026-10-24/unit-c.json)
- [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
