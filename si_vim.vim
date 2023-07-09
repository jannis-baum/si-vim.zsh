augroup Suspension
    autocmd!
    " execute commands after resuming from suspension
    autocmd VimResume,VimEnter * if filereadable($SIVIM_RESUME_SOURCE)
            \| execute('source ' . $SIVIM_RESUME_SOURCE)
            \| call delete($SIVIM_RESUME_SOURCE)
        \| endif
    " set modified marker if not all files were saved
    autocmd VimSuspend * if !empty($SIVIM_MARK_MODIFIED)
            \| if getbufinfo({  'buflisted': 1 })->filter({ _, buf -> buf.changed })->len() > 0
                \| call writefile([''], $SIVIM_MARK_MODIFIED)
            \| else
                \| call delete($SIVIM_MARK_MODIFIED)
            \| endif
        \| endif
augroup END

function! s:SivOpen(file)
    " we check if the file is open anywhere and switch to its buffer
    " this works well with `set switchbuf=usetab`
    for buf in getbufinfo({ 'bufloaded': 1 })
        if buf.name =~ a:file
            execute 'sbuffer ' . buf.bufnr
            return
        endif
    endfor

    " if the buffer is empty, e.g. when we just opened vim without a file, we
    " edit the file in the current buffer
    if (expand('%:p') == '')
        execute 'edit ' . a:file
    else
        " else we open the file in a new tab
        execute 'tabedit ' . a:file
    endif
    " fix some problem with ft detection
    filetype detect
endfunction
command! -nargs=1 -complete=file SivOpen call s:SivOpen(<q-args>)
