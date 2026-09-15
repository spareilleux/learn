---
title: Diario
description: Notas de avance fechadas — IX fijado en 490c395, los datos extraídos del CI de este sitio, el CI del código del curso, nueve puntos en los que IX difiere del libro de texto o de scikit-learn, y puntos por verificar.
sidebar:
  order: 99
---

## Progreso

- [x] IX clonado y fijado en el commit `490c395`; el código del curso depende de cinco de sus crates
- [x] Datos: `builds.csv` y `jobs.csv`, extraídos del historial de CI y del historial de Git de este repositorio
- [x] CI: formato, clippy, pruebas unitarias y cada ejemplo comparado con `expected/` en tres sistemas operativos, y una comprobación cruzada con numpy y scikit-learn en Linux
- [x] Lección 1: datos, características y evaluación
- [x] Lección 2: regresión lineal y descenso de gradiente
- [x] Lección 3: clasificación
- [x] Lección 4: agrupamiento
- [ ] Traducciones al francés y al español

## 2026-09-14 — IX, fijado

- IX está clonado aparte de mi copia de trabajo, con `git clone --filter=blob:none`, y en el checkout de [`490c39533627d296bf9f8f050e6fafc14d7a20c2`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2), un commit de `main` del 2026-09-14, 21:40 UTC. El workspace tiene 83 carpetas bajo `crates/` (su README dice 81 crates); el curso lee `ix-math`, `ix-supervised`, `ix-optimize`, `ix-unsupervised`, `ix-voicings`, `ix-io` e `ix-agent`, y depende de los cinco primeros.
- `Cargo.toml` nombra cada crate con `git` y `rev`, y `Cargo.lock` está en el commit. Cargo descarga una sola vez el repositorio completo de IX para los cinco crates, incluido su submódulo `governance/demerzel`.
- El código del curso comparte `ndarray` 0.17 con IX: las matrices pasan de las versiones a mano a las funciones de IX sin conversión.
- Las herramientas MCP de IX de mi sesión de Claude Code me ayudaron a encontrar los algoritmos; cada resultado de las lecciones viene de los ejemplos compilados, no de las herramientas.

## 2026-09-14 — Los datos

- [`data/extract.py`](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/data/extract.py) lee `code/duckdb/data/runs.json` y `jobs.json`, la exportación que hizo el [curso de DuckDB](../../duckdb/journal/) el 2026-09-14, y ejecuta `git ls-tree` en cada commit compilado para contar sus archivos `.md` y `.mdx`.
- `builds.csv`: los jobs `build` exitosos de *Deploy to GitHub Pages*, 65 filas, con los segundos del paso cuyo nombre empieza por *Install, build*.
- `jobs.csv`: los jobs que terminaron con éxito o con fallo y tienen a la vez un paso de checkout y su paso posterior, 186 filas. El sistema operativo es la etiqueta del runner sin `-latest`. `queue_s` es el tiempo desde la creación del job hasta su inicio.
- Cada tiempo es un número entero de segundos (la diferencia de dos marcas de tiempo, truncada). La lección 1 muestra lo que eso le hace a la inferencia de tarea de IX, la lección 4 lo que le hace a una mezcla gaussiana.
- No se descargó ningún conjunto de datos: ambos archivos se derivan de este repositorio público.

## 2026-09-14 — El CI

- [`ml-ix-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/ml-ix-examples.yml) ejecuta [`check.sh`](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/check.sh) en `ubuntu-latest`, `windows-latest` y `macos-latest`: `cargo fmt --check`, `cargo clippy --release --all-targets -- -D warnings`, `cargo test --release` (pruebas unitarias y doctests, incluida la importación `compile_fail` de la lección 4), y luego cada ejemplo, cuya salida y código de salida se comparan con `expected/` mediante `diff --strip-trailing-cr`. `UPDATE=1` reescribe `expected/`, `CROSSCHECK=1` añade la comprobación en Python en local.
- La comprobación cruzada solo se ejecuta en Linux, con Python 3.13, numpy 2.4.2 y scikit-learn 1.8.0: recalcula las métricas, la recta de regresión, el árbol de decisión, las exactitudes de los k vecinos más cercanos, las siluetas, DBSCAN y una mezcla gaussiana, y compara su salida con `expected/crosscheck.txt`. No puede reproducir el generador de números aleatorios de IX, así que no reproduce los inicios de k-means ni las divisiones aleatorias de IX.
- Los valores de punto flotante se imprimen con un número fijo de decimales (`fmt_vec` en [`src/lib.rs`](https://github.com/spareilleux/learn/blob/15cde43/code/machine-learning-ix/src/lib.rs#L47-L51)), así que las salidas son idénticas en los tres sistemas; ninguna necesitó un archivo por sistema operativo.
- Las ejecuciones [34903197003](https://github.com/spareilleux/learn/actions/runs/34903197003) (los ejemplos de las lecciones, commit `d9ef7fb`) y [34903462618](https://github.com/spareilleux/learn/actions/runs/34903462618) (las soluciones de los ejercicios, commit `15cde43`) pasaron en los cuatro jobs al primer push.

## 2026-09-14 — Decisiones al escribir el código

- `train_test_split`, k-means++, el inicio del GMM y `StratifiedKFold` de IX sacan sus números de `StdRng` de Rust, que Python no puede reproducir. Para ellos, la versión a mano parte del resultado ajustado de IX y comprueba que un paso más no cambia nada (k-means, EM), y la comprobación cruzada compara lo que no depende del inicio: tamaños, inercias del mejor de n, log-verosimilitudes.
- La lección 3 prueba con uno de cada cinco jobs, una división que ambos lenguajes pueden hacer.
- La lección 3 ejecuta `k = 4` junto a `k = 5` por el desempate de IX: el empate que vi primero desapareció cuando el conjunto de prueba pasó a ser uno de cada cinco jobs, y `k = 4` estandarizado vuelve a mostrar uno, en una fila de prueba real.
- La primera comparación de la mezcla gaussiana no coincidía con scikit-learn. Rastrearla llevó a las varianzas colapsadas de `complete_s`, que se convirtieron en una sección de la lección 4 en lugar de una nota al pie.

## 2026-09-14 — Donde IX difiere

Nueve puntos en los que la respuesta de IX, o su documentación, difiere del libro de texto o de scikit-learn, cada uno mostrado por código compilado en el curso salvo que se indique lo contrario. Ninguno está registrado como issue de IX.

1. **Escalar antes de dividir.** Con `normalize` activado, el pipeline de ML ajusta `StandardScaler` (y PCA) sobre todas las filas y después divide: las filas de prueba influyen en el escalado ([`ml_pipeline.rs`, líneas 190-203](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-agent/src/ml_pipeline.rs#L190-L203), luego [537-538](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-agent/src/ml_pipeline.rs#L537-L538) y [704-705](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-agent/src/ml_pipeline.rs#L704-L705)). Leído en el código; el mecanismo se muestra en la [lección 1](../01-data-and-evaluation/) (primera fila de prueba 1.440 frente a 1.042), sin ejecutar la herramienta en sí.
2. **Las etiquetas enteras se vuelven clases.** `infer_task_type` considera clasificación cualquier vector de etiquetas de enteros no negativos con como mucho 20 valores distintos ([`preprocessing.rs`, líneas 234-254](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-math/src/preprocessing.rs#L234-L254)): los segundos de build dan `MulticlassClassification { n_classes: 18 }`, y sumar 0.5 a una fila da `Regression`. El pipeline lo usa cuando la tarea es `auto`.
3. **Empates en los k vecinos más cercanos.** `KNN::predict` usa `max_by_key`, que devuelve el último máximo: un empate va al índice de clase más alto ([`knn.rs`, línea 53](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-supervised/src/knn.rs#L53)). En los jobs estandarizados con `k = 4`, la fila de prueba 27 vota `[2, 0, 2]`: IX dice macOS, la versión a mano y scikit-learn Ubuntu, el sistema operativo real; exactitud 0.947 frente a 0.974.
4. **Un cluster vacío de k-means se va al origen.** La actualización de centroides parte de ceros y omite los clusters sin filas ([`kmeans.rs`, líneas 137-152](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/kmeans.rs#L137-L152)). `KMeans(3)` sobre `[5, 5, 9, 9]` da los centroides `[5.0, 9.0, 0.0]`, y `predict([1.0])` devuelve el cluster vacío; scikit-learn da `[5.0, 9.0, 9.0]` con una advertencia.
5. **La silueta de un singleton es 1.** `silhouette_score_exact` en `ix-voicings` pone `a = 0` para una fila sola en su cluster, así que `s = 1`, donde Rousseeuw y scikit-learn usan 0 ([`lib.rs`, líneas 664-678](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-voicings/src/lib.rs#L664-L678)): 0.9296 frente a 0.5963 en `[0, 1 | 10]`.
6. **Las importaciones de los tutoriales no compilan.** `use ix_unsupervised::{KMeans, Clusterer};` falla con `E0432`, porque el crate solo exporta módulos ([`lib.rs`, líneas 5-14](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/lib.rs#L5-L14)). La misma forma aparece en `docs/unsupervised-learning/kmeans.md` (líneas 60 y 91), `dbscan.md` (línea 50), `pca.md` (líneas 63 y 101), `docs/use-cases/fraud-detection.md` (línea 43), `gis-spatial-analysis.md` (líneas 79, 375, 427), `docs/foundations/rust-for-ml.md` (línea 141), y en sus versiones en francés. El doctest del curso comprueba la primera.
7. **Un solo inicio de k-means.** `KMeans::fit` ejecuta un único inicio k-means++, y la herramienta MCP `ix_kmeans` fija la semilla en 42 ([`handlers.rs`, línea 322](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-agent/src/handlers.rs#L322)). En los jobs, las semillas 0 a 9 dan inercias de 411.23 a 618.02; para `k = 6`, la semilla 42 da 223.366 donde el mejor de 50 de scikit-learn da 214.040, con una silueta de 0.3646 frente a 0.4400.
8. **La regla de voicings no compara.** `ix_voicings::cluster` se queda con `k = 5` en cuanto su silueta alcanza 0.15, y solo prueba `k = 3` por debajo de eso ([`lib.rs`, líneas 770-776](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-voicings/src/lib.rs#L770-L776)). En los jobs, se queda con `k = 5` (0.4350) en lugar de `k = 3` (0.4997). Una decisión de diseño más que un error, pero el comentario de documentación llama al umbral uno para «aceptar el agrupamiento», no para elegir `k`.
9. **Colapso de la mezcla gaussiana.** `GMM` pone un mínimo de `1e-6` a cada varianza ([`gmm.rs`, líneas 170-171](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/crates/ix-unsupervised/src/gmm.rs#L170-L171)) y ejecuta un solo inicio aleatorio. Con los tiempos en segundos enteros, las componentes colapsan sobre `complete_s`, y la log-verosimilitud depende de la semilla, de −102.666 a 552.879; el mejor de 10 inicios de scikit-learn es −102.667. Comparar las log-verosimilitudes de IX elige el modelo más colapsado.

Diferencias que vale la pena conocer, que no cuento como errores:

- `LogisticRegression` no tiene regularización ni criterio de parada: con datos separables, sus pesos crecen con el número de iteraciones (lección 3).
- `ix_optimize::gradient::SGD` es descenso de gradiente por lote completo: `minimize` le pasa el gradiente sobre todas las filas.
- `DBSCAN` etiqueta el ruido con `0` y los clusters desde `1`, como dice su documentación; el código escrito para el `-1` de scikit-learn fusiona el ruido con un cluster.
- `ix_io::csv_io::read_csv` convierte los campos de texto en `NaN` sin error.
- `train_test_split` siempre baraja, y toma las etiquetas de clasificación como `f64`; no hay opción estratificada ni por orden temporal.

## Por verificar

- La herramienta `ix_ml_pipeline` de principio a fin: el orden del escalado del hallazgo 1, la inferencia de tarea del hallazgo 2 sobre un archivo CSV, y el error `All rows contain NaN values` para un archivo con una columna de texto. Los tres están leídos en el código, no ejecutados.
- `LinearRegression::fit` con dos características idénticas: si `ix_math::linalg::inverse` devuelve un error y `fit` hace panic, o devuelve una respuesta errónea.
- Un cluster de k-means que se vacía a mitad de una ejecución real, y no al inicio como en el hallazgo 4.
- `ix_voicings::cluster` sobre los voicings de GA: la exportación necesita `FretboardVoicingsCLI` de GA, que el curso no compila.
- La causa del build de 48 segundos de `95a3830`.
- Si los hallazgos 1 a 9 ya se conocen en el proyecto original: no he buscado en los issues de IX.
- Los ejemplos en runners Linux ARM: el CI solo cubre `ubuntu-latest` (x64), `windows-latest` y `macos-latest` (ARM).
