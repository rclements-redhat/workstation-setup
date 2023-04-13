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
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
SCRIPT_SHA256_CHECKSUM=$(sha256sum "${SCRIPT_DIR}/${SCRIPT_NAME}" | cut -d' ' -f1)

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

### FILES ######################################################################

# Get the REAL name of the user executing this script, even if they use sudo
REAL_USER="${SUDO_USER:-${USER}}"
# Based on the real user, get their home directory
USER_HOME_DIR=$(getent passwd "${REAL_USER}" | cut -d: -f6 )

# if REMOTE_SERVER is defined, then the script will send the setup commands to
# the remote server name
REMOTE_SERVER=labs

FILE_KNOWN_HOSTS="${USER_HOME_DIR}/.ssh/known_hosts"
FILE_SSH_CONFIG="${USER_HOME_DIR}/.ssh/config"
FILE_SSH_PRIVATE_KEY="${USER_HOME_DIR}/.ssh/rht_classroom.rsa"
FILE_LOCS_ANSI_COLOR=("./resources/" \
                      "${USER_HOME_DIR}/.helper_scripts/"
                      "/opt/helper_scripts/" \
                     )

FILE_ANSI_COLOR="ansi_colors.sh"

### STRINGS ####################################################################

DEFAULT_SSHALIAS=labs

SSHCONFIG_EXAMPLE="\"ssh -i ~/.ssh/rht_classroom.rsa -J cloud-user@55.60.13.103:22022 student@172.25.252.1 -p 53009\""
SPINNER="/-\|"

ALL_DNF_PACKAGES="zsh"

### UNICODE CHARS ##############################################################

unicode_check_mark="\u2713"

### PRELOAD FUNCTIONS ##########################################################

load_ansi_colors()
{
  # Check the dirs where the file may be
  # shellcheck disable=SC2068
  for dir in "${FILE_LOCS_ANSI_COLOR[@]}"
  do
    # Does the directory exist?
    if [[ -d "${dir}" ]]; then 
      # Does the file exist in the directory?
      if [[ -f "${dir}${FILE_ANSI_COLOR}" ]]; then
        # Then load the ansi color definition file
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

### COLOR CONSTANTS ############################################################

OH_MY_ZSH_NAME="Oh My ZSH!"

### FUNCTIONS ##################################################################

# Print a horizontal black line
print_horizontal_line()
{
  black_bold
  python -c "print('-' * 80)"
  reset_color

  return "${TRUE}"
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

  return "${TRUE}"
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
  printf "%s]%s %b" "${gray}" "${normal}" "${msg}"

  return "${TRUE}"
}

# This function is a trap function called by the "trap" directive. Shellcheck
# thinks its not accessible
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

  return "${TRUE}"
}

run_local()
{
  eval "${1}" &
  PID=$!
  
  # Add the PID to the running PIDS array
  RUNNING_PID="${PID}"

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

  return "${TRUE}"
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

  return "${TRUE}"
}

copy_if_remote()
{
  if [[ -n "${REMOTE_SERVER}" ]]; then
    scp "${1}" "${REMOTE_SERVER}:${2}" > /dev/null
  fi

  return "${TRUE}"
}

copy()
{
  if [[ -n "${REMOTE_SERVER}" ]]; then
    scp "${1}" "${REMOTE_SERVER}:${2}" 
  else
    cp "${1}" "${2}"
  fi

  return "${TRUE}"
}

keyscan_host()
{
  local address
  local port

  address="${1}"
  port="${2}"

  log "${INFO}" "Scanning keys from host ${lcyan}${address}${normal}:${lcyan}${port}${normal}\n"
  run_local "ssh-keyscan -p ${port} ${address} >> ${FILE_KNOWN_HOSTS} 2>&1"

  return "${TRUE}"
}

## Install ZSH
# TODO: I really don't like this. Must rework at some point.
install_zsh()
{
  print_horizontal_line
  # log "${INFO}" "Sleeeeeeeeeeping..."
  # run "sleep 10"
  log "${INFO}" "Installing zsh using dnf"
  run "sudo dnf -y install zsh > /dev/null"

  log "${INFO}" "Downloading ${OH_MY_ZSH_NAME}"
  run "curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o ./install.sh"
  log "${INFO}" "Running the ${OH_MY_ZSH_NAME} install script"
  run "sh install.sh > /dev/null"
  log "${INFO}" "Cloning powerlevel10k"
  run "git clone -q \-\-depth=1 https://github.com/romkatv/powerlevel10k.git \${ZSH_CUSTOM:-\${HOME}}/.oh-my-zsh/custom/themes/powerlevel10k > /dev/null 2>&1"
  log "${INFO}" "Cloning vim theme code-dark"
  run "git clone \-\-depth=1 https://github.com/tomasiser/vim-code-dark \${HOME}/.vim/pack/themes/start/vim-code-dark > /dev/null 2>&1"
  
  if [[ -n "${REMOTE_SERVER}" ]]; then
    log "${INFO}" "Copying sed script (sed.sh)\n"
    copy_if_remote resources/sed.sh sed.sh
    log "${INFO}" "Copying Powerlevel10k prompt script for ohmyzsh (.p10k.zsh)\n"
    copy_if_remote resources/.p10k.zsh .p10k.zsh
    log "${INFO}" "Copying vim configuration file (.vimrc)\n"
    copy_if_remote resources/.vimrc .vimrc
    log "${INFO}" "Copying zsh configuration file (.zshrc)\n"
    copy_if_remote resources/.zshrc .zshrc
  fi
  log "${INFO}" "Runing sed script (sed.sh)\n"
  run "sh sed.sh > /dev/null 2>&1"
  log "${INFO}" "Changing the user's shell to /usr/bin/zsh\n"
  run "sudo chsh \${USER} -s /usr/bin/zsh > /dev/null 2>&1"
  print_horizontal_line
  log "${INFO}" "Type: '${lcyan}ssh labs${normal}' to connect\n"
  print_horizontal_line

  return "${TRUE}"
}

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
    log "${INFO}" "Removed all references of ${lcyan}${server_hostname}${normal}:${lcyan}${server_port} in ${lcyan}${FILE_KNOWN_HOSTS}${normal}\n"
  else
    log "${WARN}" "WARNING: Could not remove all references to ${server_hostname}:${server_port}"
    log "${WARN}" "         Post-check still reports ${host_count} references left in ${FILE_KNOWN_HOSTS}"
  fi

  return "${TRUE}"
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
    log "${INFO}" "Checking for old references in ${FILE_KNOWN_HOSTS}\n"

    if [[ "${jump_host_count}" -gt 0 ]]; then
      jump_count_color="${lred}${blink}"
    else
      jump_count_color="${lgreen}"
    fi

    if [[ "${dest_host_count}" -gt 0 ]]; then
      dest_count_color="${lred}${blink}"
    else
      dest_count_color="${lgreen}"
    fi
    
    echo -n "    "
    echo -ne "${grey}-> ${normal}There are ${jump_count_color}$jump_host_count ${normal}references of ${lcyan}${jump_server_hostname}${normal}:${lcyan}${jump_server_port} in ${FILE_KNOWN_HOSTS}\n"
    echo -n "    "
    echo -ne "${grey}-> ${normal}There are ${dest_count_color}$dest_host_count ${normal}references of ${lcyan}${dest_server_hostname}${normal}:${lcyan}${dest_server_port} in ${FILE_KNOWN_HOSTS}\n"
    echo ""
    question=(\
      "Remove ALL references to the jump and dest hosts in ${lcyan}${FILE_KNOWN_HOSTS}${normal}?\n" \
      "This is ${s_u}recommended${e_u} so you don't get host key warnings.\n" \
      "[Y/n]: "
    )
    print_question "${question[@]}"
    # Wait for user's single character input. Default is 'Y'
    read -r -n1 ans
    echo ""
    echo ""
    # If user typed anything besides 'n', then remove the entries
    if [[ "${ans}" != "n" ]]; then
      log "${INFO}" "Creating backup ${lcyan}${FILE_KNOWN_HOSTS}.bak${normal}\n"
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
  echo ""

  return "${TRUE}"
}

print_question()
{
  local question_array
  local input_char
  local question_pre

  question_array=("$@")

  question_pre="${grey}[${purple}-->${grey}]${normal}"
  for line in "${question_array[@]}"
  do
    echo -ne "${question_pre} ${line}"
  done

  return "${TRUE}"
}

purge_stdin()
{
    while read -e -t 0.1; do : ; done
}

replace_tags_with_values()
{
  local -n associative_array="${1}"
  local value

  for key in "${!associative_array[@]}"
  do
    value="${associative_array[$key]}"
    ssh_t="${ssh_t//${key}/${value}}"
  done

  echo "${ssh_t}"
}

parse_ssh_options()
{
  # Define variables as local
  # Ugly, but ShellCheck thinks we should define separately from the value
  # assignment.
  # https://github.com/koalaman/shellcheck/wiki/SC2155
  local required_sshconfig_orig_string
  local optional_sshalias
  local regex
  local final_sshalias
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

  # Declare local associative array for the sshconfig_tags. This is used in the
  # key/value templating for ~/.ssh/config. The key/value pairs are defined
  # later in this function
  local -A sshconfig_tags

  # If optional_sshalias was defined by user arguments, then use that. If not,
  # then use the DEFAULT_SSHALIAS (originally set to "labs")
  optional_sshalias="${2}"
  final_sshalias="${optional_sshalias:-${DEFAULT_SSHALIAS}}"

  # An example string of what is expected
  required_sshconfig_orig_string="${1}"
  
  # convert string into an string array
  # sorry shellcheck, I actually want to split here! No quotes for you!
  # shellcheck disable=SC2206
  arg_array=(${required_sshconfig_orig_string})

  # check to ensure there are 8 elements provided by the user's input
  if [[ "${#arg_array[@]}" -ne 8 ]]; then
    echo "ERROR: The string passed to --sshconfig looks incorrect."
    echo "       There should be eight (8) parameters in the string."
    echo "       Ensure it is surrounded by quotes. You may also provide an"
    echo "       sshalias if you wish."
    echo "EXAMPLE: ${SCRIPT_NAME} --sshconfig ${SSHCONFIG_EXAMPLE} do188"
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

  ### Start Template creation for ~/.ssh/conig ###

  # Define template for ssh config
  ssh_t=$(cat <<-EOF
### _GENERATED_BY_SSH_SETUP_SCRIPT_START_FOR_HOST__FINAL_SSHALIAS_ ###
Host _FINAL_SSHALIAS_
  StrictHostKeyChecking no
  HostName _DEST_SERVER_HOSTNAME_
  Port _DEST_SERVER_PORT_
  IdentityFile _ID_RSA_
  ProxyJump _JUMP_SERVER_USERNAME_@_JUMP_SERVER_HOSTNAME_:_JUMP_SERVER_PORT_
  User _DEST_SERVER_USERNAME_
### _GENERATED_BY_SSH_SETUP_SCRIPT_END_FOR_HOST__FINAL_SSHALIAS_ ###
EOF
)

  ## Time to fill in our template!
  sshconfig_tags[_FINAL_SSHALIAS_]="${final_sshalias}"
  sshconfig_tags[_DEST_SERVER_HOSTNAME_]="${dest_server_hostname}"
  sshconfig_tags[_DEST_SERVER_PORT_]="${dest_server_port}"
  sshconfig_tags[_ID_RSA_]="${id_rsa}"
  sshconfig_tags[_JUMP_SERVER_USERNAME_]="${jump_server_username}"
  sshconfig_tags[_JUMP_SERVER_HOSTNAME_]="${jump_server_hostname}"
  sshconfig_tags[_JUMP_SERVER_PORT_]="${jump_server_port}"
  # Shellcheck thinks sshconfig_tags isn't used because we're passing it as a
  # reference to the replace_tags_with_values function instead of the array
  # itself. Therefore, we have disable SC2034 on the last line of the array
  # declaration so that it doesn't report the false-positive
  # shellcheck disable=SC2034
  sshconfig_tags[_DEST_SERVER_USERNAME_]="${dest_server_username}"

  # Call the function replace_tags_with_values and pass the sshconfig_tags
  # associative array reference to the function
  ssh_t=$(replace_tags_with_values sshconfig_tags)
  
  # Use sed to delete any previous entries
  sed -i -e "/### _GENERATED_BY_SSH_SETUP_SCRIPT_START_FOR_HOST_${final_sshalias} ###/,/### _GENERATED_BY_SSH_SETUP_SCRIPT_END_FOR_HOST_${final_sshalias} ###/d" "${FILE_SSH_CONFIG}"

  # use echo to concat the new entry into the ssh config
  echo "${ssh_t}" >> "${FILE_SSH_CONFIG}"

  ### Done with Template creation for ~/.ssh/conig ###

  # Show the result of the addition
  print_horizontal_line
  log "${INFO}" "Successfully added the jump server configuration in your ${lcyan}${FILE_SSH_CONFIG} ${normal}file\n"
  log "${INFO}" "Type: '${lcyan}ssh ${final_sshalias}${normal}' to connect\n"
  print_horizontal_line

  # Perform some final checks
  check_for_host_and_port_in_ssh_config \
    "${dest_server_hostname}" "${dest_server_port}" \
    "${jump_server_hostname}" "${jump_server_port}"

  # Perform keyscans on the hosts user just added
  keyscan_host "${jump_server_hostname}" "${jump_server_port}"
  keyscan_host "${dest_server_hostname}" "${dest_server_port}"

  echo ""
  question=(\
    "Would you like to run the \"${OH_MY_ZSH_NAME}\" setup on the remote labs host?\n"
    "${normal}[Y/n]${grey}: ")

  # Ask user if they would now like to run the zsh setup
  print_question "${question[@]}"

  local input_char

  # ensure nothing is in the buffer before reading the answer
  purge_stdin

  read -r -n1 input_char
  echo ""
  # anything besides 'n' means 'y'
  if [[ "${input_char}" != "n" ]]; then
    install_zsh
  fi

  return "${TRUE}"
}

configure_ssh_config()
{
  local required_sshconfig
  local optional_sshalias

  required_sshconfig="${1}"
  optional_sshalias="${2}"

  if [[ -z "${REMOTE_SERVER}" ]]; then
    return
  fi

  parse_ssh_options "${required_sshconfig}" "${optional_sshalias}"

  return "${TRUE}"
}

show_help()
{
  local help_msg

  help_msg=$(cat <<-EOF

|y|Options:|n|
  --|lc|help|g|: |n|this message|n|
  --|lc|sshconfig |c|<your labs ssh string given to you by your lab>|n| |c|[sshalias]|n|
    Configures your |lc|_FILE_SSH_CONFIG_|n| file to connect to the lab using an alias
    Will also ask you if you want to setup zsh/_OH_MY_ZSH_NAME_ after you're done.
    Example: |gr|--sshconfig _SSH_CONFIG_EXAMPLE_|n|

|y|Usage:|n|
  To fully configure a new lab environment:
    1|g|.|n| Ensure your classroom's private key is copied to |lc|_FILE_SSH_PRIVATE_KEY_|n|
    2|g|.|n| Copy the connection string given to you by your lab environment.
    3|g|.|n| Run |lc|./_SCRIPT_NAME_ --sshconfig |c|_SSH_CONFIG_EXAMPLE_|n|
                                   |g|^ Example ONLY, use your string instead ^|n|

    |y|** NOTE|n|: You must install the custom fonts if you install the |lc|powerlevel10k|n|
             prompt. See the |lc|fonts/|n| subdirectory for more information.
EOF
  )
  # Removed parameter for now. Keeping this here so it can be added back later
  # --|lc|installzsh |c|<user@remote_server_ip:port>|n|

  help_msg="${help_msg//_SSH_CONFIG_EXAMPLE_/${SSHCONFIG_EXAMPLE}}"
  help_msg="${help_msg//_FILE_SSH_PRIVATE_KEY_/${FILE_SSH_PRIVATE_KEY}}"
  help_msg="${help_msg//_SCRIPT_NAME_/${SCRIPT_NAME}}"
  help_msg="${help_msg//_OH_MY_ZSH_NAME_/${OH_MY_ZSH_NAME}}"
  help_msg="${help_msg//_FILE_SSH_CONFIG_/${FILE_SSH_CONFIG}}"
  help_msg="${help_msg//|lc|/${lcyan}}"
  help_msg="${help_msg//|g|/${grey}}"
  help_msg="${help_msg//|c|/${cyan}}"
  help_msg="${help_msg//|y|/${yellow}}"
  help_msg="${help_msg//|n|/${normal}}"
  help_msg="${help_msg//|gr|/${green}}"

  print_horizontal_line
  echo "${help_msg}"
  print_horizontal_line
  echo ""

  return "${TRUE}"
}

success_msg()
{
  echo "--> Everything is ready!"
  echo "--> Type: 'ssh labs' to connect to your labs server!"

  return "${TRUE}"
}

# FUNCTION    : print_compressed_header
# ARGUMENTS   : none
# DESCRIPTION : Prints a compressed version of the program's header containing
#               it's metadata, such as author, version, author email, GPG key
#               and license information.
# RETURNS     : always ${TRUE}
print_compressed_header()
{
  print_horizontal_line
  echo "${TITLE} ${VERSION} Copyright (c) 2023 ${AUTHOR} (${AUTHOR_EMAIL})"
  echo "Author GPG key: ${AUTHOR_PGP_PUBLIC_KEY}"
  echo "Script SHA256 : ${SCRIPT_SHA256_CHECKSUM}"
  print_horizontal_line
  echo "This program is free software: you can redistribute it and/or modify it under"
  echo "the terms of the GNU General Public License either v3 or later." 
  echo "License: ${LICENSE}"

  return "${TRUE}"
}

# FUNCTION    : process_subcommands
# ARGUMENTS   : An array of arguments passed from main() which are the user's
#               command-line arguments.
# DESCRIPTION : Parses the user's main command-line arguments and executes the
#               appropriate logic and functions.
# RETURNS     : always ${TRUE}
process_subcommands()
{
  local arg1
  local arg2
  local arg3
  arg1=$(_set_arg "${1}")
  arg2=$(_set_arg "${2}")
  arg3=$(_set_arg "${3}")

  case "${arg1}" in
    "--sshconfig")
      local required_sshconfig
      local optional_sshalias
      required_sshconfig="${arg2}"
      optional_sshalias="${arg3}"

      print_header
      test_sudo

      configure_ssh_config "${required_sshconfig}" "${optional_sshalias}"
    ;;
    # Parameter removed for now
    #
    # "--installzsh")
    #   print_header
    #   if [[ -z "${arg2}" ]]; then
    #     echo "You must provide a user and server name after --installzsh parameter"
    #     echo "Example: ${SCRIPT_NAME} --installzsh user@50.0.0.1"
    #     echo ""
    #     echo "Alternatively, you can also supply a port number. You may also use"
    #     echo "hostnames/aliases from your ${REMOTE_SSH_CONFIG} file or localhost"
    #     echo ""
    #   fi
    #   test_sudo
    #   install_zsh "${arg1}"
    #   success_msg
    # ;;
    "--help"|*)
      print_compressed_header
      show_help
    ;;
      

  esac

  return "${TRUE}"
}

# FUNCTION    : prompt_for_sudo_password
# ARGUMENTS   : none
# DESCRIPTION : Prompts the user for the machine's sudo password and stores it
#               in the global variable named [SUDO_PASSWORD]
# RETURNS     : always ${TRUE}
prompt_for_sudo_password()
{
  question=(\
"The ${lcyan}sudo ${normal}command requires a password when run as the ${lcyan}${REAL_USER} ${normal}user.\n" \
"\n"
"${pink}${s_u}You have THREE (3) choices (${lpurple}pick any${pink}):${e_u}\n"
"\n"
"  ${yellow}1${orange}. ${normal}Enter the ${lcyan}sudo ${normal}password below\n" \
"  ${yellow}2${orange}. ${normal}Rerun this script with sudo privileges (${lcyan}CTRL${normal}-${lcyan}C ${normal}to exit)\n" \
"  ${yellow}3${orange}. ${normal}Install the packages yourself then rerun the script\n" \
"     ${normal}a${grey}. ${normal}Use ${lcyan}CTRL${normal}-${lcyan}C ${normal}to exit this script\n" \
"     ${normal}b${grey}. ${normal}Type ${grey}\$ ${lgreen}sudo dnf -y install ${ALL_DNF_PACKAGES}${normal}\n" \
"     ${normal}b${grey}. ${normal}Rerun the script with the same arguments\n" \
"\n"
"It needs sudo because the script installs a few packages such as zsh if \n" \
"${OH_MY_ZSH_NAME} is selected to be installed.\n" \
"\n"
"Please enter the ${lcyan}sudo${normal} password (echo is turned off): " \
  )
  print_question "${question[@]}"
  
  read -r -s SUDO_PASSWORD
  echo ""
  echo ""
  log "${INFO}" "Thank you for entering the sudo password. Continuing...\n"

  return "${TRUE}"
}

# FUNCTION    : test_sudo
# ARGUMENTS   : none
# DESCRIPTION : Performs a test to see if sudo requires a password on this
#               machine. If so, call the [prompt_for_sudo_password] function.
# RETURNS     : always ${TRUE}
test_sudo()
{
  if sudo -n true 2>/dev/null; then
    SUDO_REQUIRES_PASSWORD="${FALSE}"
  else
    SUDO_REQUIRES_PASSWORD="${TRUE}"
    prompt_for_sudo_password
  fi
  return "${TRUE}"
}

main()
{
  # Configure signal traps
  assign_traps
  # Call the main subcommand parser
  process_subcommands "${@}"
}

### MAIN #######################################################################

# Call the main function
main "${@}"
# Exit with success if we got here
exit "${SUCCESS}"
