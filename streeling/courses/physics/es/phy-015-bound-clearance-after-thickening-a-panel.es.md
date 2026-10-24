---
module_id: phy-015-bound-clearance-after-thickening-a-panel
department: physics
course: "Acotar la holgura al engrosar un panel"
level: intermediate
prerequisites: ["phy-005-sheet-thickness-and-scene-units", "phy-011-compute-bend-length-on-a-declared-neutral-layer"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Acotar la holgura al engrosar un panel

> Borrador pendiente de revisión humana. Los casos fijos siguientes son modelos matemáticos elaborados tras consultar las fuentes; no son mediciones nuevas del proyecto. Siguen pendientes los dictámenes técnicos, artesanales, lingüísticos y de aprendizaje. Para esta lección no se ejecutó ningún motor de escenas, muestra física, GPU, ejecutor de políticas ni sesión con estudiantes.

## Pregunta del proyecto

Un panel IX se representa mediante una superficie de referencia y después recibe espesor finito en una escena propuesta. ¿Sigue siendo suficiente la separación original? Una superficie central, una cara interior y una exterior generan intervalos ocupados distintos. La tarea consiste en calcular una cota antes de pedir al adaptador que muestre la holgura. No certifica movimiento sin colisiones ni fabricación viable.

[Requisito previo: phy-005-sheet-thickness-and-scene-units](../../physics/en/phy-005-sheet-thickness-and-scene-units.md); [Requisito previo: phy-011-compute-bend-length-on-a-declared-neutral-layer](../../physics/en/phy-011-compute-bend-length-on-a-declared-neutral-layer.md)

## Leer el alcance antes de calcular

Lea el requisito previo y el documento del proyecto antes de calcular. Distinga las afirmaciones procedentes del código inspeccionado, los resultados registrados anteriormente y las consecuencias exclusivas de las premisas siguientes. Un comentario del código, una respuesta preparada y una observación ejecutada aportan evidencias distintas. Conserve la fecha original y todo control fallido o inconcluso al resumir un documento anterior. La referencia manual consiste en un cálculo breve en papel y una tabla de ubicaciones en las fuentes; un agente puede ayudar a localizar una definición, pero su resumen debe contrastarse con ella. Esta comparación finita no requiere un lenguaje ni una automatización nuevos.

Use dos secciones de paneles paralelos infinitos medidas según una normal común. Sus superficies de referencia permanecen fijas; los desplazamientos amplían los intervalos ocupados sin rotarlos. Reste el extremo superior del panel inferior al extremo inferior del superior. Una holgura positiva separa los intervalos en este modelo unidimensional. Una negativa indica solapamiento y cero indica contacto según la convención de intervalos cerrados. Con errores acotados, reste el máximo desplazamiento hacia dentro a la holgura nominal. La cota es determinista: no es una probabilidad de contacto ni exige errores aleatorios independientes. Elegir la referencia añade una operación distinta de convertir unidades.

## Caso fijo y supuestos

```text
zA=0 mm; zB=3 mm; tA=2 mm; tB=2 mm
A=[-1,1] mm; B=[2,4] mm; c=2-1=1 mm
eA=0.3 mm; eB=0.4 mm; c_min=1-0.3-0.4=0.3 mm
tA2=3 mm; tB2=3 mm; c2=3-1.5-1.5=0 mm
A_one_side=[0,2] mm; B_one_side=[3,5] mm; c_one_side=1 mm
```

## Ejercicios resueltos

### Ejercicio 1

Halle la holgura nominal con espesor centrado.

> **Respuesta:** Los intervalos son `[-1,1] mm` y `[2,4] mm`, con `1 mm` de holgura. La separación de superficies de referencia sobrestima el hueco restante.

### Ejercicio 2

Aplique ambas cotas de error hacia dentro.

> **Respuesta:** La holgura mínima es `0.3 mm`. Se resta la suma de los desplazamientos desfavorables; no se infiere una distribución ni probabilidad de contacto.

### Ejercicio 3

Engrose ambos paneles centrados hasta el segundo espesor.

> **Respuesta:** La holgura nominal es `0 mm`. Los mismos errores permiten `-0.7 mm`, así que falla la afirmación de holgura positiva garantizada.

### Ejercicio 4

Use los intervalos unilaterales indicados. ¿Toda convención cambia esta holgura con espesores iguales?

> **Respuesta:** No: el desplazamiento unilateral común sigue dando `1 mm`. Este control impide afirmar que cambiar la referencia siempre modifica la holgura. Desplazamientos distintos sí pueden hacerlo.

### Ejercicio 5

¿Demuestra la cota una trayectoria de plegado libre?

> **Respuesta:** No. Describe intervalos paralelos fijos. Bordes finitos, ángulos variables, tolerancias fuera de las cotas y movimiento requieren geometría y observaciones separadas.

## Tarea con consulta de fuentes

Localice superficies de referencia y unidades de escena en el requisito previo y el marco fijado. Incluya intervalos ocupados y holgura desfavorable en un traspaso IX propuesto. Conserve un croquis manual como referencia. Refuta la garantía cualquier desplazamiento permitido que vuelva no positiva la holgura prometida.

Resuelva la tarea ocultando las respuestas. Conserve las respuestas originales, los cálculos intermedios, las ubicaciones en las fuentes, las dudas y toda ayuda recibida, incluso una pista, un término traducido o una sugerencia de un agente. Después compárelas con las respuestas preparadas y registre las correcciones sin sustituir el intento original. Redacte una nota breve con la afirmación, sus supuestos, el cálculo, el control negativo y la próxima observación que podría refutarla. Un resultado correcto sin unidades ni identidad de la fuente no basta para demostrar transferencia. El expediente contiene cinco criterios preparados para el estudiante; sus decisiones permanecen null hasta disponer de un intento real y una revisión autorizada. Superar estos cálculos solo acreditaría competencia en este caso declarado. No acreditaría un adaptador implementado, un proceso material satisfactorio, un renderizador más rápido ni mejoras de aprendizaje en el proyecto. Compare la nota asistida con la referencia manual: si la ayuda oculta un supuesto o elimina un rechazo, corrija la nota antes de proponer cambios de método.

## Fuentes y diario de validación

- [Registro del proyecto](../../../../code/streeling/evidence/scene-frames-2026-10-22/orientation-controls.json)
- [Fuente primaria](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Space.fs)
- [Expediente de evidencias fijas](../../../../code/streeling/evidence/batch50-2026-10-23/unit-c.json)
- [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
