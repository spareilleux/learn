---
module_id: gaa-012-cross-timbre-with-interval-in-an-ear-trial
department: guitar-alchemist-academy
course: "Cruzar timbre e intervalo en una prueba de oído"
level: intermediate
prerequisites: ["gaa-002-training-your-ear"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Cruzar timbre e intervalo en una prueba de oído

> Ejemplo construido y lectura de fuentes. No se afirma nueva interpretación, ejecución de audio o analizador, respuesta de participante ni adopción en producción. Las decisiones técnicas humanas, lingüísticas y del aprendiz siguen pendientes.

Un guitarrista puede parecer capaz de reconocer intervalos cuando reconoce el sonido asignado. Si cada tercera mayor usa un timbre y cada cuarta otro, se adivina sin comparar alturas. GA debe mostrar ese fallo antes de informar una habilidad auditiva. Construimos un plan cruzado pequeño cuya cobertura se comprueba sin audio; su validez musical y para aprendices queda como pregunta aparte.

## Leer la evidencia conservada

Leer las políticas de pistas conservadas: cada objetivo revela u oculta etiquetas diferentes. El principio también sirve para pistas sonoras involuntarias. NIST define el factorial completo cruzando cada nivel de un factor con todos los niveles de los otros. Usamos esa propiedad combinatoria, sin tomar resultados experimentales ni implicar que se aleatorizó el orden.

[Requisito previo](../../guitar-alchemist-academy/en/gaa-002-training-your-ear.md)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/practice-items.json)

[Paquete construido fijo](../../../../code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)

[Lectura primaria](https://www.itl.nist.gov/div898/handbook/pri/section3/pri333.htm)

### Ejercicio 1

Declarar intervalos `[M3,P4]` y timbres `[nylon,steel]`. Su producto cartesiano tiene `4` celdas, ordenadas por intervalo y después timbre. No afirma que los timbres sintetizados sean perceptivamente distintos ni los intervalos igual de difíciles. Eso requiere estímulos y oyentes reales.

Enumerar las celdas en el orden declarado.

<details><summary>Respuesta 1</summary>

Son `[(M3,nylon),(M3,steel),(P4,nylon),(P4,steel)]`. El orden relaciona cada vector de cuentas con sus condiciones.

</details>

### Ejercicio 2

Asignar `2` ensayos a cada celda. El vector `[2,2,2,2]` suma `8`. Cada intervalo aparece con cada timbre; la asignación ya no permite determinar perfectamente la respuesta solo por timbre. Se elimina ese atajo determinista de la tabla, sin garantizar ausencia de cualquier otra pista.

¿Cuántos ensayos y celdas cubiertas hay?

<details><summary>Respuesta 2</summary>

Hay `8` ensayos y `4` celdas cubiertas. Todas tienen cuentas iguales y positivas: la asignación construida es completa y equilibrada.

</details>

### Ejercicio 3

El equilibrio no especifica nivel, registro, dirección, duración o visibilidad de respuesta. Cada dimensión puede dar otra pista. Declarar qué se fija y varía y conservar la identidad real del estímulo. Un renderizador que ignorase timbre fallaría otra comprobación de fidelidad aunque el plan estuviera equilibrado.

¿Valida por sí solo el equilibrio una prueba auditiva?

<details><summary>Respuesta 3</summary>

No. La tabla especifica cobertura de asignaciones. Estímulos, control de pistas, reproducción y respuestas reales necesitan observación; las cuentas no prueban aprendizaje ni equivalencia perceptiva.

</details>

### Ejercicio 4

El control negativo asigna `4` ensayos a `(M3,nylon)` y `4` a `(P4,steel)`, dejando vacías las otras celdas. El vector es `[4,0,0,4]`. Sigue habiendo `8` ensayos y márgenes equilibrados para cada factor. Pero solo se cubren `2` celdas y el timbre identifica perfectamente la respuesta.

¿Por qué los márgenes iguales no detectan la confusión?

<details><summary>Respuesta 4</summary>

Ignoran emparejamientos. El control cubre solo `2` de `4` celdas; intervalo y timbre siguen perfectamente ligados pese a totales marginales iguales.

</details>

### Ejercicio 5

Un agente puede comprobar la tabla y guardar una semilla aleatoria si después se usa realmente. No debe inventar orden mezclado, reproducción exitosa ni respuestas. Antes de interpretar puntuaciones, comparar estímulo reproducido y celda prevista, registrar ayudas y usar ejemplos nuevos si se busca transferencia.

¿Qué refutaría que se cruzaron por completo ambos factores?

<details><summary>Respuesta 5</summary>

Una celda obligatoria sin ensayos refuta la completitud. El control aporta ese testigo; afirmar producción requiere además evidencia de que se reprodujeron los estímulos previstos.

</details>

## Tarea con consulta de fuentes

Dibujar manualmente las tablas completa y confundida con sus márgenes. Inspeccionar las pistas conservadas e identificar otra pista involuntaria que controlar. Proponer un registro con intervalo, timbre e identidad real del archivo. Especificar un refutador de cobertura antes de sugerir ayuda de agente y dejar sin ejecutar aleatorización, escucha y resultados del aprendiz.

Guardar primero la respuesta antes de revelar las correcciones preparadas. Usar la tabla o cálculo manual como base para calculadora, consulta de fuentes o ayuda de agente y registrar esa ayuda. Conservar por separado respuesta original y corregida. Relacionar cada ejercicio con un criterio preparado del paquete; todavía no hay decisiones del aprendiz. Registrar un pasaje leído y su revisión y separar lo que demuestra del siguiente paso propuesto. Informar entradas ausentes como no resueltas. Una respuesta matemática correcta respalda este ejemplo; revisión humana, ejecución real y aceptación del aprendiz necesitan sus propias observaciones conservadas.
