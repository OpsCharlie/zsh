# If not running interactively, do not do anything
[[ -z "$PS1" ]] && return


function fn_timer_now {
    date +%s%N
}

function fn_timer_start {
    timer_start=${timer_start:-$(fn_timer_now)}
}

function timer_stop {
    local delta_us=$((($(fn_timer_now) - $timer_start) / 1000))
    local us=$((delta_us % 1000))
    local ms=$(((delta_us / 1000) % 1000))
    local s=$(((delta_us / 1000000) % 60))
    local m=$(((delta_us / 60000000) % 60))
    local h=$((delta_us / 3600000000))
    # Goal: always show around 3 digits of accuracy
    if ((h > 0)); then timer_show=${h}h${m}m
    elif ((m > 0)); then timer_show=${m}m${s}s
    elif ((s >= 10)); then timer_show=${s}.$((ms / 100))s
    elif ((s > 0)); then timer_show=${s}.$(printf %03d $ms)s
    elif ((ms >= 100)); then timer_show=${ms}ms
    elif ((ms > 0)); then timer_show=${ms}.$((us / 100))ms
    else timer_show=${us}us
    fi
    unset timer_start
}


function __makePS1() {
    local EXIT="$?"

    timer_stop
    PS1=''

    PS1+="${YELLOW}${timer_show}${COLOR_OFF} "
    PS1+="${debian_chroot:+($debian_chroot)}"

    if [[ ${USER} = root ]]; then
        PS1+="${BOLD_RED}" # root
    elif [[ ${USER} != "${LNAME}" ]]; then
        PS1+="${BOLD_BLUE}" # normal user
    else
        if [[ -n ${SSH_CONNECTION} ]]; then
            PS1+="${BOLD_GREEN}" # normal user with ssh
        else
            PS1+="${GREEN}" # normal local user
        fi
    fi
    PS1+="%n${COLOR_OFF}"

    if [[ -n ${SSH_CONNECTION} || ${USER} = root ]]; then
        if [[ ${USER} = root ]]; then
            PS1+="${BOLD_RED}@%m${COLOR_OFF}" # host displayed red when root
        else
            PS1+="${BOLD_GREEN}@"
            PS1+="${HOST_COLOR}%m${COLOR_OFF}" # host displayed only if ssh connection
        fi
    fi

    # working directory
    PS1+=":${BOLD_BLUE}%~${COLOR_OFF}"

    # python env
    if [[ -v VIRTUAL_ENV ]]; then
      PS1+=" ${YELLOW}(${VIRTUAL_ENV##*/})${COLOR_OFF}"
    fi

    # background jobs
    PS1+="${GREEN}%(1j. [%j].)${COLOR_OFF}"

    # git branch
    if [[ $GIT_AVAILABLE = "1" ]] && [[ $GIT = "1" ]]; then
        local branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"

        if [[ -n ${branch} ]]; then
            local git_status="$(git status --porcelain -b 2>/dev/null)"
            local letters="$( echo "${git_status}" | grep --regexp=' \w ' | sed -e 's/^\s\?\(\w\)\s.*$/\1/' )"
            local untracked="$( echo "${git_status}" | grep -F '?? ' | sed -e 's/^\?\(\?\)\s.*$/\1/' )"
            local status_line="$( echo -e "${letters}\n${untracked}" | sort | uniq | tr -d '[:space:]' )"
            PS1+=" ${CYAN}(${branch}"
            if [[ -n ${status_line} ]]; then
                PS1+=" ${status_line}"
            fi
            PS1+=")${COLOR_OFF}"
        fi
    fi

    # exit code
    PS1+="${BOLD_RED}%(?.. [!%?])${COLOR_OFF}"

    # prompt
    if [[ ${USER} = root ]]; then
        PS1+=" ${BOLD_RED}\$${COLOR_OFF} " # root
    elif [[ ${USER} != ${LNAME} ]]; then
        PS1+=" ${BOLD_BLUE}\$${COLOR_OFF} " # normal user but not login
    else
        PS1+=" ${BOLD_GREEN}\$${COLOR_OFF} " # normal user
    fi

}

#load colors
autoload -Uz colors && colors
for COLOR in RED GREEN YELLOW BLUE MAGENTA CYAN BLACK WHITE; do
    eval $COLOR='%{$fg_no_bold[${(L)COLOR}]%}'  #wrap colours between %{ %} to avoid weird gaps in autocomplete
    eval BOLD_$COLOR='%{$fg_bold[${(L)COLOR}]%}'
done
eval COLOR_OFF='%{$reset_color%}'


# Color man-pages
export GROFF_NO_SGR=1

# export LESS_TERMCAP_mb=$'\e[01;31m'       # begin blinking
# export LESS_TERMCAP_md=$'\e[01;38;5;74m'  # begin bold
# export LESS_TERMCAP_me=$'\e[0m'           # end mode
# export LESS_TERMCAP_se=$'\e[0m'           # end standout-mode
# export LESS_TERMCAP_so=$'\e[38;5;246m'    # begin standout-mode - info box
# # export LESS_TERMCAP_so=$'\e[30;43m'
# export LESS_TERMCAP_ue=$'\e[0m'           # end underline
# export LESS_TERMCAP_us=$'\e[04;38;5;146m' # begin underline

# Catppuccin theme
export LESS_TERMCAP_mb=$'\e[1;38;5;204m'
export LESS_TERMCAP_md=$'\e[1;38;2;198;160;246m'  # #c6a0f6
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[48;2;49;50;68;38;2;205;214;244m'  # bg #313244, fg #cdd6f4
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[4;38;2;116;199;236m'  # #74c7ec

# Colorized theme
# export LESS_TERMCAP_mb=$'\e[1;33m'
# export LESS_TERMCAP_md=$'\e[1;34m'
# export LESS_TERMCAP_me=$'\e[0m'
# export LESS_TERMCAP_se=$'\e[0m'
# export LESS_TERMCAP_so=$'\e[30;47m'  # or $'\e[7m' for terminal default reverse
# export LESS_TERMCAP_ue=$'\e[0m'
# export LESS_TERMCAP_us=$'\e[4;36m'

### completions
# use /usr/share/zsh/site-functions for zsh-completions
fpath=($fpath /usr/share/zsh/site-functions)

# Command completion
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select
zstyle ':completion::complete:*' gain-privileges 1
zstyle ':completion:*' rehash true
setopt COMPLETE_ALIASES
zstyle ':completion:*' matcher-list '' \
  'm:{a-z\-}={A-Z\_}' \
  'r:[^[:alpha:]]||[[:alpha:]]=** r:|=* m:{a-z\-}={A-Z\_}' \
  'r:|?=** m:{a-z\-}={A-Z\_}'


# Command completion bash compatible
autoload -Uz bashcompinit
bashcompinit
export -f _have() { command -v $@ >/dev/null }


# Easily prefix your current or previous commands with sudo by pressing [esc] twice
sudo-command-line() {
    [[ -z $BUFFER ]] && zle up-history
    if [[ $BUFFER == sudo\ * ]]; then
        LBUFFER="${LBUFFER#sudo }"
    elif [[ $BUFFER == $EDITOR\ * ]]; then
        LBUFFER="${LBUFFER#$EDITOR }"
        LBUFFER="sudoedit $LBUFFER"
    elif [[ $BUFFER == sudoedit\ * ]]; then
        LBUFFER="${LBUFFER#sudoedit }"
        LBUFFER="$EDITOR $LBUFFER"
    else
        LBUFFER="sudo $LBUFFER"
    fi
}
zle -N sudo-command-line
# Defined shortcut keys: [Esc] [Esc]
bindkey -M emacs '\e\e' sudo-command-line
bindkey -M vicmd '\e\e' sudo-command-line
bindkey -M viins '\e\e' sudo-command-line


# History search
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

[[ -n ${key[Up]}   ]] && bindkey -- "${key[Up]}"   up-line-or-beginning-search
[[ -n ${key[Down]} ]] && bindkey -- "${key[Down]}" down-line-or-beginning-search


# Dirstack. Usages: dirs -v
autoload -Uz add-zsh-hook
DIRSTACKFILE="${HOME}/.cache/zsh/dirs"
if [[ ! -d ${HOME}/.cache/zsh ]]; then
    mkdir -p ${HOME}/.cache/zsh
fi
if [[ -f $DIRSTACKFILE ]] && (( ${#dirstack} == 0 )); then
	dirstack=("${(@f)"$(< "$DIRSTACKFILE")"}")
	[[ -d ${dirstack[1]} ]] && cd -- "${dirstack[1]}"
fi
chpwd_dirstack() {
	print -l -- "$PWD" "${(u)dirstack[@]}" > "$DIRSTACKFILE"
}
add-zsh-hook -Uz chpwd chpwd_dirstack

DIRSTACKSIZE='20'

setopt AUTO_PUSHD PUSHD_SILENT PUSHD_TO_HOME PUSHD_IGNORE_DUPS PUSHD_MINUS

# enable color support of ls and also add handy aliases
if [[ -x /usr/bin/dircolors ]]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi


# aliases
if [[ -f ~/.zsh_aliases ]]; then
    . ~/.zsh_aliases
fi


# history
HISTSIZE=65535
SAVEHIST=65535
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
HISTFILE=${HOME}/.zsh_history
HISTORY_IGNORE='&:[ ]*:exit:ls:bg:fg:history:clear'


# set login name
if ! logname &>/dev/null; then
    LNAME=${USER}
else
    LNAME=$(logname)
fi


# is git available
[[ -x "$(command -v git 2>&1)" ]] && GIT_AVAILABLE=1 || GIT_AVAILABLE=0


# set base session and git when logged in via ssh
if [[ -n $SSH_CLIENT ]] || [[ -n $SSH_TTY ]]; then
    base_session='C-b'
    GIT=0
else
    base_session='C-a'
    # if tmux is enabled, disable git prompt. tmux will show git.
    # [[ $EN_TMUX -eq "1" ]] && GIT=0 || GIT=1
    GIT=1
fi


# enable/disable tmux loading
[[ ${USER} = root ]] && EN_TMUX=0 || EN_TMUX=1
command -v tmux &>/dev/null || EN_TMUX=0
[[ -z $KITTY_PID ]] || EN_TMUX=0


# Is loaded via vim
IN_VIM=$(ps -p $PPID -o comm= | grep -qsE '[gn]?vim' && echo 1 || echo 0)
if [[ $IN_VIM -eq 1 ]]; then
    GIT=0
    EN_TMUX=0
fi


# enable tmux and start session
if [[ $EN_TMUX -eq 1 ]]; then
    ## TMUX
    #if which tmux >/dev/null 2>&1; then
    #    #if not inside a tmux session, and if no session is started, start a new session
    #    test -z "$TMUX" && (tmux attach || tmux new-session)
    #fi

    if [[ -z $TMUX ]]; then
        # Create a new session if it does not exist
        tmux has-session -t $base_session || tmux new-session -d -s $base_session
        # Are there any clients connected already?
        client_cnt=$(tmux list-clients | wc -l)
        if [[ $client_cnt -ge 1 ]]; then
            session_name=$base_session"-"$client_cnt
            tmux new-session -d -t $base_session -s $session_name
            tmux -2 attach-session -t $session_name \; set-option destroy-unattached
        else
            tmux -2 attach-session -t $base_session
        fi
    fi
fi


# keybinding
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

### main
function my_preexec() {
  fn_timer_start
}

function my_precmd() {
    if [[ ! $timer_start ]]; then fn_timer_start; fi
    __makePS1
}

# Register prompt and timer hooks
precmd_functions+=(my_precmd)
preexec_functions+=(my_preexec)

# set PATH so it includes user's private bin if it exists
zsh_path_dirs=(
  "$HOME/bin"
  "$HOME/.local/bin"
)
for dir in "${zsh_path_dirs[@]}"; do
  [[ -d $dir ]] && PATH="$dir:$PATH"
done


zsh_source_files=(
  "/usr/share/bash-completion/completions/lxc.zsh"
  "etc/zsh_command_not_found"
  "$HOME/venv/3.12.3/bin/activate"
)
for file in "${zsh_source_files[@]}"; do
  [[ -f $file ]] && source "$file"
done

# Configured by fzf installer
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh


export NVM_DIR="$HOME/.nvm"
[[ -s $NVM_DIR/nvm.sh ]] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[[ -s $NVM_DIR/bash_completion ]] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# remove duplicate entries
PATH="$(awk -v RS=: '!a[$1]++{if(NR>1)printf ":";printf $1}' <<< "$PATH")"
export PATH
