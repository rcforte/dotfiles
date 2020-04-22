filetype on
filetype plugin on
filetype indent on
syntax on

set nowrap
set linebreak
set number
set cursorline
set wildmenu
set lazyredraw
set showmatch
set incsearch
set hlsearch
set nofoldenable
set ignorecase
set ruler
set title
set tabstop=4 softtabstop=0 expandtab shiftwidth=2 smarttab
set autoread
set confirm
set showcmd
set showmode

"colorscheme Monokai
"colorscheme blacklight
colorscheme dracula

"Optional settings
"colorscheme gruvbox
"set tabstop=2 softtabstop=0 expandtab shiftwidth=2 smarttab
"set background=dark

imap kj <Esc>
noremap <Leader>q :wq<CR>
nnoremap B ^
nnoremap E $
nnoremap <C-n> :bnext<CR>
nnoremap <C-p> :bprevious<CR>

au VimEnter * RainbowParenthesesToggle
au syntax * RainbowParenthesesLoadRound
au syntax * RainbowParenthesesLoadSquare
au syntax * RainbowParenthesesLoadBraces

