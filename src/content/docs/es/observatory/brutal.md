---
title: "BRUTAL: el Coloso"
description: Un prototipo en C# y Vulkan, construido con BRUTAL para probar otro motor para el Observatorio, con path tracing en una GeForce RTX.
---

<video controls playsinline preload="metadata" poster="../../../demos/brutal/colossus-day.jpg" width="1280" height="536" style="width: 100%; height: auto;"><source src="../../../demos/brutal/colossus.mp4" type="video/mp4"></video>

*Un minuto de la cinemática, del final de la tarde a la noche y de vuelta hacia el alba: 62 s, 9,3 MB, con sonido.*

El [Observatorio](../) es una escena de Godot. Para ver si otro motor podría sostenerlo, se construyó un prototipo con [BRUTAL](https://github.com/ahwootech/BRUTAL), el framework de C# de Ahwoo sobre Vulkan. Es una evaluación, no un abandono de Godot, y no hay nada que descargar.

## Lo que muestra el vídeo

- **El enjambre:** diez mil cuerpos, simulados por Jolt Physics a 120 pasos por segundo, vuelan entre las torres y se reúnen en un rostro colosal. Sus ojos y su boca brillan.
- **La ciudad:** doce variantes de torres brutalistas, modeladas por reglas en Blender, con bandas de ventanas, retículas de casetones, aletas y luces de advertencia.
- **Los bloques:** una estructura sobre una meseta, generada por una pequeña biblioteca de F# a partir de bloques tipados y anidados.
- **La luz:** cada píxel sigue un camino de hasta tres rebotes, con un rayo de sombra hacia el sol en cada uno. DLSS Ray Reconstruction elimina el ruido de los caminos, y DLSS Calidad escala 1067 × 600 a 1600 × 900.
- **La noche:** el sol se pone en un ciclo de 128 segundos. El cielo se llena de estrellas, y las ventanas y las luces se encienden.
- **El sonido:** el enjambre, el viento, un canto sin palabras y ráfagas, todos sintetizados en C# al arrancar el programa y situados en la escena con OpenAL Soft. No hay voz.

<figure>
<img src="../../../demos/brutal/colossus-day.jpg" alt="El rostro del enjambre entre las torres, en la bruma de la tarde, con el sol al lado" width="1280" height="536" loading="lazy" />
<figcaption>La tarde: el rostro entre las torres.</figcaption>
</figure>

<figure>
<img src="../../../demos/brutal/colossus-dusk.jpg" alt="El rostro al anochecer, de cerca, con los ojos brillando entre ventanas encendidas" width="1280" height="536" loading="lazy" />
<figcaption>El anochecer: los ojos brillan.</figcaption>
</figure>

<figure>
<img src="../../../demos/brutal/colossus-towers.jpg" alt="Vista hacia arriba entre las torres con las ventanas encendidas, hacia un cielo oscuro" width="1280" height="536" loading="lazy" />
<figcaption>Entre las torres, mirando hacia arriba.</figcaption>
</figure>

## Cómo se midió

El vídeo se renderizó en una sola máquina, una GeForce RTX 5080, el 2026-10-21. El programa graba a 60 imágenes por segundo fijas, sea cual sea su ritmo, y funde cada par en una imagen de un vídeo a 30 imágenes por segundo: 6.720 imágenes para 112 segundos, de los que este es un minuto. La GPU tardó 7,37 ms por imagen en la mediana y 13,34 ms en el percentil 95, para el path tracing, la eliminación de ruido y el escalado juntos.

## Por qué no hay descarga

- La licencia de BRUTAL, basada en MIT, pide a toda versión distribuida que dé crédito a Ahwoo, que muestre el logotipo de BRUTAL sin alterar antes de arrancar y que incluya su `NOTICE.txt`. Este prototipo es un experimento local y no se distribuye.
- DLSS necesita las bibliotecas Streamline de NVIDIA, que no se redistribuyen aquí.

## Créditos

- **Motor:** [BRUTAL](https://github.com/ahwootech/BRUTAL) de Ahwoo, bajo la BRUTAL License v1.0.
- **Física:** [Jolt Physics](https://github.com/jrouwe/JoltPhysics) (MIT).
- **Ventana e interfaz:** [GLFW](https://www.glfw.org/) (zlib), [Dear ImGui](https://github.com/ocornut/imgui) e [ImPlot](https://github.com/epezent/implot) (MIT).
- **Sonido:** [OpenAL Soft](https://openal-soft.org/) (LGPL-2.1). Cada sonido lo sintetiza el programa.
- **También, a través de los paquetes de BRUTAL:** [FreeType](https://freetype.org/) para el texto y [shaderc](https://github.com/google/shaderc) (Apache-2.0) para los shaders.
- **Escalado y eliminación de ruido:** NVIDIA DLSS, a través de [Streamline](https://github.com/NVIDIA-RTX/Streamline). NVIDIA, GeForce RTX y DLSS son marcas de NVIDIA Corporation.
- **El rostro:** el retrato de un busto de mármol imaginario, pintado por [Z-Image-Turbo](https://huggingface.co/Tongyi-MAI/Z-Image-Turbo) (Apache-2.0), recortado por [BiRefNet](https://github.com/ZhengPeng7/BiRefNet) (MIT) y convertido en malla por [TRELLIS.2](https://huggingface.co/microsoft/TRELLIS.2-4B) (MIT) con las características de [DINOv3](https://github.com/facebookresearch/dinov3). Built with DINOv3. Cada modelo se ejecutó en local.
- **Texturas:** generadas en local con Z-Image-Turbo.
- **Torres:** modeladas en Blender por un script.
