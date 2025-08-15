# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

# Title & Prompt
OSNAME="$(sed -rn 's/^NAME="(.+)"$/\1/p' /etc/os-release)"
OSVERS="$(sed -rn 's/^VERSION_ID="(.+)"$/\1/p' /etc/os-release)"
export PROMPT_COMMAND='echo -ne "\e]0;$OSNAME $OSVERS\a"'
export PS1="[\e[1;32m\u\e[m@\e[1;32m\h\e[m \e[1;34m\W\e[m]\$ "

# User specific environment and startup programs
fastfetch --config ~/.config/fastfetch.jsonc
echo
