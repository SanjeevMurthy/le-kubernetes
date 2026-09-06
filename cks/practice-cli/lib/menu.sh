#!/usr/bin/env bash
# Menus for the CKS practice CLI. Kept bash 3.2 compatible so the list and
# environment views can be smoke-tested on macOS.

show_main_menu() {
  print_header "${ICON_TARGET} CKS Exam Practice CLI"
  echo -e "  ${BOLD}${WHITE}Select an action:${RESET}"
  echo ""
  echo -e "  ${CYAN}[1]${RESET}  List all questions"
  echo -e "  ${CYAN}[2]${RESET}  Select a question"
  echo -e "  ${CYAN}[3]${RESET}  Random incomplete question"
  echo -e "  ${CYAN}[4]${RESET}  Progress"
  echo -e "  ${CYAN}[5]${RESET}  Mock exam (120 min, scored)"
  echo -e "  ${CYAN}[E]${RESET}  Environment check"
  echo -e "  ${CYAN}[Q]${RESET}  Quit"
  echo ""
  echo -ne "  ${BOLD}> ${RESET}"
}

show_question_list() {
  print_header "${ICON_BOOK} All CKS Questions"
  local current_domain="" q id title domain ds diff dc dfc needs mark
  for q in "${QUESTIONS[@]}"; do
    id=$(get_question_id "$q")
    title=$(get_question_title "$q")
    domain=$(get_question_domain "$q")
    ds=$(get_question_domain_short "$q")
    diff=$(get_question_difficulty "$q")
    needs=$(get_question_needs "$q")
    dc=$(get_domain_color "$ds")
    dfc=$(get_difficulty_color "$diff")
    if [[ "$domain" != "$current_domain" ]]; then
      echo ""
      echo -e "  ${BOLD}${dc}▸ ${domain}${RESET}"
      print_separator
      current_domain="$domain"
    fi
    mark=" "
    is_complete "$id" 2>/dev/null && mark="✓"
    printf "  ${dc}[Q%-2s]${RESET} %s %-48s ${dfc}%-6s${RESET} ${GRAY}%s${RESET}\n" \
      "$id" "$mark" "$title" "$diff" "$needs"
  done
  echo ""
}

show_question_selector() {
  echo ""
  echo -e "  ${BOLD}${WHITE}Enter question number (1-${#QUESTIONS[@]}) or 'b' to go back:${RESET}"
  echo -ne "  ${BOLD}> Q${RESET}"
}

show_question_actions() {
  local q="$1" id title domain diff ds dc dfc
  id=$(get_question_id "$q")
  title=$(get_question_title "$q")
  domain=$(get_question_domain "$q")
  diff=$(get_question_difficulty "$q")
  ds=$(get_question_domain_short "$q")
  dc=$(get_domain_color "$ds")
  dfc=$(get_difficulty_color "$diff")

  echo ""
  print_separator
  echo -e "  ${BOLD}${WHITE}Q${id}. ${title}${RESET}"
  echo -e "  ${dc}${domain}${RESET}  |  ${dfc}${diff}${RESET}  |  ${GRAY}needs: $(get_question_needs "$q")  host: $(get_question_host "$q")  target: $(get_question_minutes "$q") min${RESET}"
  print_separator
  echo ""
  if [[ -f "$TIMER_FILE" ]]; then
    echo -e "  ${YELLOW}${ICON_CLOCK}  Timer: $(fmt_elapsed) elapsed${RESET}"
    echo ""
  fi
  echo -e "  ${GREEN}[S]${RESET}  ${ICON_GEAR}  Setup scenario"
  echo -e "  ${CYAN}[Q]${RESET}  ${ICON_BOOK}  Show question"
  echo -e "  ${YELLOW}[H]${RESET}  ${ICON_HINT}  Show solution"
  echo -e "  ${MAGENTA}[V]${RESET}  ${ICON_CHECK}  Verify my solution"
  echo -e "  ${RED}[C]${RESET}  ${ICON_BROOM}  Cleanup scenario"
  echo -e "  ${GRAY}[B]${RESET}       Back"
  echo ""
  echo -ne "  ${BOLD}> ${RESET}"
}

confirm_action() {
  echo -ne "  ${YELLOW}$1 (y/n): ${RESET}"
  local a
  read -r a
  [[ "$a" =~ ^[Yy]$ ]]
}
