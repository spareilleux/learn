---
title: "13. Pruebas"
description: "Verificar contratos observables con tablas, ejemplos, pruebas HTTP y un objetivo de fuzzing acotado."
sidebar:
  order: 13
---

## Objetivos de aprendizaje

Elegir un comportamiento comprobable, distinguir aserciones y salida demostrativa y entender pruebas deterministas de cancelación.

## Imprimir bien no cubre todo el contrato

El [paquete testing](https://pkg.go.dev/testing) descubre funciones de prueba en archivos terminados en _test.go. Una función Test recibe [`testing.T`](https://pkg.go.dev/testing#T) y comunica fallos por ese objeto. El comando imprime total inicial y total vacío, pero las pruebas comprueban además alias, copias independientes, registros inválidos, identidad de errores, Unicode, orden y cancelación. El objetivo es hacer visibles errores plausibles, no ejecutar cada línea una vez.

TestSelectBoundaryAndOrder utiliza diecinueve y veinte minutos. Un umbral de veinte debe incluir los dos registros de frontera, excluir diecinueve y preservar orden. También modifica un resultado seleccionado y comprueba que la entrada permanezca intacta. Son contratos observables. Reescribir el bucle sin cambiarlos debe mantener la prueba. Calcular la expectativa usando Select misma eliminaría la comprobación independiente.

## Las tablas hacen visibles los casos

Las pruebas del lector y del CLI usan tablas: cada fila nombra entrada, resultado y categoría. Los [subtests](https://pkg.go.dev/testing#hdr-Subtests_and_Sub_benchmarks) identifican el escenario fallido. Elige filas significativas. JSON malformado, registro vacío y duración cero válida son contratos distintos; duplicar varios nombres válidos equivalentes no aporta lo mismo. El mensaje de fallo debe mostrar los datos observados necesarios para diagnosticarlo.

Una [prueba de ejemplo](https://pkg.go.dev/testing#hdr-Examples) documenta comportamiento pequeño y comprueba su salida. ExampleTotal imprime cuarenta y cero mediante la directiva que entiende el ejecutor. Es metadato ejecutable, no una afirmación de captura manual. El manifiesto verifica por separado las catorce salidas. Cada mecanismo tiene su función: ejemplos para formato estable, aserciones para comportamiento del dominio y categorías de error.

## Usar fronteras reales cuando sea sencillo

Las pruebas CLI llaman a Run con lectores y búferes reales, ejercitando opciones, JSON, selección y formato juntos. Un archivo temporal prueba adquisición sin una fixture permanente. Las pruebas HTTP invocan el manejador real con [`httptest`](https://pkg.go.dev/net/http/httptest). No hay un mock de Select que devuelva el número deseado, así que pueden detectar fallos de integración entre frontera y núcleo.

La prueba cancela antes de Count y comprueba [`context.Canceled`](https://pkg.go.dev/context#Canceled). No duerme esperando que una goroutine alcance cierta instrucción. La terminación del canal también proporciona un punto observable de reunión. El detector de carreras es otra comprobación: pasar pruebas normales no demuestra ausencia de carreras. El coordinador posee las ejecuciones oficiales del curso y registra su entorno real en el diario.

## Explorar sin inventar evidencia

El [objetivo de fuzzing](https://go.dev/doc/security/fuzz/) parte de una muestra, un array vacío y null. Para cualquier entrada aceptada comprueba nombres no vacíos y duraciones no negativas. Los errores son resultados legítimos: una entrada arbitraria malformada no constituye un fallo. Una ejecución normal procesa las semillas; un comando limitado explora mutaciones. No informes de cantidades de casos ni porcentajes de cobertura sin una ejecución real.

Puedes conservar el hábito C# y Java de probar comportamiento observable utilizando el descubrimiento integrado de Go. Nombra el fallo buscado, define una expectativa independiente y mantén la preparación menor que el comportamiento. Las pruebas completas forman parte del módulo y pueden leerse junto a la implementación.

## Ejemplo explicado

Código completo: [`cmd/l13/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l13/main.go).

```go
package main

import (
	"example.com/learn/go-for-csharp-java/internal/study"
	"fmt"
)

func main() {
	records := study.Fixture()
	fmt.Printf("fixture-total=%d empty-total=%d\n", study.Total(records), study.Total(nil))
}
```

Desde la raíz del repositorio:

```sh
cd code/go-for-csharp-java
go run ./cmd/l13
```

**Salida verificada — Go 1.27.1, Windows/amd64.**

```text
fixture-total=40 empty-total=0
```

## Una aserción del comportamiento de frontera

[`internal/study/study_test.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/internal/study/study_test.go)

```go
func TestSelectBoundaryAndOrder(t *testing.T) {
	records := []Record{{"first", 20}, {"skip", 19}, {"last", 20}}
	selected := Select(records, 20)
	if len(selected) != 2 || selected[0].Name != "first" || selected[1].Name != "last" {
		t.Fatal(selected)
	}
	selected[0].Name = "changed"
	if records[0].Name != "first" {
		t.Fatal("selection aliases the input elements")
	}
}
```

## Leer, predecir y comprobar

Antes de ejecutar el programa, sigue cada valor desde su declaración hasta el resultado mostrado. Anota qué operación valida los datos y cuál solo transforma datos ya tipados. Ejecuta después el comando del repositorio y compara toda la salida, incluido el salto de línea final, con examples.json. Un ejemplo coincidente demuestra este conjunto de datos; las pruebas escritas cubren contratos adicionales. Cambia una sola entrada cada vez, explica la consecuencia y separa el experimento de los datos publicados. Así podrás diagnosticar un resultado inesperado sin cambiar silenciosamente lo que promete la lección.

## Ejercicios

1. ¿Qué prueba detecta cambiar la comparación inclusiva por una estricta?

<details>
<summary>Solución 1</summary>

TestSelectBoundaryAndOrder: sus registros de veinte minutos deben incluirse con umbral veinte. Una comparación estricta los excluiría y fallarían longitud y orden esperados. La prueba no pide a la implementación calcular su propia expectativa; los registros esperados se establecen independientemente.

</details>

2. ¿El fuzzing demuestra suma ilimitada segura para toda entrada aceptada?

<details>
<summary>Solución 2</summary>

No. La propiedad comprueba nombres y duraciones negativas, no todos los límites aritméticos ni recursos. Pasar semillas tampoco es una campaña prolongada. Mantén la afirmación vinculada a las aserciones existentes y registra duración y resultados reales después de ejecutar. Un contrato más fuerte requeriría reglas y pruebas correspondientes.

</details>

## Fuentes oficiales

- [Paquete testing](https://pkg.go.dev/testing)
- [Pruebas de ejemplos](https://pkg.go.dev/testing#hdr-Examples)
- [Subpruebas](https://pkg.go.dev/testing#hdr-Subtests_and_Sub_benchmarks)
- [Pruebas de fuzzing](https://go.dev/doc/security/fuzz/)

[Siguiente lección](../14-cli-capstone/) · [Diario](../journal/)
