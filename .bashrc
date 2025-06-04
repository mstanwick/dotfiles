# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

function _update_ps1() {
    PS1=$(powerline-shell $?)
}

if [[ $TERM != linux && ! $PROMPT_COMMAND =~ _update_ps1 ]]; then
    PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
	for rc in ~/.bashrc.d/*; do
		if [ -f "$rc" ]; then
			. "$rc"
		fi
	done
fi

unset rc


##### ALIASES #####
alias please='sudo $(history -p !!)'

### ls aliases ###
## Make everything human-readable (-h option) ##
## Colorize the ls output ##
alias ls='ls -h --color=auto'
 
## Use a long listing format ##
alias ll='ls -lah'
 
## Show hidden files ##
alias l.='ls -dh .* --color=auto'

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

## Set vim as the default editor ##
alias vi=vim
alias svi='sudo vi'
alias vis='vim "+set si"'
alias edit='vim'

## update shortcuts ##
alias update='sudo dnf update'
alias updatey='sudo dnf -y update'

# Program shortcuts
alias zotero='~/zotero/zotero'
alias mullvad-browser='(cd ~/Application_Files/mullvad-browser/; ./start-mullvad-browser.desktop)'

function weather { curl -s wttr.in/"$1"\?u }
function sm-weather { curl -s wttr.in/"$1"\?u\?0 }
function cheat { curl -s cheat.sh/"$1" }
