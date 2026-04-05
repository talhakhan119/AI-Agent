# Using local Ollama with Cursor (free inference)

## Why `localhost` fails in Agent mode

If you see:

`ssrf_blocked` — connection to private IP is blocked

Cursor’s servers proxy some **Agent** requests. They refuse `http://localhost:...` and other private addresses. Your **Models** settings are correct; the block is on Cursor’s side.

## Option B — Quick public tunnel (recommended)

1. Start the stack: `make start` or `./scripts/start.sh`.
2. In a **second** terminal, run:

   **WSL / Linux / macOS**

   ```bash
   chmod +x scripts/start-cursor-tunnel.sh
   ./scripts/start-cursor-tunnel.sh
   ```

   **Windows PowerShell**

   ```powershell
   .\scripts\start-cursor-tunnel.ps1
   ```

3. Install **cloudflared** if prompted (links print in the script).
4. Copy the printed `https://xxxxx.trycloudflare.com` URL.
5. **Cursor → Settings → Models**
   - **OpenAI API Key**: ON, value e.g. `ollama`
   - **Override OpenAI Base URL**: ON
   - **Base URL**: `https://xxxxx.trycloudflare.com/v1` (must end with `/v1`)
6. Enable custom model **`deepseek-r1:7b`** (or whatever you pulled).
7. Leave the tunnel terminal **open** while you use Cursor.

**Note:** Quick tunnels get a **new URL each time**. For a fixed URL, use [ngrok](https://ngrok.com) (authtoken) or a Cloudflare **named** tunnel.

## Still free?

Yes. Inference runs on **your machine** (Docker Ollama). The tunnel only forwards HTTPS to your PC. Cursor may still require a **Cursor account** for the app; it does not bill you for Ollama tokens.

## Open WebUI (no tunnel)

Browser chat at `http://localhost:3000` talks to Ollama on your LAN directly — no SSRF issue.

## Continue.dev (optional)

The [Continue](https://continue.dev) extension often calls `localhost` from **your** machine, which can work without a tunnel for inline chat. Agent parity varies.

## Error: `does not support tools` (DeepSeek R1 + Agent mode)

**Cursor Agent** sends **tool / function-calling** requests (run terminal, read files, etc.). Many Ollama models—including **`deepseek-r1:7b`**—do **not** implement that API, so Ollama returns:

`registry.ollama.ai/library/deepseek-r1:7b does not support tools`

**What to do**

1. **Use Chat (or Composer), not Agent**  
   In the chat input bar, switch the mode from **Agent** to **Chat** (or start a **New Chat** and pick **Chat**). Same tunnel + base URL + model; only Agent requires tools.

2. **Keep using DeepSeek R1 for reasoning-style Q&A in Chat**  
   Thinking / chain-of-thought still works in normal chat completions.

3. **If you need Agent-style automation with a local model**  
   Try a model Ollama exposes with tool support (varies by image/version), e.g. pull and test **`qwen2.5-coder:7b`** or **`llama3.1:8b`**, add them in Cursor Models, and see if Agent accepts them. There is no guarantee Cursor Agent will fully match cloud agents.

**Summary:** Tunnel fixes `ssrf_blocked`. **Chat vs Agent** fixes `does not support tools` for DeepSeek R1.
