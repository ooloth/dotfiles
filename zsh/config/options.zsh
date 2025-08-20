# History
# see: https://ryantoddgarza.medium.com/a-better-zsh-history-pt-2-dde323e0c9ca
# see: https://www.reddit.com/r/zsh/comments/wy0sm6/what_is_your_history_configuration/
# see: https://zsh.sourceforge.io/Doc/Release/Parameters.html#Parameters-Used-By-The-Shell
# NOTE: keep these particular env vars here (they only work when loaded in .zshrc)
export HISTORY_IGNORE="git*"
export HISTSIZE=100000
export SAVEHIST=$HISTSIZE
setopt EXTENDED_HISTORY          # Write the history file in the ':start:elapsed;command' format.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire a duplicate event first when trimming history.
setopt HIST_FIND_NO_DUPS         # Do not display a previously found event.
setopt HIST_IGNORE_ALL_DUPS      # Delete an old recorded event if a new event is a duplicate.
setopt HIST_IGNORE_DUPS          # Do not record an event that was just recorded again.
setopt HIST_IGNORE_SPACE         # Do not record an event starting with a space.
setopt HIST_SAVE_NO_DUPS         # Do not write a duplicate event to the history file.
setopt INC_APPEND_HISTORY        # Record events as soon as they happen instead of waiting until the shell exits (so I can reload the shell without losing history).
setopt SHARE_HISTORY             # Share history between all sessions.

# enable vi mode
bindkey -v

# restore history search while in vi mode
# bindkey ^R history-incremental-search-backward
# bindkey ^S history-incremental-search-forward
