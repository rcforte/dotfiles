"
" Settings
"
syntax on

set noerrorbells
set tabstop=4 softtabstop=4
set shiftwidth=2
set expandtab
set smartindent
set nu
set nowrap
set smartcase
set noswapfile
set nobackup
set undodir=~/.vim/undodir
set undofile
set incsearch
set cursorline
set colorcolumn=80
highlight ColorColumn ctermbg=0 guibg=lightgrey

"
" Plugins
"
set encoding=UTF-8
set nocompatible
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'
Plugin 'tpope/vim-surround'
Plugin 'tpope/vim-commentary'
Plugin 'tpope/vim-repeat'
Plugin 'scrooloose/nerdtree'
Plugin 'kien/ctrlp.vim'
Plugin 'kien/rainbow_parentheses.vim'
Plugin 'bling/vim-airline'
Plugin 'easymotion/vim-easymotion'
Plugin 'flazz/vim-colorschemes'
Plugin 'yggdroot/indentline'
Plugin 'mxw/vim-jsx'
Plugin 'pangloss/vim-javascript'
Plugin 'leafgarland/typescript-vim'
Plugin 'ryanoasis/vim-devicons'
"Plugin 'vwxyutarooo/nerdtree-devicons-syntax'
Plugin 'tiagofumo/vim-nerdtree-syntax-highlight'
Plugin 'junegunn/goyo.vim'
Plugin 'itchyny/lightline.vim'
Plugin 'matze/vim-move'
Plugin 'mileszs/ack.vim'
Plugin 'mru.vim'
"Plugin 'valloric/youcompleteme'
Plugin 'ycm-core/youcompleteme'
call vundle#end()

filetype plugin indent on

" Color
colorscheme dracula

" Rainbow
augroup rainbow
au!
au VimEnter * RainbowParenthesesToggle
au Syntax * RainbowParenthesesLoadRound
au Syntax * RainbowParenthesesLoadSquare
au Syntax * RainbowParenthesesLoadBraces
augroup END

"
" Mappings
"
inoremap kj <Esc>
noremap <space> /
noremap <C-space> ?

" Leader
let mapleader = ","
noremap <Leader>w :wa!<CR>
noremap <Leader>q :wq<CR>
noremap <silent> <leader>bd :Bclose<CR>
noremap <silent> <leader>ba :1,1000 bd!<CR>
noremap <silent> <leader><cr> :noh<cr>

" Begin/End of line
nnoremap B ^
nnoremap E $

" Next/Previous file
nnoremap <C-n> :bnext<CR>
nnoremap <C-p> :bprevious<CR>

" Goyo
nnoremap <silent> <leader>z :Goyo<CR>

" NERDTree
noremap <leader>nn :NERDTreeToggle<cr>
noremap <leader>nb :NERDTreeFromBookmark 
noremap <leader>nf :NERDTreeFind<cr>
let g:NERDTreeDirArrowExpandable = '▸'
let g:NERDTreeDirArrowCollapsible = '▾'

" MRU
noremap <leader>f :MRU<CR>

" Cntrl-p
let g:ctrlp_map = '<C-f>'
noremap <leader>j :CtrlP<cr>
noremap <C-b> :CtrlPBuffer<cr>

" Surround
vnoremap Si S(i_<esc>f)
augroup surround
au!
au FileType mako vmap Si S"i${ _(<esc>2f"a) }<esc>
augroup END

" Vim Move Plugin
let g:move_key_modifier = 'C'

" Moving between windows (I don't mind doing C-W)
"map <C-j> <C-W>j
"map <C-k> <C-W>k
"map <C-h> <C-W>h
"map <C-l> <C-W>l
