---
title: "7. Interfaces y composición"
description: "Usar satisfacción implícita y reconocer un puntero nil dentro de una interfaz."
sidebar:
  order: 7
---

## Objetivos de aprendizaje

Distinguir puntero nil e interfaz nil, razonar sobre métodos y definir interfaces pequeñas desde el consumidor.

## Expresar el comportamiento necesario

Una [interfaz](https://go.dev/ref/spec#Interface_types) describe comportamiento. Named exige Label devolviendo string; Record satisface el contrato sin declarar implements. Su tipo puntero también dispone del método con receptor valor. El consumidor expresa una necesidad pequeña sin imponer una clase base al productor. Funciona entre paquetes: una interfaz local puede aceptar un tipo existente que tú no diseñaste.

El lector posterior consume [io.Reader](https://pkg.go.dev/io#Reader), que abstrae leer bytes en lugar de nombrar por separado archivos, terminales y cadenas. Es útil porque el lector necesita esa operación y las pruebas pueden proporcionar lectores reales en memoria. Evita una interfaz que copie todos los métodos de un tipo concreto solo para parecerse al registro de servicios de C#. Empieza por las operaciones que el consumidor realmente utiliza.

## Una interfaz contiene más que un puntero

Un valor interfaz tiene tipo dinámico y valor dinámico. Solo es nil cuando ambos faltan. En el ejemplo, pointer es un *Record nil. Asignarlo a Named conserva ese tipo puntero como tipo dinámico, aunque el puntero sea nil. Por eso pointer es igual a nil y named no. La diferencia afecta a retornos de errores y dependencias opcionales.

El ejemplo evita llamar a named.Label. Label usa receptor valor; acceder a ese valor mediante un puntero nil requeriría desreferenciarlo. Que la interfaz no sea nil no garantiza una llamada segura. Para devolver ausencia de interfaz, devuelve nil directamente en la frontera en vez de convertir un puntero nil tipado. Las pruebas hacen observable la diferencia sin inventar errores de compilación ni citar diagnósticos de ejecución inestables.

## Componer sin heredar estado

La incorporación de estructuras puede promover métodos de un campo incorporado; la de interfaces reúne requisitos. No crea la misma relación de subtipo que la herencia de clases. La estructura contenedora conserva identidad y campos propios. Incorpora cuando la promoción exprese el comportamiento público deseado; utiliza un campo con nombre cuando el acceso deba ser explícito. También puedes componer sin incorporar nada.

Las interfaces C# y Java resultan familiares, pero sus implementaciones suelen declarar la relación. En Go es implícita y depende de los [conjuntos de métodos](https://go.dev/ref/spec#Method_sets). Un receptor puntero puede hacer que *T satisfaga una interfaz sin que T la satisfaga. La toma de dirección cómoda en una llamada directa sobre una variable local no cambia estas reglas. Elegir receptor forma parte del diseño de la API.

## Considerar la versión

Distingue las interfaces de comportamiento de las restricciones para parámetros de tipo. any es el alias de la interfaz vacía: permite almacenar valores, sin conceder operaciones del tipo oculto. Recuperar comportamiento concreto requiere una aserción o switch de tipos. En Go 1.27 los métodos concretos pueden declarar parámetros de tipo, pero los métodos de interfaces todavía no pueden hacerlo ni ser implementados por métodos genéricos. Ese límite describe la frontera de interfaces; no significa que Go carezca de métodos genéricos.

## Ejemplo explicado

Código completo: [`cmd/l07/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l07/main.go).

```go
package main

import (
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
)

type Named interface{ Label() string }

func main() {
	var pointer *study.Record
	var named Named = pointer
	value := study.Fixture()[0]
	fmt.Printf("pointer-nil=%t interface-nil=%t label=%s\n", pointer == nil, named == nil, value.Label())
}
```

Desde la raíz del repositorio:

```sh
cd code/go-for-csharp-java
go run ./cmd/l07
```

**Salida verificada — Go 1.27.1, Windows/amd64.**

```text
pointer-nil=true interface-nil=false label=types
```

## Leer, predecir y comprobar

Antes de ejecutar el programa, sigue cada valor desde su declaración hasta el resultado mostrado. Anota qué operación valida los datos y cuál solo transforma datos ya tipados. Ejecuta después el comando del repositorio y compara toda la salida, incluido el salto de línea final, con examples.json. Un ejemplo coincidente demuestra este conjunto de datos; las pruebas escritas cubren contratos adicionales. Cambia una sola entrada cada vez, explica la consecuencia y separa el experimento de los datos publicados. Así podrás diagnosticar un resultado inesperado sin cambiar silenciosamente lo que promete la lección.

## Ejercicios

1. ¿Por qué difieren pointer-nil e interface-nil?

<details>
<summary>Solución 1</summary>

pointer es un *Record nil, pero al asignarlo a Named conserva *Record como tipo dinámico. La interfaz no es por tanto la interfaz nil vacía. El ejemplo compara ambos sin invocar métodos sobre el destino nil. Para representar ausencia completa de Named, inicializa o devuelve la interfaz misma como nil.

</details>

2. ¿Qué debe aceptar Load para admitir archivos y cadenas?

<details>
<summary>Solución 2</summary>

io.Reader, como ya hace el código del repositorio. Tanto un archivo como strings.NewReader proporcionan lectura. La interpretación queda en Load y la adquisición en quien llama. No hace falta duplicar el lector ni crear una interfaz de aplicación amplia: el pequeño contrato de bytes expresa la dependencia real.

</details>

## Fuentes oficiales

- [Tipos interfaz](https://go.dev/ref/spec#Interface_types)
- [Conjuntos de métodos](https://go.dev/ref/spec#Method_sets)
- [io.Reader](https://pkg.go.dev/io#Reader)
- [Cambios del lenguaje en Go 1.27](https://go.dev/doc/go1.27#language)

[Siguiente lección](../08-errors-defer-and-resources/) · [Diario](../journal/)
