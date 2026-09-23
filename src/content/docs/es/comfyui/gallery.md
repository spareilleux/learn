---
title: Galería
description: 'Todas las imágenes que renderizó este curso, con el modelo, la semilla y el flujo que las hicieron, y la página que ilustran: primeros renders, la misma semilla dos veces, barridos de pasos y de CFG, fallos de inpainting, bordes Canny, modelos cuantizados comparados, escalado y texturas sin costuras, y los dibujos de los nodos de Guitar Alchemist.'
sidebar:
  order: 98
---

Todas las imágenes de este curso, en el orden en que las renderizan las lecciones. Cada una conserva la nota escrita allí donde aparece: la versión de ComfyUI, el modelo, la semilla y el flujo, de modo que cualquiera pueda rehacerse. Los flujos están en [`code/comfyui/workflows/`](https://github.com/spareilleux/learn/tree/main/code/comfyui/workflows), y cada enlace de abajo apunta a la revisión exacta que produjo la imagen.

Varias son fracasos, conservados a propósito. Un curso que solo enseña lo que funcionó enseña la mitad.

## [1. El grafo de nodos, la instalación y una primera imagen](../01-install-first-image/)

![Un objeto de latón sobre un viejo banco de trabajo de madera, iluminado por el sol de la mañana a través de una ventana polvorienta. Se parece más a un reloj de arena ornamentado que a un metrónomo: un alto cuerpo de vidrio con una cintura estrecha, sujeto en un armazón de latón sobre una base redonda.](../../../../assets/comfyui/l01-metronome.webp)

*Renderizado por ComfyUI v0.36.0: Stable Diffusion XL base 1.0, semilla 42, 25 pasos, sampler `euler`, scheduler `normal`, CFG 7, 1024 × 1024, workflow [`01-txt2img.api.json`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/workflows/01-txt2img.api.json), reducido a 768 × 768 para esta página.*

## [2. La difusión, y qué hace reproducible una imagen](../02-diffusion-reproducibility/)

Todas las imágenes siguientes las renderizó ComfyUI v0.36.0 a partir del workflow de la lección 1 con una sola entrada cambiada. Todas las imágenes: Stable Diffusion XL base 1.0, 1024 × 1024, prompt positivo "a brass metronome on an old wooden workbench, morning light through a window, dust in the air, photograph", prompt negativo "blurry, text, watermark", workflow [`01-txt2img.api.json`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/workflows/01-txt2img.api.json), reducidas para esta página. Salvo que el pie diga otra cosa: semilla 42, 25 pasos, CFG 7, sampler `euler`, scheduler `normal`.

![Cinco renders uno al lado del otro. Con 1 paso, una mancha borrosa rojiza y oscura. Con 4 pasos, un objeto cónico, tenue y difuso, en una habitación oscura. Con 10 pasos, un objeto de latón nítido sobre un banco de trabajo junto a una ventana. Con 25 y 50 pasos, una versión más definida de la misma escena, la de 50 pasos con más herramientas sobre el banco.](../../../../assets/comfyui/l02-steps.webp)

*Semilla 42; 1, 4, 10, 25 y 50 pasos.*

![Cuatro renders uno al lado del otro. Con CFG 1, un farol de vidrio transparente y desvaído en una habitación descolorida. Con CFG 3, un objeto de latón pálido en un taller brumoso. Con CFG 7, el objeto de latón saturado de la lección 1. Con CFG 12, una versión más contrastada con una base cuadrada.](../../../../assets/comfyui/l02-cfg.webp)

*Semilla 42; CFG 1, 3, 7 y 12.*

![Tres renders uno al lado del otro. euler con normal: el objeto de latón de la lección 1. dpmpp_2m con karras: una composición muy parecida, con pequeñas diferencias en las herramientas. euler_ancestral: otro objeto, una pirámide de latón sobre una base cuadrada, delante de una ventana soleada.](../../../../assets/comfyui/l02-samplers.webp)

*Semilla 42; `euler` con `normal`, `dpmpp_2m` con `karras`, `euler_ancestral` con `normal`.*

![Cuatro renders uno al lado del otro, todos de un objeto de latón sobre un banco de trabajo junto a una ventana. Semilla 42: el objeto ornamentado parecido a un reloj de arena. Semilla 43: un objeto en forma de pirámide con una escala, más parecido a un metrónomo. Semilla 7: un reloj de arena achaparrado sobre una base cuadrada, con una cortina. La segunda imagen de un lote de dos con la semilla 42: un objeto cónico alto junto a un soporte de madera.](../../../../assets/comfyui/l02-seeds.webp)

*Semillas 42, 43 y 7; después, la segunda imagen de un lote de dos con la semilla 42 (`batch_size` 2).*

![Tres paneles. Los dos primeros son los dos renders con la semilla 42, que a este tamaño parecen iguales. El tercero es una imagen blanca con líneas oscuras donde difieren, amplificadas ocho veces: el contorno del objeto de latón, su vidrio, las herramientas del banco y el marco de la ventana.](../../../../assets/comfyui/l02-cold-warm.webp)

*Izquierda: primera ejecución tras arrancar el servidor. Centro: el mismo grafo ejecutado de nuevo después de volver a codificar el prompt negativo. Derecha: dónde difieren, amplificado ocho veces, oscuro donde la diferencia es grande.*

## [5. Img2img, inpainting y outpainting](../05-img2img-inpainting/)

![Cinco imágenes una al lado de la otra. La primera es la fotografía de la lección 1 de un objeto de latón parecido a un reloj de arena sobre un banco de trabajo. Las cuatro siguientes son versiones parecidas a una acuarela: con denoise 0,3 y 0,5 la composición es idéntica y cambia el estilo; con 0,7 la ventana y las herramientas empiezan a moverse; con 0,9 el objeto es más sencillo, las herramientas son distintas y la ventana tiene otra forma.](../../../../assets/comfyui/l05-img2img.webp)

*Renderizado por ComfyUI v0.36.0: Stable Diffusion XL base 1.0, semilla 42, 25 pasos, CFG 7, `euler`, `normal`, workflow [`05-img2img.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-img2img.api.json) con el prompt "a watercolor painting of a brass metronome on an old wooden workbench, morning light through a window". De izquierda a derecha: la imagen de partida, y después `denoise` 0,3, 0,5, 0,7 y 0,9.*

![Seis recortes de la parte delantera derecha del banco de trabajo, cada uno de 340 por 240 píxeles. El original tiene dos pequeños objetos de madera. VAEEncodeForInpaint: los objetos han desaparecido, y una elipse pálida con otra textura de madera muestra dónde estaba la máscara. Máscara de ruido con denoise 1: una franja azulada y plana y una pequeña mancha blanca dentro de una elipse visible. Máscara de ruido con denoise 0,8: los dos objetos siguen ahí, más oscuros y más duros, con un contorno oscuro. Modelo de inpainting con denoise 0,99: una campanilla de latón tumbada de lado y una pieza de madera redonda, con la misma luz que el resto del banco.](../../../../assets/comfyui/l05-inpaint.webp)

*Renderizado por ComfyUI v0.36.0: Stable Diffusion XL base 1.0, y la UNet SD-XL inpainting 0.1 para el último recorte; semilla 42, 25 pasos, CFG 7, `euler`, `normal`, prompt "a small brass bell on an old wooden workbench, morning light through a window, photograph". De izquierda a derecha: el original, [`05-inpaint-vaeencode`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-vaeencode.api.json), [`05-inpaint-noisemask`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-noisemask.api.json) con `denoise` 1 y 0,8, y [`05-inpaint-model`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-model.api.json) con `denoise` 0,99. Cada recorte es el resultado pegado de nuevo en el original.*

![Una imagen ancha, de 1536 por 1024 píxeles reducida: el objeto de latón sobre su banco de trabajo en el centro, con un taller añadido a ambos lados: estanterías y una lámpara a la izquierda, la ventana prolongada y un tornillo de banco a la derecha.](../../../../assets/comfyui/l05-outpaint.webp)

*Renderizado por ComfyUI v0.36.0: UNet SD-XL inpainting 0.1 con los codificadores de texto y el VAE de SDXL base 1.0, semilla 42, 25 pasos, CFG 7, `euler`, `normal`, `denoise` 0,99, workflow [`05-outpaint.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-outpaint.api.json): 256 píxeles añadidos a la izquierda y a la derecha, difuminado de 40.*

## [6. ControlNet: bordes y profundidad](../06-controlnet/)

![Cuatro imágenes de 1024 píxeles una al lado de la otra. Primera, bordes blancos sobre negro: el contorno del objeto parecido a un reloj de arena, su base, el marco de la ventana y las herramientas del banco. Segunda, el mismo objeto tallado en hielo azul translúcido, de pie sobre su base de madera, en el mismo lugar y con la misma luz. Tercera, un mapa de profundidad gris: el objeto y su base en blanco, el banco en gris claro, la ventana en gris oscuro. Cuarta, el objeto redibujado en madera pulida con la misma silueta, con pequeñas piezas de madera a su alrededor.](../../../../assets/comfyui/l06-canny-depth.webp)

*Renderizado por ComfyUI v0.36.0: Stable Diffusion XL base 1.0 con el ControlNet union SDXL ProMax de xinsir a `strength` 0,8, semilla 42, 25 pasos, CFG 7, `euler`, `normal`. De izquierda a derecha: los bordes de la imagen de la lección 1, `Canny` 0,4 y 0,8; el render de [`06-canny.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/06-canny.api.json), prompt "a metronome carved from blue ice on an old wooden workbench, morning light through a window, photograph"; el mapa de profundidad de Lotus; el render de [`06-depth.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/06-depth.api.json), prompt "a small robot made of polished wood on an old wooden workbench, morning light through a window, photograph".*

![Tres renders del objeto de hielo uno al lado del otro. Con strength 0,3, el objeto tiene la misma forma, la luz es más suave y los barrotes de la ventana están en lugares ligeramente distintos. Con strength 1,0, la imagen es casi igual que con 0,8. Con end percent 0,3, la imagen es casi igual que con el ControlNet activo en todos los pasos.](../../../../assets/comfyui/l06-strength.webp)

*Renderizado por ComfyUI v0.36.0: Stable Diffusion XL base 1.0 con el ControlNet union SDXL ProMax de xinsir, semilla 42, 25 pasos, CFG 7, `euler`, `normal`, workflow [`06-canny.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/06-canny.api.json). De izquierda a derecha: `strength` 0,3, `strength` 1,0, y `strength` 0,8 con `end_percent` 0,3.*

## [7. LoRA: cargarlos, apilarlos y qué implica entrenar uno](../07-lora/)

![Tres imágenes de pixel art una al lado de la otra. Con strength 0,5, un objeto de latón detallado parecido a un reloj de arena sobre un banco de trabajo, delante de una ventana con árboles, con píxeles finos. Con strength 1,0, un objeto más sencillo en una habitación de madera con botellas en un estante, con píxeles más gruesos. Con strength 1,5, ningún metrónomo: una mesita con un frasco verde, un cuadro enmarcado y una ventana, en píxeles grandes y planos.](../../../../assets/comfyui/l07-pixel-art.webp)

*Renderizado por ComfyUI v0.36.0: Stable Diffusion XL base 1.0 con Pixel Art XL, semilla 42, 25 pasos, CFG 7, `euler`, `normal`, prompt "pixel art, a brass metronome on an old wooden workbench, morning light through a window", workflow [`07-lora.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/07-lora.api.json). De izquierda a derecha: `strength_model` y `strength_clip` a 0,5, 1,0 y 1,5.*

![Cuatro imágenes una al lado de la otra. SDXL base con 4 pasos: un objeto cónico oscuro y borroso delante de una ventana. LCM-LoRA: un instrumento nítido de latón y vidrio con una escala, sobre un banco junto a una ventana. SDXL-Lightning: un objeto de latón parecido a un farol que contiene un reloj de arena, junto a una ventana, nítido. LCM-LoRA con Pixel Art XL: un armario de madera en pixel art con un tubo verde dentro de un marco, sobre una pared de ladrillo.](../../../../assets/comfyui/l07-few-steps.webp)

*Renderizado por ComfyUI v0.36.0: Stable Diffusion XL base 1.0, semilla 42, prompt "a brass metronome on an old wooden workbench, morning light through a window, dust in the air, photograph" para las tres primeras. De izquierda a derecha: [`01-txt2img.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/01-txt2img.api.json) con 4 pasos, CFG 7, `euler`, `normal` y sin LoRA; [`07-lcm.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/07-lcm.api.json), LCM-LoRA, 4 pasos, CFG 1, `lcm`, `sgm_uniform`; [`07-lightning.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/07-lightning.api.json), LoRA SDXL-Lightning de 4 pasos, 4 pasos, CFG 1, `euler`, `sgm_uniform`; [`07-lora-stack.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/07-lora-stack.api.json), LCM-LoRA a 1,0 y Pixel Art XL a 1,2, 8 pasos, CFG 1,5, `lcm`, `sgm_uniform`, prompt "pixel art, a brass metronome on an old wooden workbench, morning light through a window".*

## [8. Modelos recientes y sus licencias, cuantización y VRAM](../08-recent-models-quantization/)

![Cuatro renders uno al lado del otro, cada uno un metrónomo piramidal dorado y negro sobre un banco de trabajo desgastado delante de una ventana. bf16 e int8: casi la misma imagen, con un aparato con interruptores a la izquierda. nvfp4 con el codificador de texto fp4: el mismo tipo de escena, con el metrónomo algo más grande y libros y un tarro sobre el banco. nvfp4 con el codificador de texto bf16: parecido al anterior, con los objetos colocados de otra forma.](../../../../assets/comfyui/l08-quantized.webp)

*Renderizado por ComfyUI v0.36.0: Z-Image-Turbo, semilla 42, 8 pasos, CFG 1, `res_multistep`, `simple`, shift 3, prompt "a brass metronome on an old wooden workbench, morning light through a window, dust in the air, photograph", workflow [`08-z-image-turbo.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/08-z-image-turbo.api.json). De izquierda a derecha: red bf16 con el codificador de texto bf16; int8 convrot con fp8 mixed; nvfp4 con fp4 mixed; nvfp4 con bf16.*

![Cuatro renders uno al lado del otro. Primero, el render bf16 de Z-Image-Turbo con la semilla 43: un metrónomo piramidal sobre un banco de trabajo. Después, tres renders de FLUX.2 klein 4B con las semillas 42, 43 y 44: cada uno un taller polvoriento con una ventana y un objeto de latón sobre un banco desgastado, pero el objeto es un soporte con una manivela o con brazos, no un metrónomo.](../../../../assets/comfyui/l08-z-image-klein.webp)

*Renderizado por ComfyUI v0.36.0. Primero: Z-Image-Turbo bf16, semilla 43, con los ajustes de arriba. Después: FLUX.2 klein 4B destilado, bf16, con el codificador de texto Qwen3 4B, semillas 42, 43 y 44, 4 pasos, CFG 1, `euler`, `Flux2Scheduler`, el mismo prompt, workflow [`08-flux2-klein.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/08-flux2-klein.api.json).*

## [9. Escalado, texturas sin costuras y HDR](../09-upscaling-seamless-hdr/)

![Tres recortes de 512 × 512 del mismo mástil de guitarra delante de una pared de ladrillo, ampliados cuatro veces. Nearest: bloques cuadrados de cuatro píxeles en las cuerdas y los trastes. Lanczos: suave pero blando, con halos claros a lo largo de los trastes. Real-ESRGAN: trastes y cuerdas nítidos, ladrillo más plano, y el alambre de los trastes dibujado como líneas claras y limpias.](../../../../assets/comfyui/l09-upscale-methods.webp)

*Renderizado por ComfyUI v0.36.0: el detalle en (384, 384) del primer render de la sección siguiente, ampliado 4 × con `ImageScaleBy` `nearest-exact`, `ImageScaleBy` `lanczos`, e `ImageUpscaleWithModel` con `RealESRGAN_x4plus.safetensors`, workflow [`09-upscale-model.api.json`](https://github.com/spareilleux/learn/blob/d16b4d70b565257067309b7b8d7f51408cb81741/code/comfyui/workflows/09-upscale-model.api.json). Cada panel muestra los 512 × 512 píxeles centrales del resultado de 1024 × 1024, a escala 1:1.*

![Cuatro paneles. Primero, el render entero de 1024 × 1024: una guitarra acústica apoyada en una pared de ladrillo junto a un escaparate con más guitarras. Después, el mismo recorte de 512 × 512 de tres versiones de 2048 × 2048: Lanczos, blando; Real-ESRGAN, cuerdas y ladrillo nítidos; hires fix, con nueva veta de la madera y nueva textura del ladrillo, y los marcadores de los trastes desplazados.](../../../../assets/comfyui/l09-hires-fix.webp)

*Renderizado por ComfyUI v0.36.0: Z-Image-Turbo nvfp4 con Qwen3 4B fp4 mixed, semilla 42, 8 pasos, CFG 1, `res_multistep`, `simple`, shift 3, prompt "an acoustic guitar leaning against a brick wall in a small music shop, warm evening light, photograph", workflow [`09-hires-fix.api.json`](https://github.com/spareilleux/learn/blob/d16b4d70b565257067309b7b8d7f51408cb81741/code/comfyui/workflows/09-hires-fix.api.json). De izquierda a derecha: la primera pasada; el recorte de (768, 768) a (1280, 1280) de Lanczos 2 ×, de Real-ESRGAN y después Lanczos 0,5, y del hires fix con denoise 0,33 y semilla 42.*

![Cuatro recortes de 512 × 512 de la pala y el mástil de la guitarra delante de la pared de ladrillo, tras el hires fix con denoise 0,2, 0,33, 0,5 y 0,7. Con 0,2 la imagen es la escalada con un poco más de textura. Con 0,33 los ladrillos ganan grano. Con 0,5 cambian las juntas de mortero y las manchas de los ladrillos. Con 0,7 la pala se redibuja con otros clavijeros, y el mástil es más estrecho.](../../../../assets/comfyui/l09-hires-denoise.webp)

*Renderizado por ComfyUI v0.36.0: el mismo workflow y la misma primera pasada, segunda pasada con denoise 0,2, 0,33, 0,5 y 0,7, recorte de (768, 256) a (1280, 768).*

![Tres recortes de 512 × 512 de la misma pala y el mismo mástil tras un escalado latente y una segunda pasada con denoise 0,3, 0,55 y 0,75. Con 0,3 la imagen está cubierta de un grano fino y ruidoso y las cuerdas están duplicadas. Con 0,55 está limpia, con el ladrillo redibujado. Con 0,75 se redibujan la pala y los marcadores de los trastes.](../../../../assets/comfyui/l09-latent-denoise.webp)

*Renderizado por ComfyUI v0.36.0: Z-Image-Turbo nvfp4, la misma primera pasada, `LatentUpscaleBy` `bislerp` 2 ×, segundo `KSampler` con 8 pasos, `res_multistep`, `simple`, denoise 0,3, 0,55 y 0,75, workflow [`09-latent-upscale.api.json`](https://github.com/spareilleux/learn/blob/d16b4d70b565257067309b7b8d7f51408cb81741/code/comfyui/workflows/09-latent-upscale.api.json).*

![Cuatro paneles de 384 × 384. Una textura de palisandro con veta vertical. La misma textura desplazada a la mitad, con una costura horizontal y otra vertical visibles en el centro. Un cuadrado negro con una cruz blanca, suave en sus bordes. El resultado, donde el centro muestra una veta continua y ninguna línea marcada.](../../../../assets/comfyui/l09-seamless-steps.webp)

*Renderizado por ComfyUI v0.36.0: Z-Image-Turbo int8 convrot con Qwen3 4B fp8 mixed, semilla 42 para las dos pasadas, 8 pasos, CFG 1, `res_multistep`, `simple`, prompt "flat top-down photograph of dark rosewood, fine straight grain, even soft lighting, no shadows, wood texture", workflow [`09-seamless.api.json`](https://github.com/spareilleux/learn/blob/d16b4d70b565257067309b7b8d7f51408cb81741/code/comfyui/workflows/09-seamless.api.json). De izquierda a derecha: el render, el desplazamiento, la máscara, el resultado.*

![Cuatro vistas previas en mosaico, cada una una repetición 2 × 2. El palisandro tal como se renderizó: una cuadrícula clara de costuras marcadas. El palisandro tras la reparación: sin costuras marcadas, con bloques algo más oscuros y más claros aún visibles. El arce claro tal como se renderizó: una cuadrícula de costuras. El arce tras la reparación: sin costuras marcadas, con suaves bandas verticales de madera más clara y más oscura.](../../../../assets/comfyui/l09-seamless.webp)

*Renderizado por ComfyUI v0.36.0: el mismo workflow y el mismo modelo. De izquierda a derecha: el palisandro tal como se renderizó, reparado; el arce, prompt "flat top-down photograph of pale maple wood, a planed board with fine straight grain, even soft lighting, wood texture", tal como se renderizó, reparado. Cada panel es una repetición de 2048 × 2048 mostrada a 512 × 512.*

## [11. Los nodos personalizados y su seguridad](../11-custom-nodes-and-security/)

![Seis diagramas de acordes en fila, en negro sobre blanco, con la cuerda de Mi grave a la izquierda y la cejuela arriba. C: una cruz sobre la cuerda 6, puntos en el traste 3 de la cuerda 5, el traste 2 de la cuerda 4 y el traste 1 de la cuerda 2, círculos sobre las cuerdas 3 y 1. G: puntos en el traste 3 de las cuerdas 6 y 1 y en el traste 2 de la cuerda 5, tres cuerdas al aire. La menor: una cruz, luego puntos en el traste 2 de las cuerdas 4 y 3 y en el traste 1 de la cuerda 2. F: puntos en el traste 1 de las cuerdas 6, 2 y 1, en el traste 3 de las cuerdas 5 y 4, y en el traste 2 de la cuerda 3. E7: puntos en el traste 2 de la cuerda 5 y en el traste 1 de la cuerda 3, cuatro cuerdas al aire. Si semidisminuido: cruces sobre las cuerdas 6 y 1, puntos en los trastes 2, 3, 2 y 3 de las cuerdas 5 a 2.](../../../../assets/comfyui/l11-chord-diagrams.webp)

*Dibujados por el nodo GA Chord Diagram con Pillow, no por un modelo de difusión: `C`, `G`, `Am`, `F`, `E7` y `Bm7b5`, de 256 píxeles cada uno, las imágenes de [`expected/`](https://github.com/spareilleux/learn/tree/22f2bf71c21d2cc4f426c0e917e7e19dbfca5bc3/code/comfyui/custom-nodes/ga/expected).*

![Dos mapas del mástil, uno encima del otro. Arriba, líneas blancas sobre negro: el mástil desde la cejuela hasta el traste 5, seis cuerdas, una cejuela gruesa a la izquierda, dos pequeños círculos de marcas, y el acorde de Do mayor como anillos blancos: traste 3 en la cuerda de La, traste 2 en la cuerda de Re, traste 1 en la cuerda de Si, y dos anillos a la izquierda de la cejuela para las cuerdas al aire de Sol y de Mi agudo. Abajo, la versión de profundidad de La eólico del traste 5 al traste 12: un diapasón gris, cuerdas y trastes más claros, y puntos blancos en cada nota de la escala de La menor.](../../../../assets/comfyui/l11-control-maps.webp)

*Dibujados por el nodo GA Fretboard Control Map con Pillow: la salida `lines` para el acorde `C`, trastes 0 a 5, y la salida `depth` para La eólico, trastes 5 a 12; ambas de 1024 × 1024, recortadas alrededor del mástil y reducidas.*

## [Diario](../journal/)

![Un objeto de latón sobre un viejo banco de trabajo de madera, iluminado por el sol de la mañana a través de una ventana polvorienta. Parece más un reloj de arena ornamentado que un metrónomo: un cuerpo de vidrio alto con la cintura estrecha, sujeto en un marco de latón sobre una base redonda.](../../../../assets/comfyui/l01-metronome.webp)

*El primer render. ComfyUI v0.36.0: Stable Diffusion XL base 1.0, semilla 42, 25 pasos, `euler`, `normal`, CFG 7, 1024 × 1024, workflow [`01-txt2img.api.json`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/workflows/01-txt2img.api.json).*

![Tres paneles. Los dos primeros son los dos renders con la semilla 42, que a este tamaño parecen iguales. El tercero es una imagen blanca con líneas oscuras donde difieren, amplificadas ocho veces: el contorno del objeto de latón, su vidrio, las herramientas del banco y el marco de la ventana.](../../../../assets/comfyui/l02-cold-warm.webp)

*Las dos imágenes con la semilla 42. ComfyUI v0.36.0: Stable Diffusion XL base 1.0, semilla 42, 25 pasos, `euler`, `normal`, CFG 7, workflow [`01-txt2img.api.json`](https://github.com/spareilleux/learn/blob/a1a9bffadaa7156b91ca9c2c2b8885e9e9862dd5/code/comfyui/workflows/01-txt2img.api.json). Izquierda: primera ejecución tras arrancar el servidor. Centro: el mismo grafo después de volver a codificar el prompt negativo. Derecha: dónde difieren, amplificado ocho veces.*

![Tres recortes de la parte delantera del banco de trabajo. Primero: una elipse gris plana con un leve sombreado donde estaban los objetos. Segundo: una elipse nítida de madera pálida y áspera, con un borde oscuro a lo largo de su parte superior. Tercero: dos objetos de madera nuevos sobre el banco, sin ningún borde visible.](../../../../assets/comfyui/journal-l05-failures.webp)

*Dos fallos de inpainting y la solución, antes de volver a pegar el resultado. ComfyUI v0.36.0: Stable Diffusion XL base 1.0, semilla 42, 25 pasos, CFG 7, `euler`, `normal`. De izquierda a derecha: [`05-inpaint-vaeencode.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-vaeencode.api.json) con `denoise` 0,5; el mismo workflow con `denoise` 1 y una máscara con un borde suavizado de 24 píxeles; [`05-inpaint-model.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-inpaint-model.api.json), la UNet SD-XL inpainting 0.1 con `denoise` 0,99, sobre la misma máscara suavizada.*

![Líneas de borde blancas sobre fondo negro, dibujadas con píxeles gruesos: un panal de celdas onduladas sacado del patrón de prueba del curso.](../../../../assets/comfyui/journal-canny-ci.webp)

*La salida del nodo `Canny` en la máquina del autor, hash de píxeles `77af5cb1b7e93a5c`, 464 píxeles de borde, ampliada cuatro veces sin suavizado. ComfyUI v0.36.0 en la CPU, sin modelo, umbrales 0,05 y 0,15, workflow [`05-masks.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/05-masks.api.json). Los tres runners de la CI dibujaron cada uno 467 píxeles de borde, con otros tres hashes.*

![Cuatro renders uno al lado del otro, cada uno un metrónomo piramidal dorado y negro sobre un banco de trabajo de madera gastado delante de una ventana. Los dos primeros son casi iguales; los dos últimos muestran la misma escena con los objetos dispuestos de otra forma.](../../../../assets/comfyui/l08-quantized.webp)

*ComfyUI v0.36.0: Z-Image-Turbo, semilla 42, 8 pasos, CFG 1, `res_multistep`, `simple`, workflow [`08-z-image-turbo.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/08-z-image-turbo.api.json). De izquierda a derecha: bf16 con el codificador de texto bf16, int8 con fp8, nvfp4 con fp4, nvfp4 con bf16.*

![Cuatro renders uno al lado del otro. Primero, el metrónomo piramidal de Z-Image-Turbo sobre un banco de trabajo. Después, tres renders de un taller polvoriento hechos por FLUX.2 klein 4B, cada uno con un soporte de latón con manivela o brazos sobre un banco gastado en lugar de un metrónomo.](../../../../assets/comfyui/l08-z-image-klein.webp)

*ComfyUI v0.36.0. Primero: Z-Image-Turbo bf16, semilla 43, workflow [`08-z-image-turbo.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/08-z-image-turbo.api.json). Después: FLUX.2 klein 4B, semillas 42, 43 y 44, 4 pasos, CFG 1, `euler`, workflow [`08-flux2-klein.api.json`](https://github.com/spareilleux/learn/blob/40880d5819d3d72102c008a617b4c83b519600cc/code/comfyui/workflows/08-flux2-klein.api.json).*

![Tres paneles. Una repetición 2 × 2 de una textura de palisandro, con líneas horizontales y verticales tenues a través de cada mosaico. Un recorte del centro de esa textura, donde una fila de motas oscuras cruza la veta y la mitad inferior es más clara. Una repetición 2 × 2 de una madera clara con una gran hoja de arce tallada en cada mosaico.](../../../../assets/comfyui/journal-l09-seamless-failures.webp)

*Los fallos, antes de la corrección. ComfyUI v0.36.0: Z-Image-Turbo nvfp4 con Qwen3 4B fp4 mixed, semilla 42, 8 pasos, CFG 1, `res_multistep`, `simple`, workflow [`09-seamless.api.json`](https://github.com/spareilleux/learn/blob/d16b4d70b565257067309b7b8d7f51408cb81741/code/comfyui/workflows/09-seamless.api.json) con su cruz ajustada a 160 píxeles, 64 de difuminado y un denoise de 0,7. De izquierda a derecha: el palisandro repetido 2 × 2; los 512 × 512 píxeles centrales del palisandro; el prompt "flat top-down photograph of pale maple, subtle straight grain, even soft lighting, no shadows, wood texture" (foto cenital de arce claro, con veta fina y recta, luz suave y uniforme, sin sombras, textura de madera), repetido 2 × 2.*
