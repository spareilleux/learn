---
title: "10. Pruebas de carreras, fuzzing y propiedades"
description: "Convertir una ley de comportamiento en una prueba de fuzz con semillas sin exagerar su cobertura."
sidebar:
  order: 10
---

## Objetivo de aprendizaje

Convertir una ley de comportamiento en una prueba de fuzz con semillas sin exagerar su cobertura.

## Mecanismos y modelos de C#/Java

El [detector de carreras](https://go.dev/doc/articles/race_detector) instrumenta accesos del programa que realmente se ejecuta. Un resultado correcto dice que no se observaron carreras en esas ejecuciones; no demuestra estáticamente todos los órdenes posibles. Ejercite caminos concurrentes relevantes, incluidos cancelación y vaciado, en lugar de limitarse al éxito secuencial. Ejecute go test -race ./... en un entorno compatible y registre su resultado real. Una prueba con carrera sigue siendo incorrecta aunque imprima por casualidad el valor esperado.

El [tutorial de fuzzing](https://go.dev/doc/tutorial/fuzz) distingue ejecutar semillas de generar entradas activamente. go test ordinario ejecuta el corpus inicial. Una orden con -fuzz busca entradas nuevas y puede guardar fallos minimizados. FuzzReverse aporta vacío, ASCII, acentos y emoji. Comprueba una ley: invertir dos veces una cadena UTF-8 válida devuelve el original. Las secuencias arbitrarias de bytes no siempre son UTF-8 válidas; convertir bytes inválidos a runas los normaliza. Restringir el dominio es parte del contrato.

La prueba de propiedades usa testing/quick para generar valores de la misma ley. La prueba de tramas comprueba el recorrido de ida y vuelta de bytes limitados; la tabla de tramas malformadas prueba rechazos conocidos. Una ida y vuelta puede ocultar dos errores compatibles, como codificador y decodificador usando juntos el orden de bytes equivocado. Por eso hacen falta expectativas explícitas sobre cabeceras y longitudes inválidas. Combine leyes y ejemplos concretos: ninguno reemplaza comprender el contrato del protocolo.

Los frameworks de C# y Java pueden expresar las mismas propiedades, pero Go reconoce objetivos fuzz mediante su herramienta estándar y una firma obligatoria. Mantenga el objetivo determinista respecto a su entrada y sin servicios externos. Un fallo solo sirve si puede conservarse y reproducirse su entrada. Semillas, búsqueda activa, instrumentación de carreras y cobertura de sistemas son evidencias distintas. El diario deja inicialmente pendientes la búsqueda activa y la detección de carreras; no inventa cantidades de casos generados ni errores descubiertos.

## Ejemplo completo ejecutable

El ejecutable pertenece al módulo independiente `example.com/learn/go-advanced`. Su orden llama a paquetes reutilizables en vez de contener por sí sola todo el comportamiento. Lea primero el paquete y siga después sus llamadas desde la orden. Se muestran archivos versionados completos para mantener visibles importaciones, errores y liberación de recursos. No hace falta estado oculto de notebook ni servicios externos. Las órdenes utilizan el mismo directorio y sintaxis en Windows, Linux/WSL y macOS cuando Go está disponible en PATH.

### Código reutilizable

[collection/sequence_test.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/collection/sequence_test.go)

```go
package collection

import (
	"slices"
	"testing"
	"testing/quick"
	"unicode/utf8"
)

func TestMapStops(t *testing.T) {
	calls := 0
	for v := range Map(slices.Values([]int{1, 2, 3}), func(v int) int { calls++; return v * 2 }) {
		if v != 2 {
			t.Fatal(v)
		}
		break
	}
	if calls != 1 {
		t.Fatalf("iterator ignored stop: %d", calls)
	}
}
func TestReverseProperty(t *testing.T) {
	property := func(s string) bool { return !utf8.ValidString(s) || Reverse(Reverse(s)) == s }
	if err := quick.Check(property, nil); err != nil {
		t.Fatal(err)
	}
}
func FuzzReverse(f *testing.F) {
	for _, seed := range []string{"", "abc", "été", "🙂x"} {
		f.Add(seed)
	}
	f.Fuzz(func(t *testing.T, s string) {
		if !utf8.ValidString(s) {
			t.Skip()
		}
		if Reverse(Reverse(s)) != s {
			t.Fatal("involution")
		}
	})
}
```

[cmd/l10/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l10/main.go)

```go
package main

import (
	"example.com/learn/go-advanced/collection"
	"fmt"
)

func main() {
	text := "été Go"
	fmt.Println(collection.Reverse(text))
	fmt.Println(collection.Reverse(collection.Reverse(text)) == text)
}
```

Desde la raíz del repositorio:

```sh
cd code/go-advanced
go run ./cmd/l10
```

### Contrato de salida esperado

```text
oG été
true
```

## Leer el contrato antes de cambiar el código

Antes de ejecutar, prediga el resultado e identifique la operación que vuelve observable cada valor. Siga la entrada desde el consumidor, pasando por copias y referencias, hasta su destino. Distinga el valor devuelto por una función de la duración de cualquier trabajo que lance. Cuando haya un error posible, identifique quién decide detenerse, reintentar o traducirlo. Imprimir un valor correcto solo cubre parte del contrato: también deben entenderse las entradas rechazadas y la terminación.

El listado es completo deliberadamente. Compárelo con su archivo de pruebas y nombre la aserción exacta que fallaría si cambiase el comportamiento. Una modificación exclusivamente interna debería conservar esas aserciones observables. Si cambia una frontera pública, describa la garantía modificada antes de editar. Este hábito se traslada bien desde C# y Java mientras mantiene explícitas las reglas de propiedad y sincronización de Go.

## Verificación y alcance

La salida mostrada constituye el contrato esperado del ejecutable, almacenado en `examples.json`. Reprodúzcala antes de considerarla una observación de su máquina. Las pruebas están escritas en el mismo módulo y la verificación central registra su ejecución real por separado. Ejemplos correctos no demuestran todos los sistemas operativos, cargas de producción o resultados de aprendizaje. Diagnósticos, perfiles y benchmarks describen experimentos hasta que el diario registre una medición. Conserve juntos versión, revisión y orden: una observación sin condiciones resulta difícil de reproducir.

## Ejercicios

1. ¿Por qué omitir UTF-8 inválido en la prueba de involución?

<details>
<summary>Solución completa</summary>

La implementación invierte runas, no bytes crudos. La decodificación reemplaza secuencias inválidas, impidiendo reconstruir siempre los bytes originales. Restrinja esa propiedad al texto válido y use las tramas para bytes arbitrarios.

</details>

2. ¿Un go test correcto demuestra que hubo fuzzing activo?

<details>
<summary>Solución completa</summary>

No. Ejecuta las semillas. La búsqueda activa requiere una orden explícita y registrar por separado duración y resultado. Distinga además evidencia de carreras y pruebas ordinarias.

</details>

## Fuentes primarias

- [Detector de carreras](https://go.dev/doc/articles/race_detector)
- [Tutorial de fuzzing](https://go.dev/doc/tutorial/fuzz)
- [testing/quick](https://pkg.go.dev/testing/quick)

[Lección siguiente](../11-benchmarks-pprof-and-trace/) · [Diario de aprendizaje](../journal/)
