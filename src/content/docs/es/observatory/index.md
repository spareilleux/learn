---
title: Observatorio interactivo
description: Explora un prototipo 3D de Godot con un modelo de Blender y texturas generadas localmente con ComfyUI.
sidebar:
  label: Observatorio
  order: 0
---

[Abrir el observatorio 3D](../../demos/observatory/) en un navegador de escritorio compatible con WebGL 2. La primera carga descarga aproximadamente 51 MB de motor y escena. No se admiten teléfonos ni tabletas: se necesita un teclado y un ratón.

Haz clic en la escena para mirar alrededor. Muévete con **WASD** o **ZQSD**; mantén **Shift** para correr. **Esc** libera el ratón. Si el navegador no permite capturar el puntero, mantén pulsado el botón derecho y arrastra para mirar. Las teclas **1–7** cambian el punto de vista; **F** activa el vuelo libre, **E/Espacio** sube y **C** baja. La cámara permite explorar, pero aún no hay un personaje con colisiones. La captura del ratón se verificó en la versión nativa; su comportamiento en una ventana normal de Chrome, Edge o Firefox aún debe probarse. Comunica cualquier problema específico del navegador.

Todos los cursos del sitio están en las estanterías de la biblioteca. En la planta baja, cada área del sitio tiene su tramo, con una placa, y sus cursos están de frente, a la altura de los ojos. Apunta a un volumen, con la mira cuando el ratón está capturado o con el puntero, para ver su ficha; haz clic en él o pulsa **Intro** para abrir el curso en una pestaña nueva. La tecla **L** muestra el catálogo de todos los cursos. La escena lee la lista de cursos del sitio al arrancar, así que un curso nuevo llega a las estanterías sin una nueva versión de la escena. Los títulos están en el idioma de la página de la que vienes o, si no, en el de tu navegador.

El prototipo incluye un portal de acero texturizado creado en Blender y texturas generadas localmente con ComfyUI. El mármol, el grano de las encuadernaciones, la piedra labrada, la suciedad del acero y tres paneles de vidriera (sol y luna, un árbol élfico, un alambique) proceden del modelo SDXL 1.0 ya almacenado; el ornamento de pilar, de SDXL 1.0 con ControlNet Union SDXL. Los shaders los convierten en encuadernaciones de cuero y tela con nervios y filetes dorados, piedra aparejada con juntas y casetones, acero cepillado y vidrieras retroiluminadas. La balaustrada tiene balaustres torneados de bronce bajo un pasamanos de nogal.

El renderizado nativo más rico usa Godot Forward+: reflejos en pantalla, iluminación indirecta, niebla volumétrica y resplandor. La versión web usa el renderizador Compatibility de WebGL 2, donde esos efectos nativos se reducen o no están disponibles: las vidrieras no proyectan haces de luz, y los libros, el bronce y el acero reciben compensaciones sencillas por la iluminación indirecta que falta. Ninguna versión afirma usar trazado de rayos por hardware en tiempo real: Blender Cycles horneó las texturas de acero, pero no renderiza la escena interactiva.

La sala sigue siendo estilizada, sobre todo el haz central, y las letras de los lomos son glifos decorativos, no títulos legibles; solo los volúmenes de los cursos llevan títulos reales. Es un prototipo jugable, no un entorno fotorrealista terminado. Los cursos de [Blender](../blender/) y [ComfyUI](../comfyui/) explican las herramientas de creación de assets.

Créditos y licencias: [Godot Engine y bibliotecas incluidas](../../demos/observatory/LICENSES.txt); [licencia del modelo SDXL 1.0](https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/blob/main/LICENSE.md) (CreativeML Open RAIL++-M); [ControlNet Union SDXL](https://huggingface.co/xinsir/controlnet-union-sdxl-1.0) (Apache-2.0). Las texturas generadas son assets, no una redistribución de los pesos de los modelos.
