---
title: '3. Los workflows en JSON: el formato de la interfaz, el formato de la API y los diffs'
description: 'Los dos formatos JSON de un grafo de ComfyUI — el workflow que guarda el frontend, con posiciones, tablas de enlaces y valores de widgets por posición, y el prompt que ejecuta el servidor —, convertidos de uno a otro en C# byte a byte como lo hace el frontend, los metadatos que ComfyUI escribe en los archivos PNG, un workflow validado sin conexión frente a /object_info y por el servidor, y diffs que ignoran la disposición.'
sidebar:
  order: 3
---

Código: los tres archivos JSON del grafo de la lección 1 en [`workflows/`](https://github.com/spareilleux/learn/tree/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/workflows), la conversión, la validación y el diff en [`csharp/Workflow.cs`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/csharp/Workflow.cs), el lector de PNG en [`csharp/Png.cs`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/csharp/Png.cs), y las definiciones de nodos que usan en [`data/object_info.json`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/data/object_info.json).

## Dos formatos para un mismo grafo

ComfyUI guarda un grafo en dos formatos JSON, y te encontrarás con los dos.

- **El workflow**, o formato de la interfaz, es lo que guarda el frontend con File → Save, lo que arrastras al navegador y lo que son las plantillas de workflows. Describe el dibujo: dónde está cada nodo, de qué tamaño, qué enlaces conectan qué ranuras, y los valores de los widgets.
- **El prompt**, o formato de la API, es lo que ejecuta el servidor. El frontend lo construye cuando pulsas Run, y File → Export Workflow (API) lo guarda. Solo tiene tipos de nodo, entradas y enlaces.

La [página del formato de la API](https://docs.comfy.org/development/api-development/workflow-api-format) lo expresa así: "API format omits UI metadata (positions, colors, groups, node sizes) that is only needed for visual editing in the frontend." La tabla de esa misma página dice que el formato guardado usa como clave de los nodos "Node titles or labels"; en realidad, los dos formatos usan el id numérico del nodo, como muestran los archivos de abajo.

Para obtener un par real, el curso cargó el archivo de la API de la lección 1 en el frontend, versión 1.52.7, y dejó que el frontend exportara los dos formatos, desde la consola JavaScript del navegador:

```js
await app.loadApiJson(apiWorkflow, '01-txt2img');
const { workflow, output } = await app.graphToPrompt();
```

`workflow` se convirtió en [`01-txt2img.ui.json`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/workflows/01-txt2img.ui.json), de 6.660 bytes, y `output` en [`01-txt2img.exported.api.json`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/workflows/01-txt2img.exported.api.json), de 1.792 bytes. `app` es el objeto global del frontend; estas dos funciones son las que llaman sus menús, pero no son una API documentada, así que las entradas de menú son la vía estable.

| | Workflow (formato de la interfaz) | Prompt (formato de la API) |
|---|---|---|
| Nivel superior | un objeto con `nodes`, `links`, `groups`, `extra` y `version` | un objeto cuyas claves son ids de nodo |
| Un nodo | `id`, `type`, `pos`, `size`, `order`, `mode`, `inputs`, `outputs`, `widgets_values` | `class_type`, `inputs` y `_meta.title` |
| Un valor de widget | por posición, en `widgets_values` | por nombre, en `inputs` |
| Un enlace | una fila de la tabla `links` de nivel superior, referenciada por id desde los dos nodos | `["4", 1]` en la entrada que lo recibe |
| Nodos exclusivos del frontend, como las notas | se conservan | se descartan |
| Esquema | [workflow JSON 0.4](https://docs.comfy.org/specs/workflow_json_0.4), y una [1.0](https://docs.comfy.org/specs/workflow_json) más reciente | ninguno publicado; lo define la validación del servidor |

## El formato del workflow

Este es el nodo `KSampler` en el archivo de la interfaz, sin su `widgets_values_named`, del que se habla más abajo:

```json
{
  "id": 3,
  "type": "KSampler",
  "pos": [970, 130],
  "size": [270, 262],
  "flags": {},
  "order": 4,
  "mode": 0,
  "inputs": [
    { "name": "model", "type": "MODEL", "link": 10 },
    { "name": "positive", "type": "CONDITIONING", "link": 11 },
    { "name": "negative", "type": "CONDITIONING", "link": 12 },
    { "name": "latent_image", "type": "LATENT", "link": 13 }
  ],
  "outputs": [
    { "name": "LATENT", "type": "LATENT", "links": [16] }
  ],
  "properties": { "Node name for S&R": "KSampler" },
  "widgets_values": [42, "randomize", 25, 7, "euler", "normal", 1]
}
```

Y la tabla `links`, donde cada fila es `[link id, origin node, origin slot, target node, target slot, type]`:

```json
[[10, 4, 0, 3, 0, "MODEL"], [11, 6, 0, 3, 1, "CONDITIONING"], [12, 7, 0, 3, 2, "CONDITIONING"],
 [13, 5, 0, 3, 3, "LATENT"], [14, 4, 1, 6, 0, "CLIP"], [15, 4, 1, 7, 0, "CLIP"],
 [16, 3, 0, 8, 0, "LATENT"], [17, 4, 2, 8, 1, "VAE"], [18, 8, 0, 9, 0, "IMAGE"]]
```

Tres cosas sorprenden a un desarrollador que espera un formato de datos:

- **Los enlaces se guardan en tres sitios.** El enlace 10 es una fila de `links`, un id en la entrada `model` del nodo 3 y un id en la salida `MODEL` del nodo 4. Una herramienta que modifique uno de esos sitios debe modificar los otros.
- **Los valores de los widgets van por posición.** `widgets_values` tiene siete elementos para seis entradas de tipo widget. El segundo, `"randomize"`, es el widget *control after generate* que el frontend añade tras cualquier semilla: después de cada ejecución, cambia la semilla por un número aleatorio, o le suma o le resta uno. El servidor nunca lo ve.
- **La disposición es un dato.** Mueve un nodo un píxel y `pos` cambia. Un diff de control de versiones de archivos de la interfaz mezcla los cambios de disposición con los cambios que importan.

La exportación también tiene un objeto `widgets_values_named` junto a `widgets_values`, con los mismos valores por nombre. El esquema no lo menciona, y el conversor del curso no lo usa.

## Del workflow al prompt

Convertir significa resolver cada id de enlace a través de la tabla `links` y dar nombre a cada valor de widget. Los nombres vienen del servidor: `/object_info` lista las entradas de cada nodo, en orden, bajo `input_order`. El conversor en C# del curso sigue las reglas del frontend, en [`Workflow.FromUi`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/csharp/Workflow.cs):

```csharp
var values = new Queue<JsonNode?>(node["widgets_values"] as JsonArray ?? []);
var order = definition["input_order"]?["required"]?.AsArray().Concat(definition["input_order"]?["optional"]?.AsArray() ?? []) ?? [];
foreach (string name in order.Select(n => n!.GetValue<string>()))
{
    var spec = InputSpec(definition, name)!;
    if (!IsWidget(spec) || values.Count == 0) continue;
    inputs[name] = values.Dequeue()?.DeepClone();
    // A seed has a second widget, "control after generate", that the server never sees.
    if (spec.Count > 1 && spec[1]?["control_after_generate"]?.GetValue<bool>() == true && values.Count > 0)
        values.Dequeue();
}
foreach (var input in (node["inputs"] as JsonArray ?? []).Select(i => i!.AsObject()))
    if (input["link"]?.GetValue<int>() is int linkId)
    {
        var (origin, slot) = links[linkId];
        inputs[input["name"]!.GetValue<string>()] = new JsonArray(origin.ToString(), slot);
    }
```

Una entrada es un widget cuando su tipo es `INT`, `FLOAT`, `STRING`, `BOOLEAN` o una lista de opciones. `seed` se declara con `"control_after_generate": true` en [`nodes.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py#L1603), y así sabe el conversor que debe saltarse el valor siguiente.

`check.sh` ejecuta el conversor sobre el archivo de la interfaz y compara su salida con la exportación del frontend: son los mismos bytes, salvo los finales de línea. El conversor es pequeño a propósito. Rechaza los nodos reroute, los nodos primitivos, los nodos desactivados y los subgrafos, que una herramienta real tendría que tratar; para esos casos, deja que el frontend haga la exportación.

El archivo escrito a mano y la exportación del frontend no tienen los mismos bytes: la exportación añade `_meta.title`, ordena las claves de otra forma y escribe `7` donde el archivo tenía `7.0`. El comando `diff` del curso compara lo que usa el servidor, los tipos de nodo y las entradas, y trata los números como números:

```text
> comfy diff workflows/01-txt2img.api.json workflows/01-txt2img.exported.api.json
same nodes and inputs
```

Ese es el diff que hay que poner en una revisión de código. Conserva el archivo de la interfaz si la gente edita el grafo en el navegador, pero revisa los cambios sobre el formato de la API, donde una semilla cambiada es una línea cambiada:

```text
> comfy diff workflows/01-txt2img.api.json workflows/03-broken.api.json
~ 3.steps: 25 -> 0
~ 3.sampler_name: "euler" -> "euler_a"
~ 3.negative: ["7",0] -> ["12",0]
~ 3.latent_image: ["5",0] -> ["4",2]
4 differences
```

## Validar un workflow

[`03-broken.api.json`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/workflows/03-broken.api.json) es el workflow de la lección 1 con cuatro errores: esas cuatro líneas del diff. El comando `validate` del curso comprueba lo que puede sin conexión. Sin definiciones de nodos, comprueba la estructura: cada nodo tiene un `class_type`, cada enlace apunta a un nodo existente, y no hay ciclos. Con las definiciones guardadas desde el `/object_info` de un servidor, comprueba lo mismo que el servidor: tipos de nodo conocidos, entradas obligatorias, rangos de valores y opciones, y que el tipo de salida de cada enlace es el que espera la entrada.

```text
> comfy validate workflows/03-broken.api.json data/object_info.json
error: node 4 (CheckpointLoaderSimple) input ckpt_name: "sd_xl_base_1.0.safetensors" is not one of the 0 allowed values
error: node 3 (KSampler) input steps: 0 is below the minimum 1
error: node 3 (KSampler) input sampler_name: "euler_a" is not one of the 45 allowed values
error: node 3 (KSampler) input negative: links to node 12, which doesn't exist
error: node 3 (KSampler) input latent_image: expects LATENT, node 4 output 2 is VAE
```

El primer error no es uno de los cuatro: `data/object_info.json` se guardó desde el servidor de la CI, que no tiene ningún modelo, así que la lista de nombres de checkpoint permitidos está vacía. El propio servidor dice lo mismo, ya que las opciones de una entrada de tipo combo son los archivos que encuentra en el disco. Con un grafo válido, `validate` también imprime un orden en el que pueden ejecutarse los nodos:

```text
> comfy validate workflows/01-txt2img.api.json
valid; the nodes can run in this order: 4 5 6 7 3 8 9
```

Enviado al servidor, el workflow roto se rechaza con un HTTP 400:

```json
{"error": {"type": "prompt_outputs_failed_validation", "message": "Prompt outputs failed validation", "details": "", "extra_info": {}},
 "node_errors": {
  "4": {"errors": [{"type": "value_not_in_list", "message": "Value not in list",
        "details": "ckpt_name: 'sd_xl_base_1.0.safetensors' not in []", …}], "dependent_outputs": ["9"], "class_type": "CheckpointLoaderSimple"},
  "3": {"errors": [{"type": "exception_during_inner_validation", "message": "Exception when validating inner node",
        "details": "'12'", "extra_info": {…, "exception_type": "KeyError", "traceback": ["  File \"C:\\Users\\…\\ComfyUI\\execution.py\", line 933, in validate_inputs\n    o_class_type = prompt[o_id]['class_type']\n…"]}}], …}}}
```

El servidor informó de dos errores donde la comprobación sin conexión encontró cinco, y el segundo es extraño: está archivado bajo el nodo 3, pero su `extra_info` nombra la entrada `samples` y el nodo enlazado `["3", 0]`, que es la entrada del nodo 8. El código lo explica. El servidor valida desde cada nodo de salida, remontando sus enlaces. Para una entrada enlazada, [`validate_inputs`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py#L933) lee `prompt[o_id]['class_type']` antes de su bloque `try`, así que el enlace del nodo 3 al nodo 12, que no existe, lanzó un `KeyError` que escapó a la validación del nodo 3. El nodo 8, `VAEDecode`, lo capturó al validar su entrada `samples`, y [lo guardó como resultado del nodo 3](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py#L962-L979). Las demás entradas del nodo 3 no llegaron a comprobarse, o solo algunas: `validate_inputs` recorre las entradas de un nodo en el orden de un conjunto de Python ([línea 896](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py#L896)), que cambia de un arranque del servidor a otro. La respuesta incluye además una traza de Python con la ruta de instalación del servidor, un motivo más para no exponer el puerto. Validar primero sin conexión da una lista de errores mejor; la respuesta del servidor sigue siendo la que decide.

## Los metadatos de los archivos PNG

Un archivo PNG es una firma y una lista de chunks, cada uno con una longitud, un tipo de cuatro letras, unos datos y un CRC-32 ([especificación de PNG](https://www.w3.org/TR/png-3/#11tEXt)). `SaveImage` añade un chunk `tEXt` para el prompt, y uno por cada clave que el cliente envió en `extra_pnginfo`, en [`nodes.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py#L1701-L1707):

```python
metadata = PngInfo()
if prompt is not None:
    metadata.add_text("prompt", json.dumps(prompt))
if extra_pnginfo is not None:
    for x in extra_pnginfo:
        metadata.add_text(x, json.dumps(extra_pnginfo[x]))
```

El frontend envía el workflow de la interfaz en `extra_pnginfo`; los clientes de la API de este curso no lo hacen. El `prompt` es el que validó el servidor, y la validación reescribe los valores convertidos: el `"cfg": 7.0` de abajo viene de un frontend que envió `7`, convertido por `float(val)` ([`execution.py`, línea 995](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py#L995-L997)). Así que una imagen encolada desde el navegador tiene dos chunks de texto, y una encolada a través de la API tiene uno:

```text
> comfy png-info output/l01/metronome_00001_.png
chunk IHDR: 1 x, 13 bytes
chunk tEXt: 1 x, 921 bytes
chunk IDAT: 23 x, 3146752 bytes once inflated
chunk IEND: 1 x, 0 bytes
text prompt: 914 characters: {"4": {"class_type": "CheckpointLoaderSimple", "inputs": {"c...
image: 1024 x 1024, 3 channels, pixel SHA-256 698e7867e7fc04fb

> comfy png-info output/l03/from-ui_00001_.png
chunk IHDR: 1 x, 13 bytes
chunk tEXt: 2 x, 4886 bytes
chunk IDAT: 23 x, 3146752 bytes once inflated
chunk IEND: 1 x, 0 bytes
text prompt: 1191 characters: {"3": {"inputs": {"seed": 42, "steps": 25, "cfg": 7.0, "samp...
text workflow: 3679 characters: {"id": "00000000-0000-0000-0000-000000000000", "revision": 0...
image: 1024 x 1024, 3 channels, pixel SHA-256 5374ac40a393cf78
```

El lector en C# de [`Png.cs`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/csharp/Png.cs) comprueba el CRC de cada chunk, lee los chunks `tEXt` e `iTXt`, y decodifica él mismo los píxeles, con `ZLibStream` y los cinco filtros de fila de PNG, para que el hash cubra los píxeles y no los bytes del archivo. La línea IDAT muestra por qué. En la primera ejecución de la CI, la misma imagen de 64 × 48 ocupaba 84 bytes comprimidos en Linux y 88 en Windows y macOS: lo más probable es que la biblioteca zlib que usa Pillow difiera entre las builds de cada plataforma. El tamaño descomprimido, 9.264 bytes, es el mismo en todas partes, y los píxeles también.

Dos advertencias sobre estos metadatos:

- **Viajan con la imagen.** Un PNG que publicas lleva tu prompt, tu prompt negativo, el nombre de archivo del modelo y tu configuración de nodos. Arranca el servidor con `--disable-metadata`, o elimina los chunks, cuando eso importe.
- **No prueban nada.** La [página de metadatos](https://docs.comfy.org/development/api-development/workflow-metadata) lo dice claramente: "Embedded metadata is not a digital signature. It does not prove who created or modified a file." Cualquiera puede escribir cualquier prompt en un PNG.

El PNG encolado desde el navegador también muestra el widget de control en acción. Su chunk `workflow` registra la semilla 42, el valor que tenía al pulsar Run; justo después de encolar, el frontend sustituyó la semilla por 140956311522585, así que pulsar Run una segunda vez no habría producido la misma imagen.

## Puntos clave

- El formato de la interfaz describe un dibujo: posiciones, valores de widgets por posición, y enlaces guardados en una tabla y en los dos nodos. El formato de la API solo tiene tipos de nodo, entradas con nombre y enlaces.
- Convertir requiere las definiciones de nodos de `/object_info`, para los nombres y el orden de las entradas, y debe saltarse los valores de control after generate. El conversor en C# del curso reproduce byte a byte la exportación del frontend en un grafo sencillo.
- Revisa los cambios de workflows sobre el formato de la API, con un diff que compare los tipos de nodo y las entradas.
- Valida sin conexión para obtener una lista completa de errores; el servidor se detiene en el primer problema de un nodo, y puede responder con una traza.
- Los archivos PNG llevan el prompt, y también el workflow cuando se encolan desde el navegador. Calcula el hash de los píxeles, no de los archivos.

## Tu turno

Construye un grafo pequeño en el navegador — un checkpoint, dos indicaciones, un muestreador, un guardado — y expórtalo en los dos formatos. Convierte el archivo de la UI con el conversor del curso y compara el resultado con la exportación API del propio frontend: deben coincidir. Rómpelo después a propósito, con un enlace a un nodo que ya no existe o un `steps` de `-1`, y compara lo que enumera el validador sin conexión con lo que responde el servidor cuando lo pones en cola.

## Ejercicios

1. Añade un segundo nodo `SaveImage` a `01-txt2img.api.json`, alimentado por el nodo `VAEDecode`, con el prefijo `l03/copy`. Ejecuta `comfy validate` sobre él: ¿qué orden imprime?
2. En `03-broken.api.json`, corrige todo salvo el enlace al nodo 12, y envíalo a un servidor en marcha. ¿Qué errores indica ahora el servidor?
3. El nodo 9 del archivo de la interfaz tiene `"outputs": [{"name": "images", "type": "IMAGE", "links": null}]`. `SaveImage` es un nodo de salida; ¿por qué tiene una salida? Mira su `RETURN_TYPES` en [`nodes.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py#L1660-L1720) y `/object_info/SaveImage`.

<details>
<summary>Solución 1</summary>

```json
  "10": {
    "class_type": "SaveImage",
    "inputs": { "filename_prefix": "l03/copy", "images": ["8", 0] }
  }
```

`valid; the nodes can run in this order: 4 5 6 7 3 8 10 9`. El comando ordena por id, como cadenas, los nodos que están listos a la vez, así que `10` va antes que `9`. Los dos nodos de salida solo dependen del nodo 8, así que cualquiera de los dos órdenes es correcto. El servidor elige su propio orden, y la lección 4 muestra que cambia de un arranque a otro.

</details>

<details>
<summary>Solución 2</summary>

Con el checkpoint presente en el servidor, `steps` de nuevo en 25, `sampler_name` en `euler` y `latent_image` en `["5", 0]`, solo `negative` sigue apuntando al nodo 12. Enviado tres veces a un servidor con el archivo de SDXL en su carpeta de modelos, obtuvo la misma respuesta cada vez: HTTP 400 con una sola entrada en `node_errors`, para el nodo 3, de tipo `exception_during_inner_validation`, con los detalles `'12'`, el nombre de entrada `samples` y una traza de `KeyError`. El tipo de error describe un fallo del código de validación, no un nodo que falta, y la entrada que nombra es la del nodo 8, así que un cliente que solo muestre `type` a sus usuarios también debería mostrar `details`.

</details>

<details>
<summary>Solución 3</summary>

`SaveImage` declara `RETURN_TYPES = ("IMAGE",)` y su método `save_images` devuelve `{"ui": {"images": results}, "result": (images,)}`: la parte `ui` es lo que el servidor envía a los clientes y guarda en el historial, y `result` transmite las imágenes, para que otro nodo pueda usarlas después de guardarlas. `/object_info/SaveImage` muestra `"output": ["IMAGE"]` y `"output_node": true`. El frontend dibuja la ranura de salida; `"links": null` significa que no hay nada conectado a ella.

</details>

## Fuentes

- Documentación de ComfyUI: [formato de workflow de la API](https://docs.comfy.org/development/api-development/workflow-api-format), especificaciones [workflow JSON 0.4](https://docs.comfy.org/specs/workflow_json_0.4) y [1.0](https://docs.comfy.org/specs/workflow_json), [metadatos de workflows](https://docs.comfy.org/development/api-development/workflow-metadata), [SaveImage](https://docs.comfy.org/built-in-nodes/SaveImage).
- ComfyUI en la v0.36.0: [`nodes.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py), [`execution.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py), [`comfy_execution/graph_utils.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy_execution/graph_utils.py#L1-L10).
- W3C, [Portable Network Graphics (PNG) Specification (Third Edition)](https://www.w3.org/TR/png-3/).
- .NET: [`System.Text.Json.Nodes`](https://learn.microsoft.com/dotnet/api/system.text.json.nodes), [`ZLibStream`](https://learn.microsoft.com/dotnet/api/system.io.compression.zlibstream).
