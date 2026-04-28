function! s:GitSwitcher() abort
  call fzf#run(fzf#wrap({
    \ 'source': 'find ~/workspaces/ -mindepth 3 -maxdepth 3 -type d 2>/dev/null | sort -u',
    \ 'options': '--prompt="Select a git repository> "'
    \ }))
endfunction

command! GS call s:GitSwitcher()
command! Gs call s:GitSwitcher()
command! Gswitch call s:GitSwitcher()
