# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
  . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
  for rc in ~/.bashrc.d/*; do
    if [ -f "$rc" ]; then
      . "$rc"
    fi
  done
fi

unset rc

# Start ssh-agent

if [ -z "$SSH_AUTH_SOCK" ]; then
   # Check for a currently running instance of the agent
   RUNNING_AGENT="`ps -ax | grep 'ssh-agent -s' | grep -v grep | wc -l | tr -d '[:space:]'`"
   if [ "$RUNNING_AGENT" = "0" ]; then
        # Launch a new instance of the agent
        ssh-agent -s &> $HOME/.ssh/ssh-agent
   fi
   eval `cat $HOME/.ssh/ssh-agent`
fi

### GPG #######################################################################

GPG_MY_PUBLIC_KEY_ID=58646927A6BC2736

# GPG signing for WSL2 shell
# https://github.com/keybase/keybase-issues/issues/2798
export GPG_TTY=$(tty)

# function to encrypt
secret()
{
  output=~/"${1}".enc
  gpg --encrypt --armor --output "${output}" -r "${GPG_MY_PUBLIC_KEY_ID}" "${1}" \
  && echo "${1} -> ${output}"
}

encrypt()
{
  secret "${1}"
}

# function to decrypt
reveal()
{
  output=$(echo "${1}" | rev | cut -c5- | rev)
  gpg --decrypt --output ${output} "${1}" && echo "${1} -> ${output}"
}

decrypt()
{
  reveal "${1}"
}

# prompt
export PS1="\[\e[90m[\e[94m\]\u\[\e[92m\] \W \[\e[36m\]$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/')\[\e[90m]\e[37m\]$ \[$(tput sgr0)\]"

# use base python environment
source ~/.venvs/base/bin/activate

alias ap=ansible-playbook
alias ar=ansible-rulebook
alias av=ansible-vault
