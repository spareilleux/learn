---
title: "9. Flujos y delimitación de mensajes"
description: "Implementar un protocolo de tramas limitado que soporte lecturas y escrituras parciales."
sidebar:
  order: 9
---

## Objetivo de aprendizaje

Implementar un protocolo de tramas limitado que soporte lecturas y escrituras parciales.

## Mecanismos y modelos de C#/Java

Las interfaces [io](https://pkg.go.dev/io) describen flujos, no entregas de mensajes. Un Read puede devolver menos bytes de los pedidos sin indicar que el emisor haya enviado todo el mensaje. Una escritura TCP no se conserva como una lectura TCP correspondiente. También ocurre con archivos almacenados en búfer y capas de compresión. Defina un protocolo de delimitación antes de interpretar bytes como mensajes. Aquí una longitud sin signo de cuatro bytes en orden big endian precede al contenido.

El paquete [encoding/binary](https://pkg.go.dev/encoding/binary) hace explícita la representación de la cabecera, independientemente del orden nativo de la máquina. Read usa io.ReadFull para cabecera y contenido. Comprueba el máximo MaxFrame antes de asignar memoria y rechaza pronto un tamaño hostil. La longitud cero representa un mensaje vacío válido. El final antes de una nueva cabecera difiere de una truncación durante la cabecera o el contenido: un EOF limpio puede indicar cierre normal; un EOF inesperado señala una trama dañada.

Write comprueba el mismo límite, escribe toda la cabecera y después el contenido. Su auxiliar continúa las escrituras parciales, devuelve errores del writer y rechaza escrituras sin progreso. Sin esta última comprobación, un writer defectuoso podría provocar un bucle infinito. Un error después de algunos bytes no significa que no se haya transmitido nada. Reintentar automáticamente en la misma conexión puede añadir otra cabecera a una trama parcial dañada. Reconcilie el estado del protocolo o cierre el flujo antes de decidir si la operación puede repetirse con seguridad.

Los streams de C# y Java también permiten lecturas parciales; los métodos cómodos de búfer no convierten conexiones en buses de mensajes. La prueba [net.Pipe](https://pkg.go.dev/net#Pipe) conecta dos extremos locales, intercambia dos tramas y comprueba EOF al cerrar. Sus plazos limitan fallos, no sincronizan mediante sleep. Las pruebas de cabecera incompleta, longitud excesiva y contenido truncado definen errores. Las semillas de fuzz comprueban recorridos de ida y vuelta para contenidos limitados. Autenticación, negociación de compresión y entrega duradera quedan fuera de este contrato.

## Ejemplo completo ejecutable

El ejecutable pertenece al módulo independiente `example.com/learn/go-advanced`. Su orden llama a paquetes reutilizables en vez de contener por sí sola todo el comportamiento. Lea primero el paquete y siga después sus llamadas desde la orden. Se muestran archivos versionados completos para mantener visibles importaciones, errores y liberación de recursos. No hace falta estado oculto de notebook ni servicios externos. Las órdenes utilizan el mismo directorio y sintaxis en Windows, Linux/WSL y macOS cuando Go está disponible en PATH.

### Código reutilizable

[framing/frame.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/framing/frame.go)

```go
package framing

import (
	"encoding/binary"
	"errors"
	"io"
)

const MaxFrame = 1024

var ErrTooLarge = errors.New("frame too large")

func Write(w io.Writer, payload []byte) error {
	if len(payload) > MaxFrame {
		return ErrTooLarge
	}
	var header [4]byte
	binary.BigEndian.PutUint32(header[:], uint32(len(payload)))
	if err := writeAll(w, header[:]); err != nil {
		return err
	}
	return writeAll(w, payload)
}
func writeAll(w io.Writer, data []byte) error {
	for len(data) > 0 {
		n, err := w.Write(data)
		if n < 0 || n > len(data) {
			return io.ErrShortWrite
		}
		data = data[n:]
		if err != nil {
			return err
		}
		if n == 0 {
			return io.ErrShortWrite
		}
	}
	return nil
}
func Read(r io.Reader) ([]byte, error) {
	var header [4]byte
	if _, err := io.ReadFull(r, header[:]); err != nil {
		return nil, err
	}
	size := binary.BigEndian.Uint32(header[:])
	if size > MaxFrame {
		return nil, ErrTooLarge
	}
	data := make([]byte, int(size))
	_, err := io.ReadFull(r, data)
	if err == io.EOF {
		err = io.ErrUnexpectedEOF
	}
	return data, err
}
```

[cmd/l09/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l09/main.go)

```go
package main

import (
	"bytes"
	"example.com/learn/go-advanced/framing"
	"fmt"
)

func main() {
	var wire bytes.Buffer
	if err := framing.Write(&wire, []byte("Go")); err != nil {
		panic(err)
	}
	payload, err := framing.Read(&wire)
	if err != nil {
		panic(err)
	}
	fmt.Println(string(payload))
}
```

Desde la raíz del repositorio:

```sh
cd code/go-advanced
go run ./cmd/l09
```

### Contrato de salida esperado

```text
Go
```

## Leer el contrato antes de cambiar el código

Antes de ejecutar, prediga el resultado e identifique la operación que vuelve observable cada valor. Siga la entrada desde el consumidor, pasando por copias y referencias, hasta su destino. Distinga el valor devuelto por una función de la duración de cualquier trabajo que lance. Cuando haya un error posible, identifique quién decide detenerse, reintentar o traducirlo. Imprimir un valor correcto solo cubre parte del contrato: también deben entenderse las entradas rechazadas y la terminación.

El listado es completo deliberadamente. Compárelo con su archivo de pruebas y nombre la aserción exacta que fallaría si cambiase el comportamiento. Una modificación exclusivamente interna debería conservar esas aserciones observables. Si cambia una frontera pública, describa la garantía modificada antes de editar. Este hábito se traslada bien desde C# y Java mientras mantiene explícitas las reglas de propiedad y sincronización de Go.

## Verificación y alcance

La salida mostrada constituye el contrato esperado del ejecutable, almacenado en `examples.json`. Reprodúzcala antes de considerarla una observación de su máquina. Las pruebas están escritas en el mismo módulo y la verificación central registra su ejecución real por separado. Ejemplos correctos no demuestran todos los sistemas operativos, cargas de producción o resultados de aprendizaje. Diagnósticos, perfiles y benchmarks describen experimentos hasta que el diario registre una medición. Conserve juntos versión, revisión y orden: una observación sin condiciones resulta difícil de reproducir.

## Ejercicios

1. ¿Dónde debe comprobarse el límite de longitud?

<details>
<summary>Solución completa</summary>

Justo después de interpretar la cabecera fija y antes de asignar el contenido. Comprobar después ya permitiría consumir memoria excesiva. Read y Write deben compartir el límite.

</details>

2. ¿Puede repetirse ciegamente una escritura de trama parcialmente fallida?

<details>
<summary>Solución completa</summary>

No. Puede haber bytes transmitidos y el receptor puede haber actuado. Cierre o reconcilie el flujo y use identidad de operación y contrato de entrega si necesita reintentos. El tramage no garantiza ejecución única.

</details>

## Fuentes primarias

- [io](https://pkg.go.dev/io)
- [encoding/binary](https://pkg.go.dev/encoding/binary)
- [net.Pipe](https://pkg.go.dev/net#Pipe)

[Lección siguiente](../10-race-fuzz-and-property-tests/) · [Diario de aprendizaje](../journal/)
