---
title: '5. Img2img, inpainting y outpainting'
description: 'Partir de una imagen en lugar de ruido — subirla por la API, qué cambia realmente denoise en la planificación del ruido, tres formas de repintar parte de una imagen con SDXL y lo que cada una hace con los píxeles enmascarados, volver a pegar el resultado para que el resto de la imagen quede intacto, y ampliar un lienzo —, con los renders comparados en una GPU y los nodos de máscara comprobados en la CI.'
sidebar:
  order: 5
---

Código: los workflows [`05-img2img.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-img2img.api.json), [`05-inpaint-vaeencode.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-vaeencode.api.json), [`05-inpaint-noisemask.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-noisemask.api.json), [`05-inpaint-model.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-model.api.json) y [`05-outpaint.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-outpaint.api.json); la subida en [`csharp/ComfyClient.cs`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/csharp/ComfyClient.cs), la imagen de máscara en [`csharp/Images.cs`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/csharp/Images.cs), y el workflow que la CI ejecuta sin modelo en [`05-masks.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-masks.api.json).

Las lecciones 1 a 4 empezaban cada imagen a partir de un latente vacío, y `KSampler` lo llenaba de ruido. Esta lección le da al sampler una imagen existente. El punto de partida es el metrónomo de la lección 1, con la semilla 42, y todos los renders siguientes usan SDXL base 1.0 o su variante de inpainting.

## Enviar una imagen al servidor

Un workflow no puede leer un archivo del disco del cliente. `LoadImage` lee de la carpeta `input` del servidor, así que un cliente sube primero el archivo con `POST /upload/image`: un formulario multipart con el archivo en una parte llamada `image`, y los campos opcionales `subfolder`, `type` y `overwrite` ([`server.py`, líneas 397 a 467](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py#L397-L467)). La respuesta da el nombre que hay que poner en la entrada `image` de `LoadImage`. El cliente del curso hace las dos cosas con una sola opción:

```text
comfy run http://127.0.0.1:8188 workflows/05-img2img.api.json --image 10.image=metronome.png
```

La documentación no dice qué ocurre cuando un nombre ya está ocupado. La CI sube dos veces el mismo archivo, luego un archivo distinto con el mismo nombre, luego ese mismo otra vez con `overwrite`, y después un archivo en `../outside`:

```text
POST /upload/image pattern-hole.png: 200, name pattern-hole.png, subfolder "", type input
POST /upload/image pattern-hole.png: 200, name pattern-hole (1).png, subfolder "", type input
POST /upload/image pattern-hole.png: 200, name pattern-hole.png, subfolder "", type input
HttpRequestException: POST /upload/image: 400 
```

La primera línea es la segunda subida de bytes idénticos: el servidor compara un hash y conserva el archivo existente ([líneas 423 a 432](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py#L423-L432)). Unos bytes distintos reciben un nombre nuevo, y un cliente que dé por hecho su propio nombre de archivo leería la imagen antigua. `overwrite` reemplaza el archivo. Una subcarpeta que sale de la carpeta de entrada se rechaza.

### La máscara es la parte transparente

`LoadImage` tiene dos salidas: la imagen, y una máscara calculada a partir de su canal alfa como `1 - alpha` ([`nodes.py`, líneas 1784 a 1790](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py#L1784-L1790)). Los píxeles transparentes son los que hay que repintar. Una imagen sin canal alfa da una máscara de ceros, de 64 por 64 píxeles sea cual sea el tamaño de la imagen. La herramienta del curso crea la entrada de esta lección, en lugar de un editor de imágenes: `comfy cut` copia una imagen y vuelve transparente una elipse, aquí alrededor de los pequeños objetos de la parte delantera derecha del banco de trabajo.

```text
comfy cut metronome.png metronome-hole.png 850 860 120 80
metronome-hole.png: 1024 x 1024, 30176 transparent pixels, pixel SHA-256 051cb95373b4342f
```

Una máscara pintada en blanco sobre negro en un editor de imágenes no tiene canal alfa. [`LoadImageMask`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py#L1815-L1856) la lee con `channel` a `red`, `green` o `blue`, y usa ese canal tal cual; con `channel` a `alpha`, lo invierte como `LoadImage`.

## Img2img: denoise

El img2img codifica la imagen con el VAE y pasa ese latente a `KSampler` en lugar de uno vacío. `denoise` decide entonces cuánto de la imagen sobrevive. La lección 2 describió el muestreo como una planificación de niveles de ruido que va de alto a cero. Con `denoise` por debajo de 1, [`set_steps`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/samplers.py#L1431-L1441) calcula una planificación más larga y solo conserva su final:

```python
new_steps = int(steps/denoise)
sigmas = self.calculate_sigmas(new_steps).to(self.device)
self.sigmas = sigmas[-(steps + 1):]
```

Así que `denoise` no reduce el trabajo: con 25 pasos y `denoise` 0,5, ComfyUI construye una planificación de 50 pasos y ejecuta sus 25 últimos pasos, empezando por un nivel de ruido a mitad de camino. La barra de progreso del servidor mostró 25 pasos para cada valor, y los tiempos fueron los mismos:

| denoise | Tiempo, con los modelos cargados |
|---|---|
| 0,3 | 5,13 s |
| 0,5 | 4,63 s |
| 0,7 | 4,68 s |
| 0,9 | 4,88 s |

![Cinco imágenes una al lado de la otra. La primera es la fotografía de la lección 1 de un objeto de latón parecido a un reloj de arena sobre un banco de trabajo. Las cuatro siguientes son versiones parecidas a una acuarela: con denoise 0,3 y 0,5 la composición es idéntica y cambia el estilo; con 0,7 la ventana y las herramientas empiezan a moverse; con 0,9 el objeto es más sencillo, las herramientas son distintas y la ventana tiene otra forma.](../../../../assets/comfyui/l05-img2img.webp)

*Renderizado por ComfyUI v0.36.0: Stable Diffusion XL base 1.0, semilla 42, 25 pasos, CFG 7, `euler`, `normal`, workflow [`05-img2img.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-img2img.api.json) con el prompt "a watercolor painting of a brass metronome on an old wooden workbench, morning light through a window". De izquierda a derecha: la imagen de partida, y después `denoise` 0,3, 0,5, 0,7 y 0,9.*

Con 0,3 y 0,5, el sampler empieza lo bastante tarde como para que solo cambien las texturas y los colores. Con 0,9 empieza casi desde ruido puro, y solo queda la distribución aproximada de luces y sombras.

## Inpainting, de tres formas

El inpainting repinta la parte enmascarada y conserva el resto. ComfyUI tiene tres formas de hacerlo con SDXL, y no hacen lo mismo con los píxeles enmascarados.

| Workflow | Nodos | De qué parte el sampler |
|---|---|---|
| `05-inpaint-vaeencode` | `VAEEncodeForInpaint`, modelo base | la imagen con los píxeles enmascarados en gris medio, `denoise` 1 |
| `05-inpaint-noisemask` | `VAEEncode`, `SetLatentNoiseMask`, modelo base | la imagen sin cambios, con una máscara de ruido |
| `05-inpaint-model` | `InpaintModelConditioning`, UNet de inpainting de SDXL | la imagen sin cambios, y la imagen en gris y la máscara como entradas adicionales del modelo |

[`VAEEncodeForInpaint`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py#L412-L450) sustituye los píxeles enmascarados por gris antes de codificar, y redondea la máscara a 0 o 1:

```python
m = (1.0 - mask.round()).squeeze(1)
for i in range(3):
    pixels[:,:,:,i] -= 0.5
    pixels[:,:,:,i] *= m
    pixels[:,:,:,i] += 0.5
```

Su entrada `grow_mask_by` solo amplía la máscara de ruido, no la zona gris. Ni el [tutorial de inpainting](https://docs.comfy.org/tutorials/basic/inpaint) ni la página del nodo mencionan el gris.

La máscara de ruido es la forma en que el sampler conserva el resto de la imagen. En cada paso, [`KSamplerX0Inpaint`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/samplers.py#L634-L643) pone fuera de la máscara el latente original, con el ruido del nivel actual, y lo vuelve a poner en la salida del modelo:

```python
x = x * denoise_mask + self.inner_model.inner_model.scale_latent_inpaint(x=x, sigma=sigma, noise=self.noise, latent_image=self.latent_image, denoise_mask=denoise_mask) * latent_mask
out = self.inner_model(x, sigma, model_options=model_options, seed=seed)
if denoise_mask is not None:
    out = out * denoise_mask + self.latent_image * latent_mask
```

El modelo base nunca se ha entrenado para rellenar un hueco: elimina el ruido de todo el latente, y la máscara descarta lo que hizo fuera. El modelo [SD-XL inpainting 0.1](https://huggingface.co/diffusers/stable-diffusion-xl-1.0-inpainting-0.1) es una UNet entrenada para ello, con "5 additional input channels (4 for the encoded masked-image and 1 for the mask itself)". Ocupa 5,1 GB en fp16, bajo la licencia CreativeML Open RAIL++-M como SDXL, y su ficha dice "The model is intended for research purposes only." No tiene codificadores de texto ni VAE propios, así que el workflow lo carga con `UNETLoader` y toma el resto del checkpoint de SDXL. ComfyUI lo reconoce por sus 9 canales de entrada ([`model_detection.py`, líneas 1465 a 1469](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/model_detection.py#L1465-L1469)). [`InpaintModelConditioning`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py#L453-L502) construye esas entradas adicionales: pone en gris los píxeles enmascarados como `VAEEncodeForInpaint`, codifica eso como latente adicional, y devuelve la imagen **original** codificada como el latente que hay que muestrear.

El ejemplo de la ficha del modelo fija `strength=0.99`, con el comentario "make sure to use `strength` below 1.0", que en ComfyUI es `denoise`.

![Seis recortes de la parte delantera derecha del banco de trabajo, cada uno de 340 por 240 píxeles. El original tiene dos pequeños objetos de madera. VAEEncodeForInpaint: los objetos han desaparecido, y una elipse pálida con otra textura de madera muestra dónde estaba la máscara. Máscara de ruido con denoise 1: una franja azulada y plana y una pequeña mancha blanca dentro de una elipse visible. Máscara de ruido con denoise 0,8: los dos objetos siguen ahí, más oscuros y más duros, con un contorno oscuro. Modelo de inpainting con denoise 0,99: una campanilla de latón tumbada de lado y una pieza de madera redonda, con la misma luz que el resto del banco.](../../../../assets/comfyui/l05-inpaint.webp)

*Renderizado por ComfyUI v0.36.0: Stable Diffusion XL base 1.0, y la UNet SD-XL inpainting 0.1 para el último recorte; semilla 42, 25 pasos, CFG 7, `euler`, `normal`, prompt "a small brass bell on an old wooden workbench, morning light through a window, photograph". De izquierda a derecha: el original, [`05-inpaint-vaeencode`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-vaeencode.api.json), [`05-inpaint-noisemask`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-noisemask.api.json) con `denoise` 1 y 0,8, y [`05-inpaint-model`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-model.api.json) con `denoise` 0,99. Cada recorte es el resultado pegado de nuevo en el original.*

- `VAEEncodeForInpaint` borró los objetos. El sampler partió de una mancha gris y pintó madera lisa, y el borde de la máscara se ve como un cambio de textura.
- El modelo base con una máscara de ruido y `denoise` 1 no tenía nada en qué apoyarse dentro de la máscara, y pintó algo que no encaja ni con el prompt ni con el banco.
- Con `denoise` 0,8, el mismo workflow conservó la forma de los objetos, y solo cambió su tono.
- El modelo de inpainting es el único que dibujó algo nuevo, una campanilla tumbada de lado, con la luz de la escena.

El mismo workflow con `denoise` 1,0 en lugar de 0,99 dio casi la misma imagen: una diferencia media de 0,016 niveles, y un 0,01 % de los píxeles en más de 8. La advertencia de la ficha no se notó en esta imagen.

## Volver a pegar el resultado

Un VAE no devuelve los píxeles que se le dieron. Todos los workflows anteriores decodifican una imagen completa de 1024 por 1024, incluida la parte fuera de la máscara. El comando `compare` del curso cuenta solo los píxeles opacos de una imagen de máscara, así que puede medir esa parte:

```text
> comfy compare metronome.png inpaint-model_00001_.png --outside metronome-hole.png
identical pixels: no
compared: 1018400 opaque pixels of the mask
largest difference: 160 of 255, mean 1.888
pixels that differ: 96.34 %, by more than 8: 6.20 %

> comfy compare metronome.png inpaint-model-composite_00001_.png --outside metronome-hole.png
identical pixels: yes
compared: 1018400 opaque pixels of the mask
largest difference: 0 of 255, mean 0.000
pixels that differ: 0.00 %, by more than 8: 0.00 %
```

La imagen decodificada cambió un 6,2 % de los píxeles que nadie pidió repintar, sobre todo en los bordes y en las texturas finas. La ficha de SD-XL inpainting también lo advierte: "The autoencoding part of the model is lossy." Por eso cada workflow termina con [`ImageCompositeMasked`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy_extras/nodes_mask.py#L80-L104), que toma los píxeles decodificados dentro de la máscara y los originales fuera. Los dos nodos SaveImage de cada workflow guardan ambas versiones.

## Outpainting

El outpainting es inpainting sobre un lienzo más grande. [`ImagePadForOutpaint`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py#L2003-L2065) añade un borde relleno de gris, y devuelve una máscara que vale 1 en el borde y 0 en la imagen original. Con `feathering`, la máscara también sube dentro del original, cerca de los lados añadidos, para que el sampler pueda cambiar una franja de los píxeles antiguos y no se vea la costura. Se salta el difuminado cuando la imagen tiene menos del doble de anchura o de altura que el ancho del difuminado ([línea 2044](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py#L2044)).

![Una imagen ancha, de 1536 por 1024 píxeles reducida: el objeto de latón sobre su banco de trabajo en el centro, con un taller añadido a ambos lados: estanterías y una lámpara a la izquierda, la ventana prolongada y un tornillo de banco a la derecha.](../../../../assets/comfyui/l05-outpaint.webp)

*Renderizado por ComfyUI v0.36.0: UNet SD-XL inpainting 0.1 con los codificadores de texto y el VAE de SDXL base 1.0, semilla 42, 25 pasos, CFG 7, `euler`, `normal`, `denoise` 0,99, workflow [`05-outpaint.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-outpaint.api.json): 256 píxeles añadidos a la izquierda y a la derecha, difuminado de 40.*

El servidor tardó 14,7 segundos para esta imagen de 1536 por 1024, frente a 8,0 segundos para el mismo modelo a 1024 por 1024. La máscara difuminada es un degradado, y solo `InpaintModelConditioning` y `SetLatentNoiseMask` lo conservan: `VAEEncodeForInpaint` la redondea a 0 o 1, lo que convierte el difuminado en un borde duro.

## Qué comprueba la CI

La subida y los nodos de máscara no necesitan modelo. La CI crea un patrón de prueba de 64 por 48 con una elipse transparente, lo sube y ejecuta [`05-masks.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-masks.api.json) en la CPU: la máscara de `LoadImage`, `ImagePadForOutpaint`, `ImageCompositeMasked`, y el nodo `Canny` de la lección 6. Compara los hashes de píxeles de las otras cuatro salidas en Linux, Windows y macOS:

```text
GET /view node 5: ci/padded_00001_.png, 96 x 56, pixel SHA-256 7ecd793c72d18001
GET /view node 7: ci/padded-mask_00001_.png, 96 x 56, pixel SHA-256 85051ce419e3c75f
GET /view node 3: ci/mask_00001_.png, 64 x 48, pixel SHA-256 7d894dc1b0ac1189
GET /view node 10: ci/composite_00001_.png, 64 x 48, pixel SHA-256 8b6753a52c0f4a66
```

Leída con Pillow, la máscara vale 255 dentro de la elipse y 0 fuera, con una rampa corta donde `comfy cut` difuminó el canal alfa. El relleno es gris 127. A lo largo del borde izquierdo de la imagen original, la máscara con relleno pasa por 255, 113, 28 y 0, un valor cada 4 píxeles: es el `feathering` de 12 en acción. El hash de Canny se imprime pero no se compara, porque cambia de una máquina a otra, como explica la lección 6.

## Puntos clave

- Sube las imágenes de entrada con `POST /upload/image`, y usa el nombre que devuelve el servidor: unos bytes idénticos conservan el nombre existente, unos bytes distintos reciben uno nuevo.
- `LoadImage` crea su máscara a partir de la transparencia, como `1 - alpha`. Una máscara en blanco y negro sin canal alfa pasa por `LoadImageMask` con un canal de color.
- `denoise` hace empezar al sampler a mitad de una planificación más larga. Cambia cuánto de la imagen sobrevive, no cuántos pasos se ejecutan.
- `VAEEncodeForInpaint` pone en gris los píxeles enmascarados y necesita `denoise` 1. Una máscara de ruido conserva la imagen que hay debajo. Un modelo de inpainting, alimentado por `InpaintModelConditioning`, es el que pinta algo nuevo acorde con el contexto.
- El VAE cambia píxeles en todas partes: vuelve a pegar el resultado con `ImageCompositeMasked`.

## Tu turno

Toma una fotografía tuya y borra algo de ella por cada una de las tres vías, con la misma máscara y la misma semilla. Compara los resultados fuera de la máscara con `compare`: importa menos la vía que saber qué píxeles conservaste. Repinta después la misma zona con denoise 0,4, 0,7 y 1, y anota dónde deja de reconocerse tu sujeto.

## Ejercicios

1. Con 20 pasos y `denoise` 0,4, ¿cuántos niveles de ruido calcula `set_steps`, cuántos conserva y cuántos pasos se ejecutan?
2. Renderiza `05-inpaint-vaeencode` con `denoise` 0,5. ¿Qué esperas dentro de la máscara, y por qué?
3. Crea una máscara con un borde suave, con el último argumento de `comfy cut` a 24 píxeles, y ejecuta sobre ella `05-inpaint-model` y `05-inpaint-vaeencode`. ¿Cuál conserva el borde suave?

<details>
<summary>Solución 1</summary>

`int(20 / 0.4)` vale 50, así que calcula la planificación de 50 pasos, que tiene 51 niveles de ruido, y conserva los 21 últimos. El sampler ejecuta 20 pasos entre esos 21 niveles, empezando por el nivel en el que habría estado el paso 30 de la planificación de 50 pasos.

</details>

<details>
<summary>Solución 2</summary>

Los píxeles enmascarados eran grises antes de codificar, y `denoise` 0,5 empieza desde un nivel en el que se conservan las formas grandes de la imagen. Por tanto, el sampler debería conservar una mancha gris en la máscara. El render lo confirmó, y con más fuerza de lo esperado: una elipse gris plana con solo un leve sombreado, y ninguna textura de madera. A la mitad del rango de ruido, SDXL trató el gris como parte de la imagen.

</details>

<details>
<summary>Solución 3</summary>

```text
comfy cut metronome.png metronome-soft.png 850 860 120 80 24
```

`InpaintModelConditioning` pasa la máscara tal cual, así que la máscara de ruido del sampler conserva el degradado, y la composición final mezcla a lo largo de él. `VAEEncodeForInpaint` redondea la máscara, así que el resultado tiene un borde duro donde el canal alfa cruza la mitad.

Los renders, con la semilla 42, lo confirman. Con el modelo de inpainting, dos objetos de madera nuevos reposan sobre el banco, y no se ve ningún borde, ni siquiera en la imagen decodificada antes de la composición. Con `VAEEncodeForInpaint`, la imagen decodificada tiene una elipse nítida de madera pálida y más rugosa, con un reborde oscuro a lo largo de su borde superior.

</details>

## Fuentes

- Documentación de ComfyUI: [imagen a imagen](https://docs.comfy.org/tutorials/basic/image-to-image), [inpainting](https://docs.comfy.org/tutorials/basic/inpaint), [outpainting](https://docs.comfy.org/tutorials/basic/outpaint), [rutas del servidor](https://docs.comfy.org/development/comfyui-server/comms_routes).
- ComfyUI en la v0.36.0: [`nodes.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py), [`comfy/samplers.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/samplers.py), [`comfy_extras/nodes_mask.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy_extras/nodes_mask.py), [`comfy/model_detection.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/model_detection.py), [`server.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py).
- Ficha del modelo: [SD-XL Inpainting 0.1](https://huggingface.co/diffusers/stable-diffusion-xl-1.0-inpainting-0.1).
