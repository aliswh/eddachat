#!/bin/bash
# === All-in-one EddaChat installer/manager with UI customization ===

SCRIPT_DIR="$(pwd)"

# Prompt for edda username
read_username() {
  if [ -n "$OLLAMA_USERNAME" ]; then
    USERNAME="$OLLAMA_USERNAME"
  elif [ -z "$USERNAME" ]; then
    read -p "Enter your edda username: " USERNAME
  fi
  BASE_DIR="/staff/$USERNAME/eddachat"
  MODEL_DIR="$BASE_DIR/ollama_data"
}


# Install Ollama + UI
install_eddachat() {
  read_username
  echo "Creating directories in $BASE_DIR..."
  mkdir -p "$BASE_DIR" "$MODEL_DIR"

  echo "Downloading latest Ollama release..."
  cd "$BASE_DIR"
  wget -q --show-progress https://github.com/ollama/ollama/releases/latest/download/ollama-linux-amd64.tgz
  tar -xvzf ollama-linux-amd64.tgz
  rm ollama-linux-amd64.tgz

  echo "Updating ~/.bashrc..."
  {
    echo "export PATH=$BASE_DIR/bin:\$PATH"
    echo "export OLLAMA_MODELS=\"$MODEL_DIR\""
    echo "export OLLAMA_HOME=\"$BASE_DIR\""
    echo "export OLLAMA_USERNAME=\"$USERNAME\""
  } >> ~/.bashrc
  source ~/.bashrc

  echo "Verifying Ollama..."
  if ! command -v ollama &> /dev/null; then
      echo "Ollama installation failed. Please check manually."
      exit 1
  fi

  echo "Downloading sample model gemma3:1b..."
  ollama pull gemma3:1b

  echo "Cloning EddaChat UI..."
  cd "$BASE_DIR"
  git clone https://github.com/ollama-ui/ollama-ui || true

  # === Customize UI header and add icon ===
  echo "Customizing UI header and adding icon..."
  mkdir -p "$BASE_DIR/ollama-ui/public"

  if [ -f "icon-edda.jpg" ]; then
    cp icon-edda.jpg "$BASE_DIR/ollama-ui/public/icon-edda.jpg"
  else
    echo "Warning: icon-edda.jpg not found, skipping copy."
  fi

  INDEX_FILE="$BASE_DIR/ollama-ui/index.html"

  if [ -f "$INDEX_FILE" ]; then
    # Change header text
    sed -i 's/Chat with Ollama/Chat with Edda/' "$INDEX_FILE"

    # Insert image under header (if not already present)
    if ! grep -q 'icon-edda.jpg' "$INDEX_FILE"; then
      sed -i '/<h1>Chat with Edda<\/h1>/a \
      <img src="public/icon-edda.jpg" alt="Edda icon" style="max-height:100px; margin-top:4px; border-radius:8px;">' "$INDEX_FILE"
    fi
  else
    echo "Warning: index.html not found at $INDEX_FILE"
  fi

  # === Set default system prompt to Edda Sveinsdottir ===
  CHAT_JS="$BASE_DIR/ollama-ui/chat.js"
  if [ -f "$CHAT_JS" ]; then
      if ! grep -q 'Edda Sveinsdottir' "$CHAT_JS"; then
          echo "" >> "$CHAT_JS"
          echo "// Set default system prompt to Edda Sveinsdottir" >> "$CHAT_JS"
          echo "document.addEventListener(\"DOMContentLoaded\", () => {" >> "$CHAT_JS"
          echo "    const systemPromptInput = document.getElementById(\"system-prompt\");" >> "$CHAT_JS"
          echo "    if(systemPromptInput) {" >> "$CHAT_JS"
          echo "        systemPromptInput.value = \"You are Edda, a knowledgeable and helpful assistant. You are proficient in English and Danish.\";" >> "$CHAT_JS"
          echo "    }" >> "$CHAT_JS"
          echo "});" >> "$CHAT_JS"
      fi
  else
      echo "Warning: chat.js not found at $CHAT_JS. Cannot set default system prompt."
  fi

  echo "=== Installation complete! ==="
  echo "Log out/in or run 'source ~/.bashrc' for env vars to apply."
}

# Start server + launch UI
start_server_and_ui() {
  read_username
  GPU=0
  if [[ $1 =~ ^[0-9]+$ ]]; then
    GPU=$1
  fi

  echo "Restarting Ollama server on GPU $GPU..."
  pkill -u $USER -f "./ollama serve" 2>/dev/null
  sleep 1
  export CUDA_VISIBLE_DEVICES=$GPU
  export OLLAMA_NUM_PARALLEL=1
  ollama serve &
  sleep 5

  echo "Launching UI..."
  cd "$OLLAMA_HOME/ollama-ui"
  make
  if command -v xdg-open &> /dev/null; then
    xdg-open http://localhost:8000
  elif command -v open &> /dev/null; then
    open http://localhost:8000
  else
    echo "Open http://localhost:8000 in your browser."
  fi
}

# Stop server
stop_server() {
  pkill -u $USER -f "ollama serve"
  pkill -u $USER -f "python3 -m http.server"
  echo "Ollama server and web stopped"
}

# Download models (interactive menu if no name)
list_models_remote() {
  echo "Fetching list of available models from Ollama library..."
  if ! command -v curl &> /dev/null; then
    echo "Error: curl is required to list models. Please install curl."
    exit 1
  fi

  RESP=$(curl -s "https://ollamadb.dev/api/v1/models?limit=20")
  if [ -z "$RESP" ]; then
    echo "Could not fetch model list."
    exit 1
  fi

  if command -v jq &> /dev/null; then
    NAMES=($(echo "$RESP" | jq -r '.models[] | .model_identifier'))
    DESCS=($(echo "$RESP" | jq -r '.models[] | .description'))
  else
    NAMES=($(echo "$RESP" | grep -o '"model_identifier":"[^"]*' | sed 's/"model_identifier":"//'))
    DESCS=()
  fi

  echo "Available models:"
  for i in "${!NAMES[@]}"; do
    if [ "${DESCS[$i]+isset}" ]; then
      printf "%3d) %s — %s\n" $((i+1)) "${NAMES[$i]}" "${DESCS[$i]}"
    else
      printf "%3d) %s\n" $((i+1)) "${NAMES[$i]}"
    fi
  done

  read -p "Enter number of model to download (or 0 to cancel): " CHOICE
  if ! [[ "$CHOICE" =~ ^[0-9]+$ ]]; then
    echo "Invalid input."
    exit 1
  fi
  if [ "$CHOICE" -eq 0 ]; then
    echo "Cancelled."
    exit 0
  fi
  if [ "$CHOICE" -le 0 ] || [ "$CHOICE" -gt "${#NAMES[@]}" ]; then
    echo "Choice out of range."
    exit 1
  fi

  SELECTED="${NAMES[$((CHOICE-1))]}"
  echo "Downloading model: $SELECTED"
  ollama pull "$SELECTED"
}

download_model() {
  if [ -z "$1" ]; then
    list_models_remote
  else
    model="$1"
    echo "Downloading model: $model ..."
    ollama pull "$model"
  fi
}

# Delete a model
delete_model() {
  read_username
  if [ -z "$1" ]; then
    echo "Usage: $0 deletemodel [model-name]"
    return 1
  fi

  MODEL="$1"
  echo "Deleting model: $MODEL ..."

  # Start Ollama server in background
  echo "Starting temporary Ollama server..."
  export CUDA_VISIBLE_DEVICES=0
  export OLLAMA_NUM_PARALLEL=1
  ollama serve &

  SERVER_PID=$!
  sleep 5  # give server time to start

  # Try to remove the model
  if ollama rm "$MODEL"; then
    echo "Model '$MODEL' deleted successfully."
  else
    echo "Failed to delete model '$MODEL'. Make sure the model exists."
  fi

  # Stop temporary server
  echo "Stopping temporary Ollama server..."
  kill "$SERVER_PID"
  wait "$SERVER_PID" 2>/dev/null

  echo "Done."
}



# === Main ===
COMMAND="$1"; shift
case "$COMMAND" in
  install) install_eddachat ;;
  start) start_server_and_ui "$@" ;;
  stop) stop_server ;;
  model) download_model "$@" ;;
  listmodels) list_models_remote ;;
  deletemodel) delete_model "$@" ;;
  *)
    echo "Usage:"
    echo "  $0 install              # install EddaChat + UI and customize header"
    echo "  $0 start [GPU]          # start server + launch UI"
    echo "  $0 stop                 # stop server"
    echo "  $0 model [model-name]   # download a model, interactive if no name"
    echo "  $0 listmodels           # list available models"
    echo "  $0 deletemodel [name]   # delete a downloaded model"
    ;;
esac

