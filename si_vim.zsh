# single instance vim - si_vim
# always keeps one instance of vim running in the background ready to be used
# for anything

# (N)VIM EXECUTABLE ------------------------------------------------------------
# figure out how to launch vim/nvim
if command -v nvim &> /dev/null; then
    _si_vim_exec=nvim
else
    _si_vim_exec=vim
fi

# COMMAND BUFFER ---------------------------------------------------------------
# file that vim sources when it is taken to foreground
_si_vim_resume_source_dir=$HOME/.local/state/si-vim
mkdir -p $_si_vim_resume_source_dir
_si_vim_resume_source=$_si_vim_resume_source_dir/$$.vim
_si_vim_modified=$_si_vim_resume_source.modified
# add to command buffer
function _si_vim_cmd() {
    echo "$1" >> $_si_vim_resume_source
}

# JOB --------------------------------------------------------------------------
# start background job if not running & set job_id
function _si_vim_run() {
    # check if si_vim is already running
    # write jobs to temporary file because calling `jobs` with a pipe doesn't
    # produce correct output
    local jobs_file="$(mktemp)"
    jobs -l > "$jobs_file"
    local si_vim_job="$(cat "$jobs_file" | grep 'SIVIM')"
    rm "$jobs_file"

    if [[ -z "$si_vim_job" ]]; then
        # no job running, start new
        SIVIM_RESUME_SOURCE=$_si_vim_resume_source SIVIM_MARK_MODIFIED=$_si_vim_modified $_si_vim_exec &
    fi
    # bring running job to foreground
    fg %SIVIM
}

# HOOKS ------------------------------------------------------------------------
autoload -U add-zsh-hook

# keep si_vim in same directory as zsh
function _si_vim_syncpwd() {
    (( ${+SI_VIM_DISABLED} )) || _si_vim_cmd "cd $(pwd)"
}
add-zsh-hook chpwd _si_vim_syncpwd

# KEYBINDINGS ------------------------------------------------------------------
# get current cursor line, works from ZLE
_si_vim_curpos() {
    local curpos
    printf "\e[6n" > /dev/tty
    read -sdR curpos < /dev/tty
    # extract line
    curpos=${curpos##*\[} # remove everything before the last `[`
    curpos=${curpos%%;*}  # remove everything after the first `;`
    echo $curpos
}

# reset prompt to line $1 after widget
_si_vim_widget_reset_prompt() {
    # check how many lines down we are
    local diff=$(( $(_si_vim_curpos) - $1 ))
    for _ in {1..$diff}; do
        # go one line up and clear it
        printf "\e[1A\r\e[K"
    done
    zle reset-prompt
}

# bring up si_vim
# user has to configure binding, e.g. `bindkey ^u _si_vim_widget`
_si_vim_widget() {
    local curpos="$(_si_vim_curpos)"
    _si_vim_run
    # reset prompt after we're back
    _si_vim_widget_reset_prompt $curpos

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
    _si_vim_run
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
                _si_vim_cmd "edit $arg"
            fi
        done
        for cmd in $cmd_buffer; do
            _si_vim_cmd "$cmd"
        done
    fi
    # if `siv` is called from widget we can run si-vim widget to clear job
    # control logs & reset the prompt cleanly, if not we just run
    zle && _si_vim_widget || _si_vim_run
}

function siv-enable() {
    unset SI_VIM_DISABLED
}

function siv-disable() {
    export SI_VIM_DISABLED
}
