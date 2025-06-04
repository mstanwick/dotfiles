# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
setopt autocd extendedglob nomatch notify
unsetopt beep
bindkey -v
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/matt/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall
source ~/.zsh/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


# Plugins
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Enable Emacs keybindings in insert mode
bindkey -e

##### ALIASES #####
alias please='sudo $(history -p !!)'

### ls aliases ###
## Colorize the ls output ##
alias ls='ls -h --color=auto'
 
## Use a long listing format ##
alias ll='ls -lah'
 
## Show hidden files ##
alias l.='ls -d .* --color=auto'

### cd command aliases ###
## get rid of command not found ##
alias cd..='cd ..'

## a quick way to get out of current directory ##
alias ..='cd ..'
alias ...='cd ../../../'
alias ....='cd ../../../../'
alias .....='cd ../../../../'
alias .4='cd ../../../../'
alias .5='cd ../../../../..'

## Start the calculator with math support ##
alias bc='bc -l'

## Create parent directories on command ##
alias mkdir='mkdir -pv'

alias mv="mv -iv" # safer and more verbose move
alias cp="cp -riv" # safer, recursive, and verbose copy

## Set vim as the default editor ##
alias vi=vim
alias svi='sudo vi'
alias vis='vim "+set si"'
alias edit='vim'

## update shortcuts ##
alias update='sudo dnf update'
alias updatey='sudo dnf -y update'

# Program shortcuts
alias zotero='~/zotero/zotero &'
alias mullvad-browser='(cd ~/Application_Files/mullvad-browser/; ./start-mullvad-browser.desktop)'

function weather { curl -s wttr.in/"$1"\?u }
function sm-weather { curl -s wttr.in/"$1"\?u\?0 }

function cheat { curl -s cheat.sh/"$1" }

# Update PATH
PATH=$PATH:~/.local/bin
export LEDGER_FILE=~/2-Areas/Financial/2025.journal

function start_sabnzbd { systemctl start docker.service ;
			 docker start sabnzbd }
