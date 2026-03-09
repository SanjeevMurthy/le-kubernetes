#!/usr/bin/env bash
# ─── Progress Tracking ───────────────────────────────────────────

PROGRESS_FILE="$SCRIPT_DIR/.progress"

mark_complete() {
  local qid="$1"
  if ! is_complete "$qid"; then
    echo "$qid" >> "$PROGRESS_FILE"
  fi
}

is_complete() {
  local qid="$1"
  [[ -f "$PROGRESS_FILE" ]] && grep -qx "$qid" "$PROGRESS_FILE"
}

get_completed_count() {
  if [[ -f "$PROGRESS_FILE" ]]; then
    wc -l < "$PROGRESS_FILE" | tr -d ' '
  else
    echo "0"
  fi
}

get_random_incomplete() {
  local incomplete=()
  for q in "${QUESTIONS[@]}"; do
    local id
    id=$(get_question_id "$q")
    if ! is_complete "$id"; then
      incomplete+=("$id")
    fi
  done
  if [[ ${#incomplete[@]} -eq 0 ]]; then
    echo ""
    return 1
  fi
  local idx=$(( RANDOM % ${#incomplete[@]} ))
  echo "${incomplete[$idx]}"
}

show_progress() {
  local total=${#QUESTIONS[@]}
  local completed
  completed=$(get_completed_count)
  local pct=0
  if (( total > 0 )); then
    pct=$(( completed * 100 / total ))
  fi

  echo ""
  print_header "${ICON_MEDAL} Progress Tracker"

  # Progress bar
  local bar_width=30
  local filled=$(( pct * bar_width / 100 ))
  local empty=$(( bar_width - filled ))
  local bar=""
  for (( i=0; i<filled; i++ )); do bar+="█"; done
  for (( i=0; i<empty; i++ )); do bar+="░"; done

  echo -e "  ${BOLD}${WHITE}Overall: ${completed}/${total} (${pct}%)${RESET}"
  echo -e "  ${GREEN}${bar}${RESET}"
  echo ""

  # Per-domain breakdown
  local domains=("D1|Application Design and Build" "D2|Application Deployment" "D3|Application Environment, Configuration and Security" "D4|Services and Networking" "D5|Application Observability and Maintenance")
  for d in "${domains[@]}"; do
    local ds="${d%%|*}"
    local dname="${d#*|}"
    local dc
    dc=$(get_domain_color "$ds")
    local dtotal=0
    local dcompleted=0
    for q in "${QUESTIONS[@]}"; do
      local qds
      qds=$(get_question_domain_short "$q")
      if [[ "$qds" == "$ds" ]]; then
        ((dtotal++))
        local qid
        qid=$(get_question_id "$q")
        if is_complete "$qid"; then
          ((dcompleted++))
        fi
      fi
    done
    printf "  ${dc}%-50s${RESET} %d/%d\n" "$dname" "$dcompleted" "$dtotal"
  done
  echo ""
}
