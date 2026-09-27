---
title: 1. Disposición de memoria y representación
sidebar:
  order: 1
description: Medir tamaño, alineación, padding, offsets y una optimización por nichos; entender lo que repr(Rust), repr(C) y repr(transparent) prometen y lo que no.
---

Fuente: [`examples/l01_layout.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-advanced/examples/l01_layout.rs). Ejecútalo con:

```bash
cd code/rust-advanced
bash check.sh
```

## La pregunta antes de medir

Dos packets contienen exactamente los mismos campos. ¿Reduce su tamaño colocar primero el campo con la alineación más estricta?

**Hipótesis escrita antes de ejecutar:** en los targets de 64 bits del curso, el orden `u8, u32, bool` necesita padding interno y final, mientras que `u32, u8, bool` necesita menos. El segundo packet debería ser menor sin almacenar menos información.

Las funciones [`size_of`](https://doc.rust-lang.org/std/mem/fn.size_of.html), [`align_of`](https://doc.rust-lang.org/std/mem/fn.align_of.html) y [`offset_of`](https://doc.rust-lang.org/std/mem/macro.offset_of.html) permiten preguntar al target en vez de adivinar.

## Tamaño, alineación y padding

La **alineación** de un tipo define las direcciones donde puede comenzar un valor. Si `u32` tiene alineación 4, su dirección debe ser múltiplo de cuatro. Una struct puede contener:

- **padding interno** antes de un campo;
- **padding final** después del último campo, para alinear valores consecutivos en un array;
- bytes útiles pertenecientes a los campos.

El capítulo [type layout de la Rust Reference](https://doc.rust-lang.org/reference/type-layout.html) es el contrato. Los números son propiedades del target, no constantes universales.

## Una representación es una promesa

La representación predeterminada `repr(Rust)` garantiza que los campos estén correctamente alineados, no se solapen y que la alineación del tipo sea al menos la máxima de sus campos. **No** promete el orden declarado ni offsets estables. No publiques offsets de una struct Rust predeterminada como ABI.

Para este experimento, ambas structs usan [`repr(C)`](https://doc.rust-lang.org/reference/type-layout.html#the-c-representation), que proporciona el orden y las reglas de padding de la ABI C del target:

```rust
#[repr(C)]
pub struct Packet {
    pub tag: u8,
    pub count: u32,
    pub ready: bool,
}

#[repr(C)]
pub struct CompactPacket {
    pub count: u32,
    pub tag: u8,
    pub ready: bool,
}
```

La salida capturada en la máquina Windows de 64 bits del autor es:

```text
target_pointer_width=64
Packet size=12 align=4 offsets=0,4,8
CompactPacket size=8 align=4 offsets=0,4,5
Option<usize> size=16
Option<NonZeroUsize> size=8
```

La hipótesis queda confirmada localmente:

- `Packet`: el byte 0 es `tag`; 1–3 son padding; 4–7 son `count`; el byte 8 es `ready`; 9–11 son padding final;
- `CompactPacket`: 0–3 son `count`; 4 y 5 contienen los campos de un byte; 6–7 son padding final.

Reordenar ahorró cuatro bytes aquí. Eso no significa «ordena siempre los campos por tamaño»: legibilidad, compatibilidad ABI, patrones de caché y campos de tamaño cero pueden importar más. Mide el tipo real en los targets compatibles.

## Un valor que el tipo declara imposible

[`NonZeroUsize`](https://doc.rust-lang.org/std/num/type.NonZeroUsize.html) excluye cero. `Option<NonZeroUsize>` puede codificar `None` como cero y cada patrón no nulo como `Some`. Esta representación no usada es un **nicho**.

`usize` no tiene patrones inválidos, por lo que `Option<usize>` necesita un discriminante adicional. En este target, el programa midió 16 bytes frente a 8. La biblioteca estándar garantiza explícitamente la optimización de puntero nulo para los enteros no nulos documentados; no deduzcas la misma garantía para cualquier enum que hoy parezca pequeño.

## `repr(transparent)` es más preciso que «mismo tamaño»

Un wrapper [`repr(transparent)`](https://doc.rust-lang.org/reference/type-layout.html#the-transparent-representation) tiene la disposición y ABI de su único campo de tamaño no nulo. Es útil para IDs fuertemente tipados que cruzan una frontera FFI:

```rust
#[repr(transparent)]
struct UserId(u64);
```

Un segundo campo de tamaño no nulo rompe el contrato. El curso conserva el rechazo como doctest:

```rust
#[repr(transparent)]
struct InvalidTransparent(u32, u32);
```

El comando estable `cargo test --doc` verifica que el snippet falle. `cargo +nightly test --doc` verifica además el código de error exacto E0690 en vez de confiar en una salida copiada.

## Correspondencias con C# y Java

| Pregunta | Rust | C# | Java |
|---|---|---|---|
| Disposición inline de un valor | `struct`, atributo de representación | tipo valor y [`StructLayout`](https://learn.microsoft.com/dotnet/api/system.runtime.interopservices.structlayoutattribute) | los objetos ordinarios tienen disposición gestionada por la VM; la [Foreign Function & Memory API](https://docs.oracle.com/en/java/javase/25/core/foreign-function-and-memory-api.html) modela disposiciones nativas explícitas |
| ABI C estable | `repr(C)` | `LayoutKind.Sequential`/`Explicit` | `MemoryLayout` |
| Wrapper ABI de un campo | `repr(transparent)` | sin equivalente general exacto | sin equivalente general exacto |
| Preguntar al target | `size_of`, `align_of`, `offset_of` | `Unsafe.SizeOf`, `Marshal.OffsetOf`, con semántica distinta para objetos y valores | API de layout para memoria foránea, no para detalles arbitrarios de objetos |

Una `struct` Rust no equivale automáticamente a una clase C# ni a un objeto Java: no tiene una cabecera de objeto por ser una struct, y su ubicación depende de su propietario.

## Ejercicios

### 1. Predice antes de ejecutar

Añade un campo `u16` a ambos packets. Escribe los offsets y tamaños esperados antes de compilar, y usa `offset_of!` para comprobar la predicción.

<details>
<summary>Solución</summary>

Con `repr(C)`, calcula cada campo desde el offset actual redondeado al siguiente múltiplo de su alineación, y redondea el tamaño final a la alineación de la struct. El mejor orden depende de dónde coloques `u16`; si te equivocaste, conserva la predicción en tus notas.

</details>

### 2. Codifica la ausencia sin otra palabra

Define un newtype `Handle` sobre `NonZeroUsize`. Compara `size_of::<Handle>()` y `size_of::<Option<Handle>>()`.

<details>
<summary>Solución</summary>

```rust
use std::num::NonZeroUsize;

#[repr(transparent)]
struct Handle(NonZeroUsize);

assert_eq!(std::mem::size_of::<Handle>(), std::mem::size_of::<Option<Handle>>());
```

El wrapper transparente conserva el contrato de valores válidos del tipo interno, de modo que la opción conserva su nicho.

</details>

### 3. Elige la representación deliberadamente

Elige `repr(Rust)`, `repr(C)` o `repr(transparent)` para un estado interno de parser, un packet enviado a una biblioteca C y un ID `u64` fuertemente tipado que atraviesa esa biblioteca.

<details>
<summary>Solución</summary>

- estado interno del parser: `repr(Rust)` predeterminado, salvo otro requisito medido;
- packet C: `repr(C)`, con tipos de campo que también tengan representación definida en la frontera;
- ID de un campo: `repr(transparent)` alrededor de `u64`.

El atributo es necesario, pero no suficiente: ownership, validez, endianness y lifetime son contratos separados de la frontera.

</details>

## Qué demuestra — y qué no

El programa demuestra la disposición impresa en el target que lo ejecutó, y CI probará los tres targets alojados de 64 bits. No demuestra una ABI estable para `repr(Rust)`, que una struct menor acelere un programa completo ni que el resultado se mantenga en un target de 32 bits o inusual.

Siguiente: asignación, costes de ownership y trazas deterministas de `Drop`.
