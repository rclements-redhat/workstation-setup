" vimrc Customization by Ryan Clements (rclement@redhat.com)
"
" CHANGE LOG
" April 1/2023
"   - Initial setup, set tabs to 2 spaces
"   - Add line numbers
"   - Add IdentLine plugin
"   - Higlight tabs with \ character
" Custom setup for Ansible and replaces tabs with spaces
" Set yaml to have a tab of 2 spaces
autocmd FileType yaml setlocal et ts=2 ai sw=2 nu sts=2
" Set all files to have a tab of 2 spaces
set et ts=2 ai sw=2 nu sts=2
set cursorline
" Make sure we replace tabs with \ so we know where those pesky tabs are
set list lcs=tab:\|\

" Set the indentLine characters
" let g:indentLine_char_list = ['|', '¦', '┆', '┊']

" If you're using a the custom font package 'Development.ttf', then you can use
" this following for a nice look. If it shows up at a box with a question mark
" in the middle while in vim, then you don't have the font pack installed
"
" ** You'll need to set the font to Development in vscode too to see it in this
" file if using vscode to view this configuration file
let g:indentLine_char = ''

" enables vscode-inspired colors in vim
colorscheme codedark

" set 80 character column line ruler
set colorcolumn=80

" Set line numbers on left side
set number

" Ensure Containerfile uses the Dockerfile syntax
autocmd BufNewFile,BufRead Containerfile set filetype=dockerfile

" disable errorbells and visualbells
set noerrorbells visualbell t_vb=

" Ensure once gui loads, visualbell is cleared again
autocmd GUIEnter * set visualbell t_vb=
