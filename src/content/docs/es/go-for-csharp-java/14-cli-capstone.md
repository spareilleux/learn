---
title: "14. Proyecto final de línea de comandos"
description: "Combinar módulos, datos tipados, entrada JSON, filtrado e informes probados en un comando útil."
sidebar:
  order: 14
---

## Objetivos de aprendizaje

Seguir todo el comando, distinguir diagnósticos e informe y verificar fronteras reales de entrada y salida.

## La aplicación completa más pequeña

El proyecto final produce un informe de sesiones de estudio. Sin argumentos usa los datos del curso. min selecciona sesiones mediante umbral inclusivo. file admite un archivo JSON, mientras que un guion solo selecciona entrada estándar. El informe conserva el orden, muestra nombre y duración de cada sesión elegida y luego el total. Es un comando local funcional, no catorce demostraciones relacionadas únicamente por el texto.

El pequeño main delega en cli.Run con argumentos y flujos del proceso. [os.Exit](https://pkg.go.dev/os#Exit) pertenece a esa frontera. Termina sin ejecutar llamadas diferidas de main; por eso la limpieza queda en Run, cuyo retorno normal ejecuta antes sus defers. La separación permite probar la aplicación sin terminar el proceso de pruebas. Run no es un acceso exclusivo de pruebas: main utiliza exactamente esa función.

## Seguir el flujo según dependencias

El [paquete flag](https://pkg.go.dev/flag) interpreta min y file mediante un [`FlagSet`](https://pkg.go.dev/flag#FlagSet) propio. Sintaxis inválida, mínimo negativo y argumentos posicionales inesperados devuelven error de uso. La ayuda termina correctamente. La adquisición elige después la muestra, el [io.Reader](https://pkg.go.dev/io#Reader) recibido o un archivo mediante [os.Open](https://pkg.go.dev/os#Open). La función cierra solo los archivos que abrió; no posee la entrada estándar.

study.Load establece codificación, forma JSON y validez del dominio. study.Select materializa los valores elegidos y study.Total suma sus duraciones. El informe se escribe en out y los diagnósticos en errOut. Se comprueba cada escritura: un destino roto no produce éxito falso. Run devuelve uno para fallos de entrada o salida, dos para argumentos inválidos y cero para éxito. Al usar go run, distingue el comportamiento de estado del lanzador Go del código devuelto por la aplicación.

## Una frontera probada que cruza la aplicación

Las pruebas proporcionan JSON real y capturan ambos flujos. Cubren muestra, filtro, entrada estándar, datos vacíos, JSON malformado, registros inválidos, opciones incorrectas y argumentos inesperados. Un archivo temporal comprueba adquisición por ruta real. Un escritor defectuoso verifica el resultado del fallo de salida. El manifiesto también ejecuta el comando y comprueba su salida predeterminada exacta. Juntos atraviesan argumentos, dominio y formato sin servicios externos.

Desde C# o Java quizá esperes un contenedor de dependencias, framework de comandos o clase de servicio. Esta aplicación no los necesita para tener una frontera clara: sus dependencias son flujos y funciones tipadas, y los efectos se concentran en un paquete. Añade un framework si lo justifica un requisito concreto. Pequeño no significa sin pruebas: la composición es el comportamiento observado por la integración.

## Delimitar honestamente la promesa

El comando lee completamente un registro pequeño en memoria. No actualiza archivos, no fusiona nombres duplicados ni normaliza Unicode. Tampoco define un formato contable durable ni una política de desbordamiento para totales arbitrarios. Son límites deliberados de la aplicación educativa. HTTP ofrece otro adaptador del mismo núcleo; añadir un salto de red al CLI no mejoraría el contrato actual.

Recorre lo aprendido: imports del módulo, duraciones tipadas, orden de slices, causas de errores, defer para archivos, validación JSON y pruebas de composición. Las goroutines están disponibles cuando una vida de trabajo las necesita, pero sumar localmente sigue siendo secuencial. El curso avanzado puede apoyarse ya en estas decisiones concretas en vez de una lista de sintaxis memorizada.

## Ejemplo explicado

Código completo: [`cmd/l14/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l14/main.go).

```go
package main

import (
	"example.com/learn/go-for-csharp-java/internal/cli"
	"os"
)

func main() { os.Exit(cli.Run(os.Args[1:], os.Stdin, os.Stdout, os.Stderr)) }
```

Desde la raíz del repositorio:

```sh
cd code/go-for-csharp-java
go run ./cmd/l14
```

**Salida verificada — Go 1.27.1, Windows/amd64.**

```text
types: 15 min
go: 25 min
total: 40 min
```

## Leer, predecir y comprobar

Antes de ejecutar el programa, sigue cada valor desde su declaración hasta el resultado mostrado. Anota qué operación valida los datos y cuál solo transforma datos ya tipados. Ejecuta después el comando del repositorio y compara toda la salida, incluido el salto de línea final, con examples.json. Un ejemplo coincidente demuestra este conjunto de datos; las pruebas escritas cubren contratos adicionales. Cambia una sola entrada cada vez, explica la consecuencia y separa el experimento de los datos publicados. Así podrás diagnosticar un resultado inesperado sin cambiar silenciosamente lo que promete la lección.

## Ejercicios

1. ¿Cómo mostrar solo la sesión que alcanza veinte minutos?

<details>
<summary>Solución 1</summary>

Ejecuta go run ./cmd/l14 -min 20 desde el módulo. Select conserva go, que dura veinticinco; el informe contiene esa sesión y total de veinticinco minutos. El caso de integración del filtro comprueba ese comportamiento. No necesitas duplicar interpretación ni filtrado en main.

</details>

2. Un archivo JSON contiene una duración negativa. Sigue el resultado.

<details>
<summary>Solución 2</summary>

Run abre el archivo y registra su cierre; Load rechaza el registro y envuelve ErrInvalid. Run escribe un diagnóstico en errOut, devuelve uno y cierra el archivo al ejecutar sus defers. No escribe informe en out. La prueba de registro inválido comprueba ese camino sin depender de la redacción exacta del diagnóstico.

</details>

## Fuentes oficiales

- [flag package](https://pkg.go.dev/flag)
- [io.Reader](https://pkg.go.dev/io#Reader)
- [os.Open](https://pkg.go.dev/os#Open)
- [os.Exit](https://pkg.go.dev/os#Exit)

[Continuar con Go avanzado](../../go-advanced/) · [Diario](../journal/)
