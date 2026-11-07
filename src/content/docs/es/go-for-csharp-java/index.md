---
title: "Go para desarrolladores C# y Java — Misión"
description: "Una introducción completa a Go 1.27 mediante un CLI probado de registro de estudio."
sidebar:
  label: Misión
  order: 0
---

## Por qué aprender Go

Ya sabes modelar datos, tratar fallos y construir aplicaciones en C# o Java. Go mantiene esos objetivos y cambia los mecanismos: valores copiados, descriptores de slices, interfaces implícitas, errores explícitos, goroutines y herramientas estándar pequeñas. Este curso conecta tus conocimientos con esas decisiones. El objetivo es predecir correctamente un programa Go y entregar un comando comprensible, en lugar de traducir mecánicamente la sintaxis de clases.

## Requisitos previos

Debes manejar funciones, colecciones, interfaces, genéricos, JSON básico y pruebas unitarias en C# o Java. Necesitas terminal, editor y las [herramientas Go](https://go.dev/doc/install). La versión de lenguaje es Go 1.27; el coordinador dispone de Go 1.27.1 en Windows/amd64. Los ejemplos usan solo la biblioteca estándar: no requieren frameworks, cuentas ni servicios externos.

## Qué construirás

El CLI lee un array JSON de sesiones, valida nombres y duraciones, filtra por minutos mínimos y muestra un informe ordenado. Al final, el ejecutable compone el mismo paquete study utilizado durante el curso. Un pequeño manejador HTTP ofrece un segundo adaptador del núcleo. Los ejercicios de red funcionan en memoria, sin servicios públicos. Aprenderás los límites de copiar valores, la propiedad de recursos, cómo conservar causas de errores y cómo probar la frontera completa.

## Plan del curso

| # | Lección | Aporta al proyecto |
|---|---|---|
| 1 | [Herramientas y módulos](01-toolchain-and-modules/) | Un paquete local compartido |
| 2 | [Valores, tipos y cadenas](02-values-types-and-strings/) | Duraciones y nombres tipados |
| 3 | [Control de flujo y funciones](03-control-flow-and-functions/) | Selección y totales |
| 4 | [Arrays y slices](04-arrays-and-slices/) | Propiedad explícita de colecciones |
| 5 | [Mapas y estructuras](05-maps-and-structs/) | Registros y agregación |
| 6 | [Punteros y métodos](06-pointers-and-methods/) | Mutación controlada |
| 7 | [Interfaces y composición](07-interfaces-and-composition/) | Contratos de comportamiento pequeños |
| 8 | [Errores, defer y recursos](08-errors-defer-and-resources/) | Diagnósticos de entrada útiles |
| 9 | [Archivos, JSON y Unicode](09-files-json-and-unicode/) | Registros JSON validados |
| 10 | [Genéricos y colecciones](10-generics-and-collections/) | Transformaciones tipadas |
| 11 | [Goroutines y canales](11-goroutines-and-channels/) | Vidas de trabajo acotadas |
| 12 | [HTTP y context](12-http-and-context/) | Frontera HTTP comprobable |
| 13 | [Pruebas](13-testing/) | Comprobaciones e integración |
| 14 | [Proyecto final de línea de comandos](14-cli-capstone/) | Comando de informes funcional |

## Cómo estudiar

Sigue las lecciones en orden. Predice la salida antes de ejecutar cada comando y separa tus experimentos de los datos publicados. Cada capítulo incluye dos ejercicios resueltos: inténtalos antes de abrir las soluciones. Código, comandos y salidas son idénticos en los tres idiomas. Los comandos comunes a plataformas parten de la raíz del repositorio y entran después en code/go-for-csharp-java. El código completo está en [code/go-for-csharp-java](https://github.com/spareilleux/learn/tree/main/code/go-for-csharp-java).

## Verificación y límites

El módulo contiene catorce comandos, un manifiesto examples.json de salidas exactas, pruebas semánticas, integración CLI, pruebas HTTP y un objetivo de fuzzing. Pasaron las pruebas, vet, el formato, las catorce salidas exactas y un ensayo acotado de fuzzing del lector con Go 1.27.1 en Windows/amd64. Los fragmentos y las traducciones se comprobaron contra el módulo terminado. El [diario](journal/) conserva condiciones, correcciones y evidencias separadas de CI alojada, publicación y estudio con alumnos. El proyecto final lee un registro local; no ofrece garantías contables ni de flujos duraderos.

Continúa con [Go avanzado](../go-advanced/) después del proyecto final.

## Fuentes primarias

- [Go 1.27](https://go.dev/doc/go1.27)
- [Especificación del lenguaje](https://go.dev/ref/spec)
- [Biblioteca estándar](https://pkg.go.dev/std)
- [Tutorial de módulos](https://go.dev/doc/tutorial/create-module)
