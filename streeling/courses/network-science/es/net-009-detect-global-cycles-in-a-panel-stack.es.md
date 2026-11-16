---
module_id: net-009-detect-global-cycles-in-a-panel-stack
department: network-science
course: "Detectar ciclos globales en una pila de paneles"
level: intermediate
prerequisites: ["net-006-instance-and-resource-graphs", "sem-008-interpret-layer-order-relative-to-the-reference-normal"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Detectar ciclos globales en una pila de paneles

> **Alcance del borrador.** Grafos abstractos didácticos y lectura de código y pruebas fijados a una revisión. No se generó ninguna geometría FOLD nueva ni se realizó una ejecución nativa de IX, una prueba física de paneles o un ensayo de fabricación. Quedan pendientes las revisiones humanas técnica, artesanal, lingüística y de estudiantes; el HTML desplegado del curso se comprueba por separado.

## La pregunta del proyecto

¿Puede el observatorio aceptar cada cruce individual de un tejido y aun así no conseguir situar paneles rígidos en alturas globalmente coherentes? El [ADR de paneles paralelos de IX de la revisión fijada](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/docs/adr/0007-origami-thickness-as-parallel-rigid-panels.md) distingue una lectura local de capas de una altura por panel rígido paralelo. Su espesor es total en unidades del patrón de pliegues, no automáticamente milímetros. [SEM-008](../../semiotics/en/sem-008-interpret-layer-order-relative-to-the-reference-normal.md) explica cómo una relación suministrada de capas se interpreta como una afirmación de encima o debajo.

Aquí una arista dirigida va del panel inferior al superior. El [código de espesor](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/src/thickness.rs#L142-L204) usa esa convención tras fusionar caras conectadas por uniones planas. Su arista unitaria de grafo no es una fuerza física ni una altura medida.

## 1. Sumar las restricciones globales

Usa cuatro paneles didácticos y aristas `A->B`, `B->C`, `C->D`, `D->A`. Para espesor total positivo `t`, exige `z_upper>=z_lower+t` en cada arista. Sumar cancela las cuatro variables de altura y da `0>=4*t`. Un espesor positivo lo hace imposible en este modelo de paneles paralelos.

Cada cruce aún puede tener una pareja inferior/superior localmente coherente. La contradicción aparece cuando esas relaciones deben compartir la misma altura de panel entre cruces distintos. Estas etiquetas didácticas no son identificadores de caras de un nuevo caso de IX ejecutado.

### Ejercicio 1: mostrar la contradicción global

Escribe las cuatro desigualdades de separación y su suma para `t=0.5` unidades del patrón de pliegues. ¿Significa el fallo de este modelo global que cada cruce individual era localmente contradictorio?

> **Respuesta:** Las desigualdades son `z_B>=z_A+t`, `z_C>=z_B+t`, `z_D>=z_C+t` y `z_A>=z_D+t`. Su suma da `0>=4*t`, por tanto `0>=2`, que es falso. El ciclo acopla cruces distintos mediante una altura por panel; un único cruce local no tiene por qué contener una contradicción.

## 2. Conservar el límite de espesor cero

En `t=0`, las mismas desigualdades permiten que coincidan todas las alturas. El grafo dirigido sigue teniendo un ciclo. La [prueba de tejido de la revisión fijada](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/tests/thickness.rs#L281-L305) espera que el análisis de capas pase mientras la lectura rígida informa de un ciclo. El rechazo depende de que el espesor sea positivo.

Para ese caso cíclico del código, `rigid.levels` y `rigid.height` siguen siendo null incluso a espesor cero; la altura local separada de capas es cero. No sustituyas un testigo rígido ausente por un testigo numérico inventado. Son aserciones leídas en el código de pruebas, no resultados nuevos.

### Ejercicio 2: separar estado del grafo de rechazo

A espesor cero, ¿puede un adaptador reescribir «no rechazado» como «acíclico»? ¿Qué cambia a espesor positivo y certifica alguno de los resultados la fabricación?

> **Respuesta:** No. El grafo sigue siendo cíclico; el espesor cero solo desactiva este rechazo de pila rígida de espesor positivo. A espesor positivo, el mismo ciclo rechaza ese modelo sin testigo de niveles ni altura rígidos. Ni aceptar ni rechazar certifica si puede fabricarse un objeto real tejido, inclinado o deformable.

## 3. Eliminar una arista y calcular niveles

Elimina `D->A`. La cadena restante tiene niveles `A=0`, `B=1`, `C=2`, `D=3`. El camino dirigido más largo tiene tres aristas y cuatro niveles de paneles. Con `t=0.5`, los desplazamientos de nivel son `[0,0.5,1,1.5]` en unidades del patrón de pliegues.

Para una convención didáctica de envolvente de capa completa, cada panel ocupa desde su desplazamiento hasta un espesor total por encima. La extensión total es por tanto 2 unidades, mientras el desplazamiento más alto es 1.5. Ilustra el número de niveles por espesor total del informe del código; no coloca paneles físicos en una escena nativa.

### Ejercicio 3: distinguir desplazamientos y extensión

Calcula el número de niveles, el desplazamiento máximo y la extensión completa de la envolvente. ¿Es esta asignación de niveles una colocación canónica única del objeto?

> **Respuesta:** Hay cuatro niveles, desplazamiento máximo 1.5 unidades y extensión total 2 unidades. Un testigo válido de niveles no es una colocación canónica única: traslación y otras disposiciones admisibles pueden diferir. El grafo abstracto fijado y la convención de envolvente no establecen geometría exacta de plegado grueso ni holgura de movimiento.

## 4. Fusionar identidades y conservar relaciones desconocidas

Antes de fusionar, las aristas de caras `1->2` y `2->0` forman un grafo acíclico. Si las caras 0 y 1 están unidas en plano y deben compartir un panel rígido, el mapa de paneles es `[0,0,2]`. Las aristas resultantes de paneles son `0->2` y `2->0`: un ciclo. [NET-006](net-006-instance-and-resource-graphs.md) también pregunta qué entidades representa un grafo; un grafo de caras y uno de paneles no tienen por qué tener las mismas restricciones.

Por separado, considera aristas conocidas `A->B` y `C->D`, con la pareja superpuesta B/C indeterminada. El grafo conocido tiene dos niveles. Completarlo con `B->C` requiere cuatro, mientras `C->B` permite dos. Con dos capas locales estipuladas, la lectura de dos niveles inspirada en el código es solo una cota inferior mientras la pareja sea desconocida; no se emiten niveles exactos de caras.

### Ejercicio 4: realizar ambas operaciones de grafos

Explica el ciclo creado por la fusión de unión plana. Para el grafo separado de pareja desconocida en `t=0.5`, calcula las dos extensiones al completarlo y explica por qué no puede llamarse exacta a la lectura parcial.

> **Respuesta:** La fusión identifica caras 0 y 1 y convierte el camino de caras en el ciclo de paneles `0->2->0`. En el ejemplo de pareja desconocida, las dos formas de completarlo requieren cuatro y dos niveles, dando extensiones 2 y 1 unidades. El valor parcial de dos niveles es una cota inferior, no una decisión sobre la relación ausente. Ninguna geometría nueva ni comprobador nativo produjeron estos ejemplos abstractos.

## 5. Conservar el testigo del grafo con su afirmación

El [módulo de capas](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/src/layers.rs#L92-L118) interpreta relaciones suministradas usando orientación de caras. El módulo de espesor fusiona después paneles, deduplica aristas de paneles y conserva un testigo de pareja de caras para un ciclo. Las relaciones desconocidas de superposición siguen en un recuento separado; un grafo conocido acíclico no las hace conocidas.

### Ejercicio 5: preparar un rechazo con acceso a las fuentes

Lee ADR, código y prueba. Sustituye «el tejido es imposible» por un informe acotado y especifica qué debería conservar un futuro adaptador del observatorio antes de proponer otro DSL de creación.

> **Respuesta:** Informa de que las relaciones declaradas no admiten una pila de espesor positivo con una altura fija por panel rígido paralelo y conserva los testigos de caras inferiores y superiores del ciclo, mapa de paneles, interpretación de orientación y signos, unidades de espesor, recuento de parejas desconocidas y revisión del código. No dice nada universal sobre paneles inclinados, hilo flexible, movimiento de plegado ni fabricación. Compara un registro tipado de grafo y el comprobador existente antes de añadir un DSL. Aquí no se entregaron un adaptador ni un ensayo físico.

El [registro de grafos fijado](../../../../code/streeling/evidence/constraint-feedback-2026-10-22/panel-graphs.json) conserva todos los casos didácticos independientemente de los identificadores del caso de prueba del código.
