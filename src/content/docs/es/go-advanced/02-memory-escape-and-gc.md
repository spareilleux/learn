---
title: "2. Memoria, análisis de escape y GC"
description: "Separar las garantías de aliasing de las decisiones de asignación del compilador y preparar una medición honesta."
sidebar:
  order: 2
---

## Objetivo de aprendizaje

Separar las garantías de aliasing de las decisiones de asignación del compilador y preparar una medición honesta.

## Mecanismos y modelos de C#/Java

La [guía del GC](https://go.dev/doc/gc-guide) describe un recolector que rastrea los objetos alcanzables. Un puntero no implica asignación en el montón y una declaración local no implica asignación en la pila. El análisis de escape decide si el almacenamiento puede permanecer en su duración actual; el inlining y la versión del compilador pueden cambiar esa decisión. Devolver un puntero a una variable local es seguro porque Go conserva su duración. Un informe de escape explica una compilación concreta, no una propiedad permanente de una línea.

Un segmento es un descriptor sobre un array. Copiar el descriptor comparte el almacenamiento; crear otro segmento cambia la ventana visible sin liberar un array grande que siga referenciado. Clone crea almacenamiento independiente para los bytes visibles. Modificar source después solo cambia source. NewJob toma la misma decisión de propiedad para enteros. Esta garantía semántica se puede probar sin averiguar dónde sitúa el compilador cada objeto. Copiar segmentos anidados exigiría decidir la propiedad de cada nivel referenciado.

Si viene de arrays de C# o Java, distinga el valor array de Go de un segmento que referencia un array. Asignar un array Go copia sus elementos. Asignar un segmento copia únicamente su descriptor. Ni la recolección ni la sincronización independizan elementos mutables compartidos. Evite guardar una ventana diminuta de un búfer enorme en una caché duradera; copie la parte cuya propiedad necesita. La copia puede reducir memoria retenida y aumentar el número de asignaciones, por lo que la métrica depende de la carga.

Prepare el diagnóstico con go build -gcflags=-m=2 ./domain y anote compilador, opciones y revisión. Aquí esa orden sigue siendo una propuesta experimental: no se ha capturado su diagnóstico. Mida asignaciones antes de introducir un pool. Un pool puede descartar entradas y no conserva propiedad exclusiva después de devolver un valor. Ajustar el GC cambia el equilibrio entre CPU y memoria; no corrige un grafo retenido accidentalmente. Aclare primero las duraciones de vida.

## Ejemplo completo ejecutable

El ejecutable pertenece al módulo independiente `example.com/learn/go-advanced`. Su orden llama a paquetes reutilizables en vez de contener por sí sola todo el comportamiento. Lea primero el paquete y siga después sus llamadas desde la orden. Se muestran archivos versionados completos para mantener visibles importaciones, errores y liberación de recursos. No hace falta estado oculto de notebook ni servicios externos. Las órdenes utilizan el mismo directorio y sintaxis en Windows, Linux/WSL y macOS cuando Go está disponible en PATH.

### Código reutilizable

[domain/job.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/domain/job.go)

```go
package domain

import (
	"errors"
	"fmt"
	"strings"
)

var ErrInvalid = errors.New("invalid job")

type Job struct {
	Name   string
	Values []int
}

func NewJob(name string, values []int) (Job, error) {
	if strings.TrimSpace(name) == "" {
		return Job{}, fmt.Errorf("name: %w", ErrInvalid)
	}
	return Job{Name: name, Values: append([]int(nil), values...)}, nil
}

func (j Job) Total() int {
	var total int
	for _, v := range j.Values {
		total += v
	}
	return total
}

func Clone(data []byte) []byte { return append([]byte(nil), data...) }

type ValidationError struct{ Field string }

func (e *ValidationError) Error() string {
	if e == nil {
		return "nil validation"
	}
	return "invalid " + e.Field
}
func Validate(name string) error {
	if name == "" {
		return &ValidationError{Field: "name"}
	}
	return nil
}
func TypedNil() error { var e *ValidationError; return e }
```

[cmd/l02/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l02/main.go)

```go
package main

import (
	"example.com/learn/go-advanced/domain"
	"fmt"
)

func main() {
	source := []byte{1, 2}
	copy := domain.Clone(source)
	source[0] = 9
	fmt.Println(source, copy)
}
```

Desde la raíz del repositorio:

```sh
cd code/go-advanced
go run ./cmd/l02
```

### Contrato de salida esperado

```text
[9 2] [1 2]
```

## Leer el contrato antes de cambiar el código

Antes de ejecutar, prediga el resultado e identifique la operación que vuelve observable cada valor. Siga la entrada desde el consumidor, pasando por copias y referencias, hasta su destino. Distinga el valor devuelto por una función de la duración de cualquier trabajo que lance. Cuando haya un error posible, identifique quién decide detenerse, reintentar o traducirlo. Imprimir un valor correcto solo cubre parte del contrato: también deben entenderse las entradas rechazadas y la terminación.

El listado es completo deliberadamente. Compárelo con su archivo de pruebas y nombre la aserción exacta que fallaría si cambiase el comportamiento. Una modificación exclusivamente interna debería conservar esas aserciones observables. Si cambia una frontera pública, describa la garantía modificada antes de editar. Este hábito se traslada bien desde C# y Java mientras mantiene explícitas las reglas de propiedad y sincronización de Go.

## Verificación y alcance

La salida mostrada constituye el contrato esperado del ejecutable, almacenado en `examples.json`. Reprodúzcala antes de considerarla una observación de su máquina. Las pruebas están escritas en el mismo módulo y la verificación central registra su ejecución real por separado. Ejemplos correctos no demuestran todos los sistemas operativos, cargas de producción o resultados de aprendizaje. Diagnósticos, perfiles y benchmarks describen experimentos hasta que el diario registre una medición. Conserve juntos versión, revisión y orden: una observación sin condiciones resulta difícil de reproducir.

## Ejercicios

1. ¿Devolver un puntero local lo deja colgante?

<details>
<summary>Solución completa</summary>

No. Go mantiene vivo el almacenamiento referenciado. Su ubicación la decide la implementación; la seguridad depende de la duración del valor, no de una suposición sobre la pila.

</details>

2. Una caché conserva 20 bytes de un búfer de 20 MB. ¿Qué cambio y medición propondría?

<details>
<summary>Solución completa</summary>

Copie los bytes visibles antes de conservarlos. Compare memoria retenida y tráfico de asignaciones con cargas y condiciones de GC iguales. La prueba de propiedad y la relación de tamaños no demuestran una mejora de velocidad.

</details>

## Fuentes primarias

- [Guía del GC](https://go.dev/doc/gc-guide)
- [Opciones del compilador](https://pkg.go.dev/cmd/compile)

[Lección siguiente](../03-generics-and-iterators/) · [Diario de aprendizaje](../journal/)
