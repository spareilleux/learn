---
title: "6. Punteros y métodos"
description: "Elegir receptores según la mutación y el contrato de conjuntos de métodos."
sidebar:
  order: 6
---

## Objetivos de aprendizaje

Seguir un registro copiado, explicar la toma implícita de dirección y distinguir mutación e identidad compartida.

## Un puntero identifica almacenamiento

Un [puntero](https://go.dev/ref/spec#Pointer_types) contiene la dirección de una variable o es nil. Tomar una dirección y desreferenciarla son operaciones del lenguaje. Go administra las vidas de objetos normales mediante recolección de basura; devolver un puntero a una variable local no requiere reservar y liberar manualmente memoria. Eso no elimina las preguntas de propiedad. Un puntero permite alcanzar el mismo objeto mutable, haciendo visibles los cambios entre quienes lo comparten.

El programa copia primero un Record en copy. Como sus campos son un string y Minutes, los registros pueden modificarse independientemente. copy.Add cambia la copia de quince a veinte. record.Add cambia la otra variable local de quince a veinticinco. Mostramos ambos valores para distinguir la copia de una estructura de pasar su dirección a un método. La llamada no realiza ninguna copia profunda oculta.

## Elegir la promesa del receptor

Un [método](https://go.dev/ref/spec#Method_declarations) es una función asociada a un tipo receptor. Label tiene receptor valor porque solo lee un campo. Add tiene receptor puntero porque actualiza el Record señalado. El receptor sigue pasando por valor: copiar un puntero conserva acceso a su destino. Un receptor valor recibe una copia del registro y no puede reemplazar los campos de quien llama asignando los propios.

Para una variable local direccionable, Go puede tomar implícitamente su dirección al llamar a un método con receptor puntero. Esa comodidad no significa que el tipo valor tenga todos los métodos en cualquier contexto. Los conjuntos de métodos determinan la satisfacción de interfaces, tema de la siguiente lección. Distingue también un puntero nil de un Record cero: este último tiene campos accesibles; desreferenciar el primero es inválido, salvo que el método trate nil expresamente sin acceder a sus campos.

## Comparar los modelos conocidos

La copia de un [struct C#](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/struct) sirve como comparación inicial; las referencias Java ayudan a imaginar almacenamiento compartido intencionalmente. Ninguna analogía define Go por completo. No existe una clase base universal y declarar un método no exige una jerarquía. Un receptor puntero tampoco obliga al compilador a colocar el valor en el heap; el análisis de escape y la implementación deciden su ubicación.

No elijas punteros solo porque un registro parezca grande, sin medir ni considerar coherencia. La mutación ya justifica Add. Mezclar estilos de receptor debe expresar un contrato claro, especialmente con interfaces. Recibir la estructura exterior por valor no independiza automáticamente posibles campos mutables anidados. La regla de copia superficial de los slices sigue siendo válida.

## Dar una frontera comprensible

El proyecto final lee entradas inmutables y produce valores seleccionados: no necesita compartir cada registro mediante un puntero. Add es un ejemplo concreto, no una razón para reorganizar todo alrededor de la identidad. Al leer el código, identifica qué variable es direccionable y qué almacenamiento cambia cada llamada. Ese seguimiento concreto es más fiable que decir que Go pasa objetos por referencia. Todo pasa por valor; algunos valores se refieren deliberadamente a almacenamiento compartido.

## Ejemplo explicado

Código completo: [`cmd/l06/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l06/main.go).

```go
package main

import (
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
)

func main() {
	record := study.Fixture()[0]
	copy := record
	copy.Add(5)
	record.Add(10)
	fmt.Printf("record=%d copy=%d\n", record.Minutes, copy.Minutes)
}
```

Desde la raíz del repositorio:

```sh
cd code/go-for-csharp-java
go run ./cmd/l06
```

**Salida verificada — Go 1.27.1, Windows/amd64.**

```text
record=25 copy=20
```

## Leer, predecir y comprobar

Antes de ejecutar el programa, sigue cada valor desde su declaración hasta el resultado mostrado. Anota qué operación valida los datos y cuál solo transforma datos ya tipados. Ejecuta después el comando del repositorio y compara toda la salida, incluido el salto de línea final, con examples.json. Un ejemplo coincidente demuestra este conjunto de datos; las pruebas escritas cubren contratos adicionales. Cambia una sola entrada cada vez, explica la consecuencia y separa el experimento de los datos publicados. Así podrás diagnosticar un resultado inesperado sin cambiar silenciosamente lo que promete la lección.

## Ejercicios

1. Si copy.Add recibe cinco otra vez, ¿cambia record?

<details>
<summary>Solución 1</summary>

No. Tras la asignación, copy y record son variables de estructura diferentes. La segunda llamada señala copy y aumenta su duración de veinte a veinticinco. record conserva veinticinco tras su propia modificación. Tener números finales iguales no demostraría identidad compartida: serían resultados independientes de mutaciones distintas.

</details>

2. ¿Qué receptor debe usar Label y por qué es diferente Add?

<details>
<summary>Solución 2</summary>

Label puede recibir un valor porque lee un campo y no modifica almacenamiento del llamador. Add necesita un puntero para actualizar el registro de destino. Las declaraciones del repositorio implementan esa distinción. Una interfaz que requiere Label admite valores y punteros según sus conjuntos de métodos; la mutación es otro requisito.

</details>

## Fuentes oficiales

- [Tipos puntero](https://go.dev/ref/spec#Pointer_types)
- [Declaraciones de métodos](https://go.dev/ref/spec#Method_declarations)
- [Conjuntos de métodos](https://go.dev/ref/spec#Method_sets)

[Siguiente lección](../07-interfaces-and-composition/) · [Diario](../journal/)
