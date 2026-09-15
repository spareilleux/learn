---
title: 4. Services y DNS
description: Un nombre y una dirección estables delante de los pods de C# y Spring Boot con Services ClusterIP, NodePort y LoadBalancer, el DNS del clúster, los EndpointSlices y la readiness, y después un único punto de entrada para ambos con la Gateway API y con Ingress.
sidebar:
  order: 4
---

Código completo: [`code/kubernetes/l04`](https://github.com/spareilleux/learn/tree/main/code/kubernetes/l04), con sus comandos en [`l04/run.sh`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l04/run.sh). Como en las lecciones 2 y 3, los comandos se muestran tal como se ejecutan en Bash.

Cada pod tiene su propia dirección IP, y cada pod es temporal. En la lección 3, cada actualización sustituyó los tres pods de C# por otros nuevos, con nombres nuevos y direcciones nuevas. Un cliente no puede llevar una lista de ellos. Un **Service** es la parte estable: un nombre, una dirección IP virtual que no cambia durante la vida del Service, y un selector de etiquetas que decide, en cada momento, qué pods reciben el tráfico.

## Preparación

La lección reutiliza los dos Deployments de la lección 3, y añade un pod para enviar peticiones desde dentro del clúster:

```yaml
# Lección 4: un pod para enviar peticiones desde dentro del clúster. La imagen de curl ejecutaría curl y terminaría: sleep en su lugar.
apiVersion: v1
kind: Pod
metadata:
  name: client
spec:
  terminationGracePeriodSeconds: 0
  containers:
    - name: curl
      image: curlimages/curl:8.22.0
      command: ["sleep", "infinity"]
```

```text
> kubectl create namespace l04
namespace/l04 created
> kubectl apply -n l04 -f l03/csharp-api.yaml -f l03/java-reactor-api.yaml -f l04/client.yaml
deployment.apps/csharp-api created
deployment.apps/java-reactor-api created
pod/client created
```

## ClusterIP

[`l04/services.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l04/services.yaml) pone un Service delante de cada Deployment:

```yaml
# Lección 4: un nombre estable y una IP virtual delante de cada Deployment de la lección 3.
apiVersion: v1
kind: Service
metadata:
  name: csharp-api
spec:
  # ClusterIP es el tipo por defecto: accesible solo desde dentro del clúster
  type: ClusterIP
  selector:
    app: csharp-api
  ports:
    - name: http
      port: 80
      targetPort: http
---
apiVersion: v1
kind: Service
metadata:
  name: java-reactor-api
spec:
  selector:
    app: java-reactor-api
  ports:
    - name: http
      port: 80
      targetPort: http
```

`port` es al que llaman los clientes; `targetPort: http` es el puerto de los pods llamado `http` en la lección 3, el 8080. Dar nombre al puerto en la plantilla del pod permite a la aplicación cambiar de puerto sin tocar el Service.

```text
> kubectl apply -n l04 -f l04/services.yaml
service/csharp-api created
service/java-reactor-api created
> kubectl get -n l04 services
NAME               TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
csharp-api         ClusterIP   10.96.34.184   <none>        80/TCP    0s
java-reactor-api   ClusterIP   10.96.210.58   <none>        80/TCP    0s
> kubectl exec -n l04 client -- curl -s http://csharp-api/
{"app":"csharp-api","runtime":"<runtime>","os":"<os>","machine":"csharp-api-55b7fbb748-dn79k"}
> kubectl exec -n l04 client -- curl -s http://java-reactor-api/
{"app":"java-reactor-api","runtime":"<runtime>","os":"<os>","machine":"java-reactor-api-64bd9f4b94-xkbjc"}
```

[`kubectl exec`](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_exec/) ejecuta `curl` dentro del pod `client`, como lo haría `docker exec`. El campo `machine` es el nombre de host del pod, que es su nombre: el Service eligió uno de los pods.

El script sustituye el runtime y el sistema operativo, que dependen de la construcción de la imagen, por marcadores. En la máquina del autor, la API de C# indicó `".NET 10.0.12"` y `"Ubuntu 24.04.5 LTS"`, la distribución de su imagen base, y la API de Java `"Java 25.0.4+7-LTS"` y `"Linux 6.18.40.1-microsoft-standard-WSL2"`: `os.name` y `os.version` de Java describen el kernel, que es el kernel WSL 2 de Docker Desktop, compartido por todos los contenedores.

Una ClusterIP solo es accesible desde dentro del clúster. Ningún proceso escucha en ella: en cada nodo, [kube-proxy](https://kubernetes.io/docs/reference/networking/virtual-ips/) programa el kernel para reescribir los paquetes enviados a la dirección y al puerto del Service hacia uno de los pods. En kind, kube-proxy usa iptables; su log dice `"Using iptables Proxier"`. Un Service nuevo tarda un momento en programarse, y por eso el script espera a que el primer `curl` responda.

## DNS

El nombre `csharp-api` lo resolvió el DNS del clúster, [CoreDNS](https://coredns.io/), que crea un registro para cada Service. Su nombre completo incluye el namespace:

```text
> kubectl exec -n l04 client -- curl -s http://csharp-api.l04.svc.cluster.local/
{"app":"csharp-api","runtime":"<runtime>","os":"<os>","machine":"csharp-api-55b7fbb748-9rj4s"}
> kubectl exec -n l04 client -- cat /etc/resolv.conf
search l04.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
options ndots:5
> kubectl exec -n l04 client -- nslookup csharp-api.l04.svc.cluster.local.
Server:		10.96.0.10
Address:	10.96.0.10:53


Name:	csharp-api.l04.svc.cluster.local
Address: 10.96.34.184

```

El kubelet escribe el `/etc/resolv.conf` de cada pod:

- `nameserver 10.96.0.10` es la ClusterIP del Service `kube-dns` en `kube-system`, delante de los pods de CoreDNS de la lección 1.
- `search` hace que funcione un nombre corto: `csharp-api` se prueba primero como `csharp-api.l04.svc.cluster.local`. Desde otro namespace, basta con `csharp-api.l04`.
- `ndots:5` significa que un nombre con menos de cinco puntos pasa por la lista de búsqueda antes de probarse tal cual. `api.github.com` tiene dos, así que un pod pregunta primero por `api.github.com.l04.svc.cluster.local` y por otros dos nombres que no existen. Un punto final, como en el `nslookup` de arriba, marca un nombre como completo y se salta la lista.

La página [DNS for Services and Pods](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/) enumera los registros; [Debugging DNS resolution](https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/) es la página que hay que abrir cuando los nombres no se resuelven.

## EndpointSlices: ¿qué pods, y están listos?

El selector del Service lo evalúa el controlador de EndpointSlice, que escribe las direcciones de los pods que coinciden en [**EndpointSlices**](https://kubernetes.io/docs/concepts/services-networking/endpoint-slices/). kube-proxy lee estos, no los pods.

```text
> kubectl get -n l04 endpointslices
NAME                     ADDRESSTYPE   PORTS   ENDPOINTS                                AGE
csharp-api-<slice>         IPv4          8080    10.244.0.241,10.244.0.239,10.244.0.240   3s
java-reactor-api-<slice>   IPv4          8080    10.244.0.243,10.244.0.244                3s
> kubectl get -n l04 endpoints csharp-api
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME         ENDPOINTS                                               AGE
csharp-api   10.244.0.239:8080,10.244.0.240:8080,10.244.0.241:8080   3s
```

El nombre de cada slice termina con cinco caracteres aleatorios, sustituidos aquí por `<slice>`. El objeto **Endpoints**, más antiguo, sigue existiendo, y kubectl avisa: guardaba todas las direcciones de un Service en un solo objeto, lo que no escalaba a miles de pods, y está [obsoleto desde la 1.33](https://kubernetes.io/blog/2025/04/24/endpoints-deprecation/). Los tutoriales que todavía usan `kubectl get endpoints` funcionan, por ahora.

La readiness, de la lección 2, importa aquí. [`l04/unready.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l04/unready.yaml) añade un cuarto pod con la etiqueta `app: csharp-api` y una sonda de readiness que siempre falla:

```text
> kubectl apply -n l04 -f l04/unready.yaml
pod/csharp-api-unready created
> kubectl get -n l04 endpointslices -l kubernetes.io/service-name=csharp-api -o jsonpath='{range .items[*].endpoints[*]}{.targetRef.name} ready={.conditions.ready}{"\n"}{end}' | sort
csharp-api-55b7fbb748-9rj4s ready=true
csharp-api-55b7fbb748-dn79k ready=true
csharp-api-55b7fbb748-zw7ph ready=true
csharp-api-unready ready=false
```

El selector coincide con él, así que el slice lo incluye, marcado `ready=false`. Treinta peticiones muestran que kube-proxy lo omite:

```text
> kubectl exec -n l04 client -- sh -c 'for i in $(seq 30); do curl -s http://csharp-api/; echo; done' | …
3 pods answered 30 requests; csharp-api-unready answered 0
```

(La parte tras `|` cuenta los valores de `machine`; el comando completo está en `run.sh`.) También es una trampa: un Service selecciona **cualquier** pod con sus etiquetas, incluido uno de otro Deployment, o uno arrancado a mano para depurar. Esta vez, la readiness protegió a los clientes.

## NodePort

Un Service **NodePort** abre además un puerto, entre 30000 y 32767, en cada nodo. [`l04/nodeport.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l04/nodeport.yaml) pide el 30080, que [`kind/cluster.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/kind/cluster.yaml) asocia a `127.0.0.1:30080` en tu máquina con [`extraPortMappings`](https://kind.sigs.k8s.io/docs/user/configuration/#extra-port-mappings):

```yaml
spec:
  type: NodePort
  selector:
    app: csharp-api
  ports:
    - name: http
      port: 80
      targetPort: http
      nodePort: 30080
```

```text
> kubectl apply -n l04 -f l04/nodeport.yaml
service/csharp-api-nodeport created
> kubectl get -n l04 service csharp-api-nodeport
NAME                  TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
csharp-api-nodeport   NodePort   10.96.80.124   <none>        80:30080/TCP   1s
> curl -s http://localhost:30080/
{"app":"csharp-api","runtime":"<runtime>","os":"<os>","machine":"csharp-api-55b7fbb748-dn79k"}
```

El último `curl` se ejecuta en tu máquina, no en el clúster: en Windows, `curl.exe` en PowerShell. Un Service NodePort es también un Service ClusterIP. Es la forma más sencilla de entrar, pero los clientes tienen que conocer las direcciones de los nodos y un puerto poco habitual; el mapeo de puertos de kind debe declararse al crear el clúster.

## LoadBalancer

Un Service **LoadBalancer** pide a la infraestructura un balanceador de carga externo: en AKS, EKS o GKE, el controlador del proveedor de nube crea uno y escribe su dirección en el Service. kind no tiene nube, así que el curso ejecuta [cloud-provider-kind](https://github.com/kubernetes-sigs/cloud-provider-kind) v0.11.1, que cumple ese papel con un contenedor [Envoy](https://www.envoyproxy.io/) por balanceador. [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/check.sh) lo arranca como contenedor en la red Docker de kind, con acceso al socket de Docker para crear esos contenedores:

```bash
docker run -d --name learn-k8s-cloud-provider --network kind -v /var/run/docker.sock:/var/run/docker.sock \
  registry.k8s.io/cloud-provider-kind/cloud-controller-manager:v0.11.1@sha256:40e18b9cd9c798cce40d39ff5c099a4f16a36c268d8e1dda469d73955a35e403
```

En Git Bash, fija primero `MSYS_NO_PATHCONV=1`, como hace `check.sh`, o Git Bash reescribe `/var/run/docker.sock` como una ruta de Windows; `/var/run/docker.sock` es la ruta del socket dentro de la VM de Docker Desktop, no en Windows. Acceder al socket de Docker significa controlar Docker: ejecuta solo una imagen de confianza, fijada por digest como aquí.

```yaml
# Lección 4: un Service LoadBalancer. En una nube, el proveedor crea un balanceador de carga; en kind, lo hace cloud-provider-kind.
apiVersion: v1
kind: Service
metadata:
  name: java-reactor-api-lb
spec:
  type: LoadBalancer
  selector:
    app: java-reactor-api
  ports:
    - name: http
      port: 80
      targetPort: http
```

```text
> kubectl apply -n l04 -f l04/loadbalancer.yaml
service/java-reactor-api-lb created
> kubectl get -n l04 service java-reactor-api-lb
NAME                  TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
java-reactor-api-lb   LoadBalancer   10.96.155.58   172.23.0.4    80:<node-port>/TCP   1s
> kubectl exec -n l04 client -- curl -s http://172.23.0.4/
{"app":"java-reactor-api","runtime":"<runtime>","os":"<os>","machine":"java-reactor-api-64bd9f4b94-g8wnk"}
> docker ps --filter name=kindccm --format '{{.Names}} {{.Ports}}'
kindccm-86739d9686d6 0.0.0.0:80->80/tcp, 0.0.0.0:52142->10000/tcp, [::]:52142->10000/tcp
```

`EXTERNAL-IP` es la dirección del contenedor Envoy en la red `kind`. Un Service LoadBalancer es también un Service NodePort, en un puerto elegido al azar, y por tanto un Service ClusterIP: cada tipo añade una forma de entrar.

En Linux, esa dirección es accesible desde el host. En Windows y macOS, Docker se ejecuta en una VM y no lo es: desde Windows, `curl` a `172.23.0.4` agotó el tiempo de espera. El [README](https://github.com/kubernetes-sigs/cloud-provider-kind/blob/4c9c37ce120814f597129ff708ab68bc0da4d147/README.md#L371-L385) de cloud-provider-kind describe la solución que aplica ahí, publicar el puerto del balanceador en el host. En la máquina del autor, el primer balanceador obtuvo el propio puerto 80, como muestra `docker ps`, y `curl http://localhost/` desde Windows respondió; el Gateway de más abajo obtuvo en cambio un puerto de host aleatorio. Antes de contar con cualquiera de los dos, comprueba `docker ps`, y ten en cuenta que el puerto 80 de tu máquina puede estar ya ocupado.

## Un único punto de entrada: la Gateway API

Con dos API, dos balanceadores de carga significan dos direcciones y, en una nube, dos facturas. Un enrutador HTTP puede enviar ambos nombres de host al Service adecuado desde una sola dirección. Kubernetes tiene dos API para eso. La más reciente, la [**Gateway API**](https://gateway-api.sigs.k8s.io/), reparte el trabajo en tres objetos:

| Objeto | Quién lo escribe | Qué dice |
|---|---|---|
| **GatewayClass** | la plataforma, con su controlador | qué implementación, como una StorageClass |
| **Gateway** | el operador del clúster | un punto de entrada: direcciones, puertos, protocolos, certificados TLS |
| **HTTPRoute** | el equipo de la aplicación | qué peticiones van a qué Service |

La Gateway API no viene integrada en Kubernetes: sus objetos son [recursos personalizados](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) (lección 13) que se instalan desde sus versiones publicadas. cloud-provider-kind instaló la versión 1.5.0 del canal estándar, y creó una GatewayClass y una IngressClass:

```text
> kubectl get gatewayclass,ingressclass
NAME                                                         CONTROLLER                            ACCEPTED   AGE
gatewayclass.gateway.networking.k8s.io/cloud-provider-kind   kind.sigs.k8s.io/gateway-controller   True       32m

NAME                                                           CONTROLLER                            PARAMETERS   AGE
ingressclass.networking.k8s.io/cloud-provider-kind (default)   kind.sigs.k8s.io/ingress-controller   <none>       32m
```

[`l04/gateway.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l04/gateway.yaml) declara un Gateway y una ruta con una regla por host:

```yaml
# Lección 4: un único punto de entrada para las dos API con la Gateway API, enrutado por nombre de host.
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: web
spec:
  # La clase que proporciona cloud-provider-kind; una nube o un controlador de gateway proporciona la suya
  gatewayClassName: cloud-provider-kind
  listeners:
    - name: http
      protocol: HTTP
      port: 80
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: apis
spec:
  parentRefs:
    - name: web
  rules:
    - matches:
        - headers:
            - name: Host
              value: csharp.example.test
      backendRefs:
        - name: csharp-api
          port: 80
    - matches:
        - headers:
            - name: Host
              value: java.example.test
      backendRefs:
        - name: java-reactor-api
          port: 80
```

```text
> kubectl apply -n l04 -f l04/gateway.yaml
gateway.gateway.networking.k8s.io/web created
httproute.gateway.networking.k8s.io/apis created
> kubectl wait -n l04 --for=condition=Programmed gateway/web --timeout=120s
gateway.gateway.networking.k8s.io/web condition met
> kubectl get -n l04 gateway web
NAME   CLASS                 ADDRESS      PROGRAMMED   AGE
web    cloud-provider-kind   172.23.0.5   True         1s
> kubectl get -n l04 httproute apis -o jsonpath='{range .status.parents[*].conditions[*]}{.type}={.status} {.reason}{"\n"}{end}'
Accepted=True Accepted
ResolvedRefs=True ResolvedRefs
```

Los estados son lo primero que hay que leer cuando una ruta no funciona: `Programmed` dice que el controlador del Gateway ha configurado el proxy, `Accepted` que el Gateway aceptó la ruta, y `ResolvedRefs` que existen los Services que nombra. Después, una sola dirección sirve a las dos API:

```text
> kubectl exec -n l04 client -- curl -s -H "Host: csharp.example.test" http://172.23.0.5/
{"app":"csharp-api","runtime":"<runtime>","os":"<os>","machine":"csharp-api-55b7fbb748-zw7ph"}
> kubectl exec -n l04 client -- curl -s -H "Host: java.example.test" http://172.23.0.5/
{"app":"java-reactor-api","runtime":"<runtime>","os":"<os>","machine":"java-reactor-api-64bd9f4b94-g8wnk"}
> kubectl exec -n l04 client -- curl -s -o /dev/null -w '%{http_code} %header{server}\n' -H 'Host: other.example.test' http://172.23.0.5/
404 envoy
```

`-H "Host: …"` sustituye a los registros DNS que apuntarían ambos nombres al Gateway. Un host con el que no coincide ninguna regla recibe un 404 del propio Envoy, sin llegar a ningún pod.

## Ingress

[**Ingress**](https://kubernetes.io/docs/concepts/services-networking/ingress/) es la API más antigua para el mismo trabajo, un objeto con reglas de host y de ruta. Es estable y sigue teniendo soporte, pero está congelada: las funcionalidades nuevas van a la Gateway API. Su controlador más común, ingress-nginx, [se retiró en marzo de 2026](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/), y aún te lo encontrarás en clústeres existentes. [`l04/ingress.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l04/ingress.yaml):

```yaml
# Lección 4: la API más antigua para el mismo trabajo que el Gateway. Sin ingressClassName, se aplica la IngressClass por defecto:
# en kind, la que crea cloud-provider-kind.
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: apis
spec:
  rules:
    - host: csharp.example.test
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: csharp-api
                port:
                  name: http
    - host: java.example.test
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: java-reactor-api
                port:
                  name: http
```

```text
> kubectl apply -n l04 -f l04/ingress.yaml
ingress.networking.k8s.io/apis created
> kubectl get -n l04 ingress apis -o custom-columns=NAME:.metadata.name,CLASS:.spec.ingressClassName,HOSTS:.spec.rules[*].host,ADDRESS:.status.loadBalancer.ingress[0].ip
NAME   CLASS                 HOSTS                                   ADDRESS
apis   cloud-provider-kind   csharp.example.test,java.example.test   172.23.0.6
> kubectl get -n l04 gateways,httproutes
NAME                                                     CLASS                 ADDRESS      PROGRAMMED   AGE
gateway.gateway.networking.k8s.io/kind-ingress-gateway   cloud-provider-kind   172.23.0.6   True         2s
gateway.gateway.networking.k8s.io/web                    cloud-provider-kind   172.23.0.5   True         4s

NAME                                                  HOSTNAMES                 AGE
httproute.gateway.networking.k8s.io/apis                                        4s
httproute.gateway.networking.k8s.io/apis-57edfef398   ["java.example.test"]     2s
httproute.gateway.networking.k8s.io/apis-f45dc871d2   ["csharp.example.test"]   2s
> kubectl exec -n l04 client -- curl -s -H 'Host: java.example.test' http://172.23.0.6/
{"app":"java-reactor-api","runtime":"<runtime>","os":"<os>","machine":"java-reactor-api-64bd9f4b94-xkbjc"}
```

La clase la rellenó la IngressClass por defecto. cloud-provider-kind no implementa Ingress por separado: traduce el Ingress a un Gateway propio, `kind-ingress-gateway`, y a una HTTPRoute por host. Esas rutas usan el campo `hostnames` de la ruta, la forma habitual de enrutar por host, mientras que `apis` comprobaba la cabecera `Host` en sus reglas. La traducción resume bien la relación entre las dos API, y la herramienta [ingress2gateway](https://github.com/kubernetes-sigs/ingress2gateway) hace lo mismo para las migraciones.

## ¿Cuál usar?

| Necesidad | Usa |
|---|---|
| Pods que se llaman entre sí dentro del clúster | ClusterIP, por nombre DNS |
| Un vistazo rápido desde tu máquina | `kubectl port-forward`, o un NodePort en un clúster local |
| Un servicio TCP o UDP expuesto fuera | LoadBalancer |
| Enrutamiento HTTP por host o por ruta, TLS, varios servicios tras una dirección | Gateway API (Ingress en clústeres existentes) |

```text
> kubectl delete namespace l04 --wait=true
namespace "l04" deleted
```

## Puntos clave

- Un Service da a los pods un nombre y una IP virtual estables, y los elige por etiqueta en cada momento; su `targetPort` puede nombrar el puerto de los pods.
- CoreDNS resuelve `name`, `name.namespace` y `name.namespace.svc.cluster.local`; `ndots:5` hace que los nombres externos pasen primero por la lista de búsqueda.
- Los EndpointSlices listan los pods detrás de un Service con su readiness, y kube-proxy solo envía tráfico a los que están listos; la API Endpoints está obsoleta.
- NodePort añade un puerto en cada nodo, y LoadBalancer añade una dirección externa de la infraestructura; en kind la proporciona cloud-provider-kind, y en Windows y macOS se llega a la dirección por un puerto publicado en el host.
- La Gateway API reparte el enrutamiento en GatewayClass, Gateway y HTTPRoute, e informa de cada paso en sus estados; Ingress hace el mismo trabajo en una sola API congelada.

## Ejercicios

**1.** Un Service con `clusterIP: None` es **headless**. Crea uno para la API de C# ([`l04/headless.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l04/headless.yaml)) mientras `csharp-api-unready` está en marcha, y resuelve su nombre. ¿Qué obtienes, y qué falta?

<details>
<summary>Solución</summary>

```text
> kubectl apply -n l04 -f l04/headless.yaml
service/csharp-api-headless created
> kubectl get -n l04 service csharp-api-headless
NAME                  TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
csharp-api-headless   ClusterIP   None         <none>        80/TCP    1s
> kubectl exec -n l04 client -- nslookup -type=a csharp-api-headless.l04.svc.cluster.local.
Server:		10.96.0.10
Address:	10.96.0.10:53

Name:	csharp-api-headless.l04.svc.cluster.local
Address: 10.244.0.241
Name:	csharp-api-headless.l04.svc.cluster.local
Address: 10.244.0.239
Name:	csharp-api-headless.l04.svc.cluster.local
Address: 10.244.0.240

> kubectl get -n l04 pods -l app=csharp-api -o custom-columns='NAME:.metadata.name,IP:.status.podIP,READY:.status.conditions[?(@.type=="Ready")].status' --sort-by=.metadata.name
NAME                          IP             READY
csharp-api-55b7fbb748-9rj4s   10.244.0.239   True
csharp-api-55b7fbb748-dn79k   10.244.0.241   True
csharp-api-55b7fbb748-zw7ph   10.244.0.240   True
csharp-api-unready            10.244.0.245   False
```

No hay IP virtual: el nombre se resuelve a las direcciones de los propios pods listos, y el cliente elige una. Falta la `10.244.0.245` del pod no listo. Los [Services headless](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services) sirven a los clientes que quieren ver cada instancia, como un driver de base de datos o un cliente gRPC que balancea por su cuenta, y dan a cada pod de un StatefulSet un nombre DNS estable (lección 6).

</details>

**2.** [`l04/wrong-selector.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l04/wrong-selector.yaml) tiene una errata en su selector: `app: csharp_api`. ¿Cómo falla, y cómo encontrarías la causa?

<details>
<summary>Solución</summary>

```text
> kubectl apply -n l04 -f l04/wrong-selector.yaml
service/csharp-api-typo created
> kubectl exec -n l04 client -- curl -sS -m 5 http://csharp-api-typo/
curl: (7) Failed to connect to csharp-api-typo:80 after 0 ms: Could not connect to server
command terminated with exit code 7
> kubectl get -n l04 endpointslices -l kubernetes.io/service-name=csharp-api-typo
NAME                    ADDRESSTYPE   PORTS     ENDPOINTS   AGE
csharp-api-typo-<slice>   IPv4          <unset>   <unset>     1s
```

El Service se crea sin quejarse, su nombre se resuelve, y la conexión se rechaza de inmediato: kube-proxy rechaza el tráfico hacia un Service sin endpoints. Un EndpointSlice sin endpoints es la señal. Compara el selector con las etiquetas de los pods, `kubectl get pods --show-labels`. El mismo síntoma aparece cuando ninguno de los pods que coinciden está listo.

</details>

**3.** Todo clúster tiene un Service llamado `kubernetes` en el namespace `default`. ¿Qué hay detrás? Llámalo desde el pod `client`, en `l04`.

<details>
<summary>Solución</summary>

```text
> kubectl get -n default service kubernetes
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   9h
> kubectl exec -n l04 client -- curl -sk https://kubernetes.default/version
{
  "major": "1",
  "minor": "37",
  "emulationMajor": "1",
  "emulationMinor": "37",
  "minCompatibilityMajor": "1",
  "minCompatibilityMinor": "36",
  "gitVersion": "v1.37.0",
  "gitCommit": "f54c212e3a2f75d674b717a9b29052b20b60aefc",
  "gitTreeState": "clean",
  "buildDate": "2026-08-26T10:44:25Z",
  "goVersion": "go1.26.6",
  "compiler": "gc",
  "platform": "linux/amd64"
}
```

El API server. `kubernetes.default` es un nombre de otro namespace, completado por la lista de búsqueda. `/version` se puede leer sin credenciales; `-k` se salta la comprobación del certificado, que un cliente real hace con el certificado de la CA del clúster, montado por defecto en cada pod junto con el token de su service account. Así es como los controladores y los operadores que se ejecutan en pods llegan a la API (la lección 10 les da permisos).

</details>

## Fuentes

- Documentación de Kubernetes: [Service](https://kubernetes.io/docs/concepts/services-networking/service/), [Virtual IPs and service proxies](https://kubernetes.io/docs/reference/networking/virtual-ips/), [DNS for Services and Pods](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/), [Debugging DNS resolution](https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/), [EndpointSlices](https://kubernetes.io/docs/concepts/services-networking/endpoint-slices/), [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/), [Gateway API](https://kubernetes.io/docs/concepts/services-networking/gateway/)
- Blog de Kubernetes: [obsolescencia de Endpoints](https://kubernetes.io/blog/2025/04/24/endpoints-deprecation/), [retirada de Ingress NGINX](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/)
- [Gateway API](https://gateway-api.sigs.k8s.io/), [ingress2gateway](https://github.com/kubernetes-sigs/ingress2gateway)
- kind: [LoadBalancer](https://kind.sigs.k8s.io/docs/user/loadbalancer/), [Ingress](https://kind.sigs.k8s.io/docs/user/ingress/), [mapeos de puertos adicionales](https://kind.sigs.k8s.io/docs/user/configuration/#extra-port-mappings); [README de cloud-provider-kind en v0.11.1](https://github.com/kubernetes-sigs/cloud-provider-kind/blob/4c9c37ce120814f597129ff708ab68bc0da4d147/README.md)
