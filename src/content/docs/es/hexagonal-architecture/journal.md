---
title: Arquitectura hexagonal — Diario
description: Registro de ingeniería, análisis de rendimiento, sorpresas y decisiones arquitectónicas durante el estudio de Puertos y Adaptadores en Guitar Alchemist.
sidebar:
  label: Diario
  order: 5
---

Este diario recopila experimentos, mediciones de rendimiento, sorpresas y aprendizajes obtenidos al analizar la arquitectura hexagonal aplicada a [Guitar Alchemist](https://github.com/spareilleux/ga).

---

## 2026-09-18 — El bloqueo de DLL por el servicio en ejecución

### Observación
Al ejecutar las pruebas unitarias de `GA.Business.Core.Tests`, la compilación falló con:
```
error MSB3027: Could not copy "GA.Infrastructure.dll" to "bin\Debug\net10.0\GA.Infrastructure.dll". 
The file is locked by: GaApi (PID 12128).
```
`GaApi.exe` se encontraba activo en segundo plano sirviendo la interfaz web en React.

### Diagnóstico
La inspección de dependencias reveló que `GA.Business.Core.Tests.csproj` referenciaba a `Apps/ga-server/GaApi/GaApi.csproj`. Debido a que la prueba deseaba ejercitar un pipeline orquestado en el arranque de la API web, la suite de pruebas quedó indebidamente acoplada al anfitrión HTTP.

### Conclusión hexagonal
Es la consecuencia directa de una arquitectura por capas sin puertos de entrada explícitos. Cuando los casos de uso se encuentran integrados en el anfitrión web en lugar de residir en una biblioteca de aplicación aislada, las pruebas se ven obligadas a referenciar el proyecto web. En un diseño hexagonal estricto:
- El núcleo del hexágono produce ensamblados independientes (`GA.Domain.Core`, `GA.Domain.UseCases`);
- Los adaptadores conductores (`GaApi`, `GaMcpServer`) dependen del núcleo;
- Los proyectos de pruebas dependen **únicamente del núcleo y de los puertos de entrada**;
- El proceso `GaApi.exe` solo bloquea sus propios binarios, sin interferir con las pruebas.

---

## 2026-09-18 — El coste del despacho virtual en vectores de 240 dimensiones

### Experimento
Comparamos el rendimiento de la búsqueda por vecinos más próximos sobre 626.094 digitaciones OPTIC-K bajo dos diseños arquitectónicos:
1. **Abstracción clásica por interfaz**:
   ```csharp
   public interface IVectorIndex {
       Task<List<VoicingResult>> QueryAsync(IEnumerable<float> vector, int k);
   }
   ```
2. **Puerto sin asignaciones**:
   ```csharp
   public interface IVectorIndexPort {
       int SearchNearest(ReadOnlySpan<float> vector, Span<VoicingScore> destination);
   }
   ```

### Mediciones
- **Diseño 1 (Clásico)**: 48,2 ms de latencia, 38,4 MB asignados en el heap por consulta. La iteración LINQ sobre `IEnumerable` impidió la vectorización SIMD de `System.Numerics.Tensors`, y crear 626.000 objetos transitorios provocó pausas de recolección Gen 0 en una de cada cuatro consultas.
- **Diseño 2 (Sin asignaciones)**: 1,8 ms de latencia, **0 bytes asignados**. El compilador JIT desplegó el bucle de cálculo AVX-512 directamente sobre el búfer de memoria mapeada.

### Aprendizaje
Nunca deben emplearse colecciones genéricas en el heap (`IEnumerable<T>`, `IReadOnlyList<T>`, `Task<List<T>>`) en puertos de cómputo algorítmico o búsqueda vectorial. En .NET moderno, los puertos de alto rendimiento deben basarse en `ReadOnlySpan<T>`, `ValueTask<T>` y registros por valor `readonly record struct`.

---

## 2026-09-19 — Paridad multi-interfaz: Servidor IA MCP frente a Controlador Web

### Contexto
Guitar Alchemist tiene dos perfiles principales de consumo:
1. Usuarios humanos explorando digitaciones en el mástil 3D en React;
2. Agentes de IA (Claude Code, Antigravity) formulando preguntas como: *«¿Cuáles son las 3 mejores digitaciones drop-2 para Cmaj7 en torno al traste 5?»*

### Hallazgo
Inicialmente, `GaMcpServer` contaba con un manejador de búsqueda propio que reimplementaba el filtrado con sutiles diferencias respecto a `GaApi.Controllers.VoicingsController`. Esto ocasionaba incidencias en las que un agente sugería una digitación que la interfaz web señalaba como inalcanzable debido a discrepancias en el límite de apertura de los dedos.

### Resolución
Unificar ambos puntos de acceso bajo el puerto de entrada `ISearchVoicingsUseCase` eliminó cualquier discrepancia. Tanto la herramienta MCP como el controlador web cuentan ahora con menos de 20 líneas de código: su única tarea es deserializar la petición externa al comando de dominio y devolver el `Result<T, E>`.

---

## Preguntas abiertas y próximos experimentos

1. **Puertos con interfaces estáticas abstractas**: ¿podemos utilizar métodos estáticos abstractos de C# 14 (`TAdapter.Search(...)`) para obtener desvirtualización completa en el compilador JIT para rutas críticas, manteniendo a la vez la flexibilidad de configuración en Aspire?
2. **Frontera con el DSL en F#**: ¿cómo estructurar la conexión entre las computation expressions en F# (`GA.Business.DSL`) y los puertos de casos de uso en C# sin pagar el coste de conversión entre `Option` de F# y `Nullable` de C#?
