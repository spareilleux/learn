---
title: Método
description: Cómo se organizan y redactan los cursos de este sitio.
---

Cada curso vive en su propia carpeta y sigue la misma estructura.

## Estructura de un curso

| Página | Función |
|---|---|
| `index.md` — **Misión** | Por qué aprendo el tema, qué quiero ser capaz de hacer al final, requisitos previos, plan y recursos. |
| `01-…`, `02-…` — **Lecciones** | Una idea por lección. Comandos reales, un resumen, ejercicios con soluciones desplegables. |
| `journal.md` — **Diario** | Notas de progreso fechadas: intentos, errores, preguntas abiertas, puntos « por verificar ». |

## Reglas de redacción

1. **Probar antes de afirmar.** Lo que todavía no se ha verificado en mi máquina se marca como *por verificar*.
2. **Citar fuentes primarias.** Documentación oficial, repositorios, notas de versión — nada de blogs de segunda mano cuando se puede evitar.
3. **Conservar los fracasos.** Un error encontrado (y su causa) suele ser más instructivo que el camino ideal.
4. **Fechar lo que cambia rápido.** Las herramientas en versión preliminar evolucionan: cada curso indica la versión estudiada.
5. **Trilingüe.** El inglés es el idioma de referencia; la versión francesa sigue bajo `/fr/` y la española bajo `/es/`.

## Añadir un curso

1. Crea `src/content/docs/<tema>/` (inglés), `src/content/docs/fr/<tema>/` (francés) y `src/content/docs/es/<tema>/` (español), con los mismos nombres de archivo.
2. Escribe `index.md` (misión), las lecciones numeradas y `journal.md`.
3. Ordena las páginas con `sidebar: { order: N }` en el frontmatter.
4. Añade el grupo en `astro.config.mjs`:

```js
{ label: 'Mi tema', items: [{ autogenerate: { directory: 'mi-tema' } }] }
```
