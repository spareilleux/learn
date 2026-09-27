---
title: 1. Disposition mémoire et représentation
sidebar:
  order: 1
description: Mesurer taille, alignement, padding, offsets et optimisation par niche ; comprendre ce que repr(Rust), repr(C) et repr(transparent) garantissent — et ne garantissent pas.
---

Source : [`examples/l01_layout.rs`](https://github.com/spareilleux/learn/blob/main/code/rust-advanced/examples/l01_layout.rs). Pour l'exécuter :

```bash
cd code/rust-advanced
bash check.sh
```

## La question avant la mesure

Deux packets contiennent exactement les mêmes champs. Placer d'abord le champ dont l'alignement est le plus strict réduit-il leur taille ?

**Hypothèse écrite avant l'exécution :** sur les cibles 64 bits du cours, l'ordre `u8, u32, bool` exige du padding interne et final, tandis que `u32, u8, bool` en exige moins. Le second packet devrait être plus petit sans stocker moins d'information.

Les fonctions [`size_of`](https://doc.rust-lang.org/std/mem/fn.size_of.html), [`align_of`](https://doc.rust-lang.org/std/mem/fn.align_of.html) et [`offset_of`](https://doc.rust-lang.org/std/mem/macro.offset_of.html) permettent d'interroger la cible au lieu de deviner.

## Taille, alignement et padding

L'**alignement** d'un type définit les adresses auxquelles une valeur de ce type peut commencer. Si `u32` a un alignement de 4, son adresse doit être un multiple de quatre. Une struct peut donc contenir :

- du **padding interne** avant un champ ;
- du **padding final** après le dernier champ, pour aligner les valeurs successives d'un tableau ;
- les octets utiles des champs.

Le chapitre [type layout de la Rust Reference](https://doc.rust-lang.org/reference/type-layout.html) constitue le contrat. Ces nombres dépendent de la cible ; ce ne sont pas des constantes universelles.

## Une représentation est une promesse

La représentation par défaut `repr(Rust)` garantit que les champs sont correctement alignés, ne se chevauchent pas et que l'alignement du type est au moins celui de son champ le plus contraignant. Elle ne promet **ni** l'ordre de déclaration **ni** des offsets stables. Les offsets d'une struct Rust par défaut ne sont pas une ABI publique.

Pour cette expérience, les deux structs emploient [`repr(C)`](https://doc.rust-lang.org/reference/type-layout.html#the-c-representation), qui suit l'ordre des champs et les règles de padding de l'ABI C de la cible :

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

Voici la sortie capturée sur la machine Windows 64 bits de l'auteur :

```text
target_pointer_width=64
Packet size=12 align=4 offsets=0,4,8
CompactPacket size=8 align=4 offsets=0,4,5
Option<usize> size=16
Option<NonZeroUsize> size=8
```

L'hypothèse est confirmée localement :

- `Packet` : l'octet 0 contient `tag`, les octets 1–3 sont du padding, 4–7 contiennent `count`, l'octet 8 contient `ready`, et 9–11 sont du padding final ;
- `CompactPacket` : les octets 0–3 contiennent `count`, 4 et 5 les deux champs d'un octet, et 6–7 le padding final.

Le réordonnancement économise quatre octets ici. Cela ne signifie pas « toujours trier les champs par taille » : lisibilité, compatibilité ABI, accès au cache et champs de taille nulle peuvent compter davantage. Mesurez le vrai type sur les cibles prises en charge.

## Une valeur que le type interdit

[`NonZeroUsize`](https://doc.rust-lang.org/std/num/type.NonZeroUsize.html) exclut zéro. `Option<NonZeroUsize>` peut donc coder `None` par zéro et chaque motif non nul par `Some`. Cette représentation inutilisée est une **niche**.

`usize` n'a aucun motif de bits invalide ; `Option<usize>` a donc besoin d'un discriminant supplémentaire. Sur cette cible, le programme mesure 16 octets contre 8. La bibliothèque standard garantit explicitement cette optimisation pour les types entiers non nuls documentés ; n'en déduisez pas la même garantie pour tout enum qui semble petit aujourd'hui.

## `repr(transparent)` est plus précis que « même taille »

Un wrapper [`repr(transparent)`](https://doc.rust-lang.org/reference/type-layout.html#the-transparent-representation) possède la disposition et l'ABI de son unique champ de taille non nulle. C'est utile pour un identifiant typé traversant une frontière FFI :

```rust
#[repr(transparent)]
struct UserId(u64);
```

Un deuxième champ de taille non nulle détruit ce contrat. Le cours conserve le rejet comme doctest :

```rust
#[repr(transparent)]
struct InvalidTransparent(u32, u32);
```

La commande stable `cargo test --doc` vérifie que le snippet échoue. `cargo +nightly test --doc` vérifie en plus le code d'erreur exact E0690 au lieu de se fier à une sortie copiée.

## Correspondances avec C# et Java

| Question | Rust | C# | Java |
|---|---|---|---|
| Disposition inline d'une valeur | `struct`, attribut de représentation | type valeur et [`StructLayout`](https://learn.microsoft.com/dotnet/api/system.runtime.interopservices.structlayoutattribute) | les objets ordinaires ont une disposition gérée par la VM ; la [Foreign Function & Memory API](https://docs.oracle.com/en/java/javase/25/core/foreign-function-and-memory-api.html) modélise les dispositions natives explicites |
| ABI C stable | `repr(C)` | `LayoutKind.Sequential`/`Explicit` | `MemoryLayout` |
| Wrapper ABI à un champ | `repr(transparent)` | aucun équivalent général exact | aucun équivalent général exact |
| Interroger la cible | `size_of`, `align_of`, `offset_of` | `Unsafe.SizeOf`, `Marshal.OffsetOf`, avec une sémantique objet/valeur différente | API de layout pour la mémoire étrangère, pas les détails arbitraires des objets |

Une `struct` Rust n'est pas automatiquement l'équivalent d'une classe C# ou d'un objet Java : elle n'a pas d'en-tête d'objet du seul fait d'être une struct, et son emplacement dépend de son propriétaire.

## Exercices

### 1. Prédire avant d'exécuter

Ajoutez un champ `u16` aux deux packets. Écrivez les offsets et tailles attendus avant de compiler, puis utilisez `offset_of!` pour tester votre prédiction.

<details>
<summary>Solution</summary>

Avec `repr(C)`, partez de l'offset courant arrondi au prochain multiple de l'alignement du champ, puis arrondissez la taille finale à l'alignement de la struct. Le meilleur ordre dépend de la position du `u16` ; si votre prédiction était fausse, gardez-la dans vos notes.

</details>

### 2. Coder l'absence sans mot supplémentaire

Définissez un newtype `Handle` autour de `NonZeroUsize`. Comparez `size_of::<Handle>()` et `size_of::<Option<Handle>>()`.

<details>
<summary>Solution</summary>

```rust
use std::num::NonZeroUsize;

#[repr(transparent)]
struct Handle(NonZeroUsize);

assert_eq!(std::mem::size_of::<Handle>(), std::mem::size_of::<Option<Handle>>());
```

Le wrapper transparent préserve le contrat de valeurs valides du type interne ; l'option conserve donc sa niche.

</details>

### 3. Choisir délibérément la représentation

Choisissez `repr(Rust)`, `repr(C)` ou `repr(transparent)` pour : un état interne de parseur, un packet envoyé à une bibliothèque C et un identifiant `u64` fortement typé traversant cette bibliothèque.

<details>
<summary>Solution</summary>

- état interne du parseur : `repr(Rust)` par défaut, sauf autre exigence mesurée ;
- packet C : `repr(C)`, avec des types de champs ayant eux-mêmes une représentation définie à la frontière ;
- identifiant à un champ : `repr(transparent)` autour de `u64`.

L'attribut est nécessaire, mais insuffisant : ownership, validité, endianness et lifetime sont des contrats distincts de la frontière.

</details>

## Ce que cela prouve — et ne prouve pas

Le programme prouve la disposition imprimée sur la cible qui l'a exécuté, et la CI testera les trois cibles 64 bits hébergées. Il ne prouve pas une ABI stable pour `repr(Rust)`, qu'une struct plus petite accélère tout un programme, ni que le résultat vaut sur une cible 32 bits ou inhabituelle.

Suite : allocation, coût de l'ownership et traces déterministes de `Drop`.
