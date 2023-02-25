#!/usr/bin/env bash

promptYnArgs() {
  _DESCRIPTION="Ask user to choose yes or no"
  # shellcheck disable=SC2034
  _ARGUMENTS=(
    'question q "Question to ask user" true'
  )
}

promptYn() {
  while true; do
    read -rp "$(echo -e "${WEX_COLOR_CYAN}${QUESTION} ${WEX_COLOR_GRAY}[Y/n]${WEX_COLOR_RESET}: ")" yn
    case $yn in
    [Nn]*)
      echo false
      break
      ;;
    [Yy]*)
      echo true
      break
      ;;
    "")
      echo true
      break
      ;;
    *)
      wex-exec prompt/yn -q="${QUESTION}"
      break
      ;;
    esac
  done
}
