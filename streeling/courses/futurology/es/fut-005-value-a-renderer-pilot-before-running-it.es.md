---
module_id: fut-005-value-a-renderer-pilot-before-running-it
department: futurology
course: "Valorar una prueba piloto de renderizador antes de ejecutarla"
level: intermediate
prerequisites: ["fut-004-scenario-test-an-observatory-renderer", "pm-005-interpret-brutal-coexistence-experiments"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Valorar una prueba piloto de renderizador antes de ejecutarla

> **Alcance del borrador.** Modelos de decisión y señal creados para el curso, aritmética exacta y lectura de fuentes históricas fijadas a una revisión. Quedan pendientes las revisiones humanas técnica, lingüística y de estudiantes, así como la verificación del HTML del curso desplegado. No se ejecutaron una prueba piloto real, un renderizador, una GPU ni un cambio en producción.

## La pregunta del proyecto

¿Cambiaría otra prueba de renderizador la decisión o solo produciría más informes? [FUT-004](fut-004-scenario-test-an-observatory-renderer.md) comparó estrategias entre escenarios. Aquí valoramos la información antes de obtenerla considerando las acciones que podría cambiar.

El [README de BRUTAL de la revisión fijada](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/README.md) conserva un fallo original de coexistencia y un seguimiento no concluyente. [PM-005](../../product-management/en/pm-005-interpret-brutal-coexistence-experiments.md) explica esas observaciones históricas. Motivan esta pregunta, pero no proporcionan ninguna de las probabilidades ni puntos de pérdida siguientes. Todos los documentos fuente del proyecto usan el commit de GA `76efbffd5af82b46c3146957a6bd4504008eeb89`; aquí no se reprodujo ningún binario histórico.

## 1. Enunciar la decisión sin prueba piloto

Usa dos condiciones latentes creadas para el curso: F, donde un candidato se ajusta al uso previsto, y U, donde no. La probabilidad previa de cada una es `1/2`. Las acciones son K, mantener la configuración actual, y S, cambiar al candidato. Supón que estas acciones son admisibles según los controles necesarios de calidad y coexistencia antes de comparar sus consecuencias.

| Acción | Pérdida en F | Pérdida en U |
| --- | --- | --- |
| K | 4 | 4 |
| S | 0 | 10 |

Los números son puntos didácticos comparables de una escala cardinal, donde se prefiere una pérdida esperada menor. No son dinero, milisegundos ni preferencias medidas. Las pérdidas esperadas previas son 4 para K y 5 para S, así que se mantiene K. Si la probabilidad de F es p, S tiene pérdida esperada `10*(1-p)`. Solo supera a K cuando `p>3/5`; en la igualdad, nuestra política declarada mantiene K.

### Ejercicio 1: localizar el umbral de acción

Calcula ambas pérdidas esperadas previas. Resuelve el umbral de probabilidad a partir del cual S resulta preferible. ¿Estima ese umbral con qué frecuencia el candidato real es adecuado?

> **Respuesta:** K da 4; S da `(1/2)*0+(1/2)*10=5`. Resolver `10*(1-p)<4` da `p>3/5`. El umbral se deriva de las pérdidas didácticas y la regla de preferencia; no estima una probabilidad real de condiciones del anfitrión.

## 2. Modelar qué puede decirnos la prueba piloto

Estipula una prueba piloto pasiva con probabilidades de resultado positivo `P(+|F)=4/5` y `P(+|U)=1/5`. No cambia la condición latente. Sus probabilidades negativas son las complementarias. La [presentación de Bayes del NIST](https://www.itl.nist.gov/div898/handbook/apr/section2/apr1a.htm) explica cómo actualizar una distribución previa usando una verosimilitud y normalizando sobre las condiciones posibles.

Cada resultado tiene probabilidad previa `1/2`. Tras un resultado positivo, `P(F|+)=4/5`; tras uno negativo, `P(F|-)=1/5`. Por tanto, un resultado positivo selecciona S con pérdida esperada condicional 2. Uno negativo selecciona K con pérdida 4. Estas verosimilitudes son premisas explícitas, no un clasificador ajustado ni la tasa de éxito de las pruebas históricas de BRUTAL.

### Ejercicio 2: invertir el condicionamiento

Calcula la probabilidad de un resultado positivo y la probabilidad posterior de F tras él. ¿Qué acción se sigue? ¿Es `P(+|F)` automáticamente la misma cantidad que `P(F|+)`?

> **Respuesta:** `P(+)=(1/2)*(4/5)+(1/2)*(1/5)=1/2`. Después, `P(F|+)=((1/2)*(4/5))/(1/2)=4/5`; S tiene pérdida esperada 2 y se selecciona. Las probabilidades condicionales coinciden en valor en este ejemplo simétrico, pero condicionan a eventos distintos y no son intercambiables en general.

## 3. Comparar información imperfecta y perfecta

Antes de pagar la prueba piloto, promedia las mejores decisiones dependientes del resultado: `(1/2)*2+(1/2)*4=3`. El valor esperado bruto de la información muestral es la mejor pérdida previa menos este valor: `4-3=1` punto.

La información perfecta revelaría F o U antes de actuar. Elige S en F y K en U, dando pérdida esperada `(1/2)*0+(1/2)*4=2`. Su valor bruto es `4-2=2` puntos. La [clase de análisis de decisiones del MIT](https://ocw.mit.edu/courses/15-053-optimization-methods-in-management-science-spring-2013/b68f3b255275ffa42099958e373248b1_MIT15_053S13_lec19.pdf#page=7) distingue información original, perfecta e imperfecta. Usamos reducción de pérdida en lugar de su convención de aumento de beneficio.

### Ejercicio 3: calcular los dos valores

Calcula los valores brutos de la información muestral y de la información perfecta. ¿Por qué tratar esta prueba piloto ruidosa como perfecta exageraría su beneficio modelado?

> **Respuesta:** Los valores son 1 y 2 puntos respectivamente. La prueba piloto ruidosa a veces da la señal desfavorable para la condición real, así que su pérdida esperada optimizada es 3 en lugar del valor de información perfecta 2. Asignar precisión perfecta a esta prueba cambia el canal de información estipulado.

## 4. Cargar el coste de obtener información

Haz que la prueba piloto cueste 0.6 puntos en la misma escala de pérdida declarada. La pérdida esperada total pasa a ser `3+0.6=3.6`, una mejora de `4-3.6=0.4` respecto a mantener K sin prueba piloto. Un coste de 1 punto agotaría su beneficio bruto. Una prueba perfecta hipotética que costara 3 puntos tampoco sería atractiva aquí: su valor bruto es solo 2.

El valor de la información perfecta es un techo para la información sobre este estado bajo los mismos supuestos de acciones disponibles, pérdidas y tiempos. No es un presupuesto para cualquier experimento posible: una prueba nueva podría cambiar las acciones disponibles, consumir tiempo durante el que cambia el estado o alterar la propia carga de trabajo. Esos son modelos de decisión distintos.

### Ejercicio 4: rechazar una prueba demasiado cara

¿Cuál es el valor neto de la prueba piloto ruidosa de 0.6 puntos? ¿Y el de una prueba perfecta que cueste 3 puntos? ¿Pueden sumarse directamente minutos de ingeniería a estos puntos de pérdida?

> **Respuesta:** El valor neto de la prueba piloto ruidosa es 0.4 puntos. El de la prueba perfecta es `2-3=-1` punto. No pueden sumarse minutos brutos a la escala de puntos sin una conversión declarada u otro objetivo; aquí no se midió ningún tiempo ni coste real.

## 5. Preguntar si puede cambiar alguna acción

Si solo se permite K, la información no puede cambiar la acción. La distribución posterior puede moverse mientras el valor bruto de decisión sigue en 0. Más generalmente, en este modelo la información puede ignorarse, así que el valor bruto optimizado no es negativo; puede ser cero y los costes de adquisición pueden hacer negativo el valor neto.

Una siguiente investigación útil especifica la decisión real, acciones admisibles, escala de consecuencias, fundamento de la distribución previa, calibración de la señal, tiempos y regla de parada. El [informe histórico M3](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/evidence/m3-20261020-000727.md) tiene controles variables y sus propios límites de binario y estado del repositorio con cambios sin confirmar. No calibra esta prueba piloto pasiva hipotética. [CYB-007](../../cybernetics/en/cyb-007-update-beliefs-without-counting-a-trial-twice.md) comprueba si informes sucesivos representan pruebas nuevas; [PM-006](../../product-management/en/pm-006-test-a-pilot-against-its-decision-horizon.md) añade costes de migración y reutilización.

### Ejercicio 5: separar aprendizaje de valor de decisión

Supón que solo se permite K, pero la prueba piloto sigue cambiando la distribución posterior de `1/2` a `4/5` tras un resultado positivo. ¿Cuál es su valor bruto de decisión? ¿Qué pruebas faltan antes de que el resultado original de 0.4 puntos pueda justificar una prueba real de renderizador?

> **Respuesta:** El valor bruto de decisión es 0 porque la acción permitida sigue siendo K. Una decisión de prueba real necesita una escala justificada de consecuencias, alternativas admisibles, hipótesis de distribución previa y verosimilitud calibradas o explícitamente defendidas, costes reales de adquisición, tiempos y controles de calidad y coexistencia. El resultado de 0.4 puntos es aritmética condicional, no autorización ni un beneficio medido en la máquina.

El [registro de decisión fijado](../../../../code/streeling/evidence/pilot-value-2026-10-22/pilot-decision.json) conserva el modelo didáctico completo y sus valores racionales exactos.
