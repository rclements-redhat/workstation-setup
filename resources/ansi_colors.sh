#!/bin/usr/env bash
# Colour constants
declare -r \
        ansi_black='\033[30m' \
        ansi_black_bold='\033[0;30;1m' \
        ansi_red='\033[31m' \
        ansi_red_bold='\033[0;31;1m' \
        ansi_green='\033[32m' \
        ansi_green_bold='\033[0;32;1m' \
        ansi_yellow='\033[33m' \
        ansi_yellow_bold='\033[0;33;1m' \
        ansi_blue='\033[34m' \
        ansi_blue_bold='\033[0;34;1m' \
        ansi_magenta='\033[35m' \
        ansi_magenta_bold='\033[0;35;1m' \
        ansi_cyan='\033[36m' \
        ansi_cyan_bold='\033[0;36;1m' \
        ansi_white='\033[0m;37m' \
        ansi_white_bold='\033[0;37;1m' \
        ansi_reset='\033[0m'

declare -r ansi_grey="$ansi_black_bold"

declare -rA C=(
    [black]="$ansi_black"
    [black_bold]="$ansi_black_bold"
    [grey]="$ansi_grey"
    [red]="$ansi_red"
    [red_bold]="$ansi_red_bold"
    [green]="$ansi_green"
    [green_bold]="$ansi_green_bold"
    [yellow]="$ansi_yellow"
    [yellow_bold]="$ansi_yellow_bold"
    [blue]="$ansi_blue"
    [blue_bold]="$ansi_blue_bold"
    [magenta]="$ansi_magenta"
    [magenta_bold]="$ansi_magenta_bold"
    [cyan]="$ansi_cyan"
    [cyan_bold]="$ansi_cyan_bold"
    [white]="$ansi_white"
    [white_bold]="$ansi_white_bold"
    [reset]="$ansi_reset"
    [black]="$ansi_black"
    # [bb]="$ansi_black_bold"
    # [g]="$ansi_grey"
    # [r]="$ansi_red"
    # [rb]="$ansi_red_bold"
    # [gr]="$ansi_green"
    # [grb]="$ansi_green_bold"
    # [y]="$ansi_yellow"
    # [yb]="$ansi_yellow_bold"
    # [bl]="$ansi_blue"
    # [blb]="$ansi_blue_bold"
    # [m]="$ansi_magenta"
    # [mb]="$ansi_magenta_bold"
    # [c]="$ansi_cyan"
    # [cb]="$ansi_cyan_bold"
    # [w]="$ansi_white"
    # [wb]="$ansi_white_bold"
    # [re]="$ansi_reset"
)


# shellcheck disable=SC2034
black=$(tput setaf 16)
white=$(tput setaf 15)
gray=$(tput setaf 240)
grey="${gray}"
blue=$(tput setaf 21)
green=$(tput setaf 28)
red=$(tput setaf 1)
cyan=$(tput setaf 36)
purple=$(tput setaf 128)
brown=$(tput setaf 130)
yellow=$(tput setaf 226)
orange=$(tput setaf 202)
pink=$(tput setaf 207)
lgray=$(tput setaf 246)
lblue=$(tput setaf 39)
lgreen=$(tput setaf 118)
lred=$(tput setaf 9)
lcyan=$(tput setaf 14)
lpurple=$(tput setaf 99)
bold=$(tput bold)
blink=$(tput blink) # Blinking test
reverse=$(tput rev) # reverse video mode
normal=$(tput sgr0)

sol=$(tput ll)
save_cursor_pos=$(tput sc)
restore_cursor_pos=$(tput rc)




black_bold()
{
  echo -ne "${gray}"
}
reset_color()
{
  echo -ne "${normal}"
}

