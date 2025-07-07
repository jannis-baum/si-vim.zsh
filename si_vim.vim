function! s:OnResume(_)
    if filereadable($SIVIM_RESUME_SOURCE)
        execute('source ' . $SIVIM_RESUME_SOURCE)
        call delete($SIVIM_RESUME_SOURCE)
    endif
endfunction

augroup Suspension
    autocmd!
    " execute commands after resuming from suspension, with 0-timer to run it on
    " main event loop so autocmds run correctly
    autocmd VimResume,VimEnter * call timer_start(0, 's:OnResume')
    " set modified marker if not all files were saved
    autocmd VimSuspend * if !empty($SIVIM_MARK_MODIFIED)
            \| if getbufinfo({  'buflisted': 1 })->filter({ _, buf -> buf.changed })->len() > 0
                \| call writefile([''], $SIVIM_MARK_MODIFIED)
            \| else
                \| call delete($SIVIM_MARK_MODIFIED)
            \| endif
        \| endif
augroup END
