#!/usr/bin/env bash
# The course broker, one container named rabbitmq: bash broker.sh start | wait | restart | stop
# ENGINE=podman bash broker.sh start uses Podman instead of Docker; BROKER_CONTAINER names another container (CI's service).
set -euo pipefail
engine=${ENGINE:-docker}
image=rabbitmq:4.3.5-management
name=${BROKER_CONTAINER:-rabbitmq}

wait_ready() {
  for _ in $(seq 1 90); do
    if $engine exec $name rabbitmq-diagnostics -q check_port_connectivity > /dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  echo "the broker did not accept connections within 90 s" >&2
  $engine logs --tail 50 $name >&2
  return 1
}

case ${1:-} in
  start)
    # --hostname fixes the node name (rabbit@rabbitmq): RabbitMQ keeps its data under it.
    # --user rabbitmq: a CLI tool run as root before the node has written its Erlang cookie creates the file
    # as root, and the node then stops with "Error when reading /var/lib/rabbitmq/.erlang.cookie: eacces".
    $engine run -d --name $name --hostname $name --user rabbitmq -p 5672:5672 -p 15672:15672 $image > /dev/null
    wait_ready
    ;;
  wait) wait_ready ;;
  restart)
    $engine restart $name > /dev/null
    wait_ready
    ;;
  stop) $engine rm -f $name > /dev/null ;;
  *)
    echo "usage: bash broker.sh start|wait|restart|stop" >&2
    exit 2
    ;;
esac
