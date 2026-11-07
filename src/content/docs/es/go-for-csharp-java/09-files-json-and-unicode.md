---
title: "9. Archivos, JSON y Unicode"
description: "Separar adquisición de archivos, validez de bytes, decodificación JSON y validación del dominio."
sidebar:
  order: 9
---

## Objetivos de aprendizaje

Leer mediante un sistema de archivos abstracto, decodificar valores tipados y distinguir codificación, sintaxis y reglas de dominio.

## Cuatro fronteras, cuatro preguntas

Una ruta, unos bytes, un valor JSON y un registro válido son cosas diferentes. [fs.ReadFile](https://pkg.go.dev/io/fs#ReadFile) obtiene bytes de un sistema de archivos. [utf8.Valid](https://pkg.go.dev/unicode/utf8#Valid) comprueba su codificación. [json.Unmarshal](https://pkg.go.dev/encoding/json#Unmarshal) los decodifica en un destino tipado. El bucle final impone reglas del dominio. Mezclar esos pasos dificulta explicar fallos: un archivo legible puede contener JSON inválido y un JSON válido puede describir una sesión inválida.

El comando usa [fstest.MapFS](https://pkg.go.dev/testing/fstest#MapFS), un sistema de archivos en memoria de la biblioteca estándar. Evita depender del directorio actual o de separadores específicos del sistema operativo. records.json se interpreta dentro de ese sistema. fs.ReadFile también admite otras implementaciones de fs.FS. El CLI abrirá un archivo real elegido por el usuario; comparte el intérprete sin fingir que el ejemplo en memoria demuestra permisos de disco y rutas en todas las plataformas.

## Definir la forma decodificada

Load decodifica un array de Record con etiquetas name y minutes. Rechaza null porque el curso exige un array, pero acepta un array vacío. Los nombres ausentes o vacíos y las duraciones negativas fallan en validación del dominio. Los minutos ausentes reciben cero en este modelo, y cero está permitido. Aquí no se garantiza un esquema estricto frente a campos desconocidos. Un contrato de intercambio que lo exigiera necesitaría una política explícita de decodificación y sus pruebas.

El lector carga toda la entrada antes de decodificar. Es sencillo para un pequeño registro local, pero no es un analizador en flujo acotado para grandes cargas no fiables. No lo anuncies como tal. El curso avanzado trata flujos y delimitación por separado. Sumar enteros arbitrariamente grandes también puede desbordarse; los pequeños ejemplos y el CLI no establecen un contrato financiero o contable.

## Validez Unicode y anchura visual

La comprobación UTF-8 rechaza codificaciones inválidas antes del análisis. No normaliza el texto ni establece límites de caracteres visibles. café sigue teniendo cinco bytes y cuatro runas. Un acento descompuesto puede cambiar la cantidad de runas y mostrarse de forma parecida. Conservamos los nombres recibidos porque el contrato no solicita normalización lingüística. Valida exactamente lo prometido y separa los aspectos de presentación.

En C# reconocerás [System.Text.Json](https://learn.microsoft.com/dotnet/standard/serialization/system-text-json/overview); Java dispone de varias bibliotecas JSON del ecosistema en lugar de una característica equivalente del lenguaje. Go ofrece codificador y decodificador estándar, pero su comportamiento depende de la versión. Go 1.27 cambia implementaciones JSON predeterminadas. Usamos las API concretas de encoding/json enlazadas y probamos las entradas del curso sin convertir suposiciones antiguas en una garantía universal de compatibilidad.

## Seguir todo el ejemplo

El ejemplo lee Sample mediante el sistema de archivos, crea un [`io.Reader`](https://pkg.go.dev/io#Reader) sobre los bytes y llama al mismo Load del CLI. Luego muestra dos registros y una medición Unicode independiente. Los errores sintácticos siguen siendo errores; las pruebas escritas cubren texto malformado, contenido adicional y UTF-8 inválido. La salida del camino correcto por sí sola no demostraría esos contratos de rechazo.

## Ejemplo explicado

Código completo: [`cmd/l09/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l09/main.go).

```go
package main

import (
	"bytes"
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
	"io/fs"
	"testing/fstest"
	"unicode/utf8"
)

func main() {
	disk := fstest.MapFS{"records.json": {Data: []byte(study.Sample)}}
	data, err := fs.ReadFile(disk, "records.json")
	if err != nil {
		panic(err)
	}
	records, err := study.Load(bytes.NewReader(data))
	if err != nil {
		panic(err)
	}
	fmt.Printf("records=%d bytes=%d runes=%d\n", len(records), len("café"), utf8.RuneCountInString("café"))
}
```

Desde la raíz del repositorio:

```sh
cd code/go-for-csharp-java
go run ./cmd/l09
```

**Salida verificada — Go 1.27.1, Windows/amd64.**

```text
records=2 bytes=5 runes=4
```

## Leer, predecir y comprobar

Antes de ejecutar el programa, sigue cada valor desde su declaración hasta el resultado mostrado. Anota qué operación valida los datos y cuál solo transforma datos ya tipados. Ejecuta después el comando del repositorio y compara toda la salida, incluido el salto de línea final, con examples.json. Un ejemplo coincidente demuestra este conjunto de datos; las pruebas escritas cubren contratos adicionales. Cambia una sola entrada cada vez, explica la consecuencia y separa el experimento de los datos publicados. Así podrás diagnosticar un resultado inesperado sin cambiar silenciosamente lo que promete la lección.

## Ejercicios

1. ¿Deben significar lo mismo null y un array JSON vacío?

<details>
<summary>Solución 1</summary>

No. El curso exige un array JSON: null produce un slice nil y Load lo rechaza con ErrInvalid. Un array vacío es válido y suma cero. Es una política de aplicación, no una afirmación de que null sea JSON inválido. La prueba del lector cubre explícitamente ambas entradas.

</details>

2. ¿Dónde validarías un nombre de sesión vacío?

<details>
<summary>Solución 2</summary>

Después de decodificar a Record, en el bucle de validación del dominio existente. El decodificador establece el tipo sin demostrar que el contenido tenga sentido. La condición actual comprueba Name vacío y Minutes negativo, envolviendo ErrInvalid con el índice y manteniendo la distinción frente a fallos de lectura y sintaxis.

</details>

## Fuentes oficiales

- [fs.ReadFile](https://pkg.go.dev/io/fs#ReadFile)
- [json.Unmarshal](https://pkg.go.dev/encoding/json#Unmarshal)
- [utf8.Valid](https://pkg.go.dev/unicode/utf8#Valid)
- [Cambios de bibliotecas en Go 1.27](https://go.dev/doc/go1.27#library)

[Siguiente lección](../10-generics-and-collections/) · [Diario](../journal/)
