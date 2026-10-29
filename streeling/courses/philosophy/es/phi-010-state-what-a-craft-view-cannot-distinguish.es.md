---
module_id: phi-010-state-what-a-craft-view-cannot-distinguish
department: philosophy
course: "Declarar qué no distingue una vista artesanal"
level: intermediate
prerequisites: ["phi-008-separate-a-test-oracle-from-a-specification"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Declarar qué no distingue una vista artesanal

> Borrador pendiente de revisión técnica y lingüística. Cada escena, cantidad, temperatura, duración y resultado presentado aquí es un ejemplo elaborado. Consultar fuentes y hacer cálculos no constituye un ensayo físico, una importación en [Godot](https://docs.godotengine.org/en/4.5/), un renderizado en [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), una ejecución de [ComfyUI](https://docs.comfy.org/) ni una observación de aprendizaje. Las decisiones humanas y de ejecución siguen pendientes.

## Pregunta del proyecto

Una escultura de origami o relieve coincide con una referencia frontal y un agente declara fiel todo el objeto. La observación puede descartar precisamente el rasgo exigido. Construimos dos candidatos con la misma vista simplificada y distinto cumplimiento de profundidad. Ampliamos la distinción entre oráculo y especificación mostrando exactamente qué diferencia no transporta la función de observación.

## Leer el límite conservado

El pipeline solicita fotogramas de giro, pero esos argumentos no vinculan cada vista con todos los rasgos significativos. Godot distingue perspectiva y proyección ortográfica. Nuestra proyección ideal es una función matemática didáctica, no una captura de ninguno de los anfitriones.

Lea el prerrequisito y el artefacto conservado antes de interpretar el modelo. La fuente tiene su propia revisión y finalidad; aporta el límite descrito aquí, no las nuevas entradas didácticas. Prepare una tabla que distinga un campo inspeccionado, un supuesto, una cantidad calculada y un efecto propuesto para la escena. El resumen de un agente debe remitir al campo que interpreta. Un nombre de archivo no basta para demostrar un resultado anterior.

## Interpretar el modelo

Una observación convierte un candidato en algo inspeccionable. Si candidatos distintos producen la misma observación, esa coincidencia no establece una propiedad en la que difieren. Aquí se elimina deliberadamente la profundidad. El testigo basta para refutar la inferencia universal entre coincidencia frontal y requisito de profundidad. No vuelve inútiles las vistas frontales: pueden responder propiedades de las coordenadas conservadas. Una observación adicional debe dirigirse a la distinción perdida. Más imágenes sin relación declarada con el requisito pueden aumentar el volumen de pruebas sin cerrar la brecha lógica.

La referencia directa consiste en un dibujo rotulado y un cálculo manual con las respuestas cerradas. Conserve los valores intermedios y las unidades; después aplique la entrada modificada del control negativo. Una discrepancia aporta información: identifique si procede de la definición, del cálculo, de la representación o de la tarea antes de cambiar el modelo. Coincidir en el caso principal no establece una regla universal. Estos ejemplos finitos muestran un supuesto que una vista previa fluida podría ocultar.

```text
{"candidate_a":[0,0,0],"candidate_b":[0,0,1],"projection_axes":[0,1],"required_depth":0}
observe(p)=[p[0],p[1]]; requirement(p)=(p[2]==required_depth); indistinguishable=(observe(a)==observe(b))
```

## Ejercicios corregidos

### Ejercicio 1

Calcule las observaciones principales bajo la proyección declarada.

<details><summary>Respuesta 1</summary>

Ambas son `[0,0]`. Los candidatos son indistinguibles para esta observación exacta pese a tener distinta profundidad.

</details>

### Ejercicio 2

Evalúe el requisito de profundidad para ambos candidatos.

<details><summary>Respuesta 2</summary>

Es verdadero para A y falso para B. Observaciones iguales no implican igual cumplimiento de este requisito.

</details>

### Ejercicio 3

Aplique el control de posición modificada. ¿Qué diferencia se vuelve observable?

<details><summary>Respuesta 3</summary>

Las observaciones pasan a `[0,0]` y `[1,0]`. Son distinguibles, aunque B sigue incumpliendo el requisito de profundidad.

</details>

### Ejercicio 4

¿Qué observación ideal adicional distinguiría los candidatos principales?

<details><summary>Respuesta 4</summary>

Una observación que conserve profundidad podría distinguirlos. Aporta un testigo para esa pareja, no una prueba universal de identificación de toda propiedad escultórica.

</details>

### Ejercicio 5

¿Qué afirmación de fidelidad justifica la observación original?

<details><summary>Respuesta 5</summary>

Declare coincidencia solo bajo la vista frontal y la convención de comparación indicadas. Profundidad, superficies ocultas, material y proceso siguen pendientes sin pruebas separadas.

</details>

## Tarea con consulta de fuentes

Escriba la tabla de observación antes de abrir respuestas y señale un rasgo de relieve propuesto que la vista frontal omitiría. Localice los argumentos de captura sin afirmar un renderizado. Un candidato de vista idéntica que incumpla el rasgo oculto refuta una inferencia universal de fidelidad.

Conserve por separado su respuesta inicial, los pasajes consultados, el historial de ayuda y cualquier corrección posterior. Declare el resultado observable que refutaría su recomendación antes de proponer automatización. Compare el resultado asistido por fuentes con su referencia manual, incluida la incertidumbre adicional. El expediente contiene cinco criterios preparados; cada decisión permanece nula hasta disponer de un intento real y su revisión. Las respuestas preparadas permiten comprobar el trabajo; no demuestran que un alumno haya realizado la tarea.

## Fuentes y diario de validación

- [Prerrequisito: phi-008-separate-a-test-oracle-from-a-specification](../../philosophy/en/phi-008-separate-a-test-oracle-from-a-specification.md)
- [Artefacto conservado del proyecto](../../../../code/blender/scripts/glb_pipeline.py)
- [Fuente primaria](https://docs.godotengine.org/en/4.5/classes/class_camera3d.html)
- [Expediente fijo de ejemplos](../../../../code/streeling/evidence/batch50-2026-10-24/unit-c.json)
- [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
