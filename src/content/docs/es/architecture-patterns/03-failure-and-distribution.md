---
title: 3 — Cuando un límite cruza un proceso
description: Estudiar respuestas perdidas, reintentos concurrentes, extracción de módulos y recuperación sin atribuir garantías distribuidas a un puerto.
sidebar:
  order: 3
---

## La respuesta perdida

El profesor pulsa Guardar. El servidor confirma la transacción; la conexión se cierra antes de recibir el recibo. Un reintento puede crear un duplicado aunque todas las dependencias apunten hacia dentro. La [guía de Amazon sobre API idempotentes](https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/) explica por qué la intención del llamador necesita identidad estable entre reintentos. Nuestro contrato específico es un diseño propuesto, **por verificar** en una implementación.

Usar una clave de idempotencia limitada al profesor autenticado y una huella del contenido canónico. Guardar clave, huella, plan y recibo en la misma transacción. Un reintento concurrente debe encontrar una restricción de unicidad o reserva atómica equivalente, no una consulta de existencia seguida de una inserción independiente.

| Evento | Resultado requerido | Observación de prueba |
|---|---|---|
| Respuesta perdida tras commit | El reintento devuelve el recibo persistido | Un plan; mismo ID y revisión |
| Dos peticiones idénticas simultáneas | Un commit; mismo resultado para ambas | Una clave y un plan al terminar |
| Misma clave, contenido diferente | Conflicto, ningún segundo plan | Huella y recibo originales intactos |
| Fallo de almacenamiento antes de commit | Ningún recibo de éxito | El reintento aún puede completarse |
| Revisión del catálogo rechazada al confirmar | Rechazo tipado por catálogo obsoleto | Ni plan ni recibo de éxito |

Definir la retención de claves. Cuando expire el registro, la misma clave podría crear otro plan; la idempotencia perpetua no está implícita. Decidir si se recuerdan los rechazos. Nuestra candidata registra solo commits exitosos: un rechazo por catálogo obsoleto puede reintentarse tras actualizarlo.

## Un puerto no convierte llamadas remotas en locales

Supongamos que Catalog pasa a otro proceso. La llamada queda sujeta a latencia, tiempo de espera, indisponibilidad, autenticación y versiones de esquema. Un timeout indica que el llamador no tiene resultado; no prueba que la acción remota fallara. Memoria prestada o una referencia local a un objeto no pueden ser el contrato de red.

El argumento más fuerte contra la extracción es que el mismo equipo sigue publicando ambos módulos juntos. La alternativa sencilla es una API pública de módulo en el proceso actual. Rechazar la extracción salvo que despliegue independiente, escalado o aislamiento produzcan un beneficio medido que compense operar otro servicio.

Si Practice debe validar el catálogo remoto más reciente atómicamente con su commit local, una petición normal seguida de una transacción local no lo garantiza. Elegir deliberadamente: aceptar una instantánea inmutable fijada, introducir un protocolo coordinado o relajar visiblemente la frescura exigida. Esta primera entrega elige instantáneas fijadas; cambiar la regla requiere una decisión de producto.

## Las notificaciones añaden otra transacción

Guardar un plan y avisar al alumno son dos efectos. Llamar a un servicio remoto de notificación dentro de una transacción local no vuelve atómicos ambos commits. Una opción guarda una notificación pendiente con el plan y deja que un worker la entregue. Los reintentos necesitan un ID de mensaje estable y deduplicación en el receptor. Es un ejercicio de outbox propuesto, no una garantía de entrega exactamente una vez.

Los costes ocultos incluyen colas de reintentos, mensajes imposibles de procesar, conciliación, retención y herramientas de soporte. Si avisar es opcional, mostrar el plan guardado en la interfaz actual es la opción inicial más sencilla.

## Ejercicio — Seguir el crash

Un worker entrega una notificación y falla antes de marcar el registro como entregado. Al reiniciarse vuelve a enviarla. ¿Qué debe especificar el contrato? Nombrar una métrica útil y un criterio para rechazar la funcionalidad.

<details>
<summary>Solución razonada</summary>

El receptor debe reconocer el mismo ID; de otro modo, los duplicados siguen siendo posibles y el producto debe aceptarlos. Marcar primero el registro solo cambia el riesgo por una notificación perdida. Medir la edad de la notificación pendiente más antigua y contar efectos duplicados por separado de intentos de entrega. Rechazar notificaciones automáticas si el receptor no puede deduplicar y los duplicados visibles son inaceptables. Mantener el recibo duradero del plan independiente del éxito de la notificación. Probar ambas ventanas de crash antes de afirmar entrega fiable; esta lección no las ha ejecutado.

</details>
