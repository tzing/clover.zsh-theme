#!/usr/zsh
# Clover
# 🍀 a configurable theme for oh-my-zsh theme
#
# MIT license 2018 tzing

# colors
typeset -gA clover_color
clover_color[host_info]=$fg[blue]
clover_color[user]=$fg_bold[green]
clover_color[host]=$fg_bold[cyan]
clover_color[host_remote]=$fg_bold[cyan]$bg[blue]
clover_color[dir]=$fg_bold[yellow]
clover_color[currtime]=$fg[blue]
clover_color[exectime]=$fg[grey]
clover_color[venv]=$fg[grey]
clover_color[prompt]=$fg[green]
clover_color[prompt_fail]=$fg[red]

# colors of git status
typeset -gA clover_gcolor
clover_gcolor[head]=$fg_bold[blue]
clover_gcolor[clean]=$fg_bold[green]
clover_gcolor[dirty]=$fg_bold[red]
clover_gcolor[add]=$fg_bold[green]
clover_gcolor[del]=$fg_bold[red]
clover_gcolor[modify]=$fg_bold[magenta]
clover_gcolor[rename]=$fg_bold[blue]
clover_gcolor[unmerge]=$fg_bold[cyan]
clover_gcolor[untrack]=$fg_bold[yellow]
clover_gcolor[ahead]=$fg_bold[cyan]
clover_gcolor[behind]=$fg_bold[magenta]
clover_gcolor[diverge]=$fg_bold[red]

# symbols of git status
typeset -gA clover_sym
clover_sym[host_prefix]="# "
clover_sym[host_split]="@"
clover_sym[host_suffix]=": "
clover_sym[prompt]="🍀 "
clover_sym[prompt_fail]="🔥 "

# symbols of git status
typeset -gA clover_gsym
clover_gsym[clean]=" ✔ "
clover_gsym[dirty]=" ✘ "
clover_gsym[add]="+"
clover_gsym[del]="-"
clover_gsym[modify]="*"
clover_gsym[rename]=">"
clover_gsym[unmerge]="="
clover_gsym[untrack]="?"
clover_gsym[ahead]="⇡"
clover_gsym[behind]="⇣"
clover_gsym[diverge]="⇕"

# constant
typeset -g clover_hide_elasped_time=10
typeset -g clover_basedir=${0:A:h}


# functions
clover_setup() {
    # dependency
    source $clover_basedir/lib/async/async.zsh

    # register hook
    add-zsh-hook precmd clover_precmd
    add-zsh-hook preexec clover_preexec

    # git
    ZSH_THEME_GIT_PROMPT_PREFIX="%{$clover_gcolor[head]%}"
    ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"

    ZSH_THEME_GIT_PROMPT_CLEAN="%{$clover_gcolor[clean]%}$clover_gsym[clean]%{$reset_color%}"
    ZSH_THEME_GIT_PROMPT_DIRTY="%{$clover_gcolor[dirty]%}$clover_gsym[dirty]%{$reset_color%}"

    ZSH_THEME_GIT_PROMPT_ADDED="%{$clover_gcolor[add]%}$clover_gsym[add]"
    ZSH_THEME_GIT_PROMPT_DELETED="%{$clover_gcolor[del]%}$clover_gsym[del]"
    ZSH_THEME_GIT_PROMPT_MODIFIED="%{$clover_gcolor[modify]%}$clover_gsym[modify]"
    ZSH_THEME_GIT_PROMPT_RENAMED="%{$clover_gcolor[rename]%}$clover_gsym[rename]"
    ZSH_THEME_GIT_PROMPT_UNMERGED="%{$clover_gcolor[unmerge]%}$clover_gsym[unmerge]"
    ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$clover_gcolor[untrack]%}$clover_gsym[untrack]"
    ZSH_THEME_GIT_PROMPT_AHEAD_REMOTE="%{$clover_gcolor[ahead]%}$clover_gsym[ahead]%{$reset_color%}"
    ZSH_THEME_GIT_PROMPT_BEHIND_REMOTE="%{$clover_gcolor[behind]%}$clover_gsym[behind]%{$reset_color%}"
    ZSH_THEME_GIT_PROMPT_DIVERGED_REMOTE="%{$clover_gcolor[diverge]%}$clover_gsym[diverge]%{$reset_color%}"

    # user name
    local color_user="%{$clover_color[user]%}"
    if [[ $UID -eq 0 ]]; then
        color_user="%{$bg[red]%}%{$fg_bold[white]%}"
    fi

    # hostname
    local color_host="%{$clover_color[host]%}"
    if [[ "$SSH_CONNECTION" != '' ]]; then
        color_host="%{$clover_color[host_remote]%}"
    fi

    # host
    local precmd=(
        # prefix
        "%{$clover_color[host_info]%}"
        $clover_sym[host_prefix]

        # user
        $color_user
        "%n"

        # splitter
        "%{$clover_color[host_info]%}"
        $clover_sym[host_split]

        # host
        $color_host
        "%m"
        "%{$reset_color%}"

        # suffix
        "%{$clover_color[host]%}"
        $clover_sym[host_suffix]

        # dir
        "%{$clover_color[dir]%}"
        "%~"
        "%{$reset_color%}"
    )

    typeset -g clover_lprompt0="${(j..)precmd}"

    # newline
    if [[ -z $prompt_newline ]]; then
        # This variable needs to be set, usually set by promptinit.
        typeset -g prompt_newline=$'\n%{\r%}'
    fi

    # some env setup
    export PROMPT_EOL_MARK=''
    export VIRTUAL_ENV_DISABLE_PROMPT=1

    setopt prompt_subst
}

clover_precmd() {
    local exit_code=$?

    # initialize async worker
    if [[ !${clover_async_init:-0} ]]; then
        async_start_worker "prompt_clover" -n
        async_register_callback "prompt_clover" clover_precmd_callback
        typeset -g clover_async_init=1
    fi

    # git
    unset clover_git_status
    async_job "prompt_clover" clover_git_prompt_info $PWD

    # elasped time
    local elasped_time=$((EPOCHSECONDS - ${clover_last_timestamp:-EPOCHSECONDS}))
    if (( $elasped_time >= $clover_hide_elasped_time )); then
        elasped_time="%{$clover_color[exectime]%}$(clover_readable_time $elasped_time) "
    else
        elasped_time=""
    fi

    # time
    local rps=(
        # elasped time
        $elasped_time

        # current time
        "%{$reset_color%}"
        "("
        "%{$clover_color[currtime]%}"
        "%*"
        "%{$reset_color%}"
        ") "
    )
    typeset -g clover_rprompt="${(j..)rps}"

    # venv
    typeset -g clover_venv_info=$(clover_virtualenv_info)

    # status
    typeset -g clover_prompt
    if [[ exit_code -eq 0 ]]; then
        clover_prompt="%{$clover_color[prompt]%}$clover_sym[prompt]"
    else
        clover_prompt="%{$clover_color[prompt_fail]%}$clover_sym[prompt_fail]"
    fi

    clover_render_prompt "precmd"
}

clover_preexec() {
    typeset -g clover_last_timestamp=$((EPOCHSECONDS))
}

clover_precmd_callback() {
    local job=$1 code=$2 output=$3 exec_time=$4 next_pending=$6
    case $job in
        clover_git_prompt_info)
            typeset -g clover_git_status=$output
        ;;
    esac

    clover_render_prompt
}

clover_render_prompt() {
    local lprompt=$clover_lprompt0$clover_git_status
    local precmd=$lprompt$(clover_get_space $lprompt $clover_rprompt)$clover_rprompt

    local ps1=(
        # precmd
        $precmd

        # new line
        $prompt_newline

        # venv
        $clover_venv_info

        # prompt
        $clover_prompt
        "%{$reset_color%}"
    )

    PROMPT="${(j..)ps1}"

    # Expand the prompt for future comparision.
    local expanded_prompt
    expanded_prompt="${(S%%)PROMPT}"

    if [[ $1 != precmd ]] && [[ $clover_last_prompt != $expanded_prompt ]]; then
        # Redraw the prompt.
        zle && zle .reset-prompt
    fi

    typeset -g clover_last_prompt=$expanded_prompt
}

clover_git_prompt_info() {
    builtin cd -q $1
    local git_head=$(git_prompt_info)
    if [[ -n $git_head ]]; then
        local git_detail

        # git status
        local git_status="$(git_prompt_status)"
        if [[ -n $git_status ]]; then
            git_detail=$git_detail$git_status
        fi

        # git remote
        local git_remote=$(git_remote_status)
        if [[ -n $git_remote ]]; then
            git_detail=$git_detail$git_remote
        fi

        # output
        if [[ -n $git_detail ]]; then
            git_detail="[$git_detail%{$reset_color%}]"
        fi
        echo " <$git_head$git_detail>"
    fi
}

# get space to padding between lprompt and rprompt
# https://github.com/skylerlee/zeta-zsh-theme
clover_get_space() {
    local str=$1$2
    local zero='%([BSUbfksu]|([FB]|){*})'
    local len=${#${(S%%)str//$~zero/}}
    local size=$(( $COLUMNS - $len - 1 ))
    local space=""
    while [[ $size -gt 0 ]]; do
        space="$space "
        let size=$size-1
    done
    echo $space
}

# get python env name
clover_virtualenv_info() {
    # virtualenv / venv
    # https://github.com/tonyseek/oh-my-zsh-virtualenv-prompt
    if [ -n "$VIRTUAL_ENV" ]; then
        if [ -f "$VIRTUAL_ENV/__name__" ]; then
            local name=`cat $VIRTUAL_ENV/__name__`
        elif [ `basename $VIRTUAL_ENV` = "__" ]; then
            local name=$(basename $(dirname $VIRTUAL_ENV))
        else
            local name=$(basename $VIRTUAL_ENV)
        fi
    fi

    # anaconda
    local condapath=$CONDA_ENV_PATH$CONDA_PREFIX
    if [ -n "$condapath" ]; then
        local name=$(basename $condapath)
    fi

    # display name
    if [ -n "$name" ]; then
        echo "%{$clover_color[venv]%}($name) "
    fi
}

# turns seconds into human readable time
# 165392 => 1d 21h 56m 32s
# https://github.com/sindresorhus/pretty-time-zsh
clover_readable_time() {
    local human total_seconds=$1
    local days=$(( total_seconds / 60 / 60 / 24 ))
    local hours=$(( total_seconds / 60 / 60 % 24 ))
    local minutes=$(( total_seconds / 60 % 60 ))
    local seconds=$(( total_seconds % 60 ))
    (( days > 0 )) && human+="${days}d "
    (( hours > 0 )) && human+="${hours}h "
    (( minutes > 0 )) && human+="${minutes}m "
    human+="${seconds}s"

    echo $human
}

# init
clover_setup
