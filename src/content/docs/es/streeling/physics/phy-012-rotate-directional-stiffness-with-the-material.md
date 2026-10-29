---
title: Rotar la rigidez direccional con el material
description: Rotar la rigidez direccional con el material — Física
sidebar:
  label: PHY-012 · Rotar la rigidez direccional con el material
  order: 12
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/physics/es/phy-012-rotate-directional-stiffness-with-the-material.es.md
---

:::note[Streeling University]
**PHY-012** · Rotar la rigidez direccional con el material · intermedio · 45 minutos

Generado por el departamento *Física* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/physics/es/phy-012-rotate-directional-stiffness-with-the-material.es.md) · [Mi diario](../../journal/)

Requisitos previos: [PHY-006](../../physics/phy-006-check-weave-scene-units/), [PHY-008](../../physics/phy-008-keep-surface-normals-perpendicular/)
:::

> **Alcance del borrador.** Cálculos didácticos de muelles lineales y lectura de código fijado a una revisión. Quedan pendientes las revisiones humanas técnica, artesanal, lingüística y de estudiantes reales. No se probaron una probeta de material, una simulación de Godot ni una prueba de IX. La disponibilidad pública del código y el HTML desplegado del curso son comprobaciones de publicación separadas.

## La pregunta del proyecto

¿Puede girar en el observatorio un objeto con aspecto tejido determinar cómo resiste una carga? [PHY-006](../../physics/phy-006-check-weave-scene-units/) establece longitudes y unidades de escena; [PHY-008](../../physics/phy-008-keep-surface-normals-perpendicular/) establece transformaciones de normales. Ninguno aporta una ley de respuesta del material. Esta lección añade un modelo didáctico de muelle de dos grados de libertad, no un tensor continuo de tejido ni una simulación textil calibrada.

La [transcripción de la clase del MIT sobre muelles lineales](https://ocw.mit.edu/courses/res-2-002-finite-element-procedures-for-solids-and-structures-spring-2010/5195e8fac694f612c5bac7515b05f6ef_oNqSzzycRhw.pdf) presenta equilibrio de rigidez y energía cuadrática de deformación. Se leyó su texto; no se inspeccionaron el vídeo de la clase ni las figuras del PDF. Usamos esas relaciones lineales con números estipulados.

## 1. Declarar la respuesta y sus unidades

Sea el desplazamiento local `u` en mm, la fuerza `f` en N y la rigidez `K_local=[[4,0],[0,1]]` en N/mm. Define `f=K*u` y energía almacenada `E=0.5*u^T*K*u` en N*mm. Las dos coordenadas describen una respuesta ideal de muelle lineal alrededor de un equilibrio. Son ejes planos abstractos, sin correspondencia prescrita con ángulos de Euler de Godot ni altura del mundo.

### Ejercicio 1: comparar los ejes locales

Halla fuerza y energía para desplazamientos locales `[1,0]` y `[0,1]`. ¿Qué establece la diferencia sobre una muestra tejida real?

> **Respuesta:** Las fuerzas son `[4,0]` N y `[0,1]` N; las energías son 2 y 0.5 N*mm. El modelo depende de la dirección porque sus rigideces estipuladas difieren. Estos cálculos no establecen ninguna propiedad medida de un textil físico.

## 2. Rotar la respuesta del material, no solo la silueta

Para una rotación matemática activa, define `R=[[cos(theta),-sin(theta)],[sin(theta),cos(theta)]]`. Las cantidades transformadas son `u_world=R*u_local`, `K_world=R*K_local*R^T` y `f_world=R*f_local`. La transpuesta es aquí la inversa porque la rotación es ortogonal.

En un cuarto de vuelta, `K_world=[[1,0],[0,4]]`. Por tanto, una geometría idéntica puede acompañarse de respuestas distintas a la misma fuerza del mundo. Bajo fuerza `[1,0]` N, el modelo sin rotar tiene desplazamiento `[0.25,0]` mm, mientras el material girado un cuarto de vuelta tiene `[1,0]` mm. Una malla sin su ley de respuesta ni marco del material no identifica qué respuesta se pretendía.

### Ejercicio 2: mantener fija la prueba en el mundo

Para desplazamiento del mundo `[1,0]` mm, compara fuerza y energía antes y después del cuarto de vuelta. Explica después el ejemplo anterior de desplazamiento a fuerza fija.

> **Respuesta:** Antes de rotar, la fuerza es `[4,0]` N y la energía 2 N*mm; después son `[1,0]` N y 0.5 N*mm. Para fuerza fija `[1,0]` N, resolver los dos sistemas diagonales da en cambio `[0.25,0]` y `[1,0]` mm. Fijar fuerza y fijar desplazamiento son experimentos distintos; ninguna respuesta se deriva de la geometría por sí sola.

## 3. Conservar términos de acoplamiento

A 45 grados, `K_world=[[2.5,1.5],[1.5,2.5]]`. Un desplazamiento del mundo `[1,0]` mm produce fuerza `[2.5,1.5]` N y energía 1.25 N*mm. La fuerza transversal forma parte de la respuesta rotada. Sustituir la matriz por su diagonal cambia el modelo.

### Ejercicio 3: revelar una sustitución de solo diagonal

Para desplazamiento del mundo `[1,-1]` mm a 45 grados, calcula fuerza y energía. Compara con la energía obtenida tras quitar silenciosamente las entradas fuera de la diagonal.

> **Respuesta:** La matriz completa da `[1,-1]` N y energía 1 N*mm. Conservar solo entradas diagonales da fuerza `[2.5,-2.5]` N y energía 2.5 N*mm. Los términos eliminados contienen acoplamiento; omitirlos no es una rotación equivalente.

## 4. Distinguir covarianza de coordenadas de un experimento nuevo

Si desplazamiento y respuesta se rotan juntos, la energía no cambia: sustituir las cantidades transformadas cancela los factores adyacentes de transpuesta y rotación. La fuerza rota con el desplazamiento. Esto difiere de las pruebas fijas en el mundo anteriores, donde cambia la dirección del material respecto a un desplazamiento impuesto sin cambios.

El [registro didáctico de respuesta](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/weave-material-2026-10-22/directional-response.json) contiene 36 casos de covarianza en 6 ángulos y 6 desplazamientos, más pruebas separadas fijas en el mundo. Se conservan residuos de coma flotante junto a ejemplos ideales de cuarto de vuelta y ángulo diagonal. Son comprobaciones matemáticas, no observaciones del motor nativo. Los valores propios siguen siendo 1 y 4 N/mm, así que la energía cuadrática estipulada es positiva para cualquier desplazamiento no nulo.

### Ejercicio 4: nombrar el invariante

¿Por qué puede seguir invariante la energía bajo rotación de coordenadas y material mientras un desplazamiento fijo en el mundo da otra energía? ¿Valida una energía cuadrática positiva un modelo de tejido real?

> **Respuesta:** La covarianza rota el desplazamiento junto con la rigidez y describe el mismo estado relativo. La prueba fija en el mundo cambia su dirección relativa. La energía positiva se deriva de los dos valores propios positivos de este modelo lineal ideal; no valida comportamientos no lineales, de deslizamiento, pandeo o irreversibles del tejido real.

## 5. Leer los límites reales de escena y API

La [escena didáctica de Learn de la revisión fijada](https://github.com/spareilleux/learn/blob/eebf49cb0b69a314bd13015340335a983aa64bfe/code/streeling/weave-godot/trial.gd) crea cajas separadas con materiales coloreados y cuerpos estáticos de colisión. La [anisotropía de renderizado de Godot](https://docs.godotengine.org/en/4.6/classes/class_basematerial3d.html#class-basematerial3d-property-anisotropy-enabled) cambia un reflejo especular en espacio tangente. [PhysicsMaterial](https://docs.godotengine.org/en/4.6/classes/class_physicsmaterial.html) describe propiedades de colisión como fricción y rebote. [StaticBody3D](https://docs.godotengine.org/en/4.6/classes/class_staticbody3d.html) no se mueve bajo fuerzas ni contactos externos. Ninguno de estos controles seleccionados implementa la ley de muelle anterior.

El [ADR de espesor de IX de la revisión fijada](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/docs/adr/0007-origami-thickness-as-parallel-rigid-panels.md) define una lectura geométrica de paneles paralelos, no una respuesta de rigidez medida. Una disposición cíclica de capas puede pasar reglas de capas seleccionadas y aun así rechazar una pila rígida paralela de espesor positivo; no es una imposibilidad universal de fabricación.

### Ejercicio 5: preparar un ensayo de material con acceso a las fuentes

Lee la escena y las tres referencias de Godot. Un agente propone ajustar anisotropía de renderizado y fricción para calibrar rigidez de urdimbre. Corrige la afirmación y especifica las pruebas necesarias para una comparación futura útil.

> **Respuesta:** La forma del reflejo y la fricción de colisión no aportan esta ley direccional de muelle, y los cuerpos estáticos actuales no pueden demostrar deformación causada por carga. Conserva geometría de probeta, direcciones del material, unidades, condiciones de contorno, fuerzas aplicadas y desplazamientos medidos; ajusta un modelo de respuesta elegido explícitamente y reserva casos independientes de carga y dirección para comprobarlo. Compara una referencia sencilla de muelle ajustado antes de proponer un solucionador más rico. Registra incertidumbre, casos de fallo y revisión artesanal. Aquí no hubo calibración, integración de solucionador ni ensayo físico.
