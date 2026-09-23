---
title: 9. Tiempo y probabilidad
description: Las tasas convierten el grafo de alcanzabilidad en una cadena de Markov de tiempo continuo — una cola modelada como red y resuelta dos veces, una por el analizador y otra por la fórmula del manual, y luego el rendimiento, la ley de Little y las transiciones inmediatas de una GSPN cuyos estados evanescentes no contienen tiempo alguno.
sidebar:
  order: 9
---

Código completo: [`code/petri-nets`](https://github.com/spareilleux/learn/tree/main/code/petri-nets). Esta lección la imprime `dotnet run --project Examples -c Release -- l9`, y se compara con [`expected/l9.txt`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/expected/l9.txt).

Ocho lecciones de este curso han respondido a preguntas de la forma *¿puede ocurrir esto?*. Puede desbordarse el búfer, puede bloquearse el sistema, puede terminar el flujo de trabajo. Son las preguntas que una prueba no responde, y merecen la maquinaria.

Tampoco son las preguntas que uno hace primero. Las preguntas que uno hace primero son *con qué frecuencia* y *cuánto tiempo*: qué rendimiento aguanta esto, cuántas peticiones esperan, qué fracción se rechaza. Las redes de las lecciones 1 a 8 rechazan las tres, a propósito — un marcado dice dónde están las marcas, y la regla de disparo dice qué transiciones *pueden* dispararse, nunca cuál *se va* a disparar, ni cuándo.

Esta lección añade el número que falta y conserva todo lo demás. La estructura no cambia, así que todos los resultados de las lecciones 3 a 6 siguen valiendo; lo que cambia es que cada transición lleva ahora una **tasa**, y el grafo de alcanzabilidad que ya conoces se convierte en una **cadena de Markov de tiempo continuo**.

## Una tasa no es un retardo

Dale a cada transición un retardo exponencial de tasa λ: una vez sensibilizada, espera un tiempo aleatorio de media 1/λ antes de dispararse. La exponencial no es una elección inocente, y vale la pena ser honesto sobre por qué es la que funciona.

Es la única distribución continua **sin memoria**: una transición que ya ha esperado tres segundos está exactamente en el estado en que estaba en cero. Eso es lo que permite que el futuro dependa solo del marcado — y el marcado solo es toda la razón por la que el grafo de alcanzabilidad es un objeto finito que merece la pena resolver. Cualquier otra distribución haría que el futuro dependiera de cuánto lleva esperando cada transición sensibilizada, que es una cantidad no acotada de estado adicional.

También es a menudo falsa. Los tiempos de servicio de los sistemas reales rara vez son exponenciales; una lectura de disco se parece más a una constante, y un reintento con espera es deliberadamente con memoria. La sección [«Dónde se detiene esto»](#dónde-se-detiene-esto) dice qué hacer entonces. El trato es el de siempre: una distribución solo aproximadamente correcta, a cambio de una respuesta calculada exactamente en lugar de muestreada.

## La cola, como red

Dos plazas y dos transiciones:

```
== A queue with one server and room for 5 ==
net queue-5
places      room jobs
transitions arrive serve
M0          (5, 0) = room:5
arc         room -> arrive
arc         arrive -> jobs
arc         jobs -> serve
arc         serve -> room
reachable markings: 6
```

`room` contiene los huecos libres y `jobs` los trabajos en espera; una llegada toma un hueco y fabrica un trabajo, un servicio hace lo contrario. Es el búfer de la [lección 1](../01-why-petri-nets/) sin el productor ni el consumidor — y la plaza `room` sigue siendo toda la razón por la que nada se desborda.

Seis marcados alcanzables, uno por longitud de cola de 0 a 5. Ahora las tasas:

```
== The same structure, now with a rate on each transition ==
arrive: 3.0000 per unit of time
serve:  4.0000 per unit of time
load:   0.7500
```

Con una transición de llegada, una de servicio y retardos exponenciales, esta red **es** una cola M/M/1/K — el modelo del manual, con llegadas de Poisson, un servidor exponencial y una sala de espera de K. Eso importa para la sección siguiente, porque M/M/1/K es uno de los pocos modelos cuya respuesta se conoce en forma cerrada.

## Calculado dos veces

El analizador construye la cadena a partir del grafo — la tasa del estado *i* al estado *j* es la de la transición que los une — y resuelve πQ = 0 con probabilidades que suman uno. La fórmula calcula la misma distribución a partir de ρ = λ/μ, sin mirar nunca la red:

```
== Stationary distribution, computed twice ==
jobs   from the net   from the formula
0      0.3041        0.3041
1      0.2281        0.2281
2      0.1711        0.1711
3      0.1283        0.1283
4      0.0962        0.0962
5      0.0722        0.0722
every state agrees within 1e-12: ok
```

Dos caminos independientes, seis números de acuerdo. Es la única razón para fiarse del analizador en una red cuya respuesta *no* se conoce en forma cerrada — es decir, todas las que de verdad te importan.

:::note[Por qué la comprobación imprime un veredicto y no la diferencia]
La diferencia entre las dos columnas es 5,6e-17 en mi máquina, y sus cifras exactas dependen del orden en que la máquina sumó los números en coma flotante. Imprimirla produciría una línea distinta entre Windows, Linux y macOS y haría fallar la comparación por un motivo que nada tiene que ver con las redes de Petri. Por eso la comprobación imprime un veredicto frente a un umbral. La regla es general: compara números con una tolerancia, e imprime solo lo que estés dispuesto a ver reproducirse exactamente.
:::

## Lo que merece la pena preguntarle a la cadena

La distribución en sí no es la parte interesante. Estas sí:

```
== What the chain is worth asking ==
mean jobs in the system:   1.7009
accepted arrivals:         2.7835 per unit of time
completions:               2.7835 per unit of time
arrivals turned away:      0.0722 of the time
server busy:               0.6959 of the time
```

Lee esas cuatro líneas como ingeniero, no como matemático:

- **se ofrecieron 3,0 llegadas pero solo entraron 2,7835.** Las 0,2165 que faltan son el 7,22 % del tiempo en que la sala de espera está llena. La capacidad no es el rendimiento, y la red dice por cuánto difieren.
- **las terminaciones igualan a las llegadas aceptadas**, hasta la última cifra mostrada. Nada se crea ni se destruye; si esos dos números difirieran, el equivocado sería el modelo, no el sistema.
- **el servidor está ocupado el 69,59 % del tiempo**, no el 75 %. La respuesta ingenua ρ = 0,75 es la ocupación de una cola con sala de espera *no acotada*. Perder llegadas también es perder trabajo.

Ese último punto es de las cosas que una prueba de carga te dice tras una semana de producción y que un modelo te dice antes del primer despliegue.

## La ley de Little, gratis

El tiempo medio que un trabajo pasa en el sistema no es algo que la cadena calcule directamente. La [ley de Little](https://en.wikipedia.org/wiki/Little%27s_law) lo da: el número medio en el sistema es la tasa de llegada por el tiempo medio que se pasa en él, para cualquier sistema estable — sin ninguna hipótesis sobre distribuciones, orden de servicio o independencia.

```
== Little's law, as an independent check ==
mean time in the system:   0.6111
arrivals times that time:  1.7009
mean jobs (above):         1.7009
in and out balance: ok
```

Usada en un sentido es una medida: 1,7009 / 2,7835 = 0,6111 unidades de tiempo por trabajo. Usada en el otro es una **comprobación del modelo**, y así la usa la lección — una ley que vale para todo sistema estable debe valer aquí, así que si no valiera, la cadena estaría mal.

Ya tienes las dos mitades de esa identidad en producción: la profundidad de la cola en un panel y la tasa de peticiones. El tercer número sale sin instrumentar nada.

## El filo de la navaja con carga 1

Haz la tasa de llegada igual a la de servicio y la cola no se asienta en el medio. No se asienta en ninguna parte:

```
== Raising the load to 1 spreads the queue evenly ==
jobs   probability
0      0.1667
1      0.1667
2      0.1667
3      0.1667
4      0.1667
5      0.1667
```

Todas las longitudes son igual de probables. La cola está vacía un sexto del tiempo y completamente llena un sexto del tiempo, y deriva entre ambas sin preferencia, porque con ρ = 1 nada la devuelve. Un sistema dimensionado «exactamente a capacidad» no es un sistema que funciona en su límite — es un sistema sin tendencia alguna, cuya sala de espera se llena con la misma facilidad con que se vacía.

Esa intuición vale más que el número. Es también la razón por la que la forma cerrada necesita un caso especial en ρ = 1: la serie geométrica que da las otras distribuciones no tiene suma ahí.

## Una elección que no lleva tiempo

Los modelos reales tienen decisiones que no consumen tiempo: un enrutador que elige un servidor, una bifurcación sobre un campo, un límite de reintentos ya alcanzado. Darles una tasa sería mentir — habría que inventar una duración para algo instantáneo, y aparecería en la respuesta.

Una **red de Petri estocástica generalizada** (GSPN) admite **transiciones inmediatas**: llevan un peso en lugar de una tasa, se disparan en el instante en que quedan sensibilizadas, y cuando varias compiten los pesos reparten la elección. Un trabajo, dos servidores, un reparto 70/30:

```
== A choice that takes no time: immediate transitions ==
net two-servers
places      waiting at-fast at-slow
transitions to-fast to-slow done-fast done-slow
M0          (1, 0, 0) = waiting:1
reachable markings: 3, of which tangible: 2
the job waits (vanishing state): 0.0000 of the time
at the fast server: 0.5385
at the slow server: 0.4615
```

Tres marcados alcanzables, pero solo dos **tangibles**. El tercero — el trabajo esperando a ser enrutado — es **evanescente**: allí hay una transición inmediata sensibilizada, así que la red lo abandona al instante y no pasa tiempo en él. Su probabilidad no es pequeña, es exactamente cero, y el solucionador lo elimina antes de resolver la cadena en lugar de dejar que diluya la respuesta.

Los dos números que quedan tienen una respuesta que puedes hacer de cabeza, y por eso está aquí este ejemplo:

```
== The same two numbers by hand ==
at the fast server: 0.5385
at the slow server: 0.4615
```

Siete trabajos de cada diez van a un servidor que tarda media unidad de tiempo, tres de cada diez a uno que tarda una entera: 0,7 × 0,5 = 0,35 frente a 0,3 × 1 = 0,30, normalizados a 0,5385 y 0,4615. El servidor lento retiene el 46 % de los trabajos mientras recibe el 30 % — la cola está donde se pasa el tiempo, no donde va el tráfico.

## Lo que esto cuesta

Nada en esta lección agrandó el espacio de estados, y todo en ella heredó el problema del espacio de estados. La cadena tiene una ecuación por marcado alcanzable, así que la [explosión de estados de la lección 3](../03-the-reachability-graph/) es ahora también un problema de álgebra lineal: una red con un millón de marcados necesita un millón de incógnitas resueltas, y la eliminación densa usada aquí necesitaría un millón al cuadrado de coeficientes.

Las consecuencias prácticas:

- **el analizador rechaza un grafo incompleto.** Si la construcción se detuvo en su límite, los estados que faltan no son un error de redondeo — las probabilidades se normalizarían sobre el conjunto equivocado y todos los números estarían silenciosamente mal.
- **rechaza una red con un marcado muerto.** Una red que puede detenerse no tiene distribución estacionaria; tiene un estado absorbente que acaba llevándose toda la probabilidad. La [lección 4](../04-properties/) decide el bloqueo, y esa decisión va primero.
- **las herramientas reales usan solucionadores dispersos y métodos iterativos**, porque la matriz de una cadena de Markov está casi vacía. El solucionador denso de aquí es honesto sobre su tamaño: está hecho para los seis estados de una cola, no para seiscientos mil.

## Dónde se detiene esto

Tres límites, en orden creciente de con qué frecuencia los encontrarás.

**Los retardos deterministas rompen el método.** Si una transición tarda exactamente 2 segundos en lugar de 2 de media, el futuro ya no depende solo del marcado, y no hay cadena de Markov que resolver. Las **redes de Petri temporizadas** con duraciones deterministas son una teoría distinta y más difícil; las respuestas habituales son una red determinista y estocástica (DSPN, con a lo sumo una transición determinista sensibilizada a la vez), una aproximación de tipo fase — varias etapas exponenciales en serie, cuya suma varía mucho menos que una sola exponencial — o la simulación.

**El régimen estacionario no es toda la historia.** Todo lo anterior describe el sistema tras funcionar mucho tiempo. Las preguntas sobre la primera hora, sobre la probabilidad de desbordar en un día, sobre la distribución de un transitorio de arranque, son análisis **transitorio**: la misma cadena, integrada en el tiempo en vez de resuelta en el equilibrio.

**Las medias ocultan la cola de la distribución.** Esta lección calculó una longitud de cola media y un tiempo de espera medio. El número contra el que se escribe un SLO es un percentil, y una media dice muy poco de un percentil 99 — dos sistemas con la misma media pueden diferir en un orden de magnitud en la cola. La distribución sobre los estados está disponible, así que las preguntas de cola sobre la *longitud de la cola* tienen respuesta; las del *tiempo de espera* necesitan la maquinaria de los tiempos de absorción, o la simulación.

## Puntos clave

- Una tasa añade *con qué frecuencia* y *cuánto tiempo* a un modelo que solo decía *si*. La estructura queda intacta, así que los invariantes y los resultados de vivacidad de las lecciones anteriores siguen valiendo.
- La exponencial se elige porque no tiene memoria, y la ausencia de memoria es exactamente lo que permite que el marcado sea todo el estado. Es una hipótesis de modelado, no un hecho sobre tu sistema.
- Resuelve el mismo modelo dos veces por caminos independientes siempre que exista uno. La forma cerrada de la cola M/M/1/K vale más como comprobación del analizador que como respuesta.
- La ley de Little es gratis, no pide hipótesis, y sirve además como prueba de que el modelo cuadra.
- El rendimiento no es la carga ofrecida, y la ocupación no es ρ, en cuanto la sala de espera es finita.
- Con carga 1 una cola finita no se queda en el medio: todas las longitudes son igual de probables.
- Las transiciones inmediatas modelan decisiones que no llevan tiempo. Sus estados son evanescentes, tienen probabilidad cero y se eliminan antes de resolver la cadena — darles una tasa falsa metería una duración falsa en la respuesta.
- La cadena es tan grande como el grafo de alcanzabilidad. Todo lo que hacía cara la lección 3 hace caro esto también.

## Ejercicios

1. La cola de arriba pierde el 7,22 % de sus llegadas. Sin ejecutar nada, di qué reduce más esa pérdida: doblar la sala de espera de 5 a 10, o hacer el servidor un 10 % más rápido. Después compruébalo con el analizador.
2. Añade un segundo servidor a la cola, para que dos trabajos puedan estar en servicio a la vez. ¿Qué cambia en la red, y por qué la respuesta del analizador deja de coincidir con `QueueFormula`?
3. El ejemplo de dos servidores pone el 46 % de los trabajos en un servidor que recibe el 30 %. Elige los pesos que repartan los trabajos de modo que ambos servidores los retengan la misma fracción del tiempo.
4. La lección se niega a resolver una red con un marcado muerto. Di qué saldría si la resolviera de todos modos, y por qué esa respuesta sería inútil y no simplemente imprecisa.

<details>
<summary>Soluciones</summary>

**1.** La pérdida es p<sub>K</sub> = p₀ρ<sup>K</sup>, y con ρ = 0,75 cada hueco adicional multiplica la pérdida por 0,75. Cinco huecos más la multiplican por 0,75⁵ ≈ 0,237, así que la pérdida cae del 7,22 % a alrededor del 1,8 % — mucho más que a la mitad. Hacer el servidor un 10 % más rápido lleva ρ a 0,682, y 0,682⁵ frente a 0,75⁵ es una bajada de un 40 % aproximadamente, hasta un 4,3 %.

Gana la sala de espera, y gana porque la pérdida decae geométricamente en la capacidad pero solo polinómicamente en la tasa. La lección general es que cuando ρ está cómodamente por debajo de 1, el búfer es el arreglo barato; cuando ρ se acerca a 1 la caída geométrica se aplana y el búfer deja de ayudar — con ρ = 1 la sección de arriba mostraba todas las longitudes igual de probables, así que un hueco más no compra casi nada.

**2.** Añade una plaza `servers` con dos marcas, un arco de ella hacia `serve` y otro de vuelta. La estructura cambia pero el grafo de alcanzabilidad no crece: `servers` queda acotada por un invariante de plaza con los trabajos en servicio.

La fórmula deja de aplicarse porque M/M/1/K supone un solo servidor: con dos, la tasa de servicio depende de cuántos trabajos hay presentes — es 2μ cuando ambos servidores están ocupados y μ cuando lo está uno. Eso es una cola M/M/2/K, con otra forma cerrada. La tasa de una transición en la red es una constante, así que modelar dos servidores como «una transición, con el doble de tasa» sería falso exactamente en los estados donde importa: los que tienen un solo trabajo.

Es la trampa habitual con las tasas. Una tasa pertenece a una transición, no a un marcado; si la velocidad depende de cuántas marcas hay presentes, las marcas tienen que estar en la red.

**3.** El tiempo en un servidor es la parte dividida por la tasa, así que igualar los tiempos significa w<sub>rápido</sub>/2 = w<sub>lento</sub>/1, es decir el doble de tráfico al servidor rápido: pesos 2 y 1, o cualquier múltiplo. Entonces cada uno retiene exactamente 0,5.

Fíjate en lo que esto *no* dice. Repartir el tráfico en proporción a la velocidad iguala el tiempo pasado en cada servidor; no minimiza nada en particular. Mandarlo todo al servidor rápido daría aquí un tiempo medio menor — las políticas de enrutamiento merecen modelarse precisamente porque el reparto obvio rara vez es el mejor.

**4.** La cadena convergería al marcado muerto: su probabilidad iría a 1 y la de todos los demás estados a 0. No es una respuesta imprecisa, es la respuesta a otra pregunta — «dónde acaba esta red» en lugar de «cómo se comporta esta red», y la segunda no tiene respuesta aquí porque la red no sigue funcionando. Los números estarían perfectamente bien formados y describirían un sistema detenido, y por eso el analizador se niega en vez de imprimirlos. La misma distinción muerde en otros sitios: una longitud de cola media calculada sobre un periodo que incluye una caída no es un número más pequeño, es un número sobre otro sistema.

</details>

## Fuentes

- Marsan, Balbo, Conte, Donatelli, Franceschinis, *Modelling with Generalized Stochastic Petri Nets*, Wiley, 1995 — la referencia para las GSPN, los estados evanescentes y su eliminación. [Disponible libremente en la web de los autores](https://www.di.unito.it/~greatspn/GSPN-Wiley/).
- Murata, «Petri Nets: Properties, Analysis and Applications», *Proceedings of the IEEE* 77(4), 1989 — la sección sobre las extensiones temporizadas y estocásticas.
- Bolch, Greiner, de Meer, Trivedi, *Queueing Networks and Markov Chains*, 2.ª edición, Wiley, 2006 — la derivación de M/M/1/K y los métodos numéricos que las herramientas reales usan en lugar de la eliminación densa de aquí.
- La [ley de Little](https://en.wikipedia.org/wiki/Little%27s_law), y la retrospectiva del propio Little en 2011, *Little's Law as Viewed on Its 50th Anniversary*, *Operations Research* 59(3), sobre lo poco que supone.
- [GreatSPN](https://www.di.unito.it/~greatspn/index.html) y [TimeNET](https://timenet.tu-ilmenau.de/) resuelven estos modelos a una escala que el analizador de este curso no pretende. La lección 11 vuelve a ellas.
- La implementación que imprime esta lección: [`Stochastic.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Stochastic.cs), con la cadena, la eliminación de los estados evanescentes y la forma cerrada que le sirve de control.
