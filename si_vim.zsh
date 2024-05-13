# single instance vim - si_vim
# always keeps one instance of vim running in the background ready to be used
# for anything

# COMMAND BUFFER ---------------------------------------------------------------
# file that vim sources when it is taken to foreground
_si_vim_resume_source_dir=$HOME/.vim/resume-source
mkdir -p $_si_vim_resume_source_dir
_si_vim_resume_source=$_si_vim_resume_source_dir/$$.vim
_si_vim_modified=$_si_vim_resume_source.modified
# add to command buffer
function _si_vim_cmd() {
    echo "$1" >> $_si_vim_resume_source
}

# JOB --------------------------------------------------------------------------
# function to find job name in list
function _si_vim_job() {
    SIVIM_RESUME_SOURCE=$_si_vim_resume_source SIVIM_MARK_MODIFIED=$_si_vim_modified vim
}
# check if si_vim is running
function _si_vim_isrunning() {
    [[ -n "$(jobs | grep '_si_vim_job')" ]]
}

# HOOKS ------------------------------------------------------------------------
autoload -U add-zsh-hook

# ensure si_vim is always running
function _si_vim_run() {
    (( ${+SI_VIM_DISABLED} )) || _si_vim_isrunning || _si_vim_job &
}
add-zsh-hook precmd _si_vim_run

# keep si_vim in same directory as zsh
function _si_vim_syncpwd() {
    (( ${+SI_VIM_DISABLED} )) || _si_vim_cmd "cd $(pwd)"
}
add-zsh-hook chpwd _si_vim_syncpwd

# KEYBINDINGS ------------------------------------------------------------------
# bring up si_vim
# user has to configure binding, e.g. `bindkey ^u _si_vim_widget`
_si_vim_widget() {
    BUFFER="fg %_si_vim_job"
    zle accept-line; zle reset-prompt
}
zle -N _si_vim_widget

# safely quit vim & shell if no unsaved changes
_si_vim_safe_exit() {
    if test -e $_si_vim_modified; then
        echo "\nVim has unsaved changes."
        zle reset-prompt
        return
    fi
    _si_vim_cmd ":qa"
    fg %_si_vim_job
    rm -f $_si_vim_resume_source $_si_vim_modified
    exit
}
zle -N _si_vim_safe_exit
if ! (( ${+SI_VIM_NO_CTRL_D} )); then
    bindkey '^d' _si_vim_safe_exit
    # prevent ^d from sending eof
    stty eof undef
fi

# USER FUNCTIONS ---------------------------------------------------------------
# open file in running si_vim
# create directories if needed for new file
# supports running additional commands in vim prefixed by +
function siv() {
    if ! [[ $# == 0 ]]; then
        local -a cmd_buffer
        for arg in $@; do
            if [[ $arg =~ '^\+' ]]; then
                cmd_buffer+=("$(sed -e 's/"/\\"/g' -e 's/^\+\(.*\)/:exec "\1"/' <<< $arg)")
            else
                mkdir -p $(dirname $arg)
                _si_vim_cmd "SivOpen $arg"
            fi
        done
        for cmd in $cmd_buffer; do
            _si_vim_cmd "$cmd"
        done
    fi
    fg %_si_vim_job
}

function siv-enable() {
    unset SI_VIM_DISABLED
}

function siv-disable() {
    export SI_VIM_DISABLED
}
