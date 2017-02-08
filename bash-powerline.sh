#!/usr/bin/env bash
__powerline() {
    # Max length of full path
    readonly MAX_PATH_LENGTH=30

    # Unicode symbols
    readonly GIT_BRANCH_SYMBOL=' '
    readonly GIT_BRANCH_CHANGED_SYMBOL='Δ'
    readonly GIT_NEED_PUSH_SYMBOL='↑'
    readonly GIT_NEED_PULL_SYMBOL='↓'

    # ANSI Colors
    # Background
    readonly BG_BLACK="\[$(tput setab 0)\]"
    readonly BG_RED="\[$(tput setab 1)\]"
    readonly BG_GREEN="\[$(tput setab 2)\]"
    readonly BG_YELLOW="\[$(tput setab 3)\]"
    readonly BG_BLUE="\[$(tput setab 4)\]"
    readonly BG_MAGENTA="\[$(tput setab 5)\]"
    readonly BG_CYAN="\[$(tput setab 6)\]"
    readonly BG_WHITE="\[$(tput setab 7)\]"

    readonly BG_BLACK_BRIGHT="\[$(tput setab 8)\]"
    readonly BG_RED_BRIGHT="\[$(tput setab 9)\]"
    readonly BG_GREEN_BRIGHT="\[$(tput setab 10)\]"
    readonly BG_YELLOW_BRIGHT="\[$(tput setab 11)\]"
    readonly BG_BLUE_BRIGHT="\[$(tput setab 12)\]"
    readonly BG_MAGENTA_BRIGHT="\[$(tput setab 13)\]"
    readonly BG_CYAN_BRIGHT="\[$(tput setab 14)\]"
    readonly BG_WHITE_BRIGHT="\[$(tput setab 15)\]"

    # Foreground
    readonly FG_BLACK="\[$(tput setaf 0)\]"
    readonly FG_RED="\[$(tput setaf 1)\]"
    readonly FG_GREEN="\[$(tput setaf 2)\]"
    readonly FG_YELLOW="\[$(tput setaf 3)\]"
    readonly FG_BLUE="\[$(tput setaf 4)\]"
    readonly FG_MAGENTA="\[$(tput setaf 5)\]"
    readonly FG_CYAN="\[$(tput setaf 6)\]"
    readonly FG_WHITE="\[$(tput setaf 7)\]"

    readonly FG_BLACK_BRIGHT="\[$(tput setaf 8)\]"
    readonly FG_RED_BRIGHT="\[$(tput setaf 9)\]"
    readonly FG_GREEN_BRIGHT="\[$(tput setaf 10)\]"
    readonly FG_YELLOW_BRIGHT="\[$(tput setaf 11)\]"
    readonly FG_BLUE_BRIGHT="\[$(tput setaf 12)\]"
    readonly FG_MAGENTA_BRIGHT="\[$(tput setaf 13)\]"
    readonly FG_CYAN_BRIGHT="\[$(tput setaf 14)\]"
    readonly FG_WHITE_BRIGHT="\[$(tput setaf 15)\]"

    # Other Effects
    readonly DIM="\[$(tput dim)\]"
    readonly REVERSE="\[$(tput rev)\]"
    readonly RESET="\[$(tput sgr0)\]"
    readonly BOLD="\[$(tput bold)\]"

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

        # print the git branch segment without a trailing newline
        if [ "x$marks" = "x" ]; then
            printf "$BG_GREEN$FG_BLACK $GIT_BRANCH_SYMBOL$branch$marks "
        else
            printf "$BG_YELLOW$FG_BLACK $GIT_BRANCH_SYMBOL$branch$marks "
        fi
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
            local BG_EXIT="$BG_BLUE_BRIGHT"
        else
            local BG_EXIT="$BG_RED"
        fi

        PS1="\n"

        # Show username only if root or in remote
        local USERCOL="$BG_BLUE"

        if [ $(whoami) = "root" ]; then
          local USERCOL="$BG_RED"
          local show_user="y"
        fi
        if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
          local show_user="y"
        fi

        if [ "x$show_user" != "x" ]; then
          PS1+="$USERCOL$BOLD$FG_WHITE_BRIGHT $(whoami) $RESET"
        fi

        PS1+="$BG_BLACK_BRIGHT$FG_WHITE_BRIGHT $(__pwd) $RESET"

        PS1+="$BG_BLUE$FG_WHITE_BRIGHT$(__virtualenv)$RESET"

        PS1+="$(__git_info)$RESET "

        JOBS=$(__prompt_command)
        if [ "$JOBS" -gt "0" ]; then
            PS1+="$BOLD$BG_BLUE$FG_WHITE_BRIGHT[${JOBS}-BG]$RESET "
        fi
    }

    PROMPT_COMMAND=ps1
}

__powerline
unset __powerline
