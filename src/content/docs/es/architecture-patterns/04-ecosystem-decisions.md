---
title: 4 — Evaluar un límite del ecosistema
description: Convertir ideas arquitectónicas en experimentos acotados y fijados a revisiones para GA, Gaia, IX y Demerzel sin afirmar adopción.
sidebar:
  order: 4
---

## Evidencia antes de migrar

El plan de práctica es inventado. Los repositorios siguientes son reales, pero su descripción arquitectónica no prueba que cada dependencia la respete. Se consultaron las versiones de los README enlazadas; aquí no se compiló, migró ni midió ninguna aplicación del ecosistema.

| Repositorio y contexto documentado | Límite candidato que investigar | Evidencia necesaria antes de adoptarlo |
|---|---|---|
| [GA](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/README.md): cinco capas, dominio musical y hosts de aplicaciones | Una operación independiente del host compartida por dos entradas existentes | Llamadores exactos, casos de paridad entrada/salida, referencias entre capas y rutas de despliegue |
| [Gaia](https://github.com/GuitarAlchemist/gaia/blob/d68e90099ae2a6fbbec9d428617bfcd02095aac0/README.md): coordinación y flujos de evidencia | Separar decisión de transición y adaptador de efectos externos | Casos de replay, propiedad de claims, duplicados y comprobación de autoridad en el efecto |
| [IX](https://github.com/GuitarAlchemist/ix/blob/490c39533627d296bf9f8f050e6fafc14d7a20c2/README.md): algoritmos y herramientas Rust | Entradas/resultados estables con interpretación específica de la herramienta fuera | Equivalencia numérica, casos versionados, asignaciones y latencia en una carga fija |
| [Demerzel](https://github.com/GuitarAlchemist/Demerzel/blob/c72fb746116346ce1991a4f108cd12f5e012e3fb/README.md): marco de gobernanza | Separar validación de evidencia y evaluación de políticas de la publicación | Compatibilidad de esquema, procedencia, pruebas de denegación y autoridad explícita de publicación |

Son **experimentos candidatos**, no refactorizaciones verificadas ni afirmaciones de adopción de clean o hexagonal. Las revisiones proceden de cursos existentes y del archivo de bloqueo de Streeling; son referencias de estudio, no afirmaciones sobre producción actual.

## Una decisión GA acotada, resuelta

**Problema:** dos entradas podrían codificar la misma regla de forma diferente. **Supuesto:** pretenden la misma semántica; comprobarlo antes de unificarlas. **Candidata:** exponer una operación común respetando las capas establecidas. El comportamiento de IA permanece en su capa permitida; «poner todo en el núcleo» no es un plan de migración.

**Objeción más fuerte:** los clientes difieren intencionalmente en streaming, historial o errores. **Costes ocultos:** conversión de modelos, cancelación, diagnósticos, responsabilidad del despliegue y compatibilidad. **Alternativa sencilla:** compartir la regla pura y mantener orquestaciones distintas.

**Prueba:** fijar un commit, elegir diez entradas explícitas que cubran éxito, entrada inválida, denegación y cancelación, y ejecutar ambos caminos existentes. Diez es un presupuesto propuesto, no un recuento de pruebas superadas. Después extraer solo la operación común mínima en una candidata aislada y repetir los casos.

**Aceptación:** ningún cambio observable sin explicar, ninguna referencia prohibida nueva y ejecución de la regla común sin iniciar un host web. **Refutación:** una entrada supuestamente compartida necesita semánticas incompatibles. **Rechazo:** abandonar la unificación si conservar esas semánticas añade más condiciones que compartir la regla actual. **Revisión:** un nuevo llamador o un defecto de paridad reproducido cambia la evidencia.

## Separar autoridad y arquitectura

En Gaia o Demerzel, una interfaz limpia no autoriza push, merge ni publicación. Separar el resultado de decisión del efecto y volver a comprobar autoridad donde ocurre el efecto. Un adaptador falso solo demuestra cómo el llamador trata una respuesta simulada; no demuestra permisos, concurrencia ni fallos del proveedor real.

Los contratos de artefactos entre repositorios también tienen obligaciones de versión, identidad y procedencia. Antes de cambiar un campo, identificar productor y consumidores y fijar sus revisiones de esquema. Compartir nombre de interfaz no prueba equivalencia de contratos.

## Ejercicio — Escribir una decisión rechazable

Elegir una fila. Escribir seis frases: problema observado, supuesto, candidata, objeción principal, aceptación medible y desencadenante de rechazo/revisión. Indicar la evidencia que falta.

<details>
<summary>Solución razonada: IX</summary>

«Sospechamos que interpretación y cálculo numérico cambian juntos; aún no está medido. Suponemos un límite de entrada/resultado estable y determinista. Expondremos un cálculo existente tras ese límite y dejaremos la interpretación en la herramienta. La objeción es copiar más datos en una ruta crítica. Aceptar solo si los casos con semilla fija conservan la tolerancia existente y las asignaciones/latencia medidas cumplen un presupuesto acordado antes de ejecutar. Rechazar si domina la conversión o divergen las semánticas; revisar al aparecer un segundo llamador». Faltan implementación exacta, carga de referencia, tolerancia, mediciones e inventario de llamadores. Es una propuesta comprobable, no un diseño adoptado por IX.

</details>

El [diario](../journal/) distingue la validación terminada del curso de los experimentos pendientes.
