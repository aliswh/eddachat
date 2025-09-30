#!/bin/sh

PORT=$OLLAMA_PORT
echo "Starting Ollama UI on http://localhost:$PORT"
# pull in 3rd party libraries from cdn.jsdelivr.net
./fetch_resources.sh

# host local webserver
python3 -m http.server --bind 127.0.0.1 "$PORT"
