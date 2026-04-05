# Using local Ollama with Cursor (free inference)

## Fast path: Cursor **Agent** / **Ask** (tool calling)

**`deepseek-r1:7b` does not support tools** — Agent and **Ask** (when Cursor sends tools) will fail. Use **Qwen3** instead; Ollama lists it with **tools** + **thinking** ([qwen3 library](https://ollama.com/library/qwen3)).

```bash
cd /path/to/AI-Agent
make pull-agent
# same as: ./scripts/pull-agent-model.sh          → default qwen3:8b (~5.2 GB)
# lighter:  ./scripts/pull-agent-model.sh qwen3:4b
```

Then:

1. **`make tunnel-cursor`** → set **Override OpenAI Base URL** to `https://….trycloudflare.com/v1`.
2. **Cursor → Settings → Models** → **Add custom model** **`qwen3:8b`** (exact tag) → enable it.
3. New chat → pick **`qwen3:8b`** in the model dropdown → **Agent** or **Ask**.

Stronger (needs more RAM): `./scripts/pull-agent-model.sh qwen3:14b` (~9.3 GB).

**Honest expectation:** A local **8B** model is **not** cloud Opus/GPT-4 quality, but it is **free** and can run tools when the stack and Cursor agree on the API.

### `context canceled`, cloudflared `Incoming request ended abruptly`, Ollama `499` / load aborted

Cursor (and the tunnel) typically **stop waiting after ~30–35 seconds**. Loading **qwen3:8b** from disk on **CPU** often takes **longer** on the **first** request, so the client disconnects → *context canceled* → chat/Agent looks broken.

**Fix — warm up the model before Cursor:**

```bash
make warmup-ollama
# or: ./scripts/warmup-ollama.sh qwen3:8b
```

Wait until it prints **`[OK]`** (can be **1–3+ minutes** on CPU). Then start **`make tunnel-cursor`** and use Cursor.

**Optional — stay loaded (uses RAM):** in `.env` set `OLLAMA_KEEP_ALIVE=-1` so Ollama does not unload the weights after idle (default is often `5m`).

---

## cloudflared: `sendmsg: operation not permitted` / QUIC / HTML error in chat

Cloudflare’s **QUIC** transport uses **UDP**. On **WSL2**, **VPNs**, or strict firewalls, UDP is often blocked. Logs show:

`Failed to dial a quic connection … write udp … sendmsg: operation not permitted`

Then the tunnel dies; Cursor may show **raw Cloudflare 5xx HTML** instead of model output.

**Fix (this repo):** `start-cursor-tunnel` defaults to **`--protocol http2`** (TCP). Override in `.env` only if you need QUIC:

```env
TUNNEL_TRANSPORT_PROTOCOL=http2
```

To try QUIC again when your network allows UDP:

```env
TUNNEL_TRANSPORT_PROTOCOL=quic
```

Restart the tunnel after changing `.env`.

---

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
6. Enable the models you pulled — **`qwen3:8b`** for **Agent** / **Ask**; **`deepseek-r1:7b`** only for plain **Chat** (no tools).
7. Leave the tunnel terminal **open** while you use Cursor.

**Note:** Quick tunnels get a **new URL each time**. For a fixed URL, use [ngrok](https://ngrok.com) (authtoken) or a Cloudflare **named** tunnel.

## Still free?

Yes. Inference runs on **your machine** (Docker Ollama). The tunnel only forwards HTTPS to your PC. Cursor may still require a **Cursor account** for the app; it does not bill you for Ollama tokens.

## Open WebUI (no tunnel)

Browser chat at `http://localhost:3000` talks to Ollama on your LAN directly — no SSRF issue.

## Continue.dev (optional)

The [Continue](https://continue.dev) extension often calls `localhost` from **your** machine, which can work without a tunnel for inline chat. Agent parity varies.

## Error: `does not support tools`

**Agent** and **Ask** send **tool** requests. Models like **`deepseek-r1:7b`** reject them.

**Fix:** Run **`make pull-agent`** and select **`qwen3:8b`** in Cursor (see **Fast path** above).  
**Or** stay on DeepSeek and use **Chat** only (not Agent / not tool-using Ask).

**Summary:** Tunnel fixes `ssrf_blocked`. **qwen3** (or another tool-capable Ollama model) fixes `does not support tools` for Agent-style modes.
