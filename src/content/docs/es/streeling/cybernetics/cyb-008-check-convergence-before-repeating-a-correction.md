---
title: Comprobar la convergencia antes de repetir una corrección
description: Comprobar la convergencia antes de repetir una corrección — Cibernética
sidebar:
  label: CYB-008 · Comprobar la convergencia antes de repetir una corrección
  order: 8
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/cybernetics/es/cyb-008-check-convergence-before-repeating-a-correction.es.md
---

:::note[Streeling University]
**CYB-008** · Comprobar la convergencia antes de repetir una corrección · intermedio · 45 minutos

Generado por el departamento *Cibernética* de Demerzel — todavía no lo he revisado. [Ver la fuente](https://github.com/spareilleux/learn/blob/main/streeling/courses/cybernetics/es/cyb-008-check-convergence-before-repeating-a-correction.es.md) · [Mi diario](../../journal/)

Requisitos previos: [CYB-004](../../cybernetics/cyb-004-observe-before-correcting-a-feedback-loop/), [PHY-012](../../physics/phy-012-rotate-directional-stiffness-with-the-material/)
:::

> **Alcance del borrador.** Iteraciones elaboradas en aritmética exacta para un equilibrio lineal estipulado. No se ejecutó ningún controlador físico, calibración de material, solucionador nativo ni bucle de agente. Siguen pendientes las revisiones humanas técnicas, artesanales, lingüísticas por personas que dominen el idioma y pedagógicas con estudiantes; la verificación del HTML del curso desplegado es independiente.

## La pregunta del proyecto

¿Podría un agente del observatorio resolver la respuesta de un material corrigiendo repetidamente el residuo de fuerza? [PHY-012](../../physics/phy-012-rotate-directional-stiffness-with-the-material/) proporciona una ley de resorte elaborada para el ejercicio, no un modelo de tela calibrado. [CYB-004](../../cybernetics/cyb-004-observe-before-correcting-a-feedback-loop/) distingue una corrección útil de una ejecución satisfactoria. Aquí deducimos cuándo converge una corrección numérica precisa y cuándo la repetición amplifica su error.

Utilicemos la rigidez local `K=diag(4,1)` en N/mm, la fuerza objetivo `F=[4,1]` N y el desplazamiento inicial `u[0]=[0,0]` mm. El equilibrio exacto es `u*=[1,1]` mm. No se presupone ninguna convención de referencia del entorno receptor.

## 1. Definir el residuo y la ganancia

Sea el residuo `F-K*u[n]`, en N. La actualización numérica es `u[n+1]=u[n]+alpha*(F-K*u[n])`, por lo que `alpha` tiene unidades mm/N. Con el error `e[n]=u[n]-u*`, la sustitución da `e[n+1]=(I-alpha*K)*e[n]`.

Esta es una iteración algebraica indexada por actualizaciones, no una ecuación de movimiento en segundos. No incluye inercia, contacto, ruido de medición ni límites de los actuadores. Estas omisiones son supuestos, no una descripción validada de una máquina de fabricación artesanal.

### Ejercicio 1: calcular las primeras correcciones

Fije `alpha=0.25` mm/N. Calcule los dos primeros desplazamientos y los dos factores de error. ¿Por qué una ganancia adimensional con el mismo valor numérico no define la misma actualización?

> **Respuesta:** Los dos primeros desplazamientos son `[1,0.25]` y `[1,0.4375]` mm. Los factores de error son `1-4*alpha=0` y `1-alpha=0.75`. Multiplicar el residuo de fuerza por la ganancia debe producir un desplazamiento, por lo que sus unidades mm/N son necesarias. Cambiar las unidades sin transformar la ganancia cambia el modelo numérico.

## 2. Deducir el intervalo estricto de convergencia

Para que todo error inicial converja a cero, ambos factores de error deben tener magnitud inferior a uno. Las condiciones son `abs(1-4*alpha)<1` y `abs(1-alpha)<1`, que juntas dan `0<alpha<0.5` mm/N. Los extremos están excluidos.

Con `alpha=0.25`, el error del eje rígido desaparece tras la primera actualización; el otro se contrae por un factor de 0.75 en cada actualización. En la actualización 8, el desplazamiento es `[1,0.8998870849609375]` mm. El residuo del segundo eje es 0.1001129150390625 N. La contracción geométrica por actualización no demuestra rapidez en tiempo transcurrido ni mejora de un proceso físico.

### Ejercicio 2: demostrar la convergencia bajo las premisas indicadas

Deduza el intervalo a partir de ambos modos propios. Explique por qué el resultado en la actualización 8 aún no alcanza el equilibrio exacto y si observar ocho actualizaciones completadas demostraría la convergencia.

> **Respuesta:** El primer modo requiere `0<alpha<0.5`; el segundo requiere `0<alpha<2`, por lo que su intersección es `0<alpha<0.5`. El error lento en la actualización 8 es `-0.75^8` mm, no cero. Una traza finita por sí sola no es la demostración: la contracción se deriva de la recurrencia lineal exacta y sus supuestos. No se observó ninguna ejecución nativa ni convergencia física.

## 3. Probar la oscilación en el límite y la divergencia

Con `alpha=0.5`, el factor de error rígido es -1. Con nuestra condición inicial, el primer desplazamiento alterna entre 0 y 2 mm. Su promedio por pares es 1 mm, pero la sucesión no converge a ese valor. La otra coordenada converge.

Con `alpha=0.6`, los factores son -1.4 y 0.4. Un error no nulo del modo rígido crece en magnitud mientras alterna de signo. Medir solo la segunda coordenada, que mejora, pasaría por alto el modo inestable.

Definamos la diferencia de potencial cuadrático como `0.5*e^T*K*e` en N*mm. Con la ganancia límite, su contribución rígida se mantiene en 2 N*mm. Un desplazamiento medio correcto o una sola coordenada cuyo error disminuye no bastan como criterio de parada.

### Ejercicio 3: rechazar una medida de éxito incompleta

Un agente obtiene un promedio de 1 mm para la primera coordenada con la ganancia límite y declara el éxito. Analice la afirmación mediante la sucesión de errores y la diferencia de potencial. ¿Qué cambia con la ganancia 0.6?

> **Respuesta:** El promedio oculta el error alternante de desplazamiento de magnitud 1 mm, dejando una diferencia de potencial del modo rígido de 2 N*mm. Los iterados no convergen. Con la ganancia 0.6, un error rígido no nulo se multiplica en cambio por -1.4, por lo que su magnitud crece. Examine todos los modos pertinentes y un criterio declarado de residuo o error, no solo un promedio o la coordenada estable.

## 4. Cambiar el retardo y deducir de nuevo el modelo

Ahora utilicemos deliberadamente el desplazamiento de la actualización anterior en el residuo: `u[n+1]=u[n]+alpha*(F-K*u[n-1])`. Fijemos ambos valores iniciales en cero. Es una recurrencia diferente, no un detalle de implementación inocuo.

Para el modo rígido con `alpha=0.4`, la ecuación característica es `r^2-r+1.6=0`. Sus raíces complejas tienen magnitud `sqrt(1.6)`, mayor que uno. La iteración sin retardo con la misma ganancia tiene factores -0.6 y 0.6 y converge; esa conclusión no se puede trasladar a la versión retardada. Los desplazamientos de su primera coordenada comienzan con `[0,1.6,3.2,2.24,-1.28]` mm y no ofrecen una traza monótona del error.

### Ejercicio 4: exponer el supuesto modificado

Deduza la ecuación característica del modo rígido y la magnitud de las raíces para la recurrencia retardada. ¿Por qué el intervalo de ganancia anterior no justifica este bucle?

> **Respuesta:** Sustituir un modo de error proporcional a `r^n` da `r^2-r+alpha*4=0` y, por tanto, `r^2-r+1.6=0`. Las raíces conjugadas tienen producto 1.6 y magnitud `sqrt(1.6)>1`. La demostración anterior utilizaba el residuo actual y una ecuación característica diferente. Las observaciones retardadas pueden exigir otro análisis; este contraejemplo elaborado para el curso no es una medición de un controlador real.

## 5. Comparar con la resolución más sencilla

Para esta matriz diagonal conocida, la multiplicación directa por `K^-1=diag(0.25,1)` da inmediatamente `[1,1]` mm. Un bucle de agente o un nuevo DSL debe justificar su coste adicional frente a esa referencia sencilla. El [registro previo del resorte conservado](https://github.com/spareilleux/learn/blob/d488be4c2fda37afa06a4f87e322b73f21e46313/code/streeling/evidence/weave-material-2026-10-22/directional-response.json) sigue siendo un cálculo matemático elaborado para el curso.

La [escena didáctica](https://github.com/spareilleux/learn/blob/d488be4c2fda37afa06a4f87e322b73f21e46313/code/streeling/weave-godot/trial.gd) en la revisión fijada crea cuerpos estáticos. [Godot StaticBody3D](https://docs.godotengine.org/en/4.6/classes/class_staticbody3d.html) no se mueve por fuerzas externas ni contactos; estos cuerpos no implementan nuestro solucionador iterativo de resortes.

### Ejercicio 5: preparar una comparación de solucionadores con ayuda de las fuentes

Lea la escena y la documentación de cuerpos estáticos; después utilice el [registro fijado de iteraciones](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/constraint-feedback-2026-10-22/residual-iterations.json). Especifique una futura comparación acotada antes de que un agente prometa una mejora recursiva.

> **Respuesta:** Fije la ley de respuesta real, el sistema de referencia, las unidades, la ganancia, la antigüedad de las observaciones, la política de actualización y el criterio de parada. Compare con la resolución directa en este pequeño sistema conocido y conserve por separado residuos, errores, recuentos de iteraciones y costes en tiempo transcurrido. Incluya controles con ganancia límite, con retardo y con entradas inválidas; después pruebe cualquier extensión no lineal o física prevista bajo sus propios supuestos. Rechace una ventaja declarada si la orquestación añadida cuesta más sin mejorar el resultado declarado. Estos cálculos no establecen un solucionador desplegado, un material calibrado, control en tiempo real ni una mejora general de los agentes.
