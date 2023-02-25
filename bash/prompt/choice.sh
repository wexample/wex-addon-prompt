#!/usr/bin/env bash

promptChoiceArgs() {
  # shellcheck disable=SC2034
  _ARGUMENTS=(
    'choices c "Choices array" true'
    'question q "Question to ask" true "Choose a value (number / arrows)"'
    'separator s "Separator for choices splitting" true ,'
    'default d "Default value index" false 0'
  )
}

promptChoice() {
  local CHOICE_BACKSPACE
  local CHOICE_ESCAPE
  local CHOICE_SELECTED=${DEFAULT}

  wex-exec var/clear -n=CHOICE_TYPED_SELECTION

  if [ -z "${CHOICES}" ]; then
    _wexLog "No dump found."
    return
  fi

  # Split and fill up array
  mapfile -t CHOICES < <(wex-exec default::string/split -t="${CHOICES}")

  CHOICE_BACKSPACE=$(
    cat <<eof
0000000 005177
0000002
eof
  )

  CHOICE_ESCAPE=$(printf "\u1b")

  _promptChoiceRender
}

_promptChoiceRender() {
  local COUNTER=0

  echo ""

  for ITEM in "${CHOICES[@]}"; do
    ((COUNTER++))
    local LINE="\033[K    "

    if [ "${COUNTER}" = "${CHOICE_SELECTED}" ]; then
      LINE+="${WEX_COLOR_WHITE}${COUNTER}${WEX_COLOR_GRAY} >> ${WEX_COLOR_YELLOW}\033[1m"
    else
      LINE+="${WEX_COLOR_GRAY}${COUNTER} > ${WEX_COLOR_RESET}"
    fi

    printf "${LINE}%s\n" "${ITEM}"
  done

  printf "%b" "${WEX_COLOR_CYAN}"

  local CHOICE_SELECTED_DISPLAY=${CHOICE_SELECTED}
  # Hide zero from display
  if [ "${CHOICE_SELECTED}" = "0" ]; then
    CHOICE_SELECTED_DISPLAY=""
  fi

  echo ""

  read -rsn 1 -p "$(echo -e "${QUESTION} ${WEX_COLOR_RESET}${CHOICE_SELECTED_DISPLAY}   ")" ARROW

  if [ "$(echo "$ARROW" | od)" = "${CHOICE_BACKSPACE}" ]; then
    CHOICE_SELECTED=${CHOICE_SELECTED%?}
    _promptChoiceUpdate
  fi

  if [ "${ARROW}" = "${CHOICE_ESCAPE}" ]; then
    read -rsn 2 ARROW # read 2 more chars
  fi
  case ${ARROW} in
  '[A')
    ((CHOICE_SELECTED--))

    if [ ${CHOICE_SELECTED} -le 0 ]; then
      CHOICE_SELECTED=0
    fi

    _promptChoiceUpdate
    ;;
  '[B')
    ((CHOICE_SELECTED++))

    if [ ${CHOICE_SELECTED} -ge ${#CHOICES[@]} ]; then
      CHOICE_SELECTED=${#CHOICES[@]}
    fi

    _promptChoiceUpdate
    ;;
  *[0-9]*)
    if [ "${CHOICE_SELECTED}" = "0" ]; then
      CHOICE_SELECTED=""
    fi

    CHOICE_SELECTED+=${ARROW}

    if [ "${CHOICE_SELECTED}" -ge $((${#CHOICES[@]} + 1)) ]; then
      CHOICE_SELECTED=0
    fi

    _promptChoiceUpdate
    ;;
  *)
    if [ "${ARROW}" = "" ]; then
      echo ""
      echo ""

      local INDEX=$((CHOICE_SELECTED - 1))
      # Save selected values for further usage.
      wex-exec var/set -n=CHOICE_SELECTED_INDEX -v="${CHOICE_SELECTED}"
      wex-exec var/set -n=CHOICE_SELECTED_VALUE -v="\"${CHOICES[${INDEX}]}\""

      return
    else
      local TYPED_SELECTION

      COUNTER=0
      CHOICE_SELECTED=
      TYPED_SELECTION="$(wex-exec var/get -n=CHOICE_TYPED_SELECTION)${ARROW}"

      for ITEM in ${CHOICES[@]}; do
        ((COUNTER++))

        if [[ "${ITEM}" = "${TYPED_SELECTION}"* ]]; then
          CHOICE_SELECTED=${COUNTER}
        fi
      done

      if [ -n "${CHOICE_SELECTED}" ]; then
        wex-exec var/set -n=CHOICE_TYPED_SELECTION -v="${TYPED_SELECTION}"
      else
        wex-exec var/clear -n=CHOICE_TYPED_SELECTION
      fi

      _promptChoiceUpdate
    fi
    ;;
  esac
}

_promptChoiceUpdate() {
  local JUMP
  JUMP=$((${#CHOICES[@]} + 2))

  # Move cursor up
  printf "\033[%sA" "${JUMP}"

  printf "\r"

  _promptChoiceRender
}
