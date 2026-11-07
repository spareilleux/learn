---
title: "10. Genéricos y colecciones"
description: "Construir una transformación tipada inmediata y comprender las restricciones actuales."
sidebar:
  order: 10
---

## Objetivos de aprendizaje

Leer parámetros de tipo, deducir entrada y salida de una conversión y distinguir genéricos y requisitos de interfaz.

## Reutilizar un algoritmo conservando los tipos

Los [parámetros de tipo](https://go.dev/ref/spec#Type_parameter_declarations) describen una familia de operaciones concretas. Map recibe un slice de T y una conversión de T a U, y devuelve un slice de U. El compilador comprueba el tipo de entrada del callback y sus resultados. No hace falta convertir cada elemento a una interfaz any; quien llama recibe un resultado con tipo estático.

En el comando, T es Record y U es string. La [inferencia](https://go.dev/ref/spec#Type_inference) utiliza el slice y la firma del callback para evitar escribir ambos argumentos. Map reserva la longitud final, asigna una conversión en cada índice y conserva el orden. Es inmediata: todos los callbacks terminan antes de retornar. No es una consulta diferida ni paraleliza el trabajo automáticamente.

## Las restricciones determinan las operaciones

Ambos parámetros usan any porque Map no compara ni suma esos valores. Entrega T al callback y almacena U. Una función que utilice igualdad necesitaría una restricción comparable apropiada; un algoritmo numérico requeriría sus operadores. Una restricción más amplia no es automáticamente más útil si impide las operaciones necesarias. Expresa solo las necesidades reales del algoritmo.

Los tipos definidos y sus tipos subyacentes importan al diseñar restricciones reutilizables. No conviertas Minutes a int solo para satisfacer un auxiliar. La conversión de Map sigue explícita en el callback, permitiendo salidas diferentes sin perder el tipo del dominio en otras partes. La seguridad de tipos no demuestra la regla de negocio del callback: las pruebas siguen comprobando orden, valores y entrada vacía.

## Un auxiliar genérico no hace todo

El resultado tiene almacenamiento propio de slice, pero los valores convertidos pueden contener referencias. Transformar Record en Record no promete una copia profunda. Este contrato tampoco permite que el callback devuelva error. Una conversión que falle necesitaría otra función con resultado y error y una política de resultados parciales. No descartes fallos silenciosamente para conservar una firma cómoda.

[C# Enumerable.Select](https://learn.microsoft.com/dotnet/api/system.linq.enumerable.select) y [Java Stream.map](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/Stream.html#map(java.util.function.Function)) permiten comparar transformaciones de elementos. Sus modelos de ejecución difieren de este auxiliar inmediato. No importes suposiciones de ejecución diferida, invalidación de iteradores o streams paralelos a una función cuya implementación completa es un bucle corto.

## Enseñar el lenguaje actual

Go 1.27 permite métodos concretos con parámetros de tipo propios. Los materiales que prohíben universalmente métodos genéricos están desactualizados. Los métodos de interfaces todavía no pueden declarar parámetros propios ni ser implementados por métodos genéricos. Aquí usamos una función genérica porque una operación sobre slices arbitrarios encaja de forma natural a nivel de paquete, no porque el lenguaje prohíba todas las alternativas.

Usa genéricos cuando necesites el mismo algoritmo tipado para varios tipos. Select sigue siendo específica del dominio y más clara para filtrar duraciones. No hace falta convertir cada auxiliar en un framework de colecciones. Lo importante es una transformación pequeña cuya reserva, orden y momento de evaluación sean visibles.

## Ejemplo explicado

Código completo: [`cmd/l10/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l10/main.go).

```go
package main

import (
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
)

func main() {
	labels := study.Map(study.Fixture(), func(record study.Record) string { return record.Label() })
	fmt.Printf("labels=%v\n", labels)
}
```

Desde la raíz del repositorio:

```sh
cd code/go-for-csharp-java
go run ./cmd/l10
```

**Salida verificada — Go 1.27.1, Windows/amd64.**

```text
labels=[types go]
```

## Leer, predecir y comprobar

Antes de ejecutar el programa, sigue cada valor desde su declaración hasta el resultado mostrado. Anota qué operación valida los datos y cuál solo transforma datos ya tipados. Ejecuta después el comando del repositorio y compara toda la salida, incluido el salto de línea final, con examples.json. Un ejemplo coincidente demuestra este conjunto de datos; las pruebas escritas cubren contratos adicionales. Cambia una sola entrada cada vez, explica la consecuencia y separa el experimento de los datos publicados. Así podrás diagnosticar un resultado inesperado sin cambiar silenciosamente lo que promete la lección.

## Ejercicios

1. ¿Qué son T y U, y cuándo se ejecuta el callback?

<details>
<summary>Solución 1</summary>

T es study.Record y U es string. El callback se ejecuta una vez por cada registro dentro de Map, antes de que main imprima. El orden sigue siendo types y go porque cada resultado mantiene el índice de su entrada. No queda ninguna enumeración diferida pendiente tras el retorno.

</details>

2. ¿any permite sumar dos valores T?

<details>
<summary>Solución 2</summary>

No. La restricción no garantiza suma. La implementación tampoco la necesita: solo entrega valores al callback y almacena resultados. Un algoritmo numérico exigiría una restricción adecuada. Mantén esta función pequeña en lugar de debilitar los tipos mediante aserciones o inventar aritmética para valores arbitrarios.

</details>

## Fuentes oficiales

- [Parámetros de tipo](https://go.dev/ref/spec#Type_parameter_declarations)
- [Inferencia de tipos](https://go.dev/ref/spec#Type_inference)
- [Métodos genéricos de Go 1.27](https://go.dev/doc/go1.27#language)

[Siguiente lección](../11-goroutines-and-channels/) · [Diario](../journal/)
