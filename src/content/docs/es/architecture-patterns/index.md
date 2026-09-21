---
title: Patrones de arquitectura — Misión
description: Comparar capas, onion, clean, hexagonal y monolito modular con un caso de planes de práctica, decisiones refutables y ejercicios de fallos.
sidebar:
  label: Misión
  order: 0
---

## Misión

Elegir un límite porque hace un cambio concreto más seguro o menos costoso. Este curso compara cinco patrones sin clasificarlos de mejor a peor. Complementa el [curso de arquitectura hexagonal](../hexagonal-architecture/) al preguntar cuándo bastan unas capas sencillas, cómo se solapan onion y clean con puertos y adaptadores, y por qué el monolito modular responde a otra decisión.

El caso conductor es **guardar el plan de práctica de un guitarrista**: recibir un plan con nombre y tres posiciones de acordes, validarlo contra una revisión del catálogo, persistirlo y devolver un recibo. Las cuatro lecciones mantienen ese caso. Es un diseño didáctico, no una funcionalidad implementada en un repositorio del ecosistema.

## Requisitos y resultado

Conocer funciones, interfaces, transacciones y la diferencia entre proceso y biblioteca. No hacen falta cuentas, modelos de pago ni servicios. Los ejercicios son de diseño y trazas de fallos con soluciones; esta primera entrega no contiene aplicación ejecutable ni benchmark.

Terminarás con un mapa de dependencias, un contrato, una tabla de fallos y una decisión de una página con condiciones de rechazo comprobables. Tiempo sugerido: dos horas; es una estimación de estudio, no una medición.

## Plan

| Lección | Entregable |
|---|---|
| [1. Empezar con un cambio](01-change-and-boundaries/) | Supuestos, invariantes y referencia medible |
| [2. Cinco patrones, un caso](02-five-patterns/) | Comparación de dependencias y responsabilidades |
| [3. Cuando un límite cruza un proceso](03-failure-and-distribution/) | Contrato de reintentos, concurrencia y recuperación |
| [4. Evaluar un límite del ecosistema](04-ecosystem-decisions/) | Experimento acotado y decisión para GA/Gaia/IX/Demerzel |
| [Diario](journal/) | Fuentes, evidencia de validación y trabajo pendiente |

## Fuentes primarias

- [Microsoft: arquitecturas comunes de aplicaciones web](https://learn.microsoft.com/dotnet/architecture/modern-web-apps-azure/common-web-application-architectures).
- [Cockburn: artículo original de puertos y adaptadores](https://alistair.cockburn.us/hexagonal-architecture).
- [Palermo: arquitectura onion, parte 1](https://jeffreypalermo.com/2008/07/the-onion-architecture-part-1/).
- [Martin: clean architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html).
- [Spring Modulith: fundamentos de módulos](https://docs.spring.io/spring-modulith/reference/fundamentals.html) y [verificación estructural](https://docs.spring.io/spring-modulith/reference/verification.html).
- [Amazon Builders' Library: API idempotentes](https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/).

Estas fuentes establecen la terminología. La carga de trabajo, los umbrales, los juicios y los experimentos propuestos son supuestos del curso, no conclusiones medidas por esas fuentes.
