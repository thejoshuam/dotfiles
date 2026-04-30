# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'

. "$HOME/.local/share/../bin/env"

export GHOME=$HOME/Documents/_git/dotfiles/
alias v=nvim
alias p='sudo pacman'
alias pc='pacman'
alias ss='sudo systemctl'
alias 'q'=exit
alias ':q'=exit
alias 'quit'=exit
alias steam='flatpak run com.valvesoftware.'
alias feh='echo im-Vee for im-Gee! ; imv'
alias fastfetch='fastfetch --logo Calculate'
alias 'start-omarchy-windows-vm'='omarchy-windows-vm start --keep-alive'
# alias -g 'omarchy-windows-vm'='omarchy-windows-vm start --keep-alive'
