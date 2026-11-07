---
title: "8. Fronteras HTTP en producción"
description: "Definir presupuestos de recursos HTTP y probar peticiones malformadas sin servicios externos."
sidebar:
  order: 8
---

## Objetivo de aprendizaje

Definir presupuestos de recursos HTTP y probar peticiones malformadas sin servicios externos.

## Mecanismos y modelos de C#/Java

El paquete [net/http](https://pkg.go.dev/net/http) permite crear rápidamente un servidor, pero sus valores predeterminados no constituyen una política de recursos de producción. Nuestro constructor Server fija tiempos finitos para cabeceras, lectura, escritura e inactividad, además de un máximo de bytes de cabeceras. El handler limita aparte el cuerpo con MaxBytesReader y concede un segundo al trabajo admitido. Son presupuestos diferentes. Un plazo del handler no establece por sí solo un plazo de lectura del socket, y el tiempo de cabeceras no limita el cuerpo.

La frontera acepta POST en /jobs, decodifica un valor JSON, rechaza campos desconocidos y exige que una segunda decodificación encuentre el final de entrada. Sin esa comprobación se podría aceptar un objeto válido seguido de otro documento. Un cuerpo excesivo produce 413; una entrada inválida 400; un método incorrecto 405 con Allow; un servicio cerrado o lleno 503. El ejemplo suma enteros pequeños; no diseña una cola duradera ni autenticación. Identidad y persistencia exigirían contratos separados.

[httptest](https://pkg.go.dev/net/http/httptest) ofrece recorders dentro del proceso y un servidor real de bucle local. Los primeros aíslan la traducción de peticiones; la integración añade cliente y transporte reales con timeout finito. Cierre los cuerpos de respuesta para reutilizar recursos y conexiones. La orden usa un recorder para conservar una salida determinista sin escuchar en un puerto público. Una aplicación real debe construir explícitamente el servidor y coordinar su cierre con el trabajador.

Los middlewares de C# y filtros de servlets Java son adaptadores conocidos, pero los handlers Go son valores ordinarios que implementan una interfaz. Evite convertir el registro global en un contenedor implícito de dependencias. Pase el servicio explícitamente a API. Una vez enviadas las cabeceras, un error posterior no puede sustituir el estado enviado. La observabilidad de producción debería registrar fallos de escritura e identidad de petición según una política de privacidad definida; este adaptador pequeño retorna si falla el codificador. Los plazos son presupuestos necesarios, no pruebas de que toda desconexión interrumpa inmediatamente el cálculo.

## Ejemplo completo ejecutable

El ejecutable pertenece al módulo independiente `example.com/learn/go-advanced`. Su orden llama a paquetes reutilizables en vez de contener por sí sola todo el comportamiento. Lea primero el paquete y siga después sus llamadas desde la orden. Se muestran archivos versionados completos para mantener visibles importaciones, errores y liberación de recursos. No hace falta estado oculto de notebook ni servicios externos. Las órdenes utilizan el mismo directorio y sintaxis en Windows, Linux/WSL y macOS cuando Go está disponible en PATH.

### Código reutilizable

[httpapi/api.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/httpapi/api.go)

```go
package httpapi

import (
	"context"
	"encoding/json"
	"errors"
	"example.com/learn/go-advanced/domain"
	"example.com/learn/go-advanced/jobs"
	"io"
	"net/http"
	"time"
)

const MaxBody = 256

type API struct{ Service *jobs.Service }

func (a API) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/jobs" {
		http.NotFound(w, r)
		return
	}
	if r.Method != http.MethodPost {
		w.Header().Set("Allow", http.MethodPost)
		http.Error(w, "method", http.StatusMethodNotAllowed)
		return
	}
	ctx, cancel := context.WithTimeout(r.Context(), time.Second)
	defer cancel()
	r.Body = http.MaxBytesReader(w, r.Body, MaxBody)
	defer r.Body.Close()
	decoder := json.NewDecoder(r.Body)
	decoder.DisallowUnknownFields()
	var input struct {
		Name   string `json:"name"`
		Values []int  `json:"values"`
	}
	if err := decoder.Decode(&input); err != nil {
		var large *http.MaxBytesError
		if errors.As(err, &large) {
			http.Error(w, "body", http.StatusRequestEntityTooLarge)
		} else {
			http.Error(w, "json", http.StatusBadRequest)
		}
		return
	}
	if err := decoder.Decode(new(any)); err != io.EOF {
		var large *http.MaxBytesError
		if errors.As(err, &large) {
			http.Error(w, "body", http.StatusRequestEntityTooLarge)
		} else {
			http.Error(w, "trailing", http.StatusBadRequest)
		}
		return
	}
	job, err := domain.NewJob(input.Name, input.Values)
	if err != nil {
		http.Error(w, "job", http.StatusBadRequest)
		return
	}
	reply, err := a.Service.Submit(ctx, job)
	if err != nil {
		status := http.StatusServiceUnavailable
		if errors.Is(err, context.Canceled) || errors.Is(err, context.DeadlineExceeded) {
			status = http.StatusRequestTimeout
		}
		http.Error(w, "unavailable", status)
		return
	}
	select {
	case result := <-reply:
		if result.Err != nil {
			http.Error(w, "cancelled", http.StatusRequestTimeout)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		if err := json.NewEncoder(w).Encode(struct {
			Total int `json:"total"`
		}{result.Total}); err != nil {
			return
		}
	case <-ctx.Done():
		http.Error(w, "deadline", http.StatusGatewayTimeout)
	}
}

func Server(address string, handler http.Handler) *http.Server {
	return &http.Server{Addr: address, Handler: handler, ReadHeaderTimeout: 2 * time.Second, ReadTimeout: 3 * time.Second, WriteTimeout: 3 * time.Second, IdleTimeout: 30 * time.Second, MaxHeaderBytes: 8192}
}
```

[cmd/l08/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l08/main.go)

```go
package main

import (
	"context"
	"example.com/learn/go-advanced/httpapi"
	"example.com/learn/go-advanced/jobs"
	"fmt"
	"net/http/httptest"
	"strings"
)

func main() {
	service := jobs.New(1)
	defer service.Drain(context.Background())
	request := httptest.NewRequest("POST", "/jobs", strings.NewReader(`{"name":"sum","values":[2,3]}`))
	response := httptest.NewRecorder()
	httpapi.API{Service: service}.ServeHTTP(response, request)
	fmt.Println(response.Code)
	fmt.Print(response.Body.String())
}
```

Desde la raíz del repositorio:

```sh
cd code/go-advanced
go run ./cmd/l08
```

### Contrato de salida esperado

```text
200
{"total":5}
```

## Leer el contrato antes de cambiar el código

Antes de ejecutar, prediga el resultado e identifique la operación que vuelve observable cada valor. Siga la entrada desde el consumidor, pasando por copias y referencias, hasta su destino. Distinga el valor devuelto por una función de la duración de cualquier trabajo que lance. Cuando haya un error posible, identifique quién decide detenerse, reintentar o traducirlo. Imprimir un valor correcto solo cubre parte del contrato: también deben entenderse las entradas rechazadas y la terminación.

El listado es completo deliberadamente. Compárelo con su archivo de pruebas y nombre la aserción exacta que fallaría si cambiase el comportamiento. Una modificación exclusivamente interna debería conservar esas aserciones observables. Si cambia una frontera pública, describa la garantía modificada antes de editar. Este hábito se traslada bien desde C# y Java mientras mantiene explícitas las reglas de propiedad y sincronización de Go.

## Verificación y alcance

La salida mostrada constituye el contrato esperado del ejecutable, almacenado en `examples.json`. Reprodúzcala antes de considerarla una observación de su máquina. Las pruebas están escritas en el mismo módulo y la verificación central registra su ejecución real por separado. Ejemplos correctos no demuestran todos los sistemas operativos, cargas de producción o resultados de aprendizaje. Diagnósticos, perfiles y benchmarks describen experimentos hasta que el diario registre una medición. Conserve juntos versión, revisión y orden: una observación sin condiciones resulta difícil de reproducir.

## Ejercicios

1. ¿Por qué decodificar otra vez después de un objeto correcto?

<details>
<summary>Solución completa</summary>

La frontera promete exactamente un documento JSON. La segunda decodificación debe devolver io.EOF; otro objeto o bytes inválidos incumplen el contrato. Los casos locales prueban objetos concatenados.

</details>

2. ¿Un contexto de un segundo sustituye MaxBytesReader y los tiempos del servidor?

<details>
<summary>Solución completa</summary>

No. Cada mecanismo limita recursos distintos: duración del trabajo, bytes leídos y operaciones de conexión. Mantenga presupuestos explícitos y pruebe por separado cuerpos excesivos y cancelaciones.

</details>

## Fuentes primarias

- [net/http](https://pkg.go.dev/net/http)
- [httptest](https://pkg.go.dev/net/http/httptest)

[Lección siguiente](../09-streaming-and-framing/) · [Diario de aprendizaje](../journal/)
