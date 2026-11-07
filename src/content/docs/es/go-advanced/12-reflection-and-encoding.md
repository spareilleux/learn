---
title: "12. Reflexión, codificación y fronteras"
description: "Incorporar decisiones de codificación al contrato de frontera y limitar la reflexión a tipos esperados."
sidebar:
  order: 12
---

## Objetivo de aprendizaje

Incorporar decisiones de codificación al contrato de frontera y limitar la reflexión a tipos esperados.

## Mecanismos y modelos de C#/Java

[encoding/json/v2](https://pkg.go.dev/encoding/json/v2) y [encoding/json/jsontext](https://pkg.go.dev/encoding/json/jsontext) son incorporaciones estables en Go 1.27. El primero convierte valores Go; jsontext trata la capa sintáctica de JSON. El encoding/json existente utiliza la implementación nueva conservando la semántica establecida de v1. Compartir implementación no vuelve intercambiables todos los comportamientos predeterminados. Elija API y opciones como contrato explícito y pruebe los campos y extremos de los que realmente dependen los clientes.

Record declara nombres de campos JSON y Decode solicita rechazar miembros desconocidos. Encode y Decode trabajan con bytes y un destino concreto. Así evitan un mapa genérico de valores dinámicos donde números y campos ausentes reciben interpretaciones implícitas. Rechazar miembros desconocidos es una política: un protocolo público tolerante a versiones puede admitir campos nuevos deliberadamente. El curso elige entrada estricta para enseñar la decisión, no para declararla compatible con cualquier estrategia de evolución.

La función de [reflect](https://pkg.go.dev/reflect) consulta el tipo después de comprobar nil y su clase. NumField tiene sentido para estructuras, no para cualquier valor. Fields devuelve cero para nil y valores que no son estructuras, y dos para Record. Contar campos no los serializa ni demuestra que sean exportados o modificables. Usar reflexión con una clase incorrecta puede provocar pánico; modificar requiere un valor direccionable y modificable. Un pequeño switch de tipos o una interfaz explícita suele ser más sencillo cuando las alternativas son conocidas.

Los atributos de C# y las anotaciones Java recuerdan a los tags de estructuras, pero estos son cadenas que interpreta una biblioteca, no un marco general de anotaciones ejecutables. La reflexión tampoco sustituye restricciones genéricas estáticas. Mantenga fronteras tipadas para operaciones normales y aísle la inspección dinámica donde la entrada esté realmente abierta. unsafe y cgo quedan fuera de los ejemplos ejecutables: cruzan fronteras de memoria o runtimes extranjeros y añaden reglas de propiedad y portabilidad. Su existencia no justifica sustituir reflexión segura por suposiciones de disposición. Verifique la codificación con Go 1.27 en vez de extrapolar notas experimentales anteriores.

## Ejemplo completo ejecutable

El ejecutable pertenece al módulo independiente `example.com/learn/go-advanced`. Su orden llama a paquetes reutilizables en vez de contener por sí sola todo el comportamiento. Lea primero el paquete y siga después sus llamadas desde la orden. Se muestran archivos versionados completos para mantener visibles importaciones, errores y liberación de recursos. No hace falta estado oculto de notebook ni servicios externos. Las órdenes utilizan el mismo directorio y sintaxis en Windows, Linux/WSL y macOS cuando Go está disponible en PATH.

### Código reutilizable

[encodingx/record.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/encodingx/record.go)

```go
package encodingx

import (
	"encoding/json/v2"
	"reflect"
)

type Record struct {
	Name   string `json:"name"`
	Values []int  `json:"values"`
}

func Encode(value Record) ([]byte, error) { return json.Marshal(value) }
func Decode(data []byte) (Record, error) {
	var value Record
	err := json.Unmarshal(data, &value, json.RejectUnknownMembers(true))
	return value, err
}
func Fields(value any) int {
	t := reflect.TypeOf(value)
	if t == nil || t.Kind() != reflect.Struct {
		return 0
	}
	return t.NumField()
}
```

[cmd/l12/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l12/main.go)

```go
package main

import (
	"example.com/learn/go-advanced/encodingx"
	"fmt"
)

func main() {
	value := encodingx.Record{Name: "sum", Values: []int{2, 3}}
	data, err := encodingx.Encode(value)
	if err != nil {
		panic(err)
	}
	decoded, err := encodingx.Decode(data)
	if err != nil {
		panic(err)
	}
	fmt.Println(string(data))
	fmt.Println(decoded.Name, encodingx.Fields(decoded))
}
```

Desde la raíz del repositorio:

```sh
cd code/go-advanced
go run ./cmd/l12
```

### Contrato de salida esperado

```text
{"name":"sum","values":[2,3]}
sum 2
```

## Leer el contrato antes de cambiar el código

Antes de ejecutar, prediga el resultado e identifique la operación que vuelve observable cada valor. Siga la entrada desde el consumidor, pasando por copias y referencias, hasta su destino. Distinga el valor devuelto por una función de la duración de cualquier trabajo que lance. Cuando haya un error posible, identifique quién decide detenerse, reintentar o traducirlo. Imprimir un valor correcto solo cubre parte del contrato: también deben entenderse las entradas rechazadas y la terminación.

El listado es completo deliberadamente. Compárelo con su archivo de pruebas y nombre la aserción exacta que fallaría si cambiase el comportamiento. Una modificación exclusivamente interna debería conservar esas aserciones observables. Si cambia una frontera pública, describa la garantía modificada antes de editar. Este hábito se traslada bien desde C# y Java mientras mantiene explícitas las reglas de propiedad y sincronización de Go.

## Verificación y alcance

La salida mostrada constituye el contrato esperado del ejecutable, almacenado en `examples.json`. Reprodúzcala antes de considerarla una observación de su máquina. Las pruebas están escritas en el mismo módulo y la verificación central registra su ejecución real por separado. Ejemplos correctos no demuestran todos los sistemas operativos, cargas de producción o resultados de aprendizaje. Diagnósticos, perfiles y benchmarks describen experimentos hasta que el diario registre una medición. Conserve juntos versión, revisión y orden: una observación sin condiciones resulta difícil de reproducir.

## Ejercicios

1. ¿Una ida y vuelta correcta demuestra compatibilidad JSON pública?

<details>
<summary>Solución completa</summary>

No. Codificador y decodificador pueden compartir un comportamiento inesperado. Añada expectativas exactas del formato y entradas de clientes anteriores; elija políticas sobre campos desconocidos, null, números y nombres antes de cambiar el protocolo.

</details>

2. ¿Por qué consultar Kind antes de NumField?

<details>
<summary>Solución completa</summary>

NumField exige un tipo estructura. Comprobar nil y la clase establece esa precondición y devuelve cero de forma predecible fuera del dominio, sin recuperar pánicos para el flujo normal.

</details>

## Fuentes primarias

- [encoding/json/v2](https://pkg.go.dev/encoding/json/v2)
- [encoding/json/jsontext](https://pkg.go.dev/encoding/json/jsontext)
- [reflect](https://pkg.go.dev/reflect)
- [Go 1.27](https://go.dev/doc/go1.27)

[Lección siguiente](../13-dependencies-builds-and-security/) · [Diario de aprendizaje](../journal/)
