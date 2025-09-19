# EddaChat

![EddaChat Screenshot](readme-chat.png)

**EddaChat** is a local chat interface powered by **Ollama** that allows you to interact with **Edda**. You can follow the instructions to download and install the interface, and then select your favourite model to chat with.

> A very small and simple model was selected for this installation. Make sure of installing better and larger models to obtain more accurate answers.

---

## Installation

You need to log into Edda and open a terminal window to write the following instructions.

1.  **Clone the repository**
    
    ```bash
    git clone https://github.com/aliswh/eddachat.git
    cd eddachat
    ```
    If you are not familiar with Git, you can download the code archive.
    ```bash
    wget https://github.com/aliswh/eddachat/archive/refs/heads/main.zip
    ```
    and unzip it.
    ```bash
    unzip main.zip
    ```
    and raname the directory.
    ```bash
    mv eddachat-main eddachat
    ```

2.  **Make the script executable**
    
    ```bash
    cd eddachat
    chmod +x eddachat.sh
    ```
3.  **Run the installation script**
    
    ```bash
    ./eddachat.sh install
    ```
    
    This script performs the following actions:
    
    * Installs **Ollama** and **Ollama-UI** in `/staff/<username>/eddachat/`.
    * Sets up necessary environment variables like `PATH`, `OLLAMA_HOME`, and `OLLAMA_MODELS`.
    * Customizes the UI header to "Chat with Edda."
    * Copies `icon-edda.jpg` to the UI folder.
    * Configures the default system prompt to reflect Edda’s persona.
    
    **Note:** You may need to log out and log back in, or run `source ~/.bashrc` for the new environment variables to take effect.

---

## Using EddaChat

### Start the server and UI

```bash
./eddachat.sh start [GPU]
```

Replace [GPU] with the number of the GPU you want to use. If you don't specify one, it defaults to GPU 0. This command starts the Ollama server and opens the web UI in your browser. Please check which GPUs are free before starting to chat.

```bash
nvidia-smi
```

This command will show you which GPUs are free or in use.

### Stop the server
```bash
./eddachat.sh stop
```
This command frees up the GPU resources you were using.

### Download additional models
```bash
./eddachat.sh model [model-name]
```

You can find a list of models at the [Ollama library](https://ollama.com/library). Example:

```bash
./eddachat.sh model gemma3:1b
```

You can also get a list of available models, but it's better to research if that model fits your needs before downloading it.

```bash
./eddachat.sh listmodels
```

You can also delete models.

```bash
./eddachat.sh deletemodel [name]
```

# Usage notes

Keep the terminal running while using the chat interface to ensure the server stays active.

The default system prompt makes Edda a general-purpose assistant. It can be changed in the web UI.


# Development Notes
All UI customizations (header, icon, and default system prompt) are automatically handled by the installation script.


# Troubleshooting
Ollama command not found: Ensure you have run source ~/.bashrc or have logged out and back in.

Server not reachable: Confirm that ./eddachat.sh start is running and that you are using the correct URL: http://localhost:8000.

GPU busy: Use nvidia-smi to check which GPUs are available and specify an available one when starting the server (e.g., ./eddachat.sh start 1).

> Enjoy chatting with Edda! 💻✨






