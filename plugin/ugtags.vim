" A automation vim plugin for GNU global tag system.
" @file gtags-auto.vim
" @author linuor
" @date 2018-06-21

if exists("g:ugtags_has_loaded")
    finish
endif
let g:ugtags_has_loaded=1

if !exists("g:ugtags_gtags_prg")
    let g:ugtags_gtags_prg = 'gtags'
endif
if !exists("g:ugtags_project_root_symbolics")
    let g:ugtags_project_root_symbolics = ['.git']
endif
if !exists("g:ugtags_options")
    let g:ugtags_options = []
endif

let s:ctx={}
let s:db={}

function! s:normalize_cmd(lst) abort
    if has('win32')
        return join(a:lst)
    else
        let r = []
        for it in a:lst
            let l = strlen(it)
            if (it[0] == '"' && it[l - 1] == '"') || 
                        \(it[0] == "'" && it[l - 1] == "'")
                call add(r, it[1:-2])
            else
                call add(r, it)
            endif
        endfor
        return r
    endif
endfunction

function! s:add_db(root) abort
    let $GTAGSDBPATH = a:root
    let $GTAGSROOT = a:root
    if exists("s:db[a:root]")
        return
    endif
    let tagfile = a:root . '/GTAGS'
    if !filereadable(tagfile)
        return
    endif
    let tmp = &cscopeverbose
    set nocscopeverbose
    cscope kill -1
    let s:db = {}
    execute 'cscope add ' . fnameescape(tagfile)
    let s:db[a:root] = 1
    if tmp
        set cscopeverbose
    endif
endfunction!

function! s:on_exit(job, code) abort
    for key in keys(s:ctx)
        if exists("s:ctx[key]['job']") && a:job is s:ctx[key]['job']
            if a:code != 0
                echohl ErrorMsg
                echomsg '[UGtags] gtags job failed with exit code ' . a:code
                echohl None
            else
                call s:add_db(key)
            endif
            unlet s:ctx[key]['job']
            break
        endif
    endfor
endfunction

let s:prg = ['"' . g:ugtags_gtags_prg . '"', '-i'] + g:ugtags_options
let s:prg = s:normalize_cmd(s:prg)
let s:job_opts = {
            \'in_io': 'null',
            \'out_io': 'null',
            \'err_io': 'null',
            \'exit_cb': function('s:on_exit'),
            \'cwd':''
            \}

function! s:find_symbolic(sym, path) abort
    let r = finddir(a:sym, a:path)
    if r !=# ''
        return r
    else
        return findfile(a:sym, a:path)
    endif
endfunction

function! s:run() abort
    let opt = deepcopy(s:job_opts)
    let opt['cwd'] = b:ugtags_project_root
    let j = job_start(s:prg, opt)
    let s:ctx[b:ugtags_project_root]['job'] = j
    let isfail = job_status(j)
    if isfail == 'fail'
        echohl ErrorMsg
        echomsg '[UGtags] fail to start job for gtags'
        echohl None
        unlet s:ctx[b:ugtags_project_root]['job']
    endif
endfunction

function! s:on_write() abort
    if s:ctx[b:ugtags_project_root]['has_tags'] == 0
        return
    endif
    if exists("s:ctx[b:ugtags_project_root]['job']")
        return
    endif
    let s:ctx[b:ugtags_project_root]['job'] = {}
    call s:run()
endfunction

function! UGtags() abort
    call s:setup(expand('%:p:h'), 1)
    call s:on_write()
endfunction

function! s:switch() abort
    if !exists("b:ugtags_project_root")
        return
    endif
    if exists("s:ctx[b:ugtags_project_root]['has_tags']") &&
                \ s:ctx[b:ugtags_project_root]['has_tags'] == 1
        call s:add_db(b:ugtags_project_root)
    endif
endfunction

function s:setup(path, force) abort
    let pathup = a:path . ';'
    let root = ''
    for s in g:ugtags_project_root_symbolics
        let root = s:find_symbolic(s, pathup)
        if root !=# ''
            break
        endif
    endfor
    if root ==# ''
        return
    endif
    if root !~ '^[/\\]'
        let root = getcwd() . '/' . root
    endif
    if isdirectory(root)
        let root = fnamemodify(root, ':p:h:h')
    else
        let root = fnamemodify(root, ':p:h')
    endif
    let s:ctx[root] = {}
    if findfile('GTAGS', root . ';') ==# ''
        if a:force == 1
            let s:ctx[root]['has_tags'] = 1
        else
            let s:ctx[root]['has_tags'] = 0
        endif
    else
        let s:ctx[root]['has_tags'] = 1
        call s:add_db(root)
    endif

    let b:ugtags_project_root = root
    execute 'augroup ' . 'ugtags_buf' . bufnr('%')
    autocmd!
    autocmd BufWritePost <buffer> call s:on_write()
    augroup END
    command! -nargs=0 -buffer UGtags :call UGtags()
endfunction

augroup ugtags
    autocmd!
    autocmd BufNewFile,BufReadPost * call s:setup(expand('%:p:h'), 0)
    autocmd VimEnter * if expand('<amatch>')==''|call s:setup(getcwd(), 0)|endif
    autocmd BufEnter * call s:switch()
augroup END

set cscopeprg=gtags-cscope  " use gtags_cscope instead of cscope
set cscopequickfix=s-,g-,d-,c-,t-,e-,f-,i-,a-
set cscopetag   " use cscope instead of :tag and CTRL-]
set cscopepathcomp=3    " display the last 3 components of file
