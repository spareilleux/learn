---
title: 2. Pods
description: Le cycle de vie et les conditions d'un pod, les sondes liveness, readiness et startup sur les API C# et Spring Boot, les conteneurs init et les sidecars natifs, les requests, les limits et les classes QoS, chacun montré en échec volontaire.
sidebar:
  order: 2
---

Code complet : [`code/kubernetes/l02`](https://github.com/spareilleux/learn/tree/main/code/kubernetes/l02), avec ses commandes dans [`l02/run.sh`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l02/run.sh). Chaque sortie ci-dessous vient d'une exécution de ce script ; [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/check.sh) les compare avec [`expected`](https://github.com/spareilleux/learn/tree/main/code/kubernetes/expected).

Les commandes sont montrées telles que le script les exécute, en Bash. Sous Windows, exécutez-les dans Git Bash ou WSL, ou dans PowerShell sans les filtres `| grep`, `| sort` et `| head`, qui ne font que raccourcir la sortie.

Un **pod** est la plus petite chose que Kubernetes ordonnance : un ou plusieurs conteneurs qui partagent une adresse réseau, peuvent partager des volumes, et sont placés ensemble sur le même nœud. La plupart des pods contiennent un seul conteneur, et on crée rarement des pods à la main ; un Deployment le fait pour vous (leçon 3). Mais chaque réglage qui décide si votre application démarre, reçoit du trafic et survit se trouve dans le modèle de pod : cette leçon regarde donc d'abord les pods seuls.

## Les images

Cette leçon et les deux suivantes exécutent les deux API construites dans la [leçon 4 du cours Conteneurs WSL](../../wsl-containers/04-build-an-image/) : une API minimale ASP.NET Core et une API Spring Boot WebFlux, qui répondent toutes deux à `GET /` sur le port 8080 par un petit document JSON. [`images.sh`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/images.sh) les construit à partir des Containerfiles de ce cours, récupère deux images auxiliaires, et charge le tout dans le nœud kind. Sous Windows, lancez-le depuis Git Bash ou WSL.

```bash
bash images.sh
```

Les manifestes utilisent `imagePullPolicy: Never` : le nœud doit déjà avoir l'image, et Kubernetes n'essaie jamais de registre. Avec un registre, vous pousseriez les images et garderiez la valeur par défaut, `IfNotPresent` pour une image étiquetée.

:::caution[kind load docker-image et Docker Desktop]
La commande habituelle, `kind load docker-image csharp-api:1.0`, a échoué sur la machine de l'auteur avec `ctr: content digest sha256:e86d3659…: not found`. kind importe l'image dans le nœud avec `ctr images import --all-platforms`, et une image enregistrée depuis le magasin d'images containerd de Docker Desktop liste des plateformes dont les couches n'ont jamais été téléchargées. C'est le [ticket kind #3795](https://github.com/kubernetes-sigs/kind/issues/3795), listé dans les [problèmes connus](https://kind.sigs.k8s.io/docs/user/known-issues/) de kind. `images.sh` utilise le contournement : `docker save --platform linux/amd64` dans une archive, puis `kind load image-archive`.
:::

## Un pod et son cycle de vie

[`l02/pod.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l02/pod.yaml) exécute l'API C# avec des ressources et deux sondes, expliquées dans les sections suivantes :

```yaml
# Leçon 2 : un pod qui exécute l'API C# construite dans le cours Conteneurs WSL, avec requests, limits et deux sondes.
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
      # kind charge l'image dans le nœud : ne jamais essayer un registre
      imagePullPolicy: Never
      ports:
        - containerPort: 8080
      resources:
        requests:
          cpu: 100m
          memory: 64Mi
        limits:
          memory: 256Mi
      # N'envoyer du trafic qu'une fois que GET / répond
      readinessProbe:
        httpGet:
          path: /
          port: 8080
        periodSeconds: 5
      # Redémarrer le conteneur si GET / ne répond plus
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

`STATUS` résume deux choses distinctes. La [**phase**](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-phase) du pod vaut `Pending`, `Running`, `Succeeded`, `Failed` ou `Unknown`. Les **conditions** du pod disent quelles étapes il a franchies, et `kubectl wait` attend l'une d'elles :

```text
> kubectl get pod -n l02 csharp-api -o jsonpath='{range .status.conditions[*]}{.type}={.status}{"\n"}{end}'
PodReadyToStartContainers=True
Initialized=True
Ready=True
ContainersReady=True
PodScheduled=True
```

Dans l'ordre où elles arrivent : l'ordonnanceur a choisi un nœud (`PodScheduled`), le kubelet a créé le bac à sable et le réseau du pod (`PodReadyToStartContainers`), les conteneurs init ont terminé (`Initialized`), chaque conteneur a passé sa sonde readiness (`ContainersReady`), et le pod est donc `Ready`. Seul un pod `Ready` reçoit du trafic d'un Service.

La sortie standard du conteneur est son journal, comme avec `docker logs`. ASP.NET Core écrit ses lignes de démarrage :

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

Et les événements racontent ce qu'a fait le kubelet, c'est le premier endroit où regarder quand un pod ne démarre pas :

```text
> kubectl get events -n l02 --field-selector involvedObject.name=csharp-api,type=Normal -o custom-columns=TYPE:.type,REASON:.reason,MESSAGE:.message --sort-by=.metadata.creationTimestamp
TYPE     REASON      MESSAGE
Normal   Scheduled   Successfully assigned l02/csharp-api to learn-k8s-control-plane
Normal   Pulled      Container image "csharp-api:1.0" already present on machine and can be accessed by the pod
Normal   Created     Container created
Normal   Started     Container started
```

Lors de certaines exécutions, un `Warning` apparaît aussi, avec l'adresse IP du pod : `Readiness probe failed: Get "http://10.244.0.44:8080/": dial tcp 10.244.0.44:8080: connect: connection refused`. C'est pour cette raison que la commande ci-dessus ne garde que les événements `Normal`. La première sonde est partie avant que Kestrel écoute. C'est sans conséquence, et cela montre pourquoi la readiness compte : le processus tourne, mais l'application ne sert pas encore.

## Trois sondes

Une **sonde** (*probe*) est une vérification que le kubelet exécute contre un conteneur, en HTTP, en TCP, en gRPC ou par une commande. [Kubernetes en a trois sortes](https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/), et elles répondent à trois questions différentes :

| Sonde | Question | En cas d'échec | ASP.NET Core | Spring Boot |
|---|---|---|---|---|
| **liveness** | Le processus est-il bloqué sans espoir ? | le kubelet redémarre le conteneur | un health check étiqueté `live` avec [`MapHealthChecks`](https://learn.microsoft.com/aspnet/core/host-and-deploy/health-checks) | `/actuator/health/liveness` |
| **readiness** | Peut-il prendre des requêtes maintenant ? | le pod est retiré des Services, rien ne redémarre | un check étiqueté `ready`, dépendances comprises | `/actuator/health/readiness` |
| **startup** | A-t-il fini de démarrer ? | liveness et readiness attendent ; après `failureThreshold` échecs, le conteneur est redémarré | | |

L'Actuator de Spring Boot [expose les deux groupes](https://docs.spring.io/spring-boot/reference/actuator/endpoints.html#actuator.endpoints.kubernetes-probes) quand il tourne sur Kubernetes. ASP.NET Core vous laisse faire la séparation. Les deux API du cours n'ont ni l'un ni l'autre, donc les sondes appellent ici `GET /`. Cela suffit pour voir le mécanisme, mais un vrai point de terminaison liveness ne devrait pas vérifier une base de données : si la base tombe, redémarrer tous les pods ne la fait pas revenir.

### Une sonde liveness qui échoue

[`l02/liveness-fail.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l02/liveness-fail.yaml) sonde `/healthz`, un chemin que l'API n'a pas, toutes les 2 secondes, et abandonne après 2 échecs :

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

Une sonde HTTP réussit sur tout statut de 200 à 399 ; le 404 est un échec, avec le message construit dans le [`http.go`](https://github.com/kubernetes/kubernetes/blob/f54c212e3a2f75d674b717a9b29052b20b60aefc/pkg/probe/http/http.go#L147) du kubelet et enregistré comme événement par [`prober.go`](https://github.com/kubernetes/kubernetes/blob/f54c212e3a2f75d674b717a9b29052b20b60aefc/pkg/kubelet/prober/prober.go#L124). L'état précédent du conteneur est moins évident :

```text
> kubectl get pod -n l02 liveness-fail -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason} {.status.containerStatuses[0].lastState.terminated.exitCode}{"\n"}'
Completed 0
```

Le kubelet arrête un conteneur avec `SIGTERM`, et ASP.NET Core le traite comme un arrêt propre : le conteneur tué est donc sorti avec le code 0. Un compteur de redémarrages qui ne cesse de grimper avec la raison `Completed` est souvent une sonde liveness, pas un plantage. Après quelques redémarrages, le kubelet attend de plus en plus longtemps avant le suivant : sur le cluster de l'auteur, `STATUS` affichait `CrashLoopBackOff` dès le deuxième redémarrage, 16 secondes après la création du pod.

### Une sonde readiness qui échoue

La même erreur sur la sonde readiness, dans [`l02/readiness-fail.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l02/readiness-fail.yaml), donne un autre résultat :

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

`Running`, zéro redémarrage, et jamais `Ready`. Rien n'est cassé du point de vue du kubelet ; le pod ne reçoit simplement jamais de trafic. La leçon 4 montre l'autre côté : un tel pod est listé dans l'EndpointSlice de son Service, marqué non prêt.

### Une sonde startup pour la JVM

L'API Spring Boot a besoin de quelques secondes pour démarrer. Une sonde liveness avec un court délai la tuerait avant qu'elle réponde ; un long `initialDelaySeconds` retarderait la détection des vraies pannes pendant toute la vie du pod. Une sonde startup règle les deux. [`l02/startup.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l02/startup.yaml) vérifie toutes les secondes, jusqu'à 60 fois, et la sonde liveness ne commence qu'après le premier succès :

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

Lors de cette exécution, le conteneur a démarré à 13:18:36 et le pod était prêt à 13:18:38 : deux secondes, avec une sonde startup en échec qui n'a rien coûté. Sur un nœud chargé, la même JVM peut mettre dix fois plus longtemps, d'où un budget de 60 secondes et non de 3. Les durées changent d'une exécution à l'autre, donc `check.sh` enregistre cette sortie sans la comparer.

## Conteneurs init et sidecars

Les **conteneurs init** s'exécutent l'un après l'autre, chacun jusqu'au bout, avant que les conteneurs normaux démarrent : une migration, un fichier de configuration, l'attente d'une dépendance. Depuis Kubernetes 1.33, où la fonctionnalité est devenue stable, un conteneur init avec `restartPolicy: Always` est plutôt un [**sidecar natif**](https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/) : il démarre dans la séquence init, mais continue de tourner à côté de l'application, et s'arrête après elle. Les expéditeurs de logs, les proxys et les renouveleurs de certificats sont des sidecars typiques.

[`l02/init-sidecar.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l02/init-sidecar.yaml) a les deux. `setup` écrit un fichier de configuration dans un volume `emptyDir` partagé, `log-shipper` suit un fichier de log, et `app` lit la configuration et ajoute une ligne au log chaque seconde :

```yaml
spec:
  # sh tourne en PID 1 et ignore SIGTERM : sans ceci, la suppression du pod attend les 30 s par défaut avant SIGKILL
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
      # Suit le fichier qu'écrit l'application ; un vrai sidecar l'enverrait quelque part
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

`READY 2/2` compte le sidecar et l'application, pas `setup`, qui a terminé. `-c` choisit un conteneur dans un pod à plusieurs conteneurs. Le sidecar a vu la première ligne parce qu'il tournait déjà quand l'application l'a écrite : cet ordre de démarrage est ce que garantit le sidecar natif, et ce que ne garantit pas un second conteneur ordinaire dans `containers`.

## Requests, limits et QoS

Chaque conteneur peut déclarer, pour le CPU et la mémoire :

- une **request** : ce que l'ordonnanceur lui réserve sur un nœud. Un pod n'est placé que là où la somme des requests tient.
- une **limit** : le maximum qu'il peut utiliser. Au-delà de sa limite CPU, un conteneur est bridé ; au-delà de sa limite mémoire, le noyau le tue.

Le CPU se compte en cœurs (`100m` est un dixième de cœur), la mémoire en octets (`64Mi`). Le premier pod demandait `100m` et `64Mi` avec une limite mémoire de `256Mi`, et aucune limite CPU : il peut utiliser le CPU inoccupé du nœud, mais pas plus de mémoire que prévu. C'est un choix courant pour les API web ; la [page sur la gestion des ressources](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/) décrit les options.

Les requests et les limits décident de la [**classe QoS**](https://kubernetes.io/docs/concepts/workloads/pods/pod-qos/) du pod, qui décide quels pods le kubelet expulse en premier quand un nœud manque de mémoire. [`l02/qos.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l02/qos.yaml) crée un pod de chaque classe :

```text
> kubectl get pods -n l02 guaranteed burstable besteffort -o custom-columns=NAME:.metadata.name,QOS:.status.qosClass
NAME         QOS
guaranteed   Guaranteed
burstable    Burstable
besteffort   BestEffort
```

La règle, telle qu'écrite dans [`qos.go`](https://github.com/kubernetes/kubernetes/blob/f54c212e3a2f75d674b717a9b29052b20b60aefc/pkg/apis/core/v1/helper/qos/qos.go#L39-L42) : un pod est `BestEffort` si aucun conteneur n'a de request ni de limit CPU ou mémoire, `Guaranteed` si chaque conteneur a des requests CPU et mémoire égales à ses limits, et `Burstable` sinon. Les pods `BestEffort` partent en premier sous pression mémoire, les `Guaranteed` en dernier.

Les deux runtimes lisent la limite. .NET dimensionne son tas géré par le ramasse-miettes d'après la limite mémoire du conteneur ([`GCHeapHardLimit`](https://learn.microsoft.com/dotnet/core/runtime-config/garbage-collector#heap-hard-limit) vaut 75 % de celle-ci par défaut), et la JVM d'après `-XX:MaxRAMPercentage`, 25 % de la limite par défaut. Une limite copiée d'un autre service peut affamer l'un et gaspiller de la mémoire pour l'autre.

Depuis Kubernetes 1.35, les requests et les limits peuvent aussi être [modifiées sur un pod en cours d'exécution](https://kubernetes.io/docs/tasks/configure-pod-container/resize-container-resources/) sans le redémarrer ; la leçon 9, sur la mise à l'échelle, y revient.

## Un cas pratique : le guide de déploiement de GA

[Guitar Alchemist](https://github.com/GuitarAlchemist/ga) tourne sur Docker Compose et .NET Aspire, et un [chantier Kubernetes](https://github.com/GuitarAlchemist/ga/blob/3010dc68853e9228547dd2fba27ed5e5a87891da/conductor/tracks/k8s-deployment/index.md) est prévu, pas commencé. Son guide de déploiement contient déjà un [Deployment pour l'API](https://github.com/GuitarAlchemist/ga/blob/3010dc68853e9228547dd2fba27ed5e5a87891da/docs/DEPLOYMENT_GUIDE.md#L152-L195), avec une sonde liveness sur `/health` et une sonde readiness sur `/ready`, toutes deux sur le port 7001. Comparé au code du même commit :

- le [Dockerfile de l'API](https://github.com/GuitarAlchemist/ga/blob/3010dc68853e9228547dd2fba27ed5e5a87891da/Apps/ga-server/GaApi/Dockerfile#L31-L33) expose le port 8080, la valeur par défaut des images `aspnet` de .NET, et fixe `ASPNETCORE_ENVIRONMENT=Production` ;
- les service defaults d'Aspire ne mappent `/health` et `/alive` [que dans l'environnement Development](https://github.com/GuitarAlchemist/ga/blob/3010dc68853e9228547dd2fba27ed5e5a87891da/AllProjects.ServiceDefaults/Extensions.cs#L95-L112), un choix du modèle pour des raisons de sécurité ;
- aucun point de terminaison `/ready` n'existe ; le contrôleur de santé propre à l'API répond sous `/api/Health`.

Telles qu'elles sont écrites, les sondes échoueraient contre l'image : rien n'écoute sur 7001, et même sur 8080 les chemins renvoient 404. D'après cette leçon, le résultat attendu est un conteneur redémarré par sa sonde liveness et un pod jamais `Ready`, mais je n'ai pas déployé GA pour le vérifier (*à vérifier*). Le guide ne déclare pas non plus de ressources, donc le pod serait `BestEffort`. La correction concerne les deux côtés : mapper un point de terminaison de santé `live` et un `ready` en Production, sans les détails dont parle l'avertissement du modèle, et pointer les sondes dessus sur 8080.

## À retenir

- Un pod est un ou plusieurs conteneurs placés ensemble ; sa phase dit où il en est de sa vie, ses conditions disent quelles étapes il a franchies, et `Ready` décide s'il reçoit du trafic.
- `kubectl logs`, `kubectl get events` et le `lastState` du conteneur répondent à la plupart des questions « pourquoi ne démarre-t-il pas ».
- La liveness redémarre un conteneur bloqué, la readiness sort un pod du trafic sans le redémarrer, et la startup protège les démarrages lents sans affaiblir les deux autres.
- Un redémarrage par liveness d'une application ASP.NET Core apparaît comme `Completed`, code de sortie 0 : l'application s'est arrêtée proprement quand on le lui a demandé.
- Les conteneurs init s'exécutent jusqu'au bout, dans l'ordre ; un sidecar natif (`restartPolicy: Always`) démarre avant l'application et tourne à côté d'elle.
- Les requests placent les pods, les limits les plafonnent, et ensemble elles fixent la classe QoS qui décide de l'ordre d'expulsion.

## Exercices

**1.** `l02/pod.yaml` est `Burstable`. Écrivez une variante `Guaranteed`, appliquez-la, et vérifiez sa classe.

<details>
<summary>Solution</summary>

Les requests doivent égaler les limits pour le CPU comme pour la mémoire, dans chaque conteneur : [`l02/pod-guaranteed.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l02/pod-guaranteed.yaml).

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

Le prix est la limite CPU : sous charge, ce pod est bridé à un dixième de cœur même si le nœud est inoccupé.

</details>

**2.** Donnez à l'API C# une limite mémoire de `8Mi` ([`l02/oom.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l02/oom.yaml)). Que se passe-t-il, et où le voyez-vous ?

<details>
<summary>Solution</summary>

```text
> kubectl apply -n l02 -f l02/oom.yaml
pod/oom created
> kubectl get pod -n l02 oom
NAME   READY   STATUS    RESTARTS     AGE
oom    1/1     Running   1 (2s ago)   2s
> kubectl get pod -n l02 oom -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason} {.status.containerStatuses[0].lastState.terminated.exitCode}{"\n"}'
OOMKilled 137
```

Le noyau tue le processus dès qu'il dépasse la limite : raison `OOMKilled`, code de sortie 137 (128 + 9, `SIGKILL`). Le kubelet le redémarre, et quelques secondes plus tard `STATUS` affiche `OOMKilled`. `STATUS` change d'une seconde à l'autre, donc c'est `lastState` qu'il faut lire.

En préparant cet exercice, une limite de `16Mi` a d'abord semblé suffire : l'API démarrait et continuait de tourner. Puis un `kubectl exec` dans ce conteneur, pour lire sa consommation mémoire, lui a fait dépasser la limite, et l'API a été `OOMKilled`. Un processus lancé avec `kubectl exec` s'exécute dans le cgroup du conteneur et compte dans sa limite.

</details>

**3.** À quoi ressemble un pod dont le conteneur init échoue ? Essayez [`l02/init-fail.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l02/init-fail.yaml), dont le conteneur `setup` affiche une erreur et sort avec le code 1.

<details>
<summary>Solution</summary>

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

`Init:Error` signifie qu'un conteneur init est sorti en erreur ; pendant qu'il s'exécute à nouveau, `STATUS` affiche `Init:0/1`, zéro conteneur init terminé sur un. Avec la `restartPolicy: Always` par défaut du pod, le kubelet relance `setup` avec un délai croissant, et `app` attend en `PodInitializing` jusqu'à ce qu'il réussisse. Le journal du conteneur init lui-même donne la raison.

</details>

## Sources

- Documentation de Kubernetes : [Pods](https://kubernetes.io/docs/concepts/workloads/pods/), [Cycle de vie d'un pod](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/), [Sondes liveness, readiness et startup](https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/) et [comment les configurer](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/), [Conteneurs init](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/), [Conteneurs sidecar](https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/), [Gestion des ressources des pods et des conteneurs](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/), [Classes de qualité de service des pods](https://kubernetes.io/docs/concepts/workloads/pods/pod-qos/)
- Code source en v1.37.0 : [`pkg/probe/http/http.go`](https://github.com/kubernetes/kubernetes/blob/f54c212e3a2f75d674b717a9b29052b20b60aefc/pkg/probe/http/http.go#L147), [`pkg/kubelet/prober/prober.go`](https://github.com/kubernetes/kubernetes/blob/f54c212e3a2f75d674b717a9b29052b20b60aefc/pkg/kubelet/prober/prober.go#L124), [`qos.go`](https://github.com/kubernetes/kubernetes/blob/f54c212e3a2f75d674b717a9b29052b20b60aefc/pkg/apis/core/v1/helper/qos/qos.go#L39-L42)
- [Health checks dans ASP.NET Core](https://learn.microsoft.com/aspnet/core/host-and-deploy/health-checks), [Sondes Kubernetes de Spring Boot](https://docs.spring.io/spring-boot/reference/actuator/endpoints.html#actuator.endpoints.kubernetes-probes), [Configuration du ramasse-miettes .NET](https://learn.microsoft.com/dotnet/core/runtime-config/garbage-collector)
- kind : [problèmes connus](https://kind.sigs.k8s.io/docs/user/known-issues/), [ticket #3795](https://github.com/kubernetes-sigs/kind/issues/3795)
