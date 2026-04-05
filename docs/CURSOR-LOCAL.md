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
