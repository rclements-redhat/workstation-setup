#!/usr/bin/env bash
# -*- encoding: utf-8 -*-
###############################################################################
#
# Copyright (c) 2023 Ryan M. Clements
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

# Make zsh regex match behave like bash rematch. Only uncomment this if you
# change the shebang to zsh because bash isn't available. regex matches on zsh
# behave a bit... differently
# setopt bash_rematch

### META #######################################################################

TITLE="Workstation Setup"
VERSION="v1.0"
AUTHOR="Ryan M. Clements"
AUTHOR_EMAIL="rclement@redhat.com"
AUTHOR_PGP_PUBLIC_KEY="FD1EB8DBA4278107A7197F9A58646927A6BC2736"
LICENSE="https://www.gnu.org/licenses/gpl-3.0.html"
SCRIPT_NAME=$(basename "${0}")

### CONSTANTS ##################################################################

# Assign error codes so we don't have magic numbers in the script
SUCCESS=0
INFO=0
ERROR=1
WARN=2

# This is it.. the beginning of logic
FALSE=0
TRUE=1

### ARRAY DECLARATIONS #########################################################

declare -A ssh_options
declare -A RUNNING_PIDS

### FILES ######################################################################

# if REMOTE_SERVER is defined, then the script will send the setup commands to
# the remote server name
REMOTE_SERVER=labs

FILE_KNOWN_HOSTS="${HOME}/.ssh/known_hosts"
FILE_SSH_CONFIG="${HOME}/.ssh/config"
FILE_SSH_PRIVATE_KEY="${HOME}/.ssh/rht_classroom.rsa"
FILE_LOCS_ANSI_COLOR=("./resources/" \
                      "${HOME}/.helper_scripts/"
                      "/opt/helper_scripts/" \
                     )
FILE_ANSI_COLOR="ansi_colors.sh"

### STRINGS ####################################################################

SSHCONFIG_EXAMPLE="\"ssh -i ~/.ssh/rht_classroom.rsa -J cloud-user@55.60.13.103:22022 student@172.25.252.1 -p 53009\""
SPINNER="/-\|"

### UNICODE CHARS ##############################################################

unicode_check_mark="\u2713"

### PRELOAD FUNCTIONS ##########################################################

load_ansi_colors()
{
  # Check the dirs where the file may be
  # shellcheck disable=SC2068
  for dir in "${FILE_LOCS_ANSI_COLOR[@]}"
  do
    echo "DIR = ${dir}"
    # Does the directory exist?
    if [[ -d "${dir}" ]]; then 
      echo "exists"
      # Does the file exist in the directory?
      if [[ -f "${dir}${FILE_ANSI_COLOR}" ]]; then
        # Then load the ansi color definition file
        # shellcheck disable=SC1090
        echo "file exists = ${dir}/${FILE_ANSI_COLOR}"
        # Load the file
        # shellcheck source=./resources/ansi_colors.sh
        source "${dir}${FILE_ANSI_COLOR}" > /dev/null 2>&1
        # Return from function
        return
      fi
    fi
  done
}

### PRELOAD COMMANDS ###########################################################

load_ansi_colors

### FUNCTIONS ##################################################################

# Print a horizontal black line
print_horizontal_line()
{
  black_bold
  python -c "print('-' * 80)"
  reset_color
}

print_header()
{
  # Define template for ssh config
  # Put quotes around "EOF" to ensure special characters don't mess up the
  # formating.
  # https://tldp.org/LDP/abs/html/here-docs.html#EX71C
  PROGRAM_HEADER=$(cat <<-"EOF"
__        __         _        _        _   _
\ \      / /__  _ __| | _____| |_ __ _| |_(_) ___  _ __
 \ \ /\ / / _ \| '__| |/ / __| __/ _` | __| |/ _ \| '_ \
  \ V  V / (_) | |  |   <\__ \ || (_| | |_| | (_) | | | |
   \_/\_/ \___/|_|  |_|\_\___/\__\__,_|\__|_|\___/|_| |_|

 ____       _                       _   ___
/ ___|  ___| |_ _   _ _ __   __   _/ | / _ \
\___ \ / _ \ __| | | | '_ \  \ \ / / || | | |
 ___) |  __/ |_| |_| | |_) |  \ V /| || |_| |
|____/ \___|\__|\__,_| .__/    \_/ |_(_)___/
                     |_|

EOF
)
  print_horizontal_line
  echo "${PROGRAM_HEADER}"
  echo -e "$cyan"
  echo "Copyright (c) 2023 ${AUTHOR} (${AUTHOR_EMAIL})"
  echo "License: GPLv3 (${LICENSE})"
  reset_color
  print_horizontal_line
  echo ""
}

# Log messages to screen
log()
{
  local level
  local msg

  level="${1}"
  msg="${2}"

  # ? Should this be case instead?

  if [[ "${level}" -eq "${ERROR}" ]]; then
    lc="$red"
  elif [[ "${level}" -eq "${INFO}" ]]; then
    lc="$green"
  else
    lc="$yellow"
  fi

  echo -ne "${grey}[${lc}*"
  tput sc
  printf "%s]%s %s" "${gray}" "${normal}" "${msg}"
}

# This function is a trap function called by the "trap" directive. Shellcheck
# thinks its not accessable
# shellcheck disable=SC2317
_sigint_trap()
{
  echo ""
  print_horizontal_line
  log "${WARN}" "SIGINT captured: Shutting down threaded processes."
  echo ""
  print_horizontal_line

  if [[ -n "${RUNNING_PID}" ]]; then
    kill -9 "${RUNNING_PID}" > /dev/null 2>&1
  fi
  exit "${ERROR}"
}

# Assign trap functions to signals
assign_traps()
{
  trap _sigint_trap SIGINT
}

# Function to run commands
# TODO: Rework this
run()
{
  if [[ -n "${REMOTE_SERVER}" ]]; then
    ssh -q "${REMOTE_SERVER}" "${1}" > /dev/null &
    PID=$!
  else
    if [[ "${SUDO_REQUIRES_PASSWORD}" -eq "${TRUE}" ]]; then
#    echo "Requires password"
#    exit
/usr/bin/expect <<EOD
spawn ${1}
expect "[sudo] password"
send -- "${SUDO_PASSWORD}\r"
interact
EOD
    fi
    eval "${1}" &
    PID=$!
  fi
  # Add the PID to the running PIDS array
  RUNNING_PID="${PID}"
  # echo "PID = ${PID}"
  # RUNNING_PIDS[${#RUNNING_PIDS[@]}]="${PID}"

  # for pid in ${RUNNING_PIDS[@]}
  # do
  #   echo "RUNNING_PIDS = $pid"
  # done
  
  i=1
  echo -n ' '
  tput rc
  #echo -en "${restore_cursor_pos}"
  while [[ -d "/proc/${PID}" ]]
  do
    printf "\b${SPINNER:i++%${#SPINNER}:1}"
    sleep 0.1
  done
  # Delete the PID from the runing PIDS array
  RUNNING_PID=""
#  tput rc
  tput cub1
  echo -e "${unicode_check_mark}"
}

copy_if_remote()
{
  if [[ -n "${REMOTE_SERVER}" ]]; then
    scp "${1}" "${REMOTE_SERVER}:${2}" > /dev/null
  fi
}

copy()
{
  if [[ -n "${REMOTE_SERVER}" ]]; then
    scp "${1}" "${REMOTE_SERVER}:${2}" 
  else
    cp "${1}" "${2}"
  fi
}

## Install ZSH

install_zsh()
{
  print_horizontal_line
  # log "${INFO}" "Sleeeeeeeeeeping..."
  # run "sleep 10"
  log "${INFO}" "Installing zsh using dnf"
  run "sudo dnf -y install zsh > /dev/null"

  log "${INFO}" "Downloading ohmyzsh!"
  run "curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o ./install.sh"
  log "${INFO}" "Running the ohmyzsh install script"
  run "sh install.sh > /dev/null"
  log "${INFO}" "Cloning powerlevel10k"
  run "git clone -q \-\-depth=1 https://github.com/romkatv/powerlevel10k.git \${ZSH_CUSTOM:-\$HOME}/.oh-my-zsh/custom/themes/powerlevel10k > /dev/null 2>&1"
  log "${INFO}" "Cloning vim theme code-dark"
  run "git clone \-\-depth=1 https://github.com/tomasiser/vim-code-dark \${HOME}/.vim/pack/themes/start/vim-code-dark > /dev/null 2>&1"
  
  if [[ -n "${REMOTE_SERVER}" ]]; then
    log "${INFO}" "Copying sed script (sed.sh)"
    copy_if_remote resources/sed.sh sed.sh
    log "${INFO}" "Copying Powerlevel10k prompt script for ohmyzsh (.p10k.zsh)"
    copy_if_remote resources/.p10k.zsh .p10k.zsh
    log "${INFO}" "Copying vim configuration file (.vimrc)"
    copy_if_remote resources/.vimrc .vimrc
    log "${INFO}" "Copying zsh configuration file (.zshrc)"
    copy_if_remote resources/.zshrc .zshrc
  fi
  log "${INFO}" "Runing sed script (sed.sh)"
  run "sh sed.sh > /dev/null 2>&1"
  log "${INFO}" "Changing the user's shell to /usr/bin/zsh"
  run "sudo chsh \${USER} -s /usr/bin/zsh > /dev/null 2>&1"
  print_horizontal_line
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

# FUNCTION: _final_check_for_host_and_post_in_ssh_config
#
# DESCRIPTION:
# Checks if there are references to a server hostname and server port in
# the ssh config (~/.ssh/config by default)
#
# ARGUMENTS:
# ${1} = server_hostname
# ${2} = server_port
#
# RETURNS:
# nothing - just echo to stdout
_final_check_for_host_and_port_in_ssh_config()
{
  local server_hostname
  local server_port

  server_hostname="${1}"
  server_port="${2}"

  host_count=$(sed -ne "/^\[${server_hostname}\]\:${server_port}/p" "${FILE_KNOWN_HOSTS}" | wc -l)
  if [[ "${host_count}" -eq 0 ]]; then
    log "${INFO}" "Removed all references of ${server_hostname}:${server_port} in ${FILE_KNOWN_HOSTS}"
  else
    log "${WARN}" "WARNING: Could not remove all references to ${server_hostname}:${server_port}"
    log "${WARN}" "         Post-check still reports ${host_count} references left in ${FILE_KNOWN_HOSTS}"
  fi
}

# FUNCTION: check_for_host_and_post_in_ssh_config
#
# DESCRIPTION:
# Checks if there are references to a dest and jump server hostnames and server
# ports in the ssh config (~/.ssh/config by default). Then asks user if they
# wish to remove the references.
# 
# ARGUMENTS:
# ${1} = dest_server_hostname
# ${2} = dest_server_port
# ${3} = jump_server_hostname
# ${4} = jump_server_port
#
# RETURNS:
# nothing - just echo to stdout
check_for_host_and_port_in_ssh_config()
{
  local dest_server_hostname
  local dest_server_port
  local jump_server_hostname
  local jump_server_port

  dest_server_hostname="${1}"
  dest_server_port="${2}"
  jump_server_hostname="${3}"
  jump_server_port="${4}"

  # Determine how many entries are in the ${KNOWN_HOSTS} file
  # (typically ~/.ssh/known_hosts)
  jump_host_count=$(\
    sed -ne "/^\[${jump_server_hostname}\]\:${jump_server_port}/p" \
    "${FILE_KNOWN_HOSTS}" | wc -l)
  dest_host_count=$(\
    sed -ne "/^\[${dest_server_hostname}\]\:${dest_server_port}/p" \
    "${FILE_KNOWN_HOSTS}" | wc -l)

  # Did we find any entries of dest or jump server in the known_hosts file?
  if [[ "${jump_host_count}" -gt 0 || "${dest_host_count}" -gt 0 ]]; then
    log "Checking for old references in ${FILE_KNOWN_HOSTS}"
    print_horizontal_line
    echo "There are $jump_host_count references of ${jump_server_hostname}:${jump_server_port} in ${FILE_KNOWN_HOSTS}"
    echo "There are $dest_host_count references of ${dest_server_hostname}:${dest_server_port} in ${FILE_KNOWN_HOSTS}"
    print_horizontal_line
    echo ""
    echo "--> Remove ALL references to the jump and dest hosts in ${FILE_KNOWN_HOSTS}?"
    echo "--> This is recommended so you don't get host key warnings."
    echo -n "--> [Y/n]: "
    # Wait for user's single character input. Default is 'Y'
    read -r -n1 ans
    echo ""
    # If user typed anything besides 'n', then remove the entries
    if [[ "${ans}" != "n" ]]; then
      log "Creating backup ${FILE_KNOWN_HOSTS}.bak"
      sed -i.bak -e "/^\[${dest_server_hostname}\]\:${dest_server_port}/d " \
                  -e "/^\[${jump_server_hostname}\]\:${jump_server_port}/d " \
                  "${FILE_KNOWN_HOSTS}"
    fi
    # Do a final check and report if successful or failed
    # arg1 = server hostname
    # arg2 = server port
    _final_check_for_host_and_port_in_ssh_config \
      "${dest_server_hostname}" "${dest_server_port}"
    _final_check_for_host_and_port_in_ssh_config \
      "${jump_server_hostname}" "${jump_server_port}"
  fi
}

parse_ssh_options()
{
  # Define variables as local
  # Ugly, but ShellCheck thinks we should define separately from the value
  # assignment.
  # https://github.com/koalaman/shellcheck/wiki/SC2155
  local orig_string
  local regex

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

  # An example string of what is expected
  orig_string="${1}"

  # convert string into an string array
  # sorry shellcheck, I actually want to split here! No quotes for you!
  # shellcheck disable=SC2206
  arg_array=(${orig_string})

  # check to ensure there are 8 elements provided by the user's input
  if [[ "${#arg_array[@]}" -ne 8 ]]; then
    echo "ERROR: The string passed to --sshconfig looks incorrect."
    echo "       There should be eight (8) parameters in the string."
    echo "       Ensure it is surrounded by quotes."
    echo "USAGE: ${SCRIPT_NAME} --sshconfig ${SSHCONFIG_EXAMPLE}"
    exit "${ERROR}"
  fi

  # No magic numbers!
  arg_num_id_rsa=2
  arg_num_jump_server=4
  arg_num_dest_server=5
  arg_num_dest_port=7

  # assign the local variables
  id_rsa="${arg_array[${arg_num_id_rsa}]}"
  arg_jump_server="${arg_array[${arg_num_jump_server}]}"
  arg_dest_server="${arg_array[${arg_num_dest_server}]}"
  dest_server_port="${arg_array[${arg_num_dest_port}]}"

  # parse jump server argument using regex
  # format expected: user@1.1.1.1:22022
  regex="([a-zA-Z_-]+)@([0-9\.]+)\:([0-9]+)"

  # Use regex to validate the jump server's username, host, and port
  if [[ "${arg_jump_server}" =~ ${regex} ]]; then
    # assign local variables from regex match groups
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
  # format expected: user@1.1.1.1
  regex="([a-zA-Z_-]+)@([0-9\.]+)"

  # Use regex to validate the dest server username and host ip
  if [[ "${arg_dest_server}" =~ ${regex} ]]; then
    # assign local variables from regex match groups
    dest_server_username="${BASH_REMATCH[1]}"
    dest_server_hostname="${BASH_REMATCH[2]}"
  else
    echo "ERROR: Could not parse the destination server."
    echo "       Must be in this format: user@address"
    echo "       Example: student@172.25.252.1"
    exit "${ERROR}"
  fi

  # check if dest port looks like a port number
  # format expected: 53009
  regex="[0-9]+"

  # Use regex to validate the dest server port number
  if [[ ! "${dest_server_port}" =~ ${regex} ]]; then
    echo "ERROR: Could not parse the destination port number."
    echo "       Must be a number!"
    echo "       Example: 53009"
    exit "${ERROR}"
  fi

  # Define template for ssh config
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

  # Use sed to delete any previous entries
  sed -i -e '/### _GENERATED_BY_SSH_SETUP_SCRIPT_START_ ###/,/### _GENERATED_BY_SSH_SETUP_SCRIPT_END_ ###/d' ~/.ssh/config

  # use echo to concat the new entry into the ssh config
  echo "${ssh_t}" >> "${FILE_SSH_CONFIG}"

  log "${INFO}" "Successfully added the jump server configuration in your ${FILE_SSH_CONFIG} file"
  log "${INFO}" "Type: 'ssh labs' to connect"

  # Perform some final checks
  check_for_host_and_port_in_ssh_config \
    "${dest_server_hostname}" "${dest_server_port}" \
    "${jump_server_hostname}" "${jump_server_port}"

  # Ask user if they would now like to run the zsh setup
  echo "Would you like to run the oh my zsh setup on the remote labs host?"
  echo -n "[Y/n]: "
  read -r -n1 ans
  echo ""
  # anything besides 'n' means 'y'
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

show_help()
{
  help_msg=$(cat <<-EOF
Options:
  --help: this message
  --sshconfig <your labs ssh string given to you by your lab>
    Example:
      --sshconfig _SSH_CONFIG_EXAMPLE_
  --remote <remote_server_ip>

Usage:
  To fully configure a new lab environment:
    1. Ensure your classroom's private key is copied to _FILE_SSH_PRIVATE_KEY_
       or elsewhere of your choosing.
    2. Copy the connection string given to you by your lab environment. For
       example: _SSH_CONFIG_EXAMPLE_
    3. Run _SCRIPT_NAME_ --sshconfig _SSH_CONFIG_EXAMPLE_
       Ensure to surround your connection string in quotes!
       The prompts will step you through the setup process.

    ** NOTE: If you install "oh my zsh!" and the "powerlevel10k" prompt, then
             you will need to install the custom fonts on your machine.
             See the fonts/ subdirectory for more information.
EOF
  )

  help_msg="${help_msg//_SSH_CONFIG_EXAMPLE_/${SSHCONFIG_EXAMPLE}}"
  help_msg="${help_msg//_FILE_SSH_PRIVATE_KEY_/${FILE_SSH_PRIVATE_KEY}}"
  help_msg="${help_msg//_SCRIPT_NAME_/${SCRIPT_NAME}}"

  print_horizontal_line
  echo "${help_msg}"
  print_horizontal_line
  echo ""
}

success_msg()
{
  echo "--> Everything is ready!"
  echo "--> Type: 'ssh labs' to connect to your labs server!"
}

print_compressed_header()
{
  print_horizontal_line
  echo "${TITLE} ${VERSION} Copyright (c) 2023 ${AUTHOR} (${AUTHOR_EMAIL})"
  echo "Author GPG key: ${AUTHOR_PGP_PUBLIC_KEY}"
  print_horizontal_line
  echo "This program is free software: you can redistribute it and/or modify"
  echo "it under the terms of the GNU General Public License either v3 or later." 
  echo "License: ${LICENSE}"
}

options()
{
  local arg1
  local arg2
  arg1=$(_set_arg "${1}")
  arg2=$(_set_arg "${2}")

  case "${arg1}" in
    "--help")
      print_compressed_header
      show_help
    ;;
    "--sshconfig")
      print_header
      configure_ssh_config "${arg2}"
    ;;
    "--remote")
      print_header
      if [[ -z "${arg2}" ]]; then
        echo "You must provide a server name after --remote parameter"
        echo "Example: ${SCRIPT_NAME} --remote 50.1.1.1"
        exit "${ERROR}"
      fi
      REMOTE_SERVER="${arg2}"
      install_zsh
      success_msg
    ;;
    # if anything else, then just install zsh as normal
    *)
      print_header
      install_zsh "${arg1}"
      success_msg
    ;;
  esac
}

prompt_for_sudo_password()
{
  log "${WARN}" "sudo command requires a password to function on your account"
  echo  -e "--> Please enter your sudo password so this script can function."
  echo -ne "--> "
  read -s SUDO_PASSWORD
}


test_sudo()
{
  if sudo -n true 2>/dev/null; then
    SUDO_REQUIRES_PASSWORD="${FALSE}"
  else
    SUDO_REQUIRES_PASSWORD="${TRUE}"
    prompt_for_sudo_password
  fi
}


### MAIN #######################################################################

#set -x
assign_traps
test_sudo
load_ansi_colors
options "${@}"
exit "${SUCCESS}"
