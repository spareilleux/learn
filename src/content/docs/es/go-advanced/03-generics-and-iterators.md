---
title: "3. Genéricos e iteradores"
description: "Implementar una transformación genérica perezosa que se detenga con su consumidor."
sidebar:
  order: 3
---

## Objetivo de aprendizaje

Implementar una transformación genérica perezosa que se detenga con su consumidor.

## Mecanismos y modelos de C#/Java

El paquete [iter](https://pkg.go.dev/iter) nombra las formas de funciones iteradoras. Seq recibe una función yield; devolver false significa que el consumidor ha terminado. Map transforma un valor cada vez y retorna inmediatamente cuando yield devuelve false. Nada se materializa antes de que el consumidor solicite valores. La orden usa slices.Collect para materializar deliberadamente el resultado. Separar estas decisiones permite elegir entre procesamiento secuencial, salida anticipada y colección completa.

A diferencia de un pipeline [Stream](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/Stream.html) de Java, el iterador es un valor de función ordinario con una convención documentada. A diferencia de un bloque iterador de C#, su tipo público es una secuencia con callback y no un objeto [IEnumerator](https://learn.microsoft.com/dotnet/api/system.collections.ienumerator). Las analogías explican la evaluación perezosa, pero no sustituyen el contrato de yield. Volver a llamarlo después de que devuelva false incumple ese contrato. Crear una goroutine en cada iterador añadiría innecesariamente problemas de cancelación y duración que no tiene el callback síncrono.

Map tiene dos parámetros de tipo porque la salida puede tener un tipo diferente de la entrada. any expresa que no se necesita ninguna operación sobre el valor salvo pasarlo a la función proporcionada. comparable añadiría una capacidad de igualdad que esta transformación no utiliza. Las restricciones con términos de tipo subyacente describen conjuntos de tipos admitidos; no son sumas de valores ordinarios en ejecución. Distinga las interfaces de comportamiento de las restricciones aunque compartan parte de su sintaxis.

El curso utiliza Go 1.27. Sus notas incorporan métodos genéricos, por lo que la antigua afirmación de que ningún método puede introducir parámetros de tipo está obsoleta para esta versión. Los métodos de interfaz siguen sin poder introducir sus propios parámetros. Aquí se usa una función genérica de paquete porque transformar no requiere estado de un receptor. La prueba de salida anticipada cuenta las transformaciones y se interrumpe tras el primer resultado; comprobar solo una lista completa no detectaría trabajo sobrante después de detenerse.

## Ejemplo completo ejecutable

El ejecutable pertenece al módulo independiente `example.com/learn/go-advanced`. Su orden llama a paquetes reutilizables en vez de contener por sí sola todo el comportamiento. Lea primero el paquete y siga después sus llamadas desde la orden. Se muestran archivos versionados completos para mantener visibles importaciones, errores y liberación de recursos. No hace falta estado oculto de notebook ni servicios externos. Las órdenes utilizan el mismo directorio y sintaxis en Windows, Linux/WSL y macOS cuando Go está disponible en PATH.

### Código reutilizable

[collection/sequence.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/collection/sequence.go)

```go
package collection

import "iter"

func Map[A, B any](input iter.Seq[A], f func(A) B) iter.Seq[B] {
	return func(yield func(B) bool) {
		for value := range input {
			if !yield(f(value)) {
				return
			}
		}
	}
}

func Reverse(s string) string {
	r := []rune(s)
	for i, j := 0, len(r)-1; i < j; i, j = i+1, j-1 {
		r[i], r[j] = r[j], r[i]
	}
	return string(r)
}
```

[cmd/l03/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l03/main.go)

```go
package main

import (
	"example.com/learn/go-advanced/collection"
	"fmt"
	"slices"
)

func main() {
	values := collection.Map(slices.Values([]int{1, 2, 3}), func(v int) int { return v * 2 })
	fmt.Println(slices.Collect(values))
}
```

Desde la raíz del repositorio:

```sh
cd code/go-advanced
go run ./cmd/l03
```

### Contrato de salida esperado

```text
[2 4 6]
```

## Leer el contrato antes de cambiar el código

Antes de ejecutar, prediga el resultado e identifique la operación que vuelve observable cada valor. Siga la entrada desde el consumidor, pasando por copias y referencias, hasta su destino. Distinga el valor devuelto por una función de la duración de cualquier trabajo que lance. Cuando haya un error posible, identifique quién decide detenerse, reintentar o traducirlo. Imprimir un valor correcto solo cubre parte del contrato: también deben entenderse las entradas rechazadas y la terminación.

El listado es completo deliberadamente. Compárelo con su archivo de pruebas y nombre la aserción exacta que fallaría si cambiase el comportamiento. Una modificación exclusivamente interna debería conservar esas aserciones observables. Si cambia una frontera pública, describa la garantía modificada antes de editar. Este hábito se traslada bien desde C# y Java mientras mantiene explícitas las reglas de propiedad y sincronización de Go.

## Verificación y alcance

La salida mostrada constituye el contrato esperado del ejecutable, almacenado en `examples.json`. Reprodúzcala antes de considerarla una observación de su máquina. Las pruebas están escritas en el mismo módulo y la verificación central registra su ejecución real por separado. Ejemplos correctos no demuestran todos los sistemas operativos, cargas de producción o resultados de aprendizaje. Diagnósticos, perfiles y benchmarks describen experimentos hasta que el diario registre una medición. Conserve juntos versión, revisión y orden: una observación sin condiciones resulta difícil de reproducir.

## Ejercicios

1. ¿Por qué debe retornar Map inmediatamente cuando yield devuelve false?

<details>
<summary>Solución completa</summary>

El consumidor ha terminado. Retornar propaga la decisión hacia el origen y evita callbacks, trabajo y retención adicionales. TestMapStops exige exactamente una transformación después de un break inmediato.

</details>

2. ¿Mejoraría comparable la firma de Map?

<details>
<summary>Solución completa</summary>

No se necesita igualdad; rechazaría entradas útiles sin demostrar nada que el cuerpo necesite. Mantenga any y añada una restricción más fuerte solo cuando una operación la requiera.

</details>

## Fuentes primarias

- [Notas de versión de Go 1.27](https://go.dev/doc/go1.27)
- [iter](https://pkg.go.dev/iter)
- [slices](https://pkg.go.dev/slices)

[Lección siguiente](../04-error-contracts-and-typed-nil/) · [Diario de aprendizaje](../journal/)
