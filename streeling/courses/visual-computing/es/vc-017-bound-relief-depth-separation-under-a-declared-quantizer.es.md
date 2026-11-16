---
module_id: "vc-017-bound-relief-depth-separation-under-a-declared-quantizer"
department: "visual-computing"
course: "Evaluar la separación del relieve con un cuantizador declarado"
level: "advanced"
prerequisites: ["vc-014-predict-an-embroidered-stitch-pixel-footprint", "inf-005-quantization-and-indistinguishable-renders"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---


# Evaluar la separación del relieve con un cuantizador declarado

> Borrador para revisión técnica y lingüística. El caso es inventado, incluidas entradas numéricas, etiquetas y resultados esperados. No es una prueba artesanal física, una observación de [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html), un render de [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), una ejecución de [ComfyUI](https://github.com/Comfy-Org/ComfyUI) ni un resultado de aprendizaje. Todas las decisiones humanas y del estudiante siguen sin decidirse.

## Pregunta del proyecto

Una arista en relieve puede ocupar píxeles visibles y compartir un código de profundidad con el fondo. La huella en pantalla y la discriminación de profundidad son cuestiones distintas. El prerrequisito sobre pérdida de información ya muestra colisiones de cuantización; esta lección combina proyección inversa y cuantizador finito para estudiar el efecto de los planos de recorte.

Lea el prerrequisito confirmado y el pasaje conservado antes de calcular. Prepare una tabla que separe definición de fuente, premisa inventada, resultado derivado y futura observación propuesta. El paquete registra revisión y alcance de lectura. Un parámetro inspeccionado demuestra que la representación expone ese parámetro; no proporciona un coeficiente material, juicio de visibilidad o tiempo de procesamiento sin medir. Conserve esa distinción cuando un asistente resuma la fuente. La referencia primaria respalda solo el concepto y el pasaje indicados en el registro de lectura.

## Derivar la operación antes de proponer automatización

Nuestra coordenada sitúa el plano cercano en el extremo superior y el lejano en el inferior. Incrementos iguales de distancia producen incrementos desiguales de profundidad codificada. Godot documenta profundidad inversa no lineal y reconstrucción según el renderizador, sin identificar este cuantizador docente con un formato GPU concreto. El pipeline expone parámetros de captura sin elegir esta proyección. Mover el plano cercano también recorta más geometría; aumentar la separación de códigos tiene un coste.

## Modelo inventado fijo y control con entrada modificada

```json
{
  "values": {
    "near_m": 1,
    "far_m": 100,
    "depths_m": [
      10,
      10.1
    ],
    "quantizer_steps": 255
  },
  "formula": "d(z)=(1/z-1/far)/(1/near-1/far); q(z)=floor(steps*d(z)+0.5); separated=q(z1)!=q(z2)",
  "expected": {
    "encoded": [
      0.09090909090909093,
      0.08990899089908992
    ],
    "codes": [
      23,
      23
    ],
    "separated": false
  },
  "negative_control": {
    "values": {
      "near_m": 5,
      "far_m": 100,
      "depths_m": [
        10,
        10.1
      ],
      "quantizer_steps": 255
    },
    "expected": {
      "encoded": [
        0.4736842105263158,
        0.4684731631057843
      ],
      "codes": [
        121,
        119
      ],
      "separated": true
    }
  }
}
```

### Ejercicio 1

Calcule los códigos del caso principal.

<details><summary>Respuesta 1</summary>

Son `[23,23]`; `separated=false`. Profundidades físicas distintas colisionan tras el redondeo declarado.

</details>

### Ejercicio 2

¿Una anchura de puntada visible evita la colisión?

<details><summary>Respuesta 2</summary>

No. El prerrequisito de huella trata la extensión en el plano de imagen; este modelo trata la profundidad almacenada en la dirección de cámara.

</details>

### Ejercicio 3

Aplique el plano cercano modificado.

<details><summary>Respuesta 3</summary>

Los códigos pasan a `[121,119]` y `separated=true`. Las profundidades del relieve no cambian.

</details>

### Ejercicio 4

¿Qué contrapartida acompaña al cambio?

<details><summary>Respuesta 4</summary>

El límite cercano pasa de `1 m` a `5 m`, excluyendo contenido más próximo. La separación de códigos no basta para escoger una cámara.

</details>

### Ejercicio 5

¿Predice el ejemplo un defecto de precisión de Godot?

<details><summary>Respuesta 5</summary>

No. Hay que identificar renderizador, matriz de proyección y formato real del búfer y después medir. El redondeo uniforme finito es una hipótesis inventada.

</details>

## Tarea con consulta de fuentes

Tabule a mano profundidad recíproca, profundidad codificada y código redondeado. Inspeccione los argumentos de captura y el pasaje de Godot sobre profundidad. Indique los campos de cámara y formato que faltan para una futura prueba del relieve.

Empiece con una referencia manual directa: cierre las respuestas, dibuje el esquema o tabla requerido y derive cantidades intermedias con sus unidades. Conserve esa primera respuesta antes de pedir ayuda. Después use la fuente para cuestionar una hipótesis concreta y guarde la pregunta, ubicación consultada, ayuda recibida y sugerencias rechazadas. Compare la respuesta asistida con su cálculo original para la misma tarea y entradas. Una explicación más breve no demuestra mejora si pierde una condición de contorno o inventa una observación.

Aplique el control estructurado como caso separado, sin modificar las entradas principales en su lugar. Registre cambios e invariantes y determine si una discrepancia afecta al cálculo, la interpretación o las premisas. Conserve por separado cada intento fallido y su corrección. El paquete prepara un criterio por ejercicio corregido; cada decisión de aprendizaje permanece null hasta conservar y revisar un intento real. Consultar fuentes o una respuesta preparada no demuestra que el estudiante haya realizado la tarea. No se necesita ningún DSL nuevo, flujo de agentes, adaptador de escena ni integración de producción para completar este ejercicio en papel.

## Criterio de refutación previo

La afirmación de que profundidades distintas siempre siguen siendo distinguibles tras almacenarse falla con la pareja de códigos iguales; una afirmación de ejecución exigiría además medir el búfer.

## Fuentes y límite de validación

- [Prerrequisito ya confirmado: vc-014-predict-an-embroidered-stitch-pixel-footprint](../../visual-computing/en/vc-014-predict-an-embroidered-stitch-pixel-footprint.md)

- [Prerrequisito ya confirmado: inf-005-quantization-and-indistinguishable-renders](../../information-theory/en/inf-005-quantization-and-indistinguishable-renders.md)

- [Fuente de proyecto conservada](../../../../code/blender/scripts/glb_pipeline.py)

- [Lectura primaria](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html)

- [Paquete inventado fijo](../../../../code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
