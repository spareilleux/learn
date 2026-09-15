---
title: 4. Services et DNS
description: Un nom et une adresse stables devant les pods C# et Spring Boot avec les Services ClusterIP, NodePort et LoadBalancer, le DNS du cluster, les EndpointSlices et la readiness, puis un point d'entrée unique pour les deux avec la Gateway API et avec Ingress.
sidebar:
  order: 4
---

Code complet : [`code/kubernetes/l04`](https://github.com/spareilleux/learn/tree/main/code/kubernetes/l04), avec ses commandes dans [`l04/run.sh`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l04/run.sh). Comme dans les leçons 2 et 3, les commandes sont montrées telles qu'exécutées en Bash.

Chaque pod a sa propre adresse IP, et chaque pod est temporaire. Dans la leçon 3, chaque mise à jour a remplacé les trois pods C# par de nouveaux, avec de nouveaux noms et de nouvelles adresses. Un client ne peut pas en tenir la liste. Un **Service** est la partie stable : un nom, une adresse IP virtuelle qui ne change pas pendant la vie du Service, et un sélecteur de labels qui décide, à chaque instant, quels pods reçoivent le trafic.

## Mise en place

La leçon reprend les deux Deployments de la leçon 3, et ajoute un pod pour envoyer des requêtes depuis l'intérieur du cluster :

```yaml
# Leçon 4 : un pod pour envoyer des requêtes depuis l'intérieur du cluster. L'image de curl lancerait curl et se terminerait : sleep à la place.
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

[`l04/services.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l04/services.yaml) place un Service devant chaque Deployment :

```yaml
# Leçon 4 : un nom stable et une IP virtuelle devant chaque Deployment de la leçon 3.
apiVersion: v1
kind: Service
metadata:
  name: csharp-api
spec:
  # ClusterIP est la valeur par défaut : joignable depuis l'intérieur du cluster seulement
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

`port` est ce qu'appellent les clients ; `targetPort: http` est le port des pods nommé `http` dans la leçon 3, 8080. Nommer le port dans le modèle de pod permet à l'application de changer de port sans toucher au Service.

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

[`kubectl exec`](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_exec/) exécute `curl` dans le pod `client`, comme le ferait `docker exec`. Le champ `machine` est le nom d'hôte du pod, qui est son nom : le Service a choisi l'un des pods.

Le script remplace le runtime et l'OS, qui dépendent de la construction de l'image, par des marqueurs. Sur la machine de l'auteur, l'API C# indiquait `".NET 10.0.12"` et `"Ubuntu 24.04.5 LTS"`, la distribution de son image de base, et l'API Java `"Java 25.0.4+7-LTS"` et `"Linux 6.18.40.1-microsoft-standard-WSL2"` : `os.name` et `os.version` de Java décrivent le noyau, qui est le noyau WSL 2 de Docker Desktop, partagé par tous les conteneurs.

Une ClusterIP n'est joignable que depuis l'intérieur du cluster. Aucun processus n'écoute dessus : sur chaque nœud, [kube-proxy](https://kubernetes.io/docs/reference/networking/virtual-ips/) programme le noyau pour réécrire les paquets envoyés à l'adresse et au port du Service vers l'un des pods. Sur kind, kube-proxy utilise iptables ; son journal dit `"Using iptables Proxier"`. Un nouveau Service met un moment à être programmé, c'est pourquoi le script attend que le premier `curl` réponde.

## DNS

Le nom `csharp-api` a été résolu par le DNS du cluster, [CoreDNS](https://coredns.io/), qui crée un enregistrement pour chaque Service. Son nom complet inclut l'espace de noms :

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

Le kubelet écrit le `/etc/resolv.conf` de chaque pod :

- `nameserver 10.96.0.10` est la ClusterIP du Service `kube-dns` dans `kube-system`, devant les pods CoreDNS de la leçon 1.
- `search` permet à un nom court de fonctionner : `csharp-api` est d'abord essayé comme `csharp-api.l04.svc.cluster.local`. Depuis un autre espace de noms, `csharp-api.l04` suffit.
- `ndots:5` signifie qu'un nom de moins de cinq points passe par la liste de recherche avant d'être essayé tel quel. `api.github.com` en a deux, donc un pod demande d'abord `api.github.com.l04.svc.cluster.local` et deux autres noms qui n'existent pas. Un point final, comme dans le `nslookup` ci-dessus, marque un nom comme complet et saute la liste.

La page [DNS pour les Services et les Pods](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/) liste les enregistrements ; [Déboguer la résolution DNS](https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/) est la page à ouvrir quand les noms ne se résolvent pas.

## EndpointSlices : quels pods, et sont-ils prêts ?

Le sélecteur du Service est évalué par le contrôleur d'EndpointSlice, qui écrit les adresses des pods correspondants dans des [**EndpointSlices**](https://kubernetes.io/docs/concepts/services-networking/endpoint-slices/). kube-proxy lit celles-ci, pas les pods.

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

Chaque nom de slice se termine par cinq caractères aléatoires, remplacés ici par `<slice>`. L'ancien objet **Endpoints** existe toujours, et kubectl prévient : il contenait toutes les adresses d'un Service dans un seul objet, ce qui ne tenait pas l'échelle de milliers de pods, et il est [déprécié depuis 1.33](https://kubernetes.io/blog/2025/04/24/endpoints-deprecation/). Les tutoriels qui utilisent encore `kubectl get endpoints` fonctionnent, pour l'instant.

La readiness, vue à la leçon 2, compte ici. [`l04/unready.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l04/unready.yaml) ajoute un quatrième pod avec le label `app: csharp-api` et une sonde readiness qui échoue toujours :

```text
> kubectl apply -n l04 -f l04/unready.yaml
pod/csharp-api-unready created
> kubectl get -n l04 endpointslices -l kubernetes.io/service-name=csharp-api -o jsonpath='{range .items[*].endpoints[*]}{.targetRef.name} ready={.conditions.ready}{"\n"}{end}' | sort
csharp-api-55b7fbb748-9rj4s ready=true
csharp-api-55b7fbb748-dn79k ready=true
csharp-api-55b7fbb748-zw7ph ready=true
csharp-api-unready ready=false
```

Le sélecteur le reconnaît, donc la slice le liste, marqué `ready=false`. Trente requêtes montrent que kube-proxy l'ignore :

```text
> kubectl exec -n l04 client -- sh -c 'for i in $(seq 30); do curl -s http://csharp-api/; echo; done' | …
3 pods answered 30 requests; csharp-api-unready answered 0
```

(La partie après `|` compte les valeurs de `machine` ; la commande complète est dans `run.sh`.) C'est aussi un piège : un Service sélectionne **n'importe quel** pod qui porte ses labels, y compris un pod d'un autre Deployment, ou un pod lancé à la main pour déboguer. La readiness a protégé les clients cette fois.

## NodePort

Un Service **NodePort** ouvre en plus un port, de 30000 à 32767, sur chaque nœud. [`l04/nodeport.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l04/nodeport.yaml) demande 30080, que [`kind/cluster.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/kind/cluster.yaml) associe à `127.0.0.1:30080` sur votre machine avec [`extraPortMappings`](https://kind.sigs.k8s.io/docs/user/configuration/#extra-port-mappings) :

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

Le dernier `curl` s'exécute sur votre machine, pas dans le cluster : sous Windows, `curl.exe` dans PowerShell. Un Service NodePort est aussi un Service ClusterIP. C'est l'entrée la plus simple, mais les clients doivent connaître les adresses des nœuds et un port inhabituel ; le mappage de port de kind doit être déclaré à la création du cluster.

## LoadBalancer

Un Service **LoadBalancer** demande à l'infrastructure un répartiteur de charge externe : sur AKS, EKS ou GKE, le contrôleur du fournisseur cloud en crée un et écrit son adresse dans le Service. kind n'a pas de cloud, donc le cours exécute [cloud-provider-kind](https://github.com/kubernetes-sigs/cloud-provider-kind) v0.11.1, qui joue ce rôle avec un conteneur [Envoy](https://www.envoyproxy.io/) par répartiteur. [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/check.sh) le démarre comme conteneur sur le réseau Docker de kind, avec accès au socket de Docker pour créer ces conteneurs :

```bash
docker run -d --name learn-k8s-cloud-provider --network kind -v /var/run/docker.sock:/var/run/docker.sock \
  registry.k8s.io/cloud-provider-kind/cloud-controller-manager:v0.11.1@sha256:40e18b9cd9c798cce40d39ff5c099a4f16a36c268d8e1dda469d73955a35e403
```

Dans Git Bash, fixez d'abord `MSYS_NO_PATHCONV=1`, comme le fait `check.sh`, sinon Git Bash réécrit `/var/run/docker.sock` en chemin Windows ; `/var/run/docker.sock` est le chemin du socket dans la VM de Docker Desktop, pas sous Windows. Accéder au socket Docker, c'est contrôler Docker : n'exécutez qu'une image de confiance, épinglée par digest comme ici.

```yaml
# Leçon 4 : un Service LoadBalancer. Dans un cloud, le fournisseur crée un répartiteur de charge ; sur kind, c'est cloud-provider-kind.
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

`EXTERNAL-IP` est l'adresse du conteneur Envoy sur le réseau `kind`. Un Service LoadBalancer est aussi un Service NodePort, sur un port choisi au hasard, et donc un Service ClusterIP : chaque type ajoute une entrée.

Sous Linux, cette adresse est joignable depuis l'hôte. Sous Windows et macOS, Docker tourne dans une VM et elle ne l'est pas : depuis Windows, `curl` vers `172.23.0.4` a expiré. Le [README](https://github.com/kubernetes-sigs/cloud-provider-kind/blob/4c9c37ce120814f597129ff708ab68bc0da4d147/README.md#L371-L385) de cloud-provider-kind décrit le contournement qu'il y applique, en publiant le port du répartiteur sur l'hôte. Sur la machine de l'auteur, le premier répartiteur a obtenu le port 80 lui-même, comme le montre `docker ps`, et `curl http://localhost/` depuis Windows a répondu ; la Gateway plus bas a obtenu un port d'hôte aléatoire à la place. Avant de compter sur l'un ou l'autre, vérifiez `docker ps`, et notez que le port 80 de votre machine est peut-être déjà pris.

## Un point d'entrée unique : la Gateway API

Avec deux API, deux répartiteurs de charge font deux adresses et, dans un cloud, deux factures. Un routeur HTTP peut envoyer les deux noms d'hôte vers le bon Service depuis une seule adresse. Kubernetes a deux API pour cela. La plus récente, la [**Gateway API**](https://gateway-api.sigs.k8s.io/), répartit le travail en trois objets :

| Objet | Qui l'écrit | Ce qu'il dit |
|---|---|---|
| **GatewayClass** | la plateforme, avec son contrôleur | quelle implémentation, comme une StorageClass |
| **Gateway** | l'opérateur du cluster | un point d'entrée : adresses, ports, protocoles, certificats TLS |
| **HTTPRoute** | l'équipe applicative | quelles requêtes vont vers quel Service |

La Gateway API n'est pas intégrée à Kubernetes : ses objets sont des [ressources personnalisées](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) (leçon 13) installées depuis ses versions publiées. cloud-provider-kind a installé la version 1.5.0 du canal standard, et créé une GatewayClass et une IngressClass :

```text
> kubectl get gatewayclass,ingressclass
NAME                                                         CONTROLLER                            ACCEPTED   AGE
gatewayclass.gateway.networking.k8s.io/cloud-provider-kind   kind.sigs.k8s.io/gateway-controller   True       32m

NAME                                                           CONTROLLER                            PARAMETERS   AGE
ingressclass.networking.k8s.io/cloud-provider-kind (default)   kind.sigs.k8s.io/ingress-controller   <none>       32m
```

[`l04/gateway.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l04/gateway.yaml) déclare une Gateway et une route avec une règle par hôte :

```yaml
# Leçon 4 : un point d'entrée pour les deux API avec la Gateway API, routé par nom d'hôte.
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: web
spec:
  # La classe fournie par cloud-provider-kind ; un cloud ou un contrôleur de gateway fournit la sienne
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

Les états sont la première chose à lire quand une route ne marche pas : `Programmed` dit que le contrôleur de la Gateway a configuré le proxy, `Accepted` que la Gateway a pris la route, et `ResolvedRefs` que les Services qu'elle nomme existent. Ensuite, une seule adresse sert les deux API :

```text
> kubectl exec -n l04 client -- curl -s -H "Host: csharp.example.test" http://172.23.0.5/
{"app":"csharp-api","runtime":"<runtime>","os":"<os>","machine":"csharp-api-55b7fbb748-zw7ph"}
> kubectl exec -n l04 client -- curl -s -H "Host: java.example.test" http://172.23.0.5/
{"app":"java-reactor-api","runtime":"<runtime>","os":"<os>","machine":"java-reactor-api-64bd9f4b94-g8wnk"}
> kubectl exec -n l04 client -- curl -s -o /dev/null -w '%{http_code} %header{server}\n' -H 'Host: other.example.test' http://172.23.0.5/
404 envoy
```

`-H "Host: …"` remplace les enregistrements DNS qui pointeraient les deux noms vers la Gateway. Un hôte qu'aucune règle ne reconnaît reçoit un 404 d'Envoy lui-même, sans atteindre aucun pod.

## Ingress

[**Ingress**](https://kubernetes.io/docs/concepts/services-networking/ingress/) est l'API plus ancienne pour le même travail, un seul objet avec des règles d'hôte et de chemin. Elle est stable et toujours prise en charge, mais figée : les nouvelles fonctionnalités vont à la Gateway API. Son contrôleur le plus répandu, ingress-nginx, [a été retiré en mars 2026](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/), et vous le croiserez encore dans des clusters existants. [`l04/ingress.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l04/ingress.yaml) :

```yaml
# Leçon 4 : l'API plus ancienne pour le même travail que la Gateway. Sans ingressClassName, l'IngressClass par défaut s'applique :
# sur kind, celle que crée cloud-provider-kind.
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

La classe a été renseignée par l'IngressClass par défaut. cloud-provider-kind n'implémente pas Ingress à part : il traduit l'Ingress en une Gateway à lui, `kind-ingress-gateway`, et une HTTPRoute par hôte. Ces routes utilisent le champ `hostnames` de la route, la façon habituelle de router par hôte, là où `apis` reconnaissait l'en-tête `Host` dans ses règles. La traduction résume assez bien la relation entre les deux API, et l'outil [ingress2gateway](https://github.com/kubernetes-sigs/ingress2gateway) fait la même chose pour les migrations.

## Lequel choisir ?

| Besoin | Utiliser |
|---|---|
| Des pods qui s'appellent à l'intérieur du cluster | ClusterIP, par nom DNS |
| Un coup d'œil rapide depuis votre machine | `kubectl port-forward`, ou un NodePort sur un cluster local |
| Un service TCP ou UDP exposé à l'extérieur | LoadBalancer |
| Routage HTTP par hôte ou par chemin, TLS, plusieurs services derrière une adresse | Gateway API (Ingress dans les clusters existants) |

```text
> kubectl delete namespace l04 --wait=true
namespace "l04" deleted
```

## À retenir

- Un Service donne aux pods un nom et une IP virtuelle stables, et les choisit par label à chaque instant ; son `targetPort` peut nommer le port des pods.
- CoreDNS résout `name`, `name.namespace` et `name.namespace.svc.cluster.local` ; `ndots:5` fait passer les noms externes d'abord par la liste de recherche.
- Les EndpointSlices listent les pods derrière un Service avec leur readiness, et kube-proxy n'envoie le trafic qu'aux pods prêts ; l'API Endpoints est dépréciée.
- NodePort ajoute un port sur chaque nœud, et LoadBalancer une adresse externe fournie par l'infrastructure ; sur kind, c'est cloud-provider-kind qui la fournit, et sous Windows et macOS on atteint l'adresse par un port publié sur l'hôte.
- La Gateway API répartit le routage entre GatewayClass, Gateway et HTTPRoute, et rapporte chaque étape dans leurs états ; Ingress fait le même travail dans une seule API figée.

## Exercices

**1.** Un Service avec `clusterIP: None` est dit **headless**. Créez-en un pour l'API C# ([`l04/headless.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l04/headless.yaml)) pendant que `csharp-api-unready` tourne, et résolvez son nom. Qu'obtenez-vous, et que manque-t-il ?

<details>
<summary>Solution</summary>

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

Pas d'IP virtuelle : le nom se résout vers les adresses des pods prêts eux-mêmes, et c'est le client qui en choisit une. Il manque le `10.244.0.245` du pod non prêt. Les [Services headless](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services) servent les clients qui veulent voir chaque instance, comme un pilote de base de données ou un client gRPC qui répartit la charge lui-même, et donnent à chaque pod d'un StatefulSet un nom DNS stable (leçon 6).

</details>

**2.** [`l04/wrong-selector.yaml`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/l04/wrong-selector.yaml) a une faute de frappe dans son sélecteur : `app: csharp_api`. Comment échoue-t-il, et comment en trouveriez-vous la cause ?

<details>
<summary>Solution</summary>

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

Le Service est créé sans protester, son nom se résout, et la connexion est refusée aussitôt : kube-proxy rejette le trafic vers un Service sans endpoints. Une EndpointSlice sans endpoints en est le signe. Comparez le sélecteur avec les labels des pods, `kubectl get pods --show-labels`. Le même symptôme apparaît quand tous les pods correspondants sont non prêts.

</details>

**3.** Chaque cluster a un Service nommé `kubernetes` dans l'espace de noms `default`. Qu'y a-t-il derrière ? Appelez-le depuis le pod `client`, dans `l04`.

<details>
<summary>Solution</summary>

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

Le serveur d'API. `kubernetes.default` est un nom dans un autre espace de noms, complété par la liste de recherche. `/version` se lit sans identifiants ; `-k` saute la vérification du certificat, ce qu'un vrai client fait avec le certificat de l'autorité du cluster, monté par défaut dans chaque pod avec le jeton de son compte de service. C'est ainsi que les contrôleurs et les opérateurs qui tournent dans des pods joignent l'API (la leçon 10 leur donne des permissions).

</details>

## Sources

- Documentation de Kubernetes : [Service](https://kubernetes.io/docs/concepts/services-networking/service/), [IP virtuelles et proxys de service](https://kubernetes.io/docs/reference/networking/virtual-ips/), [DNS pour les Services et les Pods](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/), [Déboguer la résolution DNS](https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/), [EndpointSlices](https://kubernetes.io/docs/concepts/services-networking/endpoint-slices/), [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/), [Gateway API](https://kubernetes.io/docs/concepts/services-networking/gateway/)
- Blog de Kubernetes : [dépréciation d'Endpoints](https://kubernetes.io/blog/2025/04/24/endpoints-deprecation/), [retrait d'Ingress NGINX](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/)
- [Gateway API](https://gateway-api.sigs.k8s.io/), [ingress2gateway](https://github.com/kubernetes-sigs/ingress2gateway)
- kind : [LoadBalancer](https://kind.sigs.k8s.io/docs/user/loadbalancer/), [Ingress](https://kind.sigs.k8s.io/docs/user/ingress/), [mappages de ports supplémentaires](https://kind.sigs.k8s.io/docs/user/configuration/#extra-port-mappings) ; [README de cloud-provider-kind en v0.11.1](https://github.com/kubernetes-sigs/cloud-provider-kind/blob/4c9c37ce120814f597129ff708ab68bc0da4d147/README.md)
