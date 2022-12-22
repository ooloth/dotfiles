function ..() { cd .. }
function ...() { cd ../.. }
function ....() { cd ../../.. }
function .....() { cd ../../../.. }
function c() { clear }
function cat() { bat --paging=never }
function dot() { cd $HOME/Repos/ooloth/dotfiles }
function et() { $EDITOR $HOME/Repos/ooloth/dotfiles/config/tmux/tmux.conf }
function ez() { $EDITOR $HOME/Repos/ooloth/dotfiles/config/zsh/.zshrc }
function f() { vifm . . }                                                                   # open both vifm panes in cwd
function g() { lazygit }
function h() { cd $HOME }
function ls() { exa --all --group-directories-first }                                       # top level dir + files
function ld() { exa --all --git --group-directories-first --header --long }                 # top level details
function lt() { exa --all --git-ignore --group-directories-first -I .git --tree --level=1 } # file tree (all levels)
function lt2() { lt --level=2 }                                                             # file tree (2 levels only)
function lt3() { lt --level=3 }                                                             # file tree (3 levels only)
function lt4() { lt --level=4 }                                                             # file tree (4 levels only)
function mini() { s michael@192.168.2.22 }                                                  # automatically log in using SSH key pair
function mu() { cd $HOME/Repos/ooloth/michaeluloth.com }
function nig() {
  npm i -g \
    @fsouza/prettierd \
    bash-language-server \
    cssmodules-language-server \
    dockerfile-language-server-nodejs \
    eslint_d \
    emmet-ls \
    neovim \
    npm-check \
    pug-lint \
    svelte-language-server \
    tldr \
    tree-sitter-cli \
    typescript \
    vscode-langservers-extracted
}
function nvm() { fnm }
function oo() { cd $HOME/Repos/ooloth }
function pilots() { cd $HOME/Repos/ooloth/download-pilots }
function R() { source $HOME/.config/zsh/.zshrc }
function s() { kitty +kitten ssh }                                                          # kitty's ssh kitten
function sl() { ln -sfv $1 $2 } # easier symlinking
function t() { tmux a }
function u() {
	npm update -g
	brew upgrade && brew update && brew cleanup && brew doctor
	if $IS_WORK_LAPTOP; then
		# TODO: store version in a variable and update it programmatically?
		echo '🚨 Run "brew info librdkafka" and manually update the version in .zshrc if it has changed.'
	fi
}
function v() { vim }
function vim() { nvim }
function zt() { for i in $(seq 1 10); do /usr/bin/time zsh -i -c exit; done } # [z]sh [t]ime: measure how long new shells take to launch
