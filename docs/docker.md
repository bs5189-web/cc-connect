# Docker / Docker Compose

This image bundles `cc-connect` and the OpenAI Codex CLI (`@openai/codex`).
The container starts `cc-connect` directly and keeps both cc-connect and Codex
state on the host through bind mounts.

## Quick Start

```bash
cp docker/.env.example .env
cp docker/cc-connect/config.toml.example docker/cc-connect/config.toml
mkdir -p workspace docker/codex docker/cc-connect/data
```

If `docker/cc-connect/config.toml` is missing, the image seeds this file from
the bundled Docker template on startup. The seeded project uses the `codex`
agent by default. Existing mounted configs are never overwritten.

Edit `.env` and `docker/cc-connect/config.toml`:

- Set `OPENAI_API_KEY`.
- Set your platform credentials, such as `TELEGRAM_BOT_TOKEN`.
- Set `CC_CONNECT_WORKSPACE` to the host project directory Codex should edit.
  The directory must already exist before the container starts.
- Replace `change-me-bridge-token` and `change-me-management-token`.
- On Linux, optionally set `CC_CONNECT_UID` and `CC_CONNECT_GID` to `id -u`
  and `id -g` so mounted files stay writable by your host user.

Start:

```bash
docker compose up -d --build
```

Logs:

```bash
docker compose logs -f cc-connect
```

Stop:

```bash
docker compose down
```

## Mounted Paths

| Host path | Container path | Purpose |
| --- | --- | --- |
| `./docker/cc-connect` | `/home/ccconnect/.cc-connect` | `config.toml`, cc-connect data, session state |
| `./docker/codex` | `/home/ccconnect/.codex` | Codex config, auth, model cache, sessions, skills |
| `${CC_CONNECT_WORKSPACE}` | `/workspace` | Project directory used by the Codex agent |

The sample config sets:

```toml
[projects.agent.options]
work_dir = "/workspace"
codex_home = "/home/ccconnect/.codex"
```

If the host path configured by `CC_CONNECT_WORKSPACE` or the container
`work_dir` does not exist, starting a Codex session can fail with:

```text
codexSession: start: fork/exec /usr/local/bin/codex: no such file or directory
```

This message is misleading: the Codex binary may be installed correctly, but Go
reports `no such file or directory` when it cannot start the process in the
configured working directory. Create the host directory first, or change
`work_dir` to an existing path mounted into the container.

## Ports

The Compose file publishes these optional cc-connect services:

- `9810`: Bridge WebSocket (`[bridge]`)
- `9820`: Management API and embedded web admin (`[management]`)
- `9111`: Webhook endpoint (`[webhook]`, disabled by default in the sample)

## Codex CLI Version

By default the image installs `@openai/codex@latest`. To pin a version:

```env
CODEX_NPM_PACKAGE=@openai/codex@0.0.0
```

Then rebuild:

```bash
docker compose build --no-cache cc-connect
```
