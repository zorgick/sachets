#!/bin/bash
. "$(dirname "$0")/tokens.sh"

command_exists () {
  command -v "$1" > /dev/null 2>&1
}

# Workaround for Windows, when using yarn for scripts
if command_exists winpty && test -t 1; then
  exec < /dev/tty
fi

log() {
  local effect
  local hook
  [ ! -z $3 ] && hook="[${3##*/} hook] " || hook=""
  case $1 in
    error) effect="${WHITE}${ON_RED} ERROR ${COLOR_OFF} ";;
    info) effect="${WHITE}${ON_BLUE} INFO ${COLOR_OFF} ";;
    success) effect="${WHITE}${ON_GREEN} SUCCESS ${COLOR_OFF} ";;
    under) effect="${UNDER}";;
    * ) effect="${1}";;
  esac
  echo -e "\n${effect}${hook}${2}${COLOR_OFF}\n"
}
