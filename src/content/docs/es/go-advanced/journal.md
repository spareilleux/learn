---
title: "Diario de aprendizaje"
description: "Progreso de redacción, evidencia de verificación y experimentos pendientes de Go avanzado."
sidebar:
  order: 99
---

## Progreso

- [x] Lección escrita 1 — [Límites de paquetes y módulos](../01-package-and-module-boundaries/)
- [x] Lección escrita 2 — [Memoria, análisis de escape y GC](../02-memory-escape-and-gc/)
- [x] Lección escrita 3 — [Genéricos e iteradores](../03-generics-and-iterators/)
- [x] Lección escrita 4 — [Contratos de error y nil tipado](../04-error-contracts-and-typed-nil/)
- [x] Lección escrita 5 — [Modelo de memoria, sincronización y atómicos](../05-memory-model-sync-and-atomics/)
- [x] Lección escrita 6 — [Pipelines con concurrencia limitada](../06-bounded-pipelines/)
- [x] Lección escrita 7 — [Cancelación, plazos y cierre](../07-cancellation-deadlines-and-shutdown/)
- [x] Lección escrita 8 — [Fronteras HTTP en producción](../08-production-http/)
- [x] Lección escrita 9 — [Flujos y delimitación de mensajes](../09-streaming-and-framing/)
- [x] Lección escrita 10 — [Pruebas de carreras, fuzzing y propiedades](../10-race-fuzz-and-property-tests/)
- [x] Lección escrita 11 — [Benchmarks, pprof y trace](../11-benchmarks-pprof-and-trace/)
- [x] Lección escrita 12 — [Reflexión, codificación y fronteras](../12-reflection-and-encoding/)
- [x] Lección escrita 13 — [Dependencias, compilaciones y seguridad](../13-dependencies-builds-and-security/)
- [x] Lección escrita 14 — [Un servicio integrado de trabajos HTTP](../14-service-capstone/)
- [x] Pruebas del módulo integrado, vet, formato y catorce salidas exactas.
- [x] Correspondencia entre fuentes y fragmentos, enlaces de artículos traducidos construidos.
- [x] Fuzzing activo acotado de los objetivos escritos.
- [x] CI alojada Windows/Linux/macOS y detector de carreras Linux.
- [x] Lectura anónima de páginas públicas tras el despliegue Pages.
- [ ] Estudio con alumnos y revisión lingüística independiente.

## QA

| Esperado / observado | Ubicación y medida | Estado |
| --- | --- | --- |
| Una cabecera completa no nula sin cuerpo debería indicar una trama truncada. | [framing/frame.go:50](https://github.com/spareilleux/learn/blob/7afa6d69bf354ead998b05303ac940075f7d548b/code/go-advanced/framing/frame.go#L50); EOF inicial; regresión fallida. La normalización hace pasar las pruebas existentes y la nueva. Implementación inicial refutada. | Corregido antes de publicar |

## Experimentos

| Pregunta / hipótesis antes de probar | Resultado / veredicto |
| --- | --- |
| Una cabecera completa no nula sin cuerpo debería indicar una trama truncada. | EOF inicial; regresión fallida. La normalización hace pasar las pruebas existentes y la nueva. Implementación inicial refutada. [Go](https://github.com/spareilleux/learn/tree/main/code/go-advanced) · [Entrada fechada](#2026-11-07--revisión-contraejemplos-y-correcciones) · [JSON](https://github.com/spareilleux/learn/blob/main/docs/verification/2026-11-07-go-courses-local.json) |


## 2026-11-07 — Redacción y verificación preliminar del módulo

Se escribieron las catorce lecciones, la misión y los ejercicios resueltos en inglés, francés y español. El código es un módulo independiente que solo usa la biblioteca estándar, con catorce órdenes y paquetes reutilizables de dominio, iteración, pipeline, tramas, codificación, procedencia, HTTP y servicio de trabajos. Los listados proceden de archivos Go versionados y formateados; no hay comentarios en lenguaje natural que requieran variantes entre traducciones.

Se hicieron explícitas varias decisiones didácticas. Los trabajos copian segmentos del consumidor al admitirse, sin confiar en una convención de constructor para estructuras exportadas. Productor y coordinador poseen los cierres del pipeline. El servicio serializa admisión y cierre, reserva una respuesta con búfer por tarea y detiene definitivamente la admisión durante el vaciado. Las tramas comprueban la longitud antes de asignar y admiten escrituras parciales. Son decisiones escritas, no relatos de experimentos fallidos.

El coordinador comunicó una ejecución preliminar real de `go test -count=1 -timeout=60s ./...` con Go 1.27.1 en Windows/amd64 y CGO desactivado: compilaron los catorce paquetes de órdenes y pasaron los ocho paquetes de pruebas. El autor del curso no ejecutó esa orden independientemente. Es evidencia preliminar; el registro final debe vincular pruebas, fragmentos, salidas exactas, traducciones y revisión publicada. Las casillas marcadas indican redacción, no publicación ni aceptación humana.

Se consultó documentación Go 1.27 para evitar restricciones antiguas sobre métodos genéricos y descripciones todavía experimentales de JSON v2. Nil tipado, lecturas parciales y cancelación cooperativa son comportamientos documentados que sorprenden desde C#/Java, no errores del proyecto Go. No se abrió ninguna incidencia externa. Todavía no hay tabla QA de defectos ni tabla Experimentos de hipótesis medidas: el autor no estableció ninguna.

## 2026-11-07 — Verificación técnica integrada

Los dos módulos se ejecutaron con Go 1.27.1 en Windows/amd64, con CGO desactivado. En este módulo pasaron `go test -count=1 -timeout=60s ./...`, `go vet ./...`, las comprobaciones de formato y los catorce ejemplos `go run ./cmd/lNN`. Cada salida coincide exactamente con `examples.json`, incluido el salto final. La comprobación integrada valida 96 páginas, fragmentos Go idénticos al código fuente, 84 bloques de salidas traducidos, soluciones y estructura de diarios. La construcción del sitio pasó; los enlaces de artículos y sus anclas se resuelven en las 99 rutas afectadas. El [registro de verificación legible por máquina](https://github.com/spareilleux/learn/blob/main/docs/verification/2026-11-07-go-courses-local.json) conserva comandos, resultados y huellas SHA-256 de las fuentes.

Los ensayos acotados usan `-fuzztime=5s -parallel=2`: pasaron `FuzzLoad` del módulo estándar y `FuzzReverse` más `FuzzFrames` del avanzado. También pasó la ejecución del benchmark avanzado de una sola iteración; no constituye una referencia de rendimiento representativa. Tras simplificar el ejemplo JSON mediante `bytes.NewReader`, volvieron a pasar las pruebas estándar, la salida exacta de ese ejemplo y vet. Los fragmentos se sincronizaron en los tres idiomas.

La auditoría descubrió un defecto real del verificador: detectar el marcador `TODO` sin distinguir mayúsculas rechazaba el término español corriente « todo ». Una regresión falló primero y pasó tras corregir esa distinción; pasan las dieciséis regresiones del verificador y las diecinueve pruebas Node existentes. Era un fallo de validación de cursos, no de Go. No se afirma haber realizado un estudio con alumnos, análisis de vulnerabilidades, perfil CPU, traza ni informe de escape. CI alojada, detector de carreras y publicación siguen siendo evidencias separadas.


## 2026-11-07 — Revisión, contraejemplos y correcciones

La revisión desde seis perspectivas confirmó tres puntos: clasificación de EOF en una trama, falta de una prueba de cancelación después del inicio y enlaces ausentes a las API oficiales de iteración. Los tres están corregidos. Una cabecera completa que anunciaba un cuerpo no vacío, seguida de cero bytes, hacía fallar la nueva regresión: EOF en vez de unexpected EOF. Tras normalizar ese error, pasan las pruebas existentes y la nueva regresión. Se conservan los casos de EOF antes de cabecera, trama vacía, cuerpo parcial y otros errores del lector. El código mostrado se sincronizó en los tres idiomas.

Una prueba coordinada mediante canales cancela ahora Squares después del inicio, superada la comprobación inicial de Err; exige context.Canceled y terminación dentro del plazo de vigilancia. Otra prueba libera simultáneamente dieciséis llamadas Submit y dos llamadas Drain, comprueba todas las respuestas aceptadas y deja la primera sin leer hasta que ambos cierres terminen. Ambos paquetes superaron veinte ejecuciones consecutivas. Esto ejercita las duraciones declaradas sin explorar todos los órdenes posibles del planificador; no se observó ningún bloqueo en producción.

El validador permanente compara ahora los bloques de salida de cada traducción con examples.json. Una salida española inventada escapaba inicialmente al control y hacía fallar una regresión; la corrección la rechaza y pasan las diecisiete regresiones. Una prueba nativa de Windows mostró además que -run=^$ sin comillas llega al proceso hijo como -run=$. Las comillas de -run="^$" conservan el argumento previsto; se corrigieron las instrucciones de benchmark en los tres idiomas. El [registro de verificación](https://github.com/spareilleux/learn/blob/main/docs/verification/2026-11-07-go-courses-local.json) conserva los contraejemplos, los resultados y las huellas finales de las fuentes. La CI alojada y la lectura pública siguen pendientes en esta entrada.

## 2026-11-07 — Pruebas alojadas y publicación pública

El [workflow Go](https://github.com/spareilleux/learn/actions/runs/42404338250) superó sus nueve jobs: ambos módulos en Windows, Linux y macOS, dos jobs Linux de detección de carreras y el validador de cursos. El [despliegue Pages](https://github.com/spareilleux/learn/actions/runs/42405574875) publicó la revisión `cd8ca24400c1591d56dc0878ba52974fd6e54b4d`. Después, peticiones HTTP anónimas verificaron las 99 rutas previstas: 96 documentos de los cursos, incluidos seis diarios, y tres páginas de inicio en EN/FR/ES. Los títulos, el idioma, las URL canónicas, los índices de catorce lecciones, los ejercicios resueltos y los enlaces de inicio coincidieron con lo previsto. El [registro público](https://github.com/spareilleux/learn/blob/main/docs/verification/2026-11-07-go-courses-public.json) conserva cada URL, la hora de observación y el SHA-256 del HTML, junto con la identidad del despliegue y de la CI. Esto confirma la publicación y las comprobaciones técnicas ejecutadas; siguen pendientes la prueba con alumnos, la revisión lingüística independiente y el perfilado representativo.

## Por verificar

- Medir una carga representativa antes de extraer conclusiones de benchmarks, perfiles, trazas o escape.
- Observar intentos reales de ejercicios y obtener revisión lingüística independiente; todavía no se han realizado.

## Preguntas abiertas

- ¿Puede un desarrollador C#/Java explicar por qué cancelar una petición no implica reversión transaccional?
- ¿Puede el alumno identificar al propietario de cada cierre de canal sin abrir las soluciones?
- ¿Ayuda el método común de lectura a distinguir garantías semánticas de mediciones del compilador?
- ¿Qué contratos de persistencia e identidad permitirían repetir efectos externos con seguridad?
