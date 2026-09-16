#!/usr/bin/env bash
# Lesson 12: a primary and its standby that the failover programs reach from the host, like an Aurora writer and replica:
# node1 on port 5433 and node2 on 5434, both published by server.sh. check.sh runs this script before each program;
# with the argument stop, it only removes them. Run as the postgres user:
#   docker exec -i -u postgres pg bash -s < ops/12-cluster.sh        docker exec -i -u postgres pg bash -s stop < ops/12-cluster.sh
set -u
export PATH=/usr/lib/postgresql/18/bin:$PATH PGUSER=postgres
cd /tmp
for node in node1 node2; do
  [ -d $node ] && pg_ctl -D $node -m immediate -w stop > /dev/null 2>&1
done
rm -rf node1 node2 ./*.log password
[ "${1:-}" = stop ] && exit 0

# The postgres password is the course server's; Unix-socket connections inside the container need none
echo learn > password
initdb -D node1 --auth-local=trust --auth-host=scram-sha-256 --pwfile=password > /dev/null
rm password
cat >> node1/postgresql.conf <<'EOF'
listen_addresses = '*'
shared_buffers = 32MB
EOF
# Connections from the host come through Docker's network, not from 127.0.0.1
echo "host all all all scram-sha-256" >> node1/pg_hba.conf
pg_ctl -D node1 -l node1.log -o "-p 5433" -w start > /dev/null || exit 1
psql -X -q -p 5433 -c 'CREATE DATABASE learn'
psql -X -q -p 5433 -d learn -c 'CREATE TABLE orders (id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY, written_on int NOT NULL DEFAULT inet_server_port())'

pg_basebackup -p 5433 -D node2 -R -X stream -c fast
pg_ctl -D node2 -l node2.log -o "-p 5434" -w start > /dev/null || exit 1
for _ in $(seq 150); do
  [ "$(psql -X -Atq -p 5433 -c "SELECT count(*) FROM pg_stat_replication WHERE state = 'streaming'")" = 1 ] && break
  sleep 0.2
done
echo "node1: primary on port 5433, node2: standby on port 5434"
