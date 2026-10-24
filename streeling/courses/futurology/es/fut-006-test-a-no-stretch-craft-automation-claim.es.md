---
module_id: fut-006-test-a-no-stretch-craft-automation-claim
department: futurology
course: "Probar una promesa de automatización creativa sin estiramiento"
level: intermediate
prerequisites: ["fut-003-agent-substitution-readiness-drill", "phy-011-compute-bend-length-on-a-declared-neutral-layer", "sem-007-preserve-the-meaning-of-a-bend-angle"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Probar una promesa de automatización creativa sin estiramiento

> **Alcance del borrador.** Cálculos didácticos de superficies ideales, contraejemplos de capacidades y lectura de código y documentos primarios fijados a una revisión. Quedan pendientes las revisiones humanas técnica, artesanal, lingüística y de estudiantes, así como la verificación del HTML del curso desplegado. No se realizaron un desarrollo en CAD, una superficie en el entorno anfitrión, una comprobación completa de IX, una exportación de malla ni fabricación física.

## La pregunta del proyecto

Un futuro agente de creación promete convertir cualquier superficie de escena en una pieza plana exacta sin estiramiento. Antes de estimar cuándo llegará esa capacidad, ¿podemos declarar un modelo y un caso que refuten la afirmación? La prospectiva necesita un objetivo acotado y una prueba discriminante, no un nombre más ambicioso para una vista previa.

La [documentación de Rhino UnrollSrf](https://docs.mcneel.com/rhino/8/help/en-us/commands/unrollsrf.htm) distingue superficies desarrollables de aplanamientos aproximados o dependientes del material y trata costuras, tolerancias y riesgos. También dice que esas herramientas no se diseñaron para doblar o desplegar chapa como en conductos. Leer la documentación no es observar la ejecución de un comando ni afirmar que otra herramienta implemente el mismo comportamiento.

## 1. Probar la premisa geométrica sin restricciones

La [guía de matemáticas de superficies de Rhino](https://developer.rhino3d.com/en/guides/general/essential-mathematics/parametric-curves-surfaces/) define la curvatura de Gauss como producto de curvaturas principales. En ejemplos didácticos basados en milímetros, un plano tiene curvaturas principales 0 y 0; un cilindro de radio 10 tiene 0 y `1/10`; una esfera de radio 10 tiene `1/10` y `1/10`. Sus curvaturas de Gauss son 0, 0 y `1/100` en `mm^-2`.

Para un desarrollo exacto, suave y regular que conserve la métrica intrínseca de la superficie, una curvatura de Gauss no nula es un obstáculo. Por tanto, la esfera refuta la promesa sin restricciones de desarrollo suave sin estiramiento en este modelo. No demuestra que no pueda fabricarse una esfera, aproximarla con paneles ni conformarla mediante deformación del material. Son objetivos y procesos distintos.

### Ejercicio 1: localizar un caso que refute la afirmación

Calcula los tres productos de curvaturas e identifica un contraejemplo al aplanamiento exacto y suave sin estiramiento de toda superficie. ¿Refuta el contraejemplo cualquier forma de hacer un objeto esférico?

> **Respuesta:** Los productos de plano y cilindro son 0; el de la esfera es `1/100 mm^-2`. La esfera refuta la promesa sin restricciones bajo las hipótesis declaradas de regularidad, suavidad y ausencia de estiramiento. No refuta conformado con deformación ni una aproximación distinta facetada u otro proceso de fabricación.

## 2. Especificar un caso positivo abordable

Toma un cilindro ideal didáctico de espesor cero, radio 10 mm y altura 30 mm. Un parche de cuarto de cilindro tiene extensión angular `pi/2`; la coordenada circunferencial desarrollada es la longitud de arco `x=R*theta`, mientras la coordenada axial no cambia. Su anchura plana es `5*pi` mm y su altura 30 mm, así que su área es `150*pi` mm cuadrados.

Es un caso positivo analítico para una superficie de referencia seleccionada. No es un objeto IX analizado, una pieza plana emitida ni un doblez calibrado de espesor finito. [PHY-011](../../physics/en/phy-011-compute-bend-length-on-a-declared-neutral-layer.md) sitúa por separado una capa neutra en un modelo didáctico de espesor. Elegir qué superficie se desarrolla forma parte de la definición del objetivo.

### Ejercicio 2: hacer medible el hito

Indica las dimensiones planas y el área del parche de un cuarto. ¿Qué hipótesis de superficie de referencia y proceso deben seguir asociadas antes de presentarlo como un futuro hito de automatización?

> **Respuesta:** La anchura es `5*pi` mm, la altura 30 mm y el área `150*pi` mm cuadrados. Conserva el cilindro ideal de espesor cero, radio, extensión angular, longitud axial, unidades y superficie de referencia elegida. Estas dimensiones no incluyen una regla calibrada de capa neutra, un proceso físico de doblado ni una exportación satisfactoria del entorno anfitrión.

## 3. Comparar las distancias correctas

A la misma altura axial, el camino circunferencial curvo del cuarto de cilindro tiene longitud `5*pi`, aproximadamente 15.707963268 mm. Su cuerda espacial entre extremos es `10*sqrt2`, aproximadamente 14.142135624 mm. La cuerda atraviesa el espacio interior del cilindro; no es ese camino sobre la superficie.

Un desarrollo intrínseco puede conservar el camino curvo superficial mientras cambia la separación euclídea 3D entre sus extremos. Rechazarlo porque no se conservan todas las cuerdas espaciales probaría la equivalencia equivocada. A la inversa, hacer coincidir unas cuantas cuerdas mostradas o una caja envolvente no verificaría la métrica superficial.

### Ejercicio 3: evitar un rechazo falso

Indica las longitudes del camino de un cuarto y de la cuerda. ¿Demuestra su diferencia que el desarrollo analítico estiró la superficie? Enuncia qué longitud conserva el desarrollo afirmado.

> **Respuesta:** El camino superficial es `5*pi`, aproximadamente 15.707963268 mm; la cuerda es `10*sqrt2`, aproximadamente 14.142135624 mm. Miden caminos distintos. Su diferencia no demuestra estiramiento superficial: el desarrollo conserva longitudes intrínsecas de caminos sobre la superficie, no todas las cuerdas espaciales.

## 4. Nombrar la costura en una afirmación global

Toda la superficie lateral del cilindro tiene anchura `20*pi` y altura 30 al abrirse por una costura axial; su área es `600*pi` mm cuadrados. Antes de cortar, los parámetros angulares 0 y `2*pi` identifican la misma ubicación superficial. En el rectángulo se convierten en lados de borde opuestos. Por tanto, una correspondencia de costura forma parte de esta construcción, en lugar de demostrar que el lazo cerrado original ya tenía una única carta rectangular sin cortes.

La curvatura de Gauss cero es una propiedad geométrica local. Por sí sola no garantiza un desarrollo global, sin cortes y uno a uno, ni un certificado físico de fabricación. La superficie original y su carta abierta deben compararse con el tratamiento declarado de la costura.

### Ejercicio 4: cuestionar una condición global ausente

Indica las dimensiones y el área de toda la superficie lateral abierta. ¿Qué ubicaciones de entrada coincidentes se convierten en lados planos distintos y por qué curvatura cero no establece la afirmación global propuesta sin cortes?

> **Respuesta:** El rectángulo mide `20*pi` por 30 mm con área `600*pi` mm cuadrados. Los parámetros de entrada 0 y `2*pi` son la misma ubicación del cilindro, pero se corresponden con lados opuestos de la costura. Un corte seleccionado y una correspondencia abren ese lazo; la prueba local de curvatura cero no elimina el requisito global de costura.

## 5. Prever una capacidad acotada y después exigir pruebas

El [ADR de espesor de IX de la revisión fijada](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/docs/adr/0007-origami-thickness-as-parallel-rigid-panels.md#L7-L34) delimita su lectura de paneles paralelos por separado del radio de doblado y el movimiento. No aporta pruebas de ejecución para los ejemplos de cilindros. Una vista previa, una comprobación declarada de plegado plano, un desarrollo ideal y un proceso calibrado de fabricación son capacidades distintas.

Un hito candidato menor consiste en comparar un parche de superficie de referencia declarado y su carta usando tolerancias explícitas de longitud y área y correspondencia de costura. Sus hipótesis son geometría ideal regular y el dominio elegido. Una objeción fuerte es que una construcción analítica manual quizá ya satisfaga la necesidad inmediata de la escena, mientras un adaptador nuevo añade conversión, validación y mantenimiento. Esa alternativa más sencilla debería probarse antes de considerar necesario un nuevo DSL. Una comprobación métrica o de costura fallida rechazaría la afirmación geométrica del candidato; radio físico, espesor, regla neutra, alivios, utillaje, recuperación elástica y movimiento siguen siendo obligaciones separadas sin resolver.

### Ejercicio 5: corregir la previsión de automatización

Un agente convierte un cilindro visualmente plausible y un informe de apilamiento aprobado en «todas las superficies de creación darán piezas planas listas para fabricar». Sustituye esa previsión por un candidato refutable e identifica las pruebas que siguen haciendo falta.

> **Respuesta:** Un candidato acotado desarrollaría el parche cilíndrico ideal declarado, conservando superficie de referencia, unidades y costuras y comprobando longitudes y área intrínsecas frente a tolerancias declaradas. El contraejemplo de la esfera rechaza la promesa sin restricciones de desarrollo suave sin estiramiento. Un informe de apilamiento y una vista previa no aportan un adaptador ejecutado, una regla calibrada de espesor finito ni pruebas del proceso. Compara primero la construcción analítica más sencilla; los resultados reales del entorno anfitrión y de fabricación siguen sin verificarse.

El [registro de alcance](../../../../code/streeling/evidence/bend-development-2026-10-22/development-scope.json) conserva casos positivos, contraejemplos y afirmaciones pendientes distintas. Estas lecciones no ratifican ningún nuevo DSL de fabricación ni política de despliegue.
