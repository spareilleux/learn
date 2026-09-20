---
title: Artefactos
description: Páginas interactivas construidas con Claude mientras trabajo en mis proyectos — mapas, auditorías y simuladores que complementan los cursos.
---

Mientras trabajo en mis repositorios con [Claude Code](https://code.claude.com/docs/es/overview), algunos análisis terminan convertidos en una página interactiva (un *artefacto*) en lugar de una lección: un mapa, una auditoría, un simulador. Están alojados en claude.ai, se abren en cualquier navegador y se enlazan desde aquí y desde los cursos que ilustran.

:::note[Instantáneas, no cursos]
Cada artefacto está fechado y describe un repositorio en un momento dado. A diferencia de las lecciones, no se mantienen actualizados. Algunos están solo en inglés o en francés.
:::

## Desarrollo asistido por IA

### Playbook SDLC × IX

[Abrir el artefacto](https://claude.ai/code/artifact/9e67e00d-d2a6-4490-b2ed-d485e34be6ab) · francés · 2026-09-13 · IX en `2a84de4`

Las doce jugadas del [AI-Native SDLC Playbook](https://academy.claude.com/courses/ai-native-sdlc-playbook) de Anthropic (plan, design, build, test, deploy, maintain), contrastadas una por una con lo que realmente hacen los repositorios IX y Demerzel. Cada jugada recibe un veredicto en la lógica hexavalente del ecosistema, con la evidencia que lo respalda y la brecha por cerrar. Termina con las cinco brechas prioritarias y cuatro ideas de lecciones para la serie sobre IA agéntica: pruebas que pasan sin probar nada, hooks como puertas de aprobación, separación de funciones con un agente, y decidir antes de implementar.

### Para qué sirve realmente IX

[Abrir el artefacto](https://claude.ai/code/artifact/e1d9e83e-608f-4b20-9061-0026025af1d5) · francés, inglés y español · 2026-09-13 · IX en `ed5e998` (v0.5.0)

Una auditoría de uso de los 81 crates de IX, clasificados según lo que realmente los ejecuta y no según lo que prometen sus README: workflows programados, puertas de PR, contratos consumidos por otros repositorios y comandos lanzados por agentes a lo largo de nueve meses de sesiones. Seis niveles van de los que sostienen carga (12 crates) a los huérfanos (13), y un tercio del código solo es accesible a través de un servidor MCP que los agentes llamaron dos veces. Termina con cinco decisiones y el método detrás de las cifras.

### Demerzel × ComfyUI — Governed Asset Pipeline

[Abrir el artefacto](https://claude.ai/code/artifact/cc15cb21-c3f9-486a-b758-4127000246c8) · inglés · 2026-07-18

Cómo se conectó la generación de imágenes de [ComfyUI](https://docs.comfy.org/) a Demerzel como proveedor gobernado: cada solicitud de textura pasa por una puerta de presupuesto, se ejecuta localmente en la GPU y deja un registro de procedencia (seed, hash del workflow, prompt, consumidor). La puerta de presupuesto es interactiva: elige un proveedor y un coste, y mira cómo permite, bloquea o falla en modo cerrado.

## Música y guitarra

### Banc de Placement

[Abrir el artefacto](https://claude.ai/code/artifact/f685cdc7-8e42-4b1f-9711-c9abb14d378a) · francés e inglés · 2026-08-20

Un banco 3D para colocar dos micrófonos en una guitarra acústica. Mueve los micrófonos y lee la diferencia de recorrido, el desfase temporal y la frecuencia de la primera cancelación del filtro peine cuando los dos canales se suman en mono. Puede superponer el modelo a la imagen de una cámara para comprobar una instalación real.

### Atlas des Douze

[Abrir el artefacto](https://claude.ai/artifact/Qh4oMxFH5aPx9dYC4xGjyn) · francés e inglés · 2026-09-17 · GA en `a826864`

Once láminas 3D interactivas (three.js WebGPU) para el curso Teoría musical para Guitar Alchemist: las doce clases de altura dispuestas como taller, mástil, hélice, brazaletes, los siete modos, el vector interválico, el círculo de quintas, los acordes de una tonalidad, una máquina de cadencias, OPTIC-K y afinaciones. El panel lateral de cada lámina explica lo que muestra y dónde divergen el curso y GA. Algunas texturas de piedra y madera se generaron con ComfyUI (SDXL base 1.0), y la página lo indica junto a cada una.
