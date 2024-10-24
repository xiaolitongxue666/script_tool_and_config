"  __  __        __     _____ __  __ ____   ____
" |  \/  |_   _  \ \   / /_ _|  \/  |  _ \ / ___|
" | |\/| | | | |  \ \ / / | || |\/| | |_) | |
" | |  | | |_| |   \ V /  | || |  | |  _ <| |___
" |_|  |_|\__, |    \_/  |___|_|  |_|_| \_\\____|
"         |___/

" Todos
" - pylint reports error when doing `vim ~/Github/vim-calc/build-up/calc.py`
"   instead of doing `cd ~/Github/vim-calc/build-up` and then do `vim calc.py`
" - hotkey to switch between light theme and dark theme (in progress, still
"   some bugs
"
"
"   Testing
"fnew
"call nvim_win_float_set_pos(0,5,10,20,5)
"hi Floating guibg=#00044
"set withhl=Normal:Floating


" ===
" === Auto load for first time uses
" ===
"if empty(glob('~/.config/nvim/autoload/plug.vim'))
"  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
"    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
"  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC"
"endif

" ====================
" === Editor Setup ===
" ====================

" ===
" === System 
" ===
" copy form system clipboard
set clipboard=unnamed

" compatible with vi
set nocompatible

" automatic change working dir at now edit file's path
set autochdir

" let the color compatible to terminal
let &t_ut=' '

" file type identification
filetype on
filetype indent on
filetype plugin on
filetype plugin indent on

" encoding format
set encoding=utf-8

" ===
" === Editor behavior
" ===
"hight light syntax
syntax on

"show line number
set number

"show relative line number
set relativenumber

"show corsor line
set cursorline

" expand tab
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4

" show the space at the end of line
set list

" show the tab
set listchars=tab:▸\ ,trail:▫

" corsor distance form buffer edge some lines
set scrolloff=5

set ttimeoutlen=0

set viewoptions=cursor,folds,slash,unix

"automatic line break
set wrap

set tw=0

set indentexpr=

set foldmethod=indent

set foldlevel=99

set formatoptions-=tc

set splitright

set splitbelow

"enable mouse in vim
set mouse=a

let &t_SI = "\<Esc>]50;CursorShape=1\x7"
let &t_SR = "\<Esc>]50;CursorShape=2\x7"
let &t_EI = "\<Esc>]50;CursorShape=0\x7"

" open the fiel cursor at hte last edited position
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

" ===
" === Terminal Behavior
" ===
let g:neoterm_autoscroll = 1

autocmd TermOpen term://* startinsert

"tnoremap <C-N> <C-\><C-N>:q<CR>

" ===
" === Status bar behaviors
" ===
set noshowmode

"show type command
set showcmd

" set wildignore=log/**,node_modules/**,target/**,tmp/**,*.rbc

"open command line comletion in enhanced mode
set wildmenu

" Searching options
"high light search
set hlsearch
"clear search high light whem use vim or nvim open a file
exec "nohlsearch"
"charter by charter high light the entered words during the search
set incsearch 
"ignore case the word during the search
set ignorecase
set smartcase
"jump to search result next one
noremap n nzz
"jumo to search result last one
noremap N Nzz
"clear all search high light
noremap <LEADER><CR> :nohlsearch<CR>

" ===
" === Basic Mappings
" ===

" Set <LEADER> as <SPACE>, ; as :
let mapleader=" "
"map ; :

" Save & quit
map S :w<CR>
map Q :q<CR>

" Reload config file
map R :source $MYVIMRC<CR>

" Open the vimrc file anytime
map <LEADER>rc :e ~/.config/nvim/init.vim<CR>

" Open Startify
map <LEADER>st :Startify<CR>

" Undo operations
"noremap l u
" Undo in Insert mode
"inoremap <C-l> <C-u>

" Insert Key
noremap h i
noremap H I 
" Visual mode key map
vnoremap h i
vnoremap H I 

" Copy to system clipboard
vnoremap Y :w !xclip -i -sel c<CR>

" Duplicate words
"map <LEADER>dw /\(\<\w\+\>\)\_s*\1

" Folding
"map <silent> <LEADER>o za

" ===
" === Cursor Movement
" ===
"
" New cursor movement (the default arrow keys are used for resizing windows)
"     ^
"     i
" < j   l >
"     k
"     v
noremap i k
noremap k j 
noremap j h
noremap l l

" I/K keys for 5 times i/k (faster navigation)
noremap I 5k
noremap K 5j
" J/L keys for 5 times j/l (faster navigation)
"noremap J 5h
"noremap L 5l
" J key: go to the start of the line
noremap J 0
" L key: go to the end of the line
noremap L $

" Faster in-line navigation
"noremap W 5w
"noremap B 5b
" set h (same as n, cursor left) to 'end of word'
"noremap h e

" Ctrl + I or K will move up/down the view port without moving the cursor
noremap <C-I> 5<C-y>
noremap <C-K> 5<C-e>
"inoremap <C-I> <Esc>5<C-y>a
"inoremap <C-K> <Esc>5<C-e>a

" ===
" === Window management
" ===
" Use <space> + new arrow keys for moving the cursor around windows
map <LEADER>i <C-w>k
map <LEADER>k <C-w>j
map <LEADER>j <C-w>h
map <LEADER>l <C-w>l

" Disabling the default s key
noremap s <nop>

" split the screens to up (horizontal), down (horizontal), left (vertical), right (vertical)
map sl :set splitright<CR>:vsplit<CR>
map sj :set nosplitright<CR>:vsplit<CR>
map si :set nosplitbelow<CR>:split<CR>
map sk :set splitbelow<CR>:split<CR>

" Resize splits with arrow keys
map <up> :res +5<CR>
map <down> :res -5<CR>
map <left> :vertical resize+5<CR>
map <right> :vertical resize-5<CR>

" Place the two screens up and down
map sh <C-w>t<C-w>K
" Place the two screens side by side
map sv <C-w>t<C-w>H

" Rotate screens
noremap srh <C-w>b<C-w>K
noremap srv <C-w>b<C-w>H

" ===
" === Tab management
" ===
" Create a new tab with tu
map tu :tabe<CR>
" Move around tabs with tj and tl
map tj :-tabnext<CR>
map tl :+tabnext<CR>
" Move the tabs with tmj and tml
map tmj :-tabmove<CR>
map tml :+tabmove<CR>

" ===
" === Other useful stuff
" ===

" Opening a terminal window
map <LEADER>/ :set splitbelow<CR>:sp<CR>:term<CR>

" Press space twice to jump to the next '<++>' and edit it
"map <LEADER><LEADER> <Esc>/<++><CR>:nohlsearch<CR>c4i

" Spelling Check with <space>sc
"map <LEADER>sc :set spell!<CR>
"noremap <C-x> ea<C-x>s
"inoremap <C-x> <Esc>ea<C-x>s

" Press ` to change case (instead of ~)
"map ` ~

"imap <C-c> <Esc>zza
"nmap <C-c> zz

" Auto change directory to current dir
"autocmd BufEnter * silent! lcd %:p:h

" Call figlet
"map tx :r !figlet

" Compile function
"map r :call CompileRunGcc()<CR>
"func! CompileRunGcc()
  "exec "w"
  "if &filetype == 'c'
    "exec "!g++ % -o %<"
    "exec "!time ./%<"
  "elseif &filetype == 'cpp'
    "exec "!g++ % -o %<"
    "exec "!time ./%<"
  "elseif &filetype == 'java'
    "exec "!javac %"
    "exec "!time java %<"
  "elseif &filetype == 'sh'
    ":!time bash %
  "elseif &filetype == 'python'
    "set splitright
    ":vsp
    ":vertical resize-20
    ":term python3 %
  "elseif &filetype == 'html'
    "exec "!chromium % &"
  "elseif &filetype == 'markdown'
    "exec "MarkdownPreview"
  "endif
"endfunc

"map R :call CompileBuildrrr()<CR>
"func! CompileBuildrrr()
  "exec "w"
  "if &filetype == 'vim'
    "exec "source $MYVIMRC"
  "elseif &filetype == 'markdown'
    "exec "echo"
  "endif
"endfunc


" ===
" === Install Plugins with Vim-Plug
" === In normal mode type "PlugInstall" to install plugs
" ===
"vim-plug begin
call plug#begin('~/.config/nvim')

"Pretty Dress
"status bar
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
"show the list of buffers in the command bar
Plug 'bling/vim-bufferline'

" File navigation
Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'ctrlpvim/ctrlp.vim', { 'on': 'CtrlP' }

" Taglist
Plug 'majutsushi/tagbar', { 'on': 'TagbarOpenAutoClose' }

" Error checking
"Plug 'w0rp/ale'

" Auto Complete
"Plug 'Valloric/YouCompleteMe'
"Plug 'neoclide/coc.nvim', {'branch': 'release'}
" Plug 'davidhalter/jedi-vim'
"Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'ncm2/ncm2'
Plug 'ncm2/ncm2-jedi'
Plug 'ncm2/ncm2-github'
Plug 'ncm2/ncm2-bufword'
Plug 'ncm2/ncm2-path'
"Plug 'ncm2/ncm2-match-highlight'
Plug 'ncm2/ncm2-markdown-subscope'

" Language Server
"Plug 'autozimu/LanguageClient-neovim', {
    "\ 'branch': 'next',
    "\ 'do': 'bash install.sh',
    "\ }

"" (Optional) Multi-entry selection UI.
Plug 'junegunn/fzf'

" Undo Tree
Plug 'mbbill/undotree/'

" Other visual enhancement
Plug 'nathanaelkane/vim-indent-guides'
"Plug 'itchyny/vim-cursorword'
"Plug 'tmhedberg/SimpylFold'
Plug 'mhinz/vim-startify'

" Git
Plug 'rhysd/conflict-marker.vim'
Plug 'tpope/vim-fugitive'
Plug 'mhinz/vim-signify'
Plug 'gisphm/vim-gitignore', { 'for': ['gitignore', 'vim-plug'] }

" HTML, CSS, JavaScript, PHP, JSON, etc.
Plug 'elzr/vim-json'
Plug 'hail2u/vim-css3-syntax'
Plug 'spf13/PIV', { 'for' :['php', 'vim-plug'] }
Plug 'gko/vim-coloresque', { 'for': ['vim-plug', 'php', 'html', 'javascript', 'css', 'less'] }
Plug 'pangloss/vim-javascript', { 'for' :['javascript', 'vim-plug'] }
Plug 'mattn/emmet-vim'

" Python
Plug 'vim-scripts/indentpython.vim', { 'for' :['python', 'vim-plug'] }
Plug 'numirias/semshi', { 'do': ':UpdateRemotePlugins' }

" Markdown
Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install_sync() }, 'for' :['markdown', 'vim-plug'] }
Plug 'dhruvasagar/vim-table-mode', { 'on': 'TableModeToggle' }

" For general writing
Plug 'reedes/vim-wordy'
Plug 'ron89/thesaurus_query.vim'

" Bookmarks
Plug 'kshenoy/vim-signature'

" Other useful utilities
Plug 'jiangmiao/auto-pairs'
Plug 'terryma/vim-multiple-cursors'
Plug 'junegunn/goyo.vim' " distraction free writing mode
Plug 'tpope/vim-surround' " type ysks' to wrap the word with '' or type cs'` to change 'word' to `word`
Plug 'godlygeek/tabular' " type ;Tabularize /= to align the =
Plug 'gcmt/wildfire.vim' " in Visual mode, type i' to select all text in '', or type i) i] i} ip
Plug 'scrooloose/nerdcommenter' " in <space>cc to comment a line
"Plug 'yuttie/comfortable-motion.vim'
Plug 'brooth/far.vim'
Plug 'tmhedberg/SimpylFold'
Plug 'kassio/neoterm'
Plug 'vim-scripts/restore_view.vim'

" Dependencies
Plug 'MarcWeber/vim-addon-mw-utils'
Plug 'kana/vim-textobj-user'
Plug 'roxma/nvim-yarp'

"color
Plug 'connorholyday/vim-snazzy'

"vim-plag end
call plug#end()

" ===
" === Create a _machine_specific.vim file to adjust machine specific stuff, like python interpreter location
" ===
"let has_machine_specific_file = 1
"if empty(glob('~/.config/nvim/_machine_specific.vim'))
"  let has_machine_specific_file = 0
"  silent! exec "!cp ~/.config/nvim/default_configs/_machine_specific_default.vim ~/.config/nvim/_machine_specific.vim"
"endif
"source ~/.config/nvim/_machine_specific.vim

"open transparent and color
let g:SnazzyTransparent = 1
color snazzy 

" ===
" === Dress up my vim
" ===
"map <LEADER>c1 :set background=dark<CR>:colorscheme snazzy<CR>:AirlineTheme dracula<CR>
"map <LEADER>c2 :set background=light<CR>:colorscheme ayu<CR>:AirlineTheme ayu_light<CR>

set termguicolors     " enable true colors support
"colorscheme snazzy
let g:space_vim_transp_bg = 1
"set background=dark
"colorscheme space_vim_theme
let g:airline_theme='dracula'

let g:lightline = {
  \     'active': {
  \         'left': [['mode', 'paste' ], ['readonly', 'filename', 'modified']],
  \         'right': [['lineinfo'], ['percent'], ['fileformat', 'fileencoding']]
  \     }
  \ }

" set statusline+=%#warningmsg#
" set statusline+=%{SyntasticStatuslineFlag()}
" set statusline+=%*

" ===
" === NERDTree
" ===
map tt :NERDTreeToggle<CR>
let NERDTreeMapOpenExpl = ""
let NERDTreeMapUpdir = ""
let NERDTreeMapUpdirKeepOpen = "l"
let NERDTreeMapOpenSplit = ""
let NERDTreeOpenVSplit = ""
let NERDTreeMapActivateNode = "i"
let NERDTreeMapOpenInTab = "o"
let NERDTreeMapPreview = ""
let NERDTreeMapCloseDir = "n"
let NERDTreeMapChangeRoot = "y"


" ==
" == NERDTree-git
" ==
let g:NERDTreeIndicatorMapCustom = {
    \ "Modified"  : "?",
    \ "Staged"    : "?",
    \ "Untracked" : "?",
    \ "Renamed"   : "?",
    \ "Unmerged"  : "?",
    \ "Deleted"   : "?",
    \ "Dirty"     : "?",
    \ "Clean"     : "??",
    \ "Unknown"   : "?"
    \ }

" ===
" === NCM2
" ===
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <CR> (pumvisible() ? "\<c-y>\<cr>": "\<CR>")
autocmd BufEnter * call ncm2#enable_for_buffer()
set completeopt=noinsert,menuone,noselect

"Add by xiaoli
"let g:python3_host_prog=/usr/bin/python3

let ncm2#popup_delay = 5
let g:ncm2#matcher = "substrfuzzy"
let g:ncm2_jedi#python_version = 3
let g:ncm2#match_highlight = 'bold'

"let g:jedi#auto_initialization = 1
""let g:jedi#completion_enabled = 0
""let g:jedi#auto_vim_configuration = 0
""let g:jedi#smart_auto_mapping = 0
"let g:jedi#popup_on_dot = 1
"let g:jedi#completion_command = ""
"let g:jedi#show_call_signatures = "1"


" Some testing features
set shortmess+=c
set notimeout


" ===
" === vim-indent-guide
" ===
let g:indent_guides_guide_size = 1
let g:indent_guides_start_level = 2
let g:indent_guides_enable_on_vim_startup = 1
let g:indent_guides_color_change_percent = 1
silent! unmap <LEADER>ig
autocmd WinEnter * silent! unmap <LEADER>ig


" ===
" === some error checking
" ===



" ===
" === MarkdownPreview
" ===
let g:mkdp_auto_start = 0
let g:mkdp_auto_close = 1
let g:mkdp_refresh_slow = 0
let g:mkdp_command_for_global = 0
let g:mkdp_open_to_the_world = 0
let g:mkdp_open_ip = ''
let g:mkdp_browser = 'chromium'
let g:mkdp_echo_preview_url = 0
let g:mkdp_browserfunc = ''
let g:mkdp_preview_options = {
    \ 'mkit': {},
    \ 'katex': {},
    \ 'uml': {},
    \ 'maid': {},
    \ 'disable_sync_scroll': 0,
    \ 'sync_scroll_type': 'middle',
    \ 'hide_yaml_meta': 1
    \ }
let g:mkdp_markdown_css = ''
let g:mkdp_highlight_css = ''
let g:mkdp_port = ''
let g:mkdp_page_title = '?${name}?'


" ===
" === Python-syntax
" ===
let g:python_highlight_all = 1
" let g:python_slow_sync = 0


" ===
" === Taglist
" ===
map <silent> T :TagbarOpenAutoClose<CR>


" ===
" === vim-table-mode
" ===
map <LEADER>tm :TableModeToggle<CR>


" ===
" === Goyo
" ===
map <LEADER>gy :Goyo<CR>


" ===
" === CtrlP
" ===
map <C-p> :CtrlP<CR>
let g:ctrlp_prompt_mappings = {
  \ 'PrtSelectMove("j")':   ['<c-e>', '<down>'],
  \ 'PrtSelectMove("k")':   ['<c-u>', '<up>'],
  \ }


" ===
" === vim-signiture
" ===
let g:SignatureMap = {
        \ 'Leader'             :  "m",
        \ 'PlaceNextMark'      :  "m,",
        \ 'ToggleMarkAtLine'   :  "m.",
        \ 'PurgeMarksAtLine'   :  "dm-",
        \ 'DeleteMark'         :  "dm",
        \ 'PurgeMarks'         :  "dm/",
        \ 'PurgeMarkers'       :  "dm?",
        \ 'GotoNextLineAlpha'  :  "m<LEADER>",
        \ 'GotoPrevLineAlpha'  :  "",
        \ 'GotoNextSpotAlpha'  :  "m<LEADER>",
        \ 'GotoPrevSpotAlpha'  :  "",
        \ 'GotoNextLineByPos'  :  "",
        \ 'GotoPrevLineByPos'  :  "",
        \ 'GotoNextSpotByPos'  :  "mn",
        \ 'GotoPrevSpotByPos'  :  "mp",
        \ 'GotoNextMarker'     :  "",
        \ 'GotoPrevMarker'     :  "",
        \ 'GotoNextMarkerAny'  :  "",
        \ 'GotoPrevMarkerAny'  :  "",
        \ 'ListLocalMarks'     :  "m/",
        \ 'ListLocalMarkers'   :  "m?"
        \ }


" ===
" === Undotree
" ===
let g:undotree_DiffAutoOpen = 0
map L :UndotreeToggle<CR>

" ==
" == vim-multiple-cursor
" ==
let g:multi_cursor_use_default_mapping=0
let g:multi_cursor_start_word_key      = '<c-k>'
let g:multi_cursor_select_all_word_key = '<a-k>'
let g:multi_cursor_start_key           = 'g<c-k>'
let g:multi_cursor_select_all_key      = 'g<a-k>'
let g:multi_cursor_next_key            = '<c-k>'
let g:multi_cursor_prev_key            = '<c-p>'
let g:multi_cursor_skip_key            = '<C-x>'
let g:multi_cursor_quit_key            = '<Esc>'


" My snippits
source ~/.config/nvim/snippits.vim

" comfortable-motion
"nnoremap <silent> <C-e> :call comfortable_motion#flick(50)<CR>
"nnoremap <silent> <C-u> :call comfortable_motion#flick(-50)<CR>
"let g:comfortable_motion_no_default_key_mappings = 1
"let g:comfortable_motion_interval = 1


" Startify
let g:startify_lists = [
      \ { 'type': 'files',     'header': ['   MRU']            },
      \ { 'type': 'bookmarks', 'header': ['   Bookmarks']      },
      \ { 'type': 'commands',  'header': ['   Commands']       },
      \ ]

" Far.vim
nnoremap <silent> <LEADER>f :F  %<left><left>

" Testring my own plugin
if !empty(glob('~/Github/vim-calc/vim-calc.vim'))
  source ~/Github/vim-calc/vim-calc.vim
endif
map <LEADER>a :call Calc()<CR>

let g:user_emmet_leader_key='<C-f>'
" Open the _machine_specific.vim file if it has just been created
"if has_machine_specific_file == 0
"  exec "e ~/.config/nvim/_machine_specific.vim"
"endif
