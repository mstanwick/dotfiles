" SETTINGS
set nocompatible
filetype plugin on
runtime macros/matchit.vim " Recommended by Practical Vim

" From Practical Vim -  Treat numbers with leading zeros as numerals
set nrformats=

" From Practical Vim - Set tab and spaces defaults
set shiftwidth=4 softtabstop=4 expandtab
set autoindent

" From Practical Vim -  Behavior when searching with multiple matches in command line mode
set wildmode=longest,list

set hidden
set number
syntax on
set hlsearch
set incsearch

" MAPPINGS

" From Practical Vim - 
cnoremap <C-p> <Up>
cnoremap <C-n> <Down>

" From Practical Vim  Remapping buffer navigation keys
nnoremap <silent> [b :bprevious<CR>
nnoremap <silent> ]b :bnext<CR>
nnoremap <silent> [B :bfirst<CR>
nnoremap <silent> ]B :blast<CR>

" From Practical Vim -  Easy expansion of the active file directory
cnoremap <expr> %%  getcmdtype() == ':' ? expand('%:h').'/' : '%%'

" Clear highlighting
map <esc><esc> :nohl<CR>

" From Practical Vim -  Returns the number of instances for the most recent search
nnoremap <leader>c :%s///gn<CR>

" From Practical Vim -  Remapping * and # to search for visual selection
xnoremap * :<C-u>call <SID>VSetSearch('/')<CR>/<C-R>=@/<CR><CR>
xnoremap # :<C-u>call <SID>VSetSearch('?')<CR>?<C-R>=@/<CR><CR>

function! s:VSetSearch(cmdtype)
  let temp = @s
  norm! gv"sy
  let @/ = '\V' . substitute(escape(@s, a:cmdtype.'\'), '\n', '\\n', 'g')
  let @s = temp
endfunction

" From Practical Vim -  Remap the & key to make its behavior more consistent
nnoremap & :&&<CR>
xnoremap & :&&<CR>

" From Reddit: Replace all occurrences of the word under the cursor (sr -> search and replace).
nnoremap <leader>sr :%s/\<<C-r><C-w>\>//g<Left><Left>

" COMMANDS
" From Practical Vim - populates the args list with files named in the
" quickfix list. Pair with :vimgrep
command! -nargs=0 -bar Qargs execute 'args' QuickfixFilenames()
function! QuickfixFilenames()
  let buffer_numbers = {}
  for quickfix_item in getqflist()
    let buffer_numbers[quickfix_item['bufnr']] = bufname(quickfix_item['bufnr'])
  endfor
  return join(map(values(buffer_numbers), 'fnameescape(v:val)'))
endfunction
