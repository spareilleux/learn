---
title: 4. Luces, cámaras, y el render con EEVEE y Cycles
description: 'Luces de área en vatios e iluminación de tres puntos, una cámara orientada desde código, la transformación de vista AgX, y después los dos motores de render — EEVEE, un rasterizador, y Cycles, un trazador de caminos —, con el ruido de Cycles medido frente al número de muestras, una semilla que da los mismos píxeles en Windows, Linux y macOS, el muestreo adaptativo, OpenImageDenoise, y tiempos de CPU, GPU y EEVEE en una máquina.'
sidebar:
  order: 4
---

Código: el script de la lección, [`scripts/l04_render.py`](https://github.com/spareilleux/learn/blob/ced9808/code/blender/scripts/l04_render.py), la escena de [`scripts/stage.py`](https://github.com/spareilleux/learn/blob/ced9808/code/blender/scripts/stage.py), las imágenes de [`scripts/render_images.py`](https://github.com/spareilleux/learn/blob/ced9808/code/blender/scripts/render_images.py), y el informe, [`expected/l04_render.txt`](https://github.com/spareilleux/learn/blob/ced9808/code/blender/expected/l04_render.txt).

## Las luces

Blender tiene cuatro [tipos de luz](https://docs.blender.org/manual/en/5.2/render/lights/light_object.html): **point** (puntual), **spot** (foco), **area** (de área) y **sun** (sol). La potencia de una luz puntual, de foco o de área se expresa en vatios, y la intensidad de un sol en vatios por metro cuadrado, ya que ilumina todo desde una distancia infinita. Son vatios de potencia radiante, la luz realmente emitida, no los vatios eléctricos de la caja de una bombilla. La luz de una luz puntual, de foco o de área disminuye con el cuadrado de la distancia.

Una **luz de área** emite desde un rectángulo o un disco. Cuanto mayor es respecto a su distancia al objeto, más suaves son las sombras y más amplios los brillos, como con la caja de luz (softbox) de un fotógrafo. El tamaño no cambia la potencia: una luz más grande con los mismos vatios la reparte sobre más superficie.

[`stage.py`](https://github.com/spareilleux/learn/blob/ced9808/code/blender/scripts/stage.py) ilumina el diapasón como un estudio ilumina un producto, con **iluminación de tres puntos**: una luz *principal* (key) que da la forma y las sombras principales, una luz *de relleno* (fill) más débil al otro lado que levanta las sombras, y una luz *de contorno* (rim) detrás que perfila los bordes contra el fondo:

```text
== Lights and camera
Fill: AREA 0.6 W size 0.50 m color (0.85, 0.90, 1.00) location (0.35, 0.45, 0.25)
Key: AREA 3.0 W size 0.25 m color (1.00, 0.95, 0.88) location (0.05, -0.45, 0.45)
Rim: AREA 4.0 W size 0.10 m color (1.00, 1.00, 1.00) location (-0.25, 0.20, 0.12)
camera: lens 50.0 mm sensor 36.0 mm horizontal field of view 39.6 degrees location (-0.120, -0.200, 0.140)
world background: (0.020, 0.020, 0.025) strength 1.00
```

La luz principal es ligeramente cálida y la de relleno ligeramente fría, una elección habitual. Los vatios parecen pocos porque la escena es pequeña: las luces están a entre 30 y 65 cm de un diapasón de 48 cm de largo. La primera versión usaba 12, 3 y 15 W, y el render era tan brillante que el palisandro parecía gris. El **world** (mundo) es el entorno que rodea la escena: aquí, un gris oscuro, casi negro, que también ilumina un poco la escena desde todas las direcciones.

Las luces y las cámaras miran a lo largo de su eje −Z local. El script las orienta con un cuaternión:

```python
def aim(obj, target):
    """Points an object's -Z axis (where cameras and lights look) at a target, with +Y up."""
    direction = Vector(target) - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
```

Una restricción **Track To** hace lo mismo y sigue al objetivo cuando se mueve; la lección 7 trata las restricciones. El objetivo de 50 mm de la cámara sobre el sensor de 36 mm por defecto da un campo de visión horizontal de 2 × atan(18 / 50) = 39,6°, un objetivo "normal" en fotografía.

## De los valores de luz a los píxeles: la transformación de vista

Un renderizador calcula valores **referidos a la escena** (scene-referred): cantidades lineales de luz, desde 0 hasta muy por encima de 1 en un brillo intenso. Una pantalla muestra valores **referidos a la pantalla** (display-referred): 8 bits por canal, en sRGB. La [transformación de vista](https://docs.blender.org/manual/en/5.2/render/color_management/displays_views.html) (view transform) convierte unos en otros:

```text
== Color management
display device sRGB | view transform AgX | look None | exposure 0.0 | gamma 1.0
```

La transformación por defecto, **AgX**, es una curva de mapeo de tonos que según el manual mejora a Filmic, con 16,5 pasos de rango dinámico, y que desatura los colores muy brillantes como lo hace la película. **Standard** solo aplica la curva sRGB y recorta todo lo que pasa de 1. La elección cambia el PNG y la imagen en pantalla, pero no los valores lineales que conserva un archivo EXR (ejercicio 3). three.js tiene el mismo pipeline y también ofrece AgX ([lección 3 de three.js](../../threejs/03-color-tone-mapping-environments/)).

## Dos motores de render

Blender 5.2 incluye tres motores, `BLENDER_EEVEE`, `BLENDER_WORKBENCH` y `CYCLES`. Workbench dibuja el sombreado sólido del viewport. Los otros dos renderizan las mismas escenas y los mismos nodos de shader, de dos formas distintas:

- **[EEVEE](https://docs.blender.org/manual/en/5.2/render/eevee/index.html)** es un **rasterizador**, como un motor de videojuegos o three.js: dibuja cada triángulo en la GPU y aproxima las sombras, los reflejos y la luz indirecta con técnicas de coste fijo por fotograma. Es rápido e interactivo, y renderiza a través de la GPU, también en segundo plano: la CI del curso, que no tiene GPU, no lo ejecuta (*por verificar*: EEVEE en una máquina sin GPU).
- **[Cycles](https://docs.blender.org/manual/en/5.2/render/cycles/index.html)** es un **trazador de caminos** (path tracer): para cada píxel sigue caminos de luz aleatorios por la escena, rebotando en las superficies, y hace su media. Tiene base física: las sombras suaves, los reflejos y la luz indirecta salen bien sin trucos, pero el resultado tiene ruido hasta que se ha promediado un número suficiente de caminos. Se ejecuta en la CPU, o en una GPU mediante CUDA u OptiX (NVIDIA), HIP (AMD), oneAPI (Intel) o Metal (Apple), como enumera la [página de render en GPU](https://docs.blender.org/manual/en/5.2/render/cycles/gpu_rendering.html).

![El diapasón renderizado por Cycles con 256 muestras y eliminación de ruido: sombras suaves bajo los trastes y un brillo a lo largo de cada alambre de traste](../../../../assets/blender/l04-cycles.webp)

![La misma escena renderizada por EEVEE con 64 muestras: los mismos materiales, sombras de contacto más nítidas y oscuras, y brillos más planos en los trastes](../../../../assets/blender/l04-eevee.webp)

En la máquina del autor, un Intel Core Ultra 9 285K (24 hilos) y una RTX 5080 con el driver 610.88, los dos renders a 960 × 540 tardaron:

| Render | 1.er proceso de Blender | 2.º proceso | 3.er proceso |
|---|---|---|---|
| Cycles, CPU, 256 muestras, con eliminación de ruido | 4,01 s | 4,40 s | 4,05 s |
| Cycles, GPU con OptiX, 256 muestras, con eliminación de ruido | 3,08 s | 1,89 s | 1,45 s |
| EEVEE, 64 muestras | 11,78 s | 1,14 s, después 0,19 s | 0,92 s, después 0,28 s |

Cada cifra es la duración de una llamada a `bpy.ops.render.render` en [`render_images.py`](https://github.com/spareilleux/learn/blob/ced9808/code/blender/scripts/render_images.py), ejecutado tres veces como procesos de Blender separados; la segunda y la tercera ejecución renderizaron EEVEE dos veces. El primer render de EEVEE compiló los shaders de la escena. Los procesos siguientes tardaron alrededor de un segundo en su primer render de EEVEE, lo que sugiere una caché de shaders en disco (*por verificar*), y el segundo render en el mismo proceso tardó una fracción de eso. La GPU también fue más lenta en su primera ejecución. A este tamaño y con esta escena, la GPU supera a la CPU por un factor de unos 3 y EEVEE supera a ambas, una vez en caliente. Son ejecuciones únicas sobre una escena, no un benchmark.

## Cycles: el ruido y las muestras

El valor de un píxel en Cycles es una **estimación de Monte Carlo**: la media de N muestras aleatorias. El error de una media así disminuye como 1/√N, así que reducir el ruido a la mitad exige cuatro veces más muestras. El script lo comprueba. Renderiza la escena a 160 × 90 con 4.096 muestras como referencia, y después con menos muestras, con el muestreo adaptativo y la eliminación de ruido desactivados, guarda cada render como un EXR de 32 bits, y mide la raíz de la diferencia cuadrática media de los valores lineales respecto a la referencia:

```text
== Cycles settings
device CPU | samples 4096 | adaptive True threshold 0.010 | denoise True OPENIMAGEDENOISE | seed 0 | max bounces 12 | clamp indirect 10.0

== Noise against the sample count (160 x 90, no adaptive sampling, no denoising)
reference: 4096 samples, mean linear RGB (0.051, 0.036, 0.036)
   1 samples: RMS difference from the reference 0.0519
   4 samples: RMS difference from the reference 0.0233 | previous / this 2.23
  16 samples: RMS difference from the reference 0.0122 | previous / this 1.90
  64 samples: RMS difference from the reference 0.0065 | previous / this 1.88
 256 samples: RMS difference from the reference 0.0028 | previous / this 2.29
```

Cada vez que se multiplican las muestras por cuatro, el error se divide aproximadamente por 2, como predice 1/√N. Las razones oscilan entre 1,88 y 2,29 porque la referencia tiene su propio ruido, y una imagen de 160 × 90 es una muestra pequeña. La primera línea muestra los valores de fábrica: 4.096 muestras como máximo ([`properties.py`](https://projects.blender.org/blender/blender/src/commit/d13f752e3b9c4f8c261cda552b1021f8bcc0382c/intern/cycles/blender/addon/properties.py#L485-L490)), muestreo adaptativo y eliminación de ruido.

![Cuatro renders del diapasón: 1 muestra, lleno de motas de colores; 16 muestras, granuloso; 16 muestras con eliminación de ruido, liso; 256 muestras, casi liso](../../../../assets/blender/l04-samples.webp)

Arriba a la izquierda, 1 muestra; arriba a la derecha, 16; abajo a la izquierda, 16 con OpenImageDenoise; abajo a la derecha, 256.

### El muestreo adaptativo

Con el [muestreo adaptativo](https://docs.blender.org/manual/en/5.2/render/cycles/render_settings/sampling.html), Cycles deja de muestrear un píxel en cuanto su ruido estimado cae por debajo del **noise threshold** (umbral de ruido), así que los píxeles lisos del fondo se detienen pronto y los bordes de los trastes siguen. El número de muestras pasa a ser un máximo. El ejercicio 2 mide lo que ahorra.

### La semilla

Los números aleatorios vienen de un muestreador inicializado con una **semilla**, como `new Random(seed)` en C# o Java. La misma semilla da la misma imagen; otra semilla da la misma media con otro patrón de ruido:

```text
== The seed
16 samples, seed 0 twice: identical True | seed 0 and seed 1: identical False RMS between them 0.0173
```

Para una animación, **Use Animated Seed** cambia la semilla en cada fotograma, porque un patrón de ruido que se queda quieto mientras la imagen se mueve se nota más que uno que cambia.

La reproducibilidad va más allá de una máquina. El script guarda el render de 16 muestras como PNG de 8 bits y calcula el hash de sus píxeles:

```text
== The same render, 8 bits after the view transform
pixels sha256 52b315b4edce59f3eaad17709705db365ed4cefa92c2c5a15053bef2d06be536
mean 8-bit RGB (48.5, 42.5, 43.4)
```

`check.sh` compara ese hash, y en la CI del curso es el mismo en Windows y Linux sobre x86-64 y en macOS sobre Apple Silicon ([ejecución 35172142583](https://github.com/spareilleux/learn/actions/runs/35172142583)): los renders en CPU de esta escena son idénticos bit a bit en los tres sistemas operativos y las dos arquitecturas de CPU. Fue un resultado, no una suposición; al principio el script imprimía el hash sin compararlo, hasta que una ejecución de CI mostró que los tres coincidían. Los renders en GPU no se compararon.

### La eliminación de ruido

Un denoiser es una red neuronal que estima la imagen limpia a partir de un render con ruido, usando pasadas adicionales como los colores y las normales de las superficies. Cycles ofrece [OpenImageDenoise](https://www.openimagedenoise.org/), de Intel, en la CPU o en una GPU, y el denoiser OptiX de NVIDIA:

```text
== Denoising
16 samples + OpenImageDenoise: RMS difference from the reference 0.0101 | without: 0.0122
```

La imagen sin ruido parece mucho más limpia que la ruidosa, como muestra la imagen de arriba, pero su error respecto a la referencia solo es un 17 % menor, más o menos. El ruido ha desaparecido, pero el denoiser tiene que adivinar el detalle que había debajo, y a 160 × 90 los trastes y los marcadores miden unos pocos píxeles: sus conjeturas son suaves, no exactas. La eliminación de ruido ayuda más cuando los detalles son grandes en comparación con los píxeles, y unas pocas muestras más le ayudan a adivinar mejor.

## Puntos clave

- Las luces puntuales, de foco y de área se miden en vatios de potencia radiante, el sol en vatios por metro cuadrado; el tamaño de una luz de área fija la suavidad de sus sombras.
- Los renders son lineales; la transformación de vista, AgX por defecto, los adapta a la pantalla, y un EXR conserva los valores lineales.
- EEVEE rasteriza en la GPU y es rápido una vez compilados sus shaders; Cycles traza caminos en la CPU o en la GPU y tiene base física, pero produce ruido.
- El ruido de Cycles disminuye como 1/√N: cuatro veces más muestras para la mitad de ruido. El muestreo adaptativo gasta las muestras donde está el ruido.
- Una semilla fija da renders idénticos; aquí, el render en CPU fue idéntico bit a bit en Windows, Linux y macOS.
- La eliminación de ruido quita el ruido, no el error: adivina el detalle que no puede ver.

## Ejercicios

1. Duplica la potencia de la luz principal, renderiza con 256 muestras y compara el RGB lineal medio con la referencia. ¿Por qué no se duplica la media?
2. Activa el muestreo adaptativo con un noise threshold de 0,01 y 4.096 muestras como máximo. ¿Cómo es su error comparado con 256 muestras sin él, y cuánto tarda?
3. Cambia la transformación de vista a **Standard** y vuelve a renderizar con 16 muestras, a un PNG y a un EXR. ¿Qué cambia?

<details>
<summary>Solución 1</summary>

```text
== Exercise 1: twice the key light
mean linear RGB at 256 samples: key 6 W (0.063, 0.041, 0.039) | key 3 W (reference) (0.051, 0.036, 0.036)
```

La media sube alrededor de un 24 % en el rojo, no un 100 %. La luz se suma: la luz de relleno, la de contorno y el world no cambiaron, y buena parte de la imagen es fondo al que la luz principal no llega. Duplicar una luz solo duplica su propia contribución.

</details>

<details>
<summary>Solución 2</summary>

```text
== Exercise 2: adaptive sampling
adaptive, threshold 0.01, at most 4096 samples: RMS difference from the reference 0.0018
```

Su error, 0,0018, es menor que el de 256 muestras (0,0028). En la máquina del autor tardó 0,26 s, frente a 1,40 s para la referencia de 4.096 muestras sin muestreo adaptativo, y unos 0,1 s para 256 muestras. Los tiempos son las líneas que `check.sh` no compara.

</details>

<details>
<summary>Solución 3</summary>

```text
== Exercise 3: the Standard view transform
mean 8-bit RGB: Standard (54.5, 48.3, 49.8) | AgX (48.5, 42.5, 43.4)
the linear EXR is the same under both view transforms: True
```

El PNG es más claro con Standard: AgX comprime los tonos para dejar sitio a los brillos, y Standard no. El EXR es idéntico, porque guarda los valores lineales de antes de la transformación de vista.

</details>

## Fuentes

- Manual de Blender 5.2: [objetos de luz](https://docs.blender.org/manual/en/5.2/render/lights/light_object.html), [pantallas y vistas](https://docs.blender.org/manual/en/5.2/render/color_management/displays_views.html), [EEVEE](https://docs.blender.org/manual/en/5.2/render/eevee/index.html), [Cycles](https://docs.blender.org/manual/en/5.2/render/cycles/index.html), [muestreo](https://docs.blender.org/manual/en/5.2/render/cycles/render_settings/sampling.html), [render en GPU](https://docs.blender.org/manual/en/5.2/render/cycles/gpu_rendering.html), [caminos de luz](https://docs.blender.org/manual/en/5.2/render/cycles/render_settings/light_paths.html).
- Código fuente de Blender en la 5.2.2: los ajustes de render de Cycles en [`intern/cycles/blender/addon/properties.py`](https://projects.blender.org/blender/blender/src/commit/d13f752e3b9c4f8c261cda552b1021f8bcc0382c/intern/cycles/blender/addon/properties.py).
- [OpenImageDenoise](https://www.openimagedenoise.org/).
- M. Pharr, W. Jakob, G. Humphreys, [Physically Based Rendering: From Theory to Implementation](https://pbr-book.org/), 4.ª edición, capítulo 2 sobre la integración de Monte Carlo.
