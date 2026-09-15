---
title: Journal
description: Notes d'avancement datées du cours Kubernetes — versions choisies, un chargement d'image qui échouait sous Docker Desktop, un cluster réveillé avec des jetons expirés, surprises pour un développeur C# ou Java, et points à vérifier.
sidebar:
  order: 99
---

## Avancement

- [x] Leçon 1 — Architecture et cluster local
- [x] Leçon 2 — Pods
- [x] Leçon 3 — Deployments
- [x] Leçon 4 — Services et DNS
- [ ] Leçon 5 — Configuration : ConfigMaps et Secrets
- [ ] Leçon 6 — Stockage : volumes, PersistentVolumes, StatefulSets
- [ ] Leçon 7 — Jobs, CronJobs et DaemonSets
- [ ] Leçon 8 — Ordonnancement
- [ ] Leçon 9 — Mise à l'échelle
- [ ] Leçon 10 — Sécurité
- [ ] Leçon 11 — Empaquetage : Helm et Kustomize
- [ ] Leçon 12 — Observabilité et dépannage
- [ ] Leçon 13 — Étendre Kubernetes : CRD et opérateurs
- [ ] Leçon 14 — Livraison continue
- [ ] Leçon 15 — En production : AKS, EKS, GKE

## 2026-09-15 — Leçons 1 à 4

- [kubernetes.io/releases](https://kubernetes.io/releases/) indiquait 1.37 comme dernière version mineure, publiée le 2026-08-26, et `dl.k8s.io/release/stable.txt` disait toujours `v1.37.0` le 2026-09-15. L'image de nœud par défaut de kind 0.33.0 est la 1.37.0. Ses [notes de version](https://github.com/kubernetes-sigs/kind/releases/tag/v0.33.0) commencent par « defaults to Kubernetes 1.36.1 » et, quelques lignes plus bas, donnent l'image 1.37.0 comme nouvelle valeur par défaut ; l'image de [`defaults/image.go`](https://github.com/kubernetes-sigs/kind/blob/407a9675e6d9af1200b5f57f9ca52ec6cdacce74/pkg/apis/config/defaults/image.go#L20-L21) tranche. Le nœud exécute containerd 2.3.4, CoreDNS 1.14.6 et etcd 3.7.0.
- La machine : Windows 11 avec Docker Desktop 4.61.0 (Engine 29.2.1), qui utilise le magasin d'images de containerd. Le cluster utilise son propre fichier kubeconfig via `KUBECONFIG`, pour qu'aucune commande ne puisse atteindre un autre cluster. Sa création a pris 58 secondes avec l'image de nœud déjà téléchargée ; exécuter les quatre leçons avec [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/check.sh) prend environ trois minutes.
- Chaque leçon s'exécute dans son propre espace de noms, supprimé à la fin. Une première version de la leçon 1 travaillait dans `default`, et un Deployment de test que j'y avais oublié changeait la sortie de `kubectl get pods`.
- `kubectl rollout status` affiche un nombre variable de lignes `Waiting…`, et la première sonde readiness d'un pod qui démarre échoue parfois avec `connection refused` : `check.sh` compare la dernière ligne, filtre ces événements, et garde les sorties brutes qui varient pour que les leçons les citent.
- CI : kubeconform valide chaque manifeste sur les trois OS avec des schémas épinglés sur un commit ; le job kind tourne sous Ubuntu, avec kind et `kubectl` téléchargés et vérifiés contre leurs sommes SHA-256.
- Git Bash sous Windows transforme les arguments qui commencent par `/` en chemins Windows, ce qui cassait `docker exec … ls /etc/kubernetes/manifests`. `MSYS_NO_PATHCONV=1` corrige cela, et `KUBECONFIG` doit alors s'écrire `C:/…`, puisque la conversion ne s'applique plus à lui non plus.

**L'image qui refusait de se charger.** `kind load docker-image csharp-api:1.0` échouait avec `ctr: content digest sha256:e86d3659bcca4c720111606875d3c5554678fd22ce255e8c5ed8e4f571d5d6c3: not found`. kind importe les images avec `ctr images import --all-platforms`, et une image exportée du magasin d'images de containerd fait référence à des plateformes dont Docker Desktop n'a jamais téléchargé les couches. C'est [kind#3795](https://github.com/kubernetes-sigs/kind/issues/3795), toujours ouvert ; la page des [problèmes connus](https://kind.sigs.k8s.io/docs/user/known-issues/) du site de kind le décrit, mais pas encore la documentation du tag v0.33.0. [`images.sh`](https://github.com/spareilleux/learn/blob/main/code/kubernetes/images.sh) enregistre les images pour une seule plateforme, `docker save --platform linux/amd64`, et charge l'archive avec `kind load image-archive`.

**Le cluster réveillé avec des jetons expirés.** Après environ huit heures de veille de la machine, la première exécution de la leçon 3 a montré des événements `ReplicaSetCreateError Failed to create new replica set`, avec `Unauthorized` dans leurs messages. Mon explication, non vérifiée : les contrôleurs s'authentifient avec des jetons de compte de service qui expirent et sont renouvelés pendant que le cluster tourne, et les jetons ont expiré pendant la veille avant d'avoir pu être renouvelés. Les erreurs ont disparu d'elles-mêmes au bout de quelques minutes, et l'exécution suivante correspondait à `expected/`. Sur un portable, laissez un moment au cluster après une longue veille avant de croire ses erreurs.

**Surprises :**

- Un conteneur tué par sa sonde liveness montre un `lastState` `Completed`, code de sortie 0 : ASP.NET Core traite `SIGTERM` comme un arrêt normal. Un compteur de redémarrages qui grimpe sans erreur mérite un coup d'œil aux sondes.
- Avec une limite mémoire de 16 Mio, l'API C# démarrait et continuait de tourner ; un `kubectl exec` dans le conteneur, pour lire sa consommation mémoire, a fait dépasser sa limite au conteneur, et l'API a été `OOMKilled`. Les processus lancés par `exec` comptent dans la limite du conteneur. L'exercice de la leçon 2 utilise 8 Mio, qui échoue à chaque fois.
- `kubectl rollout undo` prévient qu'il ne met pas à jour l'annotation `last-applied-configuration`, ce que les exemples de sa page de documentation ne montrent pas.
- cloud-provider-kind n'implémente pas Ingress à part : il traduit chaque Ingress en une Gateway nommée `kind-ingress-gateway` et une HTTPRoute par hôte.
- Sous Windows, le premier répartiteur de charge de cloud-provider-kind a publié le port 80 sur l'hôte, donc `curl http://localhost/` atteignait l'API Java ; le répartiteur de la Gateway a obtenu un port d'hôte aléatoire. Un programme qui écoutait déjà sur le port 80 aurait fait échouer ou changer le premier ; je n'ai pas essayé.
- L'API Java indique le noyau WSL 2 comme OS (`Linux 6.18.40.1-microsoft-standard-WSL2`), et l'API C# la distribution de l'image (`Ubuntu 24.04.5 LTS`) : la même question, deux réponses différentes.
- `kubectl get endpoints` affiche `Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice`.

**GuitarAlchemist.** Le dépôt ga n'a aucun fichier de manifeste Kubernetes, chart ou répertoire `k8s` (à `3010dc68`). Il a un [chantier Kubernetes](https://github.com/GuitarAlchemist/ga/blob/3010dc68853e9228547dd2fba27ed5e5a87891da/conductor/tracks/k8s-deployment/index.md) marqué « Future / Not Started », et un [guide de déploiement](https://github.com/GuitarAlchemist/ga/blob/3010dc68853e9228547dd2fba27ed5e5a87891da/docs/DEPLOYMENT_GUIDE.md#L106-L231) avec une section Kubernetes. La leçon 2 compare les sondes de cette section avec l'image de l'API : le port 7001 contre 8080, et `/health` et `/ready` contre des points de terminaison mappés seulement en Development, ou pas du tout. La même section exécute MongoDB en Deployment avec un PersistentVolumeClaim et la stratégie `RollingUpdate` par défaut : avec un réplica, les valeurs par défaut autorisent un pod en plus et aucun indisponible, donc une mise à jour créerait un second pod MongoDB, qui a besoin du même volume, avant d'arrêter le premier. Le chantier lui-même dit que les bases de données ont besoin de StatefulSets ; la leçon 6 y reviendra.

**À vérifier :**

- La commande `PATH` Windows de la leçon 1, et l'onglet macOS.
- Ce que fait réellement le guide de déploiement de GA sur un cluster, que j'ai raisonné sans le déployer.
