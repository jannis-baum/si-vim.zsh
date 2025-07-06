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
    execute 'edit ' . a:file
    " fix some problem with ft detection
    filetype detect
endfunction
command! -nargs=1 -complete=file SivOpen call s:SivOpen(<q-args>)
