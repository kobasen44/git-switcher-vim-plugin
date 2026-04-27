" ── Configuration (surchargeables dans vimrc) ─────────────────
if !exists('g:gs_search_dirs')
  let g:gs_search_dirs = [$HOME]
endif

" Profondeur max de recherche (find -maxdepth)
if !exists('g:gs_max_depth')
  let g:gs_max_depth = 4
endif

" ── Fonction principale ───────────────────────────────────────
function! s:GitSwitcher() abort
  let l:repos = []

  for l:root in g:gs_search_dirs
    let l:root = expand(l:root)
    if !isdirectory(l:root)
      continue
    endif

    let l:cmd = printf(
      \ 'find %s -maxdepth %d -name ".git" -type d 2>/dev/null',
      \ shellescape(l:root),
      \ g:gs_max_depth
      \ )

    let l:raw = systemlist(l:cmd)

    for l:gitdir in l:raw
      " Retire le "/.git" final pour avoir la racine du dépôt
      let l:repo = fnamemodify(l:gitdir, ':h')
      call add(l:repos, l:repo)
    endfor
  endfor

  let l:repos = uniq(sort(l:repos))

  if empty(l:repos)
    echo '[gs] Aucun dépôt Git trouvé dans : ' . join(g:gs_search_dirs, ', ')
    return
  endif

  " 2. Afficher la liste dans un buffer temporaire flottant (popup)
  "    → si popup_menu est dispo (Vim 8.2+), on l'utilise
  "    → sinon fallback sur inputlist()
 " if has('popupwin')
 "call s:ShowPopup(l:repos)
 " else
 call s:ShowInputList(l:repos)
 " endif
endfunction

" ── Affichage via popup_menu (Vim 8.2+ / Neovim via shim) ────
function! s:ShowPopup(repos) abort
  let l:lines = []
  let l:idx   = 1
  for l:r in a:repos
    call add(l:lines, printf(' %2d  %-30s  %s', l:idx, fnamemodify(l:r, ':t'), l:r))
    let l:idx += 1
  endfor

  let s:gs_repos = a:repos

  call popup_menu(l:lines, {
    \ 'title'    : '  Git Switcher — choisir un dépôt  ',
    \ 'border'   : [],
    \ 'padding'  : [0, 1, 0, 1],
    \ 'cursorline': 1,
    \ 'minwidth' : 60,
    \ 'maxheight': 20,
    \ 'filter'   : function('s:PopupFilter'),
    \ 'callback' : function('s:PopupCallback'),
    \ })
endfunction

function! s:PopupFilter(winid, key) abort
  if a:key ==# "\<Esc>" || a:key ==# 'q'
    call popup_close(a:winid, -1)
    return 1
  endif
  return popup_filter_menu(a:winid, a:key)
endfunction

function! s:PopupCallback(winid, result) abort
  if a:result <= 0
    echo '[gs] Annulé.'
    return
  endif
  let l:repo = s:gs_repos[a:result - 1]
  call s:CdToRepo(l:repo)
endfunction

" ── Fallback : inputlist() ────────────────────────────────────
"function! s:ShowInputList(repos) abort
"  let l:choices = ['Sélectionner un dépôt Git :']
"  let l:idx = 1
"  for l:r in a:repos
"    call add(l:choices, printf('%2d. %s', l:idx, l:r))
"    let l:idx += 1
"  endfor

"  let l:choice = inputlist(l:choices)

"  if l:choice <= 0 || l:choice > len(a:repos)
"    echo '[gs] Annulé.'
"    return
"  endif

"  call s:CdToRepo(a:repos[l:choice - 1])
"endfunction

" ── Fallback : inputlist() avec fuzzy filter ─────────────────
function! s:ShowInputList(repos) abort
  let l:filtered = a:repos

  while 1
    let l:query = input('[gs] Filtre (vide = tout, Entrée = valider): ')

    if l:query !=# ''
      let l:filtered = s:FuzzyFilter(a:repos, l:query)
    else
      let l:filtered = a:repos
    endif

    if empty(l:filtered)
      echo "\n[gs] Aucun résultat pour '" . l:query . "'"
      " Relance la boucle pour retaper un filtre
      continue
    endif

    " ── Affiche la liste filtrée ──
    let l:choices = ['Résultats (' . len(l:filtered) . ') — entrer le numéro :']
    let l:idx = 1
    for l:r in l:filtered
      call add(l:choices, printf(' %2d. %s', l:idx, l:r))
      let l:idx += 1
    endfor

    let l:choice = inputlist(l:choices)

    if l:choice <= 0 || l:choice > len(l:filtered)
      echo '[gs] Annulé.'
      return
    endif

    call s:CdToRepo(l:filtered[l:choice - 1])
    return
  endwhile
endfunction

" ── Fuzzy filter : tous les chars du pattern dans l'ordre ─────
function! s:FuzzyFilter(items, pattern) abort
  let l:chars   = split(tolower(a:pattern), '\zs')
  let l:regex   = join(map(l:chars, {_, c -> escape(c, '\.^$*[]~')}), '.\{-}')

  return filter(copy(a:items), {_, v -> tolower(v) =~# l:regex})
endfunction

" ── Action : cd + message ─────────────────────────────────────
function! s:CdToRepo(repo) abort
  execute 'cd ' . fnameescape(a:repo)
  echo '[gs] Répertoire courant  → ' . a:repo
  execute 'Explore ' . fnameescape(getcwd())
endfunction

" ── Commande publique ─────────────────────────────────────────
command! GS call s:GitSwitcher()
command! Gs call s:GitSwitcher()
command! Gswitch call s:GitSwitcher()
