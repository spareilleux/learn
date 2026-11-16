---
module_id: "cyb-011-prevent-integral-accumulation-under-saturation"
department: "cybernetics"
course: "Evitar la acumulación integral durante la saturación"
title: "Evitar la acumulación integral durante la saturación"
level: "intermediate"
prerequisites: ["cyb-008-check-convergence-before-repeating-a-correction"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Evitar la acumulación integral durante la saturación

> **Alcance del borrador.** Modelos fijos elaborados con fuentes inspeccionadas. Siguen pendientes las decisiones humanas técnicas, lingüísticas y de aprendizaje. No se afirma ningún resultado de flota activa, controlador de producción, telemetría ni mejora del aprendizaje. El diario distingue pruebas ejecutadas, lecturas y comprobaciones previstas.

## Fuentes que deben inspeccionarse

- [cyb-008-check-convergence-before-repeating-a-correction.md](../../cybernetics/en/cyb-008-check-convergence-before-repeating-a-correction.md)
- [anti-windup-control-using-a-pid-controller.html](https://www.mathworks.com/help/simulink/slref/anti-windup-control-using-a-pid-controller.html)

Un controlador de agentes propuesto acumula error mientras la acción solicitada está limitada. Cuando el error invierte su signo, la demanda almacenada puede seguir apuntando con fuerza en la dirección anterior. El requisito previo de convergencia no tiene saturación. Esta lección añade un límite explícito y compara el estado integral almacenado con la orden aplicada. Ninguna secuencia representa un controlador GA medido.

La documentación primaria distingue limitar la salida de los métodos que modifican el integrador interno. Lea su explicación de la integración condicional. Nuestra regla elaborada es deliberadamente más estricta que un controlador ajustado: rechaza todo el incremento cuando el candidato supera un límite y el error empuja aún más hacia fuera. Facilita la auditoría y expone un coste de la regla. No se presenta como la implementación exacta del producto.

La versión ingenua almacena cada candidato y limita únicamente la orden aplicada. El límite impide superar el rango declarado, pero el estado interno sigue creciendo. Un error negativo posterior reduce ese estado sin cambiar necesariamente la salida saturada. Conservar solo la salida ocultaría la diferencia entre la cantidad solicitada y la aplicada. El operador necesita ambas para entender por qué la orden permanece en el límite.

La versión condicional rechaza incrementos hacia fuera y evita el exceso almacenado en este ejemplo. Sin embargo, su paso grueso deja sin utilizar parte del rango disponible: el primer candidato sobrepasa el límite y se rechaza por completo. Esta limitación se conserva; no se oculta como un éxito de implementación. Otra regla podría proyectar el estado al límite, utilizar retrocálculo o elegir una actualización distinta; cada opción requeriría una recurrencia declarada.

Para la tarea asistida por fuentes, contraste la iteración sin restricciones del requisito previo con la explicación de saturación. Construya una tabla manual con candidato, estado almacenado y orden aplicada en columnas separadas. Pida a un asistente que la calcule y explique la objeción del rango desaprovechado. Rechace propuestas que deduzcan estabilidad solo por limitar, sustituyan la regla en silencio o describan estos valores elaborados como mediciones de recursos activos.

## Caso fijo y cálculos esperados

```json
{
  "values": {
    "initial_integral": 0,
    "errors": [
      3,
      3,
      3,
      -1
    ],
    "dt_seconds": 1,
    "gain": 1,
    "lower_limit": 0,
    "upper_limit": 2
  },
  "formula": "candidate=I+gain*error*dt; naive stores candidate; conditional stores candidate unless beyond a limit and error drives farther outward; command=clip(I,lower,upper)",
  "expected": {
    "naive_integrals": [
      3,
      6,
      9,
      8
    ],
    "naive_commands": [
      2,
      2,
      2,
      2
    ],
    "conditional_integrals": [
      0,
      0,
      0,
      0
    ],
    "conditional_commands": [
      0,
      0,
      0,
      0
    ]
  },
  "negative_control": "With sufficiently wide limits both rules integrate the same error sequence.",
  "assumptions": [
    "Integral-only teaching controller, no proportional term or plant dynamics, update then output, outward-increment rejection."
  ],
  "limits": "The deliberately strict rule is not a tuned production anti-windup controller and may fail to use available actuator range."
}
```

## Conservar un intento de aprendizaje con sus fuentes

Trabaje con las entradas fijadas anteriores. Antes de pedir ayuda, escriba su predicción para el caso fijo y el control negativo, incluida la unidad de cada cantidad y la frontera exacta de comparación. Una tabla breve en papel es la referencia manual directa. Conserve valores intermedios, especialmente los que contradigan su primera predicción. Esta tarea explicativa utiliza fuentes existentes y datos fijos; no exige instalar paquetes, llamar servicios de pago ni introducir un programa nuevo.

Después utilice un asistente para localizar el pasaje pertinente y criticar su cálculo. Conserve la instrucción original, la respuesta, la ubicación citada y los cambios aceptados o rechazados. Una cita solo resulta útil cuando el contenido inspeccionado respalda la afirmación concreta. Una etapa declarada, un tipo de datos y un comentario aportan pruebas diferentes de un resultado ejecutado. Explique esa frontera en la respuesta final en vez de atribuir autoridad a una etiqueta aparentemente satisfactoria.

Entregue juntos la referencia manual, el resultado corregido, el control, el criterio de refutación y el historial de ayuda. Los criterios preparados preguntan si se identificó el alcance, se calculó correctamente, se conservó el contraejemplo, las fuentes respaldaron la explicación y la conclusión respetó sus límites. Siguen indecisos hasta existir una respuesta real de un aprendiz. Las soluciones siguientes están preparadas: no demuestran aprendizaje. El evaluador debe conservar cada criterio fallido y su motivo antes de corregirlo y juzgar por separado el intento revisado. Las pruebas de ejecución y publicación que se recojan después necesitan registros propios ligados a la revisión.

### Ejercicio 1

Calcule los estados y órdenes ingenuos.

<details>
<summary>Respuesta 1</summary>

Estados `[3,6,9,8]`; órdenes `[2,2,2,2]`.

</details>

### Ejercicio 2

Calcule los estados condicionales.

<details>
<summary>Respuesta 2</summary>

`[0,0,0,0]`; la regla declarada rechaza cada incremento propuesto hacia fuera.

</details>

### Ejercicio 3

¿Por qué el error invertido deja limitada la salida ingenua?

<details>
<summary>Respuesta 3</summary>

La integral almacenada baja de `9` a `8`, todavía por encima del límite `2`.

</details>

### Ejercicio 4

Indique la debilidad conservada de la regla condicional.

<details>
<summary>Respuesta 4</summary>

Rechazar todo un incremento excesivo deja sin utilizar parte del rango disponible.

</details>

### Ejercicio 5

Evalúe el control con límites amplios.

<details>
<summary>Respuesta 5</summary>

Si ningún candidato alcanza un límite, ambas reglas almacenan la misma secuencia integral.

</details>

[Paquete de pruebas fijas](../../../../code/streeling/evidence/batch50-2026-10-23/unit-b.json) · [Diario de validación](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
