---
title: "1. Herramientas y módulos"
description: "Crear un módulo reproducible y entender paquetes, importaciones y puntos de entrada."
sidebar:
  order: 1
---

## Objetivos de aprendizaje

Localizar la raíz de un módulo, distinguir paquete y módulo y ejecutar un comando del repositorio sin cambiar sus dependencias.

## Un ejecutable pequeño antes de un framework

[Go](https://go.dev/doc/) incluye compilador, formateador, ejecutor de pruebas y un comando que entiende los módulos. Empieza por las instrucciones oficiales de instalación para tu sistema y después utiliza los mismos comandos en Windows, Linux/WSL y macOS. El curso se dirige a Go 1.27; el coordinador identificó Go 1.27.1 en Windows. Ese dato describe el entorno y no demuestra que los ejemplos recién escritos hayan pasado. El primer resultado será un programa que importe datos locales y muestre una línea estable.

Un módulo es una colección de paquetes con versión. Su raíz contiene [`go.mod`](https://go.dev/ref/mod#go-mod-file), cuya directiva module proporciona el prefijo utilizado por los imports. Aquí es example.com/learn/go-for-csharp-java. Es un identificador educativo: importar los paquetes del mismo módulo no necesita ninguna petición a example.com. Un paquete suele reunir los archivos Go de un directorio. La cláusula package nombra su unidad de compilación; la ruta de importación identifica dónde está. Varios directorios ejecutables pueden compartir módulo y paquetes internos.

## Leer el proyecto desde fuera hacia dentro

El primer comando está en cmd/l01/main.go. El paquete main y una función llamada main definen un ejecutable. La importación de internal/study une el prefijo del módulo y un directorio. Una inicial mayúscula exporta un identificador; por eso main puede llamar a Fixture y leer Course. Las declaraciones con inicial minúscula quedan accesibles dentro de su paquete. El directorio internal también limita qué paquetes pueden importarlo: es una frontera de visibilidad comprobada por las herramientas.

Ejecuta los comandos desde code/go-for-csharp-java, no desde la raíz del repositorio. El archivo go.mod ya existe: no ejecutes go mod init sobre él. go run compila y ejecuta el paquete solicitado; sus artefactos de compilación no equivalen a publicar un binario. go build produce artefactos, mientras que go test construye y ejecuta las pruebas. El formato con [`gofmt`](https://pkg.go.dev/cmd/gofmt) es otra operación determinista. Estas diferencias serán necesarias al probar las entradas del CLI: que compile no demuestra que procese correctamente los datos.

## Aprovechar lo que sabes de compilación

Un proyecto C# y un descriptor de compilación Java agrupan responsabilidades que Go distribuye entre convenciones de directorios, go.mod y el comando go. No busques una clase Program ni un objeto aplicación. El inicio es una función del paquete main. Tampoco se declara un namespace alrededor de cada elemento. La importación no significa descargar el paquete cada vez que arranca el ejecutable; participa en la compilación y en la resolución de módulos.

El curso utiliza solamente la biblioteca estándar; no hay dependencias externas que instalar. La directiva go declara la versión de lenguaje y el requisito mínimo de herramientas del módulo; no afirma que el compilador activo tenga exactamente esa revisión. La selección de herramientas puede obtener una versión más reciente si está configurada para hacerlo. Comprueba el entorno antes de interpretar comportamientos que dependen de la versión. Go 1.27 cambia algunas reglas del lenguaje y de las bibliotecas, así que un tutorial antiguo puede discrepar del compilador actual.

## Seguir la dependencia en vez de copiar archivos

El programa llama a Fixture, que devuelve dos registros, y muestra su cantidad. Sigue el import hasta internal/study/study.go y localiza tanto la constante como la función. Este recorrido conecta ejecutable, paquete local, datos tipados y salida visible. Las próximas lecciones sustituirán el conteo por selección, lectura de JSON e informes. Conserva esa relación entre paquetes cuando experimentes. Copiar el auxiliar en cada comando ocultaría si el proyecto final utiliza realmente los comportamientos estudiados antes.

Un error habitual es ejecutar un solo archivo cuando el ejemplo necesita varios archivos del paquete. Prefiere la ruta de paquete indicada abajo. Otro es cambiar la directiva module sin actualizar los imports. Ambas escrituras forman un contrato. Por último, una importación relativa escrita como una ruta al directorio padre no es la manera de referirse aquí a los paquetes propios. Usa el prefijo del módulo y conserva la estructura de directorios.

## Ejemplo explicado

Código completo: [`cmd/l01/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l01/main.go).

```go
package main

import (
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
)

func main() {
	fmt.Printf("module=%s records=%d\n", study.Course, len(study.Fixture()))
}
```

Desde la raíz del repositorio:

```sh
cd code/go-for-csharp-java
go run ./cmd/l01
```

**Salida verificada — Go 1.27.1, Windows/amd64.**

```text
module=study-log records=2
```

## Leer, predecir y comprobar

Antes de ejecutar el programa, sigue cada valor desde su declaración hasta el resultado mostrado. Anota qué operación valida los datos y cuál solo transforma datos ya tipados. Ejecuta después el comando del repositorio y compara toda la salida, incluido el salto de línea final, con examples.json. Un ejemplo coincidente demuestra este conjunto de datos; las pruebas escritas cubren contratos adicionales. Cambia una sola entrada cada vez, explica la consecuencia y separa el experimento de los datos publicados. Así podrás diagnosticar un resultado inesperado sin cambiar silenciosamente lo que promete la lección.

## Ejercicios

1. ¿Por qué funciona sin contactar con example.com?

<details>
<summary>Solución 1</summary>

La importación se resuelve dentro del módulo actual porque su prefijo coincide con go.mod. El nombre con forma de dominio identifica el módulo; no solicita contactar con una web durante la ejecución. La dependencia es el paquete internal/study del repositorio. El manifiesto espera dos registros porque Fixture construye exactamente dos valores.

</details>

2. ¿Cómo añadir otro comando sin duplicar los datos?

<details>
<summary>Solución 2</summary>

Crea otro subdirectorio de cmd, declara package main, importa example.com/learn/go-for-csharp-java/internal/study y llama a study.Fixture desde main. El programa l01 es un patrón completo. Conserva go.mod y el paquete compartido. Solo cambia el directorio ejecutable: no necesitas otro módulo ni otra dependencia.

</details>

## Fuentes oficiales

- [Tutorial de módulos Go](https://go.dev/doc/tutorial/create-module)
- [Comando go](https://pkg.go.dev/cmd/go)
- [Referencia de módulos](https://go.dev/ref/mod)

[Siguiente lección](../02-values-types-and-strings/) · [Diario](../journal/)
