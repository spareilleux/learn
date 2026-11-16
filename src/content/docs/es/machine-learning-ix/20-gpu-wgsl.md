---
title: "20. En la GPU: los shaders WGSL de IX, sus límites y sus aceleraciones"
description: "ix-gpu de IX ejecuta compute shaders WGSL con wgpu 28, puestos a prueba con ocho predicciones escritas antes de la primera ejecución; las ocho se cumplieron. naga rechaza el shader del producto escalar por una palabra reservada, y la función provoca un pánico. El shader kNN guarda un candidato por hilo y pierde vecinos en 135 consultas de 1000, cerca de las 125 que predice un conteo tipo cumpleaños. Las funciones de coseno usan dos umbrales distintos, y similarity_matrix devuelve 1 en la CPU donde devuelve 0 en la GPU. Los límites por defecto hacen que el propio ejemplo de la guía provoque un pánico. El producto de matrices de la GPU iguala al bucle de la CPU una vez fusionadas las multiplicaciones-sumas. Supera las aceleraciones de la guía en tamaños grandes y pierde en 64³."
sidebar:
  order: 20
---

Una GPU ejecuta un mismo programa pequeño, un *compute shader*, en miles de hilos a la vez. El crate [`ix-gpu`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu) de IX, en el commit fijado, escribe sus shaders en [WGSL](https://www.w3.org/TR/WGSL/), el lenguaje de shaders de WebGPU. Los ejecuta con [wgpu](https://wgpu.rs/) 28, que comprueba cada uno con el frontal y el validador de [naga](https://docs.rs/naga/28.0.0/naga/) antes de pasárselo a Vulkan, DX12 o Metal.

Primero, algunos términos:
- los hilos van en *workgroups*, aquí de 256;
- un workgroup puede compartir una pequeña memoria declarada `var<workgroup>`;
- un *dispatch* lanza una cuadrícula de workgroups;
- los datos entran y salen por *storage buffers*.

Cada función GPU del crate recibe un `GpuContext`, que contiene el device y la queue de wgpu. La mayoría de las funciones tienen un gemelo en CPU. `ix-nn` se apoya en una de ellas: su atención llama a `matmul_gpu` para sus dos productos de matrices cuando se le da un contexto ([`attention.rs` 419-494](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-nn/src/attention.rs#L419-L494)). Es la atención del transformer que la [lección 13](../13-transformer/) estudió en la CPU.

Las ocho predicciones que pone a prueba esta lección se [escribieron en el diario](../journal/#2026-09-30--lección-20-predicha-antes-de-medir) y se commitearon antes de que existiera su código. [Los resultados](../journal/#2026-09-30--lección-20-medida) las siguen.

Los runners de la CI no tienen una GPU con la que el curso pueda contar, así que el código se divide en dos:
- **Corre en cualquier sitio.** [`gpu.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/src/gpu.rs) contiene esta parte: naga sobre los cinco shaders, un port del bucle del shader kNN, los umbrales y los límites. Los shaders se copian byte a byte del commit fijado en [`shaders.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/src/gpu/shaders.rs). [`l20_wgsl.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/examples/l20_wgsl.rs) imprime los resultados, y la CI compara su salida en Windows, Linux y macOS.
- **Necesita un adaptador.** La CI no ejecuta [`l20_on_gpu.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/src/bin/l20_on_gpu.rs). La lección cita una ejecución en la máquina del autor, guardada en [`local/l20_on_gpu.txt`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/local/l20_on_gpu.txt). Las pruebas ignoradas de [`tests/l20_gpu.rs`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/tests/l20_gpu.rs) comprueban las mismas predicciones: `cargo test --release --test l20_gpu -- --ignored --test-threads=1`.

[`crosscheck.py`](https://github.com/spareilleux/learn/blob/main/code/machine-learning-ix/crosscheck/crosscheck.py) repite el bucle kNN, los umbrales y los límites en float32 con [NumPy](https://numpy.org/doc/stable/), y encuentra los mismos números.

## 1. Qué corre dónde

`GpuContext::new()` pide a wgpu un adaptador de alto rendimiento, y luego un device con `Limits::default()` ([`context.rs` 24-58](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/context.rs#L24-L58)). El programa imprime lo que obtuvo:

```text
== the adapter
  NVIDIA GeForce RTX 5080 (Vulkan); GpuContext::new() took 532 ms
```

La guía en francés de IX dice que `GpuContext::new()` tarda de 10 a 100 ms ([`introduction-calcul-gpu.md` 166](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/introduction-calcul-gpu.md?plain=1#L166)). Tardó 532 ms en esta ejecución, y 1316 ms en la primera. Después de la primera ejecución, el programa se cambió para crear tres contextos más en el mismo proceso, y su tiempo mediano fue de 274 ms. El consejo de la guía se sostiene: crea un contexto y consérvalo. Pero cuenta con un cuarto de segundo o más para él, no con una décima.

## 2. Una palabra reservada

`dot_product_gpu` reduce un producto en una memoria de workgroup declarada `var<workgroup> shared: array<f32, 256>;` ([`similarity.rs` 81](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/similarity.rs#L81)). `shared` es una de las [palabras reservadas](https://www.w3.org/TR/WGSL/#reserved-words) de WGSL: la especificación la guarda para un uso futuro, así que un shader no puede llamar `shared` a nada. La lección pasa los cinco shaders del crate que estudia por el frontal WGSL de naga, luego por su validador, y cuenta las variables en el espacio de direcciones del workgroup:

```text
== P1, naga 28 on five shaders of ix-gpu, copied from the pinned commit
  cosine: parses; validates: yes; workgroup variables: 3
  dot product: parse error: name `shared` is a reserved keyword
  dot product, `shared` renamed: parses; validates: yes; workgroup variables: 1
  distance matrix: parses; validates: yes; workgroup variables: 0
  kNN: parses; validates: yes; workgroup variables: 0
  matrix product: parses; validates: yes; workgroup variables: 0
```

El shader del coseno es la misma reducción con otros nombres, y pasa. Renombrado, el producto escalar también pasa.

En una GPU, el error de análisis aparece cuando se ejecuta `create_shader_module`. wgpu pasa un error que nadie capturó a un manejador por defecto, y ese manejador provoca un pánico ([`wgpu_core.rs` 694-697](https://docs.rs/wgpu/28.0.0/src/wgpu/backend/wgpu_core.rs.html#694-697)). `ix-gpu` no captura ninguno. Sus `GpuError::ShaderCompilation` y `GpuError::BufferMapping` están declarados y nunca se construyen ([`context.rs` 158-163](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/context.rs#L158-L163)). Un pánico en una llamada de biblioteca se lleva consigo el hilo de quien llama. Por eso el programa hace cada llamada que puede provocar un pánico en un proceso hijo propio, `l20_on_gpu probe …`, lanzado con [`std::process::Command`](https://doc.rust-lang.org/std/process/struct.Command.html):

```text
== P1 on the GPU
  dot_product_gpu, in a process of its own: returns: no; message starts with "wgpu error": yes; contains naga's "name `shared` is a reserved keyword": yes
  cosine_similarity_gpu against cosine_similarity_cpu, 1000 components: gap 3.7e-9
```

Así que en este commit, con wgpu 28, `dot_product_gpu` no puede volver. Las propias pruebas del crate tampoco llegan a la GPU: las pruebas GPU de `knn.rs` y de `distance.rs` están comentadas, bajo «GPU tests require hardware» ([`knn.rs` 367-376](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/knn.rs#L367-L376), [`distance.rs` 242](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/distance.rs#L242)).

La última línea de la salida de naga contradice un comentario de documentación. `matmul.rs` dice que su shader «Uses tiled approach with shared memory for better cache behavior» ([`matmul.rs` 11](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/matmul.rs#L11)). Pero el módulo no declara ninguna variable de workgroup: cada hilo calcula un elemento del resultado directamente desde la memoria global. La guía del producto de matrices lo reconoce y llama al shader actual un enfoque simple por elemento ([`multiplication-matricielle-gpu.md` 226](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/multiplication-matricielle-gpu.md?plain=1#L226)). La guía de similitud todavía remite a su lector a «le compute shader tuilé sous le capot» ([`recherche-de-similarite.md` 231](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/recherche-de-similarite.md?plain=1#L231)). Otro comentario de documentación se equivoca: el de `euclidean_distance_cpu` dice «Euclidean distance on GPU (via compute shader)» ([`similarity.rs` 249](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/similarity.rs#L249)).

## 3. Un candidato por hilo

`batch_knn_gpu` lanza un workgroup de 256 hilos por consulta ([`knn.rs` 34-229](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/knn.rs#L34-L229)):
1. El hilo t recorre las referencias t, t + 256, t + 512, … y solo guarda la más cercana.
2. La CPU ordena los 256 candidatos y guarda los k primeros.

El comentario de documentación describe otra cosa: «a parallel selection of the k smallest», con «k limited to 32 (stored in shared memory per thread)» ([`knn.rs` 27-33](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/knn.rs#L27-L33)). El shader no tiene ninguna variable de workgroup, y k no está limitado.

Llamemos *clase t* a las referencias cuyo índice es congruente con t módulo 256. Los k más cercanos salen bien si y solo si caen en k clases distintas. Si dos de ellos comparten una clase, el hilo de esa clase solo guarda uno, y una referencia más lejana ocupa el lugar del perdido.

Para referencias y una consulta independientes e idénticamente distribuidas, el conjunto de los índices de los k más cercanos es un subconjunto de tamaño k uniforme de {0, …, N − 1}. Así que P(bien) = e_k(s₀, …, s₂₅₅)/C(N, k), donde s_t es el tamaño de la clase t y e_k el k-ésimo polinomio simétrico elemental. Es el problema del cumpleaños con clases de tamaño desigual. Con N = 1000 hay 232 clases de 4 y 24 de 3, y para k = 10 la fórmula da P(mal) = 0,1253. La predicción era de 90 a 160 consultas erróneas de 1000, alrededor de 125,3 con una desviación típica de 10,5.

`knn_shader_port` porta el bucle a Rust, en f32, con el mismo orden de operaciones. Este programa lo compara con `batch_knn_cpu`, el gemelo en CPU de IX, que ordena todas las referencias:

```text
== P2, the kNN shader's loop ported to Rust: 1000 references and 1000 queries uniform in [0, 1)^8, k = 10
  P(two of the 10 nearest share a class modulo 256) = 1 - e_10(class sizes) / C(1000, 10) = 0.1253
  queries whose 10 nearest differ from batch_knn_cpu's: 135; with k = 1: 0; with the first 256 references: 0
  true neighbours the port returns: 9855 of 10000
```

El port pierde vecinos en 135 consultas: 145 de los 10 000 vecinos verdaderos, así que algunas consultas pierden dos. Nunca falla con k = 1, ni cuando cada clase contiene una sola referencia. Una prueba unitaria añade el control: con 256 referencias como mucho, el port iguala a `batch_knn_cpu` para k = 1, 5, 200 y 250. La repetición en float32 de NumPy encuentra los mismos 135 y los mismos 9855.

El port solo sustituye al shader si la GPU hace lo mismo, y P6 lo comprueba en el adaptador del autor:

```text
== P6, batch_knn_gpu on P2's data, k = 10
  queries whose 10 indices equal the port's, in order: 1000 of 1000; largest distance gap 1.2e-7
  queries whose 10 nearest differ from batch_knn_cpu's: GPU 135, port 135
  the first 256 of the 1000 references: equal to batch_knn_cpu's, in order, for 1000 of 1000
```

La pérdida no disminuye con más datos. Después de la primera ejecución, la fórmula se evaluó también en otros tamaños:

```text
== exploratory
  P(some of the 10 nearest lost): N = 2000 0.1444, N = 10000 0.1593; N = 1000 with k = 5 0.0291, with k = 20 0.4371
```

Cuando N crece, las clases se igualan, y P(mal) tiende al problema del cumpleaños simple con 256 días, 1 − (256 · 255 ⋯ 247)/256¹⁰ ≈ 0,1631. Crece deprisa con k. Una selección exacta de los k más cercanos en una GPU guarda k candidatos por hilo y luego los fusiona. [Johnson, Douze y Jégou (2021)](https://doi.org/10.1109/TBDATA.2019.2921572) describen cómo lo hace Faiss en registros.

## 4. Dos umbrales y una diagonal

Tres funciones deciden de dos maneras distintas cuándo una norma es demasiado pequeña para un coseno:
- `cosine_similarity_cpu` devuelve 0 cuando alguna de las normas está por debajo de 10⁻¹⁰ ([`similarity.rs` 235-247](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/similarity.rs#L235-L247));
- `similarity_matrix_gpu` y `batch_top_k` devuelven 0 cuando el producto de las dos normas es como mucho 10⁻¹⁰ ([`batch.rs` 73](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/batch.rs#L73), [157](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/batch.rs#L157)).

Aparte, `similarity_matrix_cpu` escribe 1 en la diagonal sin calcularla ([`batch.rs` 23-37](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/batch.rs#L23-L37)). Dos vectores a y b = 2a apuntan en la misma dirección, con normas 3·10⁻⁶ y 6·10⁻⁶:

```text
== P3, a = (1e-6, 2e-6, 2e-6), b = 2a, z = 0, in f32
  cosine_similarity_cpu(a, b) 1.000000; similarity_matrix(None, [a, b])[0][1] 1.000000; batch_top_k(None, [a], [b], 1) 0.000000
  similarity_matrix(None, [z, b])[0][0] 1.000000; cosine_similarity_cpu(z, z) 0.000000
```

`batch_top_k` les da una similitud de 0: el producto de sus normas, 1,8·10⁻¹¹, está por debajo de su umbral. El vector nulo z es plenamente similar a sí mismo en la matriz, y en absoluto en `cosine_similarity_cpu`.

Después de la primera ejecución, los mismos vectores pasaron por `similarity_matrix` con un contexto:

```text
  P3's vectors with a context: similarity_matrix(Some(&ctx), [a, b])[0][1] 0.000000; similarity_matrix(Some(&ctx), [z, b])[0][0] 0.000000
```

El comentario de documentación de `similarity_matrix` dice «Uses GPU if context is provided, otherwise CPU fallback» ([`batch.rs` 12](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/batch.rs#L12)). La alternativa en CPU no calcula lo mismo. Un vector nulo es un dato corriente (un documento vacío, una fila de relleno), y obtiene 1 o 0 según se haya encontrado o no una GPU.

## 5. Los imports de la skill

La página de la skill `ix-gpu` muestra tres imports: `use ix_gpu::similarity::GpuCosineSimilarity;`, `use ix_gpu::matmul::GpuMatMul;` y `use ix_gpu::distance::GpuDistanceMatrix;` ([`SKILL.md` 28-31](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/.claude/skills/ix-gpu/SKILL.md?plain=1#L28-L31)). El único struct público del crate es `GpuContext`, y sus módulos exportan funciones. P4 guarda cada una de las tres líneas como doctest `compile_fail`, que falla con E0432, import sin resolver. La cuarta línea de la página, `use ix_gpu::context::GpuContext;`, se guarda como doctest que compila.

## 6. Los límites

`Limits::default()` permite lo siguiente ([`limits.rs` 363-396](https://docs.rs/wgpu-types/28.0.0/src/wgpu_types/limits.rs.html#363-396)):
- enlaces de almacenamiento de 128 MiB como mucho;
- buffers de 256 MiB como mucho;
- 65 535 workgroups como mucho por dimensión de un dispatch.

wgpu los describe como los límites «guaranteed to work on all modern backends» ([`limits.rs` 93-94](https://docs.rs/wgpu-types/28.0.0/src/wgpu_types/limits.rs.html#93-94)). Un adaptador puede ofrecer más, pero `ix-gpu` nunca pide más. `similarity_matrix_gpu` enlaza el resultado n × n de `matmul_gpu` como un solo storage buffer ([`batch.rs` 43-82](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/batch.rs#L43-L82)). `batch_knn_gpu` lanza un workgroup por consulta a lo largo de una sola dimensión. La aritmética corre en la CI:

```text
== P5, wgpu::Limits::default()
  max_storage_buffer_binding_size 134217728, max_buffer_size 268435456, max_compute_workgroups_per_dimension 65535
  largest n whose n x n f32 matrix fits in one binding: 5792 (134189056 bytes); 5793 needs 134235396
  the guide's 10000 embeddings compared pairwise: 400000000 bytes, above max_buffer_size: yes
```

El lado GPU hace cada llamada en un proceso propio:

```text
== P5 on the GPU, each call in a process of its own
  similarity_matrix, 5792 vectors of dimension 8: returned
  similarity_matrix, 5793 vectors of dimension 8: panics; "wgpu error": yes; last line: Buffer binding 2 range 134235396 exceeds `max_*_buffer_binding_size` limit 134217728
  similarity_matrix, 10000 vectors of dimension 768: panics; "wgpu error": yes; last line: Buffer size 400000000 is greater than the maximum buffer size (268435456)
  batch_knn_gpu, 65535 queries: returned
  batch_knn_gpu, 65536 queries: panics; "wgpu error": yes; last line: Each current dispatch group size dimension ([65536, 1, 1]) must be less or equal to 65535
```

El ejemplo con el que abre la guía, 10 000 embeddings de dimensión 768 ([`introduction-calcul-gpu.md` 5](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/introduction-calcul-gpu.md?plain=1#L5)), no vuelve: provoca un pánico. Lo mismo ocurre con la fila «10 000+» de la guía de similitud, que promete una aceleración de 10-100x ([`recherche-de-similarite.md` 197](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/recherche-de-similarite.md?plain=1#L197)). El error es un pánico, no un `Result`, así que quien llama ni siquiera puede recurrir a la CPU.

Leyendo el código, no con una ejecución: `batch_top_k` también pasa su producto consultas × corpus por `matmul_gpu`. Los mismos 128 MiB acotan por tanto consultas × corpus × 4 bytes.

## 7. Las mismas sumas, casi

`matmul_gpu` y `matmul_cpu` suman sus K productos en el mismo orden ([`matmul.rs` 36-41](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/matmul.rs#L36-L41), [141-156](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/matmul.rs#L141-L156)). También `pairwise_distance_gpu` y `pairwise_distance_cpu`, sobre las dimensiones ([`distance.rs` 46-53](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/distance.rs#L46-L53), [133-153](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/distance.rs#L133-L153)). El mismo orden no significa el mismo redondeo:
- WGSL permite a una implementación fusionar una multiplicación y una suma en una sola operación con un solo redondeo, cuando el resultado es al menos igual de preciso ([§ 15.7.5](https://www.w3.org/TR/WGSL/#reassociation-and-fusion));
- WGSL toma la precisión de `sqrt` de la de `1.0 / inverseSqrt(x)` ([§ 15.7.4.1](https://www.w3.org/TR/WGSL/#concrete-float-accuracy));
- Rust redondea cada operación.

Dos productos de matrices 256 × 256 con coeficientes en [−1, 1), y las distancias entre las 1000 referencias de P2:

```text
== P7, the GPU's sums against the CPU's
  matmul 256 x 256 x 256: elements that differ 53438 of 65536, largest gap 5.7e-6
  pairwise distances of the 1000 references: elements that differ 264496 of 1000000, largest gap 2.4e-7, zero diagonal: yes
```

El 82 % de los elementos del producto difieren, todos en los últimos bits. Los coeficientes tienen una desviación típica de unos 5,3, así que una diferencia de 5,7·10⁻⁶ es alrededor de una millonésima.

Después de la primera ejecución, el programa ejecutó además los dos bucles de CPU con [`f32::mul_add`](https://doc.rust-lang.org/std/primitive.f32.html#method.mul_add), que fusiona cada multiplicación-suma en un solo redondeo:

```text
  P7's loops on the CPU with fused multiply-adds: matmul elements that differ from the GPU 0 of 65536; distances 168810 of 1000000
```

El producto de matrices coincide entonces bit a bit: este driver fusionó cada multiplicación-suma del shader. En las distancias, la fusión baja la cuenta de 264 496 a 168 810, y el resto no se explica aquí. Un candidato es la raíz cuadrada, a la que WGSL no le exige el redondeo correcto, pero esta lección no lo pone a prueba. Otro adaptador u otro backend puede fusionar de otra manera, así que compara un resultado de GPU con uno de CPU con una tolerancia, nunca bit a bit.

## 8. Las aceleraciones prometidas

La guía del producto de matrices da una tabla de la ganancia que cabe esperar en cuatro tamaños ([`multiplication-matricielle-gpu.md` 180-184](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/multiplication-matricielle-gpu.md?plain=1#L180-L184)):

| Tamaño | Ganancia que promete la guía |
|---|---|
| 10 × 10 × 10 | ninguna |
| 64 × 64 × 64 | marginal |
| 256 × 768 × 1024 | 5-20x |
| 1024 × 1024 × 1024 | 20-100x |

P8 solo predijo los dos extremos. Los dos tamaños intermedios se midieron sin predicción. Cada tiempo es la mediana de 5 llamadas tras un calentamiento sin cronometrar, con un solo contexto de principio a fin:

```text
== P8, matmul_cpu against matmul_gpu, median of 5 calls after a warm-up
  10 x 10 x 10: cpu 0.001 ms, gpu 0.490 ms, gpu faster by 0.0x
  64 x 64 x 64: cpu 0.086 ms, gpu 0.448 ms, gpu faster by 0.2x
  256 x 768 x 1024: cpu 179.753 ms, gpu 2.908 ms, gpu faster by 61.8x
  1024 x 1024 x 1024: cpu 2133.655 ms, gpu 8.722 ms, gpu faster by 244.6x
```

La primera ejecución dio 54,0x y 137,1x en los dos tamaños grandes. El tiempo de la GPU en 1024³ apenas se movió entre ejecuciones, de 8,456 a 8,722 ms. El de la CPU pasó de 1160 a 2134 ms, y la lección no sabe por qué.

Las dos ejecuciones superan a la guía en los tamaños grandes. Las dos pierden en 64³, donde la ganancia «marginal» es en realidad una GPU cinco veces más lenta. Tres cosas explican el patrón:
- **La referencia de CPU es débil.** `matmul_cpu` es el triple bucle de manual, en un solo hilo y sin SIMD, como dice la propia guía ([`multiplication-matricielle-gpu.md` 191](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/multiplication-matricielle-gpu.md?plain=1#L191)). En 1024³ tarda de 1 a 2 ns por producto. Así que las aceleraciones miden ese bucle tanto como la GPU. Un producto en CPU por bloques, vectorizado o multihilo las reduciría; la lección no midió ninguno.
- **La GPU hace mucho menos de lo que podría.** 2 × 1024³ operaciones en 8,7 ms son unos 250 GFLOP/s, con un shader sin teselas. [Volkov y Demmel (2008)](https://doi.org/10.1109/SC.2008.5214359) muestran lo que aportan las teselas en memoria de workgroup.
- **Cada llamada a la GPU paga un coste fijo.** Hasta 64³, una llamada cuesta alrededor de medio milisegundo sea cual sea su tamaño. `matmul_gpu` crea sus buffers, su módulo de shader y su pipeline en cada llamada ([`matmul.rs` 60-138](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/matmul.rs#L60-L138)), y luego envía y lee el resultado. La guía indica un coste de inicialización de alrededor de 1 ms, «premier appel : compilation shader» ([`multiplication-matricielle-gpu.md` 192](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/multiplication-matricielle-gpu.md?plain=1#L192)). La guía de similitud añade que las llamadas siguientes reutilizan el pipeline compilado ([`recherche-de-similarite.md` 223](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/recherche-de-similarite.md?plain=1#L223)). Nada en `ix-gpu` guarda un pipeline de una llamada a otra. Puede que el driver guarde en caché el shader compilado, pero esta lección no lo mide.

La guía de introducción sitúa el punto de cruce entre 1000 y 10 000 elementos ([`introduction-calcul-gpu.md` 149](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/introduction-calcul-gpu.md?plain=1#L149)). Una matriz de 64 × 64 contiene 4096 elementos, dentro de ese intervalo, y la GPU es ahí cinco veces más lenta.

## 9. Las predicciones, puntuadas

| | Predicción, escrita antes de la primera ejecución | Medido | Veredicto |
|---|---|---|---|
| P1 | naga rechaza el producto escalar con «name `shared` is a reserved keyword», lo valida una vez renombrado y valida los otros cuatro; ninguna variable de workgroup en el producto de matrices; en la GPU, `dot_product_gpu` provoca un pánico con «wgpu error» y el mensaje de naga, y el coseno coincide con una diferencia de 10⁻⁶ como mucho | Como se predijo; diferencia del coseno 3,7·10⁻⁹ | Confirmada |
| P2 | Los 10 más cercanos del port difieren de los de `batch_knn_cpu` en 90 a 160 consultas de 1000; en ninguna con k = 1 o con las 256 primeras referencias | 135; 0 y 0 | Confirmada |
| P3 | `cosine_similarity_cpu(a, b)` y el [0][1] de la matriz iguales a 1 con una diferencia de 10⁻⁶ como mucho, `batch_top_k` 0; entrada diagonal del vector nulo 1; `cosine_similarity_cpu(z, z)` 0 | 1, 1 y 0; 1; 0 | Confirmada |
| P4 | Los tres imports de la skill fallan con E0432; `use ix_gpu::context::GpuContext;` compila | Como se predijo | Confirmada |
| P5 | 5792 vectores caben y 5793 no; el ejemplo de la guía necesita 400 000 000 bytes, por encima del límite de los buffers; en la GPU, 5792 vuelve, 5793 y 10 000 × 768 provocan un pánico, 65 535 consultas vuelven, 65 536 provocan un pánico | Como se predijo | Confirmada |
| P6 | La GPU devuelve los índices del port, en orden, en 1000 consultas de 1000, distancias con una diferencia de 10⁻⁶ como mucho; con las 256 primeras referencias, los de `batch_knn_cpu` en cada consulta | 1000; 1,2·10⁻⁷; 1000 | Confirmada |
| P7 | `matmul_gpu` difiere de `matmul_cpu` en al menos un elemento y en 10⁻⁴ como mucho; distancias con una diferencia de 10⁻⁵ como mucho, diagonal nula | 53 438 elementos, 5,7·10⁻⁶; 2,4·10⁻⁷, nula | Confirmada |
| P8 | En 1024³, `matmul_gpu` al menos 20 veces más rápida; en 10³, `matmul_cpu` más rápida | 244,6x (137,1x en la primera ejecución); 0,001 frente a 0,490 ms | Confirmada |

Las ocho se cumplieron en la primera ejecución, y no se cambió ningún intervalo después. Algunos intervalos eran anchos: 10⁻⁴ en P7 y 20x en P8 dejan margen, y una predicción que apenas puede fallar enseña menos. Los controles muestran que las comprobaciones pueden fallar:
- el producto escalar renombrado se valida, así que la comprobación con naga no lo rechaza todo;
- el port iguala a `batch_knn_cpu` siempre que cada clase contiene una sola referencia;
- 5792 vectores y 65 535 consultas sí vuelven.

Todo lo que la lección presenta como posterior a la primera ejecución se eligió después de ver su resultado: los bucles fusionados, `similarity_matrix` con un contexto, los contextos adicionales y la fórmula en otros tamaños.

## Qué usar en nuestros repositorios

- **Los errores.** El device de un `GpuContext` es público. Para que un error de wgpu no provoque un pánico, envuelve las llamadas en [`Device::push_error_scope`](https://docs.rs/wgpu/28.0.0/wgpu/struct.Device.html#method.push_error_scope), o instala [`Device::on_uncaptured_error`](https://docs.rs/wgpu/28.0.0/wgpu/struct.Device.html#method.on_uncaptured_error), y recurre al gemelo en CPU. La lección no probó ninguna de las dos; *por verificar*.
- **`dot_product_gpu`:** no puede ejecutarse. Sigue el esquema de `cosine_similarity_gpu`, o usa la CPU.
- **`batch_knn_gpu`:** úsala solo si una consulta puede permitirse perder vecinos: con 1000 referencias, el 13 % de las consultas pierde alguno con k = 10 y el 44 % con k = 20. Para vecinos exactos, usa `batch_knn_cpu`, o, hasta 256 referencias, la GPU.
- **`similarity_matrix`:** no te fíes de su resultado con un vector nulo o con vectores de norma diminuta. Normaliza tú mismo los vectores y trata el vector nulo de forma explícita, igual en los dos caminos. Con más de 5792 vectores, divide la matriz en bloques.
- **`batch_knn_gpu` con más de 65 535 consultas:** divide el lote.
- **`matmul_gpu`:** compensa en 256 × 768 × 1024 y por encima en esta máquina, no en 64³. Compara sus resultados con una tolerancia.
- **La skill `ix-gpu`:** importa funciones, como `use ix_gpu::matmul::matmul_gpu;`, y `ix_gpu::context::GpuContext`.

## Ejercicios

1. Calcula a mano P(mal) para k = 2 y N = 1000, y explica después por qué vale exactamente 0 para k = 1.
2. ¿Por qué P(mal) tiende a 1 − (256 · 255 ⋯ 247)/256¹⁰ cuando N crece, para k = 10?
3. Cambia el shader kNN para que devuelva los k más cercanos exactos para k ≤ 16. ¿Qué guarda cada hilo, y qué hace la CPU con ello?
4. Reescribe los umbrales de `cosine_similarity_cpu` y de `batch_top_k` para que den la misma respuesta con los a y b de la sección 4, y con todos sus múltiplos positivos. ¿Qué debería obtener el vector nulo?
5. Con `Limits::default()`, ¿cómo calcularías las similitudes de los 10 000 embeddings de dimensión 768 de la guía con `matmul_gpu`, sin una sola llamada que provoque un pánico?

<details>
<summary>Soluciones</summary>

1. Con k = 2, la respuesta es errónea exactamente cuando los 2 más cercanos comparten una clase. Eso da Σ C(s_t, 2)/C(1000, 2) = (232 × 6 + 24 × 3)/499 500 = 1464/499 500 ≈ 0,00293, es decir, unas 3 consultas de 1000. Para k = 1, la referencia más cercana es la más cercana de su propia clase, así que su hilo la guarda, y es la menor de las 256 candidatas.
2. Cuando N crece, cada clase contiene unas N/256 referencias, y los 10 más cercanos forman un subconjunto uniforme de tamaño 10. Cada índice cae en una clase con una probabilidad cercana a 1/256, independientemente de los demás, porque sacar sin reposición de clases grandes se comporta como sacar con reposición. Caen en 10 clases distintas con probabilidad (256/256) · (255/256) ⋯ (247/256): el problema del cumpleaños con 256 días y 10 personas.
3. Cada hilo guarda sus k más cercanos en un pequeño arreglo ordenado, en registros, e inserta cada nueva distancia desplazando las mayores. La CPU, o una segunda pasada en la GPU, fusiona después las 256 listas ordenadas y guarda los k primeros. Los k más cercanos verdaderos están entre ellos, porque cada uno está entre los k más cercanos de su propia clase. Es el esquema de Johnson, Douze y Jégou, con una fusión en lugar de su ordenación a nivel de warp.
4. El coseno no cambia cuando un vector se multiplica por un factor positivo, así que un umbral fijo sobre una norma, o sobre un producto de normas, no puede ser correcto a todas las escalas. Compara las normas con cero, `norm_a > 0.0 && norm_b > 0.0`, y divide por cada norma por separado, `dot / norm_a / norm_b`, para que el producto de dos normas pequeñas no pueda desbordar por abajo en f32. El vector nulo no tiene dirección, así que su coseno no está definido. Devuelve 0, o `None`, en los dos caminos, y nunca un 1 fijo en la diagonal.
5. Normaliza primero los vectores en la CPU, para que un producto escalar sea un coseno. Divide después los 10 000 vectores en bloques de 5792 filas como mucho, por ejemplo dos bloques de 5000. Cada producto de un bloque por la traspuesta de otro ocupa 5000 × 5000 × 4 = 100 000 000 bytes, por debajo del límite de enlace de 128 MiB. Cuatro productos dan la matriz entera, y bastan tres, porque es simétrica. Las entradas también tienen que caber: 5000 × 768 × 4 = 15 360 000 bytes por bloque.

</details>

## Fuentes

- IX en el commit fijado `490c395`: [`similarity.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/similarity.rs), [`knn.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/knn.rs), [`batch.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/batch.rs), [`matmul.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/matmul.rs), [`distance.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/distance.rs), [`context.rs`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-gpu/src/context.rs), [la skill `ix-gpu`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/.claude/skills/ix-gpu/SKILL.md), y las guías en francés [`introduction-calcul-gpu.md`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/introduction-calcul-gpu.md), [`multiplication-matricielle-gpu.md`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/multiplication-matricielle-gpu.md) y [`recherche-de-similarite.md`](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs/fr/calcul-gpu/recherche-de-similarite.md).
- W3C, [WebGPU Shading Language](https://www.w3.org/TR/WGSL/): [palabras reservadas](https://www.w3.org/TR/WGSL/#reserved-words), [reasociación y fusión](https://www.w3.org/TR/WGSL/#reassociation-and-fusion), [precisión de las expresiones de coma flotante concretas](https://www.w3.org/TR/WGSL/#concrete-float-accuracy).
- [wgpu](https://wgpu.rs/) 28: [`Limits::default`](https://docs.rs/wgpu-types/28.0.0/src/wgpu_types/limits.rs.html#363-396), [el manejador de errores por defecto](https://docs.rs/wgpu/28.0.0/src/wgpu/backend/wgpu_core.rs.html#694-697), [`Device`](https://docs.rs/wgpu/28.0.0/wgpu/struct.Device.html). [naga](https://docs.rs/naga/28.0.0/naga/) 28: [la comprobación de palabras reservadas](https://docs.rs/naga/28.0.0/src/naga/front/wgsl/parse/lexer.rs.html#495-497).
- V. Garcia, E. Debreuve y M. Barlaud, [«Fast k nearest neighbor search using GPU»](https://doi.org/10.1109/CVPRW.2008.4563100), CVPR Workshops, 2008.
- J. Johnson, M. Douze y H. Jégou, [«Billion-scale similarity search with GPUs»](https://doi.org/10.1109/TBDATA.2019.2921572), IEEE Transactions on Big Data 7, 2021.
- V. Volkov y J. W. Demmel, [«Benchmarking GPUs to tune dense linear algebra»](https://doi.org/10.1109/SC.2008.5214359), SC 2008.
- Rust: [`f32::mul_add`](https://doc.rust-lang.org/std/primitive.f32.html#method.mul_add), [`std::process::Command`](https://doc.rust-lang.org/std/process/struct.Command.html). [NumPy](https://numpy.org/doc/stable/).
