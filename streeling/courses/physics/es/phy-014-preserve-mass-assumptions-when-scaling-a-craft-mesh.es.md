---
module_id: phy-014-preserve-mass-assumptions-when-scaling-a-craft-mesh
department: physics
course: "Conservar los supuestos de masa al escalar una malla artesanal"
level: intermediate
prerequisites: ["phy-005-sheet-thickness-and-scene-units"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Conservar los supuestos de masa al escalar una malla artesanal

> Borrador pendiente de revisión humana. Los casos fijos siguientes son modelos matemáticos elaborados tras consultar las fuentes; no son mediciones nuevas del proyecto. Siguen pendientes los dictámenes técnicos, artesanales, lingüísticos y de aprendizaje. Para esta lección no se ejecutó ningún motor de escenas, muestra física, GPU, ejecutor de políticas ni sesión con estudiantes.

## Pregunta del proyecto

Una escena artesanal duplica su anchura y altura. ¿Su masa se duplica, se cuadruplica o se multiplica por ocho? Depende de si cambia el espesor y de si se mantiene la densidad o la masa total. El modelo BRUTAL inspeccionado describe cajas, transformaciones y superficies; no mide densidades. Esta lección añade un balance de masa al análisis geométrico sin convertir un nombre de material visual en una especificación física.

[Requisito previo: phy-005-sheet-thickness-and-scene-units](../../physics/en/phy-005-sheet-thickness-and-scene-units.md)

## Leer el alcance antes de calcular

Lea el requisito previo y el documento del proyecto antes de calcular. Distinga las afirmaciones procedentes del código inspeccionado, los resultados registrados anteriormente y las consecuencias exclusivas de las premisas siguientes. Un comentario del código, una respuesta preparada y una observación ejecutada aportan evidencias distintas. Conserve la fecha original y todo control fallido o inconcluso al resumir un documento anterior. La referencia manual consiste en un cálculo breve en papel y una tabla de ubicaciones en las fuentes; un agente puede ayudar a localizar una definición, pero su resumen debe contrastarse con ella. Esta comparación finita no requiere un lenguaje ni una automatización nuevos.

Suponga una lámina rectangular homogénea, sin agujeros, de espesor constante y densidad uniforme estipulada. Su volumen es el producto de sus dimensiones y su masa es la densidad por el volumen. Multiplicar todas las dimensiones por el mismo factor eleva ese factor al cubo en el volumen. Ampliar solo las dimensiones del plano lo eleva al cuadrado. Son modelos alternativos de una edición de malla, no observaciones enfrentadas. Una tercera política puede conservar la masa total, pero entonces cambia la densidad implícita si cambia el volumen. El expediente expone esa incompatibilidad antes de proponer un traslado de parámetros físicos.

## Caso fijo y supuestos

```text
w=0.20 m; h=0.10 m; t=0.001 m; rho=800 kg/m^3
V=w*h*t=0.00002 m^3; m=rho*V=0.016 kg
s=2
V_all=s^3*V=0.00016 m^3; m_all=0.128 kg
V_planar=s^2*V=0.00008 m^3; m_planar=0.064 kg
rho_fixed_mass=0.016/0.00016=100 kg/m^3
```

## Ejercicios resueltos

### Ejercicio 1

Calcule la masa original.

> **Respuesta:** El volumen es `0.00002 m^3`; al multiplicarlo por la densidad se obtienen `0.016 kg`, o `16 g`. Son valores materiales estipulados.

### Ejercicio 2

Escale todas las dimensiones. ¿Cuál es la razón de masas?

> **Respuesta:** La razón es `8`; la masa pasa a `0.128 kg`. El espesor forma parte de esta ampliación geométrica.

### Ejercicio 3

Mantenga el espesor al ampliar el plano.

> **Respuesta:** La masa se multiplica por `4` y llega a `0.064 kg`. Este control negativo refuta el uso automático del factor cúbico.

### Ejercicio 4

Conserve la masa tras ampliar todas las dimensiones. ¿Qué densidad se implica?

> **Respuesta:** Implica `100 kg/m^3`, un octavo de la densidad original. Densidad fija y masa fija no pueden coexistir con este cambio de volumen.

### Ejercicio 5

¿El nombre de superficie piedra justifica la densidad?

> **Respuesta:** No. El descriptor aporta una categoría de renderizado. La densidad numérica es un supuesto elaborado; una afirmación física exige una base material independiente.

## Tarea con consulta de fuentes

Inspeccione las definiciones de tamaño y superficie del modelo fijado. Anote una escena ampliada con una política de espesor y un supuesto de densidad independiente. Compare el balance manual de volumen con un resumen de agente. Rechácelo si conserva densidad y masa total pese al aumento de volumen.

Resuelva la tarea ocultando las respuestas. Conserve las respuestas originales, los cálculos intermedios, las ubicaciones en las fuentes, las dudas y toda ayuda recibida, incluso una pista, un término traducido o una sugerencia de un agente. Después compárelas con las respuestas preparadas y registre las correcciones sin sustituir el intento original. Redacte una nota breve con la afirmación, sus supuestos, el cálculo, el control negativo y la próxima observación que podría refutarla. Un resultado correcto sin unidades ni identidad de la fuente no basta para demostrar transferencia. El expediente contiene cinco criterios preparados para el estudiante; sus decisiones permanecen null hasta disponer de un intento real y una revisión autorizada. Superar estos cálculos solo acreditaría competencia en este caso declarado. No acreditaría un adaptador implementado, un proceso material satisfactorio, un renderizador más rápido ni mejoras de aprendizaje en el proyecto. Compare la nota asistida con la referencia manual: si la ayuda oculta un supuesto o elimina un rechazo, corrija la nota antes de proponer cambios de método.

## Fuentes y diario de validación

- [Registro del proyecto](../../../../code/streeling/evidence/brutal-composition-2026-10-22/composition-calculations.json)
- [Fuente primaria](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Model.fs)
- [Expediente de evidencias fijas](../../../../code/streeling/evidence/batch50-2026-10-23/unit-c.json)
- [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
