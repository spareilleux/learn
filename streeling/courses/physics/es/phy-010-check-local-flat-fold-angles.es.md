---
module_id: phy-010-check-local-flat-fold-angles
department: physics
course: "Comprobar los ángulos locales de un plegado plano"
level: intermediate
prerequisites: ["phy-005-sheet-thickness-and-scene-units", "cs-009-composing-origami-panel-constraints"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Comprobar los ángulos locales de un plegado plano

> **Alcance del borrador.** Código público de IX fijado a una revisión, lectura primaria de teoremas y cálculos de ángulos y asignaciones creados para el curso. Quedan pendientes las revisiones humanas técnica, lingüística y de estudiantes, así como la verificación del HTML del curso desplegado. No se ejecutaron un analizador Rust ni una escena anfitriona, ni se usó papel físico o produjo una malla plegada para esta lección.

## La pregunta del proyecto

Antes de que un agente de creación envíe un patrón de pliegues hacia una escena, ¿qué comprobaciones angulares son útiles? [CS-009](../../computer-science/en/cs-009-composing-origami-panel-constraints.md) ya trata las restricciones globales de orden de paneles. Aquí examinamos otro objeto: un pequeño entorno de un único vértice interior sobre material plano ideal de espesor cero, con todos los pliegues enumerados usados en un plegado plano. El [módulo local de IX de la revisión fijada](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/src/local.rs) proporciona filtros numéricos concretos. Todas las observaciones del código del proyecto usan el commit de IX `d7c22fdd6a62becb66b9d7246ea85850e7c55854`.

## 1. Recuperar el orden cíclico de los sectores

Usa cuatro semirrectas salientes etiquetadas desde un vértice central. Sus direcciones se miden en sentido antihorario desde un eje declarado:

| Semirrecta | Dirección, grados | Sector hasta la siguiente semirrecta, grados |
| --- | --- | --- |
| e0 | 0 | 60 |
| e1 | 60 | 90 |
| e2 | 150 | 120 |
| e3 | 270 | 90 |

El sector final vuelve a la primera semirrecta. IX [ordena las direcciones geométricas](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/src/local.rs#L45-L71) a partir de `atan2` y usa un resto positivo de vuelta completa. El orden de la lista de aristas de entrada por sí solo no define los sectores vecinos. El [registro angular fijado](../../../../code/streeling/evidence/origami-local-2026-10-22/sector-calculations.json) comprueba las 24 permutaciones de las cuatro semirrectas de entrada; esas permutaciones conservan la misma geometría.

### Ejercicio 1: cerrar el circuito angular

Recupera los cuatro sectores a partir de las direcciones de las semirrectas, incluido el cierre. ¿Cuál es su total? ¿Conservaría este entorno calcular diferencias en un orden arbitrario de la lista de aristas?

> **Respuesta:** Los sectores son 60, 90, 120 y 90 grados, con un total de 360. Los vecinos de una lista arbitraria no tienen por qué ser vecinos geométricos; ordena alrededor del vértice e incluye el cierre antes de aplicar la prueba de sectores.

## 2. Aplicar Kawasaki con sus hipótesis

Para un único vértice interior ideal sin asignación, la condición de Kawasaki exige grado par y suma alternada cero de sectores consecutivos. Sobre material plano, equivale a que cada grupo alternado sume 180 grados. La [revisión de Demaine, sección 3.1](https://erikdemaine.org/papers/OSME2001/paper.pdf#page=6), deja explícitamente sin especificar las direcciones montaña/valle en este enunciado de existencia.

Nuestros sectores dan `60-90+120-90=0`, con totales alternados 180 y 180. Un cambio cíclico de la semirrecta inicial puede invertir el signo de un residuo no nulo; su valor absoluto no cambia para grado par. Un vértice de borde o uno con un pliegue plano no usado no satisface automáticamente estas hipótesis. Tampoco una prueba angular superada establece una asignación concreta ni un movimiento físico de paneles gruesos.

### Ejercicio 2: enunciar la conclusión angular

Calcula los totales alternados del vértice didáctico. ¿Qué establece el teorema de vértice único sin asignación bajo sus hipótesis? ¿Establece todas las posibles asignaciones de etiquetas montaña/valle?

> **Respuesta:** Los totales son `60+120=180` y `90+90=180`. Bajo las hipótesis ideales declaradas de vértice único, existe una asignación montaña/valle que admite un plegado plano local. Es una afirmación de existencia, no que todas las asignaciones funcionen ni que se valide una hoja completa o un objeto grueso.

## 3. Mantener la tolerancia en radianes

La función de bajo nivel de IX acepta una tolerancia en radianes; la [llamada agregada](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/src/layers.rs#L879-L889) usa `1e-9`. Su predicado angular falla si el grado es impar o el residuo absoluto supera esa tolerancia.

Perturba la semirrecta e1 en delta radianes positivos manteniendo fijas las demás direcciones. Los dos sectores vecinos cambian en más delta y menos delta, por lo que el residuo alternado absoluto pasa a ser `2*abs(delta)` en aritmética exacta. Delta `1e-10` da `2e-10`, dentro de la tolerancia; delta `1e-8` da `2e-8`, fuera. La transcripción guardada usa operaciones angulares ordinarias de coma flotante, así que conserva su residuo calculado en lugar de presentar la expresión ideal como un resultado de Rust ejecutado. Esta tolerancia numérica no es un margen medido de plegado de papel o fabricación.

### Ejercicio 3: comparar perturbaciones

Aplica la tolerancia `1e-9` radianes a los dos deltas `1e-10` y `1e-8` radianes. ¿Qué casos numéricos pasan? ¿Puede leerse la tolerancia directamente como grados o como una especificación de taller?

> **Respuesta:** Los residuos son aproximadamente `2e-10` y `2e-8` radianes, así que el primero pasa y el segundo falla la regla numérica declarada. No pueden renombrarse silenciosamente los radianes como grados, y ninguna medición de material o proceso respalda aquí una tolerancia de taller.

## 4. Comprobar las etiquetas además de los ángulos

Para una asignación montaña/valle prescrita, Maekawa exige `abs(M-V)=2`. Con cuatro pliegues, eso permite tres de un tipo y uno del otro. No restringe dónde aparece la etiqueta minoritaria. La [revisión primaria de Hull](https://arxiv.org/pdf/1307.1065#page=8) da restricciones adicionales de asignación, incluida la construcción del ángulo menor con sus hipótesis sobre los ángulos vecinos.

Aquí el sector de 60 grados entre e0 y e1 es estrictamente menor que ambos vecinos de 90 grados. Sus pliegues limítrofes deben tener tipos montaña/valle opuestos en una asignación ideal plana válida. El etiquetado didáctico `MMMV`, en orden de semirrectas de e0 a e3, tiene `M-V=2` y supera la condición angular. Sin embargo, e0 y e1 son ambos montañas y violan esa restricción necesaria adicional. Por tanto, esos dos filtros numéricos por sí solos no certifican esta asignación prescrita.

### Ejercicio 4: rechazar un atajo de condición suficiente

Para `MMMV`, calcula la diferencia montaña/valle e identifica la regla adicional violada. ¿Demuestra esto que la propia geometría angular no tiene ninguna asignación posible? ¿Aceptó aquí este objeto el analizador completo de IX?

> **Respuesta:** Tres montañas menos un valle dan 2, pero los pliegues que delimitan el mínimo estricto de 60 grados son ambos montañas. Esa asignación prescrita viola la regla adicional; la geometría angular aún puede tener otra asignación válida según el teorema de vértice único. No se proporcionaron un objeto completo de IX ni una ejecución del analizador, así que no se afirma aceptación por el analizador completo.

## 5. Conservar el dominio probado

La [envoltura local de aplicabilidad](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/src/local.rs#L106-L143) incluye solo vértices interiores cuyos pliegues incidentes son todos montañas o valles. La [especificación FOLD de la revisión fijada](https://raw.githubusercontent.com/edemaine/fold/824f9fa6f944248787b0b2077ef622761489201e/doc/spec.md) distingue desconocido `U`, plano `F` y borde `B` de esos pliegues asignados. Un desconocido no es silenciosamente una montaña ni un valle.

Nuestra ficha de incidencia tiene un centro, cuatro vértices exteriores en un anillo de borde y un vértice aislado. Con pliegues centrales asignados, sus recuentos modelados son 1 aplicable, 4 omitidos por borde y 1 omitido por aislamiento. Cambiar un pliegue central a `U` da 0 aplicables y 1 omitido por otro tipo de pliegue, mientras los fallos siguen vacíos y el residuo máximo se inicializa en 0. Son recuentos didácticos de ramas del código, no un archivo FOLD completo ejecutado o analizado. [PHI-006](../../philosophy/en/phi-006-preserve-the-quantifier-in-a-fold-verdict.md) explica la diferencia lógica entre ausencia de fallos y una asignación probada.

### Ejercicio 5: leer un conjunto comprobado vacío

En la ficha del pliegue desconocido, ¿qué ocurrió con la cobertura del centro? ¿Demuestran los fallos vacíos y el residuo máximo 0 que se comprobó y pasó? ¿Qué debe conservar un agente posterior?

> **Respuesta:** Se omite el centro por el pliegue incidente desconocido, dejando 0 vértices aplicables. Los fallos vacíos y el máximo 0 describen un conjunto comprobado vacío; no establecen una asignación completada y probada. Conserva aplicabilidad y recuentos de omisiones, etiquetas originales de asignación, identidad del código fuente, tolerancia y alcance local del predicado. El plegado físico y la transferencia a una escena siguen sin observarse.
