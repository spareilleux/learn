---
title: Calcular la longitud de doblado en una capa neutra declarada
description: Calcular la longitud de doblado en una capa neutra declarada — Física
sidebar:
  label: PHY-011 · Calcular la longitud de doblado en una capa neutra declarada
  order: 11
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/physics/es/phy-011-compute-bend-length-on-a-declared-neutral-layer.es.md
---

:::note[Streeling University]
**PHY-011** · Calcular la longitud de doblado en una capa neutra declarada · intermedio · 40 minutos

Generado por el departamento *Física* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/physics/es/phy-011-compute-bend-length-on-a-declared-neutral-layer.es.md) · [Mi diario](../../journal/)

Requisitos previos: [PHY-005](../../physics/phy-005-sheet-thickness-and-scene-units/)
:::

> **Alcance del borrador.** Geometría de doblado circular creada para el curso, cálculos exactos y lectura de código y documentos primarios fijados a una revisión. Quedan pendientes las revisiones humanas técnica, artesanal, lingüística y de estudiantes, así como la verificación del HTML del curso desplegado. No se probaron una probeta de material, una máquina de doblado, un comando CAD, un comprobador IX ni una escena. El factor de capa neutra se estipula, no se calibra.

## La pregunta del proyecto

¿Puede un futuro adaptador de creación inferir la longitud desarrollada de una pieza metálica plana a partir de un informe de espesor de origami? El [ADR de espesor de IX de la revisión fijada](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/docs/adr/0007-origami-thickness-as-parallel-rigid-panels.md#L7-L34) describe comprobaciones de espesor cero con una lectura opcional de paneles paralelos. Excluye explícitamente rechazos por radio de doblado y movimiento de plegado. [PHY-005](../../physics/phy-005-sheet-thickness-and-scene-units/) convierte las unidades de esa lectura; esta lección añade un modelo didáctico separado de doblado sin afirmar que IX lo implemente.

La [referencia de reglas de chapa de Fusion](https://help.autodesk.com/cloudhelp/ENU/Fusion-Sheet-Metal/files/SM-RULES-REF.htm) distingue espesor, radio interior de doblado y razón de desplazamiento del eje neutro. Se leyó su texto real. Esas definiciones motivan las cantidades siguientes, pero no aportan un factor medido para nuestro material o máquina.

## 1. Declarar la capa de referencia

Usa un radio interior didáctico de 4 mm, espesor total 2 mm y factor adimensional de desplazamiento neutro `k=0.4`. Define el radio neutro mediante `R_n=R_i+k*t`, dando 4.8 mm. El radio exterior es 6 mm. Supón capas circulares concéntricas y trata el arco neutro como la longitud desarrollada del doblez; es una regla geométrica simplificada, no una predicción de deformación, recuperación elástica ni comportamiento del utillaje.

Para magnitud de doblado 90 grados, o `pi/2` radianes, la longitud de arco es radio por magnitud angular. Los arcos interior, neutro y exterior son respectivamente `2*pi`, `2.4*pi` y `3*pi` mm. El arco neutro es aproximadamente 7.539822369 mm. Capas de referencia distintas dan longitudes distintas aunque una escena represente la misma región doblada.

### Ejercicio 1: identificar el arco desarrollado

Calcula el radio neutro y las tres longitudes de arco para el doblez declarado. ¿Cuál usa este modelo y describe el factor elegido una probeta física medida?

> **Respuesta:** El radio neutro es `4+0.4*2=4.8` mm. Los arcos interior, neutro y exterior son `2*pi`, `2.4*pi` y `3*pi` mm. El modelo usa el arco neutro `2.4*pi`, aproximadamente 7.539822369 mm. El factor 0.4 es una hipótesis didáctica, no una regla de material medida.

## 2. No sustituir una capa declarada por el punto medio

Elegir el radio a mitad del espesor daría 5 mm y longitud desarrollada de doblez `2.5*pi` mm. Supera la longitud de referencia en `0.1*pi`, aproximadamente 0.314159265 mm. Usar en cambio el arco interior o exterior la cambia en `-0.4*pi` o `0.6*pi` mm.

Ni una línea central renderizada ni la palabra «espesor» eligen automáticamente la capa neutra. Un punto medio geométrico y un desplazamiento neutro calibrado son cantidades distintas. Una aplicación puede mostrar un punto medio por comodidad y conservar una regla de doblado separada; esta lección no observa tal implementación.

### Ejercicio 2: cuantificar una sustitución conveniente

Un agente sustituye silenciosamente el factor estipulado por 0.5. ¿Qué radio, longitud desarrollada de doblez y error resultan? ¿Es una calibración de material un menor error de visualización o un doblez visualmente plausible?

> **Respuesta:** Usa radio 5 mm y longitud desarrollada de doblez `2.5*pi` mm, superando los `2.4*pi` estipulados en `0.1*pi`, aproximadamente 0.314159265 mm. Un resultado visual no calibra el desplazamiento neutro ni demuestra que el modelo sustituido describa un proceso real.

## 3. Indicar dónde terminan las longitudes rectas

Añade dos longitudes rectas didácticas de 30 y 20 mm, cada una medida hasta la tangente donde empieza el doblez circular. El total plano del modelo es por tanto `30+20+2.4*pi`, aproximadamente 57.539822369 mm. La convención de tangencia hace que esas regiones rectas no se solapen con el arco del doblez.

Las dimensiones exteriores de pestañas medidas hasta una esquina viva virtual son otra convención. Sumar esos números al arco completo sin los retrocesos o deducciones adecuados puede contar material dos veces. Aquí no derivamos una fórmula de dimensiones exteriores. Un traspaso debe conservar los extremos de medición en lugar de etiquetar toda longitud como «longitud de pestaña».

### Ejercicio 3: auditar la convención de dimensiones

Calcula el total para las longitudes medidas a tangentes. ¿Puede usarse la misma expresión sin cambios si 30 y 20 denotan en cambio dimensiones exteriores no especificadas hasta una esquina virtual?

> **Respuesta:** El total medido a tangentes es `50+2.4*pi`, aproximadamente 57.539822369 mm. Las dimensiones exteriores no especificadas no justifican esa suma: primero debe resolverse su convención de solapamiento o retroceso. Cambiar la etiqueta de sus números a longitudes tangentes cambiaría el problema.

## 4. Llevar la incertidumbre como un intervalo condicional

Estipula por separado que `k` podría estar entre 0.3 y 0.5 mientras radio, espesor y ángulo permanecen fijos. Los radios neutros van entonces de 4.6 a 5 mm, y las longitudes desarrolladas de dobleces de 90 grados de `2.3*pi` a `2.5*pi` mm. Su anchura es `0.2*pi`, aproximadamente 0.628318531 mm. El total correspondiente es 50 mm más ese intervalo de longitud de doblez.

La longitud desarrollada del doblez cambia en `pi` mm por un cambio unitario de `k` bajo estas premisas fijas. Es sensibilidad del modelo, no una distribución de probabilidad ni un intervalo de confianza. El intervalo elegido es una hipótesis didáctica, no un rango recomendado para cualquier metal, herramienta o proceso de conformado.

### Ejercicio 4: propagar el intervalo de factor estipulado

Deriva el intervalo de longitud desarrollada del doblez, su anchura y el intervalo de longitud total. ¿Qué justificaría tratarlo como un intervalo de proceso real en lugar de un ejemplo didáctico de sensibilidad?

> **Respuesta:** La longitud desarrollada del doblez va de `2.3*pi` a `2.5*pi` mm, con anchura `0.2*pi`; la longitud total va de `50+2.3*pi` a `50+2.5*pi` mm. Harían falta comportamiento medido pertinente del material y proceso y un modelo justificado. La aritmética por sí sola no aporta calibración, probabilidad ni tolerancia de producción.

## 5. Mantener la lectura de IX dentro de su alcance real

El [módulo de espesor de la revisión fijada](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/src/thickness.rs#L1-L22) acepta espesor total en unidades del patrón de pliegues e informa de lecturas de apilamiento. Su texto distingue explícitamente un rechazo de paneles paralelos de una afirmación de fabricabilidad. Las [pruebas de espesor existentes](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/tests/thickness.rs) son aserciones del código sobre ese modelo; no se ejecutó ninguna prueba nueva en este paquete.

### Ejercicio 5: corregir la afirmación de fabricación

Un agente llama a un informe de espesor de IX una pieza metálica plana desarrollada y certificada. ¿Qué cantidades y observaciones adicionales faltan en esa conclusión?

> **Respuesta:** El informe seleccionado no aporta unidades físicas del modelo de doblado circular, radio interior, regla de desplazamiento neutro, convención de ángulo de doblado ni extremos de cotas a tangentes. Un proceso real también necesita calibración pertinente y comprobaciones de recuperación elástica, alivios, utillaje y movimiento o holgura. El cálculo didáctico de arco y una lectura de apilamiento no certifican una pieza física plana ni su fabricación. Aquí no hubo tal ensayo.

El [registro de doblado fijado](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/bend-development-2026-10-22/bend-lengths.json) conserva múltiplos exactos de pi junto a decimales mostrados. [SEM-007](../../semiotics/sem-007-preserve-the-meaning-of-a-bend-angle/) sigue el mismo cálculo a través de distintos significados del ángulo.
