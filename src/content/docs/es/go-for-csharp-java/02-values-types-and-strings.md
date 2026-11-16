---
title: "2. Valores, tipos y cadenas"
description: "Distinguir bytes, puntos de código Unicode y tipos numéricos definidos."
sidebar:
  order: 2
---

## Objetivos de aprendizaje

Predecir valores cero y conversiones, explicar los recuentos de bytes y runas y asignar un tipo propio a los minutos.

## Valores con representación explícita

El [sistema de tipos](https://go.dev/ref/spec#Types) de Go distingue la representación de un valor de las operaciones que su tipo permite. Una variable declarada sin inicializador recibe el valor cero del tipo: cero para números, false para booleanos y una cadena vacía para strings. Son valores inicializados. Un valor cero útil reduce la preparación, pero no sustituye una regla de dominio. Un nombre de estudio vacío sigue siendo inválido en nuestro registro aunque sea una cadena Go válida.

Un int es un entero con signo cuyo tamaño depende de la arquitectura de destino. Úsalo para índices y cantidades habituales; elige un entero de tamaño explícito cuando lo exija un formato binario. Los tipos numéricos generalmente no se mezclan mediante ampliaciones automáticas. Una conversión explícita señala la frontera deseada, pero no demuestra que el valor quepa. Las constantes sin tipo tienen reglas especiales de representabilidad: un literal puede inicializar Minutes sin que cualquier variable int pueda asignarse directamente.

## Un nombre puede expresar una diferencia de dominio

La declaración de Minutes crea un tipo definido cuyo tipo subyacente es int. No es un alias. Permite adjuntar Double y evita mezclar accidentalmente minutos con otro tipo numérico definido. La aritmética sigue siendo numérica: nombrar el tipo no prohíbe automáticamente valores negativos ni desbordamientos. Load impondrá después la regla de entradas no negativas. La distinción estática y la validación resuelven familias distintas de errores.

La declaración corta deduce el tipo de la variable a partir del inicializador. No crea un valor de tipo dinámico. Las reasignaciones siguen respetando las reglas de tipos. Dentro de otro ámbito, una declaración corta también puede ocultar una variable exterior, algo fácil de pasar por alto al comprobar errores. Lee el lugar de declaración, no solo el identificador. Mostrar el número con un formato decimal no cambia su tipo ni añade validación.

## Una cadena cuenta bytes

Un [string](https://go.dev/ref/spec#String_types) es una secuencia inmutable de bytes, no un array de caracteres. Nuestro literal café ocupa cinco bytes UTF-8 y cuatro puntos de código Unicode. [`len`](https://pkg.go.dev/builtin#len) cuenta bytes; [utf8.RuneCountInString](https://pkg.go.dev/unicode/utf8#RuneCountInString) cuenta puntos de código. rune es un alias de int32 utilizado para representar un punto de código. Ningún recuento mide necesariamente los caracteres que percibe una persona: las marcas combinantes y los emoji unidos requieren otro modelo.

Indexar una cadena obtiene un byte. Un bucle range decodifica UTF-8 y entrega posiciones en bytes y valores rune. Cortar en una posición arbitraria puede dividir la codificación de un carácter. Las cadenas Go pueden contener UTF-8 inválido: su validez es un contrato de entrada. Nuestro lector JSON lo comprueba expresamente. No normalices ni recortes nombres silenciosamente si tu aplicación no exige esa política; bytes, puntos de código e identidades de dominio responden a preguntas diferentes.

## Venir de C# o Java

Las API de [string en C#](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/reference-types#the-string-type) y [String en Java](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/String.html) están orientadas a UTF-16. Trasladar una suposición sobre el número de caracteres cambia su significado. La igualdad de strings en Go compara bytes: formas compuestas y descompuestas visualmente iguales pueden ser distintas. El comando demuestra tres propiedades separadas: cinco bytes, cuatro runas y veinte minutos duplicados. Localiza después la declaración del tipo en el paquete compartido.

## Ejemplo explicado

Código completo: [`cmd/l02/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l02/main.go).

```go
package main

import (
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
	"unicode/utf8"
)

func main() {
	name := "café"
	minutes := study.Minutes(20)
	fmt.Printf("bytes=%d runes=%d double=%d\n", len(name), utf8.RuneCountInString(name), minutes.Double())
}
```

Desde la raíz del repositorio:

```sh
cd code/go-for-csharp-java
go run ./cmd/l02
```

**Salida verificada — Go 1.27.1, Windows/amd64.**

```text
bytes=5 runes=4 double=40
```

## Leer, predecir y comprobar

Antes de ejecutar el programa, sigue cada valor desde su declaración hasta el resultado mostrado. Anota qué operación valida los datos y cuál solo transforma datos ya tipados. Ejecuta después el comando del repositorio y compara toda la salida, incluido el salto de línea final, con examples.json. Un ejemplo coincidente demuestra este conjunto de datos; las pruebas escritas cubren contratos adicionales. Cambia una sola entrada cada vez, explica la consecuencia y separa el experimento de los datos publicados. Así podrás diagnosticar un resultado inesperado sin cambiar silenciosamente lo que promete la lección.

## Ejercicios

1. ¿Qué cambia si el nombre pasa a ser el string ASCII go?

<details>
<summary>Solución 1</summary>

La longitud en bytes y el número de runas valen dos, porque cada punto de código ASCII ocupa un byte UTF-8. El resultado numérico sigue siendo cuarenta: la cadena no interviene en el cálculo. Cambiar el texto no modifica el tipo de minutes ni el receptor de Double.

</details>

2. ¿Convertir un int negativo en Minutes valida la duración?

<details>
<summary>Solución 2</summary>

No. La conversión expresa un cambio de tipo numérico; no impone la regla del registro. Load rechaza las duraciones negativas después de decodificarlas. Double multiplica el receptor por dos. Un constructor podría imponer un invariante más fuerte, pero este curso enseña deliberadamente la validación en la frontera existente.

</details>

## Fuentes oficiales

- [Tipos del lenguaje](https://go.dev/ref/spec#Types)
- [Longitud de cadenas](https://go.dev/ref/spec#Length_and_capacity)
- [Recuento de runas UTF-8](https://pkg.go.dev/unicode/utf8#RuneCountInString)

[Siguiente lección](../03-control-flow-and-functions/) · [Diario](../journal/)
