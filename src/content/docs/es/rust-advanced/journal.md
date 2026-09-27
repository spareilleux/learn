---
title: Diario
description: Progreso fechado, experimentos y preguntas abiertas del curso Rust avanzado.
sidebar:
  order: 99
---

## Progreso

- [x] Misión y plan de doce lecciones
- [x] Crate del curso con formato, Clippy, pruebas unitarias, doctests compile-fail y salida capturada
- [x] Lección 1: disposición de memoria y representación
- [ ] Lección 2: asignación, costes de ownership y `Drop`
- [ ] Lecciones 3–12

## Experimentos

| Pregunta | Hipótesis escrita antes de medir | Resultado | Veredicto | Prueba |
|---|---|---|---|---|
| ¿Colocar primero el campo más alineado reduce este packet `repr(C)`? | `u8, u32, bool` necesita más padding que `u32, u8, bool` en los targets de 64 bits del curso | 12 bytes se convirtieron en 8 en la máquina Windows x86-64 del autor; los offsets cambiaron de `0,4,8` a `0,4,5` | Confirmado localmente; targets de CI pendientes | [Entrada](#2026-09-27--la-primera-porción-medida), [`code/rust-advanced`](https://github.com/spareilleux/learn/tree/main/code/rust-advanced) |
| ¿Puede `Option` reutilizar un valor inválido de `NonZeroUsize`? | `Option<NonZeroUsize>` debería conservar una palabra, mientras `Option<usize>` necesita otra | 8 bytes frente a 16 en el mismo target | Confirmado localmente; caso garantizado y documentado por la biblioteca estándar | [Entrada](#2026-09-27--la-primera-porción-medida), [lección](../01-memory-layout-and-representation/) |

## 2026-09-27 — La primera porción medida

El curso empezó como tracer-bullet y no como doce lecciones vacías: una misión, una lección completa y una crate que comprueba cada número citado. Rust 1.94.0 produjo:

```text
target_pointer_width=64
Packet size=12 align=4 offsets=0,4,8
CompactPacket size=8 align=4 offsets=0,4,5
Option<usize> size=16
Option<NonZeroUsize> size=8
```

`bash check.sh` superó el formato, Clippy con warnings denegados, una prueba unitaria, un doctest compile-fail y la comparación de salida capturada. Una ejecución doctest separada con nightly también verificó el código E0690 exacto. Es una prueba local de Windows. El workflow tiene tres runners, pero su resultado no existe hasta que CI se ejecute.

La lección excluye `repr(Rust)` de la comparación de offsets porque el orden de campos no es una promesa ABI. Los dos packets medidos usan `repr(C)`, haciendo que la elección de representación forme parte de la pregunta y no sea un detalle accidental del compilador.

## Por verificar

- Confirmar `check.sh` en los runners alojados Linux, Windows y macOS antes de llamar multiplataforma a la porción.
- Decidir si la lección 2 debe medir directamente el asignador del sistema o contar asignaciones con un asignador de prueba estrictamente acotado.
- Elegir un tipo real de IX o hari solo después de estabilizar el método independiente; un experimento del curso no debe convertirse en una optimización no solicitada.

## Preguntas abiertas

- ¿Qué afirmaciones de layout ayudan a desarrolladores de aplicaciones sin fomentar compromisos ABI prematuros?
- ¿Pueden los ejemplos de Miri de la lección 3 ser suficientemente deterministas y distinguir con claridad detección de undefined behaviour de prueba de soundness?
