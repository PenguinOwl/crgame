function! LintGameHandle(buffer, lines) abort
let l:output = []

for l:error in ale#util#FuzzyJSONDecode(a:lines, [])
    if !has_key(l:error, 'file')
        continue
    endif

    call add(l:output, {
    \   'lnum': l:error.line + 0,
    \   'col': l:error.column + 0,
    \   'text': l:error.message,
    \})
  endfor

  return l:output
endfunction

function! LintGame(buffer) abort
    return 'crystal build -f json --no-codegen --no-color -o '
    \   . ale#Escape(g:ale#util#nul_file)
    \   . ' src/crgame.cr'
endfunction

call ale#linter#Define('crystal', {
\   'name': 'crgame',
\   'executable': 'crystal',
\   'output_stream': 'both',
\   'lint_file': 1,
\   'command': function('LintGame'),
\   'callback': 'LintGameHandle',
\})
let b:ale_linters = ['crgame']
