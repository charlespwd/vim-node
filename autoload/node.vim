" Vim by default sets the filetype to JavaScript for the following suffices.
" And, yes, it has .jsx there.
if !exists("node#suffixesadd")
	let node#suffixesadd = [".js", ".json", ".es", ".jsx"]
endif

function! node#initialize(root)
	let b:node_root = a:root

	command! -bar -bang -nargs=1 -buffer -complete=customlist,s:complete Nedit
		\ exe s:nedit(<q-args>, expand('%:p'), "edit<bang>")
	command! -bar -bang -nargs=1 -buffer -complete=customlist,s:complete Nopen
		\ exe s:nopen(<q-args>, expand('%:p'), "edit<bang>")

	nnoremap <buffer><silent> <Plug>NodeGotoFile
		\ :call <SID>edit(expand("<cfile>"), expand('%:p'))<CR>
	nnoremap <buffer><silent> <Plug>NodeSplitGotoFile
		\ :call <SID>edit(expand("<cfile>"), expand('%:p'), "split")<CR>
	nnoremap <buffer><silent> <Plug>NodeVSplitGotoFile
		\ :call <SID>edit(expand("<cfile>"), expand('%:p'), "vsplit")<CR>
	nnoremap <buffer><silent> <Plug>NodeTabGotoFile
		\ :call <SID>edit(expand("<cfile>"), expand('%:p'), "tab split")<CR>

	silent doautocmd User Node
endfunction

function! node#javascript()
	" This might be called multiple times if multiple filetypes match.
	if exists("b:node_javascript") && b:node_javascript | return | endif
	let b:node_javascript = 1

	setlocal path-=/usr/include
	let &l:suffixesadd .= "," . join(g:node#suffixesadd, ",")
	let &l:include = '\<require(\(["'']\)\zs[^\1]\+\ze\1'
	let &l:includeexpr = "node#lib#find(v:fname, expand('%:p'))"

	" @ is used for scopes, but isn't a default filename character on
	" non-Windows sytems.
	setlocal isfname+=@-@

	if !hasmapto("<Plug>NodeGotoFile")
		" Split gotofiles don't take a count for the new window's width, but for
		" opening the nth file. Though Node.vim doesn't support counts atm.
		nmap <buffer> gf <Plug>NodeGotoFile
		nmap <buffer> <C-w>f <Plug>NodeSplitGotoFile
		nmap <buffer> <C-w><C-f> <Plug>NodeSplitGotoFile
		nmap <buffer> <C-w>gf <Plug>NodeTabGotoFile
	endif
endfunction

function! s:edit(name, from, ...)
	if empty(a:name) | return | endif
	let dir = isdirectory(a:from) ? a:from : fnamemodify(a:from, ":h")
	let command = a:0 == 1 ? a:1 : "edit"
	let path = node#lib#find(a:name, dir)

	if empty(path)
		return s:error("E447: Can't find file \"" . a:name . "\" in path")
	endif

	exe command . " " . fnameescape(path)
endfunction

function! s:nedit(name, from, ...)
	let command = a:0 == 1 ? a:1 : "edit"
	call s:edit(a:name, b:node_root, command)
endfunction

function! s:nopen(name, from, ...)
	let command = a:0 == 1 ? a:1 : "edit"
	call s:nedit(a:name, a:from, command)
	if exists("b:node_root") | exe "lcd " . fnameescape(b:node_root) | endif
endfunction

function! s:complete(arg, cmd, cursor)
	let matches = node#lib#glob(s:dirname(a:arg))

	" Show private modules (_*) only if explicitly asked:
	if a:arg[0] != "_" | call filter(matches, "v:val[0] != '_'") | endif

	let filter = "stridx(v:val, a:arg) == 0"
	let ignorecase = 0
	let ignorecase = ignorecase || exists("&fileignorecase") && &fileignorecase
	let ignorecase = ignorecase || exists("&wildignorecase") && &wildignorecase
	if ignorecase | let filter = "stridx(tolower(v:val),tolower(a:arg)) == 0" | en

	return filter(matches, filter)
endfunction

function! s:dirname(path)
	let dirname = fnamemodify(a:path, ":h")
	if dirname == "." | return "" | endif

	" To not change the amount of final consecutive slashes, using this
	" dirname/basename trick:
	let basename = fnamemodify(a:path, ":t")
	return a:path[0 : 0 - len(basename) - 1]
endfunction

" Using the built-in :echoerr prints a stacktrace, which isn't that nice.
function! s:error(msg)
	echohl ErrorMsg
	echomsg a:msg
	echohl NONE
	let v:errmsg = a:msg
endfunction
