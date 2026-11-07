---
title: "11. Benchmarks, pprof y trace"
description: "Elegir una medición que responda a una pregunta de rendimiento sin inventar tiempos."
sidebar:
  order: 11
---

## Objetivo de aprendizaje

Elegir una medición que responda a una pregunta de rendimiento sin inventar tiempos.

## Mecanismos y modelos de C#/Java

Un [benchmark](https://pkg.go.dev/testing#hdr-Benchmarks) es un experimento sobre una operación y una distribución concreta de entradas. BenchmarkSum construye un segmento fijo antes del bucle medido, informa de asignaciones y guarda el resultado en una variable del paquete. Esa variable hace observable el resultado. El bucle mide sumar, no construir repetidamente su entrada. Este microbenchmark no establece rendimiento HTTP, latencia de cancelación ni capacidad global del servicio.

La orden go test -run=^$ -bench=BenchmarkSum -benchmem ./metrics solicita una medición. Registre compilador, sistema operativo, CPU, revisión, opciones y tamaño junto al resultado. Compare ejecuciones repetidas, no una cifra atractiva. Aquí no se citan ns/op, bytes/op ni allocations/op porque el autor no ha medido esta unidad. Un cambio puede reducir tráfico de asignaciones y conservar más memoria. Vincule la métrica con la pregunta en vez de considerar universalmente mejor cualquier contador menor.

La guía [Diagnósticos](https://go.dev/doc/diagnostics) separa perfiles y trazas. Un perfil CPU muestrea dónde se dedica tiempo; un perfil de memoria ayuda a investigar asignaciones o retención; una traza muestra planificación, bloqueos y eventos del runtime a lo largo del tiempo. Genere un archivo local con go test -run=^$ -bench=BenchmarkSum -cpuprofile=cpu.out ./metrics y examine con go tool pprof -http=127.0.0.1:0 cpu.out. Mantenga la escucha en bucle local. Los perfiles pueden contener rutas y datos sensibles de la carga; aplique la política de datos de la aplicación.

Los hábitos de perfilado de C# y Java sirven para formular preguntas: establecer una referencia, localizar el coste, cambiar una hipótesis y medir otra vez. Go tiene señales y herramientas diferentes. Go 1.27 añade el perfil goroutineleak a runtime/pprof; no detecta todas las fugas lógicas ni todos los trabajadores bloqueados. Siguen haciendo falta señales de finalización y pruebas de vaciado. Trazas, perfiles y detector de carreras también añaden coste: no compare una ejecución instrumentada con otra sin instrumentación atribuyendo toda diferencia al cambio.

## Ejemplo completo ejecutable

El ejecutable pertenece al módulo independiente `example.com/learn/go-advanced`. Su orden llama a paquetes reutilizables en vez de contener por sí sola todo el comportamiento. Lea primero el paquete y siga después sus llamadas desde la orden. Se muestran archivos versionados completos para mantener visibles importaciones, errores y liberación de recursos. No hace falta estado oculto de notebook ni servicios externos. Las órdenes utilizan el mismo directorio y sintaxis en Windows, Linux/WSL y macOS cuando Go está disponible en PATH.

### Código reutilizable

[metrics/sum_test.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/metrics/sum_test.go)

```go
package metrics

import "testing"

var sink int

func TestSum(t *testing.T) {
	if Sum([]int{2, 3, 4}) != 9 {
		t.Fatal("sum")
	}
}
func BenchmarkSum(b *testing.B) {
	values := make([]int, 1024)
	for i := range values {
		values[i] = i
	}
	b.ReportAllocs()
	for b.Loop() {
		sink = Sum(values)
	}
}
```

[cmd/l11/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l11/main.go)

```go
package main

import (
	"example.com/learn/go-advanced/metrics"
	"fmt"
)

func main() { fmt.Println(metrics.Sum([]int{1, 2, 3})) }
```

Desde la raíz del repositorio:

```sh
cd code/go-advanced
go run ./cmd/l11
```

### Contrato de salida esperado

```text
6
```

## Leer el contrato antes de cambiar el código

Antes de ejecutar, prediga el resultado e identifique la operación que vuelve observable cada valor. Siga la entrada desde el consumidor, pasando por copias y referencias, hasta su destino. Distinga el valor devuelto por una función de la duración de cualquier trabajo que lance. Cuando haya un error posible, identifique quién decide detenerse, reintentar o traducirlo. Imprimir un valor correcto solo cubre parte del contrato: también deben entenderse las entradas rechazadas y la terminación.

El listado es completo deliberadamente. Compárelo con su archivo de pruebas y nombre la aserción exacta que fallaría si cambiase el comportamiento. Una modificación exclusivamente interna debería conservar esas aserciones observables. Si cambia una frontera pública, describa la garantía modificada antes de editar. Este hábito se traslada bien desde C# y Java mientras mantiene explícitas las reglas de propiedad y sincronización de Go.

## Verificación y alcance

La salida mostrada constituye el contrato esperado del ejecutable, almacenado en `examples.json`. Reprodúzcala antes de considerarla una observación de su máquina. Las pruebas están escritas en el mismo módulo y la verificación central registra su ejecución real por separado. Ejemplos correctos no demuestran todos los sistemas operativos, cargas de producción o resultados de aprendizaje. Diagnósticos, perfiles y benchmarks describen experimentos hasta que el diario registre una medición. Conserve juntos versión, revisión y orden: una observación sin condiciones resulta difícil de reproducir.

## Ejercicios

1. ¿Por qué preparar la entrada fuera del bucle medido?

<details>
<summary>Solución completa</summary>

Se pregunta por sumar un segmento existente. Incluir su construcción mediría otra operación. Si forma parte de la carga real, escriba un benchmark distinto que la incluya deliberadamente.

</details>

2. ¿Un perfil goroutineleak sin anomalías sustituye pruebas de cierre?

<details>
<summary>Solución completa</summary>

No. El perfil tiene un alcance concreto del runtime; las pruebas verifican contratos de finalización de la aplicación. Mantenga esperas y pruebas de cancelación y use perfiles para investigar una carga representativa.

</details>

## Fuentes primarias

- [Benchmarks con testing](https://pkg.go.dev/testing#hdr-Benchmarks)
- [Diagnósticos](https://go.dev/doc/diagnostics)
- [runtime/pprof](https://pkg.go.dev/runtime/pprof)
- [runtime/trace](https://pkg.go.dev/runtime/trace)

[Lección siguiente](../12-reflection-and-encoding/) · [Diario de aprendizaje](../journal/)
