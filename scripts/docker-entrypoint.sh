#!/bin/sh
# ZeroClaw cloud entrypoint — generates config.toml from env vars at runtime.
# This runs every container start so config is always in sync with Dokploy env vars.
set -e

CONFIG_DIR="/zeroclaw-data/.zeroclaw"
CONFIG_FILE="${CONFIG_DIR}/config.toml"

mkdir -p "${CONFIG_DIR}" /zeroclaw-data/workspace

# ── Base config ───────────────────────────────────────────────
cat > "${CONFIG_FILE}" << _TOML
workspace_dir = "/zeroclaw-data/workspace"
config_path = "${CONFIG_FILE}"
api_key = "${API_KEY:-}"
default_provider = "${PROVIDER:-openrouter}"
default_model = "${ZEROCLAW_MODEL:-anthropic/claude-sonnet-4-20250514}"
default_temperature = 0.7

[gateway]
port = ${ZEROCLAW_GATEWAY_PORT:-3000}
host = "[::]"
allow_public_bind = true

[channels]
cli = false
_TOML

# ── Telegram (only added if TELEGRAM_BOT_TOKEN is set) ───────
if [ -n "${TELEGRAM_BOT_TOKEN}" ]; then
  # Build TOML array from comma-separated TELEGRAM_ALLOWED_USERS
  # e.g. "alice,bob" → ["alice","bob"]
  USERS=""
  OLD_IFS="$IFS"
  IFS=','
  for u in ${TELEGRAM_ALLOWED_USERS:-}; do
    trimmed="$(echo "$u" | tr -d ' ')"
    if [ -n "$trimmed" ]; then
      if [ -n "$USERS" ]; then
        USERS="${USERS},\"${trimmed}\""
      else
        USERS="\"${trimmed}\""
      fi
    fi
  done
  IFS="$OLD_IFS"

  cat >> "${CONFIG_FILE}" << _TOML

[channels.telegram]
bot_token = "${TELEGRAM_BOT_TOKEN}"
allowed_users = [${USERS}]
_TOML
fi

exec zeroclaw "$@"
