---
module_id: wml-012-preserve-direction-in-a-melodic-inventory
department: world-music-languages
course: "Conservar la dirección en un inventario melódico"
level: intermediate
prerequisites: ["wml-007-resolve-scale-degrees-against-tonic-and-mode"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Conservar la dirección en un inventario melódico

> Ejemplo construido y lectura de fuentes. No se afirma nueva interpretación, ejecución de audio o analizador, respuesta de participante ni adopción en producción. Las decisiones técnicas humanas, lingüísticas y del aprendiz siguen pendientes.

Un conjunto de clases indica qué tonos aparecen en algún lugar sin decir cuáles se permiten en una dirección. Sustituir dos inventarios por su unión puede aceptar una frase que el original excluye. Construimos esa pérdida para una futura explicación GA o propuesta de gramática. Los números son material inventado; no describen una tradición identificada ni autorizan conclusiones sobre práctica interpretativa.

## Leer la evidencia conservada

Leer las observaciones del catálogo y los campos de frecuencias construidas por separado del paquete de entonación. El resumen de clases es una representación seleccionada, no una gramática completa. El requisito previo resuelve grados contra una forma declarada. Añadimos dirección mediante una política finita concreta, sin suponer que dos conjuntos describen toda melodía tradicional.

[Requisito previo](../../world-music-languages/en/wml-007-resolve-scale-degrees-against-tonic-and-mode.md)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/intonation-listening-2026-10-22/intonation.json)

[Paquete construido fijo](../../../../code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)

### Ejercicio 1

El inventario ascendente es `[0,2,4,7,9]` y el descendente `[0,2,3,7,9]`, dentro de un registro declarado. La unión es `[0,2,3,4,7,9]`, pero no dice dónde se permitían `3` y `4`. Mantener procedencia evita convertir este contraste inventado en una afirmación etnomusicológica mal atribuida.

¿Qué información elimina la unión?

<details><summary>Respuesta 1</summary>

Elimina que `4` pertenece solo al ascendente y `3` solo al descendente. Conserva pertenencia en algún lugar, no permiso según dirección.

</details>

### Ejercicio 2

Usar frase `[0,4,7,4,0]`. Comparar destino y origen de cada pareja para elegir dirección y comprobar el destino en el inventario correspondiente. Los primeros movimientos ascienden y son permitidos. La política no limita saltos ni exige grados vecinos; es deliberadamente más estrecha que una gramática completa.

¿Cuáles son las primeras dos decisiones?

<details><summary>Respuesta 2</summary>

Son `[true,true]`: los destinos `4` y `7` están en el ascendente. No juzga estilo ni ejecución física.

</details>

### Ejercicio 3

El movimiento de `7` a `4` desciende y `4` no está en el inventario descendente. La llegada final a `0` sí se permite. El vector completo es `[true,true,false,true]` y se rechaza la frase. La primera posición fallida aporta un testigo inspeccionable sin ejecutar un motor musical.

¿Por qué rechaza la frase la política original?

<details><summary>Respuesta 3</summary>

La bajada hacia `4` falla pertenencia. El vector `[true,true,false,true]` muestra que no se permiten todos los pasos requeridos.

</details>

### Ejercicio 4

El control negativo sustituye ambos inventarios por su unión `[0,2,3,4,7,9]`. La misma frase da `[true,true,true,true]` y se acepta. La unión es igual en ambas descripciones; un test limitado a esa proyección no distingue política original y reemplazo con pérdidas.

¿Qué demuestra usar la unión como política completa?

<details><summary>Respuesta 4</summary>

Aporta una frase aceptada después de proyectar pero rechazada antes. Uniones iguales no establecen reglas direccionales equivalentes.

</details>

### Ejercicio 5

Una descripción real puede depender además de registro, frases características, contexto, entonación y autoridad de fuentes. Nuestra política omite esas dimensiones. Un DSL futuro debe reproducir primero el testigo manual y conservar incógnitas sin convertir estos conjuntos en modelo normativo. Aceptar datos no demuestra validez musical.

¿Qué refutaría que un intercambio preserva la política direccional?

<details><summary>Respuesta 5</summary>

Aceptar la frase principal solo por la unión mientras se afirma equivalencia contradice el testigo. Interpretaciones culturales más amplias necesitan fuentes adecuadas y revisión musical.

</details>

## Tarea con consulta de fuentes

Construir manualmente tabla de direcciones y pertenencia y repetir con la unión. Inspeccionar el límite del catálogo y declarar qué preguntas responde. Proponer un registro direccional consultivo incluyendo el paso rechazado como refutador de pérdida. Mantener explícita su procedencia inventada y no etiquetarlo como tradición real.

Guardar primero la respuesta antes de revelar las correcciones preparadas. Usar la tabla o cálculo manual como base para calculadora, consulta de fuentes o ayuda de agente y registrar esa ayuda. Conservar por separado respuesta original y corregida. Relacionar cada ejercicio con un criterio preparado del paquete; todavía no hay decisiones del aprendiz. Registrar un pasaje leído y su revisión y separar lo que demuestra del siguiente paso propuesto. Informar entradas ausentes como no resueltas. Una respuesta matemática correcta respalda este ejemplo; revisión humana, ejecución real y aceptación del aprendiz necesitan sus propias observaciones conservadas.
