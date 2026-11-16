---
title: "4. Arrays y slices"
description: "Comprender arrays copiados, almacenamiento compartido, append y clonación explícita."
sidebar:
  order: 4
---

## Objetivos de aprendizaje

Dibujar el almacenamiento compartido entre slices, distinguir longitud y capacidad y decidir cuándo basta una copia superficial.

## La colección no siempre es su almacenamiento

Un [array](https://go.dev/ref/spec#Array_types) contiene un número fijo de elementos y su longitud pertenece al tipo. Asignarlo copia esos elementos. Un [slice](https://go.dev/ref/spec#Slice_types), en cambio, describe un segmento de un array subyacente. La longitud es el número de elementos accesibles; la capacidad indica cuánto puede extenderse ese segmento antes de que [`append`](https://pkg.go.dev/builtin#append) necesite otra reserva. Copiar el slice copia la descripción, sin copiar automáticamente los elementos descritos.

Fixture devuelve un nuevo slice de dos valores Record. La expresión que toma su primer elemento como slice crea otra vista del mismo array. Actualizar el primer registro a través de esa vista también modifica el que lee el slice original. En cambio, study.Clone utiliza [slices.Clone](https://pkg.go.dev/slices#Clone), que reserva una secuencia separada. El primer registro independiente conserva quince minutos cuando el original compartido pasa a treinta. Es una cuestión de propiedad del almacenamiento.

## Append puede cambiar el reparto

append devuelve un slice: conserva su resultado. Si queda capacidad puede reutilizar el array; de lo contrario reserva almacenamiento y copia los elementos existentes. No bases la corrección en un factor de crecimiento no documentado. Dos ejemplos parecidos pueden compartir de forma distinta porque sus capacidades difieren. Si necesitas almacenamiento independiente, clona expresamente en lugar de esperar que un append posterior reserve memoria por casualidad.

El slice nil tiene longitud y capacidad cero y admite range y append. Un slice vacío no nil también tiene longitud cero, pero la diferencia puede importar en serialización o contratos de API. El índice debe estar dentro de la longitud aunque exista capacidad sobrante. Amplía una vista mediante slicing solo cuando sea intencional. Pasar un slice copia el descriptor: las modificaciones de elementos compartidos siguen visibles, pero reasignar el descriptor local no cambia la variable de quien llama.

## La profundidad depende del elemento

Record contiene actualmente un string y un valor numérico Minutes. La copia superficial de elementos basta para aislar asignaciones posteriores a esos campos; los strings son inmutables. Si Record incorporase un mapa mutable u otro slice, clonar el slice exterior copiaría sus descriptores manteniendo compartido su almacenamiento. No anuncies Clone como copia profunda universal. Su garantía depende del modelo actual y del contrato de la biblioteca estándar.

Los arrays de C# y Java son objetos con referencias: asignar una variable comparte el objeto. En Go la asignación de arrays copia elementos, mientras que asignar slices comparte almacenamiento mediante descriptores copiados. Traducir la palabra array no basta para trasladar una intuición. Pregunta qué tipo tiene realmente la declaración. Un slice tampoco es un objeto ampliable con todos los métodos de tus colecciones habituales; las operaciones básicas se expresan mediante funciones y elementos del lenguaje.

## Diagnosticar antes de corregir

Sigue los tres nombres del ejemplo. original y alias alcanzan el mismo primer registro; detached llega a otro registro. La modificación pasa por alias, pero la salida lee original y detached para hacer observable la relación. La prueba escrita verifica ambos lados: fallaría si se eliminase accidentalmente el alias o si la copia siguiera compartiendo. Una expresión completa de slice puede limitar la capacidad y condicionar la reutilización por append, pero no aísla escrituras en elementos existentes. Clone es la operación adecuada cuando necesitas esa independencia.

## Ejemplo explicado

Código completo: [`cmd/l04/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l04/main.go).

```go
package main

import (
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
)

func main() {
	original := study.Fixture()
	alias := original[:1]
	detached := study.Clone(alias)
	alias[0].Minutes = 30
	fmt.Printf("original=%d clone=%d\n", original[0].Minutes, detached[0].Minutes)
}
```

Desde la raíz del repositorio:

```sh
cd code/go-for-csharp-java
go run ./cmd/l04
```

**Salida verificada — Go 1.27.1, Windows/amd64.**

```text
original=30 clone=15
```

## Leer, predecir y comprobar

Antes de ejecutar el programa, sigue cada valor desde su declaración hasta el resultado mostrado. Anota qué operación valida los datos y cuál solo transforma datos ya tipados. Ejecuta después el comando del repositorio y compara toda la salida, incluido el salto de línea final, con examples.json. Un ejemplo coincidente demuestra este conjunto de datos; las pruebas escritas cubren contratos adicionales. Cambia una sola entrada cada vez, explica la consecuencia y separa el experimento de los datos publicados. Así podrás diagnosticar un resultado inesperado sin cambiar silenciosamente lo que promete la lección.

## Ejercicios

1. ¿Por qué original contiene treinta y clone quince?

<details>
<summary>Solución 1</summary>

alias apunta al primer elemento del mismo array que original; asignar treinta por alias cambia lo que original lee. Clone había copiado ese elemento antes de la asignación. Su array separado sigue conteniendo quince. Si inviertes el orden de copia y asignación, la copia contendría treinta.

</details>

2. ¿Clonar aislaría un campo mapa añadido a Record?

<details>
<summary>Solución 2</summary>

No. La clonación superficial copia el valor mapa, que continúa refiriéndose al mismo almacenamiento. Conserva el modelo actual con campos inmutables o define y prueba una copia más profunda para el campo nuevo. Limitar la capacidad del slice tampoco aislaría entradas del mapa ni elementos existentes.

</details>

## Fuentes oficiales

- [Tipos array](https://go.dev/ref/spec#Array_types)
- [Tipos slice](https://go.dev/ref/spec#Slice_types)
- [slices.Clone](https://pkg.go.dev/slices#Clone)

[Siguiente lección](../05-maps-and-structs/) · [Diario](../journal/)
