---
title: Diario
description: Notas de progreso fechadas del curso de Kubernetes — versiones elegidas, una carga de imágenes que falló en Docker Desktop, un clúster que despertó con tokens caducados, sorpresas para un desarrollador de C# o Java, y puntos por verificar.
sidebar:
  order: 99
---

## Progreso

- [x] Lección 1 — Arquitectura y un clúster local
- [x] Lección 2 — Pods
- [x] Lección 3 — Deployments
- [x] Lección 4 — Services y DNS
- [ ] Lección 5 — Configuración: ConfigMaps y Secrets
- [ ] Lección 6 — Almacenamiento: volúmenes, PersistentVolumes, StatefulSets
- [ ] Lección 7 — Jobs, CronJobs y DaemonSets
- [ ] Lección 8 — Planificación
- [ ] Lección 9 — Escalado
- [ ] Lección 10 — Seguridad
- [ ] Lección 11 — Empaquetado: Helm y Kustomize
- [ ] Lección 12 — Observabilidad y diagnóstico
- [ ] Lección 13 — Extender Kubernetes: CRD y operadores
- [ ] Lección 14 — Entrega continua
- [ ] Lección 15 — En producción: AKS, EKS, GKE

## 2026-09-15 — Lecciones 1 a 4

- [kubernetes.io/releases](https://kubernetes.io/releases/) indicaba la 1.37 como última versión menor, publicada el 2026-08-26, y `dl.k8s.io/release/stable.txt` seguía diciendo `v1.37.0` el 2026-09-15. La imagen de nodo por defecto de kind 0.33.0 es la 1.37.0. Sus [notas de versión](https://github.com/kubernetes-sigs/kind/releases/tag/v0.33.0) empiezan con «defaults to Kubernetes 1.36.1» y, unas líneas más abajo, dan la imagen 1.37.0 como nuevo valor por defecto; la imagen de [`defaults/image.go`](https://github.com/kubernetes-sigs/kind/blob/407a9675e6d9af1200b5f57f9ca52ec6cdacce74/pkg/apis/config/defaults/image.go#L20-L21) zanja la cuestión. El nodo ejecuta containerd 2.3.4, CoreDNS 1.14.6 y etcd 3.7.0.
- La máquina: Windows 11 con Docker Desktop 4.61.0 (Engine 29.2.1), que usa el almacén de imágenes de containerd. El clúster usa su propio archivo kubeconfig mediante `KUBECONFIG`, para que ningún comando pudiera llegar a otro clúster. Crearlo tardó 58 segundos con la imagen de nodo ya descargada; ejecutar las cuatro lecciones con [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/check.sh) lleva unos tres minutos.
- Cada lección se ejecuta en su propio namespace, que se borra al final. Una primera versión de la lección 1 trabajaba en `default`, y un Deployment de prueba que había olvidado allí cambió la salida de `kubectl get pods`.
- `kubectl rollout status` imprime un número variable de líneas `Waiting…`, y la primera sonda de readiness de un pod que arranca a veces falla con `connection refused`: `check.sh` compara la última línea, filtra esos eventos, y conserva las salidas brutas que varían para que las lecciones las citen.
- CI: kubeconform valida todos los manifiestos en los tres sistemas operativos con esquemas fijados a un commit; el job de kind se ejecuta en Ubuntu, con kind y `kubectl` descargados y comprobados contra sus sumas SHA-256.
- Git Bash en Windows convierte los argumentos que empiezan por `/` en rutas de Windows, lo que rompía `docker exec … ls /etc/kubernetes/manifests`. `MSYS_NO_PATHCONV=1` lo arregla, y entonces `KUBECONFIG` debe escribirse `C:/…`, porque la conversión tampoco se le aplica ya.

**La imagen que no se cargaba.** `kind load docker-image csharp-api:1.0` falló con `ctr: content digest sha256:e86d3659bcca4c720111606875d3c5554678fd22ce255e8c5ed8e4f571d5d6c3: not found`. kind importa las imágenes con `ctr images import --all-platforms`, y una imagen exportada desde el almacén de imágenes de containerd hace referencia a plataformas cuyas capas Docker Desktop nunca descargó. Es [kind#3795](https://github.com/kubernetes-sigs/kind/issues/3795), todavía abierta; la página de [problemas conocidos](https://kind.sigs.k8s.io/docs/user/known-issues/) del sitio de kind la describe, pero la documentación de la etiqueta v0.33.0 aún no. [`images.sh`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/images.sh) guarda las imágenes para una sola plataforma, `docker save --platform linux/amd64`, y carga el archivo con `kind load image-archive`.

**El clúster que despertó con tokens caducados.** Después de que la máquina estuviera suspendida unas ocho horas, la primera ejecución de la lección 3 mostró eventos `ReplicaSetCreateError Failed to create new replica set`, con `Unauthorized` en sus mensajes. Mi explicación, sin verificar: los controladores se autentican con tokens de service account que caducan y se renuevan mientras el clúster funciona, y los tokens caducaron durante la suspensión antes de poder renovarse. Los errores desaparecieron solos al cabo de unos minutos, y la ejecución siguiente coincidió con `expected/`. En un portátil, dale un momento a un clúster tras una suspensión larga antes de creerte sus errores.

**Sorpresas:**

- Un contenedor matado por su sonda de liveness muestra el `lastState` `Completed`, código de salida 0: ASP.NET Core trata `SIGTERM` como un apagado normal. Un contador de reinicios que no para de crecer sin ningún error merece una mirada a las sondas.
- Con un límite de memoria de 16 MiB, la API de C# arrancó y siguió funcionando; un `kubectl exec` en el contenedor, para leer su uso de memoria, llevó el contenedor por encima de su límite, y la API acabó `OOMKilled`. Los procesos lanzados con `exec` cuentan para el límite del contenedor. El ejercicio de la lección 2 usa 8 MiB, que falla siempre.
- `kubectl rollout undo` avisa de que no actualiza la anotación `last-applied-configuration`, algo que los ejemplos de su página de documentación no muestran.
- cloud-provider-kind no implementa Ingress por separado: traduce cada Ingress a un Gateway llamado `kind-ingress-gateway` y a una HTTPRoute por host.
- En Windows, el primer balanceador de cloud-provider-kind publicó el puerto 80 en el host, así que `curl http://localhost/` llegó a la API de Java; el balanceador del Gateway obtuvo un puerto de host aleatorio. Un programa que ya escuchara en el puerto 80 habría hecho fallar o cambiar el primero; no lo probé.
- La API de Java indica el kernel WSL 2 como su sistema operativo (`Linux 6.18.40.1-microsoft-standard-WSL2`), y la API de C# la distribución de la imagen (`Ubuntu 24.04.5 LTS`): la misma pregunta, dos respuestas distintas.
- `kubectl get endpoints` imprime `Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice`.

**GuitarAlchemist.** El repositorio ga no tiene archivos de manifiesto de Kubernetes, ni chart, ni directorio `k8s` (en `3010dc68`). Tiene una [línea de trabajo de Kubernetes](https://github.com/GuitarAlchemist/ga/blob/3010dc68853e9228547dd2fba27ed5e5a87891da/conductor/tracks/k8s-deployment/index.md) marcada «Future / Not Started», y una [guía de despliegue](https://github.com/GuitarAlchemist/ga/blob/3010dc68853e9228547dd2fba27ed5e5a87891da/docs/DEPLOYMENT_GUIDE.md#L106-L231) con una sección de Kubernetes. La lección 2 compara las sondas de esa sección con la imagen de la API: el puerto 7001 frente al 8080, y `/health` y `/ready` frente a endpoints mapeados solo en Development, o en ningún sitio. La misma sección ejecuta MongoDB como un Deployment con un PersistentVolumeClaim y la estrategia `RollingUpdate` por defecto: con una réplica, los valores por defecto permiten un pod de más y ninguno no disponible, así que una actualización crearía un segundo pod de MongoDB, que necesita el mismo volumen, antes de detener el primero. La propia línea de trabajo dice que las bases de datos necesitan StatefulSets; la lección 6 volverá sobre ello.

**Por verificar:**

- El comando del `PATH` de Windows de la lección 1, y la pestaña de macOS.
- Lo que hace realmente la guía de despliegue de GA en un clúster, sobre lo que razoné sin desplegarla.

## 2026-09-16 — Las primeras ejecuciones de la CI

El workflow solo pudo publicarse cuando el token de `gh` tuvo el scope `workflow`. Hicieron falta [tres ejecuciones](https://github.com/spareilleux/learn/actions/workflows/kubernetes-examples.yml) para ponerlo en verde, y ningún fallo venía de las lecciones en sí:

- **Una herramienta de sumas de verificación por sistema.** Git Bash en el runner de Windows tiene `sha256sum` pero no `shasum`. El runner de macOS tiene las dos, y su `sha256sum` es el de BSD, que rechazó una lista de sumas leída por la entrada estándar. El paso escribe ahora la línea esperada en un archivo y usa `shasum -a 256` en macOS y `sha256sum` en los demás.
- **El DNS del runner dentro del pod.** Todos los pasos de las lecciones 1 a 4 coincidieron con `expected/` salvo el `/etc/resolv.conf` del pod, cuya línea `search` terminaba con el dominio `internal.cloudapp.net` del propio runner: el kubelet añade los dominios de búsqueda del nodo después de los tres del clúster. En mi máquina el nodo no hereda ninguno. `normalize` quita ahora lo que sigue a `cluster.local` en esa línea.
- **Un orden de respuestas.** `nslookup` pasó en la primera ejecución y falló en la segunda con las mismas líneas; solo se movieron sus líneas vacías. Mi explicación, sin verificar: envía juntas las consultas A y AAAA e imprime cada respuesta según llega. La comparación ignora ahora las líneas vacías; la lección 4 cita la salida sin cambios.
