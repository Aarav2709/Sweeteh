# fish setup shipped with sweeteh, the prompt and greeting follow end-4's dots
if status is-interactive
    # no greeting
    set fish_greeting

    # starship prompt, with transience so old prompts fold down to one symbol
    function starship_transient_prompt_func
        starship module character
    end
    if test "$TERM" != "linux"
        starship init fish | source
        enable_transience
    end

    # wallpaper colors for terminals that are not kitty
    if test -f ~/.local/state/sweeteh/terminal-sequences.txt
        cat ~/.local/state/sweeteh/terminal-sequences.txt
    end

    # kitty does not clear properly, so print the reset ourselves
    alias clear "printf '\033[2J\033[3J\033[1;1H'"
    alias celar "printf '\033[2J\033[3J\033[1;1H'"
    alias claer "printf '\033[2J\033[3J\033[1;1H'"
    alias pamcan pacman
    if test "$TERM" != "linux"
        alias ls 'eza --icons=auto'
    end
    if test "$TERM" = "xterm-kitty"
        alias ssh 'kitten ssh'
    end
end
