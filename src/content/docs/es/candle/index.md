---
title: Candle, el aprendizaje automático de Hugging Face en Rust — Misión
description: Aprende Candle, el framework de aprendizaje automático de Hugging Face en Rust, desde sus tensores hasta servir modelos — tensores, rendimiento en CPU, autodiff, candle-nn, safetensors y el Hub, transformers, LLM cuantizados, despliegue e interoperabilidad con C# y Java —, con cada salida impresa por código fijado y compilado.
sidebar:
  label: Misión
  order: 0
---

:::note[Cómo se prueba este curso]
Cada resultado de este curso lo imprime un programa en [`code/candle`](https://github.com/spareilleux/learn/tree/main/code/candle): un workspace de Cargo que depende de `candle-core` y `candle-nn` **0.11.0**, fijados con `=`, solo en CPU. `check.sh` ejecuta `cargo fmt`, `clippy`, las pruebas (con un doctest `compile_fail` por cada fragmento que una lección muestra rechazado) y cada ejemplo, y compara cada salida con el archivo de `expected/`. Las salidas de las lecciones se capturaron con Rust 1.94.0 en Windows 11 en septiembre de 2026, y `check.sh` dio las mismas salidas en Linux, en un contenedor `rust:1.94.0`. Un workflow, `candle-examples.yml`, ejecuta el mismo script en Linux, Windows y macOS; todavía no está en GitHub, así que macOS queda *por verificar*.
:::

## Por qué aprendo esto

El [curso de IX](../machine-learning-ix/) escribió algoritmos de aprendizaje automático a mano en Rust, y el [curso de IA de GA](../ga-ai/) siguió embeddings calculados en C# por ONNX Runtime. Entre los dos está la pregunta que responde este curso: ¿puede un programa en Rust cargar un modelo publicado, ejecutarlo e incluso entrenar uno pequeño, sin Python y sin un runtime nativo al lado?

[Candle](https://github.com/huggingface/candle) es la respuesta de Hugging Face. Es una biblioteca de tensores con diferenciación automática, un conjunto de capas e implementaciones de modelos conocidos, de BERT a LLM cuantizados, todo compilado dentro de tu binario. Quiero saber qué hace bajo los tensores, cuánto cuesta en una CPU, dónde están sus límites y cómo lo usaría un servicio en C# o Java.

## Para quién es este curso

Escribes C# o Java, y conoces lo básico de Rust por el [curso de Rust](../rust-for-csharp-java/): ownership, `Result` y `?`, traits, Cargo. Conoces las nociones de aprendizaje automático del [curso de IX](../machine-learning-ix/): una pérdida, un gradiente, el descenso de gradiente, los conjuntos de entrenamiento y de prueba. Este curso no las vuelve a explicar; enlaza a ellas.

No necesitas Python ni PyTorch. Cuando la forma de PyTorch de hacer algo ayuda, la lección la muestra junto a la de Candle, ya que la mayor parte del código de modelos que leerás está escrito con él.

## Candle, TorchSharp y DJL en una tabla

| | TorchSharp (C#) | DJL (Java) | Candle (Rust) |
|---|---|---|---|
| Un tensor | `torch.Tensor`, sobre libtorch | `NDArray`, sobre el motor que elijas | `candle_core::Tensor`, Rust puro en la CPU |
| Un error | una excepción | una excepción | un `Result` de cada operación |
| Broadcasting | implícito | implícito | explícito: `broadcast_add` |
| Gradientes | `requires_grad`, `.grad` se acumula | `GradientCollector` | `Var`, `backward` devuelve un `GradStore` nuevo |
| Archivos de modelo | su propio formato, y TorchScript | el formato del motor | `safetensors`, GGUF |
| Lo que despliegas | una app .NET más los paquetes de libtorch | una app JVM más las bibliotecas nativas del motor | un binario, o un módulo WebAssembly |

Fuentes: [README de TorchSharp](https://github.com/dotnet/TorchSharp/blob/8f4def03b641b6753f18076aa5438f8eaaef2d30/README.md), [README de DJL](https://github.com/deepjavalibrary/djl/blob/f3782179ff48a1bd31382667dbfae1f568891a55/README.md), [README de Candle](https://github.com/huggingface/candle/blob/31f35b147389700ed2a178ee66a91c3cc25cc80d/README.md), y las lecciones 1 a 4 para la columna de Candle.

## Candle, fijado

El curso usa la última versión de crates.io, [**0.11.0**](https://crates.io/crates/candle-core/0.11.0), publicada el 26 de junio de 2026. Sus fuentes son la etiqueta `0.11.0`, commit [`31f35b1`](https://github.com/huggingface/candle/tree/31f35b147389700ed2a178ee66a91c3cc25cc80d), y cada enlace al código de Candle apunta ahí, para que los números de línea sigan siendo correctos cuando `main` avance. [`Cargo.toml`](https://github.com/spareilleux/learn/blob/c45b150/code/candle/Cargo.toml) fija los crates:

```toml
[workspace.dependencies]
candle-core = "=0.11.0"
candle-nn = "=0.11.0"
```

Cuando `main` ya ha corregido algo con lo que se topan las lecciones, lo dicen, con el commit.

## Al final de este curso, sabré

- crear, cambiar de forma, indexar y combinar tensores, y leer los errores en tiempo de ejecución de Candle;
- distinguir una vista de una copia, y medir y ajustar lo que cuesta una operación en una CPU;
- calcular gradientes con `Var` y `backward`, comprobarlos y entrenar un modelo con ellos;
- construir y entrenar una red con `candle-nn`, y guardar y cargar sus pesos con `safetensors`;
- descargar un modelo del Hugging Face Hub en una revisión fijada, calcular embeddings y ejecutar un LLM cuantizado;
- servir un modelo por HTTP, en un contenedor y en el navegador, y llamarlo desde C# y Java;
- portar un modelo pequeño de PyTorch a Candle y comprobar que ambos dan las mismas salidas.

## Plan

| # | Lección | Si conoces PyTorch |
|---|---|---|
| 1 | [Por qué Candle](01-why-candle/) | `pip install torch`, `torch.cuda.is_available()` |
| 2 | [Tensores](02-tensors/) | `torch.tensor`, `view`, indexación, broadcasting |
| 3 | [Cálculo y rendimiento en CPU](03-cpu-performance/) | `contiguous()`, `torch.set_num_threads` |
| 4 | [Diferenciación automática](04-autodiff/) | `requires_grad`, `backward()`, `.grad` |
| 5 | `candle-nn`: módulos, capas, optimizadores, una red pequeña entrenada con un conjunto de datos público | `nn.Module`, `nn.Linear`, `torch.optim` |
| 6 | Formatos y el Hub: `safetensors`, `VarBuilder`, `hf-hub`, la caché, las licencias de los modelos | `torch.load`, `from_pretrained` |
| 7 | Transformers en inferencia: un modelo de embeddings, tokenizadores, similitud, comparado con los embeddings de GA | `transformers.AutoModel` |
| 8 | LLM cuantizados: GGUF, tensores cuantizados, un modelo pequeño, muestreo | `llama.cpp`, `bitsandbytes` |
| 9 | GPU: las features CUDA y Metal, en teoría, *por verificar* | `.to("cuda")` |
| 10 | Despliegue: un servicio HTTP con axum, un único binario, un contenedor, WebAssembly en el navegador | TorchServe |
| 11 | Interoperabilidad: llamar a un modelo de Candle desde C# y desde Java | TorchSharp, DJL |
| 12 | Escribir tu propio modelo: portar un modelo pequeño de PyTorch y comparar las salidas | — |
| — | [Diario](journal/) | |

Las lecciones 5 a 12 son el plan; cambiarán a medida que las primeras me enseñen lo que importa. La lección 9 se queda en teoría porque la GPU de la máquina en la que se escribe este curso está reservada para otro trabajo.

## Recursos

- [Candle en `31f35b1`](https://github.com/huggingface/candle/tree/31f35b147389700ed2a178ee66a91c3cc25cc80d), sus [ejemplos](https://github.com/huggingface/candle/tree/31f35b147389700ed2a178ee66a91c3cc25cc80d/candle-examples/examples) y el [libro de Candle](https://huggingface.github.io/candle/)
- En docs.rs: [`candle-core`](https://docs.rs/candle-core/0.11.0/candle_core/), [`candle-nn`](https://docs.rs/candle-nn/0.11.0/candle_nn/), [`candle-transformers`](https://docs.rs/candle-transformers/0.11.0/candle_transformers/)
- [Documentación del Hugging Face Hub](https://huggingface.co/docs/hub/index) y [`safetensors`](https://huggingface.co/docs/safetensors)
- [Documentación de PyTorch](https://docs.pytorch.org/docs/stable/index.html), la referencia contra la que está escrito la mayor parte del código de modelos
- El [curso de Rust](../rust-for-csharp-java/) y el [curso de IX](../machine-learning-ix/), los requisitos previos de este curso
