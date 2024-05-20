# History
# see: https://ryantoddgarza.medium.com/a-better-zsh-history-pt-2-dde323e0c9ca
# see: https://www.reddit.com/r/zsh/comments/wy0sm6/what_is_your_history_configuration/
setopt EXTENDED_HISTORY          # Write the history file in the ':start:elapsed;command' format.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire a duplicate event first when trimming history.
setopt HIST_FIND_NO_DUPS         # Do not display a previously found event.
setopt HIST_IGNORE_ALL_DUPS      # Delete an old recorded event if a new event is a duplicate.
setopt HIST_IGNORE_DUPS          # Do not record an event that was just recorded again.
setopt HIST_IGNORE_SPACE         # Do not record an event starting with a space.
setopt HIST_SAVE_NO_DUPS         # Do not write a duplicate event to the history file.
setopt SHARE_HISTORY             # Share history between all sessions.

# enable vi mode
bindkey -v

# restore history search while in vi mode
# bindkey ^R history-incremental-search-backward
# bindkey ^S history-incremental-search-forward
