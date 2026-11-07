---
title: "7. Cancelación, plazos y cierre"
description: "Separar la solicitud de cancelación, la observación de finalización y el vaciado del trabajo aceptado."
sidebar:
  order: 7
---

## Objetivo de aprendizaje

Separar la solicitud de cancelación, la observación de finalización y el vaciado del trabajo aceptado.

## Mecanismos y modelos de C#/Java

Un [context](https://pkg.go.dev/context) transporta cancelación, plazo y valores de una petición. Páselo explícitamente como primer parámetro cuando el trabajo pueda bloquearse. Su función de cancelación solicita una parada cooperativa; no espera a las goroutines. Por eso el ejemplo usa dos señales: started demuestra que el trabajador llegó a la espera y done devuelve su error terminal. Ningún sleep adivina si ha comenzado. WithCancelCause conserva la razón sin cambiar la identidad ordinaria de cancelación que devuelve Err.

Libere siempre los recursos de un contexto derivado llamando a su función de cancelación, incluso si termina antes. La propagación de plazos impide que un hijo prolongue la vida de su padre. Un timeout alrededor de una función no interrumpe un bucle arbitrario ni una biblioteca que ignore el contexto. Sitúe puntos de observación donde tengan sentido y documente las operaciones que terminan una vez admitidas. Nuestra suma pequeña puede completarse cuando cancelación y envío coinciden; cancelar HTTP no implica deshacer el trabajo.

El servicio separa admisión y vaciado. Submit mantiene un mutex mientras comprueba closed y realiza un envío no bloqueante a la cola. Drain mantiene el mismo mutex al detener la admisión y cerrar la cola. Esto evita una carrera entre enviar y cerrar. El canal done se cierra cuando el trabajador ha consumido las tareas aceptadas. Cada respuesta dispone de un hueco de búfer, de modo que el trabajador puede terminar aunque el solicitante deje de esperar. Ese canal contiene exactamente un resultado, no un flujo que deba recorrerse indefinidamente.

Los tokens de C# también requieren cooperación; cancelar una future Java tampoco garantiza interrumpir cualquier operación. Diseñe el cierre alrededor de estados observables. En HTTP, detenga admisión, deje terminar handlers con un contexto finito, vacíe trabajos aceptados y respete un plazo global. [http.Server.Shutdown](https://pkg.go.dev/net/http#Server.Shutdown) gestiona conexiones HTTP, pero desconoce un trabajador independiente. Si vence el plazo de vaciado, termina la espera; no reabre admisión ni deshace silenciosamente trabajos aceptados.

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

[cmd/l07/main.go](https://github.com/spareilleux/learn/blob/main/code/go-advanced/cmd/l07/main.go)

```go
package main

import (
	"context"
	"errors"
	"example.com/learn/go-advanced/pipeline"
	"fmt"
)

func main() {
	ctx, cancel := context.WithCancelCause(context.Background())
	defer cancel(nil)
	started := make(chan struct{})
	done := make(chan error, 1)
	go func() { done <- pipeline.Wait(ctx, started) }()
	<-started
	cancel(errors.New("requested"))
	fmt.Println(<-done)
}
```

Desde la raíz del repositorio:

```sh
cd code/go-advanced
go run ./cmd/l07
```

### Contrato de salida esperado

```text
requested
```

## Leer el contrato antes de cambiar el código

Antes de ejecutar, prediga el resultado e identifique la operación que vuelve observable cada valor. Siga la entrada desde el consumidor, pasando por copias y referencias, hasta su destino. Distinga el valor devuelto por una función de la duración de cualquier trabajo que lance. Cuando haya un error posible, identifique quién decide detenerse, reintentar o traducirlo. Imprimir un valor correcto solo cubre parte del contrato: también deben entenderse las entradas rechazadas y la terminación.

El listado es completo deliberadamente. Compárelo con su archivo de pruebas y nombre la aserción exacta que fallaría si cambiase el comportamiento. Una modificación exclusivamente interna debería conservar esas aserciones observables. Si cambia una frontera pública, describa la garantía modificada antes de editar. Este hábito se traslada bien desde C# y Java mientras mantiene explícitas las reglas de propiedad y sincronización de Go.

## Verificación y alcance

La salida mostrada constituye el contrato esperado del ejecutable, almacenado en `examples.json`. Reprodúzcala antes de considerarla una observación de su máquina. Las pruebas están escritas en el mismo módulo y la verificación central registra su ejecución real por separado. Ejemplos correctos no demuestran todos los sistemas operativos, cargas de producción o resultados de aprendizaje. Diagnósticos, perfiles y benchmarks describen experimentos hasta que el diario registre una medición. Conserve juntos versión, revisión y orden: una observación sin condiciones resulta difícil de reproducir.

## Ejercicios

1. ¿Por qué una respuesta con búfer evita aquí una fuga durante el cierre?

<details>
<summary>Solución completa</summary>

Cada tarea aceptada produce exactamente un resultado. Un hueco permite terminar el envío aunque el solicitante cancele. Sin búfer haría falta seleccionar cancelación o garantizar un receptor.

</details>

2. Si Drain devuelve un error de plazo, ¿puede Submit volver a aceptar?

<details>
<summary>Solución completa</summary>

No. La admisión se cierra una vez y permanece cerrada. El plazo limita la espera, no revierte la transición del servicio. Vuelva a observar con Drain sin reenviar trabajo cuyo resultado desconoce.

</details>

## Fuentes primarias

- [context](https://pkg.go.dev/context)
- [http.Server.Shutdown](https://pkg.go.dev/net/http#Server.Shutdown)

[Lección siguiente](../08-production-http/) · [Diario de aprendizaje](../journal/)
