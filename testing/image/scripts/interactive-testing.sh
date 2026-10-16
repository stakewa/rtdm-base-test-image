#!/usr/bin/env bash
#
# Copyright (c) 2026 Daaf Wassenaar
# License: MIT
#

cleanup() {
  tput cnorm 2>/dev/null || true  # Show cursor
  tput rmcup 2>/dev/null || true  # Restore previous screen
}

# Enter alternate screen, hide cursor, and clear the display.
tput smcup
tput civis
tput clear
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

json="tests.json"
total=$(jq 'length' "$json") || exit 1
statuses=()

show_summary() {
  local upto=$1
  local j title

  echo "Progress:"

  if (( upto == 0 )); then
    echo "  No tests completed yet."
    return
  fi

  for ((j = 0; j < upto; j++)); do
    title=$(jq -r ".[$j].title" "$json")
    echo "  $((j + 1))/$total $title — ${statuses[j]}"
  done
}

show_test() {
  local index=$1
  local title=$2
  local description=$3

  echo
  show_summary "$index"
  echo
  echo "--- $((index + 1))/$total: $title ---"
  echo "[$((index + 1))/$total] $description"
}

for ((i = 0; i < total; i++)); do
  title=$(jq -r ".[$i].title" "$json")
  description=$(jq -r ".[$i].description" "$json")
  script=$(jq -r ".[$i].script // \"\"" "$json")
  question=$(jq -r ".[$i].question // \"\"" "$json")

  while true; do
    show_test "$i" "$title" "$description"

    if [[ -n "$script" ]]; then
      read -r -p "Press Enter to run test: "
      clear # Clear screen before running script
      bash "$script"
      show_test "$i" "$title" "$description"
    fi

    while true; do
      if [[ -n "$question" ]]; then
        echo "Question: $question"
      fi

      read -r -p "Pass? [y = pass, n = fail, r = run again, q = quit] " answer
      case "$answer" in
        y|Y) statuses[i]="PASSED"; break 2 ;;
        n|N) statuses[i]="FAILED"; break 2 ;;
        r|R) break ;;
        q|Q) exit 0 ;;
        *) echo "Please enter y, n, r, or q." ;;
      esac
    done
  done
done

echo
echo "Final summary:"
for ((i = 0; i < total; i++)); do
  title=$(jq -r ".[$i].title" "$json")
  echo "  $((i + 1))/$total $title — ${statuses[i]:-NOT RUN}"
done

read -r -p "Press Enter to close..."
