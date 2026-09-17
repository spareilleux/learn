# Equivalent of `docker compose -p wslcdemo up -d` for compose.yaml, with wslc
$project = 'wslcdemo'

# What Compose creates implicitly: one network per project, named volumes
wslc network create "${project}_default"
wslc volume create "${project}_qdrant-data"

# service qdrant (the service name becomes a DNS alias on the project network)
wslc run -d --name "$project-qdrant-1" --network "${project}_default" --network-alias qdrant `
    -p 127.0.0.1:16333:6333 -v "${project}_qdrant-data:/qdrant/storage" qdrant/qdrant:v1.19.1

# service seed (depends_on only orders the start: curl retries until qdrant answers)
wslc run --name "$project-seed-1" --network "${project}_default" --network-alias seed `
    curlimages/curl:8.16.0 --silent --show-error --retry 10 --retry-connrefused --retry-delay 1 `
    -X PUT http://qdrant:6333/collections/demo -H 'Content-Type: application/json' `
    -d '{"vectors":{"size":4,"distance":"Cosine"}}'
