---
title: "4. Contratos de error y nil tipado"
description: "Conservar la identidad del error entre capas y devolver una interfaz realmente nil cuando hay éxito."
sidebar:
  order: 4
---

## Objetivo de aprendizaje

Conservar la identidad del error entre capas y devolver una interfaz realmente nil cuando hay éxito.

## Mecanismos y modelos de C#/Java

El paquete [errors](https://pkg.go.dev/errors) separa reconocer un error de mostrar su mensaje. NewJob envuelve ErrInvalid mediante la directiva de formato correspondiente. El consumidor puede añadir contexto sin perder la identidad que comprueba errors.Is. errors.As busca un error tipado compatible en el árbol y rellena el puntero de destino. Use identidades y tipos para tomar decisiones; reserve las cadenas legibles para explicarlas. Cambiar puntuación no debería modificar silenciosamente el flujo del programa.

Una interfaz contiene información de tipo dinámico y un valor dinámico. TypedNil devuelve una interfaz error que contiene un puntero nil de tipo ValidationError. Esa interfaz no es nil. Validate devuelve, en cambio, el literal nil cuando tiene éxito. La orden muestra la diferencia sin desreferenciar un puntero nil. ValidationError.Error admite un receptor nil, lo que permite mostrar ese valor concreto; otros tipos podrían provocar un pánico. La lección trata de la representación de interfaces, no de una garantía universal sobre receptores nil.

Las anotaciones de referencias anulables de C# describen un contrato estático, mientras que null en Java es un valor de referencia. Ninguno predice directamente la igualdad con nil de una interfaz Go. Considere ambas partes de la interfaz. Una función que devuelve un puntero concreto puede devolver su valor cero, pero convertir ese puntero en error crea otro contrato. Declare error cuando el consumidor deba seguir la convención habitual y devuelva nil explícitamente para el éxito.

Envolver un error de implementación también expone información. Si los consumidores empiezan a reconocer un error concreto del controlador de datos, sustituirlo puede romper una API pública. Decida qué errores tienen significado en la frontera del paquete. Este curso expone invalid, full y closed para distinguir validación, sobrecarga y cierre, sin prometer toda representación interna. Un pánico puede señalar una suposición de programación violada en una frontera de proceso, pero no una entrada inválida rutinaria. Se pueden unir varios errores sin prometer el formato textual de su árbol.

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

[cmd/l04/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l04/main.go)

```go
package main

import (
	"errors"
	"example.com/learn/go-advanced/domain"
	"fmt"
)

func main() {
	fmt.Println(domain.TypedNil() == nil, domain.Validate("ok") == nil)
	var detail *domain.ValidationError
	fmt.Println(errors.As(domain.Validate(""), &detail), detail.Field)
}
```

Desde la raíz del repositorio:

```sh
cd code/go-advanced
go run ./cmd/l04
```

### Contrato de salida esperado

```text
false true
true name
```

## Leer el contrato antes de cambiar el código

Antes de ejecutar, prediga el resultado e identifique la operación que vuelve observable cada valor. Siga la entrada desde el consumidor, pasando por copias y referencias, hasta su destino. Distinga el valor devuelto por una función de la duración de cualquier trabajo que lance. Cuando haya un error posible, identifique quién decide detenerse, reintentar o traducirlo. Imprimir un valor correcto solo cubre parte del contrato: también deben entenderse las entradas rechazadas y la terminación.

El listado es completo deliberadamente. Compárelo con su archivo de pruebas y nombre la aserción exacta que fallaría si cambiase el comportamiento. Una modificación exclusivamente interna debería conservar esas aserciones observables. Si cambia una frontera pública, describa la garantía modificada antes de editar. Este hábito se traslada bien desde C# y Java mientras mantiene explícitas las reglas de propiedad y sincronización de Go.

## Verificación y alcance

La salida mostrada constituye el contrato esperado del ejecutable, almacenado en `examples.json`. Reprodúzcala antes de considerarla una observación de su máquina. Las pruebas están escritas en el mismo módulo y la verificación central registra su ejecución real por separado. Ejemplos correctos no demuestran todos los sistemas operativos, cargas de producción o resultados de aprendizaje. Diagnósticos, perfiles y benchmarks describen experimentos hasta que el diario registre una medición. Conserve juntos versión, revisión y orden: una observación sin condiciones resulta difícil de reproducir.

## Ejercicios

1. ¿Por qué TypedNil() == nil es false?

<details>
<summary>Solución completa</summary>

La interfaz conserva el tipo dinámico del puntero aunque su valor sea nil. Devuelva el literal nil en el camino de éxito como Validate; no repare los consumidores comparando cadenas.

</details>

2. ¿Cómo reconoce un adaptador HTTP un trabajo inválido cuyo error fue envuelto?

<details>
<summary>Solución completa</summary>

Use errors.Is(err, domain.ErrInvalid). Para detalles de ValidationError, use errors.As con un destino puntero. Ambos recorren envoltorios; la igualdad directa solo reconoce la propia variable centinela.

</details>

## Fuentes primarias

- [errors](https://pkg.go.dev/errors)
- [Preguntas frecuentes: error nil](https://go.dev/doc/faq#nil_error)

[Lección siguiente](../05-memory-model-sync-and-atomics/) · [Diario de aprendizaje](../journal/)
