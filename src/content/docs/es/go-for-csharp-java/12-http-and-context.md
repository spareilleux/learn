---
title: "12. HTTP y context"
description: "Ejercitar un manejador HTTP en memoria y propagar cancelación cooperativa."
sidebar:
  order: 12
---

## Objetivos de aprendizaje

Leer el contrato HTTP, probar estado y JSON sin servicio público e identificar quién posee la cancelación.

## HTTP adapta comportamiento tipado

Un [http.Handler](https://pkg.go.dev/net/http#Handler) atiende una petición escribiendo cabeceras, estado y cuerpo en [`ResponseWriter`](https://pkg.go.dev/net/http#ResponseWriter). El paquete webapi expone los registros mediante una ruta GET con [http.ServeMux](https://pkg.go.dev/net/http#ServeMux). El manejador codifica datos tipados, sin construir JSON concatenando texto. Establece Content-Type antes del cuerpo, porque la primera escritura puede confirmar las cabeceras.

Es una frontera pequeña para aprender la forma del protocolo. El CLI no necesita llamar por HTTP a sus funciones de dominio: ambas fronteras utilizan study directamente. Así evita red innecesaria dentro de un informe local. Un manejador reutiliza el núcleo sin convertirse en propietario de toda la lógica. El curso avanzado desarrolla por separado el ciclo de vida del servicio y los aspectos operativos de producción.

## Probar sin un servicio externo

El ejemplo crea un [httptest.ResponseRecorder](https://pkg.go.dev/net/http/httptest#ResponseRecorder) y una petición, y llama a ServeHTTP directamente. No abre sockets ni contacta con servicios públicos. Estado, cabeceras y cuerpo quedan observables para las pruebas. Decodifica el cuerpo a Record y comprueba los datos del dominio en vez de comparar espacios accidentales del JSON.

Los datos deben producir estado doscientos y dos registros. Las pruebas comprueban también tipo de contenido y método no permitido. Un recorder no demuestra configuración TLS, comportamiento de proxies, delimitación de mensajes ni tiempos de un cliente real. Eso exige otras pruebas. Limitar la conclusión al manejador mantiene precisa la evidencia mientras ejercita enrutamiento, serialización y composición reales.

## Context transmite una vida entre llamadas

Un [context.Context](https://pkg.go.dev/context#Context) comunica cancelación y plazos a través de llamadas. Usa el contexto de la petición cuando el trabajo le pertenece. [context.WithCancel](https://pkg.go.dev/context#WithCancel) devuelve un contexto hijo y una función de cancelación; quien lo crea debe llamar a cancel para liberar recursos asociados. Pasar un contexto no fuerza la detención: la operación debe consultar su error o seleccionar el canal Done.

Después de la llamada correcta, el comando cancela su contexto y llama a Count. Count comprueba cancelación antes de empezar y devuelve [`context.Canceled`](https://pkg.go.dev/context#Canceled), que [`errors.Is`](https://pkg.go.dev/errors#Is) reconoce. El orden es determinista: la cancelación ya ocurrió y no depende de carreras temporales ni pausas. El manejador también comprueba el contexto antes de codificar; su prueba verifica que no escribe cuerpo para una petición ya cancelada.

## Comparar vidas de peticiones

[C# CancellationToken](https://learn.microsoft.com/dotnet/api/system.threading.cancellationtoken) ayuda a entender cancelación cooperativa, pero context también transporta plazos y valores de petición. No escondas configuración habitual ni parámetros opcionales en el contexto para evitar argumentos explícitos. Un contexto cancelado no debe reutilizarse para una operación nueva e independiente. Deriva otra vida del padre adecuado.

La codificación puede fallar después de confirmar cabeceras. Nuestro manejador retorna en ese caso; no implementa una política completa de diagnóstico o búfer de producción. Una comprobación inicial tampoco garantiza que no coincida una escritura con cancelación posterior. Comprende el punto exacto de observación. La práctica principal es propagar la vida bajo propiedad y mantener el dominio comprobable sin iniciar un servicio.

## Ejemplo explicado

Código completo: [`cmd/l12/main.go`](https://github.com/spareilleux/learn/blob/main/code/go-for-csharp-java/cmd/l12/main.go).

```go
package main

import (
	"context"
	"encoding/json"
	"errors"
	"example.com/learn/go-for-csharp-java/internal/study"
	"example.com/learn/go-for-csharp-java/internal/webapi"
	"fmt"
	"net/http"
	"net/http/httptest"
)

func main() {
	ctx, cancel := context.WithCancel(context.Background())
	request := httptest.NewRequestWithContext(ctx, http.MethodGet, "/records", nil)
	response := httptest.NewRecorder()
	webapi.Handler().ServeHTTP(response, request)
	var records []study.Record
	if err := json.Unmarshal(response.Body.Bytes(), &records); err != nil {
		panic(err)
	}
	cancel()
	_, err := study.Count(ctx, records)
	fmt.Printf("status=%d records=%d cancelled=%t\n", response.Code, len(records), errors.Is(err, context.Canceled))
}
```

Desde la raíz del repositorio:

```sh
cd code/go-for-csharp-java
go run ./cmd/l12
```

**Salida verificada — Go 1.27.1, Windows/amd64.**

```text
status=200 records=2 cancelled=true
```

## Leer, predecir y comprobar

Antes de ejecutar el programa, sigue cada valor desde su declaración hasta el resultado mostrado. Anota qué operación valida los datos y cuál solo transforma datos ya tipados. Ejecuta después el comando del repositorio y compara toda la salida, incluido el salto de línea final, con examples.json. Un ejemplo coincidente demuestra este conjunto de datos; las pruebas escritas cubren contratos adicionales. Cambia una sola entrada cada vez, explica la consecuencia y separa el experimento de los datos publicados. Así podrás diagnosticar un resultado inesperado sin cambiar silenciosamente lo que promete la lección.

## Ejercicios

1. ¿Por qué no necesita un servidor público ni un puerto?

<details>
<summary>Solución 1</summary>

ServeHTTP es una llamada ordinaria de interfaz. httptest proporciona petición y ResponseWriter que registra estado, cabeceras y cuerpo en memoria. El ejemplo ejercita directamente enrutamiento y codificación. Demuestra el contrato del manejador, sin afirmar nada sobre sockets, TLS o configuración de despliegue.

</details>

2. ¿Por qué cancelar antes de llamar a Count?

<details>
<summary>Solución 2</summary>

Establece orden determinista: Count recibe un contexto ya cancelado y devuelve context.Canceled al entrar, antes de trabajar. Una pausa no demostraría ese orden con fiabilidad. En una petición real, cancelar puede ocurrir durante el trabajo; cada operación debe observarlo y documentar su contrato de terminación.

</details>

## Fuentes oficiales

- [http.Handler](https://pkg.go.dev/net/http#Handler)
- [http.ServeMux](https://pkg.go.dev/net/http#ServeMux)
- [httptest.ResponseRecorder](https://pkg.go.dev/net/http/httptest#ResponseRecorder)
- [context.WithCancel](https://pkg.go.dev/context#WithCancel)

[Siguiente lección](../13-testing/) · [Diario](../journal/)
