let s:save_cpo = &cpoptions
set cpoptions&vim

let s:source_func_curr = {
      \ 'name': 'godecls/func',
      \ 'description': 'GoDecls implementation for unite',
      \ 'syntax': 'uniteSource__Decls',
      \ 'action_table': {},
      \ 'hooks': {},
      \ }

let s:source_func = {
      \ 'name': 'godecls/funcs',
      \ 'description': 'GoDecls implementation for unite',
      \ 'syntax': 'uniteSource__Decls',
      \ 'action_table': {},
      \ 'hooks': {},
      \ }

let s:source_type = {
      \ 'name': 'godecls/types',
      \ 'description': 'GoDecls implementation for unite',
      \ 'syntax': 'uniteSource__Decls',
      \ 'action_table': {},
      \ 'hooks': {},
      \ }

function! unite#sources#godecls#define()
  return [s:source_func_curr, s:source_func, s:source_type]
endfunction

function! s:source_func_curr.gather_candidates(args, context) abort
    let a:context.decls_include = "func"
    let a:context.decls_mode = "file"
    let a:context.decls_path = bufname("%")

    return s:gather_candidates(a:args, a:context)
endfunction

function! s:source_func.gather_candidates(args, context) abort
    let a:context.decls_include = "func"
    let a:context.decls_mode = "dir"
    let a:context.decls_path = fnamemodify(bufname("%"), ":p:h")

    return s:gather_candidates(a:args, a:context)
endfunction

function! s:source_type.gather_candidates(args, context) abort
    let a:context.decls_include = "type"
    let a:context.decls_mode = "dir"
    let a:context.decls_path = fnamemodify(bufname("%"), ":p:h")

    return s:gather_candidates(a:args, a:context)
endfunction

function! s:source_func_curr.hooks.on_syntax(args, context) abort
    return s:on_syntax(a:args, a:context)
endfunction

function! s:source_func.hooks.on_syntax(args, context) abort
    return s:on_syntax(a:args, a:context)
endfunction

function! s:source_type.hooks.on_syntax(args, context) abort
    return s:on_syntax(a:args, a:context)
endfunction

function! s:gather_candidates(args, context) abort
  let l:bin_path = go#path#CheckBinPath('motion')
  if empty(l:bin_path)
    return []
  endif

  let l:mode = a:context.decls_mode
  let l:path = a:context.decls_path
  let l:include = a:context.decls_include

  let l:command = printf('%s -format vim -mode decls -include %s -%s %s', l:bin_path, l:include, l:mode, shellescape(l:path))
  let l:candidates = []
  try
    let l:result = eval(unite#util#system(l:command))
    let l:candidates = get(l:result, 'decls', [])
  catch
    call unite#print_source_error(['command returned invalid response.', v:exception], s:source.name)
  endtry


  return map(l:candidates, "{
        \ 'word': v:val.ident,
        \ 'abbr': printf('%s', v:val.full),
        \ 'kind': 'jump_list',
        \ 'action__path': v:val.filename,
        \ 'action__line': v:val.line,
        \ 'action__col': v:val.col,
        \ }")
endfunction

function! s:on_syntax(args, context) abort
  syntax match uniteSource__Decls_Filepath /[^:]*\ze:/ contained containedin=uniteSource__Decls
  syntax match uniteSource__Decls_Line /\d\+\ze :/ contained containedin=uniteSource__Decls
  syntax match uniteSource__Decls_WholeFunction /\vfunc %(\([^)]+\) )?[^(]+/ contained containedin=uniteSource__Decls
  syntax match uniteSource__Decls_Function /\S\+\ze(/ contained containedin=uniteSource__Decls_WholeFunction
  syntax match uniteSource__Decls_WholeType /type \S\+/ contained containedin=uniteSource__Decls
  syntax match uniteSource__Decls_Type /\v( )@<=\S+/ contained containedin=uniteSource__Decls_WholeType
  highlight default link uniteSource__Decls_Filepath Comment
  highlight default link uniteSource__Decls_Line LineNr
  highlight default link uniteSource__Decls_Function Function
  highlight default link uniteSource__Decls_Type Type

  syntax match uniteSource__Decls_Separator /:/ contained containedin=uniteSource__Decls conceal
  syntax match uniteSource__Decls_SeparatorFunction /func / contained containedin=uniteSource__Decls_WholeFunction conceal
  syntax match uniteSource__Decls_SeparatorType /type / contained containedin=uniteSource__Decls_WholeType conceal
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
