---
title: 2. Pods
description: El ciclo de vida y las condiciones de un pod, las sondas liveness, readiness y startup sobre las API de C# y Spring Boot, los init containers y los sidecars nativos, las requests, los limits y las clases de QoS, cada uno mostrado fallando a propósito.
sidebar:
  order: 2
---

Código completo: [`code/kubernetes/l02`](https://github.com/spareilleux/learn/tree/main/code/kubernetes/l02), con sus comandos en [`l02/run.sh`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l02/run.sh). Cada salida de abajo sale de una ejecución de ese script; [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/check.sh) las compara con [`expected`](https://github.com/spareilleux/learn/tree/main/code/kubernetes/expected).

Los comandos se muestran tal como los ejecuta el script, en Bash. En Windows, ejecútalos en Git Bash o WSL, o en PowerShell sin los filtros `| grep`, `| sort` y `| head`, que solo acortan la salida.

Un **pod** es lo más pequeño que planifica Kubernetes: uno o varios contenedores que comparten una dirección de red, pueden compartir volúmenes y se colocan juntos en el mismo nodo. La mayoría de los pods contienen un solo contenedor, y rara vez creas pods a mano; lo hace un Deployment por ti (lección 3). Pero cada ajuste que decide si tu aplicación arranca, recibe tráfico y sobrevive vive en la plantilla del pod, así que esta lección mira primero los pods solos.

## Las imágenes

Esta lección y las dos siguientes ejecutan las dos API construidas en la [lección 4 del curso de contenedores WSL](../../wsl-containers/04-build-an-image/): una minimal API de ASP.NET Core y una API de Spring Boot WebFlux, que responden ambas a `GET /` en el puerto 8080 con un pequeño documento JSON. [`images.sh`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/images.sh) las construye a partir de los Containerfiles de ese curso, descarga dos imágenes auxiliares y lo carga todo en el nodo de kind. En Windows, ejecútalo desde Git Bash o WSL.

```bash
bash images.sh
```

Los manifiestos usan `imagePullPolicy: Never`: el nodo ya debe tener la imagen, y Kubernetes nunca intenta un registro. Con un registro, subirías las imágenes y dejarías el valor por defecto, `IfNotPresent` para una imagen con etiqueta.

:::caution[kind load docker-image y Docker Desktop]
El comando habitual, `kind load docker-image csharp-api:1.0`, falló en la máquina del autor con `ctr: content digest sha256:e86d3659…: not found`. kind importa la imagen en el nodo con `ctr images import --all-platforms`, y una imagen guardada desde el almacén de imágenes containerd de Docker Desktop enumera plataformas cuyas capas nunca se descargaron. Es la [incidencia #3795 de kind](https://github.com/kubernetes-sigs/kind/issues/3795), incluida en los [problemas conocidos](https://kind.sigs.k8s.io/docs/user/known-issues/) de kind. `images.sh` usa la solución alternativa: `docker save --platform linux/amd64` a un archivo, y luego `kind load image-archive`.
:::

## Un pod y su ciclo de vida

[`l02/pod.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l02/pod.yaml) ejecuta la API de C# con recursos y dos sondas, que se explican en las secciones siguientes:

```yaml
# Lección 2: un pod que ejecuta la API de C# construida en el curso de contenedores WSL, con requests, limits y dos sondas.
apiVersion: v1
kind: Pod
metadata:
  name: csharp-api
  labels:
    app: csharp-api
spec:
  containers:
    - name: api
      image: csharp-api:1.0
      # kind carga la imagen en el nodo: nunca intentes un registro
      imagePullPolicy: Never
      ports:
        - containerPort: 8080
      resources:
        requests:
          cpu: 100m
          memory: 64Mi
        limits:
          memory: 256Mi
      # Envía tráfico solo cuando GET / responde
      readinessProbe:
        httpGet:
          path: /
          port: 8080
        periodSeconds: 5
      # Reinicia el contenedor si GET / deja de responder
      livenessProbe:
        httpGet:
          path: /
          port: 8080
        periodSeconds: 10
        failureThreshold: 3
```

```text
> kubectl apply -n l02 -f l02/pod.yaml
pod/csharp-api created
> kubectl wait -n l02 --for=condition=Ready pod/csharp-api --timeout=120s
pod/csharp-api condition met
> kubectl get pod -n l02 csharp-api
NAME         READY   STATUS    RESTARTS   AGE
csharp-api   1/1     Running   0          1s
```

`STATUS` resume dos cosas distintas. La [**fase**](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-phase) del pod es una de `Pending`, `Running`, `Succeeded`, `Failed` o `Unknown`. Las **condiciones** del pod dicen qué pasos ha superado, y `kubectl wait` espera a una de ellas:

```text
> kubectl get pod -n l02 csharp-api -o jsonpath='{range .status.conditions[*]}{.type}={.status}{"\n"}{end}'
PodReadyToStartContainers=True
Initialized=True
Ready=True
ContainersReady=True
PodScheduled=True
```

En el orden en que ocurren: el scheduler eligió un nodo (`PodScheduled`), el kubelet creó el sandbox y la red del pod (`PodReadyToStartContainers`), los init containers terminaron (`Initialized`), cada contenedor superó su sonda de readiness (`ContainersReady`), y por tanto el pod está `Ready`. Solo un pod `Ready` recibe tráfico de un Service.

La salida estándar del contenedor es su log, como con `docker logs`. ASP.NET Core escribe sus líneas de arranque:

```text
> kubectl logs -n l02 csharp-api
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: http://[::]:8080
info: Microsoft.Hosting.Lifetime[0]
      Application started. Press Ctrl+C to shut down.
info: Microsoft.Hosting.Lifetime[0]
      Hosting environment: Production
info: Microsoft.Hosting.Lifetime[0]
      Content root path: /app
```

Y los eventos cuentan lo que hizo el kubelet, que es el primer sitio donde mirar cuando un pod no arranca:

```text
> kubectl get events -n l02 --field-selector involvedObject.name=csharp-api,type=Normal -o custom-columns=TYPE:.type,REASON:.reason,MESSAGE:.message --sort-by=.metadata.creationTimestamp
TYPE     REASON      MESSAGE
Normal   Scheduled   Successfully assigned l02/csharp-api to learn-k8s-control-plane
Normal   Pulled      Container image "csharp-api:1.0" already present on machine and can be accessed by the pod
Normal   Created     Container created
Normal   Started     Container started
```

En algunas ejecuciones aparece también un `Warning`, con la dirección IP del pod: `Readiness probe failed: Get "http://10.244.0.44:8080/": dial tcp 10.244.0.44:8080: connect: connection refused`. Por eso el comando de arriba solo conserva los eventos `Normal`. La primera sonda salió antes de que Kestrel escuchara. Es inofensivo, y muestra por qué importa la readiness: el proceso está en marcha, pero la aplicación aún no sirve.

## Tres sondas

Una **sonda** (probe) es una comprobación que el kubelet ejecuta contra un contenedor, por HTTP, TCP, gRPC o con un comando. [Kubernetes tiene tres tipos](https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/), y responden a tres preguntas distintas:

| Sonda | Pregunta | Cuando falla | ASP.NET Core | Spring Boot |
|---|---|---|---|---|
| **liveness** | ¿Está el proceso bloqueado sin remedio? | el kubelet reinicia el contenedor | un health check etiquetado `live` con [`MapHealthChecks`](https://learn.microsoft.com/aspnet/core/host-and-deploy/health-checks) | `/actuator/health/liveness` |
| **readiness** | ¿Puede atender peticiones ahora? | el pod se retira de los Services, nada se reinicia | un check etiquetado `ready`, que incluye las dependencias | `/actuator/health/readiness` |
| **startup** | ¿Ha terminado de arrancar? | liveness y readiness esperan; tras `failureThreshold` fallos se reinicia el contenedor | | |

El Actuator de Spring Boot [expone los dos grupos](https://docs.spring.io/spring-boot/reference/actuator/endpoints.html#actuator.endpoints.kubernetes-probes) cuando se ejecuta en Kubernetes. ASP.NET Core te deja a ti esa separación. Las dos API del curso no tienen ninguna de las dos cosas, así que aquí las sondas llaman a `GET /`. Basta para ver la mecánica, pero un endpoint de liveness real no debería comprobar una base de datos: si la base de datos cae, reiniciar todos los pods no la levanta.

### Una sonda de liveness que falla

[`l02/liveness-fail.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l02/liveness-fail.yaml) sondea `/healthz`, una ruta que la API no tiene, cada 2 segundos, y se rinde tras 2 fallos:

```yaml
      livenessProbe:
        httpGet:
          path: /healthz
          port: 8080
        periodSeconds: 2
        failureThreshold: 2
```

```text
> kubectl get pod -n l02 liveness-fail
NAME            READY   STATUS    RESTARTS     AGE
liveness-fail   1/1     Running   1 (2s ago)   6s
> kubectl get events -n l02 --field-selector involvedObject.name=liveness-fail,type=Warning -o custom-columns=TYPE:.type,REASON:.reason,MESSAGE:.message --no-headers | grep -v 'connection refused' | sort -u
Warning   Unhealthy   Liveness probe failed: HTTP probe failed with statuscode: 404
> kubectl get events -n l02 --field-selector involvedObject.name=liveness-fail,reason=Killing -o custom-columns=TYPE:.type,REASON:.reason,MESSAGE:.message --no-headers | sort -u
Normal   Killing   Container api failed liveness probe, will be restarted
```

Una sonda HTTP tiene éxito con cualquier estado entre 200 y 399; el 404 es un fallo, con el mensaje construido en [`http.go`](https://github.com/kubernetes/kubernetes/blob/f54c212e3a2f75d674b717a9b29052b20b60aefc/pkg/probe/http/http.go#L147), del kubelet, y registrado como evento por [`prober.go`](https://github.com/kubernetes/kubernetes/blob/f54c212e3a2f75d674b717a9b29052b20b60aefc/pkg/kubelet/prober/prober.go#L124). El estado anterior del contenedor es menos evidente:

```text
> kubectl get pod -n l02 liveness-fail -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason} {.status.containerStatuses[0].lastState.terminated.exitCode}{"\n"}'
Completed 0
```

El kubelet detiene un contenedor con `SIGTERM`, y ASP.NET Core lo trata como un apagado limpio, así que el contenedor matado terminó con el código 0. Un contador de reinicios que no para de crecer con el motivo `Completed` suele ser una sonda de liveness, no un fallo. Tras unos cuantos reinicios, el kubelet espera cada vez más antes del siguiente: en el clúster del autor, `STATUS` mostró `CrashLoopBackOff` desde el segundo reinicio, 16 segundos después de crear el pod.

### Una sonda de readiness que falla

El mismo error en la sonda de readiness, en [`l02/readiness-fail.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l02/readiness-fail.yaml), da un resultado distinto:

```text
> kubectl get pod -n l02 readiness-fail
NAME             READY   STATUS    RESTARTS   AGE
readiness-fail   0/1     Running   0          1s
> kubectl get pod -n l02 readiness-fail -o jsonpath='{range .status.conditions[*]}{.type}={.status}{"\n"}{end}'
PodReadyToStartContainers=True
Initialized=True
Ready=False
ContainersReady=False
PodScheduled=True
> kubectl get events -n l02 --field-selector involvedObject.name=readiness-fail,type=Warning -o custom-columns=TYPE:.type,REASON:.reason,MESSAGE:.message --no-headers | grep -v 'connection refused' | sort -u
Warning   Unhealthy   Readiness probe failed: HTTP probe failed with statuscode: 404
```

`Running`, cero reinicios, y nunca `Ready`. Desde el punto de vista del kubelet no hay nada roto; el pod simplemente nunca recibe tráfico. La lección 4 muestra la otra cara: un pod así aparece en el EndpointSlice de su Service, marcado como no listo.

### Una sonda de startup para la JVM

La API de Spring Boot necesita un par de segundos para arrancar. Una sonda de liveness con poco retardo la mataría antes de que responda; un `initialDelaySeconds` largo retrasaría la detección de los fallos reales durante toda la vida del pod. Una sonda de startup resuelve ambas cosas. [`l02/startup.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l02/startup.yaml) comprueba cada segundo, hasta 60 veces, y la sonda de liveness solo empieza tras el primer éxito:

```yaml
      startupProbe:
        httpGet:
          path: /
          port: 8080
        periodSeconds: 1
        failureThreshold: 60
      livenessProbe:
        httpGet:
          path: /
          port: 8080
        periodSeconds: 10
```

```text
> kubectl wait -n l02 --for=condition=Ready pod/java-reactor-api --timeout=180s
pod/java-reactor-api condition met
> kubectl get events -n l02 --field-selector involvedObject.name=java-reactor-api -o custom-columns=TYPE:.type,REASON:.reason,COUNT:.count,MESSAGE:.message --sort-by=.metadata.creationTimestamp
TYPE      REASON      COUNT   MESSAGE
Normal    Scheduled   1       Successfully assigned l02/java-reactor-api to learn-k8s-control-plane
Normal    Pulled      1       Container image "java-reactor-api:1.0" already present on machine and can be accessed by the pod
Normal    Created     1       Container created
Normal    Started     1       Container started
Warning   Unhealthy   1       Startup probe failed: Get "http://10.244.0.196:8080/": dial tcp 10.244.0.196:8080: connect: connection refused
```

En esta ejecución, el contenedor arrancó a las 13:18:36 y el pod estuvo listo a las 13:18:38: dos segundos, con una sonda de startup fallida que no costó nada. En un nodo cargado, la misma JVM puede tardar diez veces más, y por eso el margen es de 60 segundos y no de 3. Los tiempos cambian de una ejecución a otra, así que `check.sh` registra esta salida sin compararla.

## Init containers y sidecars

Los **init containers** se ejecutan uno tras otro, cada uno hasta terminar, antes de que arranquen los contenedores normales: una migración, un archivo de configuración, la espera de una dependencia. Desde Kubernetes 1.33, versión en la que la funcionalidad pasó a estable, un init container con `restartPolicy: Always` es en cambio un [**sidecar nativo**](https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/): arranca en la secuencia de init, pero sigue ejecutándose junto a la app, y se detiene después de ella. Los enviadores de logs, los proxies y los renovadores de certificados son sidecars típicos.

[`l02/init-sidecar.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l02/init-sidecar.yaml) tiene ambos. `setup` escribe un archivo de configuración en un volumen `emptyDir` compartido, `log-shipper` sigue un archivo de log, y `app` lee la configuración y añade una línea al log cada segundo:

```yaml
spec:
  # sh se ejecuta como PID 1 e ignora SIGTERM: sin esto, borrar el pod espera los 30 s por defecto antes de SIGKILL
  terminationGracePeriodSeconds: 5
  initContainers:
    - name: setup
      image: busybox:1.38.0
      command: ["sh", "-c", "echo 'greeting=hello' > /config/app.conf && echo setup done"]
      volumeMounts:
        - name: config
          mountPath: /config
    - name: log-shipper
      image: busybox:1.38.0
      restartPolicy: Always
      # Sigue el archivo que escribe la app; un sidecar real lo enviaría a algún sitio
      command: ["sh", "-c", "touch /logs/app.log && tail -F /logs/app.log"]
      volumeMounts:
        - name: logs
          mountPath: /logs
  containers:
    - name: app
      image: busybox:1.38.0
      command: ["sh", "-c", ". /config/app.conf; i=0; while true; do i=$((i+1)); echo \"$greeting $i\" >> /logs/app.log; sleep 1; done"]
      volumeMounts:
        - name: config
          mountPath: /config
        - name: logs
          mountPath: /logs
  volumes:
    - name: config
      emptyDir: {}
    - name: logs
      emptyDir: {}
```

```text
> kubectl get pod -n l02 init-sidecar
NAME           READY   STATUS    RESTARTS   AGE
init-sidecar   2/2     Running   0          5s
> kubectl get pod -n l02 init-sidecar -o jsonpath='{range .status.initContainerStatuses[*]}{.name}: started={.started} ready={.ready} terminated={.state.terminated.reason}{"\n"}{end}{range .status.containerStatuses[*]}{.name}: started={.started} ready={.ready}{"\n"}{end}'
setup: started=false ready=true terminated=Completed
log-shipper: started=true ready=true terminated=
app: started=true ready=true
> kubectl logs -n l02 init-sidecar -c setup
setup done
> kubectl logs -n l02 init-sidecar -c log-shipper | head -3
hello 1
hello 2
hello 3
```

`READY 2/2` cuenta el sidecar y la app, no `setup`, que ha terminado. `-c` elige un contenedor en un pod con varios contenedores. El sidecar vio la primera línea porque ya estaba en marcha cuando la app la escribió: ese orden de arranque es lo que garantiza el sidecar nativo, y lo que no garantiza un segundo contenedor normal en `containers`.

## Requests, limits y QoS

Cada contenedor puede declarar, para la CPU y la memoria:

- una **request**: lo que el scheduler le reserva en un nodo. Un pod solo se coloca donde cabe la suma de las requests.
- un **limit**: lo máximo que puede usar. Por encima de su límite de CPU, un contenedor se ralentiza (throttling); por encima de su límite de memoria, el kernel lo mata.

La CPU se cuenta en núcleos (`100m` es una décima de núcleo), la memoria en bytes (`64Mi`). El primer pod pidió `100m` y `64Mi` con un límite de memoria de `256Mi`, y sin límite de CPU: puede usar la CPU libre del nodo, pero no más memoria de la prevista. Es una elección habitual para las API web; la [página de gestión de recursos](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/) describe las opciones.

Las requests y los limits deciden la [**clase de QoS**](https://kubernetes.io/docs/concepts/workloads/pods/pod-qos/) del pod, que decide qué pods desaloja primero el kubelet cuando un nodo se queda sin memoria. [`l02/qos.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l02/qos.yaml) crea un pod de cada una:

```text
> kubectl get pods -n l02 guaranteed burstable besteffort -o custom-columns=NAME:.metadata.name,QOS:.status.qosClass
NAME         QOS
guaranteed   Guaranteed
burstable    Burstable
besteffort   BestEffort
```

La regla, tal como está escrita en [`qos.go`](https://github.com/kubernetes/kubernetes/blob/f54c212e3a2f75d674b717a9b29052b20b60aefc/pkg/apis/core/v1/helper/qos/qos.go#L39-L42): un pod es `BestEffort` si ningún contenedor tiene request ni limit de CPU o de memoria, `Guaranteed` si cada contenedor tiene requests de CPU y de memoria iguales a sus limits, y `Burstable` en los demás casos. Los pods `BestEffort` son los primeros en irse bajo presión de memoria, los `Guaranteed` los últimos.

Los dos runtimes leen el límite. .NET dimensiona su heap gestionado por el recolector de basura a partir del límite de memoria del contenedor ([`GCHeapHardLimit`](https://learn.microsoft.com/dotnet/core/runtime-config/garbage-collector#heap-hard-limit) vale por defecto el 75 % de él), y la JVM a partir de `-XX:MaxRAMPercentage`, el 25 % del límite por defecto. Un límite copiado de otro servicio puede asfixiar a uno y desperdiciar memoria en el otro.

Desde Kubernetes 1.35, las requests y los limits también se pueden [cambiar en un pod en ejecución](https://kubernetes.io/docs/tasks/configure-pod-container/resize-container-resources/) sin reiniciarlo; la lección 9, sobre el escalado, vuelve sobre ello.

## Un caso práctico: la guía de despliegue de GA

[Guitar Alchemist](https://github.com/GuitarAlchemist/ga) funciona con Docker Compose y .NET Aspire, y hay una [línea de trabajo de Kubernetes](https://github.com/GuitarAlchemist/ga/blob/3010dc68853e9228547dd2fba27ed5e5a87891da/conductor/tracks/k8s-deployment/index.md) planificada, sin empezar. Su guía de despliegue ya tiene un [Deployment para la API](https://github.com/GuitarAlchemist/ga/blob/3010dc68853e9228547dd2fba27ed5e5a87891da/docs/DEPLOYMENT_GUIDE.md#L152-L195), con una sonda de liveness en `/health` y una sonda de readiness en `/ready`, ambas en el puerto 7001. Comparado con el código del mismo commit:

- el [Dockerfile de la API](https://github.com/GuitarAlchemist/ga/blob/3010dc68853e9228547dd2fba27ed5e5a87891da/Apps/ga-server/GaApi/Dockerfile#L31-L33) expone el puerto 8080, el valor por defecto de las imágenes `aspnet` de .NET, y fija `ASPNETCORE_ENVIRONMENT=Production`;
- los valores por defecto de servicio de Aspire mapean `/health` y `/alive` [solo en el entorno Development](https://github.com/GuitarAlchemist/ga/blob/3010dc68853e9228547dd2fba27ed5e5a87891da/AllProjects.ServiceDefaults/Extensions.cs#L95-L112), una elección de la plantilla por motivos de seguridad;
- no existe ningún endpoint `/ready`; el controlador de salud propio de la API responde bajo `/api/Health`.

Tal como están escritas, las sondas fallarían contra la imagen: nada escucha en el 7001, e incluso en el 8080 las rutas devuelven 404. Según esta lección, el resultado esperado es un contenedor reiniciado por su sonda de liveness y un pod que nunca está `Ready`, pero no he desplegado GA para comprobarlo (*por verificar*). La guía tampoco declara recursos, así que el pod sería `BestEffort`. El arreglo corresponde a ambos lados: mapear un endpoint de salud `live` y otro `ready` en Production, sin los detalles a los que se refiere la advertencia de la plantilla, y apuntar las sondas hacia ellos en el 8080.

## Puntos clave

- Un pod es uno o varios contenedores colocados juntos; su fase dice en qué punto de su vida está, sus condiciones dicen qué pasos ha superado, y `Ready` decide si recibe tráfico.
- `kubectl logs`, `kubectl get events` y el `lastState` del contenedor responden a la mayoría de las preguntas del tipo «¿por qué no arranca?».
- La liveness reinicia un contenedor bloqueado, la readiness saca un pod del tráfico sin reiniciarlo, y la startup protege a los que arrancan despacio sin debilitar las otras dos.
- Un reinicio por liveness de una app ASP.NET Core aparece como `Completed`, código de salida 0: la app se apagó limpiamente cuando se le pidió.
- Los init containers se ejecutan hasta terminar, en orden; un sidecar nativo (`restartPolicy: Always`) arranca antes que la app y se ejecuta junto a ella.
- Las requests colocan los pods, los limits los acotan, y juntos fijan la clase de QoS que decide el orden de desalojo.

## Ejercicios

**1.** `l02/pod.yaml` es `Burstable`. Escribe una variante que sea `Guaranteed`, aplícala y comprueba su clase.

<details>
<summary>Solución</summary>

Las requests deben ser iguales a los limits, para la CPU y para la memoria, en cada contenedor: [`l02/pod-guaranteed.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l02/pod-guaranteed.yaml).

```yaml
      resources:
        requests:
          cpu: 100m
          memory: 128Mi
        limits:
          cpu: 100m
          memory: 128Mi
```

```text
> kubectl apply -n l02 -f l02/pod-guaranteed.yaml
pod/csharp-api-guaranteed created
> kubectl get pod -n l02 csharp-api-guaranteed -o jsonpath='{.status.qosClass}{"\n"}'
Guaranteed
```

El precio es el límite de CPU: con carga, este pod se limita a una décima de núcleo aunque el nodo esté ocioso.

</details>

**2.** Dale a la API de C# un límite de memoria de `8Mi` ([`l02/oom.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l02/oom.yaml)). ¿Qué pasa, y dónde lo ves?

<details>
<summary>Solución</summary>

```text
> kubectl apply -n l02 -f l02/oom.yaml
pod/oom created
> kubectl get pod -n l02 oom
NAME   READY   STATUS    RESTARTS     AGE
oom    1/1     Running   1 (2s ago)   2s
> kubectl get pod -n l02 oom -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason} {.status.containerStatuses[0].lastState.terminated.exitCode}{"\n"}'
OOMKilled 137
```

El kernel mata el proceso en cuanto supera el límite: motivo `OOMKilled`, código de salida 137 (128 + 9, `SIGKILL`). El kubelet lo reinicia, y unos segundos después `STATUS` muestra `OOMKilled`. `STATUS` cambia de un segundo a otro, así que `lastState` es el sitio fiable donde leer.

Al preparar este ejercicio, un límite de `16Mi` parecía suficiente al principio: la API arrancó y siguió funcionando. Luego un `kubectl exec` en ese contenedor, para leer su uso de memoria, lo llevó por encima del límite, y la API acabó `OOMKilled`. Un proceso lanzado con `kubectl exec` se ejecuta dentro del cgroup del contenedor y cuenta para su límite.

</details>

**3.** ¿Qué aspecto tiene un pod cuando falla su init container? Prueba [`l02/init-fail.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l02/init-fail.yaml), cuyo contenedor `setup` imprime un error y termina con el código 1.

<details>
<summary>Solución</summary>

```text
> kubectl apply -n l02 -f l02/init-fail.yaml
pod/init-fail created
> kubectl get pod -n l02 init-fail
NAME        READY   STATUS     RESTARTS     AGE
init-fail   0/1     Init:Error   1 (2s ago)   2s
> kubectl get pod -n l02 init-fail -o jsonpath='setup: exit code {.status.initContainerStatuses[0].lastState.terminated.exitCode}{"\n"}app: {.status.containerStatuses[0].state.waiting.reason}{"\n"}'
setup: exit code 1
app: PodInitializing
> kubectl logs -n l02 init-fail -c setup
config server unreachable
```

`Init:Error` significa que un init container terminó con un error; mientras vuelve a ejecutarse, `STATUS` muestra `Init:0/1`, cero de un init container terminados. Con la `restartPolicy: Always` por defecto del pod, el kubelet reintenta `setup` con un retardo creciente, y `app` espera en `PodInitializing` hasta que tenga éxito. El propio log del init container da el motivo.

</details>

## Fuentes

- Documentación de Kubernetes: [Pods](https://kubernetes.io/docs/concepts/workloads/pods/), [Pod lifecycle](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/), [Liveness, readiness and startup probes](https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/) y [cómo configurarlas](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/), [Init containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/), [Sidecar containers](https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/), [Resource management for pods and containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/), [Pod quality of service classes](https://kubernetes.io/docs/concepts/workloads/pods/pod-qos/)
- Código fuente en v1.37.0: [`pkg/probe/http/http.go`](https://github.com/kubernetes/kubernetes/blob/f54c212e3a2f75d674b717a9b29052b20b60aefc/pkg/probe/http/http.go#L147), [`pkg/kubelet/prober/prober.go`](https://github.com/kubernetes/kubernetes/blob/f54c212e3a2f75d674b717a9b29052b20b60aefc/pkg/kubelet/prober/prober.go#L124), [`qos.go`](https://github.com/kubernetes/kubernetes/blob/f54c212e3a2f75d674b717a9b29052b20b60aefc/pkg/apis/core/v1/helper/qos/qos.go#L39-L42)
- [Health checks en ASP.NET Core](https://learn.microsoft.com/aspnet/core/host-and-deploy/health-checks), [sondas de Kubernetes en Spring Boot](https://docs.spring.io/spring-boot/reference/actuator/endpoints.html#actuator.endpoints.kubernetes-probes), [configuración del recolector de basura de .NET](https://learn.microsoft.com/dotnet/core/runtime-config/garbage-collector)
- kind: [problemas conocidos](https://kind.sigs.k8s.io/docs/user/known-issues/), [incidencia #3795](https://github.com/kubernetes-sigs/kind/issues/3795)
