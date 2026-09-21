---
title: 1 — Empezar con un cambio, no con un diagrama
description: Establecer el contrato del plan de práctica, supuestos explícitos y mediciones antes de elegir límites arquitectónicos.
sidebar:
  order: 1
---

## El mismo pequeño problema de principio a fin

Un profesor de guitarra guarda el plan de un alumno mediante un formulario web. Mañana, un importador por lotes podría necesitar la misma validación. El plan contiene un título, exactamente tres identificadores distintos de posiciones y la revisión del catálogo donde se eligieron. Guardarlo devuelve un identificador de plan y una revisión; posiciones desconocidas, duplicados o catálogo obsoleto producen un rechazo tipado sin escritura.

Suponemos un equipo, un proceso desplegado, almacenamiento transaccional local y una instantánea inmutable del catálogo. La identidad del profesor ya está establecida, pero el caso de uso debe comprobar que puede modificar el plan de este alumno. Todavía no hacen falta facturación, flujos de eventos ni despliegue independiente. Son supuestos del ejercicio, no hechos de un sistema en producción.

El contrato resulta más útil que un árbol de carpetas:

| Entrada o evento | Observación requerida |
|---|---|
| Tres identificadores conocidos y distintos, revisión actual | Un plan y un recibo duradero |
| Identificador repetido | `InvalidPlan`; ningún plan guardado |
| Revisión del catálogo ya no aceptada | `StaleCatalog`; ninguna escritura |
| Alumno de otro profesor | `Forbidden`; ninguna escritura |
| Reintento con mismo ID de petición y contenido | Mismo recibo; ningún segundo plan |
| Mismo ID de petición, contenido diferente | `RequestConflict`; ninguna sobrescritura |

Los dos últimos requisitos serán centrales en la [lección 3](../03-failure-and-distribution/). También afectan a un servicio web local: el cliente puede perder la conexión después del commit.

## Empezar con una candidata en capas

La [guía de arquitectura de Microsoft](https://learn.microsoft.com/dotnet/architecture/modern-web-apps-azure/common-web-application-architectures) distingue capas lógicas y despliegue. Empezamos con un manejador de peticiones, una operación de aplicación y un adaptador de persistencia en un proceso. Una capa organiza código; no implica otro servidor.

Colocar la regla de las tres posiciones en una sola función. El manejador interpreta la entrada; la operación comprueba permisos, carga el catálogo aceptado, llama a la función y guarda. Puede bastar. Un tipo de base de datos que se filtra a la regla es una dependencia concreta que evaluar, no prueba de que toda arquitectura en capas sea defectuosa.

## Definir el experimento antes de medir

**Hipótesis:** separar la operación del host web permitirá reutilizarla desde el importador sin copiar la validación. **Objeción más fuerte:** una única función llamada desde ambos manejadores ya lo consigue; otro proyecto y un repositorio genérico podrían no aportar valor.

Probar primero la función sencilla. En una revisión y datos fijos, registrar:

| Límite | Medida | Criterio de aceptación propuesto |
|---|---|---|
| Manejador → operación | Definiciones de reglas y pruebas reutilizadas por dos llamadores | Una implementación; mismos rechazos |
| Regla → infraestructura | Dependencias de ejecución directas y transitivas | La prueba no inicia host ni base de datos |
| Operación → almacenamiento | Archivos cambiados para añadir almacenamiento de prueba | Regla intacta; mismos casos contractuales superados |
| Salida de compilación → proceso activo | Reproducir por separado un bloqueo de archivo | No afirmar que una interfaz resuelve los bloqueos |

Los umbrales son un experimento propuesto, **por verificar**. Contar cambios semánticos, incluidos ensamblado y pruebas, sin premiar un número arbitrariamente bajo de archivos. Medir el tiempo de pruebas en la misma máquina tras controlar arranque y cachés.

## Ejercicio — Encontrar el supuesto oculto

La validación acepta un ID de posición y luego el almacenamiento vuelve a consultar el último catálogo. ¿Puede el recibo decir qué revisión se validó? Proponer la corrección mínima y un criterio que refute añadir un proyecto de dominio separado.

<details>
<summary>Solución razonada</summary>

Las dos lecturas pueden observar revisiones diferentes. Llevar la revisión inmutable validada hasta la escritura y persistirla en el recibo. Si la aceptación depende de la revisión actual al hacer commit, comprobar esa precondición atómicamente con la escritura; una lectura previa no basta. No se requiere otro proyecto para expresar el contrato. Rechazar la extracción si ambos llamadores ya reutilizan la regla pura, no hay dependencias prohibidas y el único efecto observado es trabajo adicional de compilación o conversión. Revisar cuando aparezca un problema concreto de dependencia o responsabilidad.

</details>
