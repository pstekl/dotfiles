set number
syntax off

set visualbell

imap jj <Esc>

set smartindent
set bg=light

set wildmode=longest,list

let _curfile = expand("%:t")
if _curfile =~ "Makefile" || _curfile =~ "makefile" || _curfile =~ ".*\.mk"
set noexpandtab
else
set expandtab
endif

set tabstop=4
set shiftwidth=2

set list listchars=tab:>-,trail:.,precedes:<,extends:>

set nolist

"filetype plugin on
let g:clang_user_options='|| exit 0'
