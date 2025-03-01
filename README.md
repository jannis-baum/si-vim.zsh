# si-vim

Keep a single instance of (n)vim running & attached to each interactive Zsh
session. This enables you to switch back and forth between (n)vim and Zsh
instantly.

## Features

- automatically keep an instance of (n)vim running for each interactive Zsh
  session
- use `siv` or your own keybinding to go to (n)vim, use `:sus[pend]` (or a
  keybinding) to go back to Zsh
- open files from Zsh with `siv`, this will open (n)vim and
  - switch to the corresponding buffer if the file was already open, or
  - open the file in a new tab if it wasn't yet open
- automatically keep the working directory of Zsh & (n)vim in sync, i.e.
  whenever you change your directory in Zsh, the attached si-vim session will
  switch as well
- exiting `zsh` with `ctrl-d` will warn you in case you have unsaved changes in
  (n)vim and otherwise exit cleanly (you can disable this behavior by setting
  `$SI_VIM_NO_CTRL_D` before sourcing this plugin).
- disable/enable automatically keeping (n)vim open with `siv-[en|dis]able` or by
  setting/unsetting the environment variable `$SI_VIM_DISABLED`
- `siv` also supports running startup commands from arguments with the `+`
  prefix like (n)vim and will create all directories that don't exist for the
  given file path
- si-vim uses NeoVim by default if you have it installed and otherwise Vim

### Keybindings

I recommend setting a keybinding to switch back and forth between Zsh and
(n)vim.  To do this with `ctrl-u`, for example, add the following to your
`.zshrc`

```zsh
bindkey ^u _si_vim_widget
```

and to your `.vimrc` / `init.vim`

```vimscript
nnoremap <C-u> :suspend<CR>
```

Furthermore, depending on how you usually exit (n)vim, you will probably want to
reconfigure it to only close all buffers and suspend (n)vim instead of quitting
it.  I like doing this with `ZZ`, and keep the following in my `.vimrc`

```vimscript
nnoremap <S-z><S-z> :bufdo bw<CR>:sus<CR>
```

## Installation

To use this plugin, simply source all `.zsh` files from this repo in your
`.zshrc`, for example like this

```zsh
for script in $(find '<path to this repo>' -name '*.zsh'); do
    source $script
done
```

and all `.vim` files in your `.vimrc` / `init.vim`, for example like this

```vimscript
for f in glob($HOME . '<path to this repo>/**/*.vim', 0, 1)
    execute 'source ' . f
endfor
```

I do this by keeping this repository as a submodule in my
[dotfiles](https://github.com/jannis-baum/dotfiles.git). If you want to do this,
I recommend using my tool
[`sdf`](https://github.com/jannis-baum/sync-dotfiles.zsh) to manage your
dotfiles and their dependencies.
