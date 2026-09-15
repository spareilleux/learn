---
title: Aprendizaje automático, aplicado en IX — Misión
description: Aprende aprendizaje automático desde el álgebra — dividir y puntuar, regresión lineal y descenso de gradiente, clasificación, agrupamiento — escribiendo cada algoritmo a mano en Rust y luego leyendo y ejecutando el mismo algoritmo en los crates de IX, sobre el historial de CI de este sitio.
sidebar:
  label: Misión
  order: 0
---

:::note[Cómo se prueba este curso]
Cada resultado de este curso lo imprime un programa de [`code/machine-learning-ix`](https://github.com/spareilleux/learn/tree/main/code/machine-learning-ix): un proyecto Cargo que depende de los crates de IX en el commit [`490c395`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2). [`.github/workflows/ml-ix-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/ml-ix-examples.yml) ejecuta `cargo fmt`, `clippy`, las pruebas unitarias y cada ejemplo en Linux, Windows y macOS, y compara cada salida con el archivo de `expected/`. Solo en Linux, el mismo workflow recalcula con [numpy](https://numpy.org/doc/stable/) 2.4.2 y [scikit-learn](https://scikit-learn.org/stable/) 1.8.0 los resultados que no dependen de IX, y también los compara. Las salidas de las lecciones se capturaron con Rust 1.94 en Windows en septiembre de 2026, y son las mismas en los tres sistemas.
:::

## Por qué aprendo esto

[IX](https://github.com/GuitarAlchemist/ix) es un workspace de Rust con algoritmos de aprendizaje automático y de matemáticas que Claude Code puede llamar como herramientas: k-means, árboles de decisión, descenso de gradiente y unos ochenta crates más. Cuando una herramienta responde «3 clusters, silueta 0.50», quiero saber qué se calculó, si es correcto y cómo sería una respuesta mejor.

Mi forma de aprender un algoritmo es escribirlo. Cada lección escribe un algoritmo en unas pocas decenas de líneas, lo ejecuta junto con la versión de IX sobre los mismos datos, y compara ambos hasta el último dígito impreso. Cuando difieren, uno de los dos está mal, y averiguar cuál es donde más aprendo: esta tanda encontró nueve puntos en los que la respuesta de IX, o su documentación, difiere del libro de texto o de scikit-learn, enumerados en el [diario](journal/).

## Para quién es este curso

Escribes C# o Java. Te manejas con el álgebra del bachillerato: una recta `y = w·x + b`, una suma `Σ`, una raíz cuadrada, una derivada. No necesitas saber nada de aprendizaje automático. Tampoco necesitas conocer bien Rust: el código usa bucles, closures y las matrices de [ndarray](https://docs.rs/ndarray/0.17/ndarray/), y el [curso de Rust](../rust-for-csharp-java/) cubre el resto.

Si has usado [ML.NET](https://learn.microsoft.com/dotnet/machine-learning/), [Tribuo](https://tribuo.org/) o [Deeplearning4j](https://deeplearning4j.konduit.ai/), cada lección relaciona lo que sabes con lo que hace IX.

## IX, ML.NET y Tribuo en una tabla

| | ML.NET | Tribuo | IX |
|---|---|---|---|
| Lenguaje | C#, F# | Java | Rust |
| Un conjunto de datos | `IDataView`, columnas tipadas | `Dataset<T>` de `Example<T>` | dos matrices `ndarray`: `Array2<f64>` características, `Array1` etiquetas |
| Un modelo | `IEstimator.Fit` devuelve un `ITransformer` | `Trainer.train` devuelve un `Model` | un struct con `fit` y `predict` (traits `Regressor`, `Classifier`, `Clusterer`) |
| Preprocesamiento | `NormalizeMeanVariance`, ajustado como un modelo | `TransformationMap` | `StandardScaler::fit`, luego `transform` |
| Desde un asistente de IA | — | — | herramientas MCP como `ix_kmeans` e `ix_ml_pipeline` |

Fuentes: [tareas y entrenadores de ML.NET](https://learn.microsoft.com/dotnet/machine-learning/resources/tasks), [clustering en Tribuo](https://tribuo.org/learn/4.3/javadoc/org/tribuo/clustering/package-summary.html), [README de IX](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/README.md).

## Los datos

Ningún conjunto de datos descargado: ambos archivos vienen de este repositorio, y [`data/extract.py`](https://github.com/spareilleux/learn/blob/15cde435d825d3c392307e7c6f9ee2e085d0e2bc/code/machine-learning-ix/data/extract.py) los reconstruye a partir del historial de CI que el [curso de DuckDB](../duckdb/) exportó el 2026-09-14 (`runs.json` y `jobs.json`) y de Git:

- [`builds.csv`](https://github.com/spareilleux/learn/blob/15cde435d825d3c392307e7c6f9ee2e085d0e2bc/code/machine-learning-ix/data/builds.csv), para la regresión: los 65 builds exitosos de este sitio, en orden de commit, con el número de páginas Markdown en ese commit (de 18 a 289) y los segundos del paso que las compila (de 10 a 48). ¿Crece el tiempo de build con el número de páginas?
- [`jobs.csv`](https://github.com/spareilleux/learn/blob/15cde435d825d3c392307e7c6f9ee2e085d0e2bc/code/machine-learning-ix/data/jobs.csv), para la clasificación y el agrupamiento: 186 jobs de CI, cada uno con cinco tiempos en segundos enteros (espera en la cola, preparación del job, checkout del repositorio, limpieza del checkout, finalización del job) y el sistema operativo del runner: 121 Ubuntu, 34 Windows, 31 macOS. ¿Pueden los tiempos decir qué sistema operativo ejecutó un job?

## IX, fijado

El curso usa cinco crates de IX: `ix-math` (estadística, escalado, división), `ix-supervised` (regresión, clasificación, métricas, validación cruzada), `ix-optimize` (descenso de gradiente), `ix-unsupervised` (k-means, DBSCAN, mezclas gaussianas) e `ix-voicings` (el coeficiente de silueta y el agrupamiento de voicings de guitarra). [`Cargo.toml`](https://github.com/spareilleux/learn/blob/15cde435d825d3c392307e7c6f9ee2e085d0e2bc/code/machine-learning-ix/Cargo.toml) los toma de Git, fijados a un commit, como describe la [referencia de Cargo](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html):

```toml
ix-supervised = { git = "https://github.com/GuitarAlchemist/ix", rev = "490c39533627d296bf9f8f050e6fafc14d7a20c2" }
```

Cada enlace a código de IX en las lecciones apunta a ese commit, así que los números de línea siguen siendo correctos cuando IX cambia.

## Al final de este curso, sabré

- dividir los datos para entrenamiento y prueba, elegir una línea base y puntuar un modelo con la métrica que corresponde a la pregunta;
- ajustar una recta de dos maneras, con la forma cerrada y con descenso de gradiente, y explicar por qué el descenso diverge;
- entrenar y comparar la regresión logística, los k vecinos más cercanos y un árbol de decisión, con validación cruzada;
- agrupar datos sin etiquetas con k-means, DBSCAN y una mezcla gaussiana, y juzgar los grupos;
- leer un algoritmo en IX, contrastarlo con una versión escrita a mano y con scikit-learn, y describir una diferencia con precisión.

## Plan

| # | Lección | Si conoces ML.NET |
|---|---|---|
| 1 | [Datos, características y evaluación](01-data-and-evaluation/) | `IDataView`, `TrainTestSplit`, `RegressionMetrics` |
| 2 | [Regresión lineal y descenso de gradiente](02-linear-regression/) | `Ols`, `OnlineGradientDescent` |
| 3 | [Clasificación: regresión logística, k vecinos más cercanos, árboles de decisión](03-classification/) | `LbfgsLogisticRegression`, `FastTree`, `CrossValidate` |
| 4 | [Agrupamiento: k-means, DBSCAN, mezclas gaussianas](04-clustering/) | `KMeansTrainer` |
| — | [Diario](journal/) | |

## Recursos

- [IX en el commit `490c395`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2), y su carpeta [`docs/`](https://github.com/GuitarAlchemist/ix/tree/490c39533627d296bf9f8f050e6fafc14d7a20c2/docs) de tutoriales
- [Guía de usuario de scikit-learn](https://scikit-learn.org/stable/), la referencia que usa la comprobación cruzada, y su página sobre [errores comunes](https://scikit-learn.org/stable/common_pitfalls.html)
- [Documentación de ML.NET](https://learn.microsoft.com/dotnet/machine-learning/) y [documentación de Tribuo](https://tribuo.org/)
- *[An Introduction to Statistical Learning](https://www.statlearning.com/)*, de James, Witten, Hastie, Tibshirani y Taylor: gratuito en línea, el libro detrás de la mayoría de las fórmulas de este curso
- [ndarray](https://docs.rs/ndarray/0.17/ndarray/), el crate de matrices que comparten IX y este curso
