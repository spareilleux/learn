---
module_id: "vc-021-fold-the-lower-hemisphere-in-a-normal-encoding"
department: "visual-computing"
course: "Plegar el hemisferio inferior al codificar normales"
level: "advanced"
prerequisites: ["phy-008-keep-surface-normals-perpendicular"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Plegar el hemisferio inferior al codificar normales

> Borrador para revisión técnica y lingüística. Entradas numéricas, etiquetas y resultados esperados son casos didácticos inventados. No constituyen nuevas pruebas físicas de materiales, ejecuciones nativas de escena, observaciones de aprendizaje ni resultados de producción. Las decisiones humanas y de aprendizaje siguen sin decidirse.

## Operación del proyecto e interpretación

Un relieve cincelado tiene normales orientadas hacia un eje de referencia y en sentido contrario. Guardar solo las primeras coordenadas tras normalizar pierde el hemisferio. El traspaso compacto propuesto necesita un mapa y su inversa explícitos, sin suponer que una textura normal siempre apunta hacia delante. Aquí se deriva un caso de codificación octaédrica con valores reales. Se detiene antes de cuantización entera, muestreo de shader o afirmaciones de rendimiento de almacenamiento.

Divida primero por la suma de valores absolutos de las componentes. Esto sitúa la dirección en un octaedro. En el hemisferio inferior, pliegue el par hacia fuera usando ambas componentes originales. Al decodificar se reconstruye la profundidad desde la suma absoluta y se despliega el par cuando esa profundidad es negativa. La normalización euclídea final restablece la longitud unitaria. Actualizar en el mismo sitio es peligroso: usar la primera coordenada ya modificada para calcular la segunda cambia el mapa declarado.

El control sin pliegue conserva dirección y decodificador. Su longitud unitaria verosímil no detecta el error de hemisferio, pero el producto escalar con la dirección original sí. Para un futuro asset de [ComfyUI](https://docs.comfy.org/) a [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md) o [Godot](https://docs.godotengine.org/en/4.5/), conserve convención de codificación e interpretación de textura con los datos. La longitud unitaria no certifica dirección, marco tangente ni aspecto de fibras bordadas. El revisor asistido debe señalar el predicado que detecta realmente este control.

Para una componente exactamente nula, este mapa usa `sign(0)=1`. Ambas coordenadas plegadas usan simultáneamente el par anterior; la profundidad negativa se comprueba antes de normalizar euclídeamente.

Lea el prerrequisito confirmado y el pasaje primario delimitado antes de calcular. Prepare un registro que separe definición de fuente, premisa inventada, resultado derivado y observación futura. Una documentación solo respalda la afirmación dentro del alcance leído. Parámetro de fuente, respuesta matemática y observación de ejecución tienen papeles probatorios distintos; un resumen seguro de un asistente no puede intercambiarlos. El paquete conserva revisión y alcance de lectura para poder cuestionar una afirmación precisa.

Trabaje primero con respuestas cerradas. Dibuje la tabla o esquema requerido y conserve cantidades intermedias con unidades o convenciones de identidad. Esa derivación a mano es la referencia manual directa. Solo después consulte un asistente o ayuda de traducción. Guarde pregunta, ubicación citada, sugerencia y cambio aceptado o rechazado. Compare el resultado asistido con el primer intento conservado, usando entradas idénticas. Una respuesta más corta no mejora el trabajo si omite una condición o inventa un ensayo terminado.

## Modelo fijo y control con entrada modificada

```json
{
  "values": {
    "vector": [
      1,
      2,
      -1
    ],
    "fold_lower": true
  },
  "formula": "p=v/(abs(x)+abs(y)+abs(z)); uv=(p.x,p.y); if p.z<0 and fold_lower: uv=((1-abs(p.y))*sign(p.x),(1-abs(p.x))*sign(p.y)); q=(u,v,1-abs(u)-abs(v)); if q.z<0 unfold xy using old coordinates; decoded=q/length(q); agreement=dot(decoded,original/length(original))",
  "expected": {
    "encoded": [
      0.5,
      0.75
    ],
    "decoded_normal": [
      0.4082482904638631,
      0.8164965809277261,
      -0.4082482904638631
    ],
    "agreement": 1
  },
  "negative_control": {
    "values": {
      "vector": [
        1,
        2,
        -1
      ],
      "fold_lower": false
    },
    "expected": {
      "encoded": [
        0.25,
        0.5
      ],
      "decoded_normal": [
        0.4082482904638631,
        0.8164965809277261,
        0.4082482904638631
      ],
      "agreement": 0.6666666666666666
    }
  }
}
```

### Ejercicio 1

Halle las coordenadas del octaedro.

<details><summary>Respuesta 1</summary>

Son `[0.25,0.5,-0.25]`. La componente final negativa exige la rama inferior antes del almacenamiento.

</details>

### Ejercicio 2

Calcule el par almacenado.

<details><summary>Respuesta 2</summary>

Es `[0.5,0.75]`. Calcule ambas componentes desde el par original, sin sobrescribirlo secuencialmente.

</details>

### Ejercicio 3

Compruebe la dirección decodificada.

<details><summary>Respuesta 3</summary>

Su profundidad sigue negativa y la concordancia es `1`. Renormalizar cambia magnitud, conservando la dirección decodificada.

</details>

### Ejercicio 4

Evalúe el control sin pliegue.

<details><summary>Respuesta 4</summary>

El par pasa a `[0.25,0.5]`; la profundidad decodificada es positiva y la concordancia baja a `0.6666666666666666`. La longitud unitaria sigue cumpliéndose.

</details>

### Ejercicio 5

¿Esto establece un formato de textura de motor?

<details><summary>Respuesta 5</summary>

No. El modelo no define cuantizador entero, convención de canales ni ejecución de shader. Vincule esos elementos por separado.

</details>

## Tarea con fuentes y referencia manual directa

Prepare una traza en papel de codificación y decodificación de una normal de relieve. Compare comprobar solo longitud con comprobar dirección original y proponga los metadatos de textura que faltan.

Trate el control como un registro separado. Conserve el caso principal, escriba una predicción para la entrada modificada y explique qué premisa cambia. Si discrepa de la primera respuesta, distinga error aritmético, error de interpretación y límite del modelo. Conserve juntos intento fallido y corrección. Se pide una nota revisable antes de proponer un nodo DSL o flujo de agentes; una tabla manual puede cubrir ya la necesidad.

Entregue juntos referencia inicial, ubicaciones de fuentes, explicación corregida, resultado del control y criterio de refutación. Los criterios preparados son para una revisión futura, no resultados de aprendizaje aceptados. Respuesta real, historial de ayuda, corrección y decisión permanecen vacíos hasta conservar un intento. Revisión técnica, revisión lingüística, ejecución, adopción productiva y publicación requieren cada una evidencia aplicable. Un cálculo finito correcto establecería solo la operación declarada bajo sus premisas.

## Criterio de refutación previo

El cambio de hemisferio y concordancia del control refuta que eliminar la profundidad conserve esta dirección.

## Criterios de aprendizaje preparados

- Para el ejercicio 1: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 2: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 3: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 4: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.
- Para el ejercicio 5: conservar respuesta correcta, razonamiento intermedio y alcance declarado; la decisión de aprendizaje sigue sin decidirse.

## Fuentes y alcance de las afirmaciones

- [Prerrequisito confirmado: phy-008-keep-surface-normals-perpendicular](../../physics/en/phy-008-keep-surface-normals-perpendicular.md)
- [Fuente de proyecto conservada](../../../../code/blender/scripts/atlas/kit.py)
- [Lectura primaria](https://pbr-book.org/4ed/Geometry_and_Transformations/Spherical_Geometry)
- [Paquete inventado](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-c.json)
- [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
