#!/usr/bin/env bash
# -*- encoding: utf-8 -*-
###############################################################################
#
# Copyright (c) 2023 Ryan Clements
# Author: Ryan M. Clements
# LinkedIn: https://www.linkedin.com/in/ryan-clements-rhce/
# License: https://www.gnu.org/licenses/gpl-3.0.html
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
###############################################################################

# if REMOTE_SERVER is defined, then the script will send the setup commands to
# the remote server name
REMOTE_SERVER=labs

run()
{
  if [[ -z "${REMOTE_SERVER}" ]]; then
    ssh -q "${REMOTE_SERVER}" "${1}"
  else
    eval "${1}"
  fi
}

copy_if_remote()
{
  if [[ -z "${REMOTE_SERVER}" ]]; then
    scp "${1}" "${REMOTE_SERVER}:${2}" 
  fi
}

copy()
{
  if [[ -z "${REMOTE_SERVER}" ]]; then
    scp "${1}" "${REMOTE_SERVER}:${2}" 
  else
    cp "${1}" "${2}"
  fi
}

run "sudo dnf -y install zsh"
run "curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O install.sh"
run "sh install.sh"
run 'git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k'
copy_if_remote sed.sh sed.sh
run "-q 'sh sed.sh'"
copy_if_remote .p10k.zsh .p10k.zsh
copy_if_remote .vimrc .vimrc

