---
title: Diario
description: Notas de progreso fechadas del curso de RabbitMQ — versiones elegidas, el broker que fallaba antes de arrancar, sorpresas para un desarrollador de C# o Java, errores, y puntos por verificar.
sidebar:
  order: 99
---

## Progreso

- [x] Lección 1 — Primeros pasos
- [x] Lección 2 — Topología: exchanges, bindings y colas
- [x] Lección 3 — Clientes en C#, Java y Spring AMQP
- [x] Lección 4 — Fiabilidad: acuses de recibo, prefetch, confirmaciones
- [ ] Lección 5 — Tipos de colas: clásicas, quorum y streams
- [ ] Lección 6 — Errores: dead lettering, TTL, reintentos y mensajes diferidos
- [ ] Lección 7 — Patrones: work queues, publish/subscribe, RPC, consumidores en competencia, outbox
- [ ] Lección 8 — Clustering y alta disponibilidad
- [ ] Lección 9 — Seguridad: virtual hosts, usuarios, permisos, TLS
- [ ] Lección 10 — Observabilidad: Prometheus, Grafana, alarmas, control de flujo
- [ ] Lección 11 — Rendimiento y dimensionamiento
- [ ] Lección 12 — Otros protocolos: streams, MQTT, AMQP 1.0; RabbitMQ y Kafka
- [ ] Lección 13 — Operaciones: actualizaciones, definiciones, Kubernetes

## 2026-09-15 — Lecciones 1 a 4

- La página de [release information](https://www.rabbitmq.com/release-information) indicaba 4.3.5 como última versión a 2026-09-15, y el tag `rabbitmq:4.3.5-management` de Docker Hub se había construido el 2026-09-10. La imagen ejecuta Erlang/OTP 27.3.4.17. Los clientes son los últimos de NuGet y Maven Central ese día: RabbitMQ.Client 7.2.2 y amqp-client 5.35.0. Spring Boot 4.1.1 gestiona amqp-client 5.30.0 y Spring AMQP 4.1.1; el POM padre del curso sube el cliente a 5.35.0 con la propiedad `rabbit-amqp-client.version`, para que los dos programas Java usen el mismo cliente.
- El código es un proyecto C# con un comando por ejemplo ([`csharp`](https://github.com/spareilleux/learn/tree/main/code/rabbitmq/csharp)) y un build de Maven con dos módulos, un JAR shaded para el cliente Java y un JAR de Spring Boot ([`java`](https://github.com/spareilleux/learn/tree/main/code/rabbitmq/java)). [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/rabbitmq/check.sh) ejecuta 36 pasos contra un broker recién creado, incluidos comandos `rabbitmqctl` y `rabbitmq-diagnostics` y un reinicio del broker, y compara cada salida con `expected/`. Lo ejecuté dos veces seguidas sobre contenedores nuevos en Windows con los mismos resultados.
- CI: los runners de Windows y macOS alojados por GitHub no tienen Docker, así que el workflow compila allí los clientes y lo ejecuta todo contra un contenedor de servicio de RabbitMQ solo en Linux.
- Para obtener una salida determinista de un broker, los programas evitan depender del tiempo: leen las colas con `basic.get` después de publicar, detienen a los consumidores tras un número conocido de mensajes, y no imprimen ningún consumer tag generado por el servidor. Dos ejemplos aún esperan un poco: 300 ms tras un fallo simulado, para que la ventana de prefetch se llene, y 500 ms para comprobar que un consumidor no recibe un cuarto mensaje.
- Ninguno de los repositorios de GuitarAlchemist usa RabbitMQ en su código (ga en `dc2e74cb`, ix en `ed5e998`, tars en `54487423`). La única configuración que encontré es un [archivo Docker Compose generado en tars](https://github.com/GuitarAlchemist/tars/blob/54487423b5b6e8d4849571e1b3d710f4e99d6f60/.tars/projects/create_a_distributed_microservices_architecture_with_api_gateway/docker-compose.yml#L44-L62): ejecuta `rabbitmq:3.12-management`, una serie que ya no está en la lista de versiones soportadas, con un volumen de datos pero sin `hostname`, de modo que un contenedor recreado arrancaría con un nombre de nodo nuevo y no encontraría sus datos, y fija en el código las credenciales `admin`/`admin123`. Su health check, `rabbitmq-diagnostics ping` como root, es el patrón que tumbó mi broker, aunque un intervalo de 30 segundos hace improbable la carrera.

**El broker que se detenía antes de arrancar.** Mi primer `broker.sh` esperaba al broker ejecutando `docker exec rabbitmq rabbitmq-diagnostics check_port_connectivity` cada segundo. El contenedor moría en menos de dos segundos con `Error when reading /var/lib/rabbitmq/.erlang.cookie: eacces`. La CLI, ejecutada como root, creó la cookie de Erlang antes que el nodo; el nodo, ejecutado como `rabbitmq`, no podía leerla. Lo reproduje con un solo `docker exec` justo después de `docker run`, y `ls -la` mostraba el archivo como propiedad de `root`. Ejecutar el contenedor con `--user rabbitmq` lo arregló, con un health check cada segundo. Es [docker-library/rabbitmq#695](https://github.com/docker-library/rabbitmq/issues/695), cerrada sin comentarios en 2024; la documentación de la imagen no lo menciona. La lección 1 cuenta la historia.

**Sorpresas:**

- RabbitMQ 4.3.5 rechaza una cola declarada con `durable: false` salvo que sea exclusiva: `541 INTERNAL_ERROR - Feature transient_nonexcl_queues is deprecated`, un error de conexión. Todos los tutoriales antiguos que declaran `durable: false` fallan con esta versión.
- Ese texto de error termina en `To...`: los textos de respuesta de AMQP son short strings de 255 bytes como mucho, y el aviso de obsolescencia es más largo.
- Un mensaje no enrutable publicado sin `mandatory` se confirma. Una confirmación de publicación dice que el broker ha terminado con el mensaje, no que una cola lo tenga.
- Con el seguimiento de confirmaciones, RabbitMQ.Client 7 lanza `PublishReturnException` para un mensaje devuelto; el cliente Java informa la misma publicación como confirmada y llama al `ReturnListener` justo antes.
- `redelivered` depende de la ventana de prefetch: sin límite, los mensajes que un consumidor caído nunca miró vuelven con `redelivered=True`.
- El convertidor de Jackson de Spring AMQP escribe el nombre de la clase Java, `dev.learn.rabbitmq.spring.OrdersApplication$Order`, en una cabecera `__TypeId__`, y prescinde de ella cuando el tipo del parámetro del listener es concreto.
- Justo después de arrancar un broker, `curl "…/api/queues/%2F/hello?columns=name,messages,consumers"` devolvía solo `{"name":"hello"}`. En otra ejecución, seis segundos después de publicar, la misma petición devolvía `{"consumers":0,"messages":2,"name":"hello"}`. El plugin de gestión recoge las estadísticas de las colas periódicamente, así que la API HTTP va unos segundos por detrás de `rabbitmqctl`. El intervalo exacto en 4.3.5 está *por verificar*.
- Sin nada escuchando en el puerto 5672 en Windows, el cliente .NET tardó 4,3 segundos en informar `BrokerUnreachableException`, el cliente Java 165 milisegundos. Una fracción de segundo después de `docker rm -f`, Docker Desktop aún aceptaba la conexión TCP y el cliente .NET informaba `connection.start was never received` en su lugar.

**Lo que hice mal al principio:**

- Git Bash convertía `/var/lib/rabbitmq/` en `docker exec rabbitmq ls /var/lib/rabbitmq/` en una ruta de Windows bajo `C:/Program Files/Git`. `MSYS_NO_PATHCONV=1` lo impide; `check.sh` lo fija para los comandos que se ejecutan en el contenedor. Fijarlo para todo el script rompía en cambio el script de arranque de Maven.
- El POM padre de Spring Boot configura el plugin Maven Shade con sus propios transformers, y Maven fusionaba mi `ManifestResourceTransformer` con uno de ellos: «Cannot find 'resource' in class ManifestResourceTransformer». `combine.self="override"` en `<transformers>` lo arregló.
- La primera versión de los volcados de colas imprimía la clave de enrutamiento de cada mensaje antes de su cuerpo. Los mensajes headers y fanout tienen una clave vacía o sin sentido, y la salida tenía espacios dobles; los volcados imprimen ahora los cuerpos, y los ejemplos topic usan la clave de enrutamiento como cuerpo.
- Mi primer push fue rechazado: el token de GitHub ya no tenía el scope `workflow`, necesario para crear un archivo en `.github/workflows`. El código salió primero; el workflow espera al scope, así que hasta entonces la CI no ejecuta estos programas.

## Preguntas abiertas

- Los comandos de `wslc` y Podman de la lección 1, y los de Linux y macOS, están *por verificar*; la CI ejecuta la imagen en Linux.
- La recuperación automática de conexiones en ambos clientes tras un reinicio del broker: *por verificar* con un programa, probablemente en la lección 8.
- Qué le hace a la entrega una excepción lanzada desde un handler `ReceivedAsync` de RabbitMQ.Client 7, y el error de conversión de un listener de Spring con un parámetro de tipo interfaz y sin `__TypeId__`: *por verificar* en la lección 6.
- `deprecated_features.permit.transient_nonexcl_queues = true` para volver a permitir colas no durables en 4.3.5: *por verificar*.
- Adónde van los 4,3 segundos de la conexión rechazada del cliente .NET en Windows: *por verificar*.
- El rendimiento de los mensajes persistentes frente a los transitorios, y de las confirmaciones por mensaje frente a las confirmaciones por lotes: *por verificar* en la lección 11.
