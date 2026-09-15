#!/usr/bin/env bash
# RabbitMQ course: build the C# and Java examples, then run them against a fresh broker and compare every output
# the lessons quote with expected/.
#   bash check.sh build   only builds (CI on Windows and macOS, whose hosted runners have no Docker)
#   bash check.sh         builds and runs; the broker must be up (bash broker.sh start) and empty
#   UPDATE=1 bash check.sh   writes the outputs to expected/ instead of comparing (review the diff before committing)
# RABBITMQ_HOST names the broker (default localhost); ENGINE and BROKER_CONTAINER are passed on to broker.sh.
set -uo pipefail
cd "$(dirname "$0")"
MVN=${MVN:-mvn}
engine=${ENGINE:-docker}
container=${BROKER_CONTAINER:-rabbitmq}

dotnet build csharp -c Release -m:1 --nologo -v quiet "-clp:ErrorsOnly;NoSummary" || exit 1
$MVN -B -q -f java/pom.xml package || exit 1
if [ "${1:-}" = build ]; then
  exit 0
fi

status=0
mkdir -p out expected

compare() {
  local name=$1
  if [ "${UPDATE:-}" = 1 ]; then
    cp "out/$name.txt" "expected/$name.txt"
    echo "upd  $name"
  elif diff --strip-trailing-cr "expected/$name.txt" "out/$name.txt"; then
    echo "ok   $name"
  else
    echo "FAIL $name"
    status=1
  fi
}

# step <expected name> <command...>: runs the command, records its output and exit code, compares
step() {
  local name=$1
  shift
  { "$@" < /dev/null 2>&1; echo "exit $?"; } > "out/$name.txt"
  compare "$name"
}

cs() { dotnet csharp/bin/Release/net10.0/rabbit.dll "$@"; }
java_client() { java -jar java/client/target/rabbitmq-client.jar "$@"; }
spring() { java -jar java/spring/target/orders-spring.jar "$@"; }
# Runs a CLI tool inside the broker's container, like docker exec rabbitmq rabbitmqctl ...
in_broker() { MSYS_NO_PATHCONV=1 $engine exec "$container" "$@"; }

# Lesson 1: a producer and a consumer in two languages, and the broker's view in between
step l01-server-version in_broker rabbitmq-diagnostics server_version
step l01-listeners in_broker rabbitmq-diagnostics listeners
step l01-plugins in_broker rabbitmq-plugins list --enabled
step l01-port-connectivity in_broker rabbitmq-diagnostics check_port_connectivity
step l01-send-cs cs l01-send
step l01-list-queues in_broker rabbitmqctl list_queues name messages consumers
step l01-receive-java java_client l01-receive
step l01-send-java java_client l01-send
step l01-receive-cs cs l01-receive

# Lesson 2: exchange types, unroutable messages, a redeclaration error; Java's topic output must match C#'s
step l02-direct cs l02-direct
step l02-fanout cs l02-fanout
step l02-topic cs l02-topic
{ java_client l02-topic < /dev/null 2>&1; echo "exit $?"; } > out/l02-topic-java.txt
if [ "${UPDATE:-}" != 1 ] && ! diff --strip-trailing-cr expected/l02-topic.txt out/l02-topic-java.txt; then
  echo "FAIL l02-topic (java)"
  status=1
else
  echo "ok   l02-topic (java)"
fi
step l02-exercise-topic cs l02-exercise-topic
step l02-headers cs l02-headers
step l02-unroutable cs l02-unroutable
step l02-inequivalent cs l02-inequivalent
step l02-exercise-e2e cs l02-exercise-e2e

# Lesson 3: the same order messages across the C# client, the Java client and Spring AMQP
step l03-publish-cs cs l03-publish
step l03-consume-java java_client l03-consume
step l03-publish-java java_client l03-publish
step l03-consume-cs cs l03-consume
step l03-publish-cs cs l03-publish
step l03-listen-spring spring --spring.profiles.active=listen
step l03-publish-spring spring --spring.profiles.active=publish
step l03-consume-cs-from-spring cs l03-consume

# Lesson 4: acknowledgements, prefetch, confirms, durability across a broker restart, idempotence
step l04-autoack cs l04-autoack
step l04-manual-ack cs l04-manual-ack
step l04-exercise-prefetch cs l04-exercise-prefetch
step l04-nack cs l04-nack
step l04-prefetch cs l04-prefetch
step l04-confirms-cs cs l04-confirms
step l04-confirms-java java_client l04-confirms
step l04-durable-publish cs l04-durable-publish
bash broker.sh restart || exit 1
step l04-durable-check cs l04-durable-check
step l04-idempotent cs l04-idempotent

exit $status
