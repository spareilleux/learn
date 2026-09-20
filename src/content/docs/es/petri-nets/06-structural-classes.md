---
title: 6. Clases estructurales
description: Máquinas de estados, grafos marcados y redes de libre elección — tres formas de red que vienen con teoremas, los circuitos, sifones y trampas en los que esos teoremas están enunciados, una vivacidad decidida sobre una red cuyo grafo de alcanzabilidad es infinito, y la razón honesta por la que la mayoría de los modelos reales caen fuera de las tres clases.
sidebar:
  order: 6
---

Código completo: [`code/petri-nets`](https://github.com/spareilleux/learn/tree/main/code/petri-nets). Esta lección la imprime `dotnet run --project Examples -c Release -- l6`, y se compara con [`expected/l6.txt`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/expected/l6.txt).

La lección 5 demostraba cosas a partir de la matriz de incidencia. Esta lección demuestra cosas a partir de la *forma* de la red — de qué plazas alimentan a qué transiciones, antes de cualquier peso, cualquier marca, cualquier disparo.

La razón para que te importe es directa: para tres formas concretas, alguien ya ha hecho el trabajo duro. Si tu red es una de ellas, una propiedad que en general cuesta un grafo de alcanzabilidad cuesta una inspección de los arcos. Si tu red no es una de ellas, también deberías saberlo, porque te dice qué teorema no tienes permitido usar.

Dos piezas de notación, usadas en todo lo que sigue y en [`Structure.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Structure.cs):

- **•t** es el conjunto de plazas de las que toma la transición *t*, y **t•** el conjunto en el que deposita;
- **•p** es el conjunto de transiciones que llenan la plaza *p*, y **p•** el conjunto de las que la vacían.

## Las tres formas

| clase | condición | lo que prohíbe |
|---|---|---|
| **máquina de estados** | toda transición tiene exactamente una plaza de entrada y una de salida | cualquier transición que sincronice o bifurque |
| **grafo marcado** | toda plaza tiene exactamente una transición de entrada y una de salida | cualquier plaza por la que compitan dos transiciones |
| **red de libre elección** | si dos plazas comparten una transición de salida, cada una tiene exactamente esa única salida | una elección cuyo resultado depende de las marcas de otro |

Una máquina de estados es lo que dibujabas antes de conocer las redes de Petri: una marca paseando por un grafo de estados. Puede ramificarse, no puede bifurcar — nada en ella produce nunca dos marcas.

Un grafo marcado es el dual: puede bifurcar y sincronizar, y no tiene ninguna elección. Toda plaza tiene un productor y un consumidor, así que nunca compiten dos transiciones.

Una red de libre elección permite las dos cosas, mientras la elección y la sincronización no toquen la misma plaza. Cuando `p` alimenta a `t1` y a `t2`, la decisión entre ambas es libre — nada más en la red puede hacer que una sea imposible dejando la otra sensibilizada.

Aquí es donde caen las redes de este curso, con las clases decididas solo sobre los arcos:

```
== Where the nets of this course sit ==
net                 state machine  marked graph  free choice  ext. free choice  asym. choice  strongly conn.
producer-consumer   no             yes           yes          yes               yes           yes
unbounded-producer  no             yes           yes          yes               yes           no
connection          yes            no            yes          yes               yes           yes
start-once          yes            no            yes          yes               yes           no
handshake           no             no            yes          yes               yes           no
mutual-exclusion    no             no            no           no                yes           yes
two-locks           no             no            no           no                yes           yes
readers-writers     no             no            no           no                no            yes
philosophers-3      no             no            no           no                no            yes
```

Las dos últimas columnas son las parientes más débiles. La **libre elección extendida** pide que dos plazas que comparten una transición de salida compartan *todas*; la **elección asimétrica** (también llamada red simple) pide solo que uno de los dos conjuntos de transiciones de salida contenga al otro. Cada clase contiene a la anterior, y la tabla muestra la escalera funcionando: el cerrojo es de elección asimétrica, los filósofos ni siquiera eso.

Lee las cuatro filas de abajo antes que las cinco de arriba. Todo lo que en este curso modela un recurso compartido queda fuera de la clase de libre elección, y no es casualidad — la última sección de esta lección dice por qué.

## Grafos marcados: cuenta las marcas de cada circuito

El productor y el consumidor es un grafo marcado: `free` solo la llena `take` y solo la vacía `deposit`, y todas las demás plazas igual.

```
== A marked graph: the producer and consumer ==
structure of producer-consumer
  ordinary (every arc weight 1):  yes
  pure (no self-loop):            yes
  strongly connected:             yes
  state machine:                  no
  marked graph:                   yes
  free choice:                    yes
  extended free choice:           yes
  asymmetric choice:              yes
circuits of producer-consumer: 3 circuits
  {ready, produced}  tokens at M0: 1
  {free, full}  tokens at M0: 2
  {waiting, taken}  tokens at M0: 1
marked graph theorem  live: True   safe: False   markings enumerated: 0
reachability graph    live: True   safe: False   markings enumerated: 12
```

Detente en esos tres circuitos y compáralos con la lección 5:

```
ready + produced = 1
free + full = 2
waiting + taken = 1
```

Son los mismos tres conjuntos con los mismos tres números. En un grafo marcado las marcas de un circuito no pueden cambiar nunca — toda transición del circuito toma una marca de la plaza anterior y pone una en la siguiente — así que **cada circuito es un invariante de plazas**, y el número de marcas que lleva es la constante. Las pruebas unitarias del analizador comprueban esa correspondencia sobre esta red. El álgebra de la lección 5 y la geometría de esta lección son, aquí, dos descripciones de un mismo hecho.

De ahí caen dos teoremas, los dos de *Marked directed graphs* de Commoner, Holt, Even y Pnueli ([JCSS 5(5), 1971](https://doi.org/10.1016/S0022-0000(71)80013-2)):

- un grafo marcado es **vivo** exactamente cuando todo circuito dirigido lleva al menos una marca;
- un grafo marcado vivo es **seguro** exactamente cuando toda plaza está en un circuito que lleva exactamente una marca.

Los dos son fáciles de creer a partir del invariante: un circuito sin marcas es un conjunto de condiciones de las que ninguna puede llegar a ser cierta, y el circuito que pasa por una plaza limita cuántas marcas puede tener esa plaza. El analizador los aplica y luego contrasta las respuestas con el grafo de alcanzabilidad — `live: True  safe: False` por ambos caminos, doce marcados de un lado y ninguno del otro. `free` y `full` están en un circuito con dos marcas, que es exactamente por lo que la red está 2-acotada y no es segura.

Es la primera vez en el curso que una pregunta de vivacidad se responde sin enumeración.

## Máquinas de estados: una marca, y si puedes volver

```
== A state machine that is live, and one that is not ==
net connection
places      disconnected connecting connected
transitions open established failed close
M0          (1, 0, 0) = disconnected:1
arc         disconnected -> open
arc         open -> connecting
arc         connecting -> established
arc         established -> connected
arc         connecting -> failed
arc         failed -> disconnected
arc         connected -> close
arc         close -> disconnected
structure of connection
  ordinary (every arc weight 1):  yes
  pure (no self-loop):            yes
  strongly connected:             yes
  state machine:                  yes
  marked graph:                   no
  free choice:                    yes
  extended free choice:           yes
  asymmetric choice:              yes
state machine theorem  strongly connected: True   tokens at M0: 1
                       live: True   safe: True
reachability graph     live: True   safe: True   markings enumerated: 3
```

`connection` es `disconnected → connecting → connected → disconnected`, con una rama `failed` de vuelta desde `connecting`. Es la máquina de estados que habrías dibujado de todos modos, y para esa forma la regla es corta: una máquina de estados es viva cuando es fuertemente conexa y tiene al menos una marca, y segura cuando tiene como mucho una. El número total de marcas no cambia nunca, porque toda transición toma una y da una.

`start-once` es el contraejemplo que ya usó la lección 4, y ahora la razón es estructural en vez de conductual:

```
net start-once
places      stopped running serving
transitions start accept finish
M0          (1, 0, 0) = stopped:1
arc         stopped -> start
arc         start -> running
arc         running -> accept
arc         accept -> serving
arc         serving -> finish
arc         finish -> running
structure of start-once
  ...
  strongly connected:             no
  state machine:                  yes
state machine theorem  strongly connected: False   tokens at M0: 1
                       live: False   safe: True
reachability graph     live: False   safe: True   markings enumerated: 3
```

Nada lleva de vuelta a `stopped`. Una ojeada a los arcos lo zanja, y la lección 4 necesitó el grafo entero para decir lo mismo.

## Sifones y trampas

Para la clase de libre elección el teorema está enunciado con dos ideas que merece la pena tener incluso cuando tu red no está en ninguna clase.

Un **sifón** es un conjunto *S* de plazas con **•S ⊆ S•**: toda transición que mete una marca en *S* también saca una de *S*.

Una **trampa** es un conjunto *S* con **S• ⊆ •S**: toda transición que saca una marca de *S* también devuelve una.

Cada uno lleva pegada una prueba de una línea, para las redes ordinarias — las redes donde todo arco tiene peso 1:

- **Un sifón que está vacío se queda vacío.** Supón que *S* no tiene nada y que alguna *t* dispara metiendo una marca en *S*. Entonces *t* ∈ •S ⊆ S•, así que *t* también toma una marca de alguna plaza de *S* — que no tiene ninguna, luego *t* no estaba sensibilizada. Contradicción.
- **Una trampa que tiene una marca sigue teniéndola.** Supón que *S* tiene una marca y que *t* dispara. Si *t* no toma nada de *S*, el recuento no puede bajar. Si sí toma, entonces *t* ∈ S• ⊆ •S, así que *t* también mete una marca en alguna plaza de *S*, y *S* vuelve a estar marcada de inmediato.

Un sifón es una manera que tiene un sistema de morir; una trampa es una manera de seguir vivo. Por eso son las dos nociones en las que se escriben los teoremas de vivacidad, y merece la pena ser preciso sobre cuál es cuál: es la **trampa** la que tiene que estar marcada, nunca el sifón.

Ahora la consecuencia que no necesita ninguna clase, y cuya prueba cabe en tres líneas:

:::note[Todo marcado muerto vacía un sifón]
Sea *M* un marcado muerto de una red ordinaria y sea *D* el conjunto de plazas que no tienen nada en *M*. Toma cualquier *t* que meta una marca en *D*. Como *M* está muerto, *t* no está sensibilizada, así que alguna de sus plazas de entrada no tiene nada — esa plaza está en *D*, luego *t* toma de *D*. Por tanto •D ⊆ D•: *D* es un sifón.

Dale la vuelta y obtienes una condición suficiente para la **ausencia de interbloqueo** en cualquier red ordinaria: si todo sifón contiene una trampa marcada en *M0*, no hay ningún marcado muerto. Un marcado muerto daría un sifón vacío *D*; *D* contiene una trampa marcada; esa trampa sigue teniendo una marca, y está dentro de *D*, que no tiene ninguna.
:::

El analizador verifica la primera mitad sobre la red que se interbloquea de la lección 4:

```
== Every dead marking empties a siphon ==
dead marking (0, 1, 0, 1, 0, 0)  a_has_x:1 b_has_y:1
  places holding nothing: {a_idle, b_idle, x, y}
  that set is a siphon: True
  largest trap inside it: {}
```

Y la causa estructural es uno de sus cinco sifones minimales:

```
siphons of two-locks: 5 minimal siphons
  siphon {a_idle, a_has_x}
    largest trap inside it: {a_idle, a_has_x}  marked at M0: yes
  siphon {b_idle, b_has_y}
    largest trap inside it: {b_idle, b_has_y}  marked at M0: yes
  siphon {a_has_x, x}
    largest trap inside it: {a_has_x, x}  marked at M0: yes
  siphon {b_has_y, y}
    largest trap inside it: {b_has_y, y}  marked at M0: yes
  siphon {x, y}
    largest trap inside it: {}  marked at M0: no
  every siphon contains a marked trap: no
  minimal traps: {a_idle, a_has_x} {b_idle, b_has_y} {a_has_x, x} {b_has_y, y}
```

`{x, y}`, los dos cerrojos juntos, es un sifón que no contiene ninguna trampa. Los dos cerrojos se pueden tomar y ninguno tiene que volver, y una vez que ese conjunto está vacío lo está para siempre. El interbloqueo de la lección 4 era una imagen; esto es su causa, encontrada sin disparar nada.

## El teorema de Commoner, y lo que compra

Para las redes de libre elección la condición suficiente se convierte en una caracterización exacta. El resultado está enunciado en la tesis de máster de Michel Hack de 1972 y allí se atribuye a Frederic Commoner:

> Una red de libre elección es viva si y solo si todo sifón contiene una trampa marcada.

El analizador lo aplica a las redes de libre elección del curso y pone al lado el veredicto del grafo de alcanzabilidad:

```
== Free choice, siphons and traps ==
siphons of producer-consumer: 3 minimal siphons
  siphon {ready, produced}
    largest trap inside it: {ready, produced}  marked at M0: yes
  siphon {free, full}
    largest trap inside it: {free, full}  marked at M0: yes
  siphon {waiting, taken}
    largest trap inside it: {waiting, taken}  marked at M0: yes
  every siphon contains a marked trap: yes
  minimal traps: {ready, produced} {free, full} {waiting, taken}
free choice: True   every siphon contains a marked trap: True
Commoner therefore says live: True
the reachability graph says live: True

siphons of start-once: 1 minimal siphon
  siphon {stopped}
    largest trap inside it: {}  marked at M0: no
  every siphon contains a marked trap: no
  minimal traps: {running, serving}
free choice: True   every siphon contains a marked trap: False
Commoner therefore says live: False
the reachability graph says live: False

siphons of handshake: 1 minimal siphon
  siphon {request, response}
    largest trap inside it: {request, response}  marked at M0: no
  every siphon contains a marked trap: no
  minimal traps: {served} {request, response}
free choice: True   every siphon contains a marked trap: False
Commoner therefore says live: False
the reachability graph says live: False
```

`start-once` merece una segunda mirada, porque es el caso donde la redacción importa. El sifón `{stopped}` **sí** está marcado en *M0* — el servicio empieza parado. Lo que no contiene es una *trampa*: una vez que `start` ha disparado, nada vuelve a meter una marca en `stopped`, así que el sifón se vacía y se queda vacío, y `start` está muerta para el resto del tiempo. Que un sifón esté marcado ahora no significa nada. La promesa es una trampa marcada dentro de él.

La red `handshake` es la otra forma del fracaso: allí el sifón `{request, response}` también es una trampa, y no tiene nada desde el principio. Una red que empieza con una trampa vacía ya ha perdido.

Ahora el beneficio. Pon una marca en `request` y la misma estructura se vuelve viva — y la red pasa a no estar acotada, porque `served` cuenta los intercambios terminados para siempre:

```
== A liveness decided where no reachability graph exists ==
net handshake-started
places      request response served
transitions receive reply
M0          (1, 0, 0) = request:1
siphons of handshake-started: 1 minimal siphon
  siphon {request, response}
    largest trap inside it: {request, response}  marked at M0: yes
  every siphon contains a marked trap: yes
  minimal traps: {served} {request, response}
free choice: True
every siphon contains a marked trap: True
Commoner: live
the graph cannot say so: bounded: False, dead transitions: none
reachability graph stopped after 500 markings, complete: False
```

El grafo de alcanzabilidad se rindió a los 500 marcados y habría seguido para siempre. El árbol de cobertura de la lección 3 puede decir que la red no está acotada y que ninguna transición está muerta, y eso es todo lo que puede decir — ω tiró los recuentos que la vivacidad necesita. La estructura respondió a la pregunta de todos modos. Para eso están estas clases.

## Dónde se detienen las clases

Toda red de este curso que modela un recurso compartido queda fuera de la clase de libre elección, y el analizador dice exactamente dónde:

```
== Where the classes stop: the place two transitions fight over ==
mutual-exclusion   free choice: False, extended: False, asymmetric: True
  mutex feeds enter1 and enter2, which do not read the same places
two-locks          free choice: False, extended: False, asymmetric: True
  x feeds a_take_x and b_take_x, which do not read the same places
  y feeds a_take_y and b_take_y, which do not read the same places
philosophers-3     free choice: False, extended: False, asymmetric: False
  fork1 feeds take1 and take3, which do not read the same places
  fork2 feeds take1 and take2, which do not read the same places
  fork3 feeds take2 and take3, which do not read the same places
```

El patrón es el mismo siempre. `mutex` ofrece una elección entre `enter1` y `enter2`, pero la elección no es libre: que `enter1` pueda tomar la marca depende de `idle1`, que no tiene nada que ver con `mutex`. Eso es precisamente lo que la libre elección prohíbe, y es precisamente lo que un cerrojo *es*. Los filósofos caen también fuera de la clase de elección asimétrica, porque en un anillo cada tenedor se lo disputan dos vecinos cuyas otras entradas no tienen relación en ninguno de los dos sentidos.

Así que el resumen honesto de esta lección es tanto una advertencia como una herramienta: los teoremas son afilados y la clase que lleva el más afilado de todos excluye la exclusión mutua, el orden de los cerrojos y los filósofos comensales — tres de las cuatro cosas que un programa concurrente hace realmente. Lo que sobrevive fuera de la clase es la implicación en un solo sentido demostrada más arriba (una trampa marcada en todo sifón significa que no hay interbloqueo), que vale para cualquier red ordinaria y es en lo que se apoya la lección 7.

:::caution[El coste de encontrar un sifón]
[`Structure.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Structure.cs) encuentra los sifones minimales probando todos los subconjuntos de plazas. Es exacto, va bien en redes de veinte plazas, y es exponencial. Decidir si una red tiene un sifón con una propiedad dada es NP-difícil en general, y las herramientas reales usan resolutores de restricciones en lugar de enumeración. Los tres filósofos de la lección 7 tienen 4 096 subconjuntos; seis filósofos tendrían 16 millones.
:::

## Puntos clave

- Una **máquina de estados** tiene una plaza de entrada y una de salida por transición. Es viva cuando es fuertemente conexa con al menos una marca, y segura cuando tiene como mucho una.
- Un **grafo marcado** tiene una transición de entrada y una de salida por plaza. Sus circuitos son sus invariantes de plazas; es vivo cuando todo circuito lleva una marca, y uno vivo es seguro cuando toda plaza está en un circuito que lleva exactamente una.
- Una **red de libre elección** nunca mezcla elección con sincronización. El teorema de Commoner convierte la vivacidad exactamente en «todo sifón contiene una trampa marcada».
- Un **sifón** que se vacía se queda vacío; una **trampa** que está marcada sigue marcada. Las dos pruebas son de una línea, para redes ordinarias.
- **Todo marcado muerto vacía un sifón**, en cualquier red ordinaria. Así que una trampa marcada dentro de todo sifón demuestra la ausencia de interbloqueo, sea cual sea la clase de la red.
- Todas las clases se decidieron **a partir de los arcos**, sin enumerar ningún marcado; `handshake-started` se declara viva aunque su grafo de alcanzabilidad sea infinito.
- La exclusión mutua, el orden de los cerrojos y los filósofos quedan **fuera** de la clase de libre elección. Compartir un recurso es exactamente lo que la rompe.

## Ejercicios

1. `two-locks-ordered` — los dos hilos tomando `x` antes que `y` — se mostró libre de interbloqueo en la lección 4 por enumeración. Predice cómo son sus sifones minimales y si cada uno contiene una trampa marcada, y luego comprueba con el analizador.
2. El productor y el consumidor es a la vez un grafo marcado y una red de libre elección. ¿Es casualidad? Demuestra o refuta: todo grafo marcado es una red de libre elección.
3. Toma `connection` y borra la transición `failed`. ¿Cuál de las dos hipótesis del teorema de las máquinas de estados se rompe, y qué le pasa a la red?
4. La red `handshake` tiene `{served}` entre sus trampas minimales. Explica por qué una plaza sin arco saliente es siempre una trampa, y por qué ese hecho es inútil.

<details>
<summary>Soluciones</summary>

**1.** El analizador imprime esto, y merece la pena contrastar tu predicción con la primera línea, porque la mía estaba mal:

```
== Exercise 1: the same net with both threads taking x first ==
siphons of two-locks-ordered: 4 minimal siphons
  siphon {y}
    largest trap inside it: {y}  marked at M0: yes
  siphon {a_idle, a_has_x}
    largest trap inside it: {a_idle, a_has_x}  marked at M0: yes
  siphon {b_idle, b_has_x}
    largest trap inside it: {b_idle, b_has_x}  marked at M0: yes
  siphon {a_has_x, b_has_x, x}
    largest trap inside it: {a_has_x, b_has_x, x}  marked at M0: yes
  every siphon contains a marked trap: yes
  minimal traps: {y} {a_idle, a_has_x} {b_idle, b_has_x} {a_has_x, b_has_x, x}
free choice: False
deadlock-free by the graph: True
```

Esperaba que `{x, y}` siguiera apareciendo, con una trampa marcada añadida. No aparece en absoluto. En la red ordenada, `y` por sí sola es un sifón — la llenan y la vacían las mismas dos transiciones — y también es una trampa con una marca, así que `{x, y}` ya no es *minimal*. El conjunto que lleva `x` es `{a_has_x, b_has_x, x}`: el cerrojo o está libre o lo tiene uno de los dos hilos, y toda forma de tomarlo lo pone en algún sitio de ese conjunto. Los dos son trampas, los dos están marcados, todo sifón contiene una trampa marcada, y por la implicación demostrada más arriba eso es una prueba de la ausencia de interbloqueo sin necesidad de grafo de alcanzabilidad. La lección 4 llegó a la misma respuesta con uno. Fíjate en las dos últimas líneas: la red *no* es de libre elección, así que esto es solo la implicación en un sentido — que la condición se cumpla demuestra la ausencia de interbloqueo, y no habría demostrado la vivacidad.

**2.** No es casualidad: **todo grafo marcado es una red de libre elección**, y la prueba es inmediata. La libre elección solo puede incumplirse cuando dos plazas comparten una transición de salida mientras una de ellas tiene además otra salida. En un grafo marcado toda plaza tiene exactamente una transición de salida, así que si `p1` y `p2` comparten una, las dos tienen exactamente esa — que es la condición de libre elección satisfecha. El recíproco falla: `connection` es de libre elección y no es un grafo marcado, ya que `disconnected` tiene dos transiciones de entrada.

**3.** Se rompe la conexidad fuerte: sin `failed`, la única salida de `connecting` es `established`, y sigue habiendo un camino de vuelta, así que de hecho la red sigue siendo fuertemente conexa — `connecting → established → connected → close → disconnected → open → connecting`. Borra `close` en su lugar y cortas el único retorno desde `connected`, la red deja de ser fuertemente conexa, y degenera en `start-once`: una conexión que se abre y no se puede reabrir nunca. El ejercicio va en realidad de darse cuenta de qué arco es el camino de vuelta.

**4.** Una plaza `p` con `p•` vacío satisface `p• ⊆ •p` por la razón trivial de que el conjunto vacío es subconjunto de cualquier cosa, así que `{p}` es una trampa. Es inútil porque está marcada solo si ya tiene una marca, y estar marcada para siempre no es interesante para una plaza que nadie lee: es un contador, no una condición. Las trampas que importan en el teorema de Commoner son las que están *dentro de un sifón*, y una plaza sumidero no está en ningún sifón — `•{p}` no es vacío mientras que `{p}•` sí lo es, así que `{p}` no puede satisfacer la condición de sifón.

</details>

## Fuentes

- Frederic Commoner, Anatol W. Holt, Shimon Even y Amir Pnueli, *Marked directed graphs*, **Journal of Computer and System Sciences** 5(5), octubre de 1971, páginas 511–523, [doi:10.1016/S0022-0000(71)80013-2](https://doi.org/10.1016/S0022-0000(71)80013-2). Los teoremas de vivacidad y seguridad para los grafos marcados. Registro confirmado a través de Crossref; el artículo está tras el muro de pago de Elsevier y no lo he leído. *Por verificar.*
- Michel Hack, *Analysis of production schemata by Petri nets*, tesis de máster, MIT, febrero de 1972, publicada como informe técnico del Project MAC MAC-TR-94 / MIT-LCS-TR-094, [handle 1721.1/149406](https://dspace.mit.edu/handle/1721.1/149406). Ahí es donde está enunciado el teorema de vivacidad de Commoner para las redes de libre elección. El registro y el PDF de acceso abierto están confirmados en DSpace@MIT, pero la descarga está tras una comprobación antibots que rechazó todas mis peticiones, así que **no he leído la tesis** y la redacción de más arriba está tomada de fuentes secundarias. *Por verificar.* Lo que esta lección sí afirma con su propia evidencia es más estrecho y está comprobado: sobre las cuatro redes de libre elección que hay aquí, la condición y el grafo de alcanzabilidad coinciden, y las pruebas unitarias fallan si alguna vez dejan de coincidir.
- Jörg Desel y Javier Esparza, *Free Choice Petri Nets*, Cambridge Tracts in Theoretical Computer Science 40, Cambridge University Press, 1995, [doi:10.1017/CBO9780511526558](https://doi.org/10.1017/CBO9780511526558). La monografía sobre la clase. Registro confirmado en Cambridge Core; no leída. *Por verificar.*
- Tadao Murata, *Petri nets: Properties, analysis and applications*, **Proceedings of the IEEE** 77(4), abril de 1989, páginas 541–580, [doi:10.1109/5.24143](https://doi.org/10.1109/5.24143), secciones II-B y IV para las clases y para los sifones y las trampas. Tras muro de pago y no leído. *Por verificar.*
- La implementación: [`Structure.cs`](https://github.com/spareilleux/learn/blob/main/code/petri-nets/PetriNets/Structure.cs).
