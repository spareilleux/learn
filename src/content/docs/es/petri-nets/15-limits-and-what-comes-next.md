---
title: "15. Límites y qué viene después: indecidibilidad, desplegados, reducción de orden parcial, extensiones"
description: Medir dónde se detiene este analizador y por qué, añadir la única extensión que levanta un límite, y ver al árbol de cobertura dar una respuesta falsa en vez de una lenta.
sidebar:
  order: 15
---

Catorce lecciones construyeron un analizador y luego lo comprobaron — contra sí mismo, contra los ficheros de otra herramienta, contra las respuestas publicadas de un concurso, contra TLC. Esta pregunta qué no sabe hacer, y responde con números en vez de con un encogimiento de hombros.

Aquí hay tres clases de límite, y no son la misma cosa. Uno es de este analizador (fuerza bruta sobre subconjuntos, un tope de veinte plazas). Otro es de la máquina (la lección 12 lo midió: 1 216 millones de arcos). El tercero pertenece al formalismo, y ninguna cantidad de ingeniería lo mueve.

## Ejecutar el experimento

```bash
dotnet run --project code/petri-nets/Examples -c Release -- l15
dotnet test code/petri-nets/Tests -c Release --filter InhibitorTests
```

Todo el bloque de abajo está en [`expected/l15.txt`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/expected/l15.txt), comparado línea a línea por `check.sh`. La extensión con arcos inhibidores es [`Inhibitor.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Inhibitor.cs) y las dos redes sobre las que se demuestra están en [`InhibitorNets.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/Examples/InhibitorNets.cs).

## Con qué rapidez crece el espacio de estados

```
  family                     n   markings        arcs  arcs/marking
  philosophers               2          3           4           1.3
  philosophers               3          4           6           1.5
  philosophers               4          7          16           2.3
  philosophers               5         11          30           2.7
  philosophers               6         18          60           3.3
  philosophers               7         29         112           3.9
  philosophers-one-fork      2          6           8           1.3
  philosophers-one-fork      3         14          27           1.9
  philosophers-one-fork      4         34          88           2.6
  philosophers-one-fork      5         82         265           3.2
  philosophers-one-fork      6        198         768           3.9
  kanban                     1        160         616           3.9
  kanban                     2       4600       28120           6.1
  kanban                     3      58400      446400           7.6
```

Dos cosas de esa tabla importan más que el crecimiento en sí.

La primera es la **última columna**. La lección 12 encontró que el muro de memoria es de arcos y no de marcados — `Dekker-PT-020` tiene 11,5 millones de marcados y 1 216 millones de arcos y muere con un montículo de 8 GiB, mientras que `Peterson-PT-3` tiene 3,4 millones de marcados y 13,6 millones de arcos y cabe. Aquí la razón sube con cada componente añadido: 1,3 → 3,9 para los filósofos, 3,9 → 7,6 para Kanban. Cada filósofo nuevo no añade solo sus propios estados; multiplica las maneras de abandonar cada estado existente.

La segunda es la **diferencia entre las dos familias de filósofos**. Tomar los dos tenedores de golpe da 29 marcados con siete filósofos. Tomarlos de uno en uno da 198 con seis. El formalismo no cambió y la máquina tampoco: lo que creció es el número de entrelazados que el modelo está obligado a distinguir, que es exactamente lo que la reducción de orden parcial y los desplegados existen para borrar.

## Lo que cuesta la estructura, en comparación

```
  net                       places  invariants  siphons   traps
  philosophers-3                 9           6        6       6
  philosophers-4                12           8        8       8
  philosophers-5                15          10       10      10
```

Los invariantes son una eliminación de Farkas sobre una matriz: siguen respondiendo mientras el espacio de estados se multiplica. Los sifones y las trampas son la fuerza bruta de la lección 7, que enumera subconjuntos de plazas, y el analizador la limita a veinte. Seis filósofos tomando un tenedor cada vez tienen veinticuatro plazas, así que el veredicto estructural no se puede calcular para la mayor red de la propia tabla de la lección 7 — un límite de este código, no de la teoría. Encontrar un sifón mínimo es NP-difícil, lo cual es una razón honesta para ser lento y ninguna razón para estar limitado a veinte: una formulación con un resolutor de restricciones llegaría mucho más lejos, a costa de hacer que el curso dependa de un resolutor.

## El muro que la ingeniería no mueve

Tres hechos, ninguno medible aquí, todos decididos:

**La alcanzabilidad es decidible.** Dada una red y un marcado, existe un algoritmo que dice si el marcado es alcanzable. No es obvio y costó veinte años resolverlo.

**Es Ackermann-completa.** No exponencial — *ackermanniana*, una función que supera a toda función primitiva recursiva. [Leroux (2021)](https://arxiv.org/abs/2104.12695) demostró que la cota inferior no es primitiva recursiva; [Czerwiński y Orlikowski (2021)](https://arxiv.org/abs/2104.13866) la fijaron en Ackermann-completa. Ninguna implementación quita eso, y las instancias de la lección 12 que respondieron en segundos lo hicieron porque eran pequeñas, no porque el problema sea fácil.

**La acotación es decidible, y por eso funciona la lección 3.** [Karp y Miller (1969)](https://doi.org/10.1016/S0022-0000(69)80011-5) dieron el árbol de cobertura, que termina en toda red sustituyendo por ω una plaza que creció. `CoverabilityTree.Build` es ese algoritmo, y la lección 12 midió lo que cuesta su falta de fusión: en `kanban-1`, una red con **160 marcados alcanzables**, agotó la memoria.

**Algunas preguntas son directamente indecidibles.** Si dos redes tienen el mismo conjunto de alcanzabilidad es una; [Araki y Kasami (1976)](https://doi.org/10.1016/0304-3975(76)90067-0) reúnen varias. Vale la pena ponerlo al lado de la lección 13: TLC responderá a cualquier invariante que sepas escribir sobre un espacio de estados finito, y la pregunta *¿son estos dos modelos el mismo?* no tiene algoritmo en ninguno de los dos formalismos.

## La extensión que levanta el límite, y lo que cuesta

Una red de Petri no sabe comprobar si una plaza está a cero. Una transición se dispara cuando sus plazas de entrada llevan *suficiente*; no hay arco que signifique *y esta plaza está vacía*. Por eso `handshake` no puede detectar que está atascada, y por eso la solidez de la lección 10 tuvo que definirse con un cortocircuito en vez de con «las plazas de trabajo están vacías».

Añade un tipo de arco y el límite desaparece:

```csharp
public sealed record InhibitorArc(string Place, string Transition);
```

`InhibitorNet.IsEnabled` es la regla ordinaria más una línea: toda plaza inhibidora debe estar vacía.

Esto es lo que compra. `flush(n)` mueve *n* marcas de `a` a `b` de una en una, y `finish` está inhibida por `a`:

```
  flush(n)       with the zero test     without it
  flush-1                         3              4
  flush-2                         4              6
  flush-4                         6             10
  flush-8                        10             18
```

Con el arco inhibidor, `finish` se dispara exactamente una vez, tras el último `move`: *n* + 2 marcados. Quítalo y `finish` puede dispararse en cualquier momento, lo que son 2(*n* + 1) marcados y un modelo que ya no dice para lo que fue escrito. Los marcados de más no son complejidad — son respuestas falsas.

Y esto es lo que cuesta. `self-inhibited` es la red más pequeña que se puede construir con uno: una plaza, una transición, y un arco de la plaza a la transición que la produjo.

```
  self-inhibited: one place, one transition, one inhibitor arc.
    as an ordinary net, the coverability tree says bounded = False, p <= omega
    with the inhibitor arc, the reachable set is 2 markings, p <= 1, complete = True
```

**El árbol de cobertura no es lento aquí. Es falso.** La aceleración de Karp y Miller descansa en un argumento que un arco inhibidor rompe: si un marcado cubre estrictamente a uno de sus ancestros, la secuencia de disparos intermedia puede repetirse para siempre, así que las plazas que crecieron pueden crecer sin cota. Con un arco inhibidor, la marca que apareció es exactamente lo que ahora bloquea la transición que la produjo. La secuencia no puede repetirse, y ω es una mentira.

No es un defecto que arreglar. La comprobación a cero convierte dos plazas en los contadores de una máquina de dos contadores, así que una red con arcos inhibidores simula una máquina de Turing, y la acotación, la alcanzabilidad y la vivacidad se vuelven todas indecidibles. `InhibitorNet` viene por eso con un constructor de conjunto alcanzable que toma un límite y **ninguna contrapartida de cobertura**: cuando su búsqueda es incompleta, la respuesta es «no dentro del límite», nunca «no acotada». Todo lo demás en este repositorio es una red ordinaria a propósito.

## Lo que ayudaría de verdad, y no está aquí

Tres técnicas atacan la tabla del principio de esta lección, y ninguna está implementada.

**Los desplegados.** En vez de enumerar marcados, se construye un orden parcial de eventos — una red que registra lo que ocurrió, dejando la concurrencia sin ordenar en vez de entrelazada. [McMillan (1993)](https://doi.org/10.1007/3-540-56496-9_14) mostró cómo parar: un evento de *corte* es uno cuyo resultado ya está representado, y el prefijo finito completo que queda puede ser exponencialmente más pequeño que el grafo de alcanzabilidad para sistemas concurrentes. [Esparza, Römer y Vogler (1996)](https://doi.org/10.1007/3-540-61042-1_40) corrigieron el orden adecuado que hace mínimo ese prefijo. Las dos familias de filósofos de arriba son precisamente la forma que esto ataca: la diferencia entre 29 y 198 es entrelazado, y un desplegado no lo paga.

**La reducción de orden parcial.** Se sigue enumerando marcados, pero en cada uno se dispara solo un subconjunto de las transiciones habilitadas — elegido de modo que toda propiedad de interés se preserve. Los conjuntos obstinados de Valmari y las construcciones de conjuntos amplios son las formulaciones habituales. Más barato de injertar en un explorador existente que un desplegado, y mucho más difícil de hacer bien: la condición sobre el subconjunto es donde vive la corrección, y una mala pierde estados en silencio, que es el mismo modo de fallo que una restricción de estado en la lección 13.

**Los diagramas de decisión.** La lección 12 midió este desde fuera. `tedd` responde a `Dekker-PT-020` en 2,3 s y 1209 MB donde este analizador muere tras 158,3 s con 8 GiB, porque un diagrama de decisión almacena un *conjunto* de marcados simbólicamente y no almacena ningún arco. Los 1 216 millones de arcos que mataron la búsqueda explícita sencillamente no existen en esa representación.

*Por verificar.* Ninguna de las tres se implementó ni se midió aquí. La afirmación de que un desplegado es exponencialmente más pequeño para la familia de los filósofos es el resultado publicado, no una observación de este repositorio, y la versión honesta es: el entrelazado se ve en la tabla, y la técnica que lo quita no se ejecutó.

## Dónde se detiene el propio curso

- **Sin lógica temporal.** La lección 13 le entregó a TLC el espacio de estados y ninguna línea `PROPERTY`; `[]<>Enabled(t) => []<>t` bajo equidad es lo que pregunta realmente la cuestión de la inanición de la lección 7, y ni este analizador ni ningún módulo de aquí la responde.
- **Sin tiempo determinista.** La lección 9 añadió tasas estocásticas y obtuvo una cadena de Markov. Un intervalo de Merlin `[a, b]` necesita una construcción por clases de estados que no está aquí; [TINA](https://projects.laas.fr/tina/) la hace.
- **Sin tuplas coloreadas.** Las redes coloreadas de la lección 8 enlazan una variable por transición. Una transición que une dos mensajes necesita una tupla y el despliegue crece como un producto; los modelos del concurso de la lección 12 lo esquivaron entregando todo ya desplegado.
- **Sin redes continuas ni híbridas**, donde un marcado es un número real y el disparo es un caudal. Es otro formalismo con otra teoría, y nada de lo anterior se traslada a él.
- **El tope de los sifones.** Veinte plazas, por la razón dada arriba.

## Puntos clave

- El coste de la enumeración está en los arcos, y los arcos por marcado suben con cada componente añadido: 1,3 → 3,9 en seis filósofos, 3,9 → 7,6 en tres tarjetas Kanban.
- Tomar un tenedor cada vez en vez de dos cuesta 198 marcados donde la toma atómica cuesta 29. Esa diferencia es entrelazado, y es lo que los desplegados y la reducción de orden parcial existen para quitar.
- El análisis estructural sigue respondiendo mientras el espacio de estados se multiplica, porque los invariantes son un cálculo matricial. El tope de veinte plazas en los sifones es del analizador, no de la teoría.
- La alcanzabilidad es decidible y Ackermann-completa. Ninguna implementación mueve eso, y la igualdad de dos conjuntos de alcanzabilidad es directamente indecidible.
- Un arco inhibidor compra la comprobación a cero — y hace el formalismo Turing-completo, momento en el que el árbol de cobertura deja de ser una aproximación y pasa a ser falso: responde ω para una red cuya plaza nunca lleva dos marcas.
- Cada red de este repositorio es una red plaza/transición ordinaria por esa razón, y la única excepción está en el curso para medirse una vez y guardarse.

## Ejercicios

1. Ejecuta `l15` y prolonga la fila de Kanban a cuatro tarjetas. Antes de ejecutarlo, predice los arcos por marcado a partir de las tres filas que ya están. ¿Cuánto se acerca la predicción, y en qué dirección se equivoca?
2. `flush(n)` tiene *n* + 2 marcados con la comprobación a cero y 2(*n* + 1) sin ella. Escribe la frase que el arco inhibidor le hace decir a la red, y la que dice la red ordinaria en su lugar. ¿Cuál de las dos es una especificación que le podrías dar a un programador?
3. Construye una red con arcos inhibidores con dos plazas `x` e `y` y transiciones que decrementen `x` mientras incrementan `y`, más una transición habilitada solo cuando `x` está vacía. Has construido la mitad de una máquina de dos contadores. ¿Qué haría falta añadir para la otra mitad, y por qué hace eso indecidible la acotación?
4. `CoverabilityTree.Build(InhibitorNets.SelfInhibited().Net)` responde ω. Encuentra el paso de la construcción de Karp y Miller que no es válido aquí, y enuncia la suposición que hace, en una frase.

<details>
<summary>Soluciones</summary>

1. Las tres razones son 3,9, 6,1 y 7,6, así que los incrementos son +2,2 y +1,5 y una extrapolación lineal da unos **8,9**. Medido, cuatro tarjetas dan **454 475 marcados, 3 979 850 arcos, razón 8,8** — la extrapolación se pasa, y seguirá pasándose. La razón es el grado de salida medio de un marcado, acotado por el número de transiciones, y `Nets.Kanban` tiene dieciséis con cualquier número de tarjetas; la curva tiene que aplanarse. Donde el coste sigue componiéndose es en los marcados: 160 → 4 600 → 58 400 → 454 475, un factor de unas ocho veces por tarjeta sin techo a la vista.

2. Con el arco: *cuando todos los artículos se hayan movido, terminar.* Sin él: *en algún momento, terminar, y aparte los artículos se mueven.* La primera es una especificación — nombra la condición. La segunda es la descripción de dos cosas que ocurren, y un programador al que se la den tendría razón en preguntar «¿antes o después?» y no obtendría respuesta del modelo. Es exactamente la brecha que la lección 10 tuvo que cerrar con un cortocircuito a falta de comprobación a cero.

3. Hace falta un segundo contador y la capacidad de bifurcar según la nulidad de cualquiera de los dos: una máquina de dos contadores son dos contadores, incremento, decremento, y un salto condicional a cero para cada uno. `x` e `y` son los contadores, los arcos son los incrementos y decrementos, y el arco inhibidor es el salto. El resultado de Minsky es que dos contadores bastan para simular una máquina de Turing; así que «¿pone esta red alguna vez más de *k* marcas en una plaza?» se convierte en «¿alcanza esta máquina alguna vez esta configuración?», es decir, el problema de la parada. No hay algoritmo, así que no puede existir ningún árbol de cobertura — no uno lento, ninguno.

4. El paso no válido es la aceleración por ω: cuando un marcado nuevo *M′* cubre estrictamente a un ancestro *M* de su propio camino, toda plaza donde *M′ > M* se pone a ω. La suposición es que **la secuencia de disparos que lleva de *M* a *M′* puede volver a dispararse desde *M′***, y que por tanto esas plazas pueden bombearse arbitrariamente alto. En `self-inhibited` la secuencia es la única transición `grow`, y dispararla pone una marca en `p` — que es precisamente lo que inhibe a `grow`. La secuencia no puede repetirse ni una vez, mucho menos arbitrariamente a menudo.

</details>

## Fuentes

- Jérôme Leroux, *The Reachability Problem for Petri Nets is Not Primitive Recursive*, [arXiv:2104.12695](https://arxiv.org/abs/2104.12695), 2021. La cota inferior.
- Wojciech Czerwiński y Łukasz Orlikowski, *Reachability in Vector Addition Systems is Ackermann-complete*, [arXiv:2104.13866](https://arxiv.org/abs/2104.13866), 2021. La cota superior correspondiente, y la razón de que esta lección diga Ackermann en vez de «muy difícil».
- Richard Karp y Raymond Miller, *Parallel program schemata*, **Journal of Computer and System Sciences** 3(2), 1969, [doi:10.1016/S0022-0000(69)80011-5](https://doi.org/10.1016/S0022-0000(69)80011-5). El árbol de cobertura que implementa `CoverabilityTree.cs`. El registro está confirmado por Crossref; el artículo está tras un muro de pago y no lo he leído, y todo lo que este curso dice de la construcción está o deducido en la lección 3 o medido. *Por verificar.*
- Toshiro Araki y Tadao Kasami, *Some decision problems related to the reachability problem for Petri nets*, **Theoretical Computer Science** 2(1), 1976, [doi:10.1016/0304-3975(76)90067-0](https://doi.org/10.1016/0304-3975(76)90067-0). Misma reserva. *Por verificar.*
- Kenneth McMillan, *Using unfoldings to avoid the state explosion problem in the verification of asynchronous circuits*, **CAV '92**, LNCS 663, [doi:10.1007/3-540-56496-9_14](https://doi.org/10.1007/3-540-56496-9_14), y Javier Esparza, Stefan Römer y Walter Vogler, *An improvement of McMillan's unfolding algorithm*, **TACAS '96**, LNCS 1055, [doi:10.1007/3-540-61042-1_40](https://doi.org/10.1007/3-540-61042-1_40). Ninguno de los dos algoritmos está implementado aquí. *Por verificar.*
- Tadao Murata, *Petri nets: Properties, analysis and applications*, **Proceedings of the IEEE** 77(4), 1989, [doi:10.1109/5.24143](https://doi.org/10.1109/5.24143). La sección IV-A es la presentación del árbol de cobertura que siguió este curso, y la sección VI enumera las extensiones.
- [TINA](https://projects.laas.fr/tina/), nombrada por la construcción por clases de estados que este analizador no tiene.
- Las cifras del concurso de la lección 12, para `tedd`: resultados del [Model Checking Contest](https://mcc.lip6.fr/).
