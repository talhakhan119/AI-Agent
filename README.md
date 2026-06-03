# Local AI Agent Stack (DeepSeek R1)

This project provides a ready-to-use Docker environment to host LLMs locally using **Ollama**, an interactive frontend via **Open WebUI**, and web search integration with **SearXNG**.

Our primary goal is to run the **DeepSeek R1** model locally with zero API limits, quotas, or token costs, and easily integrate it as an AI backend for IDEs like Cursor, VSCode, and Antigravity.

---

## 🚀 Running in WSL (Windows Subsystem for Linux)

**Question:** *Is it easily possible to run the models in WSL and use them from Windows IDEs?*
**Answer:** **Yes, it is perfectly and easily possible!**
When you run Docker containers inside WSL, the ports are seamlessly forwarded to your Windows host. This means Ollama running inside WSL on port `11434` will be instantly available to your Windows IDEs at `http://localhost:11434` without any extra network configuration.

### Prerequisites
1. Windows with **WSL2** installed.
2. **Docker Desktop** installed on Windows (with WSL2 integration enabled for your specific distro) OR **Docker Engine** installed directly inside WSL.
3. (Optional but recommended) NVIDIA drivers for GPU acceleration.

---

## 🛠️ Setup & Installation

### 1. Start the Docker Services
Open your WSL terminal, navigate to this project folder, and run:

```bash
# To run on CPU only:
docker compose up -d

# To run with GPU acceleration (Recommended for DeepSeek R1):
docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d
```

### 2. Download the DeepSeek R1 Model
Once the containers are up, you need to pull the DeepSeek R1 model into Ollama. Run the following command in your WSL terminal:

```bash
docker exec -it ai-agent-ollama ollama run deepseek-r1
```
*(Note: You can specify a quantized version based on your RAM/VRAM, e.g., `deepseek-r1:8b` or `deepseek-r1:14b` depending on what your laptop can handle).*

You can verify the model is downloaded by running:
```bash
docker exec -it ai-agent-ollama ollama list
```

---

## 💻 IDE Integration (Cursor, VSCode, Antigravity)

Now that Ollama is serving DeepSeek R1 at `http://localhost:11434`, you can configure your agentic coding environments to use it.

### Cursor Setup
1. Open Cursor Settings (Gear icon).
2. Go to **Models**.
3. Under the **OpenAI API** or **Local API** section, toggle the base URL or add a custom OpenAI compatible endpoint.
4. Set the Base URL to: `http://localhost:11434/v1`
5. Set the API Key to anything (e.g., `ollama`), as it is not checked by local Ollama.
6. Add the model name exactly as it appears in Ollama (e.g., `deepseek-r1` or `deepseek-r1:8b`).
7. Save and select the model from the dropdown in your chat.

### VSCode (via Continue.dev or CodeGPT extensions)
1. Install an extension like **Continue.dev**.
2. Open the extension's configuration (`config.json`).
3. Add Ollama as a provider:
```json
{
  "models": [
    {
      "title": "DeepSeek R1 (Local)",
      "provider": "ollama",
      "model": "deepseek-r1",
      "apiBase": "http://localhost:11434"
    }
  ]
}
```
4. Start chatting and generating code without API quotas!

### Antigravity Setup
If Antigravity supports OpenAI-compatible endpoints, simply configure the environment variables or UI settings:
- **API URL**: `http://localhost:11434/v1`
- **Model**: `deepseek-r1`
- **API Key**: `dummy-key`

---

## 🌐 Open WebUI Interface

If you just want to chat with DeepSeek R1, this stack includes **Open WebUI**.
- Go to `http://localhost:3000` in your Windows browser.
- Create an admin account (stored locally).
- Select the `deepseek-r1` model from the dropdown at the top and start chatting.

## 📝 Managing the Stack

- **Stop the stack**: `docker compose down`
- **View logs**: `docker compose logs -f`
- **Update images**: `docker compose pull && docker compose up -d`
