---
module_id: "phy-022-budget-displacement-for-a-floating-sculpture"
department: "physics"
course: "Calcular el desplazamiento de una escultura flotante"
level: "advanced"
prerequisites: ["phy-014-preserve-mass-assumptions-when-scaling-a-craft-mesh"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Calcular el desplazamiento de una escultura flotante

> Borrador para revisión técnica y lingüística. Entradas numéricas, etiquetas y resultados esperados son casos didácticos inventados. No constituyen nuevas pruebas físicas de materiales, ejecuciones nativas de escena, observaciones de aprendizaje ni resultados de producción. Las decisiones humanas y de aprendizaje siguen sin decidirse.

## Operación del proyecto e interpretación

Se propone una escultura metálica hueca para un estanque del Observatory. La carcasa visible y el volumen desplazado responden a preguntas distintas: la carcasa aporta masa y la envolvente sellada excluye fluido. El prerrequisito sobre escalado de masa no decide si puede existir equilibrio flotante. Esta operación calcula el desplazamiento necesario para equilibrar el peso y comprueba si la envolvente puede proporcionarlo. Todas las dimensiones y masas son entradas inventadas para una especificación de asset, no mediciones de un objeto fabricado.

Dibuje toda la envolvente sellada antes de multiplicar densidad y volumen. El desplazamiento requerido procede de igualar el peso del objeto al del fluido excluido. Una fracción requerida inferior a la unidad es compatible con inmersión parcial; no es la fracción real durante una aceleración. La fuerza neta con inmersión total es otro diagnóstico. Un resultado positivo indica fuerza resultante ascendente bajo estas premisas. No significa que el equilibrio flotante tenga esa misma fuerza neta.

En el traspaso de la artesanía a la escena, conserve por separado masa de carcasa y volumen de envolvente. Una superficie mallada puede no demostrar un interior sellado. Una barca de origami o una forma esculpida hueca puede cambiar mucho de desplazamiento sin variar proporcionalmente su masa material. El asistente debe identificar la región excluida, sin deducir flotabilidad del nombre del material o de un render acuático convincente.

Lea el prerrequisito confirmado y el pasaje primario delimitado antes de calcular. Prepare un registro que separe definición de fuente, premisa inventada, resultado derivado y observación futura. Una documentación solo respalda la afirmación dentro del alcance leído. Parámetro de fuente, respuesta matemática y observación de ejecución tienen papeles probatorios distintos; un resumen seguro de un asistente no puede intercambiarlos. El paquete conserva revisión y alcance de lectura para poder cuestionar una afirmación precisa.

Trabaje primero con respuestas cerradas. Dibuje la tabla o esquema requerido y conserve cantidades intermedias con unidades o convenciones de identidad. Esa derivación a mano es la referencia manual directa. Solo después consulte un asistente o ayuda de traducción. Guarde pregunta, ubicación citada, sugerencia y cambio aceptado o rechazado. Compare el resultado asistido con el primer intento conservado, usando entradas idénticas. Una respuesta más corta no mejora el trabajo si omite una condición o inventa un ensayo terminado.

## Modelo fijo y control con entrada modificada

```json
{
  "values": {
    "mass_kg": 0.6,
    "fluid_density_kg_m3": 1000,
    "sealed_volume_m3": 0.001,
    "g_m_s2": 10
  },
  "formula": "weight=m*g; maximum_buoyancy=rho*g*V; required_displacement=m/rho; required_fraction=required_displacement/V; feasible=required_fraction<=1; full_submersion_net=maximum_buoyancy-weight",
  "expected": {
    "weight_N": 6,
    "maximum_buoyancy_N": 10,
    "required_displacement_m3": 0.0006,
    "required_fraction": 0.6,
    "feasible": true,
    "full_submersion_net_N": 4
  },
  "negative_control": {
    "values": {
      "mass_kg": 1.2,
      "fluid_density_kg_m3": 1000,
      "sealed_volume_m3": 0.001,
      "g_m_s2": 10
    },
    "expected": {
      "weight_N": 12,
      "maximum_buoyancy_N": 10,
      "required_displacement_m3": 0.0012,
      "required_fraction": 1.2,
      "feasible": false,
      "full_submersion_net_N": -2
    }
  }
}
```

### Ejercicio 1

Calcule el peso y el empuje máximo.

<details><summary>Respuesta 1</summary>

Son `6 N` y `10 N`. El segundo usa toda la envolvente sellada, no solo el volumen ocupado por metal.

</details>

### Ejercicio 2

Halle el desplazamiento y la fracción requerida.

<details><summary>Respuesta 2</summary>

Son `0.0006 m^3` y `0.6`. Es un desplazamiento de equilibrio posible, no una medición obtenida de una imagen.

</details>

### Ejercicio 3

Interprete la fuerza neta con inmersión total.

<details><summary>Respuesta 3</summary>

Es `4 N` hacia arriba. En el equilibrio flotante propuesto la resultante se anularía bajo las premisas estáticas declaradas.

</details>

### Ejercicio 4

Aplique el control más pesado.

<details><summary>Respuesta 4</summary>

La fracción requerida es `1.2` y la fuerza neta con inmersión total es `-2 N`. La inmersión parcial no puede equilibrar ese peso.

</details>

### Ejercicio 5

¿La viabilidad demuestra una orientación estable?

<details><summary>Respuesta 5</summary>

No. El cálculo carece de par restaurador y modelo de entrada de agua. Estabilidad y sellado requieren pruebas distintas para el uso propuesto.

</details>

## Tarea con fuentes y referencia manual directa

Prepare una anotación de envolvente y carcasa para una escultura Atlas hueca propuesta. Use un balance de fuerzas a mano como referencia directa e identifique el volumen que debería establecer una inspección futura del mallado. Deje vacías las mediciones físicas y de escena.

Trate el control como un registro separado. Conserve el caso principal, escriba una predicción para la entrada modificada y explique qué premisa cambia. Si discrepa de la primera respuesta, distinga error aritmético, error de interpretación y límite del modelo. Conserve juntos intento fallido y corrección. Se pide una nota revisable antes de proponer un nodo DSL o flujo de agentes; una tabla manual puede cubrir ya la necesidad.

Entregue juntos referencia inicial, ubicaciones de fuentes, explicación corregida, resultado del control y criterio de refutación. Los criterios preparados son para una revisión futura, no resultados de aprendizaje aceptados. Respuesta real, historial de ayuda, corrección y decisión permanecen vacíos hasta conservar un intento. Revisión técnica, revisión lingüística, ejecución, adopción productiva y publicación requieren cada una evidencia aplicable. Un cálculo finito correcto establecería solo la operación declarada bajo sus premisas.

## Criterio de refutación previo

La fracción requerida refuta cualquier afirmación de que el control más pesado puede flotar parcialmente con el mismo volumen sellado.

## Criterios de aprendizaje preparados

- Para el ejercicio 1: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 2: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 3: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 4: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 5: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.

## Fuentes y alcance de las afirmaciones

- [Prerrequisito confirmado: phy-014-preserve-mass-assumptions-when-scaling-a-craft-mesh](../../physics/en/phy-014-preserve-mass-assumptions-when-scaling-a-craft-mesh.md)
- [Fuente de proyecto conservada](../../../../code/blender/scripts/atlas/kit.py)
- [Lectura primaria](https://openstax.org/books/university-physics-volume-1/pages/14-4-archimedes-principle-and-buoyancy)
- [Paquete inventado](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-c.json)
- [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
