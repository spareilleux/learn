---
title: "Go para desarrolladores C# y Java — Diario"
description: "Evidencia fechada de redacción y verificación del curso Go estándar."
sidebar:
  order: 99
---

## Progreso

- [x] Redactado: [Herramientas y módulos](../01-toolchain-and-modules/).
- [x] Redactado: [Valores, tipos y cadenas](../02-values-types-and-strings/).
- [x] Redactado: [Control de flujo y funciones](../03-control-flow-and-functions/).
- [x] Redactado: [Arrays y slices](../04-arrays-and-slices/).
- [x] Redactado: [Mapas y estructuras](../05-maps-and-structs/).
- [x] Redactado: [Punteros y métodos](../06-pointers-and-methods/).
- [x] Redactado: [Interfaces y composición](../07-interfaces-and-composition/).
- [x] Redactado: [Errores, defer y recursos](../08-errors-defer-and-resources/).
- [x] Redactado: [Archivos, JSON y Unicode](../09-files-json-and-unicode/).
- [x] Redactado: [Genéricos y colecciones](../10-generics-and-collections/).
- [x] Redactado: [Goroutines y canales](../11-goroutines-and-channels/).
- [x] Redactado: [HTTP y context](../12-http-and-context/).
- [x] Redactado: [Pruebas](../13-testing/).
- [x] Redactado: [Proyecto final de línea de comandos](../14-cli-capstone/).
- [x] Pruebas del módulo integrado, vet, formato y catorce salidas exactas.
- [x] Correspondencia entre fuentes y fragmentos, enlaces de artículos traducidos construidos.
- [x] Fuzzing activo acotado de los objetivos escritos.
- [ ] CI alojada Windows/Linux/macOS y detector de carreras Linux.
- [ ] Lectura anónima de páginas públicas tras el despliegue Pages.
- [ ] Estudio con alumnos y revisión lingüística independiente.

## QA

| Esperado / observado | Ubicación y medida | Estado |
| --- | --- | --- |
| El término español habitual todo debería aceptarse en la prosa. | [scripts/tests/test_check_go_courses.py](https://github.com/spareilleux/learn/blob/7afa6d69bf354ead998b05303ac940075f7d548b/scripts/tests/test_check_go_courses.py#L164); Rechazo inicial; la regresión falló y después pasaron las 16 regresiones originales al distinguir mayúsculas. Hipótesis refutada antes de corregir. | Corregido antes de publicar |

## Experimentos

| Pregunta / hipótesis antes de probar | Resultado / veredicto |
| --- | --- |
| El término español habitual todo debería aceptarse en la prosa. | Rechazo inicial; la regresión falló y después pasaron las 16 regresiones originales al distinguir mayúsculas. Hipótesis refutada antes de corregir. [Go](https://github.com/spareilleux/learn/tree/main/code/go-for-csharp-java) · [Entrada fechada](#2026-11-07--revisión-contraejemplos-y-correcciones) · [JSON](https://github.com/spareilleux/learn/blob/main/docs/verification/2026-11-07-go-courses-local.json) |


## 2026-11-07 — Curso redactado y verificación preliminar del módulo

El curso estándar se redactó como curso general de Learn, fuera de Streeling. Catorce lecciones avanzan desde módulos y semántica de valores hasta un CLI real de registro de estudio. Las versiones inglesa, francesa y española contienen explicaciones completas y dos ejercicios resueltos por lección. Coinciden nombres de archivo, fragmentos Go, comandos y contratos de salida esperada.

El ejemplo mantiene coherencia: internal/study posee registros tipados, selección, totales, lectura JSON y flujo cancelable; internal/cli compone opciones, adquisición e informes; internal/webapi ofrece una frontera HTTP pequeña probada en memoria. El comando final reutiliza esos paquetes en lugar de repetir una demostración aislada. El módulo no tiene dependencias externas.

Los fragmentos se extrajeron directamente de main.go ya formateados, evitando divergencia entre fuentes y traducciones. La lección trece también reproduce exactamente una función de prueba compilada. Las salidas esperadas se escribieron en examples.json antes de ejecutar y siguen etiquetadas como esperadas hasta la comprobación final del coordinador sobre los artefactos completos. No se inventaron diagnósticos del compilador ni mediciones de rendimiento.

Se incorporó una corrección específica de versión: Go 1.27 permite métodos genéricos concretos, mientras que los métodos de interfaces todavía no pueden declarar parámetros de tipo propios. El comportamiento JSON se vincula a las API encoding/json reales y a pruebas explícitas, sin asumir una implementación antigua. Otra distinción importante: un puntero nil dentro de una interfaz conserva su tipo dinámico y no constituye una interfaz nil.

El coordinador comunicó una ejecución preliminar correcta del módulo con Go 1.27.1 en Windows/amd64 y CGO desactivado. El comando exacto fue go test -count=1 -timeout=60s ./... desde code/go-for-csharp-java. Compilaron los catorce paquetes de comandos y pasaron las pruebas de cli, study y webapi. Es un resultado proporcionado por el coordinador; este agente de redacción no ejecutó pruebas Go. La verificación final debe vincular esa evidencia al código y documentación terminados.

El código se formateó con gofmt. Las pruebas escritas cubren alias y clonación de slices, mutación de estructuras, interfaces con nil tipado, validación y causas envueltas, JSON malformado, UTF-8 inválido, bytes y runas, fronteras y orden de selección, transformación genérica, cancelación, HTTP y fallos de entrada/salida CLI. Existe un objetivo de fuzzing; no se afirma una campaña, mediciones de rendimiento ni una sesión humana de aprendizaje.

El coordinador ejecutó después los catorce comandos del curso estándar y confirmó que todas las salidas coincidían exactamente con examples.json, incluidos los saltos finales. También comunicó que go vet ./... y las comprobaciones de formato pasaron en el mismo entorno Go 1.27.1 de Windows con CGO desactivado. Son resultados preliminares reales, no capturas inventadas; todavía falta vincular documentación terminada y estado de publicación mediante comprobaciones finales.

## 2026-11-07 — Verificación técnica integrada

Los dos módulos se ejecutaron con Go 1.27.1 en Windows/amd64, con CGO desactivado. En este módulo pasaron `go test -count=1 -timeout=60s ./...`, `go vet ./...`, las comprobaciones de formato y los catorce ejemplos `go run ./cmd/lNN`. Cada salida coincide exactamente con `examples.json`, incluido el salto final. La comprobación integrada valida 96 páginas, fragmentos Go idénticos al código fuente, 84 bloques de salidas traducidos, soluciones y estructura de diarios. La construcción del sitio pasó; los enlaces de artículos y sus anclas se resuelven en las 99 rutas afectadas. El [registro de verificación legible por máquina](https://github.com/spareilleux/learn/blob/main/docs/verification/2026-11-07-go-courses-local.json) conserva comandos, resultados y huellas SHA-256 de las fuentes.

Los ensayos acotados usan `-fuzztime=5s -parallel=2`: pasaron `FuzzLoad` del módulo estándar y `FuzzReverse` más `FuzzFrames` del avanzado. También pasó la ejecución del benchmark avanzado de una sola iteración; no constituye una referencia de rendimiento representativa. Tras simplificar el ejemplo JSON mediante `bytes.NewReader`, volvieron a pasar las pruebas estándar, la salida exacta de ese ejemplo y vet. Los fragmentos se sincronizaron en los tres idiomas.

La auditoría descubrió un defecto real del verificador: detectar el marcador `TODO` sin distinguir mayúsculas rechazaba el término español corriente « todo ». Una regresión falló primero y pasó tras corregir esa distinción; pasan las dieciséis regresiones del verificador y las diecinueve pruebas Node existentes. Era un fallo de validación de cursos, no de Go. No se afirma haber realizado un estudio con alumnos, análisis de vulnerabilidades, perfil CPU, traza ni informe de escape. CI alojada, detector de carreras y publicación siguen siendo evidencias separadas.


## 2026-11-07 — Revisión, contraejemplos y correcciones

La revisión desde seis perspectivas confirmó tres puntos: clasificación de EOF en una trama, falta de una prueba de cancelación después del inicio y enlaces ausentes a las API oficiales de iteración. Los tres están corregidos. Una cabecera completa que anunciaba un cuerpo no vacío, seguida de cero bytes, hacía fallar la nueva regresión: EOF en vez de unexpected EOF. Tras normalizar ese error, pasan las pruebas existentes y la nueva regresión. Se conservan los casos de EOF antes de cabecera, trama vacía, cuerpo parcial y otros errores del lector. El código mostrado se sincronizó en los tres idiomas.

Una prueba coordinada mediante canales cancela ahora Squares después del inicio, superada la comprobación inicial de Err; exige context.Canceled y terminación dentro del plazo de vigilancia. Otra prueba libera simultáneamente dieciséis llamadas Submit y dos llamadas Drain, comprueba todas las respuestas aceptadas y deja la primera sin leer hasta que ambos cierres terminen. Ambos paquetes superaron veinte ejecuciones consecutivas. Esto ejercita las duraciones declaradas sin explorar todos los órdenes posibles del planificador; no se observó ningún bloqueo en producción.

El validador permanente compara ahora los bloques de salida de cada traducción con examples.json. Una salida española inventada escapaba inicialmente al control y hacía fallar una regresión; la corrección la rechaza y pasan las diecisiete regresiones. Una prueba nativa de Windows mostró además que -run=^$ sin comillas llega al proceso hijo como -run=$. Las comillas de -run="^$" conservan el argumento previsto; se corrigieron las instrucciones de benchmark en los tres idiomas. El [registro de verificación](https://github.com/spareilleux/learn/blob/main/docs/verification/2026-11-07-go-courses-local.json) conserva los contraejemplos, los resultados y las huellas finales de las fuentes. La CI alojada y la lectura pública siguen pendientes en esta entrada.

## Por verificar

- Consultar CI alojada en Windows, Linux y macOS, incluido el detector de carreras Linux.
- Leer anónimamente las páginas EN/FR/ES desplegadas y registrar la revisión publicada.
- Medir una carga representativa antes de extraer conclusiones de benchmarks, perfiles, trazas o escape.
- Observar intentos reales de ejercicios y obtener revisión lingüística independiente; todavía no se han realizado.

## Preguntas abiertas

- ¿Explican los lectores C# y Java el nil tipado antes de abrir la solución? Requiere observar alumnos.
- ¿Sus dibujos de propiedad de slices permiten predecir el proyecto final? También queda como pregunta para un estudio real.
