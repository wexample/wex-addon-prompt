#!/usr/bin/env bash

promptChoiceGetValueArgs() {
  _DESCRIPTION="Get the interactively chosen value by user"
}

promptChoiceGetValue() {
  wex-exec var/get -n=CHOICE_SELECTED_VALUE
}
