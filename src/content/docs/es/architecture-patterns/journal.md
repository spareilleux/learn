---
title: Patrones de arquitectura — Diario
description: Evidencia, procedencia de fuentes y experimentos pendientes del curso de patrones de arquitectura.
sidebar:
  label: Diario
  order: 5
---

## Progreso

- [x] Definir un caso y cuatro lecciones centradas.
- [x] Comparar los cinco patrones, supuestos y criterios de rechazo.
- [x] Proporcionar ejercicios resueltos en inglés, francés y español.
- [x] Fijar las lecturas del ecosistema sin afirmar adopción.
- [ ] Ejecutar un experimento de cambio de dependencias en un repositorio del ecosistema.
- [ ] Ejecutar casos de concurrencia y recuperación contra un adaptador real.

## 2026-09-21 — Una comparación con evidencia acotada

Revisión de referencia del sitio: `c05b01f35c2a407e8b637db6f6c1bb5015c518d3`. Se reutilizó la navegación Arquitectura y diseño. No se modificó ningún otro curso.

Fuentes primarias consultadas: [capas](https://learn.microsoft.com/dotnet/architecture/modern-web-apps-azure/common-web-application-architectures), [onion](https://jeffreypalermo.com/2008/07/the-onion-architecture-part-1/), [clean](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html), [hexagonal](https://alistair.cockburn.us/hexagonal-architecture), [fundamentos de módulos](https://docs.spring.io/spring-modulith/reference/fundamentals.html), [verificación de módulos](https://docs.spring.io/spring-modulith/reference/verification.html) e [idempotencia](https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/). La página de Microsoft se abrió mediante su URL inglesa. Los README de la [lección 4](../04-ecosystem-decisions/) fueron accesibles en las revisiones fijadas.

El catálogo, el invariante de tres posiciones, el presupuesto de casos y los umbrales son supuestos didácticos del autor. Las soluciones son razonamientos, no salidas capturadas. No se afirma ninguna medición de rendimiento, asignaciones, concurrencia ni conformidad arquitectónica. Aún no hay tablas QA o Experimentos porque no se produjo ningún hallazgo de software ni experimento arquitectónico medido.

Validación del sitio en Windows, Node.js v24.12.0 y npm 11.7.0:

- `npm ci --no-audit --no-fund`: dependencias bloqueadas instaladas correctamente.
- `npm run build`: correcto; 1138 páginas generadas. Las lecciones de música existentes emitieron avisos de resaltado `play` no admitido; esos archivos no se modificaron.
- Comprobaciones del curso: 18 páginas, seis nombres idénticos por idioma, mismos órdenes de navegación y URL, 12 soluciones plegables con etiquetas equilibradas.
- Las 11 URL externas únicas devolvieron HTTP 200; los enlaces relativos apuntan a fuentes y HTML generado existentes.
- El HTML contiene enlaces del curso en las tres portadas y barras laterales; existen las 18 rutas.
- `git diff --check`: correcto.

Son comprobaciones del sitio y contenido, no experimentos arquitectónicos. El renderizado documental no valida los diseños de aplicaciones propuestos.

## Por verificar

- Renderizado en navegador y navegación en los tres idiomas.
- Compilaciones Linux/macOS; no hubo ejecución multiplataforma en esta entrega.
- Dependencias reales, paridad de llamadores y permisos antes de modificar el ecosistema.
- Idempotencia, unicidad concurrente, frescura del catálogo y recuperación tras crash en una implementación ejecutable.

## Preguntas abiertas

- ¿Qué regla realmente duplicada justifica la primera extracción?
- ¿Qué garantía de frescura debe tener la revisión guardada del catálogo?
- ¿Necesita algún módulo publicación o escalado independiente hoy?
