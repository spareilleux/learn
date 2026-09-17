---
title: '9. Escalado, texturas sin costuras y HDR'
description: 'Hacer imágenes más grandes, repetibles en mosaico y más profundas — un modelo de escalado junto al redimensionado nearest y Lanczos, el hires fix en el espacio de píxeles y en el espacio latente y lo que le hace el denoise, la decodificación por mosaicos, una textura de madera sin costuras hecha solo con nodos del núcleo, y lo que contienen los archivos PNG de 16 bits, EXR lineal y AVIF HLG cuando salen de un modelo de difusión, medido en una GPU.'
sidebar:
  order: 9
---

Código: los workflows [`09-upscale-model.api.json`](https://github.com/spareilleux/learn/blob/d16b4d70b565257067309b7b8d7f51408cb81741/code/comfyui/workflows/09-upscale-model.api.json), [`09-hires-fix.api.json`](https://github.com/spareilleux/learn/blob/d16b4d70b565257067309b7b8d7f51408cb81741/code/comfyui/workflows/09-hires-fix.api.json), [`09-latent-upscale.api.json`](https://github.com/spareilleux/learn/blob/d16b4d70b565257067309b7b8d7f51408cb81741/code/comfyui/workflows/09-latent-upscale.api.json), [`09-seamless.api.json`](https://github.com/spareilleux/learn/blob/d16b4d70b565257067309b7b8d7f51408cb81741/code/comfyui/workflows/09-seamless.api.json) y [`09-exr.api.json`](https://github.com/spareilleux/learn/blob/d16b4d70b565257067309b7b8d7f51408cb81741/code/comfyui/workflows/09-exr.api.json); el decodificador de PNG de 16 bits en [`csharp/Png.cs`](https://github.com/spareilleux/learn/blob/d16b4d70b565257067309b7b8d7f51408cb81741/code/comfyui/csharp/Png.cs).

Z-Image-Turbo dibuja imágenes de 1024 × 1024. Una impresión, un fondo de escritorio o una textura sobre un mástil de guitarra en 3D necesitan más píxeles, bordes que se repitan sin una costura visible, o más de 8 bits por canal. Esta lección hace cada una de estas cosas con nodos del núcleo, y comprueba lo que contienen realmente los archivos.

Los renders se ejecutaron en una RTX 5080 con ComfyUI v0.36.0. La regla de RAM de la lección 8 eligió el modelo en cada arranque: Z-Image-Turbo nvfp4 con el codificador de texto fp4 cuando había 22 GB de RAM libres, int8 con fp8 cuando había 24 GB. Cada pie de imagen indica el que se usó.

## Modelos de escalado

Un modelo de escalado es una pequeña red convolucional entrenada para convertir una imagen pequeña en otra más grande y más nítida. ComfyUI lo carga con [`UpscaleModelLoader`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy_extras/nodes_upscale_model.py#L20-L47), desde la carpeta `models/upscale_models`, a través de la biblioteca [spandrel](https://github.com/chaiNNer-org/spandrel), y lo ejecuta con `ImageUpscaleWithModel`, "Upscale Image (using Model)". No interviene ningún modelo de difusión, y el prompt no desempeña ningún papel.

El curso usa [Real-ESRGAN](https://github.com/xinntao/Real-ESRGAN) x4plus, el modelo del blueprint *Image Upscale (Z-image-Turbo)* de ComfyUI. Comfy-Org lo reempaqueta como `RealESRGAN_x4plus.safetensors`, de 66.857.836 bytes, en [Comfy-Org/Real-ESRGAN_repackaged](https://huggingface.co/Comfy-Org/Real-ESRGAN_repackaged). Su licencia es BSD-3-Clause.

Aquí también importan las licencias. El README de spandrel dice que el paquete "only contains architectures with permissive and public domain licenses" (solo contiene arquitecturas con licencias permisivas o de dominio público), pero eso cubre su código, no los pesos: 4x-UltraSharp, un modelo ESRGAN popular, está bajo CC BY-NC-SA 4.0, no comercial, según [OpenModelDB](https://openmodeldb.info/models/4x-UltraSharp). El [tutorial de escalado](https://docs.comfy.org/tutorials/basic/upscale) de la documentación usa otro archivo, 4x-ESRGAN de OpenModelDB, como `.pth`.

El nodo trabaja por mosaicos: [512 píxeles con 32 de solapamiento](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy_extras/nodes_upscale_model.py#L79-L95), y reduce a la mitad el tamaño del mosaico tras cada error de falta de memoria, hasta 128. El tamaño no tiene entrada en la interfaz.

`09-upscale-model.api.json` recorta un detalle de 256 × 256 de un render y lo amplía cuatro veces de tres formas:

![Tres recortes de 512 × 512 del mismo mástil de guitarra delante de una pared de ladrillo, ampliados cuatro veces. Nearest: bloques cuadrados de cuatro píxeles en las cuerdas y los trastes. Lanczos: suave pero blando, con halos claros a lo largo de los trastes. Real-ESRGAN: trastes y cuerdas nítidos, ladrillo más plano, y el alambre de los trastes dibujado como líneas claras y limpias.](../../../../assets/comfyui/l09-upscale-methods.webp)

*Renderizado por ComfyUI v0.36.0: el detalle en (384, 384) del primer render de la sección siguiente, ampliado 4 × con `ImageScaleBy` `nearest-exact`, `ImageScaleBy` `lanczos`, e `ImageUpscaleWithModel` con `RealESRGAN_x4plus.safetensors`, workflow [`09-upscale-model.api.json`](https://github.com/spareilleux/learn/blob/d16b4d70b565257067309b7b8d7f51408cb81741/code/comfyui/workflows/09-upscale-model.api.json). Cada panel muestra los 512 × 512 píxeles centrales del resultado de 1024 × 1024, a escala 1:1.*

El modelo de escalado inventa bordes verosímiles; Lanczos solo interpola. La ejecución tardó 2,08 segundos, incluida la carga del modelo.

## El hires fix

Un modelo de escalado afina lo que ya está; no añade detalle. El *hires fix* sí lo hace: "Hires fix is just creating an image at a lower resolution, upscaling it and then sending it through img2img" (el hires fix consiste simplemente en crear una imagen a una resolución menor, escalarla y pasarla por img2img), dice el [ejemplo de 2 pasadas](https://comfyanonymous.github.io/ComfyUI_examples/2_pass_txt2img/) de ComfyUI. La segunda pasada es el img2img de la lección 5, con un denoise bajo, sobre la imagen más grande.

`09-hires-fix.api.json` sigue el blueprint *Image Upscale (Z-image-Turbo)*:

1. Z-Image-Turbo dibuja una imagen de 1024 × 1024, como en la lección 8.
2. Real-ESRGAN la amplía a 4096 × 4096, y `ImageScaleBy` `lanczos` 0,5 la devuelve a 2048 × 2048.
3. `VAEEncode`, y después un `KSampler` con 5 pasos, CFG 1, `dpmpp_2m_sde`, `beta` y denoise 0,33, los valores del blueprint.
4. `VAEDecodeTiled` decodifica el latente de 2048 × 2048 en mosaicos de 1024 píxeles.

El segundo prompt del blueprint es "masterpiece, 8k"; el workflow conserva en su lugar el primer prompt.

![Cuatro paneles. Primero, el render entero de 1024 × 1024: una guitarra acústica apoyada en una pared de ladrillo junto a un escaparate con más guitarras. Después, el mismo recorte de 512 × 512 de tres versiones de 2048 × 2048: Lanczos, blando; Real-ESRGAN, cuerdas y ladrillo nítidos; hires fix, con nueva veta de la madera y nueva textura del ladrillo, y los marcadores de los trastes desplazados.](../../../../assets/comfyui/l09-hires-fix.webp)

*Renderizado por ComfyUI v0.36.0: Z-Image-Turbo nvfp4 con Qwen3 4B fp4 mixed, semilla 42, 8 pasos, CFG 1, `res_multistep`, `simple`, shift 3, prompt "an acoustic guitar leaning against a brick wall in a small music shop, warm evening light, photograph", workflow [`09-hires-fix.api.json`](https://github.com/spareilleux/learn/blob/d16b4d70b565257067309b7b8d7f51408cb81741/code/comfyui/workflows/09-hires-fix.api.json). De izquierda a derecha: la primera pasada; el recorte de (768, 768) a (1280, 1280) de Lanczos 2 ×, de Real-ESRGAN y después Lanczos 0,5, y del hires fix con denoise 0,33 y semilla 42.*

Mira el mástil: el hires fix añade veta y textura a la madera, y también desplaza los marcadores de los trastes. El denoise decide cuánto puede cambiar:

![Cuatro recortes de 512 × 512 de la pala y el mástil de la guitarra delante de la pared de ladrillo, tras el hires fix con denoise 0,2, 0,33, 0,5 y 0,7. Con 0,2 la imagen es la escalada con un poco más de textura. Con 0,33 los ladrillos ganan grano. Con 0,5 cambian las juntas de mortero y las manchas de los ladrillos. Con 0,7 la pala se redibuja con otros clavijeros, y el mástil es más estrecho.](../../../../assets/comfyui/l09-hires-denoise.webp)

*Renderizado por ComfyUI v0.36.0: el mismo workflow y la misma primera pasada, segunda pasada con denoise 0,2, 0,33, 0,5 y 0,7, recorte de (768, 256) a (1280, 768).*

### Tiempo y memoria

A 1024 × 1024 un paso tardaba unos 0,3 segundos. A 2048 × 2048 un paso tardaba de 2,2 a 2,8 segundos: cuatro veces los píxeles, y unas ocho veces el tiempo. Las capas de atención comparan cada parche con todos los demás, así que su coste crece con el cuadrado del número de parches. Con el modelo cargado, el workflow entero con una semilla nueva tardó 26,4 segundos; cambiar solo el denoise de la segunda pasada tardó 16,4 segundos, porque ComfyUI reutilizó la primera pasada y el escalado de la caché (lección 4).

Aquí `VAEDecodeTiled` no hace falta por la memoria. El mismo grafo con un `VAEDecode` normal se ejecutó sin el aviso "Ran out of memory when regular VAE decoding, retrying with tiled VAE decoding" (sin memoria en la decodificación VAE normal, reintentando con la decodificación por mosaicos) que ComfyUI imprime [cuando recurre a ella](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/sd.py#L1267). Las dos imágenes difieren en 0,93 niveles por canal de media, como máximo 29 de 255, y en más de 8 niveles en el 0,02 % de los píxeles: la mezcla de mosaicos de [`VAEDecodeTiled`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py#L343-L378) es cercana, no idéntica. Resérvalo para imágenes 4K, vídeo o una GPU más pequeña.

### En el espacio latente

El hires fix más antiguo se salta los píxeles: [`LatentUpscaleBy`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py#L1369-L1388) amplía el propio latente, aquí con `bislerp`, y un segundo `KSampler` muestrea con denoise 0,3, 0,55 o 0,75.

![Tres recortes de 512 × 512 de la misma pala y el mismo mástil tras un escalado latente y una segunda pasada con denoise 0,3, 0,55 y 0,75. Con 0,3 la imagen está cubierta de un grano fino y ruidoso y las cuerdas están duplicadas. Con 0,55 está limpia, con el ladrillo redibujado. Con 0,75 se redibujan la pala y los marcadores de los trastes.](../../../../assets/comfyui/l09-latent-denoise.webp)

*Renderizado por ComfyUI v0.36.0: Z-Image-Turbo nvfp4, la misma primera pasada, `LatentUpscaleBy` `bislerp` 2 ×, segundo `KSampler` con 8 pasos, `res_multistep`, `simple`, denoise 0,3, 0,55 y 0,75, workflow [`09-latent-upscale.api.json`](https://github.com/spareilleux/learn/blob/d16b4d70b565257067309b7b8d7f51408cb81741/code/comfyui/workflows/09-latent-upscale.api.json).*

Un latente ampliado no es un latente que el VAE hubiera podido producir: con denoise 0,3 al sampler no le quedan suficientes pasos para limpiarlo, y el grano se queda. Necesita alrededor de 0,55, lo que también cambia más la imagen. La ruta por píxeles conserva la composición con un denoise más bajo, a cambio de un modelo de escalado. Aquí la segunda pasada tardó 17,8 segundos, con 8 pasos a 2048 × 2048.

Para imágenes grandes por partes, el núcleo tiene también `SplitImageToTileList` e `ImageMergeTileList`, que mezclan los mosaicos con una ventana sinusoidal; muestrear cada mosaico y fusionarlos está *por verificar*. Los nodos de difusión por mosaicos como *Ultimate SD Upscale* son nodos personalizados (lección 11).

## Texturas sin costuras

Una textura se repite en mosaico cuando su borde derecho continúa su borde izquierdo, y su borde inferior el superior. Un render no lo hace: repetirlo 2 × 2 muestra una cuadrícula. Algunas herramientas hacen que las convoluciones del modelo den la vuelta a la imagen; el núcleo de ComfyUI no tiene esa opción en la v0.36.0. El relleno `circular` aparece en [`pad_to_patch_size`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/ldm/common_dit.py#L5-L13), para la división en parches, donde no llega ninguna entrada.

El apaño clásico funciona con nodos del núcleo:

1. **Desplazar a la mitad.** Cuatro nodos `ImageCropV2` cortan los cuartos, y tres nodos `ImageStitch` los intercambian. Los antiguos bordes se encuentran ahora en una cruz en el centro, y los nuevos bordes eran vecinos en el render, así que se repiten sin costura.
2. **Enmascarar la cruz.** `SolidMask`, `FeatherMask` y `MaskComposite` construyen una cruz suave, de 384 píxeles de ancho con 128 píxeles de difuminado a cada lado.
3. **Repintar la cruz.** `VAEEncode` y `SetLatentNoiseMask` (lección 5), y después un `KSampler` con denoise 1,0 y el mismo prompt.
4. **Conservar los bordes.** `ImageCompositeMasked` vuelve a pegar los píxeles repintados a través de la máscara, así que los bordes se quedan exactamente como estaban.

![Cuatro paneles de 384 × 384. Una textura de palisandro con veta vertical. La misma textura desplazada a la mitad, con una costura horizontal y otra vertical visibles en el centro. Un cuadrado negro con una cruz blanca, suave en sus bordes. El resultado, donde el centro muestra una veta continua y ninguna línea marcada.](../../../../assets/comfyui/l09-seamless-steps.webp)

*Renderizado por ComfyUI v0.36.0: Z-Image-Turbo int8 convrot con Qwen3 4B fp8 mixed, semilla 42 para las dos pasadas, 8 pasos, CFG 1, `res_multistep`, `simple`, prompt "flat top-down photograph of dark rosewood, fine straight grain, even soft lighting, no shadows, wood texture", workflow [`09-seamless.api.json`](https://github.com/spareilleux/learn/blob/d16b4d70b565257067309b7b8d7f51408cb81741/code/comfyui/workflows/09-seamless.api.json). De izquierda a derecha: el render, el desplazamiento, la máscara, el resultado.*

El workflow también une cada textura 2 × 2, para comprobar la repetición a simple vista:

![Cuatro vistas previas en mosaico, cada una una repetición 2 × 2. El palisandro tal como se renderizó: una cuadrícula clara de costuras marcadas. El palisandro tras la reparación: sin costuras marcadas, con bloques algo más oscuros y más claros aún visibles. El arce claro tal como se renderizó: una cuadrícula de costuras. El arce tras la reparación: sin costuras marcadas, con suaves bandas verticales de madera más clara y más oscura.](../../../../assets/comfyui/l09-seamless.webp)

*Renderizado por ComfyUI v0.36.0: el mismo workflow y el mismo modelo. De izquierda a derecha: el palisandro tal como se renderizó, reparado; el arce, prompt "flat top-down photograph of pale maple wood, a planed board with fine straight grain, even soft lighting, wood texture", tal como se renderizó, reparado. Cada panel es una repetición de 2048 × 2048 mostrada a 512 × 512.*

Para medir una costura, compara el salto a través de ella con el salto entre píxeles vecinos corrientes. La diferencia absoluta media entre dos columnas adyacentes, en niveles de 255:

| Palisandro, int8 | Fila central | Columna central | Filas vecinas típicas | Columnas vecinas típicas |
|---|---|---|---|---|
| Desplazado, antes de la reparación | 9,41 | 10,35 | 3,08 | 5,66 |
| Reparado, denoise 0,85 | 3,58 | 5,81 | 3,04 | 5,51 |
| Reparado, denoise 1,0 | 3,67 | 5,68 | 3,03 | 5,56 |

Las costuras bajan a la propia variación de la textura. Lo que los números no muestran es el tono: las mitades vienen de partes del render con distinto brillo medio, y el repintado las funde a lo largo de 384 píxeles en lugar de eliminar la diferencia. En el arce, la columna central sigue saltando 9,88 frente a 5,71 para las vecinas: su veta es lisa, así que el escalón se ve. Un prompt para un material uniforme e iluminado de forma pareja ayuda más que cualquier ajuste.

El primer intento, con una cruz de 160 píxeles, 64 píxeles de difuminado y denoise 0,7, dejó una línea moteada y un escalón visible: el diario lo muestra.

## HDR, y lo que contienen los archivos

Un modelo de difusión dibuja en el rango del VAE: el paso de salida por defecto [limita cada píxel a entre 0 y 1](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/sd.py#L507-L508). El PNG de 8 bits de `SaveImage` [redondea ese rango a 256 niveles](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py#L1698-L1699). `SaveImageAdvanced`, "Save Image (Advanced)", [escribe más](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy_extras/nodes_images.py#L1725-L1881):

- **PNG**, 8 o 16 bits por canal, sRGB.
- **EXR**, coma flotante de 32 bits. `input_color_space` dice qué son los píxeles: sRGB se convierte a luz lineal, `HDR` se decodifica desde HLG, y `linear` se escribe tal cual.
- **AVIF**, 8 o 10 bits, sRGB, `HDR` (BT.2020 con HLG) o `HDR PQ`.

En el formato de la API, las opciones de una entrada dinámica tienen nombres con puntos: `"format": "exr"`, `"format.bit_depth": "32-bit float"`, `"format.input_color_space": "sRGB"`.

`09-exr.api.json` guarda el render de 1024 × 1024 del hires fix de tres formas. [`ImageColorSpace`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy_extras/nodes_images.py#L1111-L1179) lo convierte a HLG antes del AVIF. Los archivos se volvieron a leer con PyAV, desde el Python de la versión portable:

| Archivo | Tamaño | Qué contiene |
|---|---|---|
| `SaveImage`, PNG de 8 bits | 1.623.741 bytes | 256 niveles por canal |
| PNG de 16 bits | 1.922.698 bytes | `rgb48be`, y aun así 256 niveles distintos en el canal rojo |
| EXR, entrada sRGB | 12.600.735 bytes | `gbrpf32le`, sin comprimir, mínimo 0,0, máximo 1,0, ningún valor por encima de 1 |
| AVIF, HLG | 117.350 bytes | `yuv420p10le`, primarios 9 (BT.2020), transferencia 18 (HLG) |

Los archivos más profundos contienen los mismos 256 niveles. Un PNG de 16 bits o un EXR en coma flotante sirve como entrada para un paso posterior que trabaje en coma flotante, como la corrección de color. La luz más brillante que el blanco no sale del modelo: nada en el EXR supera 1,0, que en la convención de ComfyUI es el blanco de referencia de 203 nits del sRGB. La descripción del nodo lo dice: "Linear 1.0 uses the same 203-nit reference white as sRGB; HLG uses a 1000-nit reference display." (el 1.0 lineal usa el mismo blanco de referencia de 203 nits que sRGB; HLG usa una pantalla de referencia de 1000 nits).

Dos trampas:

- `LatentOperationTonemapReinhard`, que se encuentra buscando "hdr latent", aplica un mapeo de tonos [al vector de guía](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy_extras/nodes_latent.py#L373-L407), para domar un CFG alto. No produce ningún píxel HDR.
- En Windows, `LoadImage` no enumera los archivos `.exr`: el módulo `mimetypes` de Python no tiene tipo para ellos, así que [el filtro](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/folder_paths.py#L229-L253) los descarta. Linux y macOS dependen de la base de datos MIME del sistema: *por verificar*.

### En three.js

three.js lee estos archivos. [EXRLoader](https://threejs.org/docs/pages/EXRLoader.html) admite EXR sin comprimir, como lo escribe ComfyUI, y lo carga como `HalfFloatType` por defecto; cargar este archivo en un navegador está *por verificar*. Para los archivos `.hdr`, `RGBELoader` está obsoleto desde la r180: usa [HDRLoader](https://threejs.org/docs/pages/HDRLoader.html). Para una textura de color, un PNG de 8 bits con `texture.colorSpace = SRGBColorSpace` suele bastar; [MeshStandardMaterial](https://threejs.org/docs/pages/MeshStandardMaterial.html) espera los mapas de datos como `normalMap` en `NoColorSpace`. La lección 13 construye texturas así para el sitio.

## Puntos clave

- Un modelo de escalado afina sin prompt; comprueba la licencia de sus pesos, no solo la de su arquitectura.
- El hires fix añade detalle con una segunda pasada img2img. Un denoise de 0,2 a 0,35 conserva la composición en el espacio de píxeles; un escalado latente necesita alrededor de 0,55 y cambia más.
- A 2048 × 2048 cada paso tardó unas ocho veces más que a 1024 × 1024.
- El núcleo de ComfyUI no tiene convolución circular: desplaza la textura a la mitad, repinta una cruz suave, vuelve a pegarla a través de la máscara, y mide las costuras.
- Un PNG de 16 bits, un EXR en coma flotante o un AVIF HLG hecho a partir de un render no contiene luz más allá del blanco: la salida del VAE está limitada a entre 0 y 1.

## Tu turno

Haz una textura sin costuras para algo tuyo: la madera de un diapasón, un golpeador de metal cepillado, la tela de la rejilla de un altavoz. Renderízala, ejecuta `09-seamless.api.json` con tu prompt y `--set 5.text=...`, y únela 2 × 2. Después intenta romperla: un prompt con un elemento grande, como "a single knot in the middle" (un único nudo en el centro), y mira lo que la cruz le hace.

## Ejercicios

1. Amplías un render de 1024 × 1024 a 2048 × 2048 para una impresión. ¿Qué ruta conserva exactamente la composición, cuál añade detalle, y qué cuesta cada una?
2. Un colega guarda un render de Z-Image-Turbo como EXR de 32 bits y te pide que lo uses como mapa de entorno HDR, "ya que es HDR". ¿Qué le respondes?
3. En `09-seamless.api.json`, ¿por qué `ImageCompositeMasked` vuelve a pegar la imagen repintada a través de la máscara, en lugar de guardar la salida de `VAEDecode`?

<details>
<summary>Solución 1</summary>

Lanczos o un modelo de escalado dejan cada forma donde está: Lanczos es instantáneo y blando, Real-ESRGAN tardó aquí unos 2 segundos y afina los bordes. El hires fix añade detalle muestreando de nuevo a 2048 × 2048, a unos 2,5 segundos por paso en esta GPU, y desplaza las cosas pequeñas: con denoise 0,33 los marcadores de los trastes se movieron. Para una impresión de esta guitarra, Real-ESRGAN y después un hires fix de 0,2 a 0,3 es un buen punto de partida; compara los recortes antes de elegir.

</details>

<details>
<summary>Solución 2</summary>

El contenedor es HDR, el contenido no. El VAE limita su salida a entre 0 y 1, así que el píxel más brillante vale 1,0, el blanco sRGB: la luz cálida de la imagen no es más brillante que una pared blanca, y un mapa de entorno hecho con ella ilumina una escena como una imagen sRGB plana. El EXR sigue siendo útil para la corrección de color en coma flotante. Un entorno HDR de verdad necesita luz medida o renderizada, por ejemplo una foto con horquillado de exposición o un render 3D, *por verificar* con tu motor de render.

</details>

<details>
<summary>Solución 3</summary>

`SetLatentNoiseMask` limita el ruido a la zona enmascarada, pero la imagen entera sigue pasando por `VAEEncode` y `VAEDecode`, y el VAE cambia ligeramente cada píxel: la lección 5 lo midió fuera de la máscara. Los bordes deben quedarse exactamente como estaban, porque son lo que se repite en mosaico. Pegar a través de la máscara toma los píxeles no enmascarados de la imagen desplazada, intactos.

</details>

## Fuentes

- X. Wang, L. Xie, C. Dong y Y. Shan, [Real-ESRGAN: Training Real-World Blind Super-Resolution with Pure Synthetic Data](https://arxiv.org/abs/2107.10833), 2021.
- Documentación de ComfyUI: [tutorial de escalado](https://docs.comfy.org/tutorials/basic/upscale), [ImageColorSpace](https://docs.comfy.org/built-in-nodes/ImageColorSpace); ejemplos de ComfyUI: [2 pass txt2img](https://comfyanonymous.github.io/ComfyUI_examples/2_pass_txt2img/).
- ComfyUI en la v0.36.0: [`comfy_extras/nodes_upscale_model.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy_extras/nodes_upscale_model.py), [`comfy_extras/nodes_images.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy_extras/nodes_images.py), [`comfy_extras/nodes_latent.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy_extras/nodes_latent.py), [`nodes.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/nodes.py), [`comfy/sd.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/sd.py), [`folder_paths.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/folder_paths.py).
- Modelos: [xinntao/Real-ESRGAN](https://github.com/xinntao/Real-ESRGAN), [Comfy-Org/Real-ESRGAN_repackaged](https://huggingface.co/Comfy-Org/Real-ESRGAN_repackaged), [OpenModelDB 4x-UltraSharp](https://openmodeldb.info/models/4x-UltraSharp), [chaiNNer-org/spandrel](https://github.com/chaiNNer-org/spandrel).
- three.js: [EXRLoader](https://threejs.org/docs/pages/EXRLoader.html), [HDRLoader](https://threejs.org/docs/pages/HDRLoader.html), [MeshStandardMaterial](https://threejs.org/docs/pages/MeshStandardMaterial.html).
