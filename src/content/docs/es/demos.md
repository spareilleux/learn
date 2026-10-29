---
title: Demos
description: Lo que se puede jugar o ver aquí — el observatorio 3D, el Coloso de BRUTAL y su ciudad Lego, las escenas de three.js y los prototipos de Guitar Alchemist.
---

Algunos cursos terminan en algo que se puede ver. Esta página los reúne. Las primeras demos funcionan en tu navegador, en un ordenador o en un teléfono. Las demás son programas nativos que solo funcionan en la máquina del autor: aquí se muestran en vídeo y en capturas.

## En el navegador

### Observatorio interactivo

**[Jugar en el navegador](../../demos/observatory/)** · [Sobre el observatorio](../observatory/)

Una escena 3D hecha con [Godot](https://godotengine.org/), a partir de un modelo construido en Blender y de texturas generadas en local con ComfyUI. La versión web necesita un navegador reciente con WebGL 2 y descarga unos 55 MB la primera vez. Una versión RTX, con path tracing y DLSS, se instala en Windows con una tarjeta GeForce RTX. Las versiones para Linux y macOS son rasterizadas.

### Escenas de three.js

Cuatro escenas completas del [curso de three.js](../threejs/):

- [Una guitarra para tocar](../../threejs-demos/demos/guitar.html): haz clic en una cuerda entre dos trastes, o rasguea acordes (lección 5).
- [Una guitarra en un estudio](../../threejs-demos/demos/studio.html): exposición, luces, bloom y un neón, ajustados desde un panel (lección 7).
- [Púas](../../threejs-demos/demos/physics.html): lanza púas contra el mástil, simuladas con Rapier (lección 10).
- [Voicings](../../threejs-demos/demos/voicing.html): elige un acorde y un voicing, míralo en el mástil y escúchalo (lección 13).

Cada lección tiene además su propia demo, más pequeña.

### Laboratorio Guitar Alchemist

Dos prototipos del [Laboratorio Guitar Alchemist](../ga-lab/):

- [P1: explorador del espacio de voicings](../ga-lab/01-voicing-explorer/): 30 000 voicings de guitarra de Guitar Alchemist como una nube de puntos 3D que se puede girar, pulsar y escuchar.
- [P2: toca un acorde, mira el universo](../ga-lab/02-chord-universe/): un reconocedor de acordes que funciona en el navegador, dibujado sobre un mástil en 3D.

## Vídeos y capturas

### BRUTAL: el Coloso

<figure>
<a href="../observatory/brutal/"><img src="../../demos/brutal/colossus-day.jpg" alt="El rostro del enjambre entre las torres, en la bruma de la tarde, con el sol al lado" width="1280" height="536" loading="lazy" /></a>
<figcaption>La tarde: el rostro entre las torres.</figcaption>
</figure>

Un prototipo en C# y Vulkan construido con [BRUTAL](https://github.com/ahwootech/BRUTAL) para probar otro motor para el observatorio. Diez mil cuerpos vuelan entre torres brutalistas y se reúnen en un rostro colosal, con path tracing en una GeForce RTX y DLSS. **[Ver el vídeo de un minuto](../observatory/brutal/)**.

### Lego

<figure>
<img src="../../demos/lego/lego-polis-rtx-20261021.jpg" alt="Una ciudad griega amurallada vista desde arriba al atardecer: casas con tejados de tejas, un ágora, un teatro y una acrópolis sobre su terraza, con las torres del Coloso detrás" width="1600" height="900" loading="lazy" />
<figcaption>La polis: murallas, casas, ágora, teatro y acrópolis, en la ciudad del Coloso.</figcaption>
</figure>

Una pequeña biblioteca de F# compone escenas a partir de bloques tipados y anidados. Una columna, luego una columnata de columnas, luego un templo de columnatas, y así hasta una ciudad amurallada: la polis. Tiene 406 instancias de bloques y 6663 cajas, en cinco niveles de anidamiento: polis, acrópolis, propileo, templo, columnata, columna. Cada bloque coloca a los demás por su nombre y su versión, con sus propios argumentos; ninguno copia la lógica de otro.

La biblioteca no dibuja nada. Genera una escena, luego la valida, y una escena rechazada nunca llega al motor. Sus pruebas funcionan sin motor. La polis y la acrópolis las dibuja BRUTAL con las funciones RTX del Coloso: DLAA y Ray Reconstruction.

<figure>
<img src="../../demos/lego/lego-acropolis-rtx-20261021.jpg" alt="Una acrópolis al atardecer: una gran escalera sube a una terraza con un gran templo, un pórtico entre dos stoas y un tholos redondo, entre torres iluminadas" width="1600" height="900" loading="lazy" />
<figcaption>La acrópolis: una escalera, un pórtico entre dos stoas, templos y un tholos sobre la terraza.</figcaption>
</figure>

<figure>
<img src="../../demos/lego/lego-sanctuary-20261021.png" alt="Un gran templo rodeado de templos más pequeños sobre un plano gris, sin efectos de luz" width="1280" height="720" loading="lazy" />
<figcaption>La primera porción: un santuario de templos alrededor de templos, sin las funciones RTX.</figcaption>
</figure>

Capturas del 2026-10-21. Los bloques, las convenciones y las mediciones están en [las notas de la evaluación de BRUTAL](https://github.com/GuitarAlchemist/ga/blob/644e25db913a53f43b1464677fd130fe79c75090/Experiments/Brutal/README.md#lego-composable-scenes-2026-10-21) (pull request [#840](https://github.com/GuitarAlchemist/ga/pull/840) de Guitar Alchemist, en inglés). Como el Coloso, es un experimento local que no se distribuye; el motor es [BRUTAL](https://github.com/ahwootech/BRUTAL) de Ahwoo, bajo la BRUTAL License v1.0.

## Ver también

La página [Artefactos](../artifacts/) recoge páginas interactivas alojadas en claude.ai, como el *Atlas des Douze* y un banco de colocación de micrófonos.
