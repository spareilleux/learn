---
title: "Go avanzado para desarrolladores de C#/Java — Misión"
description: "Catorce lecciones prácticas sobre propiedad, concurrencia, fronteras y un servicio HTTP probado."
sidebar:
  label: "Misión"
  order: 0
---

## ¿Por qué profundizar en Go?

Conocer la sintaxis no basta para revisar un servicio que posee búferes, coordina trabajadores y debe detenerse de forma predecible. Este curso desarrolla esas capacidades mediante contratos concretos y pequeños paquetes reutilizables. Está dirigido a desarrolladores de servicios C# o Java que hayan completado [Go para desarrolladores de C#/Java](../go-for-csharp-java/). Domine antes segmentos, interfaces, errores, goroutines, canales, HTTP y pruebas básicas.

El objetivo es **Go 1.27** y el módulo declara `go 1.27.0`. El compilador proporcionado para verificar es Go 1.27.1 en Windows/amd64. La versión importa: Go 1.27 admite métodos genéricos y estabiliza JSON v2. Consulte las [notas oficiales](https://go.dev/doc/go1.27) y la [especificación](https://go.dev/ref/spec) en vez de aplicar restricciones de tutoriales antiguos.

## Qué podrá hacer

- Elegir fronteras de paquetes y hacer explícita la propiedad.
- Explicar visibilidad de memoria y limitar trabajo concurrente.
- Conservar contratos de error y distinguir nil tipado de interfaces nil.
- Construir fronteras HTTP y de tramas limitadas con pruebas locales deterministas.
- Diseñar propiedades de fuzz y experimentos de rendimiento sin inventar resultados.
- Integrar validación, copias al admitir, cancelación y vaciado en un servicio completo.

## Cómo trabajar el curso

El código está en [code/go-advanced](https://github.com/spareilleux/learn/tree/main/code/go-advanced), un módulo independiente que solo usa la biblioteca estándar. Cada lección muestra archivos Go versionados exactos y una orden de `cmd/l01` a `cmd/l14`. Desde la raíz del repositorio, entre en `code/go-advanced` y ejecute la orden. No necesita contenedores, bases de datos, credenciales, servicios externos ni frameworks adicionales.

Prediga la salida, explique por qué cada resultado puede observarse con seguridad y resuelva los ejercicios antes de abrir las soluciones completas. Los contratos stdout están en `examples.json`. Las pruebas cubren propiedad, identidades de error, parada de iteración, atómicos, cancelación, tramas, HTTP y vaciado. El proyecto final es un servicio limitado en memoria, no una plantilla de despliegue ni una cola duradera.

Las órdenes usan la misma sintaxis de Go en Windows, Linux/WSL y macOS. El detector de carreras requiere plataformas y herramientas C compatibles además de pruebas ordinarias; consulte su documentación. Las herramientas de perfiles deben escuchar en bucle local. Benchmarks, fuzzing activo, trazas y análisis de escape necesitan sus condiciones registradas: una compilación correcta no demuestra que se hayan ejecutado.

## Plan del curso

1. [Límites de paquetes y módulos](01-package-and-module-boundaries/)
2. [Memoria, análisis de escape y GC](02-memory-escape-and-gc/)
3. [Genéricos e iteradores](03-generics-and-iterators/)
4. [Contratos de error y nil tipado](04-error-contracts-and-typed-nil/)
5. [Modelo de memoria, sincronización y atómicos](05-memory-model-sync-and-atomics/)
6. [Pipelines con concurrencia limitada](06-bounded-pipelines/)
7. [Cancelación, plazos y cierre](07-cancellation-deadlines-and-shutdown/)
8. [Fronteras HTTP en producción](08-production-http/)
9. [Flujos y delimitación de mensajes](09-streaming-and-framing/)
10. [Pruebas de carreras, fuzzing y propiedades](10-race-fuzz-and-property-tests/)
11. [Benchmarks, pprof y trace](11-benchmarks-pprof-and-trace/)
12. [Reflexión, codificación y fronteras](12-reflection-and-encoding/)
13. [Dependencias, compilaciones y seguridad](13-dependencies-builds-and-security/)
14. [Un servicio integrado de trabajos HTTP](14-service-capstone/)

## Recursos

- [Go](https://go.dev/doc/)
- [Go 1.27](https://go.dev/doc/go1.27)
- [Especificación](https://go.dev/ref/spec)
- [Modelo de memoria](https://go.dev/ref/mem)
- [Biblioteca estándar](https://pkg.go.dev/std)

## Diario y estado de verificación

El [diario de aprendizaje](journal/) separa material escrito, verificaciones técnicas reales, mediciones pendientes y preguntas pedagógicas. Compilar y reproducir ejemplos no demuestra que un alumno humano pueda completar el curso.
