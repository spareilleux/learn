---
title: "5. Jev × Petri: clasificar evidencia, nunca conceder efectos"
description: Un tracer ejecutable y sin conexión que expone el camino inseguro desde el consejo hasta la autoridad y comprueba una alternativa protegida.
sidebar:
  order: 5
---

Este experimento conecta dos cursos sin poner un modelo en la ruta de control de producción. [Jev](../../typesafe-ai-system-one/05-confidence-gate-stress/) proporciona una **clasificación consultiva sintética**; el [motor de redes de Petri](../../petri-nets/14-on-our-systems/) enumera lo que permitiría un flujo de control propuesto. Ninguno verifica por sí solo una transición real de Gaia o IX.

## Pregunta y baseline

¿Puede un umbral de confianza autorizar una implementación? El caso fijado [`gaia_design_authority`](https://github.com/spareilleux/learn/blob/main/code/typesafe-ai-system-one/benchmark-corpus.json) espera `contradicted`: existe un Design Receipt aprobado, pero no una concesión de implementación. El banco de estrés sintético devuelve deliberadamente `supported` con 0,98. **No** es una respuesta de la API Jev ni un error medido del modelo.

La red insegura consume ese token consultivo y produce `effect`. Su testigo más corto es `classify → authorize_from_advisory`. La red protegida envía el consejo a revisión y `authorize` exige **tanto** evidencia verificada de forma independiente como autoridad de implementación. Los tokens se usan una sola vez en este pequeño modelo finito; la política real puede diferir.

```text
elección Jev sintética ──> consejo ──> revisión ──> confirmado ───┐
                              evidencia verificada ────────────────┤ authorize ──> efecto
                              concesión de implementación ─────────┘
```

Las dos entradas de la derecha deben proceder de recibos verificados independientemente, nunca de la confianza Jev ni del propio modelo. Un marcado de Petri describe supuestos; no crea recibos reales.

## Ejecutar el tracer acotado

Desde la raíz del repositorio:

```bash
python -m unittest discover -s code/typesafe-ai-system-one -p 'test_jev_gate_audit.py' -v
python -m unittest discover -s code/repository-dogfooding-lab -p 'test_jev_petri_fixture.py' -v
dotnet test code/petri-nets/Tests -c Release --filter JevEvidenceGateTests
```

La [fixture](https://github.com/spareilleux/learn/blob/main/code/repository-dogfooding-lab/jev-petri-fixture.json) se compara con la respuesta sintética de Python y la leen las [pruebas C#](https://github.com/spareilleux/learn/blob/main/code/petri-nets/Tests/JevEvidenceGateTests.cs). La [definición de las redes](https://github.com/spareilleux/learn/blob/main/code/petri-nets/Examples/JevEvidenceGate.cs) reutiliza el motor del curso. Las pruebas exigen accesibilidad completa: el efecto inseguro es alcanzable, el protegido no lo es si falta cualquiera de las dos condiciones, y sigue existiendo una ruta autorizada cuando ambas están presentes.

## Lo que no demuestra

- No hubo llamadas a TypeSafe, medición de tokens facturados ni estimación de calidad de Jev.
- No se leyó ni modificó el estado de producción de Gaia o IX. El texto del caso es una fixture didáctica fijada, no un recibo de autoridad actual.
- La red protegida comprueba una abstracción finita. No demuestra que el código real imponga las mismas guardas, que los recibos sean auténticos ni que la concurrencia y los reintentos las preserven.

## Próximo gate de dogfooding

Fijar una transición real de Gaia o IX y su revisión. Asociar los campos del recibo autorizado con los lugares de la red; inyectar evidencia ausente o falsificada; reproducir el testigo inseguro en un seam público. Comparar con una prueba sencilla de guarda determinista. Incubar solo si el modelo descubre un fallo que esa prueba no detecta y una revisión independiente acepta la correspondencia. De lo contrario, conservar la prueba sencilla y rechazar este modelo adicional.
