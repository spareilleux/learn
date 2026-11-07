---
title: "14. Un servicio integrado de trabajos HTTP"
description: "Seguir una petición completa por validación, admisión con datos propios, trabajo limitado, respuesta y vaciado."
sidebar:
  order: 14
---

## Objetivo de aprendizaje

Seguir una petición completa por validación, admisión con datos propios, trabajo limitado, respuesta y vaciado.

## Mecanismos y modelos de C#/Java

El proyecto final combina [net/http](https://pkg.go.dev/net/http), valores de dominio y un trabajador limitado en un servicio observable. Un POST a /jobs lleva nombre y enteros. El adaptador limita bytes, decodifica exactamente un documento, valida el nombre y envía una copia del trabajo. Un trabajador calcula el total y deposita un resultado en una respuesta con búfer. El handler escribe JSON o comunica cancelación. Las garantías reales son procesamiento en memoria, presupuestos finitos y cierre explícito, sin prometer entrega duradera.

El servicio posee su cola y la vida del trabajador. Submit y Drain comparten un mutex alrededor de la admisión, impidiendo que cerrar la cola compita con un envío. La inserción no bloqueante devuelve ErrFull en vez de crear otra goroutine esperando indefinidamente. Una vez iniciado el vaciado, nuevas solicitudes reciben ErrClosed. El trabajador consume tareas aceptadas y cierra done. Repetir Drain es seguro; un plazo limita la espera sin reabrir admisión. Así existe una transición concreta que puede probarse sin sleep.

Cancelar no deshace una suma completada. El trabajador comprueba el contexto antes de calcular; el cálculo finito puede terminar si la cancelación llega después. El búfer de respuesta impide que un solicitante HTTP que se marcha bloquee la finalización. Copiar en admisión evita que una modificación posterior del consumidor cambie el trabajo aceptado. Estas reglas conectan lecciones anteriores de forma más directa que añadir un framework o una base de datos. Persistir trabajos exigiría identidades, estados duraderos y recuperación fuera de esta unidad.

La orden demuestra una petición correcta, vacía el servicio y observa el rechazo de otra tardía. La integración con [httptest](https://pkg.go.dev/net/http/httptest) añade una petición HTTP real de bucle local con timeout finito. Los recorders cubren entrada inválida, cuerpos excesivos, campos desconocidos, métodos y rutas. Pruebas separadas de propiedad y cancelación localizan fallos. Los servicios alojados de C# y endpoints Java con ejecutores comparten estos ciclos de vida, pero Go hace visible el protocolo de goroutines y canales. Revise cada envío bloqueante, cada propietario del cierre y cada presupuesto. Una suite correcta demuestra contratos ejercitados, no preparación operativa ni aceptación del alumno.

## Ejemplo completo ejecutable

El ejecutable pertenece al módulo independiente `example.com/learn/go-advanced`. Su orden llama a paquetes reutilizables en vez de contener por sí sola todo el comportamiento. Lea primero el paquete y siga después sus llamadas desde la orden. Se muestran archivos versionados completos para mantener visibles importaciones, errores y liberación de recursos. No hace falta estado oculto de notebook ni servicios externos. Las órdenes utilizan el mismo directorio y sintaxis en Windows, Linux/WSL y macOS cuando Go está disponible en PATH.

### Código reutilizable

[jobs/service.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/jobs/service.go)

```go
package jobs

import (
	"context"
	"errors"
	"example.com/learn/go-advanced/domain"
	"sync"
)

var ErrFull = errors.New("queue full")
var ErrClosed = errors.New("service closed")

type Result struct {
	Total int
	Err   error
}
type work struct {
	ctx   context.Context
	job   domain.Job
	reply chan Result
}
type Service struct {
	mu     sync.Mutex
	closed bool
	queue  chan work
	done   chan struct{}
}

func New(capacity int) *Service {
	if capacity < 0 {
		capacity = 0
	}
	s := &Service{queue: make(chan work, capacity), done: make(chan struct{})}
	go func() {
		defer close(s.done)
		for task := range s.queue {
			if err := task.ctx.Err(); err != nil {
				task.reply <- Result{Err: err}
				continue
			}
			task.reply <- Result{Total: task.job.Total()}
		}
	}()
	return s
}

func (s *Service) Submit(ctx context.Context, job domain.Job) (<-chan Result, error) {
	if err := ctx.Err(); err != nil {
		return nil, err
	}
	owned, err := domain.NewJob(job.Name, job.Values)
	if err != nil {
		return nil, err
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.closed {
		return nil, ErrClosed
	}
	reply := make(chan Result, 1)
	select {
	case s.queue <- work{ctx, owned, reply}:
		return reply, nil
	default:
		return nil, ErrFull
	}
}

func (s *Service) Drain(ctx context.Context) error {
	s.mu.Lock()
	if !s.closed {
		s.closed = true
		close(s.queue)
	}
	s.mu.Unlock()
	select {
	case <-s.done:
		return nil
	case <-ctx.Done():
		return ctx.Err()
	}
}
```

[cmd/l14/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l14/main.go)

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
	service := jobs.New(2)
	defer service.Drain(context.Background())
	api := httpapi.API{Service: service}
	first := httptest.NewRecorder()
	api.ServeHTTP(first, httptest.NewRequest("POST", "/jobs", strings.NewReader(`{"name":"sum","values":[4,5]}`)))
	fmt.Println(first.Code)
	fmt.Print(first.Body.String())
	if err := service.Drain(context.Background()); err != nil {
		panic(err)
	}
	late := httptest.NewRecorder()
	api.ServeHTTP(late, httptest.NewRequest("POST", "/jobs", strings.NewReader(`{"name":"late"}`)))
	fmt.Println(late.Code)
}
```

Desde la raíz del repositorio:

```sh
cd code/go-advanced
go run ./cmd/l14
```

### Contrato de salida esperado

```text
200
{"total":9}
503
```

## Leer el contrato antes de cambiar el código

Antes de ejecutar, prediga el resultado e identifique la operación que vuelve observable cada valor. Siga la entrada desde el consumidor, pasando por copias y referencias, hasta su destino. Distinga el valor devuelto por una función de la duración de cualquier trabajo que lance. Cuando haya un error posible, identifique quién decide detenerse, reintentar o traducirlo. Imprimir un valor correcto solo cubre parte del contrato: también deben entenderse las entradas rechazadas y la terminación.

El listado es completo deliberadamente. Compárelo con su archivo de pruebas y nombre la aserción exacta que fallaría si cambiase el comportamiento. Una modificación exclusivamente interna debería conservar esas aserciones observables. Si cambia una frontera pública, describa la garantía modificada antes de editar. Este hábito se traslada bien desde C# y Java mientras mantiene explícitas las reglas de propiedad y sincronización de Go.

## Verificación y alcance

La salida mostrada constituye el contrato esperado del ejecutable, almacenado en `examples.json`. Reprodúzcala antes de considerarla una observación de su máquina. Las pruebas están escritas en el mismo módulo y la verificación central registra su ejecución real por separado. Ejemplos correctos no demuestran todos los sistemas operativos, cargas de producción o resultados de aprendizaje. Diagnósticos, perfiles y benchmarks describen experimentos hasta que el diario registre una medición. Conserve juntos versión, revisión y orden: una observación sin condiciones resulta difícil de reproducir.

## Ejercicios

1. El cliente agota su plazo después de enviar. ¿Es seguro repetir automáticamente?

<details>
<summary>Solución completa</summary>

No. Puede haberse completado y el servicio no tiene identidad duradera de deduplicación. Reconcilie el resultado antes de repetir efectos externos. Cancelar controla espera y cooperación, no ofrece reversión transaccional.

</details>

2. Describa una prueba de aceptación completa del cierre.

<details>
<summary>Solución completa</summary>

Envíe datos válidos propios, reciba el total esperado, vacíe con un contexto limitado, repita el vaciado y compruebe ErrClosed y HTTP 503 para una solicitud posterior. Ordene mediante canales o finalización, nunca sleep.

</details>

## Fuentes primarias

- [net/http](https://pkg.go.dev/net/http)
- [httptest](https://pkg.go.dev/net/http/httptest)
- [context](https://pkg.go.dev/context)

[Lección siguiente](../journal/) · [Diario de aprendizaje](../journal/)
