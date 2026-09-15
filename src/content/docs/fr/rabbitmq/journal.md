---
title: Journal
description: Notes d'avancement datées du cours RabbitMQ — versions choisies, le broker qui plantait avant d'avoir démarré, surprises pour un développeur C# ou Java, erreurs, et points à vérifier.
sidebar:
  order: 99
---

## Avancement

- [x] Leçon 1 — Premiers pas
- [x] Leçon 2 — Topologie : exchanges, bindings et files
- [x] Leçon 3 — Clients en C#, en Java et avec Spring AMQP
- [x] Leçon 4 — Fiabilité : acquittements, prefetch, confirmations
- [ ] Leçon 5 — Types de files : classiques, quorum et streams
- [ ] Leçon 6 — Erreurs : dead lettering, TTL, nouvelles tentatives et messages différés
- [ ] Leçon 7 — Patterns : work queues, publish/subscribe, RPC, consommateurs concurrents, outbox
- [ ] Leçon 8 — Clustering et haute disponibilité
- [ ] Leçon 9 — Sécurité : virtual hosts, utilisateurs, permissions, TLS
- [ ] Leçon 10 — Observabilité : Prometheus, Grafana, alarmes, contrôle de flux
- [ ] Leçon 11 — Performance et dimensionnement
- [ ] Leçon 12 — Autres protocoles : streams, MQTT, AMQP 1.0 ; RabbitMQ et Kafka
- [ ] Leçon 13 — Exploitation : mises à jour, définitions, Kubernetes

## 2026-09-15 — Leçons 1 à 4

- La page [release information](https://www.rabbitmq.com/release-information) indiquait 4.3.5 comme dernière version au 2026-09-15, et le tag `rabbitmq:4.3.5-management` de Docker Hub avait été construit le 2026-09-10. L'image exécute Erlang/OTP 27.3.4.17. Les clients sont les derniers sur NuGet et Maven Central ce jour-là : RabbitMQ.Client 7.2.2 et amqp-client 5.35.0. Spring Boot 4.1.1 gère amqp-client 5.30.0 et Spring AMQP 4.1.1 ; le POM parent du cours monte le client à 5.35.0 avec la propriété `rabbit-amqp-client.version`, pour que les deux programmes Java utilisent le même client.
- Le code est un projet C# avec une commande par exemple ([`csharp`](https://github.com/spareilleux/learn/tree/main/code/rabbitmq/csharp)) et un build Maven à deux modules, un JAR shadé pour le client Java et un JAR Spring Boot ([`java`](https://github.com/spareilleux/learn/tree/main/code/rabbitmq/java)). [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/rabbitmq/check.sh) exécute 36 étapes contre un broker neuf, dont des commandes `rabbitmqctl` et `rabbitmq-diagnostics` et un redémarrage du broker, et compare chaque sortie avec `expected/`. Je l'ai exécuté deux fois de suite sur des conteneurs neufs sous Windows, avec les mêmes résultats.
- CI : les runners Windows et macOS hébergés par GitHub n'ont pas Docker, donc le workflow y compile les clients et exécute tout contre un conteneur de service RabbitMQ sous Linux seulement.
- Pour obtenir une sortie déterministe d'un broker, les programmes évitent de dépendre du temps : ils lisent les files avec `basic.get` après avoir publié, arrêtent les consommateurs après un nombre connu de messages, et n'affichent aucun consumer tag généré par le serveur. Deux exemples attendent encore un peu : 300 ms après un plantage simulé, pour que la fenêtre de prefetch soit remplie, et 500 ms pour vérifier qu'un consommateur ne reçoit pas de quatrième message.
- Aucun des dépôts GuitarAlchemist n'utilise RabbitMQ dans son code (ga à `dc2e74cb`, ix à `ed5e998`, tars à `54487423`). La seule configuration que j'ai trouvée est un [fichier Docker Compose généré dans tars](https://github.com/GuitarAlchemist/tars/blob/54487423b5b6e8d4849571e1b3d710f4e99d6f60/.tars/projects/create_a_distributed_microservices_architecture_with_api_gateway/docker-compose.yml#L44-L62) : il exécute `rabbitmq:3.12-management`, une série qui ne figure plus dans la liste des versions prises en charge, avec un volume de données mais sans `hostname`, si bien qu'un conteneur recréé démarrerait sous un nouveau nom de nœud et ne trouverait pas ses données, et il code en dur les identifiants `admin`/`admin123`. Son health check, `rabbitmq-diagnostics ping` en root, est le motif qui a fait planter mon broker, même si un intervalle de 30 secondes rend la course peu probable.

**Le broker qui s'arrêtait avant d'avoir démarré.** Mon premier `broker.sh` attendait le broker en exécutant `docker exec rabbitmq rabbitmq-diagnostics check_port_connectivity` chaque seconde. Le conteneur mourait en moins de deux secondes avec `Error when reading /var/lib/rabbitmq/.erlang.cookie: eacces`. La CLI, exécutée en root, avait créé le cookie Erlang avant le nœud ; le nœud, exécuté sous `rabbitmq`, ne pouvait pas le lire. Je l'ai reproduit avec un seul `docker exec` juste après `docker run`, et `ls -la` montrait le fichier appartenant à `root`. Lancer le conteneur avec `--user rabbitmq` l'a corrigé, avec un health check chaque seconde. C'est [docker-library/rabbitmq#695](https://github.com/docker-library/rabbitmq/issues/695), fermée sans commentaire en 2024 ; la documentation de l'image n'en parle pas. La leçon 1 raconte l'histoire.

**Surprises :**

- RabbitMQ 4.3.5 refuse une file déclarée avec `durable: false` sauf si elle est exclusive : `541 INTERNAL_ERROR - Feature transient_nonexcl_queues is deprecated`, une erreur de connexion. Tous les anciens tutoriels qui déclarent `durable: false` échouent sur cette version.
- Ce texte d'erreur se termine par `To...` : les textes de réponse AMQP sont des short strings de 255 octets au plus, et l'avertissement de dépréciation est plus long.
- Un message non routable publié sans `mandatory` est confirmé. Une confirmation de publication dit que le broker en a fini avec le message, pas qu'une file l'a.
- Avec le suivi des confirmations, RabbitMQ.Client 7 lève `PublishReturnException` pour un message renvoyé ; le client Java signale la même publication comme confirmée et appelle le `ReturnListener` juste avant.
- `redelivered` dépend de la fenêtre de prefetch : sans limite, les messages qu'un consommateur planté n'a jamais regardés reviennent avec `redelivered=True`.
- Le convertisseur Jackson de Spring AMQP écrit le nom de la classe Java, `dev.learn.rabbitmq.spring.OrdersApplication$Order`, dans un en-tête `__TypeId__`, et se passe de lui quand le type du paramètre du listener est concret.
- Juste après le démarrage d'un broker, `curl "…/api/queues/%2F/hello?columns=name,messages,consumers"` ne renvoyait que `{"name":"hello"}`. Dans une autre exécution, six secondes après la publication, la même requête renvoyait `{"consumers":0,"messages":2,"name":"hello"}`. Le plugin de gestion collecte les statistiques des files périodiquement, donc l'API HTTP a quelques secondes de retard sur `rabbitmqctl`. L'intervalle exact sur 4.3.5 est *à vérifier*.
- Sans rien à l'écoute sur le port 5672 sous Windows, le client .NET a mis 4,3 secondes à signaler `BrokerUnreachableException`, le client Java 165 millisecondes. Une fraction de seconde après `docker rm -f`, Docker Desktop acceptait encore la connexion TCP et le client .NET signalait `connection.start was never received` à la place.

**Ce que j'ai d'abord raté :**

- Git Bash convertissait `/var/lib/rabbitmq/` dans `docker exec rabbitmq ls /var/lib/rabbitmq/` en chemin Windows sous `C:/Program Files/Git`. `MSYS_NO_PATHCONV=1` l'en empêche ; `check.sh` le positionne pour les commandes exécutées dans le conteneur. Le positionner pour tout le script cassait à la place le script de lancement de Maven.
- Le POM parent de Spring Boot configure le plugin Maven Shade avec ses propres transformers, et Maven fusionnait mon `ManifestResourceTransformer` avec l'un d'eux : « Cannot find 'resource' in class ManifestResourceTransformer ». `combine.self="override"` sur `<transformers>` l'a corrigé.
- La première version des dumps de files affichait la clé de routage de chaque message avant son corps. Les messages headers et fanout ont une clé vide ou sans signification, et la sortie avait des doubles espaces ; les dumps affichent maintenant les corps, et les exemples topic utilisent la clé de routage comme corps.
- Mon premier push a été refusé : le jeton GitHub n'avait plus le scope `workflow`, nécessaire pour créer un fichier sous `.github/workflows`. Le code est parti en premier ; le workflow attend le scope, donc d'ici là la CI n'exécute pas ces programmes.

## Questions ouvertes

- Les commandes `wslc` et Podman de la leçon 1, ainsi que les commandes Linux et macOS, sont *à vérifier* ; la CI exécute l'image sous Linux.
- La reprise automatique des connexions dans les deux clients après un redémarrage du broker : *à vérifier* avec un programme, probablement dans la leçon 8.
- Ce que fait à la livraison une exception levée par un handler `ReceivedAsync` de RabbitMQ.Client 7, et l'erreur de conversion d'un listener Spring avec un paramètre de type interface et sans `__TypeId__` : *à vérifier* dans la leçon 6.
- `deprecated_features.permit.transient_nonexcl_queues = true` pour autoriser de nouveau les files non durables sur 4.3.5 : *à vérifier*.
- Où passent les 4,3 secondes de la connexion refusée du client .NET sous Windows : *à vérifier*.
- Le débit des messages persistants par rapport aux transitoires, et des confirmations par message par rapport aux confirmations par lot : *à vérifier* dans la leçon 11.
