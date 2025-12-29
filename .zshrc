# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ------------------------------------------------------
# Basic env
# ------------------------------------------------------
export PATH="$HOME/bin:$PATH"
export EDITOR="vim"

# History
HISTFILE=~/.zsh_history
HISTSIZE=5000
SAVEHIST=5000

# ------------------------------------------------------
# Zsh options (useful but not noisy)
# ------------------------------------------------------
setopt autocd                    # 'cd' by just typing directory
setopt histignoredups            # ignore duplicate history entries
setopt sharehistory              # share history across sessions
setopt incappendhistory          # append to history immediately
setopt interactivecomments       # allow comments in interactive shell
setopt extendedglob

# ------------------------------------------------------
# Antidote initialization
# ------------------------------------------------------
source ${ZDOTDIR:-$HOME}/.antidote/antidote.zsh

# Load plugins
antidote load

# ------------------------------------------------------
# Powerlevel10k prompt
# ------------------------------------------------------
# If you haven't generated a config yet, you'll get a wizard on first start.
# After running the wizard once, it will create ~/.p10k.zsh and this will pick it up.
if [[ -r "${HOME}/.p10k.zsh" ]]; then
  source "${HOME}/.p10k.zsh"
else
  # Fallback simple prompt until you run `p10k configure`
  PROMPT='%F{cyan}%n@%m%f %F{yellow}%1~%f %# '
fi

# ------------------------------------------------------
# History substring search keybindings
# ------------------------------------------------------
# Use up/down arrow to search history by current prefix
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# ------------------------------------------------------
# fzf defaults (optional but useful)
# ------------------------------------------------------
export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!.git" 2>/dev/null || fd || find .'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
