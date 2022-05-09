#!/bin/bash
. "$(dirname "$0")/tokens.sh"
. "$(dirname "$0")/common.sh"
declare -xg MENU_RESULT=-1

##
# BASH only string to hex
str2hex_echo() {
  # USAGE: hex_repr=$(str2hex_echo "ABC")
  #        returns "0x410x420x43"
  local str=${1:-$(cat -)}
  local fmt=""
  local chr
  local -i i
  printf "0x"
  for i in `seq 0 $((${#str}-1))`; do
    chr=${str:i:1}
    printf  "%x" "'${chr}"
  done
}

##
# Read key and map to human readable output
#
# notes
#  output prefix (concated by `-`)
#    c    ctrl key
#    a    alt key
#    c-a  ctrl+alt key
#  use F if you mean shift!
#  uppercase `f` for `c+a` combination is not possible!
#
# arguments
#  -d           for debugging keycodes (hex output via xxd)
#  -l           lowercase all chars
#  -l <timeout> timeout
#
# stdout
#   mapped key code like in notes
ui_key_input() {
  local key
  local ord
  local debug=0
  local lowercase=0
  local prefix=''
  local args=()
  local opt

  while (( "$#" )); do
    opt="${1}"
    shift
    case "${opt}" in
      "-d") debug=1;;
      "-l") lowercase=1;;
      "-t") args+=(-t $1); shift;;
    esac
  done
  IFS= read ${args[@]} -rsn1 key 2>/dev/null >&2
  read -sN1 -t 0.0001 k1; read -sN1 -t 0.0001 k2; read -sN1 -t 0.0001 k3
  key+="${k1}${k2}${k3}"
  if [[ "${debug}" -eq 1 ]]; then echo -n "${key}" | str2hex_echo; echo -n " : " ;fi;
    case "${key}" in
      '') key=enter;;
      $'\x1b') key=esc;;
      $'\x1b\x5b\x36\x7e') key=pgdown;;
      $'\x1b\x5b\x33\x7e') key=erase;;
      $'\x7f') key=backspace;;
      $'\e[A'|$'\e0A  '|$'\e[D'|$'\e0D') key=up;;
      $'\e[B'|$'\e0B'|$'\e[C'|$'\e0C') key=down;;
      $'\e[1~'|$'\e0H'|$'\e[H') key=home;;
      $'\e[4~'|$'\e0F'|$'\e[F') key=end;;
      $'\e') key=enter;;
      $'\e'?) prefix="a-"; key="${key:1:1}";; 
    esac

    # only lowercase if we have a single letter
    # ctrl key is hidden within char code (no o)
    if [[ "${#key}" == 1 ]]; then
      ord=$(LC_CTYPE=C printf '%d' "'${key}")
      if [[ "${ord}" -lt 32 ]]; then
        prefix="c-${prefix}"
        ord="$(printf "%X" $((ord + 0x60)))"
        key="$(printf "\x${ord}")"
      fi       
      if [[ "${lowercase}" -eq 1 ]]; then
        key="${key,,}"
      fi
    fi

    echo "${prefix}${key}"
  }

##
# draws menu in three different states
# - initial: draw every line as intenden
# - update: only draw updated lines and skip existing
# - exit: only draw selected lines
draw_menu() {
  local mode="${initial:-$1}" 
  local check=false
  local check_tpl=""
  local str=""
  local msg=""
  local tpl_selected="${WHITE}${ON_GREEN}→  %s${COLOR_OFF}"
  local tpl_default="   %s %s"
  local marg=()

  if ${drawn} && [[ "$mode" != "exit" ]]; then 
    # reset position
    str+="\r\e[2K"
    for i in "${menu[@]}"; do str+="\e[1A"; done
  fi

  for ((i=0;i<${#menu[@]};i++)); do
    check=false
    marg=("${menu[${i}]}")
    if [[ ${cur} == ${i} ]]; then
      check=true
    fi
    if [[ "${mode}" != "exit" ]] && [[ ${cur} == ${i} ]]; then
      str+="$(printf "\e[2K${tpl_selected}" "${marg[@]}")\n";
    elif ([[ "${mode}" != "exit" ]] && ([[ "${oldcur}" == "${i}" ]] || [[ "${mode}" == "initial" ]])) || (${check} && [[ "${mode}" == "exit" ]]); then
      str+="$(printf "\e[2K${tpl_default}" "${marg[@]}")\n";
    elif [[ "${mode}" -eq "update" ]] && [[ "${mode}" != "exit" ]]; then
      str+="\e[1B\r"
    fi
  done
  echo -en "${str}"
  export drawn=true
}

##
# UI Widget Select
#
# arguments
#  -i <[menu-item(s)] …>      menu items
#  -k <[key(s)] …>            keys for menu items (if none given indexes are used)
#  -c                         clear complete menu on exit
#  -l                         clear menu and leave selections
#   
#  MENU_RESULT will be selected index / key or -1
#
# return
#   0  success
#  -1  cancelled 
ui_widget_select() {
  local menu=() keys=()
  local cur=0 oldcur=0 collect="item"
  local marg="" drawn=false
  local should_clear_onexit=false should_leave_onexit=false
  export MENU_RESULT=-1
  while (( "$#" )); do
    opt="${1}"; shift
    case "${opt}" in
      -k) collect="key";;
      -i) collect="item";;
      -l) should_clear_onexit=true; should_leave_onexit=true;;
      -c) should_clear_onexit=true;;
      *)
        if [[ "${collect}" == "key" ]]; then
          keys+=("${opt}")
        else
          menu+=("$opt")
        fi;;
      esac
    done

    # exit if items are empty
    if [[ "${#menu[@]}" -eq 0 ]]; then
      >&2 log error "No menu items given."
      return 1
    fi

    # if keys are used, use them
    if [[ "${#keys[@]}" -gt 0 ]]; then
      if [[ "${#keys[@]}" -gt 0 ]] && [[ "${#keys[@]}" != "${#menu[@]}" ]]; then
        >&2 log error "Number of keys do not match menu options."
        return 1
      fi
    fi

    clear_menu() {
      # clear previous lines and menu lines
      local str="${CLEAR_LINE}${CLEAR_LINE}${CLEAR_LINE}"
      for i in "${menu[@]}"; do str+="${CLEAR_LINE}"; done
      echo -en "${str}"
    }


    # initial draw
    draw_menu initial 

    # action loop
    while true; do
      oldcur=${cur}
      key=$(ui_key_input)
      case "${key}" in
        up|k|h) ((cur > 0)) && ((cur--));;
        down|j|l) ((cur < ${#menu[@]}-1)) && ((cur++));;
        home)  cur=0;;
        u) 
          let cur-=5 
          if [[ "${cur}" -lt 0 ]]; then 
            cur=0 
          fi;;
        d) 
          let cur+=5 
          if [[ "${cur}" -gt $((${#menu[@]}-1)) ]]; then 
            cur=$((${#menu[@]}-1)) 
          fi;;
        end) ((cur=${#menu[@]}-1));;
        enter)
          if [[ "${#keys[@]}" -gt 0 ]]; then
            export MENU_RESULT="${keys[${cur}]}";
          else
            export MENU_RESULT=${cur};
          fi 
          if $should_clear_onexit; then clear_menu; fi
          if $should_leave_onexit; then draw_menu initial; fi
          return
          ;;
        esc|q|$'\e')
          if $should_clear_onexit; then clear_menu; fi
          return 1;;
      esac

      # Redraw menu
      draw_menu update
      done
    }

# Uncomment for key probing
# while [[ true ]]; do
#   ui_key_input -d
# done

# Uncomment for testing
# . "$(dirname "$0")/vars.sh"
# log under "Choose type:";
# tput rmam;
# ui_widget_select -c -k "${!TYPES[@]}" -i "${TYPES[@]}"
# tput smam;
# log info "Selected type: ${MENU_RESULT}";
