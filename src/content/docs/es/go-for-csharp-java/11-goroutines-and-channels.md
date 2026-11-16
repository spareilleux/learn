---
title: "11. Goroutines y canales"
description: "Transmitir registros con cierre bajo propiedad y envíos cancelables."
sidebar:
  order: 11
---

## Objetivos de aprendizaje

Seguir un intercambio sin búfer, asignar responsabilidad de cierre y ofrecer cancelación a un emisor bloqueado.

## La concurrencia necesita una vida definida

Una [instrucción go](https://go.dev/ref/spec#Go_statements) inicia una función en una goroutine. No devuelve un futuro que se reúna automáticamente. Quien llama debe decidir cómo termina el trabajo, cómo comunica fallos y cómo la cancelación detiene lo abandonado. Stream inicia un productor y devuelve un canal solo de recepción. El comando consume hasta su cierre, estableciendo terminación explícita sin pausas ni suposiciones sobre la velocidad de otra goroutine.

Un [canal](https://go.dev/ref/spec#Channel_types) transfiere valores entre goroutines. El canal sin búfer de Stream exige que cada envío correcto encuentre un receptor. No almacena una acumulación arbitraria. Un canal con búfer permite un número acotado de valores pendientes. Su capacidad cambia planificación y contrapresión, pero no sustituye una política de terminación. Elige el búfer para expresar un límite real, no para ocultar un productor que nadie consumirá.

## Poseer la operación de cierre

El productor crea el canal y difiere close antes de enviar. Solo él sabe cuándo no quedan valores. El consumidor recorre el canal hasta que está cerrado y vacío. Los receptores no deben cerrarlo solo porque quieran dejar de leer: el emisor puede continuar escribiendo. Cerrar dos veces o enviar después del cierre es un error de programación; la propiedad debe resultar visible en la estructura.

Stream devuelve un canal solo de recepción. Esa referencia impide enviar o cerrar desde el consumidor. El tipo documenta la dirección y permite comprobar parte del contrato. Los Record enviados son copias. Sus campos actuales pueden leerse independientemente tras el intercambio, pero enviar estructuras con punteros o mapas no copiaría profundamente ese almacenamiento.

## Cancelar también las operaciones bloqueadas

El [select](https://go.dev/ref/spec#Select_statements) de Stream espera un receptor o la cancelación del contexto. Un envío simple podría quedar bloqueado si quien llama deja de consumir. Seleccionar el canal de cancelación ofrece una salida. El comando posee cancel y lo difiere: abandonar la operación por retorno normal puede liberar al productor. Un contexto no termina código arbitrario por la fuerza; la operación debe observarlo.

Si varios casos están listos, no se garantiza que gane cancelación en cada selección. No prometas que impide todo último valor cercano a su observación. Count comprueba cancelación antes de empezar y al finalizar el flujo; ese contrato difiere de afirmar que nunca circula un valor alrededor de la cancelación. Las pruebas utilizan cancelación explícita y terminación de canales, sin pausas para establecer el orden.

## Relacionarlo con tareas e hilos

[C# Task](https://learn.microsoft.com/dotnet/api/system.threading.tasks.task) y los [hilos virtuales Java](https://docs.oracle.com/en/java/javase/25/core/virtual-threads.html) ayudan a imaginar trabajo independiente, pero goroutines y canales tienen semántica propia. El [modelo de memoria Go](https://go.dev/ref/mem) define relaciones de sincronización para los canales. Iniciar una goroutine no vuelve seguras las escrituras compartidas. El ejemplo evita un acumulador compartido: solo suma el consumidor. Los cuarenta esperados no dependen de cómo se intercalen los intercambios.

## Ejemplo explicado

Código completo: [`cmd/l11/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l11/main.go).

```go
package main

import (
	"context"
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
)

func main() {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	var total study.Minutes
	for record := range study.Stream(ctx, study.Fixture()) {
		total += record.Minutes
	}
	fmt.Printf("stream-total=%d\n", total)
}
```

Desde la raíz del repositorio:

```sh
cd code/go-for-csharp-java
go run ./cmd/l11
```

**Salida verificada — Go 1.27.1, Windows/amd64.**

```text
stream-total=40
```

## Leer, predecir y comprobar

Antes de ejecutar el programa, sigue cada valor desde su declaración hasta el resultado mostrado. Anota qué operación valida los datos y cuál solo transforma datos ya tipados. Ejecuta después el comando del repositorio y compara toda la salida, incluido el salto de línea final, con examples.json. Un ejemplo coincidente demuestra este conjunto de datos; las pruebas escritas cubren contratos adicionales. Cambia una sola entrada cada vez, explica la consecuencia y separa el experimento de los datos publicados. Así podrás diagnosticar un resultado inesperado sin cambiar silenciosamente lo que promete la lección.

## Ejercicios

1. ¿Puede el consumidor cerrar después de recibir un registro?

<details>
<summary>Solución 1</summary>

No. El productor puede enviar el segundo, así que cerrarlo violaría la propiedad. Para abandonar, el consumidor cancela el contexto que posee y retorna. El productor observa cancelación mediante select y cierra su propio canal al salir.

</details>

2. ¿Por qué un búfer de dos no soluciona toda fuga de productores?

<details>
<summary>Solución 2</summary>

Solo permite terminar los dos envíos de este ejemplo sin receptor inmediato. Una fuente mayor puede llenar el búfer y bloquearse. La solución duradera acota la vida: la cancelación deja salir al productor bloqueado; consumo y cierre definen la terminación normal. Capacidad y cancelación resuelven problemas distintos.

</details>

## Fuentes oficiales

- [Instrucciones go](https://go.dev/ref/spec#Go_statements)
- [Tipos canal](https://go.dev/ref/spec#Channel_types)
- [Instrucciones select](https://go.dev/ref/spec#Select_statements)
- [Modelo de memoria Go](https://go.dev/ref/mem)

[Siguiente lección](../12-http-and-context/) · [Diario](../journal/)
