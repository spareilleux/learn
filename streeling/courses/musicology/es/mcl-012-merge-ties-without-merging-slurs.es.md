---
module_id: mcl-012-merge-ties-without-merging-slurs
department: musicology
course: "Unir ligaduras de prolongación sin unir las de expresión"
level: intermediate
prerequisites: ["mcl-007-integrate-a-midi-tempo-map-before-scheduling"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Unir ligaduras de prolongación sin unir las de expresión

> Ejemplo construido y lectura de fuentes. No se afirma nueva interpretación, ejecución de audio o analizador, respuesta de participante ni adopción en producción. Las decisiones técnicas humanas, lingüísticas y del aprendiz siguen pendientes.

Una partitura puede mostrar dos cabezas para un sonido sostenido o una curva sobre varios sonidos separados. Un importador GA que fusione cada curva puede conservar alturas impresas cambiando la frase. Calculamos la distinción con pocos eventos. Añadimos identidad sonora a la reconstrucción temporal antes de elegir programación audio o técnica física. Ataque significa aquí comienzo sonoro simbólico, no golpe de púa.

## Leer la evidencia conservada

Leer las identidades estables y las instantáneas sostenidas del paquete temporal. Ya distinguen mantener un evento de volver a dispararlo en cada instantánea. MusicXML asigna tie al sonido y tied a la notación. El pasaje establece esa diferencia, sin validar un importador. El caso siguiente es construido para una voz; no se afirma que GA lo importara o reprodujera.

[Requisito previo](../../musicology/en/mcl-007-integrate-a-midi-tempo-map-before-scheduling.md)

[Artefacto conservado del proyecto](../../../../code/streeling/evidence/music-phrase-2026-10-22/timed-events.json)

[Paquete construido fijo](../../../../code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)

[Lectura primaria](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/tie/)

### Ejercicio 1

Las filas son altura `60` en pulso `0` durante `1` pulso, `60` en pulso `1` durante `1` pulso y `62` en pulso `2` durante `1` pulso. La primera pareja está explícitamente ligada como prolongación. Coinciden alturas y son contiguas, por lo que la regla construida fusiona la pareja conservando el inicio.

¿Qué evento sonoro sustituye a la pareja?

<details><summary>Respuesta 1</summary>

Altura `60`, inicio `0`, duración `2` pulsos. La segunda cabeza no constituye otro ataque simbólico bajo esta regla.

</details>

### Ejercicio 2

La última altura cambia a `62` y permanece como evento de pulso `2` a `3`. La lista completa tiene `2` eventos en `3` pulsos. Sumar duraciones no revela si una nota repetida se atacó o sostuvo; deben conservarse relación e identidades.

Dar los totales de eventos sonoros y extensión temporal.

<details><summary>Respuesta 2</summary>

Hay `2` eventos con duraciones `[2,1]` pulsos y extensión `3` pulsos. La extensión sola no determina ataques.

</details>

### Ejercicio 3

La igualdad de altura no basta. Un hueco, otra voz o falta de relación de prolongación cambia la premisa. Los formatos reales también necesitan reglas para parejas inicio/final, repeticiones y notación incorrecta. Esta lección no las implementa. La revisión debe declarar su caso simple sin afirmar conformidad general.

¿Se pueden fusionar automáticamente alturas iguales adyacentes?

<details><summary>Respuesta 3</summary>

No. Deben conservarse relación y condiciones relevantes de identidad y tiempo. Altura igual no establece continuidad; el modelo cubre solo su voz contigua declarada.

</details>

### Ejercicio 4

El control negativo cambia la relación a `slur` conservando alturas y duraciones. La regla no autoriza fusión de duraciones. Ahora hay `3` eventos simbólicos y siguen `3` pulsos de extensión. Una ligadura de expresión puede indicar fraseo o articulación sin convertir esas fronteras en prolongación.

¿Qué cambia pese a totales temporales iguales?

<details><summary>Respuesta 4</summary>

El número pasa a `3`, con duraciones `[1,1,1]` pulsos. La extensión idéntica de `3` pulsos no certifica identidad de sostenidos.

</details>

### Ejercicio 5

Una guitarra puede producir notas legato separadas sin nuevos golpes de púa, mientras una prolongación pide continuidad. El conteo simbólico no permite inferir el gesto físico. Separar relación notada, identidad sonora y acción prevista, y exigir traza real antes de afirmar conservación en audio.

¿Qué refutaría que un importador distingue ambas ligaduras?

<details><summary>Respuesta 5</summary>

Producir la misma lista sonora fusionada para caso principal y control pierde la distinción. Una duración total correcta no repara la frontera eliminada.

</details>

## Tarea con consulta de fuentes

Dibujar filas escritas e intervalos sonoros para ambas relaciones. Compararlos con las instantáneas conservadas y la distinción MusicXML entre sonido y notación. Proponer una tabla mínima con relación, voz, altura y extremos. Especificar un resultado que rechace una fusión indebida y dejar pendientes ejecución del importador, audio y actuación del aprendiz.

Guardar primero la respuesta antes de revelar las correcciones preparadas. Usar la tabla o cálculo manual como base para calculadora, consulta de fuentes o ayuda de agente y registrar esa ayuda. Conservar por separado respuesta original y corregida. Relacionar cada ejercicio con un criterio preparado del paquete; todavía no hay decisiones del aprendiz. Registrar un pasaje leído y su revisión y separar lo que demuestra del siguiente paso propuesto. Informar entradas ausentes como no resueltas. Una respuesta matemática correcta respalda este ejemplo; revisión humana, ejecución real y aceptación del aprendiz necesitan sus propias observaciones conservadas.
