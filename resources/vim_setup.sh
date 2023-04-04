#!/usr/bin/env bash
################################################################################
# VIM Installer and Setup Script
# Copyright (C) 2023  Ryan M. Clements

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
################################################################################
# Author: Ryan Clements
# Email: rclement@redhat.com
#
# vimrc setup
#
# To add new plugs or themes, just add them to the arrays below
#
################################################################################
#
### HELPER SCRIPTS #############################################################
#
# Load ANSI colors
source /opt/helper_scripts/ansi_colors.sh > /dev/null 2>&1

### CONSTANTS ##################################################################

## PLUGINS
PLUGIN_INSTALL_PATH="${HOME}/.vim/pack/vendor/start"

# indent lines with nice characters instead of spaces
# configure options in your ~/.vimrc
PLUGIN_NAMES=("indentLine"
              )              
PLUGIN_URLS=("https://github.com/Yggdroot/indentLine.git" # indentLine
             )

## THEMES
THEME_INSTALL_PATH="${HOME}/.vim/pack/themes/start"

# vscode inspired colors. Toggle off and on in ~/.vimrc. Default is on.
THEME_NAMES=("vim-code-dark"
            )
THEME_URLS=("https://github.com/tomasiser/vim-code-dark" # vim-code-dark
           )

## CODES
INFO=0
ERROR=1

SCRIPT_PATH="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"

### FUNCTIONS ##################################################################

## Formating functions
center()
{
  local total_space
  local pre_color
  local padding
  
  total_space="${2}"
  pre_color="${3}"
  padding="$(printf '%0.1s' .{1..500})"
  
  printf "${C[black_bold]}%*.*s ${pre_color}%s ${C[black_bold]}%*.*s\n" 0 "$(((total_space-2-${#1})/2))" "${padding}" "${1}" 0 "$(((total_space-1-${#1})/2))" "${padding}"
}

log()
{
  local level=${1}
  local pre_msg=${2}
  local post_msg=${3}

  local pre_color
  local post_color

  case ${level} in
    ERROR)
      pre_color="${C[red_bold]}"
      post_color="${C[red]}"
      ;;
    *)
      pre_color="${C[green]}"
      post_color="${C[reset]}"
  esac

  pre_msg_centered="$(center "${pre_msg}" 15 $pre_color)"
  pre_msg_final="${C[black_bold]}[${C[green]}${pre_msg_centered}${C[black_bold]}]"
  post_msg_final="${post_color}${post_msg}"

  echo -e "$pre_msg_final ${post_msg_final}"
}

join () {
    echo "$(IFS=; echo "$*")"
}

### MAIN CODE ##################################################################

log INFO \
    "script start" \
    "$(join "Executing: " \
    "${C[reset]}${C[magenta]}[${C[cyan_bold]}" \
    "${SCRIPT_PATH}${C[reset]}${C[magenta]}]")"
log INFO "vim plugins" "${C[yellow]}Installing/updating plugins"

# Loop through all the plugins
for num in "${PLUGIN_NAMES[@]}"
do
  _plugin_path="${PLUGIN_INSTALL_PATH}/${PLUGIN_NAMES[${num}]}"

  # does the plugin's path exist?
  if [[ -d "${_plugin_path}" ]]
  then
    # if it exists, attempt a new pull
    git_msg="$(git -C "${_plugin_path}" pull)" ||
    {
      log ERROR "vim plugins" "$(join "  Could not pull ${PLUGIN_NAMES[${num}]}"\
                              "from ${PLUGIN_URLS[${num}]}")"
      log ERROR "git" "  - ${git_msg}"
    } &&
    {
      log INFO "vim plugins" "$(join "  Refreshing ${C[cyan]}"\
                             "${PLUGIN_NAMES[${num}]}${C[reset]} from "\
                             "${C[cyan]}${PLUGIN_URLS[${num}]}")"
      log INFO "git" "  - ${git_msg}"
    }
  else
    # if doesn't exist, clone it
    git_msg="$(git clone "${PLUGIN_URLS[${num}]}" "${_plugin_path}")" ||
    {
      log ERROR "vim plugins" "$(join "  Could not clone ${PLUGIN_NAMES[${num}]}"\
                              " from ${PLUGIN_URLS[${num}]}")"
      log ERROR "git" "  - ${git_msg}"
    } &&
    {
      log INFO "vim plugins" "$(join "  Installed ${PLUGIN_NAMES[${num}]} "\
                             "from ${PLUGIN_URLS[${num}]}")"
      log INFO "git" "  - ${git_msg}"
    }
    
  fi                                                                                                                                                   

  # add help
  vim -u NONE \
    -c "helptags" \
    "${_plugin_path}/doc" \
    -c "q"
done

log INFO "vim themes" "${C[yellow]}Installing/updating themes"

# loop through all the themes
for num in "${THEME_NAMES[@]}"
do
  _theme_path="${THEME_INSTALL_PATH}/${THEME_NAMES[${num}]}"

  if [[ -d "${_theme_path}" ]]
  then
    # if it exists, attempt a new pull
    git_msg="$(git -C "${_theme_path}" pull)" ||
    {
      log ERROR \
          "vim themes" \
          "$(join "  Could not pull ${THEME_NAMES[${num}]} from "\
          "${THEME_URLS[${num}]}")"
              
      log ERROR "git" "  - ${git_msg}"
    } &&
    {
      log INFO \
          "vim plugins" \
          "$(join "  Refreshing ${C[cyan]}${THEME_NAMES[${num}]} ${C[reset]}from"\
          " ${C[cyan]}${THEME_URLS[${num}]}")"
      log INFO "git" "  - ${git_msg}"
    }
  else
    git_msg="$(git clone "${THEME_URLS[${num}]}" "${_theme_path}")" ||
    {
      log ERROR \
          "vim plugins" \
          "$(join "  Could not clone ${THEME_NAMES[${num}]} "\
          "from ${THEME_URLS[${num}]}")"
      log ERROR "git" "  - ${git_msg}"
    } &&
    {
      log INFO \
          "vim plugins" \
          "$(join "  Installed ${C[cyan]}${THEME_NAMES[${num}]} "\
          "from ${THEME_URLS[${num}]}")"
    }
  fi                                                                                                                                                   
done

log INFO \
    "script done" \
    "$(join "Complete: " \
    "${C[reset]}${C[magenta]}[${C[cyan_bold]}" \
    "${SCRIPT_PATH}${C[reset]}${C[magenta]}]")"
