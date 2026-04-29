" ── Git Switcher ─────────────────────────────────────
function! s:GitSwitcher() abort
  call fzf#run(fzf#wrap({
    \ 'source': 'find ~/workspaces/ -maxdepth 4 -name ".git" -type d 2>/dev/null | sed "s|/.git||" | sort -u',
    \ 'options': '--prompt="Select a git repository> "'
    \ }))
endfunction

" ── Commandes  ───────────────────────────────────────
command! GS call s:GitSwitcher()
command! Gs call s:GitSwitcher()
command! Gswitch call s:GitSwitcher()
