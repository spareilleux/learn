---
title: "5. Modelo de memoria, sincronización y atómicos"
description: "Explicar la relación de sincronización que hace observable un resultado concurrente."
sidebar:
  order: 5
---

## Objetivo de aprendizaje

Explicar la relación de sincronización que hace observable un resultado concurrente.

## Mecanismos y modelos de C#/Java

El [modelo de memoria de Go](https://go.dev/ref/mem) define cuándo una goroutine puede depender de las escrituras de otra. El código concurrente correcto necesita una relación de sincronización, no una historia plausible sobre el planificador. Una comunicación por canal, un protocolo de mutex, una espera de finalización o una operación atómica pueden establecer la relación adecuada. Esperar cierto tiempo no demuestra que una escritura haya ocurrido o sea visible. Un programa sin carreras de datos obtiene la garantía de coherencia secuencial descrita en el modelo.

Counter guarda su valor en un atomic.Int64. Add y Load operan sobre la misma ubicación atómica. La orden lanza cuatro goroutines que incrementan veinticinco veces y espera antes de imprimir. El total es estable porque cada incremento es atómico y todos terminan antes de la observación final. Un incremento ordinario combina lectura, cálculo y escritura; varios incrementos pueden sobrescribirse. El curso no incluye una orden deliberadamente insegura con un total final inventado.

El paquete [sync](https://pkg.go.dev/sync) ofrece herramientas con responsabilidades diferentes. WaitGroup sigue la finalización; no protege automáticamente un mapa compartido por sus tareas. Mutex protege un invariante entre varios valores cuando todos los accesos relevantes siguen el mismo protocolo. Los campos atómicos permiten operaciones precisas sobre valores individuales. Sustituir el mutex de un saldo y su registro por dos atómicos independientes no preservaría su relación. Nunca copie un valor de sincronización después de utilizarlo.

lock de C# y synchronized de Java son formas conocidas de proteger invariantes. No implican que los atómicos de Go equivalgan a un campo ordinario con una anotación volatile. Consulte el modelo y la documentación de Go para la garantía exacta. El pipeline utiliza otra estrategia: los trabajadores envían resultados indexados y una sola goroutine escribe el segmento de salida. Así elimina escrituras concurrentes. Elija el argumento más sencillo que pueda explicar con precisión y compruebe que participa cada acceso. El detector de carreras observa caminos ejecutados; complementa ese argumento sin demostrar la seguridad de todos los caminos.

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

[cmd/l05/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l05/main.go)

```go
package main

import (
	"example.com/learn/go-advanced/pipeline"
	"fmt"
	"sync"
)

func main() {
	var c pipeline.Counter
	var group sync.WaitGroup
	for range 4 {
		group.Go(func() {
			for range 25 {
				c.Add()
			}
		})
	}
	group.Wait()
	fmt.Println(c.Value())
}
```

Desde la raíz del repositorio:

```sh
cd code/go-advanced
go run ./cmd/l05
```

### Contrato de salida esperado

```text
100
```

## Leer el contrato antes de cambiar el código

Antes de ejecutar, prediga el resultado e identifique la operación que vuelve observable cada valor. Siga la entrada desde el consumidor, pasando por copias y referencias, hasta su destino. Distinga el valor devuelto por una función de la duración de cualquier trabajo que lance. Cuando haya un error posible, identifique quién decide detenerse, reintentar o traducirlo. Imprimir un valor correcto solo cubre parte del contrato: también deben entenderse las entradas rechazadas y la terminación.

El listado es completo deliberadamente. Compárelo con su archivo de pruebas y nombre la aserción exacta que fallaría si cambiase el comportamiento. Una modificación exclusivamente interna debería conservar esas aserciones observables. Si cambia una frontera pública, describa la garantía modificada antes de editar. Este hábito se traslada bien desde C# y Java mientras mantiene explícitas las reglas de propiedad y sincronización de Go.

## Verificación y alcance

La salida mostrada constituye el contrato esperado del ejecutable, almacenado en `examples.json`. Reprodúzcala antes de considerarla una observación de su máquina. Las pruebas están escritas en el mismo módulo y la verificación central registra su ejecución real por separado. Ejemplos correctos no demuestran todos los sistemas operativos, cargas de producción o resultados de aprendizaje. Diagnósticos, perfiles y benchmarks describen experimentos hasta que el diario registre una medición. Conserve juntos versión, revisión y orden: una observación sin condiciones resulta difícil de reproducir.

## Ejercicios

1. ¿Basta WaitGroup para proteger un incremento compartido?

<details>
<summary>Solución completa</summary>

No. Coordina la finalización, no las lecturas y escrituras del incremento. Use Counter o un mutex que proteja todos los accesos y espere antes de interpretar el total final.

</details>

2. ¿Dos atómicos mantienen automáticamente un invariante entre campos?

<details>
<summary>Solución completa</summary>

No. Un lector puede observar una combinación de actualizaciones diferentes. Proteja el estado relacionado con un mutex o publique una instantánea inmutable mediante un punto de sincronización según el invariante real.

</details>

## Fuentes primarias

- [Modelo de memoria de Go](https://go.dev/ref/mem)
- [sync](https://pkg.go.dev/sync)
- [sync/atomic](https://pkg.go.dev/sync/atomic)

[Lección siguiente](../06-bounded-pipelines/) · [Diario de aprendizaje](../journal/)
