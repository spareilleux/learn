---
title: "3. Control de flujo y funciones"
description: "Escribir transformaciones explícitas con bucles, retornos múltiples y funciones pequeñas."
sidebar:
  order: 3
---

## Objetivos de aprendizaje

Seguir un bucle de selección, distinguir declaración y asignación y elegir una frontera de función clara.

## Hacer visible la transformación

Las [instrucciones de control](https://go.dev/ref/spec#Statements) permiten expresar directamente la regla del registro: conservar las sesiones que alcanzan una duración mínima y sumar sus minutos. Empieza por un bucle sencillo antes de crear una cadena fluida. El comando delega selección y suma en dos funciones pequeñas. Sus nombres responden a preguntas diferentes y el slice seleccionado es un valor intermedio normal que puedes inspeccionar o probar por separado.

Solo existe una palabra para los bucles: for. Admite condición, inicialización y actualización, repetición incondicional o range sobre un valor compatible. En nuestro slice, range proporciona índice y valor del elemento. Descartamos el índice con el identificador vacío. El elemento es una copia de Record. Leer Minutes resulta directo; modificar la copia no reescribe el elemento original. La siguiente lección explicará cuándo el almacenamiento compartido cambia esa situación.

## Seguir las ramas y los retornos

Select reserva un resultado inicialmente vacío y añade cada registro que satisface una comparación inclusiva. Con quince y veinticinco minutos, un mínimo de veinte conserva solo el segundo. El orden de entrada se mantiene porque el bucle añade en el orden encontrado. Total empieza con el valor cero de Minutes y suma cada valor seleccionado. Una entrada vacía produce cero sin una rama especial. Estas decisiones observables son el comportamiento público que deben verificar las pruebas.

Las condiciones Go no necesitan paréntesis, pero sus cuerpos utilizan llaves. Un if puede introducir una variable antes de la condición; después usaremos esa forma con errores. Mantén su ámbito pequeño para que se vea qué operación la produjo. Una declaración corta debe introducir al menos una variable nueva no vacía en el ámbito actual. Dentro de otro bloque puede crear una variable diferente en lugar de actualizar la que pretendías.

Las [funciones](https://go.dev/ref/spec#Function_declarations) pueden devolver varios valores. Usaremos un valor y un error para los fallos habituales en lugar de ocultarlos tras excepciones. Los parámetros pasan por valor; copiar un puntero o descriptor de slice conserva acceso a datos compartidos. Por tanto, pasar por valor no promete aislamiento profundo. Una función también puede almacenarse o pasarse a otra función. La lección diez aprovechará esa capacidad sin introducir una jerarquía de clases.

## Traducir los hábitos conocidos

Quien viene de C# quizá piense en [Enumerable.Where](https://learn.microsoft.com/dotnet/api/system.linq.enumerable.where); quien viene de Java, en [Stream.filter](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/Stream.html#filter(java.util.function.Predicate)). Nuestro bucle se ejecuta inmediatamente y devuelve un slice materializado. No crea una consulta diferida y recorrer el resultado otra vez no repite el predicado. Esto importa si cambian los datos o el predicado tiene efectos. Aquí la comparación es pura y el resultado puede reutilizarse.

Un switch sin expresión permite organizar condiciones ordenadas, y los casos normales no continúan automáticamente en el siguiente. Úsalo cuando aclare una elección real, sin sustituir todos los if. Dos funciones no necesitan reproducir un framework empresarial. La frontera actual basta: Select filtra y Total suma. Ninguna imprime, interpreta argumentos ni abre archivos. Así pueden reutilizarse en las fronteras HTTP y CLI posteriores.

## Interpretar el resultado

El ejemplo selecciona un elemento, pero suma veinticinco minutos. Contar y sumar son mediciones diferentes. Cambia mentalmente el umbral a quince y sigue ambos registros: se conservarían los dos y sumarían cuarenta. Con veinticinco, la comparación sigue incluyendo el segundo. Esa frontera es precisamente donde una comparación estricta accidental produciría un informe plausible pero incorrecto.

## Ejemplo explicado

Código completo: [`cmd/l03/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l03/main.go).

```go
package main

import (
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
)

func main() {
	records := study.Select(study.Fixture(), 20)
	fmt.Printf("selected=%d total=%d\n", len(records), study.Total(records))
}
```

Desde la raíz del repositorio:

```sh
cd code/go-for-csharp-java
go run ./cmd/l03
```

**Salida verificada — Go 1.27.1, Windows/amd64.**

```text
selected=1 total=25
```

## Leer, predecir y comprobar

Antes de ejecutar el programa, sigue cada valor desde su declaración hasta el resultado mostrado. Anota qué operación valida los datos y cuál solo transforma datos ya tipados. Ejecuta después el comando del repositorio y compara toda la salida, incluido el salto de línea final, con examples.json. Un ejemplo coincidente demuestra este conjunto de datos; las pruebas escritas cubren contratos adicionales. Cambia una sola entrada cada vez, explica la consecuencia y separa el experimento de los datos publicados. Así podrás diagnosticar un resultado inesperado sin cambiar silenciosamente lo que promete la lección.

## Ejercicios

1. ¿Qué ocurre con un mínimo de veinticinco y con uno de veintiséis?

<details>
<summary>Solución 1</summary>

La comparación inclusiva mantiene el registro de veinticinco minutos en el primer umbral: un elemento y veinticinco minutos. Con veintiséis no queda ninguno; la longitud es cero y Total devuelve su acumulador cero. No hace falta una rama especial para tratar la entrada vacía.

</details>

2. ¿Dónde deben ir la lectura de argumentos y el formato de salida?

<details>
<summary>Solución 2</summary>

Fuera de Select y Total. El paquete CLI transforma las opciones en un umbral Minutes, llama a Select y formatea los registros y su Total. La función Select completa de abajo muestra el núcleo reutilizable: recibe datos tipados y devuelve datos tipados, permitiendo probar la frontera sin una terminal.

</details>

## Fuentes oficiales

- [Instrucciones for](https://go.dev/ref/spec#For_statements)
- [Declaraciones de funciones](https://go.dev/ref/spec#Function_declarations)
- [Instrucciones if](https://go.dev/ref/spec#If_statements)

[Siguiente lección](../04-arrays-and-slices/) · [Diario](../journal/)
