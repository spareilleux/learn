---
title: Diario
description: Notas de avance fechadas — Candle 0.11.0 fijado, el código del curso y cómo se comprueba, las mediciones, si GA, IX y TARS usan Candle, dieciséis hallazgos sobre Candle, su documentación y la de IX, y puntos por verificar.
sidebar:
  order: 99
---

## Progreso

- [x] Candle leído en la etiqueta `0.11.0`, commit `31f35b1`; el código del curso depende de `candle-core` y `candle-nn` 0.11.0
- [x] Código del curso: ejemplos, salidas en `expected/`, siete doctests `compile_fail`, `check.sh`
- [x] Mismas salidas en Windows y en Linux (un contenedor `rust:1.94.0`)
- [ ] CI en GitHub: el workflow está escrito, aún no se ha subido
- [x] Lección 1: por qué Candle
- [x] Lección 2: tensores
- [x] Lección 3: cálculo y rendimiento en CPU
- [x] Lección 4: diferenciación automática
- [ ] Lecciones 5 a 12
- [x] Traducciones al francés y al español de las lecciones 1 a 4

## 2026-09-15 — Candle, fijado

- La última versión en crates.io es **0.11.0**, publicada el 26 de junio de 2026. Sus fuentes son la etiqueta `0.11.0`, commit [`31f35b147389700ed2a178ee66a91c3cc25cc80d`](https://github.com/huggingface/candle/commit/31f35b147389700ed2a178ee66a91c3cc25cc80d), clonado aparte de este repositorio. `main` estaba en [`ddf1b87`](https://github.com/huggingface/candle/commit/ddf1b879dc3a1760cbcb3f3c4a7c6467850cec4a) ese mismo día.
- El workspace lista diez miembros, entre ellos los ejemplos WebAssembly, y deja aparte seis crates más (los kernels de GPU, `candle-onnx`, el libro); `candle-transformers` tiene 125 entradas bajo `models/` y `candle-examples` 111 ejemplos.
- El curso fija `=0.11.0` en `Cargo.toml` y hace commit de `Cargo.lock`, en lugar de seguir `main` como hace el `cargo add --git` del libro de Candle.
- El código solo usa la CPU: ninguna feature de Cargo activada, ningún modelo descargado en este lote.

## 2026-09-15 — El código del curso

- [`code/candle`](https://github.com/spareilleux/learn/tree/c45b150/code/candle) es un workspace con un crate, `candle-course`: 13 ejemplos, y `src/lib.rs` con los helpers `show` (redondea cada valor, para que los tres sistemas impriman los mismos dígitos), `outcome` y `caught` (imprime el mensaje de un panic), y los siete doctests `compile_fail`.
- [`check.sh`](https://github.com/spareilleux/learn/blob/c45b150/code/candle/check.sh) ejecuta `cargo fmt --check`, `clippy --release --all-targets -D warnings`, `cargo test --release` y luego cada ejemplo, y compara su salida y su código de salida con `expected/`. `l01_machine` y `l03_bench` dependen de la máquina: se ejecutan sin comparación.
- El `rustdoc` estable comprueba que un fragmento `compile_fail` falla, no con qué error. Un doctest indicaba al principio `E0369` para `Result<Tensor> - f64`; compilar el fragmento dio `E0277`. El workflow añade un `cargo test --doc` con nightly en Linux, que sí comprueba los códigos.
- La primera compilación release compiló 128 crates en 73 segundos con `-j 4`. 72 de los 119 crates detrás de `candle-core` vienen de `tokenizers`.
- `data/builds.csv` es una copia del archivo del curso de IX, del commit `d9ef7fb`, para que la lección 4 entrene con los mismos 52 builds.
- `ix-autograd` viene de Git en el commit `490c395` de IX, el commit del curso de IX, como dependencia de desarrollo.
- En Linux, `check.sh` se ejecutó en Docker Desktop 29.2.1 (`rust:1.94.0`, `--cpus 4`): cada salida comparada fue idéntica a la de Windows.

## 2026-09-15 — El CI

- `.github/workflows/candle-examples.yml` está escrito: `check.sh` en `ubuntu-latest`, `windows-latest` y `macos-latest`, una caché del registro de Cargo, los checkouts de Git y `target/`, con clave en `Cargo.lock`, y el paso de doctests con nightly en Linux.
- No está subido: el token con el que esta sesión hace push no puede crear archivos bajo `.github/workflows/` sin el scope `workflow`. Hasta que se ejecute, macOS (ARM, NEON) queda *por verificar*, en particular las sumas `f32` de la lección 4, que podrían redondearse de otra forma.

## 2026-09-15 — Las mediciones

- Intel Core Ultra 9 285K (24 núcleos, sin hyper-threading), 64 GB, Windows 11 Pro, Rust 1.94.0. La máquina ejecutaba otro trabajo al mismo tiempo; la lección lo dice y trata como ruido las diferencias por debajo de un 20 %.
- La primera versión del benchmark del forward pass ejecutó tensores simples y luego `Var`, una vez cada uno, y mostró el grafo un 35 % más rápido. Ejecutar dos rondas alternadas mostró un efecto de calentamiento; la lección muestra la versión alternada y explica por qué.
- `target-cpu=native` compiló en 65 segundos en un directorio target aparte y no cambió nada más allá del ruido. `gemm` ya elige kernels AVX2 y FMA en tiempo de ejecución.
- En un contenedor limitado a 4 CPU, Candle sigue contando 24 núcleos físicos y arranca 24 hilos: la red pequeña tardó 168 ms frente a 44 ms con `RAYON_NUM_THREADS=1`.

## 2026-09-15 — GA, IX y TARS

Commits leídos: GA [`32f143c`](https://github.com/GuitarAlchemist/ga/tree/32f143c866c126338b332e384e4a615cd4b44381), IX [`a7e5fbc`](https://github.com/GuitarAlchemist/ix/tree/a7e5fbce3d4a7a9d15bb9638b3bcba7c08c2941a) (con `ix-autograd` sin cambios desde `490c395`), TARS [`87464ce`](https://github.com/GuitarAlchemist/tars/tree/87464ce583c42cd11c3d76836e05842377455b24).

- Ninguno de los tres depende de Candle. GA (C#) y TARS (F#) ejecutan sus modelos con ONNX Runtime y `Microsoft.ML.Tokenizers`.
- IX escribió su propia diferenciación automática, `ix-autograd`, sobre `ndarray`, y reserva un lugar para un backend de Candle. La lección 4 muestra que su gradiente y el de Candle coinciden hasta `1e-9` en la regresión del curso de IX.
- Dónde podría servir Candle: los embeddings de GA (la lección 7 compara), y un backend de `ix-autograd` si IX necesita más operaciones o una GPU. Son notas para lecciones posteriores, no propuestas hechas a los proyectos.

## 2026-09-15 — Hallazgos

Dieciséis cosas que encontró este lote, cada una mostrada por código compilado del curso salvo que se indique. Nada se ha abierto como issue ni como pull request.

1. **Un compilador de C para `candle-core` 0.11.0.** Depende de `tokenizers` con la feature `onig`, que compila Oniguruma desde fuentes en C, para un solo archivo, el tokenizador GGUF ([lección 1](../01-why-candle/)). `main` pasó a `fancy-regex`, en Rust puro; la próxima versión debería eliminar el requisito (*por verificar*).
2. **`from_vec` y `from_slice` no comprueban el número de elementos** cuando la forma no tiene hueco: cinco valores con una forma `(2, 3)` se aceptan y provocan un panic más tarde ([lección 2](../02-tensors/)). [Issue #3812](https://github.com/huggingface/candle/issues/3812), corregido en `main` por [#3813](https://github.com/huggingface/candle/pull/3813) el 13 de agosto de 2026, después de 0.11.0.
3. **Las funciones de coma flotante sobre tensores enteros provocan un panic** con `todo!("no unary function for u32")` en lugar de devolver un error ([lección 2](../02-tensors/)). Sigue así en `main` en `ddf1b87`; no encontré ningún issue al respecto.
4. **El generador aleatorio de la CPU no admite semilla**: `Device::Cpu.set_seed(42)` devuelve un error, así que `rand` y `randn` no son reproducibles en la CPU ([lección 2](../02-tensors/)).
5. **La chuleta del README no compila**: `tensor.to_dtype(&DType::F16)?` pasa una referencia donde `to_dtype` recibe un `DType` ([lección 1](../01-why-candle/), un doctest).
6. **`copy()` clona todo el almacenamiento**, no los elementos de la vista: una fila de 1000 elementos de un tensor de 4 MB sigue ocupando 4 MB después de `copy()`; `force_contiguous` ocupa 4 KB ([lección 3](../03-cpu-performance/)).
7. **Un mensaje confuso para un índice de más**: `m.i((0, 0, 0))` sobre una matriz dice "dimension index 0 out of range for shape []" ([lección 2](../02-tensors/)).
8. **`squeeze` sobre una dimensión cuyo tamaño no es 1 tiene éxito en silencio** y devuelve el tensor sin cambios, como PyTorch ([lección 2](../02-tensors/)).
9. **Los gradientes también llegan a tensores simples** que son entradas directas de operaciones registradas: la regresión de la lección 4 calcula gradientes para sus datos ([lección 4](../04-autodiff/)). Correcto, pero trabajo de más.
10. **`backward` sobre un no escalar se inicializa con unos sin avisar**, donde PyTorch se niega ([lección 4](../04-autodiff/)).
11. **El número de hilos por defecto ignora los límites de CPU del contenedor**: 24 hilos con `--cpus 4`, cuatro veces más lento en una red pequeña que un solo hilo ([lección 3](../03-cpu-performance/)).
12. **`target-cpu=native` no aportó ninguna ganancia medible** en productos de matrices, operaciones elemento a elemento ni en una red pequeña en esta máquina; el propio `.cargo/config.toml` de Candle lo activa para sus ejemplos ([lección 3](../03-cpu-performance/)).
13. **Los productos de matrices `f16` no son más rápidos que `f32` en una CPU**: `gemm-f16` convierte a bloques `f32` ([lección 3](../03-cpu-performance/)).
14. **La documentación de IX describe a Candle como usuario de "cuTENSOR"** ([`code-analysis-tools.md`, línea 129](https://github.com/GuitarAlchemist/ix/blob/a7e5fbce3d4a7a9d15bb9638b3bcba7c08c2941a/docs/guides/code-analysis-tools.md?plain=1#L129)); las features CUDA de Candle usan cuBLAS, cuBLASLt, cuRAND, NVRTC y, opcionalmente, cuDNN ([lección 1](../01-why-candle/)). Leído en las fuentes, no ejecutado.
15. **`hf-hub`**: el workspace de Candle 0.11.0 pide `hf-hub` 0.5.0, mientras que la última versión en crates.io es la 1.0.0. Para la lección 6 (*por verificar* qué cambió).
16. **El libro de Candle instala desde Git**: `cargo add --git https://github.com/huggingface/candle.git candle-core` sigue `main`, así que un ejemplo del libro puede depender de código que no se ha publicado ([lección 1](../01-why-candle/)).

## Por verificar

- La primera ejecución del workflow en los tres sistemas, y las salidas `f32` en macOS ARM.
- El requisito del compilador de C tras la próxima versión de Candle.
- `default_num_threads` en Apple Silicon, que solo cuenta los núcleos de rendimiento.
- `CANDLE_GRAD_DO_NOT_DETACH` y las segundas derivadas.
- Por qué las operaciones elemento a elemento contiguas tardan la mitad en Linux que en Windows, en el mismo procesador (la asignación de memoria, como hipótesis).
