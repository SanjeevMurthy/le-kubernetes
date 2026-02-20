#!/usr/bin/env bash
# ─── Setup Script Resolution ─────────────────────────────────────
# All setup scripts are now local to the cka-cli-tool/questions/ directory.
# This file is kept for backward compatibility but the v2 mapping is removed.

get_setup_path() {
  local folder="$1"
  local cli_dir
  cli_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  local setup="$cli_dir/questions/$folder/setup.sh"
  if [[ -f "$setup" ]]; then
    echo "$setup"
  else
    echo ""
  fi
}
