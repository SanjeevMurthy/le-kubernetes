#!/usr/bin/env bash
# ─── Setup Script Resolution (v2) ────────────────────────────────

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
