---
title: "6. Sandcastle: una ejecución aislada de un agente"
description: Construir un laboratorio Sandcastle acotado con Docker, una rama explícita, una iteración y verificación controlada por el host.
sidebar:
  order: 6
---

[Sandcastle](https://github.com/mattpocock/sandcastle/tree/e99f832f26dc9d245c019a9ddd19fa5dee792427) es una biblioteca TypeScript que ejecuta agentes de código en sandboxes y gestiona sus ramas y commits. Esta lección está fijada en el commit `e99f832f` y la versión 0.12.0, comprobados el 20 de septiembre de 2026.

Sandcastle es un harness de ejecución, no un método de requisitos. El prompt y el host aún deciden qué trabajo es válido, cómo se verifica y si un commit resultante puede fusionarse.

## Prepara un laboratorio desechable

Requisitos previos: Git, Node.js y Docker o Podman. No empieces en un repositorio de producción.

```bash
npm install --save-dev @ai-hero/sandcastle
npx @ai-hero/sandcastle init
```

El inicializador crea `.sandcastle/`. Pon las credenciales del proveedor solo en `.sandcastle/.env`, mantenlo ignorado y nunca copies un token en una lección o transcripción. Un token de suscripción y una clave API tienen costes distintos: verifica el proveedor seleccionado antes de ejecutar.

## La ejecución útil más pequeña

```ts
import { run, claudeCode } from "@ai-hero/sandcastle";
import { docker } from "@ai-hero/sandcastle/sandboxes/docker";

const result = await run({
  agent: claudeCode("<verified-model-id>"),
  sandbox: docker(),
  branchStrategy: { type: "branch", branch: "agent/tutorial" },
  promptFile: ".sandcastle/prompt.md",
  maxIterations: 1,
});

console.log(result.branch, result.commits);
```

Ejecuta el punto de entrada generado con el nombre creado por tu versión instalada, actualmente:

```bash
npx tsx .sandcastle/main.mts
```

`prompt.md` es una convención, no un fallback automático: pásalo mediante `promptFile`. Una estrategia `branch` explícita deja el trabajo disponible para inspección. `head` escribe directamente en el checkout del host; `merge-to-head` fusiona una rama temporal en `HEAD`. Ninguna es adecuada para el primer ejercicio.

## La puerta de evidencia

Después de la ejecución, el host —no el modelo— debe inspeccionar:

1. `result.branch` y `result.commits`;
2. el diff exacto contra el commit inicial;
3. la salida determinista de las pruebas;
4. el registro y código de salida de la sandbox;
5. cualquier límite de red, credenciales o coste cruzado.

No fusiones nada durante este ejercicio. Una iteración basta para demostrar el harness, el límite de rama y la ruta de evidencia.

## El aislamiento no es autorización

Una sandbox limita un sistema de archivos y un entorno de procesos. No vuelve correcto un prompt no confiable, no protege todos los secretos de red, no concede permiso para push ni demuestra que el cambio satisface al usuario. Los valores predeterminados del proveedor pueden automatizar aprobaciones dentro de la sandbox, así que el host aún debe imponer alcance, presupuesto y condición de parada.

Evita `noSandbox()` en este laboratorio: elimina deliberadamente el aislamiento. Evita proveedores cloud y API de pago hasta revisar explícitamente su presupuesto y ruta de credenciales.

:::caution[Deriva de la documentación upstream]
En la revisión fijada, una página antigua todavía menciona `.sandcastle/config.json` y diez iteraciones por defecto. El README y las plantillas generadas actuales configuran directamente la API TypeScript y documentan una iteración por defecto. Sigue el README fijado y la plantilla generada, y vuelve a comprobar upstream antes de actualizar esta lección.
:::

## Ejercicio

Crea un repositorio desechable con una prueba roja y pide al agente que solo haga pasar esa prueba. Usa Docker, una rama nombrada y `maxIterations: 1`. El ejercicio solo pasa si el host puede mostrar el SHA inicial, el commit resultante, el diff y la prueba verde sin fusionar nada.

Continúa con [Compound Engineering](../07-compound-engineering/) para hacer explícitos los artefactos de planificación, implementación, revisión y aprendizaje.

