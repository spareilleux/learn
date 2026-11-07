---
title: "8. Errores, defer y recursos"
description: "Conservar la identidad de errores, añadir contexto y liberar recursos propios."
sidebar:
  order: 8
---

## Objetivos de aprendizaje

Distinguir fallos de entrada y de programación, reconocer causas envueltas y colocar limpieza tras la adquisición.

## El fallo forma parte del resultado

La [interfaz error](https://pkg.go.dev/builtin#error) describe un valor con método Error. Una función suele devolver un valor útil y un error; quien llama comprueba el error antes de utilizar el valor. Load devuelve registros solo tras completar lectura, decodificación y validación. Los datos de usuario malformados son un fallo ordinario de esa operación. Deben comunicarse al llamador sin terminar el proceso dentro de un paquete reutilizable.

El comando carga los datos conocidos y después envía deliberadamente un nombre vacío. La primera operación debe sumar cuarenta minutos. La segunda debe producir un error vinculado a ErrInvalid. El panic ante un fallo inesperado del conjunto fijo queda limitado a la suposición inicial del comando educativo; Load no provoca panic por entradas inválidas. El CLI transformará ese mismo error en diagnóstico y estado de salida no cero.

## Añadir contexto conservando la causa

[fmt.Errorf](https://pkg.go.dev/fmt#Errorf), con el formato de envoltura, añade ubicación útil conservando el error subyacente. Load identifica el índice del registro y envuelve ErrInvalid. [errors.Is](https://pkg.go.dev/errors#Is) reconoce esa causa a través del contexto añadido. Comparar todo el mensaje convertiría cambios de redacción en rupturas de compatibilidad. Comparar solo el error exterior por igualdad perdería la sentinela envuelta.

No todo fallo es ErrInvalid. Un error de lectura conserva su causa; los errores de sintaxis y tipo JSON mantienen información del decodificador. Decide qué distinciones necesita quien llama. Una sentinela identifica una categoría; un tipo concreto y [`errors.As`](https://pkg.go.dev/errors#As) pueden exponer detalles estructurados si existe un consumidor real. No añadas una taxonomía para imitar excepciones. Las pruebas verifican tanto identidad de validación como preservación de un error de lectura real.

## Limpiar después de adquirir

Una [instrucción defer](https://go.dev/ref/spec#Defer_statements) programa una llamada al retornar la función actual. Registra limpieza después de que la adquisición tenga éxito. En el CLI, [`os.Open`](https://pkg.go.dev/os#Open) devuelve archivo y error; solo la rama exitosa difiere [File.Close](https://pkg.go.dev/os#File.Close). Los argumentos se evalúan al ejecutar defer; las llamadas diferidas se ejecutan en orden inverso. Un defer dentro de un bucle largo espera al retorno de la función: reduce la vida del recurso mediante una función menor si hace falta.

Cerrar un archivo de entrada libera un recurso; no implica poseer la entrada estándar del llamador. El CLI cierra los archivos que abre y deja la vida del lector recibido a su propietario. En archivos de salida, Close puede informar de un fallo significativo y debe formar parte del éxito de escritura. El proyecto solo abre entradas y comprueba sus escrituras: no implementa sustitución durable de archivos.

## Trasladar el control, no la sintaxis

[C# using](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/using) y [Java try-with-resources](https://docs.oracle.com/javase/tutorial/essential/exceptions/tryResourceClose.html) relacionan limpieza y una construcción léxica. Go defer la relaciona con el retorno de una función. Los errores normales también se devuelven explícitamente, sin desenrollar automáticamente la pila. Cada decisión es visible, pero exige comprobar los resultados relevantes. Descartar un error con el identificador vacío pierde información deliberadamente; no equivale a gestionarlo con éxito.

## Ejemplo explicado

Código completo: [`cmd/l08/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l08/main.go).

```go
package main

import (
	"errors"
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
	"strings"
)

func main() {
	records, err := study.Load(strings.NewReader(study.Sample))
	if err != nil {
		panic(err)
	}
	_, invalid := study.Load(strings.NewReader(`[{"name":"","minutes":1}]`))
	fmt.Printf("total=%d invalid=%t\n", study.Total(records), errors.Is(invalid, study.ErrInvalid))
}
```

Desde la raíz del repositorio:

```sh
cd code/go-for-csharp-java
go run ./cmd/l08
```

**Salida verificada — Go 1.27.1, Windows/amd64.**

```text
total=40 invalid=true
```

## Leer, predecir y comprobar

Antes de ejecutar el programa, sigue cada valor desde su declaración hasta el resultado mostrado. Anota qué operación valida los datos y cuál solo transforma datos ya tipados. Ejecuta después el comando del repositorio y compara toda la salida, incluido el salto de línea final, con examples.json. Un ejemplo coincidente demuestra este conjunto de datos; las pruebas escritas cubren contratos adicionales. Cambia una sola entrada cada vez, explica la consecuencia y separa el experimento de los datos publicados. Así podrás diagnosticar un resultado inesperado sin cambiar silenciosamente lo que promete la lección.

## Ejercicios

1. ¿Por qué usar errors.Is en lugar de comparar el texto?

<details>
<summary>Solución 1</summary>

Load añade contexto como el índice del registro; el error exterior no es directamente la sentinela. errors.Is sigue la envoltura y reconoce ErrInvalid. Comparar texto dependería de la redacción y puntuación. La prueba de validación demuestra el contrato sin prometer un diagnóstico exacto a los usuarios.

</details>

2. ¿Quién cierra un archivo entregado a Load y dónde va defer?

<details>
<summary>Solución 2</summary>

El llamador que abre correctamente el archivo es quien debe cerrarlo. Load recibe io.Reader y no puede suponer que sea un archivo ni poseer su vida. En cli.Run, defer sigue a la rama exitosa de os.Open. Un retorno anticipado por fallo de interpretación también ejecuta ese cierre diferido.

</details>

## Fuentes oficiales

- [errors.Is](https://pkg.go.dev/errors#Is)
- [fmt.Errorf](https://pkg.go.dev/fmt#Errorf)
- [Instrucciones defer](https://go.dev/ref/spec#Defer_statements)
- [File.Close](https://pkg.go.dev/os#File.Close)

[Siguiente lección](../09-files-json-and-unicode/) · [Diario](../journal/)
