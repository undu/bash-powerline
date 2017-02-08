#!/usr/bin/env bash
__powerline() {
    # Max length of full path
    readonly MAX_PATH_LENGTH=30

    # Unicode symbols
    readonly GIT_BRANCH_SYMBOL='∓'
    readonly GIT_BRANCH_CHANGED_SYMBOL='Δ'
    readonly GIT_NEED_PUSH_SYMBOL='↑'
    readonly GIT_NEED_PULL_SYMBOL='↓'

    # ANSI Colours
    readonly BLACK=0
    readonly RED=1
    readonly GREEN=2
    readonly YELLOW=3
    readonly BLUE=4
    readonly MAGENTA=5
    readonly CYAN=6
    readonly WHITE=7

    readonly BLACK_BRIGHT=8
    readonly RED_BRIGHT=9
    readonly GREEN_BRIGHT=10
    readonly YELLOW_BRIGHT=11
    readonly BLUE_BRIGHT=12
    readonly MAGENTA_BRIGHT=13
    readonly CYAN_BRIGHT=14
    readonly WHITE_BRIGHT=15

    # Font effects
    readonly DIM="\[$(tput dim)\]"
    readonly REVERSE="\[$(tput rev)\]"
    readonly RESET="\[$(tput sgr0)\]"
    readonly BOLD="\[$(tput bold)\]"

    # Generate terminal colour codes
    # $1 is an int (a colour) and $2 must be 'fg' or 'bg'
    __get_colour() {
      case ${2} in
        'fg'*)
          echo "\[$(tput setaf ${1})\]"
          ;;
        'bg'*)
          echo "\[$(tput setab ${1})\]"
          ;;
        *)
          echo "\[$(tput setab ${1})\]"
          ;;
      esac
    }

    __git_info() {
        if [ "x$(which git)" == "x" ]; then
          # git not found
          return
        fi
        # force git output in English to make our work easier
        local git_eng="env LANG=C git"
        # get current branch name or short SHA1 hash for detached head
        local branch="$($git_eng symbolic-ref --short HEAD 2>/dev/null || $git_eng describe --tags --always 2>/dev/null)"

        if [ "x$branch" == "x" ]; then
          # git branch not found
          return
        fi

        local marks

        # branch is modified?
        [ -n "$($git_eng status --porcelain 2>/dev/null)" ] && marks+=" $GIT_BRANCH_CHANGED_SYMBOL"

        # how many commits local branch is ahead/behind of remote?
        local stat="$($git_eng status --porcelain --branch 2>/dev/null | grep '^##' | grep -o '\[.\+\]$')"
        local aheadN="$(echo $stat | grep -o 'ahead [[:digit:]]\+' | grep -o '[[:digit:]]\+')"
        local behindN="$(echo $stat | grep -o 'behind [[:digit:]]\+' | grep -o '[[:digit:]]\+')"
        [ -n "$aheadN" ] && marks+=" $GIT_NEED_PUSH_SYMBOL$aheadN"
        [ -n "$behindN" ] && marks+=" $GIT_NEED_PULL_SYMBOL$behindN"

        if [ "x$marks" = "x" ]; then
          local bg=$(__get_colour $GREEN 'bg')
          local fg=$(__get_colour $BLACK 'fg')
        else
          local bg=$(__get_colour $YELLOW 'bg')
          local fg=$(__get_colour $BLACK 'fg')
        fi

        # print the git branch segment without a trailing newline
        printf "$bg$fg $GIT_BRANCH_SYMBOL $branch$marks "
    }

    __virtualenv() {
        # Copied from Python virtualenv's activate.sh script.
        # https://github.com/pypa/virtualenv/blob/a9b4e673559a5beb24bac1a8fb81446dd84ec6ed/virtualenv_embedded/activate.sh#L62
        # License: MIT
        if [ "x$VIRTUAL_ENV" != "x" ]; then
            if [ "`basename \"$VIRTUAL_ENV\"`" == "__" ]; then
                # special case for Aspen magic directories
                # see http://www.zetadev.com/software/aspen/
                printf "[`basename \`dirname \"$VIRTUAL_ENV\"\``]"
            else
                printf "(`basename \"$VIRTUAL_ENV\"`)"
            fi
        fi
    }

    __pwd() {
        # Use ~ to represent $HOME prefix
        local pwd=$(pwd | sed -e "s|^$HOME|~|")
        if [[ ( $pwd = ~\/*\/* || $pwd = \/*\/*/* ) && ${#pwd} -gt $MAX_PATH_LENGTH ]]; then
            local IFS='/'
            read -ra split <<< "$pwd"
            if [[ $pwd = ~* ]]; then
                pwd="~/${split[1]}/.../${split[@]:(-2):1}/${split[@]:(-1)}"
            else
                pwd="/${split[1]}/.../${split[@]:(-2):1}/${split[@]:(-1)}"
            fi
        fi
        printf "$pwd"
    }

    __user() {
        # Show username only if root or in remote
        local user_colour="$(__get_colour $BLUE 'bg')"
        local block=''

        if [ $(whoami) = "root" ]; then
          local user_colour="$(__get_colour $RED 'bg')"
          local show_user="y"
          local show_host="y"
        fi

        if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
          local show_user="y"
          local show_host="y"
        fi

        if [ "x$show_user" != "x" ]; then
          block+="$user_colour$BOLD$(__get_colour $WHITE_BRIGHT 'fg') $(whoami)"
        fi
        if [ "x$show_host" != "x" ]; then
          block+="@\h"
        fi
        echo "$block "
    }

    __prompt_command() {
        local JOBS=$(jobs | wc -l | tr -d " ")
        printf "%s" "$JOBS"
    }

    ps1() {
        # Check the exit code of the previous command and display different
        # colors in the prompt accordingly.
        local EXIT_CODE=$?
        $(history -a ; history -n)

        if [ $EXIT_CODE -eq 0 ]; then
            local BG_EXIT="$(__get_colour $BLUE_BRIGHT 'bg')"
        else
            local BG_EXIT="$(__get_colour $RED 'bg')"
        fi

        PS1="\n"

        PS1+="$(__user)$RESET"

        PS1+="$(__get_colour $BLACK_BRIGHT 'bg')$(__get_colour $WHITE_BRIGHT 'fg') $(__pwd) $RESET"

        PS1+="$(__get_colour $BLUE 'bg')$(__get_colour $WHITE_BRIGHT 'fg')$(__virtualenv)$RESET"

        PS1+="$(__git_info)$RESET"

        JOBS=$(__prompt_command)
        if [ "$JOBS" -gt "0" ]; then
            PS1+="$BOLD$(__get_colour $BLUE 'bg')$(__get_colour $WHITE_BRIGHT 'fg')[${JOBS}-BG]$RESET"
        fi

        PS1+=" "
    }

    PROMPT_COMMAND=ps1
}

__powerline
unset __powerline
