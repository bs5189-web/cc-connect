#!/usr/bin/env sh
set -eu

default_config="/home/ccconnect/.cc-connect/config.toml"
seed_config="/etc/cc-connect/config.toml"

config_path="${CC_CONNECT_CONFIG:-$default_config}"
prev=""
for arg in "$@"; do
    if [ "$prev" = "-config" ] || [ "$prev" = "--config" ]; then
        config_path="$arg"
        break
    fi
    case "$arg" in
        -config=*)
            config_path="${arg#-config=}"
            break
            ;;
        --config=*)
            config_path="${arg#--config=}"
            break
            ;;
    esac
    prev="$arg"
done

if [ ! -s "$config_path" ] && [ -f "$seed_config" ]; then
    mkdir -p "$(dirname "$config_path")"
    cp "$seed_config" "$config_path"
    echo "Seeded default Codex config at $config_path"
fi

exec "$@"
