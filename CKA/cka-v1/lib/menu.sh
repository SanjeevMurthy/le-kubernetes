#!/usr/bin/env bash
# ─── Menu Functions ────────────────────────────────────────────────

show_main_menu() {
  print_header "${ICON_TARGET} CKA Exam Practice CLI"
  echo -e "  ${BOLD}${WHITE}Select an action:${RESET}"
  echo ""
  echo -e "  ${CYAN}[1]${RESET}  ${WHITE}List all questions${RESET}"
  echo -e "  ${CYAN}[2]${RESET}  ${WHITE}Select a question to practice${RESET}"
  echo -e "  ${CYAN}[3]${RESET}  ${WHITE}Exit${RESET}"
  echo ""
  echo -ne "  ${BOLD}> ${RESET}"
}

show_question_list() {
  print_header "${ICON_BOOK} All CKA Questions"

  local current_domain=""
  for q in "${QUESTIONS[@]}"; do
    local id=$(get_question_id "$q")
    local title=$(get_question_title "$q")
    local domain=$(get_question_domain "$q")
    local ds=$(get_question_domain_short "$q")
    local diff=$(get_question_difficulty "$q")
    local dc=$(get_domain_color "$ds")
    local dfc=$(get_difficulty_color "$diff")

    if [[ "$domain" != "$current_domain" ]]; then
      echo ""
      echo -e "  ${BOLD}${dc}▸ ${domain}${RESET}"
      print_separator
      current_domain="$domain"
    fi

    printf "  ${dc}[Q%-2s]${RESET}  %-45s ${dfc}%-6s${RESET}\n" "$id" "$title" "$diff"
  done
  echo ""
}

show_question_selector() {
  echo ""
  echo -e "  ${BOLD}${WHITE}Enter question number (1-18) or 'b' to go back:${RESET}"
  echo -ne "  ${BOLD}> Q${RESET}"
}

show_question_actions() {
  local q="$1"
  local id=$(get_question_id "$q")
  local title=$(get_question_title "$q")
  local domain=$(get_question_domain "$q")
  local diff=$(get_question_difficulty "$q")
  local ds=$(get_question_domain_short "$q")
  local dc=$(get_domain_color "$ds")
  local dfc=$(get_difficulty_color "$diff")

  echo ""
  print_separator
  echo -e "  ${BOLD}${WHITE}Q${id} — ${title}${RESET}"
  echo -e "  ${dc}${domain}${RESET}  |  ${dfc}${diff}${RESET}"
  print_separator
  echo ""

  # Show timer if running
  if [[ -n "${TIMER_START:-}" ]]; then
    local elapsed=$(( $(date +%s) - TIMER_START ))
    local mins=$(( elapsed / 60 ))
    local secs=$(( elapsed % 60 ))
    echo -e "  ${YELLOW}${ICON_CLOCK}  Timer: ${mins}m ${secs}s elapsed${RESET}"
    echo ""
  fi

  echo -e "  ${GREEN}[S]${RESET}  ${ICON_GEAR}  Setup scenario"
  echo -e "  ${CYAN}[Q]${RESET}  ${ICON_BOOK}  Show question"
  echo -e "  ${YELLOW}[H]${RESET}  ${ICON_HINT}  Show solution (hint)"
  echo -e "  ${MAGENTA}[V]${RESET}  ${ICON_CHECK}  Verify my solution"
  echo -e "  ${RED}[C]${RESET}  ${ICON_BROOM}  Cleanup scenario"
  echo -e "  ${GRAY}[B]${RESET}       Back to menu"
  echo ""
  echo -ne "  ${BOLD}> ${RESET}"
}

display_question_file() {
  local filepath="$1"
  local label="$2"
  echo ""
  print_separator
  echo -e "  ${BOLD}${CYAN}${label}${RESET}"
  print_separator
  echo ""
  if [[ -f "$filepath" ]]; then
    # Indent and colorize the markdown content
    while IFS= read -r line; do
      if [[ "$line" =~ ^#\  ]]; then
        echo -e "  ${BOLD}${WHITE}${line}${RESET}"
      elif [[ "$line" =~ ^\>\  ]]; then
        echo -e "  ${YELLOW}${line}${RESET}"
      elif [[ "$line" =~ ^\`\`\` ]]; then
        echo -e "  ${GRAY}${line}${RESET}"
      else
        echo "  $line"
      fi
    done < "$filepath"
  else
    print_warn "File not found: $filepath"
  fi
  echo ""
}

confirm_action() {
  local prompt="$1"
  echo -ne "  ${YELLOW}${prompt} (y/n): ${RESET}"
  read -r answer
  [[ "$answer" =~ ^[Yy]$ ]]
}
