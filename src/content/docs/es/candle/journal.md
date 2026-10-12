---
title: Diario
description: Notas de avance fechadas — Candle 0.11.0 fijado, el código del curso y cómo se comprueba, las mediciones, si GA, IX y TARS usan Candle, dieciséis hallazgos sobre Candle, su documentación y la de IX, las predicciones, resultados y tabla QA de la lección 5, y puntos por verificar.
sidebar:
  order: 99
---

## Progreso

- [x] Candle leído en la etiqueta `0.11.0`, commit `31f35b1`; el código del curso depende de `candle-core` y `candle-nn` 0.11.0
- [x] Código del curso: ejemplos, salidas en `expected/`, nueve doctests `compile_fail`, `check.sh`
- [x] Mismas salidas en Windows y en Linux (un contenedor `rust:1.94.0`)
- [x] CI en GitHub: Linux, Windows y macOS ARM, primera ejecución el 2026-09-16
- [x] Lección 1: por qué Candle
- [x] Lección 2: tensores
- [x] Lección 3: cálculo y rendimiento en CPU
- [x] Lección 4: diferenciación automática
- [x] Lección 5: una primera red con `candle-nn`
- [ ] Lecciones 6 a 12
- [x] Traducciones al francés y al español de las lecciones 1 a 5

## QA

Lo que el curso encontró en Candle a partir de la lección 5; los hallazgos 1 a 16 están en la [entrada del 2026-09-15](#2026-09-15--hallazgos). Los enlaces apuntan a Candle `0.11.0`, commit `31f35b1`; `main` se leyó en [`5ba5d5b`](https://github.com/huggingface/candle/tree/5ba5d5b468b5b1df40e82dd3d556987bedeea041) (28 de septiembre de 2026).

| # | Esperado | Lo que pasa | Dónde | Medición | Estado |
|---|---|---|---|---|---|
| 17 | `binary_cross_entropy_with_logit` da una pérdida y un gradiente finitos para cualquier logit | Toma la sigmoide, luego `log p` y `log(1 − p)`: NaN cuando una predicción segura acierta, infinito cuando falla, un gradiente NaN en ambos casos | [`loss.rs:64-74`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-nn/src/loss.rs#L64-L74) | `f32`: logit 17, objetivo 1 → NaN (16 → `1.192e-7`); −100, objetivo 0 → NaN. `f64`: 37 → NaN (36 → `2.220e-16`). La forma estable es finita en los ocho casos ([lección 5](../05-candle-nn/)) | Reproducido; reportado aguas arriba en el [issue #2561](https://github.com/huggingface/candle/issues/2561) (14 de octubre de 2024, abierto); mismo código en `main` |
| 18 | El tipo de objetivo que da la documentación funciona | La documentación de `binary_cross_entropy_with_logit` llama al objetivo «a tensor of u32»; los objetivos `u32` fallan | [`loss.rs:60`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-nn/src/loss.rs#L60) | `dtype mismatch in mul, lhs: U32, rhs: F32` | Reproducido; mismo texto en `main`; no reportado |
| 19 | Un error sobre un tipo de índice nombra el tipo del índice | `gather` indica el tipo del tensor que lee | [`cpu_backend/mod.rs:2883-2890`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/cpu_backend/mod.rs#L2883-L2890); `index_select`, `scatter`, `scatter_add`, `index_add` en las líneas 2879, 2905, 2924, 2973 (leído, no ejecutado) | Objetivos `f32` para logits `f64`: `unsupported dtype F64 for op gather` | Reproducido para `gather`; mismo código en `main`; no se encontró ningún issue |
| 20 | `cross_entropy` rechaza un objetivo `u32::MAX`, o documenta lo que hace con él | `gather` escribe 0 para el máximo de su tipo, una regla desde el [PR #2940](https://github.com/huggingface/candle/pull/2940): la fila no suma nada, pero `nll` sigue dividiendo por el tamaño del lote. Ninguna de las dos documentaciones lo dice | [`cpu_backend/mod.rs:623-626`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-core/src/cpu_backend/mod.rs#L623-L626), [`loss.rs:14-30`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-nn/src/loss.rs#L14-L30) | `0.1725049744` = (fila 1 + fila 3) / 3; el `ignore_index` de PyTorch promedia sobre las otras filas: `0.2587574616` | Reproducido; no reportado |
| 21 | `linear` inicializa como el `nn.Linear` de PyTorch | Una normal de Kaiming, de desviación típica `√(2 / in)`: `√6 ≈ 2.449` veces la de `nn.Linear` | [`linear.rs:84-94`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-nn/src/linear.rs#L84-L94), [`init.rs:105-109`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-nn/src/init.rs#L105-L109) | 512 × 512: desviación típica a menos del 1 % de 0,0625, 4,55 % de los pesos más allá de dos desviaciones típicas | Confirmado; una decisión de diseño, no un defecto, que conviene conocer al portar un modelo |
| 22 | Un optimizador que recibe una variable que no actualizará lo dice | Las variables no flotantes se descartan y las que no tienen gradiente se saltan, sin error | [`optim.rs:44-47`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-nn/src/optim.rs#L44-L47), [`optim.rs:123`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-nn/src/optim.rs#L123), [`optim.rs:58-65`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-nn/src/optim.rs#L58-L65) | `SGD::new` con una variable `U32` y una `F32` conserva 1; una variable fuera de la pérdida queda igual | Reproducido; intencionado, no documentado |

## Experimentos

| Pregunta | Hipótesis, escrita el 2026-09-30 antes del código | Resultado | Veredicto | Entrada, código |
|---|---|---|---|---|
| ¿Cómo inicializa `linear`? | Desviación típica de los pesos a menos del 1 % de 0,0625 en 512 → 512, `√6` veces la de PyTorch; sesgos dentro de ±0,0442 | A menos del 1 %; razón 2,449; todos los sesgos dentro de ±0,0442; 4,55 % más allá de dos desviaciones típicas, como una normal | Confirmada | [2026-10-01](#2026-10-01--lección-5-resultados-frente-a-las-predicciones), [`l05_modules.rs`](https://github.com/spareilleux/learn/blob/40470dc/code/candle/course/examples/l05_modules.rs#L94-L125) |
| ¿Son iguales dos `VarMap` llenados por las mismas llamadas? | No, el generador de la CPU no admite semilla | Distintos; iguales tras `reseed(…, 5)` | Confirmada | [2026-10-01](#2026-10-01--lección-5-resultados-frente-a-las-predicciones), [`l05_modules.rs`](https://github.com/spareilleux/learn/blob/40470dc/code/candle/course/examples/l05_modules.rs#L127-L152) |
| ¿`cross_entropy` coincide con la fórmula y resiste logits grandes? | Igual hasta `1e-12` en `f64`; finita en 1000 donde softmax y luego log ingenuos dan NaN | `0.2458859914` de ambas formas; 0, 1000 y 2000 para los logits 1000, 0, −1000; ingenuo: `[NaN, -inf, -inf]` | Confirmada | [2026-10-01](#2026-10-01--lección-5-resultados-frente-a-las-predicciones), [`l05_losses.rs`](https://github.com/spareilleux/learn/blob/40470dc/code/candle/course/examples/l05_losses.rs#L32-L68) |
| ¿Dónde se rompe `binary_cross_entropy_with_logit`? | NaN en el logit 17 en `f32` (16 finito), en −100 para el objetivo 0, en el logit 37 en `f64` (36 finito); forma estable finita | Exactamente esos umbrales; una predicción segura y errónea da infinito; el gradiente es NaN en los seis casos que fallan | Confirmada | [2026-10-01](#2026-10-01--lección-5-resultados-frente-a-las-predicciones), [`l05_losses.rs`](https://github.com/spareilleux/learn/blob/40470dc/code/candle/course/examples/l05_losses.rs#L93-L137) |
| ¿`SGD` y `AdamW` coinciden con sus algoritmos? | SGD bit a bit; tres pasos de AdamW hasta `1e-12` en `f64` | SGD bit a bit; AdamW también bit a bit, en cada uno de los tres pasos | Confirmada, más allá de la hipótesis | [2026-10-01](#2026-10-01--lección-5-resultados-frente-a-las-predicciones), [`l05_optimizers.rs`](https://github.com/spareilleux/learn/blob/40470dc/code/candle/course/examples/l05_optimizers.rs#L19-L72) |
| ¿Qué hace un optimizador con una variable `u32`? | Un `SGD` construido con un `Var` `u32` y uno `f32` conserva uno | Conserva 1; `AdamW::new` acepta ambos sin error | Confirmada | [2026-10-01](#2026-10-01--lección-5-resultados-frente-a-las-predicciones), [`l05_optimizers.rs`](https://github.com/spareilleux/learn/blob/40470dc/code/candle/course/examples/l05_optimizers.rs#L74-L95) |
| ¿Qué tal clasifica Iris una red 4 → 16 → 3? | Al menos 28 de 30 flores de prueba tras 300 épocas de AdamW a 0,01; errores solo entre versicolor y virginica | 29 de 30; el error es una virginica (fila 120) tomada por una versicolor; entrenamiento 118 de 120 | Confirmada | [2026-10-01](#2026-10-01--lección-5-resultados-frente-a-las-predicciones), [`l05_iris.rs`](https://github.com/spareilleux/learn/blob/40470dc/code/candle/course/examples/l05_iris.rs#L52-L98) |
| ¿Cambia `f32` el resultado? | Mismas 30 predicciones de prueba; pérdida final a menos de `1e-4` de la de `f64` | Mismas predicciones; misma pérdida con cuatro decimales en las seis épocas mostradas | Confirmada | [2026-10-01](#2026-10-01--lección-5-resultados-frente-a-las-predicciones), [`l05_iris.rs`](https://github.com/spareilleux/learn/blob/40470dc/code/candle/course/examples/l05_iris.rs#L100-L112) |
| ¿SGD a 0,1 frente a AdamW a 0,01? | SGD termina con una pérdida de entrenamiento más alta | 0,0846 frente a 0,0355, mismas 29 de 30; SGD iba por delante en la época 10 (0,6089 frente a 0,9078) | Confirmada | [2026-10-01](#2026-10-01--lección-5-resultados-frente-a-las-predicciones), [`l05_iris.rs`](https://github.com/spareilleux/learn/blob/40470dc/code/candle/course/examples/l05_iris.rs#L114-L126) |

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

## 2026-09-30 — Lección 5: predicciones antes de la primera ejecución

Escritas a partir de las fuentes de `candle-nn` 0.11.0, antes de que existiera el código de la lección; la entrada de resultados contrastará cada una con lo que impriman los programas. El conjunto de datos es Iris, del UCI Machine Learning Repository (Fisher, 1936, [doi:10.24432/C56C76](https://doi.org/10.24432/C56C76), CC BY 4.0), en su versión corregida `bezdekIris.data`; el archivo contiene también `iris.data`, cuyas filas 35 y 38 difieren del artículo de Fisher.

1. **Inicialización.** [`linear`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-nn/src/linear.rs#L84-L94) toma sus pesos de una normal de desviación típica √(2 / in), Kaiming con la ganancia de ReLU ([`init.rs`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-nn/src/init.rs#L105-L109)), y sus sesgos de una uniforme en ±1/√in. En una capa 512 → 512, la desviación típica medida de los pesos debería quedar a menos del 1 % de 0,0625, √6 ≈ 2,45 veces la de `nn.Linear` por defecto en PyTorch (uniforme en ±1/√in, desviación típica 1/√(3 · in)), y cada sesgo dentro de ±0,0442, como en PyTorch.
2. **Reproducibilidad.** Dos `VarMap` llenados con las mismas llamadas a `linear` reciben pesos distintos, porque al generador de la CPU no se le puede dar semilla (hallazgo 4). El curso sobrescribirá cada variable con valores de su propio generador con semilla.
3. **Entropía cruzada.** `loss::cross_entropy` debería ser igual a la media de −log softmax en el objetivo, calculada a mano, con un margen de 1e-12 en `f64`, y seguir finita con logits de 1000, donde softmax y luego log escritos de forma ingenua (sin restar el máximo) dan NaN.
4. **Entropía cruzada binaria con logits.** [`binary_cross_entropy_with_logit`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-nn/src/loss.rs#L64-L74) aplica la sigmoide y luego los logaritmos de `p` y de `1 − p`, así que una predicción segura y *correcta* debería dar NaN. En `f32`, ocurre con un logit de 17 y objetivo 1 (16 sigue finito) y con un logit de −100 y objetivo 0; en `f64`, con un logit de 37 y objetivo 1 (36 sigue finito). La forma estable `max(x, 0) − x·y + log(1 + e^−|x|)` sigue finita en todos los casos. La [incidencia #2561](https://github.com/huggingface/candle/issues/2561) señala la inestabilidad desde 2024.
5. **Optimizadores.** Un paso de [`SGD`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-nn/src/optim.rs#L31-L70) es igual a `θ − lr · g` bit a bit (no hay momentum). Tres pasos de [`AdamW`](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-nn/src/optim.rs#L117-L183) son iguales al algoritmo AdamW de PyTorch escrito a mano (decaimiento desacoplado `θ · (1 − lr · λ)`, momentos con corrección de sesgo, ε fuera de la raíz) con un margen de 1e-12 en `f64`.
6. **Variables enteras.** Los dos optimizadores descartan sin avisar las variables cuyo tipo no es flotante: un `SGD` construido con un `Var` `u32` y un `Var` `f32` conserva una sola variable.
7. **Iris.** Una red 4 → 16 → 3 con ReLU, entrenada con 120 filas (40 por especie, estandarizadas con las medias y desviaciones del conjunto de entrenamiento) durante 300 épocas de `AdamW` sobre el lote completo, con una tasa de aprendizaje de 0,01, clasifica bien al menos 28 de las 30 filas apartadas, y sus posibles errores son entre versicolor y virginica, ninguno en setosa.
8. **`f32` frente a `f64`.** El mismo entrenamiento en `f32` da las mismas 30 predicciones de prueba, y una pérdida final de entrenamiento a menos de 1e-4 de la de `f64`.
9. **`SGD` frente a `AdamW`.** El `SGD` simple con una tasa de 0,1, desde los mismos pesos y durante las mismas 300 épocas, termina con una pérdida de entrenamiento más alta que `AdamW` con 0,01.

## 2026-10-01 — Lección 5: resultados frente a las predicciones

Los cinco ejemplos se ejecutaron en Windows 11 con Rust 1.94.0; `check.sh` pasó (formato, clippy, 9 doctests, 18 ejemplos, las 11 salidas comparadas antes de esta lección sin cambios), y los doctests nightly (1.97.0) confirmaron `E0599` para los dos nuevos fragmentos `compile_fail`. El código es el commit [`40470dc`](https://github.com/spareilleux/learn/tree/40470dc/code/candle).

1. **Inicialización**: confirmada. En 262.144 pesos, la desviación típica está a menos del 1 % de 0,0625 y el 4,55 % de los pesos está más allá de dos desviaciones típicas, como en una normal; razón respecto al `nn.Linear` de PyTorch, 2,449; todos los sesgos dentro de ±0,0442. El programa imprime comprobaciones, no los valores aleatorios.
2. **Reproducibilidad**: confirmada. Dos `VarMap` difieren; `reseed` los iguala, con sorteos uniformes cuya desviación típica es la de `linear`.
3. **Entropía cruzada**: confirmada, `0.2458859914` con Candle y a mano. Logits de 1000 dan 0, 1000 y 2000; la versión ingenua da `[NaN, -inf, -inf]`.
4. **Entropía cruzada binaria con logits**: confirmada en cada umbral predicho. No predicho: una predicción segura y *errónea* da infinito en lugar de NaN, y el gradiente es NaN en los seis casos que fallan.
5. **Optimizadores**: confirmada, y más: los tres pasos de AdamW coinciden con la transcripción bit a bit, no solo hasta `1e-12`, porque repite el orden de operaciones de `optim.rs`. PyTorch 2.14 las ordena de otra forma ([`adam.py`, líneas 533-546](https://github.com/pytorch/pytorch/blob/v2.14.0/torch/optim/adam.py#L533-L546)).
6. **Variables enteras**: confirmada, `SGD` conserva 1 de 2. Una variable fuera de la pérdida también queda igual, sin error.
7. **Iris**: confirmada, 29 de las 30 flores apartadas. El error es la fila 120 de `bezdekIris.data`, una virginica de 6,0, 2,2, 5,0 y 1,5 cm tomada por una versicolor; ningún error en setosa.
8. **`f32`**: confirmada, las mismas 30 predicciones y las mismas pérdidas con cuatro decimales.
9. **SGD**: confirmada al final, 0,0846 frente a 0,0355. No predicho: SGD iba por delante en la época 10.

Las nueve hipótesis se sostuvieron. La mayoría salía de leer las fuentes de `candle-nn`, así que la ejecución sobre todo confirmó la lectura; los hallazgos vinieron de lo que no se había predicho, las filas 18 a 20 de la tabla QA: el objetivo `u32` documentado que falla, el error que nombra el tipo equivocado, y el objetivo `u32::MAX` que se salta pero se cuenta. El CI que se ejecutó el 2026-09-16 ([run 35096038472](https://github.com/spareilleux/learn/actions/runs/35096038472), commit `f922f5d`) pasó en Linux, Windows y macOS sobre una imagen `arm64`, lo que resuelve el *por verificar* anterior sobre `f32` en macOS ARM para las lecciones 1 a 4. El CI del pull request de la lección 5 queda *por verificar*.

## 2026-10-02 — Lección 5 en el CI

El CI del pull request ([run 36865098140](https://github.com/spareilleux/learn/actions/runs/36865098140), commit `fd3359e`, 1 de octubre) pasó en los tres sistemas: en Ubuntu 24.04, en Windows (imagen `windows-2025-vs2026`) y en macOS sobre una imagen `arm64` (`macos-26-arm64`), los cinco ejemplos de la lección 5 reprodujeron línea por línea las salidas de `expected/`, también las 11 salidas comparadas antes que ellos, y los nueve doctests pasaron; en Linux, la toolchain nightly confirmó además `E0599` para los dos nuevos fragmentos `compile_fail`. Las salidas que podían depender de la plataforma se sostuvieron: las pérdidas con cuatro decimales, el entrenamiento en `f32`, el gradiente subnormal impreso `4e-44`, los pesos con semilla y las comprobaciones de la inicialización. Esto resuelve el *por verificar* de arriba.

## Por verificar

- Si entrenar con `iris.data` en lugar de `bezdekIris.data` cambia los resultados de la lección 5 (la fila 35 es una flor de prueba).
- El AdamW de PyTorch frente a los números de la lección 5: igual salvo redondeo, por hipótesis, no bit a bit.
- El requisito del compilador de C tras la próxima versión de Candle.
- `default_num_threads` en Apple Silicon, que solo cuenta los núcleos de rendimiento.
- `CANDLE_GRAD_DO_NOT_DETACH` y las segundas derivadas.
- Por qué las operaciones elemento a elemento contiguas tardan la mitad en Linux que en Windows, en el mismo procesador (la asignación de memoria, como hipótesis).
