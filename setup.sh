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

# Make zsh regex match behave like bash rematch
#setopt bash_rematch

SCRIPT_NAME=$(basename "${0}")

SUCCESS=0
ERROR=1

declare -A ssh_options

# if REMOTE_SERVER is defined, then the script will send the setup commands to
# the remote server name
REMOTE_SERVER=labs

run()
{
  if [[ -n "${REMOTE_SERVER}" ]]; then
    ssh -q "${REMOTE_SERVER}" "${1}" > /dev/null
  else
    eval "${1}"
  fi
}

copy_if_remote()
{
  if [[ -n "${REMOTE_SERVER}" ]]; then
    scp "${1}" "${REMOTE_SERVER}:${2}" > /dev/null
  fi
}

copy()
{
  if [[ ! -z "${REMOTE_SERVER}" ]]; then
    scp "${1}" "${REMOTE_SERVER}:${2}" 
  else
    cp "${1}" "${2}"
  fi
}

## Install ZSH

install_zsh()
{
  echo "Installing zsh using dnf"
  run "sudo dnf -y install zsh > /dev/null"
  echo "Downloading oh my zsh!"
  run "curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o ./install.sh"
  run "sh install.sh"
  echo "Cloning powerlevel10k"
  run "git clone \-\-depth=1 https://github.com/romkatv/powerlevel10k.git \${ZSH_CUSTOM:-\$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
  echo "Copying sed.sh"
  copy_if_remote resources/sed.sh sed.sh
  echo "Runing sed.sh"
  run "sh sed.sh"
  echo "Copying .10k.zsh"
  copy_if_remote resources/.p10k.zsh .p10k.zsh
  echo "Copying .vimrc"
  copy_if_remote resources/.vimrc .vimrc
  echo "Copying .zshrc"
  copy_if_remote resources/.zshrc .zshrc
  run "sudo chsh student -s /usr/bin/zsh"
}

## Configure ~/.ssh/config

_set_arg()
{
  if [[ -z "${1}" ]]; then
    echo ""
  else
    echo "${1}"
  fi
}

parse_ssh_options()
{
  local sshconfig_example
  local orig_string
  local regex

  sshconfig_example="\"ssh -i ~/.ssh/rht_classroom.rsa -J cloud-user@55.60.13.103:22022 student@172.25.252.1 -p 53009\""
  orig_string="${1}"

  # convert string into an string array
  # sorry shellcheck, I actually want to split here! No quotes for you!
  # shellcheck disable=SC2206
  arg_array=(${orig_string})

  # check to ensure there are 8 elements
  if [[ "${#arg_array[@]}" -ne 8 ]]; then
    echo "ERROR: The string passed to --sshconfig looks incorrect."
    echo "       There should be eight (8) parameters in the string."
    echo "       Ensure it is surrounded by quotes."
    echo "USAGE: ${SCRIPT_NAME} --sshconfig ${sshconfig_example}"
    exit "${ERROR}"
  fi

  local id_rsa
  local arg_jump_server
  local arg_dest_server

  local dest_server_port
  local dest_server_hostname
  local dest_server_username

  local jump_server_username
  local jump_server_port
  local jump_server_hostname

  local arg_num_id_rsa
  local arg_num_jump_server
  local arg_num_dest_server
  local arg_num_dest_port

  arg_num_id_rsa=2
  arg_num_jump_server=4
  arg_num_dest_server=5
  arg_num_dest_port=7

  id_rsa="${arg_array[${arg_num_id_rsa}]}"
  arg_jump_server="${arg_array[${arg_num_jump_server}]}"
  arg_dest_server="${arg_array[${arg_num_dest_server}]}"
  dest_server_port="${arg_array[${arg_num_dest_port}]}"

  # parse jump server argument using regex
  regex="([a-zA-Z_-]+)@([0-9\.]+)\:([0-9]+)"

  if [[ "${arg_jump_server}" =~ ${regex} ]]; then
    jump_server_username="${BASH_REMATCH[1]}"
    jump_server_hostname="${BASH_REMATCH[2]}"
    jump_server_port="${BASH_REMATCH[3]}"
  else
    echo "ERROR: Could not parse the jump server."
    echo "       Found: \"${arg_jump_server}\""
    echo "       Must be in this format: user@address:port"
    echo "       Example: cloud-server:55.60.13.103:22022"
    exit "${ERROR}"
  fi

  # parse dest server argument using regex
  regex="([a-zA-Z_-]+)@([0-9\.]+)"

  if [[ "${arg_dest_server}" =~ ${regex} ]]; then
    dest_server_username="${BASH_REMATCH[1]}"
    dest_server_hostname="${BASH_REMATCH[2]}"
  else
    echo "ERROR: Could not parse the destination server."
    echo "       Must be in this format: user@address"
    echo "       Example: student@172.25.252.1"
    exit "${ERROR}"
  fi

  # check if dest port looks like a port number
  regex="[0-9]+"

  if [[ ! "${dest_server_port}" =~ ${regex} ]]; then
    echo "ERROR: Could not parse the destination port number."
    echo "       Must be a number!"
    echo "       Example: 53009"
    exit "${ERROR}"
  fi

  ssh_t=$(cat <<-EOF
### _GENERATED_BY_SSH_SETUP_SCRIPT_START_ ###
Host labs
  StrictHostKeyChecking no
  HostName _DEST_SERVER_HOSTNAME_
  Port _DEST_SERVER_PORT_
  IdentityFile _ID_RSA_
  ProxyJump _JUMP_SERVER_USERNAME_@_JUMP_SERVER_HOSTNAME_:_JUMP_SERVER_PORT_
  User _DEST_SERVER_USERNAME_
### _GENERATED_BY_SSH_SETUP_SCRIPT_END_ ###
EOF
)

  # time to fill in our template

  ssh_t="${ssh_t//_DEST_SERVER_HOSTNAME_/${dest_server_hostname}}"
  ssh_t="${ssh_t//_DEST_SERVER_PORT_/${dest_server_port}}"
  ssh_t="${ssh_t//_ID_RSA_/${id_rsa}}"
  ssh_t="${ssh_t//_JUMP_SERVER_USERNAME_/${jump_server_username}}"
  ssh_t="${ssh_t//_JUMP_SERVER_HOSTNAME_/${jump_server_hostname}}"
  ssh_t="${ssh_t//_JUMP_SERVER_PORT_/${jump_server_port}}"
  ssh_t="${ssh_t//_DEST_SERVER_USERNAME_/${dest_server_username}}"

  sed -i -e '/### _GENERATED_BY_SSH_SETUP_SCRIPT_START_ ###/,/### _GENERATED_BY_SSH_SETUP_SCRIPT_END_ ###/d' ~/.ssh/config

  echo "${ssh_t}" >> ~/.ssh/config

  echo "Successfully added the jump server configuration in your ~/.ssh/config file"
  echo "Type: 'ssh labs' to connect"

  host_count=$(sed -ne "/^\[${dest_server_hostname}\]\:${dest_server_port}/p" ~/.ssh/known_hosts | wc -l)

  if [[ ${host_count} -gt 0 ]]; then
    echo "There are $host_count references of ${dest_server_hostname}:${dest_server_port} in ~/.ssh/known_hosts"
    echo "  Remove ALL references to ${dest_server_hostname}:${dest_server_port} in ~/.ssh/known_hosts?"
    echo "  This is recommended so you don't get host key warnings."
    echo -n "  [Y/n]: "
    read -r -n1 ans
    echo ""
    if [[ "${ans}" != "n" ]]; then
      echo "Creating backup ~/.ssh/known_hosts.bak"
      sed -i.bak -e "/^\[${dest_server_hostname}\]\:${dest_server_port}/d " ~/.ssh/known_hosts
    fi

    # Do a final check
    host_count=$(sed -ne "/^\[${dest_server_hostname}\]\:${dest_server_port}/p" ~/.ssh/known_hosts | wc -l)
    if [[ ${host_count} -eq 0 ]]; then
      echo "Removed all references of ${dest_server_hostname}:${dest_server_port} in ~/.ssh/known_hosts"
    else
      echo "WARNING: Could not remove all references to ${dest_server_hostname}:${dest_server_port}"
      echo "         Post-check still reports ${host_count} references left in ~/.ssh/known_hosts"
    fi
  fi

  echo "Would you like to run the oh my zsh setup on the remote labs host?"
  echo -n "[Y/n]: "
  read -r -n1 ans
  echo ""
  if [[ "${ans}" != "n" ]]; then
    install_zsh
  fi
}

configure_ssh_config()
{
  local ssh_options
  ssh_options="${1}"

  if [[ -z "${REMOTE_SERVER}" ]]; then
    return
  fi

  parse_ssh_options "${ssh_options}"
}

options()
{
  local arg1
  local arg2
  arg1=$(_set_arg "${1}")
  arg2=$(_set_arg "${2}")

  case "${arg1}" in
    "--sshconfig")
      configure_ssh_config "${arg2}"
    ;;
    "--remote")
      if [[ -z "${arg2}" ]]; then
        echo "You must provide a server name after --remote parameter"
        echo "Example: ${SCRIPT_NAME} --remote 50.1.1.1"
        exit "${ERROR}"
      fi
      REMOTE_SERVER="${arg2}"
      install_zsh
    ;;
    # if anything else, then just install zsh as normal
    *)
      install_zsh "${arg1}"
    ;;
  esac
}

### MAIN #######################################################################

options "${@}"
exit "${SUCCESS}"
