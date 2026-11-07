---
title: "5. Mapas y estructuras"
description: "Modelar registros como valores y distinguir ausencia y cero."
sidebar:
  order: 5
---

## Objetivos de aprendizaje

Utilizar literales con nombres de campo, agregar en un mapa y distinguir una clave ausente de un cero almacenado.

## Nombrar los datos antes de elegir la colección

Una [estructura](https://go.dev/ref/spec#Struct_types) agrupa campos con nombre. Record contiene Name y Minutes: su literal describe una sesión en lugar de una pareja anónima. Los literales con campos nombrados hacen visible la relación y toleran mejor su reordenación. Los campos con mayúscula inicial son exportados; sus etiquetas JSON indican los nombres externos. Una etiqueta es metadato, no una regla de validez. Load aplicará las reglas del dominio después de decodificar.

Asignar una estructura copia sus campos. Se parece más a un tipo valor de C# que a suponer que todo objeto de datos Java tiene identidad por referencia. La copia puede conservar referencias compartidas si contiene mapas, punteros o slices. Los campos actuales evitan ese almacenamiento mutable anidado. Una estructura no crea herencia, constructores ni accesores automáticos. Las funciones y métodos proporcionan el comportamiento necesario.

## Agregar con una regla explícita de ausencia

Un [mapa](https://go.dev/ref/spec#Map_types) asocia claves y valores. El comando reserva un mapa de string a Minutes y suma cada duración al total de su nombre. Leer una clave ausente devuelve el valor cero del tipo asociado. La primera aparición empieza en cero; las siguientes añaden al total existente. Una lectura con dos destinos también devuelve un booleano de presencia que distingue un cero almacenado de un nombre ausente.

El ejemplo lee una clave conocida y otra ausente. No imprime todo el mapa porque su orden de iteración no está especificado. Un informe estable debe conservar el orden de entrada u ordenar las claves explícitamente. El proyecto final mantiene el orden del slice. El formato determinista es una decisión de comportamiento; un mapa por sí solo no lo garantiza.

## Mutación y propiedad

Un mapa nil admite lecturas y consultas de longitud, pero no nuevas entradas. Resérvalo con [`make`](https://pkg.go.dev/builtin#make) antes de escribir. Asignar un valor mapa comparte su almacenamiento; no clona las entradas. [`delete`](https://pkg.go.dev/builtin#delete) elimina una clave y no causa problemas si no existe. La modificación concurrente sin sincronización es otro problema: usar un mapa no vuelve seguro su acceso desde varias goroutines.

Una entrada que contiene una estructura se recupera como valor. Para modificarla, recupera una copia local, cámbiala y vuelve a asignarla a la entrada. Un mapa de punteros comparte intencionalmente registros mutables, con otro contrato de propiedad. No elijas punteros solo para facilitar llamadas a métodos. Decide primero si dos lectores deben observar la misma modificación.

## Comparar el contrato de consulta

[C# Dictionary.TryGetValue](https://learn.microsoft.com/dotnet/api/system.collections.generic.dictionary-2.trygetvalue) hace explícita la presencia, igual que la consulta Go con dos resultados. [Java Map.get](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/Map.html#get(java.lang.Object)) suele utilizar null para la ausencia, con distinciones adicionales en mapas que permiten valores null. En Go, cero es un valor Minutes legítimo: comprobar solo el número pierde información. El booleano responde si existe la clave, independientemente del dominio numérico.

## Ejemplo explicado

Código completo: [`cmd/l05/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l05/main.go).

```go
package main

import (
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
)

func main() {
	totals := make(map[string]study.Minutes)
	for _, record := range study.Fixture() {
		totals[record.Name] += record.Minutes
	}
	minutes, present := totals["missing"]
	fmt.Printf("go=%d missing=%d present=%t\n", totals["go"], minutes, present)
}
```

Desde la raíz del repositorio:

```sh
cd code/go-for-csharp-java
go run ./cmd/l05
```

**Salida verificada — Go 1.27.1, Windows/amd64.**

```text
go=25 missing=0 present=false
```

## Leer, predecir y comprobar

Antes de ejecutar el programa, sigue cada valor desde su declaración hasta el resultado mostrado. Anota qué operación valida los datos y cuál solo transforma datos ya tipados. Ejecuta después el comando del repositorio y compara toda la salida, incluido el salto de línea final, con examples.json. Un ejemplo coincidente demuestra este conjunto de datos; las pruebas escritas cubren contratos adicionales. Cambia una sola entrada cada vez, explica la consecuencia y separa el experimento de los datos publicados. Así podrás diagnosticar un resultado inesperado sin cambiar silenciosamente lo que promete la lección.

## Ejercicios

1. ¿Cómo distingues go almacenado con cero minutos de una clave ausente?

<details>
<summary>Solución 1</summary>

Recupera ambos resultados. La clave go devuelve cero y true; una ausente devuelve cero y false. El número por sí solo no permite distinguirlas. Por eso el ejemplo imprime el booleano de presencia junto al valor ausente, en lugar de tratar automáticamente cero como un error.

</details>

2. Dos sesiones go duran diez y quince minutos. ¿Qué debe producir la agregación?

<details>
<summary>Solución 2</summary>

El mapa debe contener veinticinco para go. La primera suma empieza en el cero de la clave ausente; la segunda añade quince a diez. Conserva el mapa reservado y el += de main. Para imprimir varios nombres de forma reproducible, ordena sus claves o mantén una lista ordenada aparte.

</details>

## Fuentes oficiales

- [Tipos mapa](https://go.dev/ref/spec#Map_types)
- [Tipos estructura](https://go.dev/ref/spec#Struct_types)
- [Indexación de mapas](https://go.dev/ref/spec#Index_expressions)

[Siguiente lección](../06-pointers-and-methods/) · [Diario](../journal/)
