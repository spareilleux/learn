---
title: "6. Pipelines con concurrencia limitada"
description: "Limitar el trabajo concurrente y permitir cancelar cada operación que pueda bloquearse."
sidebar:
  order: 6
---

## Objetivo de aprendizaje

Limitar el trabajo concurrente y permitir cancelar cada operación que pueda bloquearse.

## Mecanismos y modelos de C#/Java

Un [pipeline](https://go.dev/blog/pipelines) necesita reglas de propiedad y terminación para cada etapa. Squares tiene un productor, un número fijo de trabajadores y un recolector. Solo el productor cierra jobs. Otra goroutine espera a todos los trabajadores y cierra results. El recolector recorre results hasta ese cierre. Ningún trabajador cierra un canal compartido del que no sea propietario exclusivo. Estas decisiones importan más que un diagrama atractivo de flechas.

El número de trabajadores se normaliza a un mínimo de uno y un máximo igual al número de entradas. Una entrada vacía no crea trabajadores. Los canales sin búfer fuerzan entregas entre etapas sin almacenar una cola ilimitada. La función sigue asignando una salida proporcional a la entrada: limitar concurrencia no significa memoria total constante. Para un flujo ilimitado, la API necesitaría salida en flujo o un límite explícito de entrada. Aquí el segmento es finito y la salida conserva su orden de índices.

Cada envío del productor y los trabajadores selecciona también la cancelación de [context](https://pkg.go.dev/context). Un consumidor que abandona un flujo sin cancelar puede dejar bloqueado al emisor anterior; esta función evita ese peligro público recolectando hasta que terminan los trabajadores. La cancelación es cooperativa. Si comunicación y cancelación están listas, select puede elegir cualquiera, así que pueden ocurrir algunos pasos adicionales limitados. La comprobación final del contexto impide presentar resultados parciales como completos.

Las consultas paralelas de C# y los streams paralelos de Java ocultan la planificación mediante operadores. Pero trasladarlos lanzando una goroutine por entrada no conserva un presupuesto de concurrencia. Defina ese presupuesto aparte del número de entradas. Distinga también orden de resultados y orden de finalización: etiquetar índices admite cualquier planificación y reconstruye una salida determinista. Pruebe varios números de trabajadores, entradas vacías y entradas ya canceladas. El cálculo utiliza enteros de tamaño de máquina y puede desbordarse; enseña ciclos de vida, no aritmética financiera comprobada.

## Ejemplo completo ejecutable

El ejecutable pertenece al módulo independiente `example.com/learn/go-advanced`. Su orden llama a paquetes reutilizables en vez de contener por sí sola todo el comportamiento. Lea primero el paquete y siga después sus llamadas desde la orden. Se muestran archivos versionados completos para mantener visibles importaciones, errores y liberación de recursos. No hace falta estado oculto de notebook ni servicios externos. Las órdenes utilizan el mismo directorio y sintaxis en Windows, Linux/WSL y macOS cuando Go está disponible en PATH.

### Código reutilizable

[pipeline/pipeline.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/pipeline/pipeline.go)

```go
package pipeline

import (
	"context"
	"sync"
	"sync/atomic"
)

type Counter struct{ value atomic.Int64 }

func (c *Counter) Add()         { c.value.Add(1) }
func (c *Counter) Value() int64 { return c.value.Load() }

func Squares(ctx context.Context, input []int, workers int) ([]int, error) {
	if err := ctx.Err(); err != nil {
		return nil, err
	}
	if workers < 1 {
		workers = 1
	}
	if workers > len(input) {
		workers = len(input)
	}
	type item struct{ index, value int }
	jobs := make(chan item)
	results := make(chan item)
	var group sync.WaitGroup
	group.Add(workers)
	for range workers {
		go func() {
			defer group.Done()
			for {
				select {
				case <-ctx.Done():
					return
				case job, ok := <-jobs:
					if !ok {
						return
					}
					job.value *= job.value
					select {
					case results <- job:
					case <-ctx.Done():
						return
					}
				}
			}
		}()
	}
	go func() {
		defer close(jobs)
		for i, v := range input {
			select {
			case jobs <- item{i, v}:
			case <-ctx.Done():
				return
			}
		}
	}()
	go func() { group.Wait(); close(results) }()
	output := make([]int, len(input))
	for result := range results {
		output[result.index] = result.value
	}
	if err := ctx.Err(); err != nil {
		return nil, err
	}
	return output, nil
}

func Wait(ctx context.Context, started chan<- struct{}) error {
	close(started)
	<-ctx.Done()
	return context.Cause(ctx)
}
```

[cmd/l06/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l06/main.go)

```go
package main

import (
	"context"
	"example.com/learn/go-advanced/pipeline"
	"fmt"
)

func main() {
	values, err := pipeline.Squares(context.Background(), []int{1, 2, 3}, 2)
	if err != nil {
		panic(err)
	}
	fmt.Println(values)
}
```

Desde la raíz del repositorio:

```sh
cd code/go-advanced
go run ./cmd/l06
```

### Contrato de salida esperado

```text
[1 4 9]
```

## Leer el contrato antes de cambiar el código

Antes de ejecutar, prediga el resultado e identifique la operación que vuelve observable cada valor. Siga la entrada desde el consumidor, pasando por copias y referencias, hasta su destino. Distinga el valor devuelto por una función de la duración de cualquier trabajo que lance. Cuando haya un error posible, identifique quién decide detenerse, reintentar o traducirlo. Imprimir un valor correcto solo cubre parte del contrato: también deben entenderse las entradas rechazadas y la terminación.

El listado es completo deliberadamente. Compárelo con su archivo de pruebas y nombre la aserción exacta que fallaría si cambiase el comportamiento. Una modificación exclusivamente interna debería conservar esas aserciones observables. Si cambia una frontera pública, describa la garantía modificada antes de editar. Este hábito se traslada bien desde C# y Java mientras mantiene explícitas las reglas de propiedad y sincronización de Go.

## Verificación y alcance

La salida mostrada constituye el contrato esperado del ejecutable, almacenado en `examples.json`. Reprodúzcala antes de considerarla una observación de su máquina. Las pruebas están escritas en el mismo módulo y la verificación central registra su ejecución real por separado. Ejemplos correctos no demuestran todos los sistemas operativos, cargas de producción o resultados de aprendizaje. Diagnósticos, perfiles y benchmarks describen experimentos hasta que el diario registre una medición. Conserve juntos versión, revisión y orden: una observación sin condiciones resulta difícil de reproducir.

## Ejercicios

1. ¿Quién puede cerrar results y cuándo?

<details>
<summary>Solución completa</summary>

El coordinador lo cierra cuando WaitGroup confirma que ningún trabajador sigue enviando. Si lo cerrase un trabajador, otro podría enviar al canal cerrado. El productor solo es dueño de jobs.

</details>

2. ¿Un número fijo de trabajadores garantiza memoria constante?

<details>
<summary>Solución completa</summary>

No. Los segmentos de entrada y salida crecen con el número de valores. Para una fuente ilimitada, exponga consumo en flujo con cancelación o imponga un límite documentado en vez de recolectarlo todo.

</details>

## Fuentes primarias

- [Pipelines y cancelación](https://go.dev/blog/pipelines)
- [context](https://pkg.go.dev/context)

[Lección siguiente](../07-cancellation-deadlines-and-shutdown/) · [Diario de aprendizaje](../journal/)
