#!/usr/bin/env bash
# ─── Color & Emoji Constants ──────────────────────────────────────

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# Box drawing
BOX_TL='╔'
BOX_TR='╗'
BOX_BL='╚'
BOX_BR='╝'
BOX_H='═'
BOX_V='║'
LINE='─'

# Emojis
ICON_TARGET='🎯'
ICON_CHECK='✅'
ICON_CROSS='❌'
ICON_WARN='⚠️'
ICON_CLOCK='⏱️'
ICON_BOOK='📋'
ICON_HINT='💡'
ICON_GEAR='⚙️'
ICON_BROOM='🧹'
ICON_ROCKET='🚀'
ICON_MEDAL='🏅'

# ─── Helper Functions ─────────────────────────────────────────────

print_header() {
  local title="$1"
  local width=50
  local pad=$(( (width - ${#title} - 2) / 2 ))
  echo ""
  echo -e "${CYAN}${BOX_TL}$(printf "${BOX_H}%.0s" $(seq 1 $width))${BOX_TR}${RESET}"
  echo -e "${CYAN}${BOX_V}$(printf ' %.0s' $(seq 1 $pad)) ${BOLD}${WHITE}${title}${RESET}${CYAN} $(printf ' %.0s' $(seq 1 $(( width - pad - ${#title} - 1 ))))${BOX_V}${RESET}"
  echo -e "${CYAN}${BOX_BL}$(printf "${BOX_H}%.0s" $(seq 1 $width))${BOX_BR}${RESET}"
  echo ""
}

print_separator() {
  echo -e "${GRAY}$(printf "${LINE}%.0s" $(seq 1 55))${RESET}"
}

print_success() {
  echo -e "  ${GREEN}${ICON_CHECK} $1${RESET}"
}

print_error() {
  echo -e "  ${RED}${ICON_CROSS} $1${RESET}"
}

print_warn() {
  echo -e "  ${YELLOW}${ICON_WARN}  $1${RESET}"
}

print_info() {
  echo -e "  ${CYAN}${ICON_BOOK} $1${RESET}"
}
