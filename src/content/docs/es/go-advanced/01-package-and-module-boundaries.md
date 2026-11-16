---
title: "1. Límites de paquetes y módulos"
description: "Diseñar un paquete de dominio pequeño cuya propiedad de datos y cuyos errores se entiendan sin su adaptador HTTP."
sidebar:
  order: 1
---

## Objetivo de aprendizaje

Diseñar un paquete de dominio pequeño cuya propiedad de datos y cuyos errores se entiendan sin su adaptador HTTP.

## Mecanismos y modelos de C#/Java

Un [módulo](https://go.dev/ref/mod) es una colección versionada de paquetes; un paquete es la unidad de compilación, visibilidad y dependencia. Un directorio con archivos Go ordinarios suele definir un solo paquete. La ruta del módulo sirve de prefijo para las importaciones; no crea un ensamblado que reúna todos los símbolos exportados. Empiece por una responsabilidad que el consumidor pueda nombrar: valores de dominio, delimitación de mensajes o admisión de trabajos. Un paquete llamado helpers suele ocultar la decisión sobre dependencias en lugar de resolverla.

El paquete de dominio construye un trabajo comprobando el nombre y copiando el segmento recibido. Exportar Job permite intercambiar un valor útil entre adaptadores; NewJob proporciona una construcción validada. Como sus campos exportados también permiten construirlo directamente, el servicio vuelve a validar en su verdadera frontera de admisión. Es intencional: una convención de constructor no garantiza por sí sola los invariantes de una estructura exportada. Una biblioteca más estricta podría ocultar campos y ofrecer accesores; aquí se mantiene visible la frontera del transporte.

Un espacio de nombres de C# y un paquete Java ofrecen analogías útiles, pero ninguno equivale exactamente a un módulo Go. La inicial mayúscula exporta un identificador; no se escribe public en cada declaración. El directorio internal limita las importaciones al árbol de su padre, y se rechazan los ciclos de importación. Prefiera una interfaz pequeña en el consumidor cuando realmente necesite una sustitución. Convertir cada tipo concreto en una interfaz traslada una costumbre de inyección de dependencias sin reducir ninguna dependencia.

Siga el futuro servicio hacia dentro: HTTP importa jobs, jobs importa domain y domain solo importa la biblioteca estándar. El dominio no debe importar HTTP para decidir un estado de respuesta. Eso impondría decisiones del transporte a todos sus consumidores. El versionado pertenece al módulo: después de la versión uno, una ruptura pública suele exigir una ruta de importación de nueva versión mayor. Este módulo es material didáctico, no una promesa de publicación en un registro.

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

[cmd/l01/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l01/main.go)

```go
package main

import (
	"example.com/learn/go-advanced/domain"
	"fmt"
)

func main() {
	job, err := domain.NewJob("sum", []int{2, 3})
	if err != nil {
		panic(err)
	}
	fmt.Println(job.Name, job.Total())
}
```

Desde la raíz del repositorio:

```sh
cd code/go-advanced
go run ./cmd/l01
```

### Contrato de salida esperado

```text
sum 5
```

## Leer el contrato antes de cambiar el código

Antes de ejecutar, prediga el resultado e identifique la operación que vuelve observable cada valor. Siga la entrada desde el consumidor, pasando por copias y referencias, hasta su destino. Distinga el valor devuelto por una función de la duración de cualquier trabajo que lance. Cuando haya un error posible, identifique quién decide detenerse, reintentar o traducirlo. Imprimir un valor correcto solo cubre parte del contrato: también deben entenderse las entradas rechazadas y la terminación.

El listado es completo deliberadamente. Compárelo con su archivo de pruebas y nombre la aserción exacta que fallaría si cambiase el comportamiento. Una modificación exclusivamente interna debería conservar esas aserciones observables. Si cambia una frontera pública, describa la garantía modificada antes de editar. Este hábito se traslada bien desde C# y Java mientras mantiene explícitas las reglas de propiedad y sincronización de Go.

## Verificación y alcance

La salida mostrada constituye el contrato esperado del ejecutable, almacenado en `examples.json`. Reprodúzcala antes de considerarla una observación de su máquina. Las pruebas están escritas en el mismo módulo y la verificación central registra su ejecución real por separado. Ejemplos correctos no demuestran todos los sistemas operativos, cargas de producción o resultados de aprendizaje. Diagnósticos, perfiles y benchmarks describen experimentos hasta que el diario registre una medición. Conserve juntos versión, revisión y orden: una observación sin condiciones resulta difícil de reproducir.

## Ejercicios

1. El consumidor cambia el segmento original después de NewJob. ¿Qué propiedad debe mantenerse y por qué?

<details>
<summary>Solución completa</summary>

El total sigue siendo cinco porque se copió el array subyacente. TestOwnership modifica la entrada y comprueba el total observable; copiar solo el descriptor conservaría el alias.

</details>

2. ¿Dónde debe situarse la regla que convierte un trabajo inválido en HTTP 400?

<details>
<summary>Solución completa</summary>

En el adaptador HTTP. El dominio devuelve una identidad de error; el adaptador elige el estado y otro consumidor podría elegir un código de salida. Mantenga las dependencias orientadas al dominio.

</details>

## Fuentes primarias

- [Referencia de módulos Go](https://go.dev/ref/mod)
- [Nombres de paquetes](https://go.dev/blog/package-names)

[Lección siguiente](../02-memory-escape-and-gc/) · [Diario de aprendizaje](../journal/)
