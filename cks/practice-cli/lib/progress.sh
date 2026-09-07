#!/usr/bin/env bash
# Progress tracking. State lives in $CKS_STATE_DIR so nothing runtime-generated
# lands inside the repo. Requires lib/questions.sh and lib/colors.sh.
PROGRESS_FILE="$CKS_STATE_DIR/.progress"

mark_complete() { is_complete "$1" || echo "$1" >> "$PROGRESS_FILE"; }
is_complete()   { [[ -f "$PROGRESS_FILE" ]] && grep -qx "$1" "$PROGRESS_FILE"; }

get_completed_count() {
  if [[ -f "$PROGRESS_FILE" ]]; then wc -l < "$PROGRESS_FILE" | tr -d ' '; else echo 0; fi
}

get_random_incomplete() {
  local incomplete=() q id
  for q in "${QUESTIONS[@]}"; do
    id=$(get_question_id "$q")
    is_complete "$id" || incomplete+=("$id")
  done
  [[ ${#incomplete[@]} -eq 0 ]] && return 1
  echo "${incomplete[$(( RANDOM % ${#incomplete[@]} ))]}"
}

show_progress() {
  local total=${#QUESTIONS[@]} completed pct=0 bar="" i filled empty
  completed=$(get_completed_count)
  (( total > 0 )) && pct=$(( completed * 100 / total ))
  filled=$(( pct * 30 / 100 )); empty=$(( 30 - filled ))
  for (( i=0; i<filled; i++ )); do bar="${bar}█"; done
  for (( i=0; i<empty; i++ )); do bar="${bar}░"; done

  echo ""
  print_header "${ICON_MEDAL} Progress Tracker"
  echo -e "  ${BOLD}${WHITE}Overall: ${completed}/${total} (${pct}%)${RESET}"
  echo -e "  ${GREEN}${bar}${RESET}"
  echo ""

  local d ds dname dc dtotal dcompleted q qid
  for d in "D1|Cluster Setup" \
           "D2|Cluster Hardening" \
           "D3|System Hardening" \
           "D4|Minimize Microservice Vulnerabilities" \
           "D5|Supply Chain Security" \
           "D6|Monitoring, Logging and Runtime Security"; do
    ds="${d%%|*}"; dname="${d#*|}"
    dc=$(get_domain_color "$ds")
    dtotal=0; dcompleted=0
    for q in "${QUESTIONS[@]}"; do
      if [[ "$(get_question_domain_short "$q")" == "$ds" ]]; then
        dtotal=$(( dtotal + 1 ))
        qid=$(get_question_id "$q")
        is_complete "$qid" && dcompleted=$(( dcompleted + 1 ))
      fi
    done
    printf "  ${dc}%-42s${RESET} %d/%d\n" "$dname" "$dcompleted" "$dtotal"
  done
  echo ""
}
