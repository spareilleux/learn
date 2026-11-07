---
title: "13. Dependencias, compilaciones y seguridad"
description: "Distinguir selección reproducible de fuentes, análisis de vulnerabilidades y artefacto desplegable."
sidebar:
  order: 13
---

## Objetivo de aprendizaje

Distinguir selección reproducible de fuentes, análisis de vulnerabilidades y artefacto desplegable.

## Mecanismos y modelos de C#/Java

La [referencia de módulos](https://go.dev/ref/mod) describe go.mod como parte de la selección de dependencias y configuración del lenguaje. Este módulo declara go 1.27.0 y solo importa la biblioteca estándar. No tener dependencias externas no elimina el mantenimiento de seguridad: compilador y biblioteca necesitan actualizaciones compatibles. Una suma de comprobación compara contenido descargado con un resumen esperado; no certifica seguridad, revisión ni ausencia de vulnerabilidades.

La [orden go](https://pkg.go.dev/cmd/go) ofrece inspección del grafo, pruebas, vet y compilación con propósitos diferentes. go list -m all muestra módulos seleccionados; go mod verify comprueba contenido descargado; go vet detecta construcciones sospechosas; go test ejercita contratos escritos. Cada resultado responde una pregunta distinta. Una prueba correcta no demuestra qué compilador creó un artefacto ni que el despliegue use ese artefacto. Registre versión y procedencia junto al resultado relevante.

[runtime/debug.ReadBuildInfo](https://pkg.go.dev/runtime/debug#ReadBuildInfo) expone información de compilación disponible en el binario en ejecución. Nuestra orden imprime la ruta del módulo principal, un dato determinista aquí. Evita citar versiones de compilador o revisiones que cambian entre máquinas. Los metadatos reales de una entrega deberían incluir revisión, compilador, opciones, arquitectura y resumen del artefacto. Las rutas pueden revelar datos de la máquina de compilación; considere trimpath como decisión explícita de publicación y verifique su efecto sin asumir reproducibilidad bit a bit.

Quienes usan NuGet en C# y Maven en Java conocen la diferencia entre seleccionar dependencias, restaurar bytes y publicar binarios. Las reglas de módulos Go difieren de dar prioridad al más cercano o aplicar reemplazos improvisados. Revise replacements y configuración workspace porque las sustituciones locales pueden cambiar lo construido. La [gestión de vulnerabilidades de Go](https://go.dev/security/vuln) explica cómo govulncheck utiliza la base de avisos y los símbolos alcanzables. Esta unidad no lo instala ni ejecuta. Registre una ejecución real antes de afirmar una evaluación; un resultado limpio sigue limitado a avisos conocidos y al alcance de la herramienta. Mantenga secretos fuera de ejemplos y examine artefactos además del código.

## Ejemplo completo ejecutable

El ejecutable pertenece al módulo independiente `example.com/learn/go-advanced`. Su orden llama a paquetes reutilizables en vez de contener por sí sola todo el comportamiento. Lea primero el paquete y siga después sus llamadas desde la orden. Se muestran archivos versionados completos para mantener visibles importaciones, errores y liberación de recursos. No hace falta estado oculto de notebook ni servicios externos. Las órdenes utilizan el mismo directorio y sintaxis en Windows, Linux/WSL y macOS cuando Go está disponible en PATH.

### Código reutilizable

[provenance/build.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/provenance/build.go)

```go
package provenance

import "runtime/debug"

func MainModule() (string, bool) {
	info, ok := debug.ReadBuildInfo()
	if !ok {
		return "", false
	}
	return info.Main.Path, true
}
```

[cmd/l13/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l13/main.go)

```go
package main

import (
	"example.com/learn/go-advanced/provenance"
	"fmt"
)

func main() {
	path, ok := provenance.MainModule()
	if !ok {
		panic("build info unavailable")
	}
	fmt.Println(path)
}
```

Desde la raíz del repositorio:

```sh
cd code/go-advanced
go run ./cmd/l13
```

### Contrato de salida esperado

```text
example.com/learn/go-advanced
```

## Leer el contrato antes de cambiar el código

Antes de ejecutar, prediga el resultado e identifique la operación que vuelve observable cada valor. Siga la entrada desde el consumidor, pasando por copias y referencias, hasta su destino. Distinga el valor devuelto por una función de la duración de cualquier trabajo que lance. Cuando haya un error posible, identifique quién decide detenerse, reintentar o traducirlo. Imprimir un valor correcto solo cubre parte del contrato: también deben entenderse las entradas rechazadas y la terminación.

El listado es completo deliberadamente. Compárelo con su archivo de pruebas y nombre la aserción exacta que fallaría si cambiase el comportamiento. Una modificación exclusivamente interna debería conservar esas aserciones observables. Si cambia una frontera pública, describa la garantía modificada antes de editar. Este hábito se traslada bien desde C# y Java mientras mantiene explícitas las reglas de propiedad y sincronización de Go.

## Verificación y alcance

La salida mostrada constituye el contrato esperado del ejecutable, almacenado en `examples.json`. Reprodúzcala antes de considerarla una observación de su máquina. Las pruebas están escritas en el mismo módulo y la verificación central registra su ejecución real por separado. Ejemplos correctos no demuestran todos los sistemas operativos, cargas de producción o resultados de aprendizaje. Diagnósticos, perfiles y benchmarks describen experimentos hasta que el diario registre una medición. Conserve juntos versión, revisión y orden: una observación sin condiciones resulta difícil de reproducir.

## Ejercicios

1. ¿Una suma de comprobación verificada demuestra seguridad?

<details>
<summary>Solución completa</summary>

No. Demuestra coincidencia con contenido esperado. Revise código y avisos por separado, ejecute la herramienta adecuada cuando corresponda y registre su alcance y resultado real.

</details>

2. ¿Por qué imprimir la ruta del módulo en vez de una versión fija del compilador?

<details>
<summary>Solución completa</summary>

La ruta es estable para el ejemplo versionado y permite compararla exactamente. Compilador y revisión deben proceder del artefacto o la orden realmente ejecutada, no de una configuración supuesta.

</details>

## Fuentes primarias

- [Referencia de módulos](https://go.dev/ref/mod)
- [Orden Go](https://pkg.go.dev/cmd/go)
- [Gestión de vulnerabilidades de Go](https://go.dev/security/vuln)
- [runtime/debug.ReadBuildInfo](https://pkg.go.dev/runtime/debug#ReadBuildInfo)

[Lección siguiente](../14-service-capstone/) · [Diario de aprendizaje](../journal/)
