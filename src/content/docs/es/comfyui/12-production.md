---
title: '12. ComfyUI en producción: un servicio, una cola, varias GPU'
description: 'Convertir ComfyUI en un servicio de renderizado — lo que da su servidor (un prompt a la vez, /prompt, /queue, /history, /interrupt, identificadores de prompt que nunca se deduplican) y lo que no da, y luego un worker en C# y en Java que toma jobs de una cola, los ejecuta en un pool de GPU elegidas por la longitud de su cola, reintenta con backoff, manda a las cartas muertas lo que nunca funcionará, interrumpe al vencer el plazo, se recupera de un WebSocket perdido y ejecuta cada job una sola vez; probado contra un ComfyUI falso construido con respuestas grabadas, en tres sistemas operativos y contra un ComfyUI real en CPU, con notas de despliegue y el experimento del laboratorio GA como un lote de jobs.'
sidebar:
  order: 12
---

Código: el worker en C# en [`worker/csharp/ComfyWorker/`](https://github.com/spareilleux/learn/tree/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/csharp/ComfyWorker) y en Java en [`worker/java/`](https://github.com/spareilleux/learn/tree/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/java/src/main/java/dev/learn/comfy/worker), el servidor falso en [`worker/csharp/FakeComfy/`](https://github.com/spareilleux/learn/tree/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/csharp/FakeComfy) con las respuestas que reproduce en [`worker/data/recorded/`](https://github.com/spareilleux/learn/tree/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/data/recorded), las pruebas, los archivos de jobs y las transcripciones esperadas, todo ejecutado por [`worker/check.sh`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/check.sh) y el workflow [`comfyui-worker-examples.yml`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/.github/workflows/comfyui-worker-examples.yml).

La lección 4 enviaba un prompt y lo esperaba. Un servicio recibe prompts de muchos clientes, en cualquier momento, y tiene que cumplir sus promesas cuando un servidor responde 500, se corta un WebSocket, una GPU se queda sin memoria, un prompt no termina nunca o un worker se detiene en medio de un job. El servidor de ComfyUI no se encarga de nada de eso por ti: ejecuta un prompt a la vez y no comprueba nada en tu lugar. Esta lección lee lo que el servidor sí ofrece, construye un worker a su alrededor en C# y en Java, y prueba cada fallo sin GPU.

## La arquitectura

```mermaid
flowchart LR
  C1[Cliente] --> API[API del servicio]
  C2[Cliente] --> API
  API -->|job: id + workflow| Q[(Cola de jobs)]
  Q --> W1[Worker 1]
  Q --> W2[Worker 2]
  W1 --> G0[ComfyUI en la GPU 0]
  W1 --> G1[ComfyUI en la GPU 1]
  W2 --> G2[ComfyUI en la GPU 2]
  W1 --> S[(Almacén de resultados)]
  W2 --> S
  Q -.->|fallo definitivo| D[(Cartas muertas)]
  API -.->|lee estados y archivos| S
```

- Los **clientes** nunca hablan con ComfyUI. Envían un job a la **API del servicio** y leen su resultado más tarde. ComfyUI no tiene autenticación, y su cola es común a todo el servidor.
- La **cola de jobs** guarda los jobs hasta que un worker toma uno, y devuelve un job si el worker muere antes de confirmarlo. En esta lección es una cola en memoria para las pruebas y una sola máquina, y después [RabbitMQ](../../rabbitmq/).
- Un **worker** toma tantos jobs como GPU tiene, envía cada uno a **un proceso de ComfyUI por GPU**, lo sigue y descarga las salidas.
- El **almacén de resultados** guarda los archivos y un registro de cada job terminado. También es lo que hace que un job se ejecute una sola vez.
- Las **cartas muertas** son los jobs que fallaron para siempre, con su motivo, para que una persona o un programa los revise.

## Lo que ComfyUI ofrece por sí mismo

Todo lo que sigue se lee en ComfyUI v0.36.0, commit [`ee71d5c`](https://github.com/Comfy-Org/ComfyUI/tree/ee71d5c4993f29086b27fde1629a945ae48425bf).

### Un prompt a la vez

`main.py` arranca un único hilo [`prompt_worker`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/main.py#L319-L397) ([línea 529](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/main.py#L529)). Toma el siguiente elemento de la [`PromptQueue`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py#L1286-L1341), un montículo ordenado por el número del prompt, lo ejecuta con [`e.execute`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/main.py#L362), escribe el historial con [`task_done`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/main.py#L367-L372) y envía `executing` con `node: null` ([líneas 373 y 374](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/main.py#L373-L374)). Un servidor, un prompt en ejecución: para usar dos GPU en paralelo, se arrancan dos servidores. Un segundo prompt enviado a un servidor ocupado espera en su cola, y un cliente no puede saber cuánto tiempo a partir de la respuesta de `POST /prompt`.

### Las rutas que usa un worker

| Ruta | Lo que hace el worker con ella | `server.py` |
|---|---|---|
| `GET /ws?clientId=…` | recibe los eventos de los prompts que encoló con ese identificador de cliente | [269-327](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py#L269-L327) |
| `POST /prompt` | encola un prompt con su propio `prompt_id`; 200 con `number`, o 400 con `error` y `node_errors` | [1075-1147](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py#L1075-L1147) |
| `GET /queue` | si este prompt está en ejecución o pendiente, y cuántos prompts tiene delante | [1067-1073](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py#L1067-L1073) |
| `POST /queue` con `delete` | quita un prompt pendiente | [1149-1161](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py#L1149-L1161) |
| `GET /history/{prompt_id}` | las salidas y el estado de un prompt terminado | [1048-1065](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py#L1048-L1065) |
| `POST /interrupt` con `prompt_id` | detiene ese prompt si es el que está en ejecución | [1163-1193](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py#L1163-L1193) |
| `POST /free` | descarga modelos y libera memoria en el próximo momento libre | [1195-1204](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py#L1195-L1204) |
| `GET /system_stats` | si el servidor responde, qué dispositivo, cuánta VRAM libre | [689-740](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py#L689-L740) |

`client_id` es solo una clave de enrutamiento. El manejador de WebSocket guarda un socket por `clientId`, y una conexión nueva con el mismo identificador reemplaza la anterior. Los eventos de un prompt van al identificador de cliente con el que se encoló, salvo `status`, que [`queue_updated`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py#L1399-L1400) difunde a todos cada vez que cambia la cola. Cuando el worker grabó el encolado de un prompt, recibió dos mensajes `status`.

### Lo que el servidor no hace por ti

Estos hechos dan forma al worker. Se leen en el código fuente, y el [script de grabación](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/record/record.py) del curso también provocó los casos del identificador de prompt, los errores y la interrupción en un servidor CPU, y guardó las respuestas y los mensajes en `data/recorded/`.

- **Un cliente puede elegir el identificador del prompt**, y debe ser un UUID en minúsculas con guiones: [`validate_job_id`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy_execution/jobs.py#L34-L50) rechaza cualquier otra escritura con un 400 `invalid_prompt_id`.
- **El mismo identificador de prompt no se deduplica.** Enviado dos veces, se encola dos veces, se ejecuta dos veces, y la segunda ejecución sobrescribe la entrada de historial de la primera. La idempotencia es cosa de quien llama.
- **`execution_success` llega antes que el historial.** Se envía al final de la ejecución, [línea 824](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py#L824), y `task_done` escribe el historial después. Un cliente que llama a `/history` justo después del mensaje puede no encontrar nada todavía.
- **`execution_interrupted` se difunde** a todos los clientes ([`handle_execution_error`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py#L686-L712)), mientras que `execution_error` solo va al cliente del prompt.
- **Una reconexión no reproduce** lo que el cliente se perdió: el socket nuevo recibe un `status`, y `executing` con el nodo actual si es el cliente en ejecución. Un prompt que terminó mientras no estabas solo está en `/history`.
- **La entrada de historial lleva el número del prompt** en `prompt[0]`. Cuando el mismo identificador de prompt se ha ejecutado dos veces, es la única forma de saber a qué ejecución pertenece una entrada.
- **Quedarse sin memoria es un `execution_error` normal.** ComfyUI añade consejos al mensaje y luego descarga todos los modelos ([líneas 640 a 644](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py#L640-L644)), así que un segundo intento puede funcionar.
- **Los errores de validación son un 400** con `node_errors` por nodo ([`validate_prompt`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py#L1227-L1238)); un cuerpo que no es JSON hace que aiohttp responda un 500 en texto plano, `500 Internal Server Error` y luego `Server got itself in trouble`.
- **`/interrupt` con un `prompt_id`** solo interrumpe si ese prompt está en ejecución, y responde 200 con un cuerpo vacío en ambos casos; un prompt pendiente sigue en la cola hasta que `POST /queue` lo borra.
- **El historial está acotado**: [`MAXIMUM_HISTORY_SIZE`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py#L1284) es de 10 000 entradas, y un reinicio lo vacía.

ComfyUI v0.36.0 también tiene rutas `/api/jobs` para listar y cancelar jobs. El worker no las usa, para funcionar igual con las rutas de la lección 4.

### Direcciones, puertos y dispositivos

En [`comfy/cli_args.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/cli_args.py):

- `--listen` ([línea 63](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/cli_args.py#L63)) vale `127.0.0.1` por defecto; sin valor, escucha en `0.0.0.0,::`. `--port` ([línea 64](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/cli_args.py#L64)) vale 8188 por defecto.
- `--cuda-device` ([línea 77](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/cli_args.py#L77)) fija `CUDA_VISIBLE_DEVICES` antes de que se cargue PyTorch ([`main.py`, líneas 97 a 102](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/main.py#L97-L102)): `--cuda-device 1 --port 8189` es el servidor de la segunda GPU. En Windows, sin `--cuda-device`, ComfyUI fuerza la GPU 0 ([líneas 46 a 53](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/main.py#L46-L53)).
- `--base-directory` ([línea 70](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/cli_args.py#L70)) y `--extra-model-paths-config` ([línea 71](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/cli_args.py#L71)) separan las entradas y salidas de cada servidor de una carpeta de modelos compartida.
- No hay autenticación. El servidor tiene `--tls-keyfile` y `--tls-certfile` ([líneas 65 y 66](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/cli_args.py#L65-L66)), y [`origin_only_middleware`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py#L159-L197), que rechaza las peticiones cross-site de un navegador; impide que una página web encole prompts en tu máquina, no que lo haga un programa en la red. `--multi-user` ([línea 218](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/cli_args.py#L218)) separa los ajustes de los usuarios, no los permisos. Mantén ComfyUI en loopback o en una red privada, y deja la autenticación a la API del servicio; la lección 11 da las demás razones.

## El worker

El worker de C# y el de Java tienen las mismas clases, la misma línea de comandos y las mismas líneas de log, así que las transcripciones de abajo se comparan con los mismos archivos esperados. El código C# apunta a .NET 10, el código Java a Java 25 con Jackson 3, como en la lección 4.

| Parte | C# | Java |
|---|---|---|
| un job, la interfaz de cola, la cola en memoria | `Jobs.cs` | `Jobs.java` |
| un servidor ComfyUI: salud, cola, historial, envío, cancelación, WebSocket | `ComfyInstance.cs` | `ComfyInstance.java` |
| el pool de servidores y el planificador | `GpuPool.cs` | `GpuPool.java` |
| archivos y registros de jobs, reservas | `ResultStore.cs` | `ResultStore.java` |
| un intento de un job | `JobRunner.cs` | `JobRunner.java` |
| bucles de consumo, reintentos, cartas muertas, parada | `Worker.cs` | `Worker.java` |
| RabbitMQ | `RabbitMqJobQueue.cs` | `RabbitMqJobQueue.java` |
| línea de comandos | `Program.cs` | `Main.java` |

### Un job y su cola

Un job es un identificador y un workflow en formato API. El identificador lo elige quien encola el job, y es un UUID, porque el worker lo usa como `prompt_id` de ComfyUI: un reintento en el mismo servidor puede entonces encontrar el prompt en `/queue` o en `/history`.

```csharp
public sealed record Job(string Id, JsonObject Workflow)
{
    public static Job Create(string id, JsonObject workflow)
    {
        // ComfyUI 0.36.0 refuses any other spelling of a UUID (comfy_execution/jobs.py, validate_job_id).
        if (!Guid.TryParse(id, out var guid) || guid.ToString() != id)
            throw new ArgumentException($"job id {id} is not a lowercase hyphenated UUID");
        return new Job(id, workflow);
    }

    public string Short => Id[..8];
}
```

El worker ve la cola a través de dos interfaces. Una entrega se confirma cuando el job termina, se devuelve a la cola al parar, o se manda a las cartas muertas con un motivo:

```csharp
public interface IDelivery
{
    Job Job { get; }
    ValueTask AckAsync();
    /// <summary>Gives the job back, for another worker: used at shutdown.</summary>
    ValueTask RequeueAsync();
    ValueTask DeadLetterAsync(string reason);
}

public interface IJobQueue
{
    /// <summary>The next job, or null once the queue is completed and empty.</summary>
    ValueTask<IDelivery?> ReceiveAsync(CancellationToken cancel);
}
```

La cola en memoria es en C# un [`Channel<T>`](https://learn.microsoft.com/dotnet/core/extensions/channels) sin límite con varios lectores, uno por GPU, como en la [lección sobre channels](../../csharp-advanced/06-channels/#varios-productores-varios-consumidores). En Java es una [`LinkedBlockingQueue`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/LinkedBlockingQueue.html) consultada por un [hilo virtual](https://docs.oracle.com/en/java/javase/25/core/virtual-threads.html) por GPU. Las esperas bloqueantes en hilos virtuales cuestan poco, por eso el worker de Java no necesita Reactor aquí; la [lección sobre Reactor](../../spring-cloud-reactor/03-reactor-under-the-hood/#hilos-virtuales-o-reactivo) compara los dos enfoques.

Cada bucle de consumo solo toma un job cuando puede ejecutarlo: un worker con dos GPU tiene dos bucles, y nunca retiene un tercer job que otro worker podría ejecutar.

### Un intento, paso a paso

[`JobRunner`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/csharp/ComfyWorker/JobRunner.cs) ejecuta un intento de un job en un servidor, y nunca lanza una excepción por lo que haga un servidor. Devuelve un resultado: éxito, fallo transitorio o fallo definitivo.

1. **Ponerse al día.** Si `/history/{id}` ya tiene una entrada con éxito, un intento anterior u otro worker terminó el prompt: se descargan sus salidas. Si `/queue` tiene el identificador, se sigue en lugar de enviarlo otra vez.
2. **Conectar y luego enviar.** El WebSocket se abre con un identificador de cliente nuevo antes de `POST /prompt`, para que ningún evento salga antes de que alguien escuche. El `number` de la respuesta identifica esta ejecución.
3. **Seguir** hasta `execution_success`, `execution_error` o `execution_interrupted` para este identificador de prompt, y solo después del `execution_start` de esta ejecución: un `execution_interrupted` de una ejecución anterior con el mismo identificador, difundido a todos, no debe terminar esta. Cada cinco segundos, y después de cada reconexión, también lee `/history`, y solo acepta la entrada cuyo `prompt[0]` es el número de esta ejecución.
4. **Descargar** cada salida con `/view`, escribirla con un nombre temporal y luego renombrarla.

El resultado decide lo que viene después:

```csharp
var (status, body) = await gpu.SubmitAsync(job, clientId, deadline.Token);
if (status == HttpStatusCode.BadRequest)
    return Outcome.Permanent($"POST /prompt 400, {DescribeErrors(body)}");
if ((int)status >= 500)
    return Outcome.Transient($"POST /prompt {(int)status}, {body.Split('\n')[0]}");
```

```csharp
case "execution_error":
    string type = data?["exception_type"]?.GetValue<string>() ?? "";
    string message = (data?["exception_message"]?.GetValue<string>() ?? "").Split('\n')[0];
    string where = $"node {data?["node_id"]} ({data?["node_type"]}): {type}: {message}";
    // An out-of-memory error depends on what else the GPU held (execution.py unloads all models
    // after one): worth another try. Anything else will fail the same way again.
    return IsOutOfMemory(type, data)
        ? Outcome.Transient($"execution_error, {where}")
        : Outcome.Permanent($"execution_error, {where}");
default:
    return Outcome.Transient($"execution_interrupted at node {data?["node_id"]}, by someone else");
```

| Lo que pasó | Resultado | Por qué |
|---|---|---|
| `POST /prompt` 400 | definitivo | el workflow no es válido: el mismo cuerpo se rechazará otra vez |
| `POST /prompt` 5xx, conexión rechazada, reiniciada o vencida | transitorio | quizá el servidor se está reiniciando |
| `execution_error` con un tipo o un mensaje de falta de memoria | transitorio | la memoria depende de qué más tenía cargado la GPU |
| cualquier otro `execution_error` | definitivo | un error en el workflow o en un nodo |
| `execution_interrupted` sin plazo vencido | transitorio | otra persona pulsó Cancel en la interfaz |
| sin final antes del plazo del job | transitorio | primero se interrumpe el prompt |

### Reintentos con backoff

Un fallo transitorio se reintenta tras una espera que se duplica cada vez, con un tope de un minuto. Con el jitter activado, que es el valor por defecto, la espera es un valor aleatorio entre cero y ese tope, el «full jitter» del [artículo de Marc Brooker](https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/), para que cien jobs que fallan a la vez no reintenten a la vez.

```csharp
public TimeSpan Backoff(int attempt)
{
    double capped = Math.Min(options.MaxDelay.TotalMilliseconds, options.BaseDelay.TotalMilliseconds * Math.Pow(2, attempt - 1));
    return TimeSpan.FromMilliseconds(options.Jitter ? Random.Shared.NextDouble() * capped : capped);
}
```

```java
public Duration backoff(int attempt) {
    double capped = Math.min(options.maxDelay().toMillis(), options.baseDelay().toMillis() * Math.pow(2, attempt - 1));
    return Duration.ofMillis(Math.round(options.jitter() ? ThreadLocalRandom.current().nextDouble() * capped : capped));
}
```

Un reintento prefiere el servidor del intento anterior cuando las colas son iguales: ese servidor quizá todavía tiene el prompt en su cola o en su historial. Después del último intento, el job va a las cartas muertas con el último motivo: `gave up after 4 attempts, last: …`. Los valores por defecto son 4 intentos, 2 s de espera base, un tope de 1 minuto y 10 minutos de plazo por job.

### Idempotencia: cada job se ejecuta una vez

Una cola con confirmaciones entrega **al menos una vez**: a un worker que muere después de terminar un job pero antes de confirmarlo se le vuelve a entregar ese job, a él mismo o a otro worker. La [lección sobre fiabilidad de RabbitMQ](../../rabbitmq/04-reliability/#los-duplicados-son-normales-consumidores-idempotentes) dice lo mismo. Como ComfyUI tampoco deduplica, el worker lo hace con tres comprobaciones:

1. **`done.json`** en la carpeta del job, en el almacén de resultados: el job ha terminado, se confirma sin ejecutarlo.
2. **Un archivo de reserva**, creado con `FileMode.CreateNew` en C# y `StandardOpenOption.CREATE_NEW` en Java, que falla de forma atómica si el archivo existe: otro worker está ejecutando el job. La reserva tiene un plazo de arrendamiento, una hora por defecto; una reserva más antigua que su plazo pertenece a un worker muerto, y se toma.
3. **El identificador del prompt** en el servidor: el paso de puesta al día encuentra un prompt que un intento anterior encoló o terminó.

```csharp
// CreateNew fails if the file exists, atomically, on every OS and on most network file systems.
using var file = new FileStream(path, FileMode.CreateNew, FileAccess.Write);
JsonSerializer.Serialize(file, new JsonObject { ["owner"] = owner, ["expires"] = DateTimeOffset.UtcNow.Add(lease) });
return true;
```

Una carpeta con un archivo de reserva sustituye a lo que usaría un despliegue real: almacenamiento de objetos para los archivos, y una fila de base de datos con una clave única para la reserva y el registro. La regla es la misma: reservar antes de ejecutar, registrar antes de confirmar.

### Plazos, `/interrupt` y cartas muertas

Cada intento se ejecuta con un plazo enlazado al token de cancelación del worker. Cuando vence el plazo, [`CancelPromptAsync`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/csharp/ComfyWorker/ComfyInstance.cs) envía `/interrupt` con el identificador del prompt, borra el identificador de la cola por si no había empezado, y espera a que haya salido de `/queue`. Sin esa espera, el reintento, que usa el mismo identificador de prompt, podría recibir los últimos mensajes de la ejecución interrumpida.

Los fallos definitivos y los reintentos agotados van a las cartas muertas con un motivo que una persona puede leer. El motivo también se escribe en `failed.txt` en la carpeta del job, y la reserva se libera, para que alguien pueda corregir el workflow y volver a encolar el job.

### Un pool de GPU

Al worker se le dan sus servidores en la línea de comandos, uno por GPU: `--gpu gpu0=http://127.0.0.1:8188 --gpu gpu1=http://127.0.0.1:8189`. Un semáforo cuenta los libres. Para elegir un servidor, [`GpuPool`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/csharp/ComfyWorker/GpuPool.cs) pide `/system_stats` y `/queue` a cada servidor libre, con un límite de 3 segundos por sonda, y ordena los que están sanos:

```csharp
var healthy = health.Where(h => h.Health.Healthy)
    .OrderBy(h => h.Health.QueueLength)
    .ThenBy(h => h.Slot.Instance == prefer ? 0 : 1)
    .ThenBy(h => slots.IndexOf(h.Slot))
    .ToList();
```

La longitud de la cola importa porque un worker rara vez es el único cliente de un servidor: otro worker, o una persona en la interfaz web, puede haber encolado prompts allí. «El menos cargado» significa «el que tiene menos prompts delante», algo que ComfyUI sí puede decir; la VRAM libre sería una peor señal, ya que ComfyUI mantiene los modelos cargados a propósito. Cuando ningún servidor está sano, el pool los muestra y espera 5 segundos.

### Comprobación de salud y parada ordenada

`comfy-worker health` sondea cada servidor y sale con 0 si al menos uno está sano, que es lo que necesita una sonda de disponibilidad:

```
gpu0: healthy, device cpu, 23238 MiB free, 0 prompt(s) in its queue
gpu1: unreachable (HttpRequestException)
exit code 0
```

El worker de Java muestra `ConnectException` en la segunda línea. El resto es idéntico.

Un contenedor se detiene con SIGTERM, y se mata tras un periodo de gracia. El worker usa dos tokens: `stopReceiving` impide que los bucles tomen jobs nuevos, y `abort`, que se dispara tras `--grace-s` segundos, interrumpe los jobs que siguen en ejecución y los devuelve a la cola. En C#, [`PosixSignalRegistration`](https://learn.microsoft.com/dotnet/api/system.runtime.interopservices.posixsignalregistration) captura la señal:

```csharp
void Stop(PosixSignalContext context)
{
    context.Cancel = true;
    if (stopReceiving.IsCancellationRequested) return;
    log($"{context.Signal}: no new jobs, {grace.TotalSeconds:0} s for the running ones");
    stopReceiving.Cancel();
    abort.CancelAfter(grace);
}
using var sigint = PosixSignalRegistration.Create(PosixSignal.SIGINT, Stop);
using var sigterm = PosixSignalRegistration.Create(PosixSignal.SIGTERM, Stop);
```

En Java, un [shutdown hook](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Runtime.html#addShutdownHook(java.lang.Thread)) se ejecuta con SIGTERM o Ctrl+C, y la JVM termina cuando el hook retorna, así que el hook espera al hilo principal:

```java
Runtime.getRuntime().addShutdownHook(new Thread(() -> {
    if (!main.isAlive()) {
        return;
    }
    log.accept("shutdown: no new jobs, " + grace.toSeconds() + " s for the running ones");
    stopReceiving.cancel();
    abort.cancelAfter(grace);
    try {
        main.join();
    } catch (InterruptedException e) {
        Thread.currentThread().interrupt();
    }
}));
```

Java no tiene `CancellationToken`, así que [`Cancellation.java`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/java/src/main/java/dev/learn/comfy/worker/Cancellation.java) es un pequeño equivalente: una bandera, un padre, un plazo, y esperas cortadas en tramos breves que la comprueban. Mantén el periodo de gracia por debajo del `terminationGracePeriodSeconds` de Kubernetes, 30 s por defecto, o el pod muere antes de que el worker haya devuelto sus jobs.

### Con RabbitMQ

[`RabbitMqJobQueue`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/csharp/ComfyWorker/RabbitMqJobQueue.cs) implementa la misma interfaz con el [cliente .NET de RabbitMQ](https://www.rabbitmq.com/client-libraries/dotnet) 7.2.2, y su gemelo de Java con el [cliente Java](https://www.rabbitmq.com/client-libraries/java-client) 5.35.0:

- una [quorum queue](https://www.rabbitmq.com/docs/quorum-queues) duradera para los jobs, y una segunda, `<queue>.dead`, para las cartas muertas;
- confirmaciones manuales, y un [prefetch](https://www.rabbitmq.com/docs/consumer-prefetch) igual al número de GPU, para que el broker nunca le dé a un worker más jobs de los que puede ejecutar;
- una carta muerta se publica en `<queue>.dead` con el motivo en una cabecera `x-worker-reason`, y luego se confirma el original;
- una devolución a la cola al parar es un `basicNack` con `requeue` activado;
- `enqueue` publica un archivo de jobs con mensajes persistentes, el identificador del job como identificador del mensaje, y confirmaciones del publicador.

```java
/** Published to the dead-letter queue with the reason in a header, then acked. */
@Override
public void deadLetter(String reason) throws IOException {
    AMQP.BasicProperties properties = MessageProperties.PERSISTENT_BASIC.builder()
            .messageId(job.id()).contentType("application/json").headers(Map.of("x-worker-reason", reason)).build();
    synchronized (channel) {
        channel.basicPublish("", deadLetterQueue, properties, body);
        channel.basicAck(tag, false);
    }
}
```

El worker publica la carta muerta él mismo en lugar de usar los [dead letter exchanges](https://www.rabbitmq.com/docs/dlx) de RabbitMQ, porque un `basicReject` no puede llevar un motivo. Si el worker muere entre la publicación y la confirmación, el job se vuelve a entregar, y `failed.txt` no lo detiene: la carta muerta puede aparecer dos veces. Los dos adaptadores compilan y la CI los construye, pero **el curso todavía no los ha ejecutado contra un broker**: la ejecución con RabbitMQ está *por verificar*. Los comandos serían:

```bash
java -jar java/target/comfy-worker.jar enqueue --rabbitmq amqp://guest:guest@localhost --queue renders --jobs jobs/happy.jsonl
dotnet csharp/ComfyWorker/bin/Release/net10.0/comfy-worker.dll run --rabbitmq amqp://guest:guest@localhost --queue renders \
  --gpu gpu0=http://127.0.0.1:8188 --store out/store-rabbit
```

## Probar sin ComfyUI

### Un servidor falso a partir de respuestas grabadas

Una prueba que necesita una GPU se ejecuta pocas veces. Los fallos del worker tienen que ver con códigos HTTP, mensajes WebSocket y tiempos, y todo eso se puede reproducir. [`record.py`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/record/record.py) arranca un ComfyUI v0.36.0 real con `--cpu` en una carpeta base temporal, provoca cada caso con workflows que no necesitan ningún modelo, y guarda las peticiones, las respuestas y los mensajes WebSocket en `data/recorded/`: un éxito, el mismo identificador de prompt enviado dos veces, tres prompts seguidos, un error de validación, un identificador de prompt no válido, un `IndexError` en `ImageToMask`, una interrupción, un 500 y las demás rutas.

[`FakeComfyServer`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/csharp/FakeComfy/FakeComfyServer.cs) es una [API mínima](https://learn.microsoft.com/aspnet/core/fundamentals/minimal-apis) sobre [Kestrel](https://learn.microsoft.com/aspnet/core/fundamentals/servers/kestrel) que sirve las mismas rutas con esas respuestas, ejecuta un prompt a la vez, escribe archivos PNG reales para los nodos `SaveImage`, y sigue un guion, una palabra por prompt en orden de llegada:

| Palabra | Lo que hace el servidor falso |
|---|---|
| `ok` | ejecuta cada nodo y luego `execution_success` |
| `500` | responde 500 como aiohttp cuando un manejador lanza una excepción |
| `invalid` | 400 con `prompt_outputs_failed_validation` y `node_errors` |
| `error` | `execution_error` en el segundo nodo, el `IndexError` grabado |
| `oom` | `execution_error` con el tipo y los consejos de una falta de memoria |
| `drop` | corta el WebSocket del cliente en el primer nodo y luego termina |
| `hang` | se detiene en el segundo nodo hasta `POST /interrupt` |
| `slow` | como `ok`, diez veces más lento |

`--busy N` añade a su cola N prompts de otro cliente, para probar el planificador. El servidor falso anota lo que recibió, por identificador de prompt, para que las pruebas puedan comprobar cuántas veces se envió y se ejecutó un prompt. Las pruebas de C# lo usan dentro del mismo proceso; las de Java y las transcripciones lo arrancan como programa.

### Las pruebas

[`WorkerTests.cs`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/csharp/ComfyWorker.Tests/WorkerTests.cs) usa [xUnit v3](https://xunit.net/docs/getting-started/v3/getting-started), y [`WorkerTest.java`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/java/src/test/java/dev/learn/comfy/worker/WorkerTest.java) [JUnit 6](https://docs.junit.org/). Sus nombres dicen lo que comprueban:

- `Success_stores_the_files_and_a_duplicate_delivery_does_not_run_again`: el mismo job encolado dos veces se ejecuta una vez y se confirma dos veces.
- `Server_error_500_is_retried_with_backoff`: enviado dos veces, ejecutado una vez.
- `WebSocket_dropping_mid_job_is_followed_again_without_posting_twice`
- `Validation_error_goes_to_the_dead_letter_queue_without_retry`
- `Timeout_interrupts_the_prompt_and_gives_up_after_the_last_attempt`: dos interrupciones, y luego la reserva queda libre para un operador.
- `Out_of_memory_is_retried_and_other_execution_errors_are_not`
- `Two_workers_competing_for_the_same_jobs_run_each_job_once`: 8 jobs, cada uno entregado dos veces, 2 workers en 2 servidores; cada job se ejecuta exactamente una vez, los dos servidores trabajan, 16 confirmaciones.
- `Scheduler_picks_the_instance_with_the_shortest_queue`
- `Shutdown_after_the_grace_period_interrupts_and_requeues`

C# tiene dos más, `Unreachable_instance_is_reported_and_skipped` y `Graceful_shutdown_lets_the_running_job_finish_and_takes_no_new_one`. En la máquina Windows del autor:

```bash
bash code/comfyui/worker/check.sh build
bash code/comfyui/worker/check.sh test
```

```
   ComfyWorker.Tests  Total: 11, Errors: 0, Failed: 0, Skipped: 0, Not Run: 0, Time: 11.909s
[INFO] Tests run: 9, Failures: 0, Errors: 0, Skipped: 0
```

Los proyectos de prueba de xUnit v3 son programas: `check.sh` ejecuta el ensamblado de pruebas con `dotnet`. `dotnet test` en .NET 10 necesita `"test": {"runner": "Microsoft.Testing.Platform"}` en `global.json`, y el del worker lo tiene.

### Los fallos, desde la línea de comandos

`check.sh transcripts` ejecuta los dos workers contra servidores falsos y compara su salida con `expected/`. Los jobs de [`jobs/failures.jsonl`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/jobs/failures.jsonl) se encuentran con el guion `500,ok,drop,invalid,oom,ok,error,hang,hang`, con 2 intentos, un plazo de 1 s y una espera base de 100 ms sin jitter:

```bash
dotnet csharp/ComfyWorker/bin/Release/net10.0/comfy-worker.dll run --gpu gpu0=http://127.0.0.1:52100/ \
  --store out/store-failures-cs --jobs jobs/failures.jsonl \
  --name worker-1 --no-jitter --base-delay-ms 100 --poll-ms 200 --attempts 2 --timeout-s 1
```

```
worker worker-1: 1 GPU(s), up to 2 attempts, job timeout 1 s
job 00000003: attempt 1 failed, POST /prompt 500, 500 Internal Server Error; retry in 100 ms
job 00000003 attempt 2 on gpu0: POST /prompt 200
job 00000003: done on gpu0 after 2 attempt(s), 2 file(s): 3-solid_00001_.png 12f8083634dd0a19, 4-inverted_00001_.png 12f8083634dd0a19
job 00000004 attempt 1 on gpu0: POST /prompt 200
job 00000004 attempt 1 on gpu0: WebSocket lost, reconnecting with the same client id
job 00000004: done on gpu0 after 1 attempt(s), 2 file(s): 3-solid_00002_.png 12f8083634dd0a19, 4-inverted_00002_.png 12f8083634dd0a19
job 00000005: dead-lettered, POST /prompt 400, prompt_outputs_failed_validation: node 3 (KSampler): exception_during_inner_validation
job 00000006 attempt 1 on gpu0: POST /prompt 200
job 00000006: attempt 1 failed, execution_error, node 2 (ImageInvert): torch.OutOfMemoryError: Allocation on device ; retry in 100 ms
job 00000006 attempt 2 on gpu0: POST /prompt 200
job 00000006: done on gpu0 after 2 attempt(s), 2 file(s): 3-solid_00003_.png 12f8083634dd0a19, 4-inverted_00003_.png 12f8083634dd0a19
job 00000007 attempt 1 on gpu0: POST /prompt 200
job 00000007: dead-lettered, execution_error, node 2 (ImageToMask): IndexError: index 3 is out of bounds for dimension 3 with size 3
job 00000008 attempt 1 on gpu0: POST /prompt 200
job 00000008 attempt 1 on gpu0: no result after 1 s, POST /interrupt and remove it from the queue
job 00000008: attempt 1 failed, timed out after 1 s; retry in 100 ms
job 00000008 attempt 2 on gpu0: POST /prompt 200
job 00000008 attempt 2 on gpu0: no result after 1 s, POST /interrupt and remove it from the queue
job 00000008: dead-lettered, gave up after 2 attempts, last: timed out after 1 s
job 00000009 attempt 1 on gpu0: POST /prompt 200
job 00000009: done on gpu0 after 1 attempt(s), 2 file(s): 3-solid_00004_.png 12f8083634dd0a19, 4-inverted_00004_.png 12f8083634dd0a19
worker worker-1: stopped
summary: 4 acknowledged, 3 dead-lettered
  dead letter 00000005: POST /prompt 400, prompt_outputs_failed_validation: node 3 (KSampler): exception_during_inner_validation
  dead letter 00000007: execution_error, node 2 (ImageToMask): IndexError: index 3 is out of bounds for dimension 3 with size 3
  dead letter 00000008: gave up after 2 attempts, last: timed out after 1 s
```

El puerto cambia de una ejecución a otra. El worker de Java, `java -jar java/target/comfy-worker.jar` con los mismos argumentos, imprime exactamente las mismas líneas. La primera línea del job 3 no tiene «POST /prompt 200» porque el intento falló en el envío. El WebSocket cortado no cuesta un segundo envío: el worker se reconecta con el mismo identificador de cliente y encuentra el final en `/history`. La falta de memoria se reintenta, el `IndexError` no.

Con dos servidores falsos, el primero con dos prompts de otra persona, el planificador manda el primer job al servidor libre. De la ejecución de Java:

```
scheduler: gpu1 chosen, queue lengths gpu0 2, gpu1 0
scheduler: gpu0 chosen, queue lengths gpu0 2, gpu1 0
```

La segunda línea es correcta: `gpu1` está ahora ocupado con el propio job del worker, y solo los servidores libres son candidatos. Qué job va a dónde depende de los tiempos, así que `check.sh` solo compara la línea de resumen, `summary: 4 acknowledged, 0 dead-lettered`.

### Contra un ComfyUI real en CPU

`check.sh integration` arranca ComfyUI v0.36.0 con `--cpu` mediante el `server.sh` de la lección 4, y ejecuta [`jobs/real.jsonl`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/jobs/real.jsonl): el workflow de color sólido de la lección 4, el mismo job una segunda vez, un workflow que falla con un `IndexError`, y uno lento, tres desenfoques grandes de una imagen de 1024 × 1024. Primero el worker de C#:

```
worker worker-1: 1 GPU(s), up to 2 attempts, job timeout 120 s
job 00000021 attempt 1 on gpu0: POST /prompt 200
job 00000021: done on gpu0 after 1 attempt(s), 2 file(s): 3-solid_00001_.png 413ca196d3253a3a, 4-inverted_00001_.png 6ae2ff48c6792970
job 00000021: already done, acknowledged without running
job 00000022 attempt 1 on gpu0: POST /prompt 200
job 00000022: dead-lettered, execution_error, node 2 (ImageToMask): IndexError: index 3 is out of bounds for dimension 3 with size 3
job 00000023 attempt 1 on gpu0: POST /prompt 200
job 00000023: done on gpu0 after 1 attempt(s), 1 file(s): 5-slow_00001_.png f4a8fceb7d74373b
worker worker-1: stopped
summary: 3 acknowledged, 1 dead-lettered
  dead letter 00000022: execution_error, node 2 (ImageToMask): IndexError: index 3 is out of bounds for dimension 3 with size 3
```

Después el worker de Java, con otro almacén de resultados, en el mismo servidor y con los mismos identificadores de job. Encuentra los prompts terminados en `/history` y los descarga sin volver a ejecutarlos; el que falló no es un éxito en el historial, así que se envía y vuelve a fallar:

```
job 00000021 attempt 1 on gpu0: already in /history, downloading its outputs
job 00000021: done on gpu0 after 1 attempt(s), 2 file(s): 3-solid_00001_.png <sha256>, 4-inverted_00001_.png <sha256>
job 00000021: already done, acknowledged without running
job 00000022 attempt 1 on gpu0: POST /prompt 200
job 00000022: dead-lettered, execution_error, node 2 (ImageToMask): IndexError: index 3 is out of bounds for dimension 3 with size 3
job 00000023 attempt 1 on gpu0: already in /history, downloading its outputs
```

`check.sh` sustituye los hashes por `<sha256>` antes de comparar, porque los bytes de un PNG dependen de la versión de zlib.

### CI

El workflow tiene dos jobs:

- **`fake`**, en Ubuntu, Windows y macOS: .NET 10, Java 25, y luego `bash code/comfyui/worker/check.sh`, que compila, ejecuta las dos baterías de pruebas y compara las transcripciones. Sin GPU, sin modelo, sin ComfyUI.
- **`real`**, en Ubuntu: clona ComfyUI en `v0.36.0`, comprueba que la etiqueta es el commit `ee71d5c`, instala PyTorch 2.13.0 para CPU y las dependencias de ComfyUI, y luego `check.sh build` y `check.sh integration`.

La primera ejecución de la CI encontró un error que Windows ocultaba. `check.sh` detiene los servidores falsos con `kill`, y en el runner de Linux seguían vivos, así que el script los esperó hasta que se canceló el job; en Windows, el `kill` de Git Bash sí los había terminado. El servidor falso ahora espera SIGTERM o SIGINT con `PosixSignalRegistration`, y cada job tiene un `timeout-minutes`. La ejecución [35178934958](https://github.com/spareilleux/learn/actions/runs/35178934958) pasó después en los cuatro jobs.

## Desplegarlo

Nada de esta sección lo ha ejecutado el curso: está *por verificar*, según la documentación citada.

- **Un contenedor.** ComfyUI v0.36.0 no trae Dockerfile. Una imagen necesita Python, una compilación de PyTorch para su versión de CUDA, el `requirements.txt` de ComfyUI, los nodos personalizados que hayas revisado (lección 11), y un comando como `python main.py --listen 0.0.0.0 --port 8188 --base-directory /data --extra-model-paths-config /config/extra_model_paths.yaml`. La GPU llega al contenedor mediante el [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/index.html). Construye el worker como una segunda imagen; no necesita GPU.
- **Kubernetes y las GPU.** Con el device plugin de NVIDIA, un contenedor pide una GPU con `resources.limits: nvidia.com/gpu: 1` ([Schedule GPUs](https://kubernetes.io/docs/tasks/manage-gpus/scheduling-gpus/)). Las GPU solo se indican como límites, y enteras: dos contenedores no comparten una sin time-slicing o MIG. Un pod por GPU con ComfyUI y el worker como dos contenedores mantiene simple «un servidor por GPU»; el worker tiene entonces un único `--gpu` en `127.0.0.1`. La [lección sobre pods](../../kubernetes/02-pods/#tres-sondas) cubre las sondas: `comfy-worker health` sirve para una sonda de disponibilidad, y una [sonda de startup](../../kubernetes/02-pods/#una-sonda-de-startup-para-la-jvm) da a ComfyUI tiempo para arrancar. Su sección sobre [requests y limits](../../kubernetes/02-pods/#requests-limits-y-qos) se aplica a la RAM que ocupan los modelos cuando salen de la GPU.
- **Modelos compartidos de solo lectura.** Un checkpoint de varios gigabytes no debería copiarse en cada pod. Monta un volumen de solo lectura, y haz que cada servidor apunte a él con `extra_model_paths.yaml`; el archivo [`extra_model_paths.yaml.example`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/extra_model_paths.yaml.example) del repositorio muestra el formato. Mantén `output`, `input`, `temp` y `user` separados por servidor, bajo su propio `--base-directory`.
- **Arranque en frío.** Un servidor nuevo tiene que arrancar Python, importar PyTorch y los nodos personalizados, y luego cargar cada modelo del disco a la RAM y a la VRAM la primera vez que un prompt lo necesita. En la lección 8, el primer render en un servidor recién arrancado fue sobre todo carga desde un SSD externo; desde un volumen de red puede tardar mucho más. Calienta un servidor nuevo con un prompt pequeño antes de que pase su sonda de disponibilidad, y mantén sus modelos cargados en lugar de escalar a cero si la latencia importa.
- **`--highvram` y `--lowvram`.** En un servidor que renderiza todo el día, [`--highvram`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/cli_args.py#L168-L172) mantiene los modelos en la memoria de la GPU en lugar de devolverlos a la memoria de la CPU después de usarlos. `--lowvram` ejecuta los codificadores de texto en la CPU, pero su texto de ayuda dice que no hace nada cuando la VRAM dinámica está activa, y [`enables_dynamic_vram`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/cli_args.py#L317-L320) la activa por defecto salvo con `--highvram`, `--gpu-only`, `--novram` o `--cpu`. Mide las dos opciones con tus workflows.
- **Coste.** Una GPU cuesta lo mismo por hora tanto si renderiza como si espera. El coste de una imagen es más o menos el precio por hora dividido entre las imágenes por hora con la utilización real, más el almacenamiento y la transferencia. Agrupar los jobs de un mismo modelo en un mismo servidor evita cambios de modelo; el planificador de aquí no lo hace, y es uno de los ejercicios.

## Experimento con GA

El primer experimento del laboratorio GA, [`01-chord-neck.yaml`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/ga-lab/experiments/01-chord-neck.yaml), genera un mástil de guitarra para cada uno de diez acordes, de C a Bm7b5, con el mapa de diapasón de GA a través del ControlNet, para las semillas 42 y 43: veinte imágenes. La lección 14, el laboratorio Guitar Alchemist, lo ejecutará con el runner del laboratorio, en una GPU, comprobando la memoria antes de cada prompt y midiendo dónde caen los puntos. El worker es la otra cara del mismo trabajo: el lote como jobs en una cola, repartidos entre las GPU que haya, con reintentos y un archivo de resultados.

[`jobs/ga-chord-neck.jsonl`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/jobs/ga-chord-neck.jsonl) tiene un job por imagen. El identificador codifica la posición del acorde y la semilla, `00050043-…` para el quinto acorde, D, y la semilla 43, así que encolar el archivo dos veces no ejecuta nada dos veces. Cada línea fija las mismas entradas que el experimento:

```json
{"id": "00010042-0000-4000-8000-000000000000", "workflow": "../../ga-lab/workflows/ga-chord-neck.api.json", "set": {"3.seed": 42, "18.chord": "C", "18.note_style": "filled", "18.inlays": "hide", "18.fret_start": 0, "18.fret_end": 5, "22.strength": 0.8}}
```

[`jobs/results.py`](https://github.com/spareilleux/learn/blob/1bb94b047841da315a41c7773157c929d8a91cf1/code/comfyui/worker/jobs/results.py) convierte el almacén de resultados en una fila CSV por job: sus parámetros, su estado (`done`, `dead-lettered` o `pending`), su servidor, sus intentos y sus archivos. `check.sh` ejecuta los veinte jobs contra un servidor falso que se queda sin memoria una vez, lo que comprueba el archivo de jobs frente al workflow, no las imágenes:

```
job 00020042 attempt 1 on gpu0: POST /prompt 200
job 00020042: attempt 1 failed, execution_error, node 4 (CheckpointLoaderSimple): torch.OutOfMemoryError: Allocation on device ; retry in 100 ms
job 00020042 attempt 2 on gpu0: POST /prompt 200
job 00020042: done on gpu0 after 2 attempt(s), 2 file(s): 9-neck_00003_.png 12f8083634dd0a19, 19-neck-map_00003_.png 12f8083634dd0a19
```

```
summary: 20 acknowledged, 0 dead-lettered
```

Las primeras filas del CSV:

```bash
python jobs/results.py jobs/ga-chord-neck.jsonl out/store-ga-cs
```

```
job,18.chord,18.fret_end,18.fret_start,18.inlays,18.note_style,22.strength,3.seed,status,gpu,attempts,files,reason
00010042,C,5,0,hide,filled,0.8,42,done,gpu0,1,9-neck_00001_.png:12f8083634dd0a19 19-neck-map_00001_.png:12f8083634dd0a19,
00010043,C,5,0,hide,filled,0.8,43,done,gpu0,1,9-neck_00002_.png:12f8083634dd0a19 19-neck-map_00002_.png:12f8083634dd0a19,
00020042,G,5,0,hide,filled,0.8,42,done,gpu0,2,9-neck_00003_.png:12f8083634dd0a19 19-neck-map_00003_.png:12f8083634dd0a19,
```

En la GPU, con SDXL y el ControlNet cargados, el comando sería el mismo con la dirección del servidor real, y un segundo `--gpu` para una segunda tarjeta. Esa ejecución está *por verificar*: el curso nunca arranca ComfyUI en la GPU desde sus comprobaciones automáticas, y esa medición le corresponde al runner del laboratorio.

## Puntos clave

- Un servidor ComfyUI ejecuta un prompt a la vez. Varias GPU significan varios servidores, cada uno con `--cuda-device` y su propio puerto, y algo delante que elija.
- ComfyUI no deduplica identificadores de prompt, no reproduce los eventos WebSocket perdidos, envía `execution_success` antes de escribir el historial y difunde `execution_interrupted`. Un worker tiene que consultar `/queue` y `/history` por su cuenta, y hacer coincidir las entradas del historial con el número de su ejecución.
- Usa el identificador del job como `prompt_id`, reserva el job antes de ejecutarlo, regístralo antes de confirmarlo: así una entrega de al menos una vez ejecuta cada job una sola vez.
- Clasifica los fallos: un 400 o un `execution_error` normal es definitivo y va a las cartas muertas; un 5xx, una conexión perdida, una falta de memoria o un plazo vencido es transitorio y se reintenta con backoff exponencial y jitter.
- Un plazo vencido no está resuelto hasta que el prompt se ha interrumpido y ha salido de la cola del servidor.
- Elige el servidor con menos prompts delante, y deja de tomar jobs con SIGTERM antes de que acabe el periodo de gracia.
- Un servidor falso que reproduce respuestas grabadas prueba cada fallo en tres sistemas operativos en minutos; un servidor CPU con workflows sin modelo contrasta el falso con el real.

## Tu turno

Arranca el servidor falso y haz que tu worker se enfrente a un fallo de verdad: mata el proceso de ComfyUI en mitad de un prompt, o devuelve un 500 en `/prompt`, y comprueba que el trabajo vuelve exactamente una vez, ni cero ni dos. Pon después dos trabajos en cola con el mismo identificador y mira si tu reserva detiene realmente al segundo. Una cola vale lo que vale el día en que algo se cae sosteniendo un trabajo.

## Ejercicios

1. Calcula las esperas entre intentos con los valores por defecto (4 intentos, base de 2 s, tope de 1 minuto) sin jitter. Con full jitter, ¿cuál es la espera total media de un job que falla siempre?
2. Intercambia los pasos 2 y 3 de un intento: primero enviar, luego abrir el WebSocket. ¿Qué puede fallar con un prompt que tarda 50 ms, y qué parte del worker salva aun así el job?
3. Un worker se ejecuta con `--timeout-s 7200`, y un job tarda 90 minutos. El plazo de la reserva es de una hora, el valor por defecto. Una segunda entrega del job llega en el minuto 70 a otro worker. ¿Qué pasa, y cómo lo arreglarías?
4. Con RabbitMQ, un worker escribe `done.json` y luego su contenedor muere antes de `basicAck`. Sigue el job hasta el final. Después responde lo mismo para una muerte entre la publicación de la carta muerta y su confirmación.
5. Cambia el planificador para que un servidor cuya cola ya tenga `--max-queue` prompts o más no sea candidato, y el job espere. Escribe primero la prueba de C#, con dos servidores falsos y `Busy`.
6. Añade a `results.py` una columna con el tiempo real de cada job, y di dónde tendría que registrarlo el worker.
7. Un pod ejecuta ComfyUI y el worker. Escribe su sonda de disponibilidad y su `terminationGracePeriodSeconds` para un worker arrancado con `--grace-s 60`.

<details>
<summary>Solución 1</summary>

Sin jitter, la espera después del intento n es 2 s × 2^(n−1): 2 s después del primer intento, 4 s después del segundo, 8 s después del tercero. No hay espera después del cuarto: el job va a las cartas muertas. En total, 14 s de espera, más hasta cuatro plazos de 10 minutos si cada intento se bloquea. Con full jitter, cada espera es uniforme entre 0 y su tope, así que su valor medio es la mitad: 1 + 2 + 4 = 7 s de media. El tope de un minuto solo cuenta a partir de la espera después del sexto intento, 2 × 2^5 = 64 s.

</details>

<details>
<summary>Solución 2</summary>

El prompt puede terminar antes de que el socket esté abierto, y sus `execution_start` y `execution_success` se envían a un identificador de cliente que todavía no tiene socket. Se pierden: ComfyUI no reproduce eventos. El worker esperaría entonces mensajes que nunca llegan. Lo que lo salva es la lectura periódica de `/history`, cada `--poll-ms` (5 s por defecto): se encuentra la entrada de historial con el número de esta ejecución, y el job termina con normalidad, unos segundos tarde. Sin esa lectura esperaría hasta el plazo del job, interrumpiría un prompt ya terminado y lo reintentaría.

</details>

<details>
<summary>Solución 3</summary>

En el minuto 60 la reserva vence. En el minuto 70, el segundo worker comprueba `done.json` (no existe), y luego `TryClaim`: la reserva ha vencido, así que la borra y la toma. Si elige el mismo servidor, la puesta al día encuentra el prompt en `/queue` y lo sigue en lugar de enviarlo otra vez. En otro servidor, envía el job: el prompt se ejecuta dos veces, y los dos workers escriben las mismas salidas. Arreglos: hacer el plazo de la reserva más largo que los intentos por el plazo del job, más las esperas. Los valores por defecto lo cumplen, 4 × 10 min + 14 s es menos de una hora, pero un plazo de dos horas pide una reserva de más de 8 horas, lo que deja bloqueado ese tiempo el job de un worker muerto. El mejor arreglo es renovar la reserva mientras el job se ejecuta, con un latido que reescribe `expires` cada pocos minutos. Una reserva en base de datos haría lo mismo con un `UPDATE … WHERE owner = @me`.

</details>

<details>
<summary>Solución 4</summary>

Primer caso: la conexión se cierra sin confirmación, así que RabbitMQ devuelve el mensaje a la cola y lo entrega a otro consumidor, o al mismo worker cuando se reinicia. Esa entrega encuentra `done.json`, muestra `already done, acknowledged without running` y confirma. El job se ejecutó una vez y se confirmó una vez. Segundo caso: la carta muerta está en `renders.dead`, pero el original se entrega otra vez. El worker no registró la carta muerta como terminada: encuentra `failed.txt` pero no lo comprueba, reserva el job y lo ejecuta de nuevo. Un fallo definitivo vuelve a fallar y va a las cartas muertas por segunda vez, así que `renders.dead` tiene dos copias. Un consumidor de las cartas muertas debería deduplicarlas por identificador de mensaje, o el worker podría tratar `failed.txt` como `done.json`, a costa de no reintentar nunca un job que alguien corrigió sin vaciar su carpeta.

</details>

<details>
<summary>Solución 5</summary>

La prueba, en `WorkerTests.cs`:

```csharp
[Fact]
public async Task Server_with_a_full_queue_is_not_a_candidate()
{
    await using var h = await Harness.StartAsync(output, new FakeOptions { Busy = 5 }, new FakeOptions());
    var job = Harness.NewJob(40);
    await h.Queue.EnqueueAsync(job);

    await h.RunAsync(h.NewWorker("w1"));

    Assert.Empty(h.Fakes[0].Stats.Executed);
    Assert.Equal(1, h.Fakes[1].Stats.Executed[job.Id]);
}
```

Ya pasa, porque el servidor libre tiene la cola más corta. Haz primero que falle: da también `Busy = 5` al segundo servidor, y comprueba que el job no se envía en un segundo. Después, en `GpuPool.AcquireAsync`, filtra `h.Health.QueueLength < maxQueue` antes de ordenar, y trata «ningún candidato» como «ningún servidor sano»: mostrar y esperar. Los prompts de `--busy` nunca se ejecutan, así que el job espera para siempre; detén el worker en la prueba con `stopReceiving` y comprueba que `Posted` está vacío. El curso no ha compilado el código de esta solución: *por verificar*.

</details>

<details>
<summary>Solución 6</summary>

El worker no lo registra, así que `results.py` no puede calcularlo. En `Worker.HandleAsync`, mide desde la reserva hasta `store.Complete` con un `Stopwatch` (C#) o `System.nanoTime()` (Java), y pásalo a `Complete`, que lo escribe en `done.json`, por ejemplo `"seconds": 12.4`. Luego `results.py` lee `done.get("seconds", "")`. Para el laboratorio, el tiempo por intento es más útil que el tiempo por job, ya que las esperas del backoff forman parte del segundo: registra los dos.

</details>

<details>
<summary>Solución 7</summary>

```yaml
spec:
  terminationGracePeriodSeconds: 90
  containers:
    - name: worker
      readinessProbe:
        exec:
          command: ["dotnet", "/app/comfy-worker.dll", "health", "--gpu", "gpu0=http://127.0.0.1:8188"]
        periodSeconds: 10
        timeoutSeconds: 8
```

`health` sale con 1 cuando ningún servidor responde, así que el pod no está disponible mientras ComfyUI arranca. El periodo de gracia tiene que cubrir `--grace-s 60`, más la interrupción y la devolución a la cola, más la parada del propio ComfyUI: 90 s dejan 30 s. Kubernetes envía SIGTERM a los dos contenedores a la vez, así que ComfyUI puede morir antes de que terminen los jobs del worker; un hook `preStop` en el contenedor de ComfyUI que duerma durante el periodo de gracia lo mantiene vivo. El curso no ha aplicado este manifiesto: *por verificar*.

</details>

## Fuentes

- ComfyUI en v0.36.0, commit `ee71d5c`: [`server.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/server.py), [`main.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/main.py), [`execution.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/execution.py), [`comfy/cli_args.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy/cli_args.py), [`comfy_execution/jobs.py`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/comfy_execution/jobs.py), [`extra_model_paths.yaml.example`](https://github.com/Comfy-Org/ComfyUI/blob/ee71d5c4993f29086b27fde1629a945ae48425bf/extra_model_paths.yaml.example).
- Documentación de ComfyUI: [rutas del servidor](https://docs.comfy.org/development/comfyui-server/comms_routes), [mensajes](https://docs.comfy.org/development/comfyui-server/comms_messages).
- .NET: [channels](https://learn.microsoft.com/dotnet/core/extensions/channels), [`PosixSignalRegistration`](https://learn.microsoft.com/dotnet/api/system.runtime.interopservices.posixsignalregistration), [`ClientWebSocket`](https://learn.microsoft.com/dotnet/api/system.net.websockets.clientwebsocket), [API mínimas](https://learn.microsoft.com/aspnet/core/fundamentals/minimal-apis), [Kestrel](https://learn.microsoft.com/aspnet/core/fundamentals/servers/kestrel), [xUnit v3](https://xunit.net/docs/getting-started/v3/getting-started).
- Java: [`LinkedBlockingQueue`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/concurrent/LinkedBlockingQueue.html), [hilos virtuales](https://docs.oracle.com/en/java/javase/25/core/virtual-threads.html), [`Runtime.addShutdownHook`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Runtime.html#addShutdownHook(java.lang.Thread)), [`java.net.http.WebSocket`](https://docs.oracle.com/en/java/javase/25/docs/api/java.net.http/java/net/http/WebSocket.html), [JUnit](https://docs.junit.org/).
- RabbitMQ: [quorum queues](https://www.rabbitmq.com/docs/quorum-queues), [consumer prefetch](https://www.rabbitmq.com/docs/consumer-prefetch), [dead letter exchanges](https://www.rabbitmq.com/docs/dlx), [cliente .NET](https://www.rabbitmq.com/client-libraries/dotnet), [cliente Java](https://www.rabbitmq.com/client-libraries/java-client).
- M. Brooker, [Exponential Backoff And Jitter](https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/), AWS Architecture Blog, 2015.
- Kubernetes: [Schedule GPUs](https://kubernetes.io/docs/tasks/manage-gpus/scheduling-gpus/), [terminación de pods](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-termination); NVIDIA [Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/index.html).
