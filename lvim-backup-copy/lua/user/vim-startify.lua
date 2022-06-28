local M = {}

M.setup = function()
	-- useful commands: ':SSave', ':SLoad', ':SDelete'

	-- See: https://github.com/mhinz/vim-startify/blob/master/doc/startify.txt
	-- See: https://www.chrisatmachine.com/Neovim/11-startify/

	vim.g.startify_change_to_vcs_root = 1 -- change cwd to project root on open
	vim.g.startify_enable_special = 0 -- get rid of empty buffers on quit
	vim.g.startify_fortune_use_unicode = 1 -- if I want Unicode
	vim.g.startify_session_autoload = 1 -- automatically restart sessions if dir has Sessions.vim
	vim.g.startify_session_delete_buffers = 1 -- let Startify take care of buffers
	vim.g.startify_session_dir = "$HOME/.config/nvim/sessions"
	vim.g.startify_session_persistence = 1 -- automatically update sessions on quit
	vim.g.startify_session_sort = 0 -- sort sessions by date modified
	vim.g.startify_update_oldfiles = 1 -- keep Startify up to date as I work

	-- -- returns all modified files of the current git repo
	-- -- `2>/dev/null` makes the command fail quietly, so that when we are not in a git repo, the list will be empty
	-- function! s:gitModified()
	--   let files = systemlist('git ls-files -m 2>/dev/null')
	--   return map(files, "{'line': v:val, 'path': v:val}")
	-- endfunction

	-- -- same as above, but show untracked files, honouring .gitignore
	-- function! s:gitUntracked()
	--   let files = systemlist('git ls-files -o --exclude-standard 2>/dev/null')
	--   return map(files, "{'line': v:val, 'path': v:val}")
	-- endfunction

	-- -- Return just the tail path of the current working directory
	-- -- https://vi.stackexchange.com/a/15047
	-- function! s:getDir()
	--   return fnamemodify(getcwd(), ':t')
	-- endfunction

	vim.g.startify_lists = {
		{ type = "sessions", header = { " Sessions" } },
		-- { type = function('s:gitModified'), header = {' [Git] Modified in current branch'} },
		-- { type = function('s:gitUntracked'), header = {' [Git] Untracked in current branch'} },
		{ type = "bookmarks", header = { " Bookmarks" } },
	}

	vim.g.startify_bookmarks = {
		{ e = "~/Repos/ecobee/consumer-website/" },
		{ d = "~/Repos/ooloth/dotfiles/" },
		{ m = "~/Repos/ooloth/michaeluloth.com/" },
		{ g = "~/Repos/ooloth/gatsbytutorials.com/" },
		{ s = "~/Repos/" },
	}

	-- Create viminfo file (for new installs)
	-- https://github.com/ChristianChiarulli/nvim/issues/5#issuecomment-625933872
	-- set viminfo='100,n$HOME/.config/nvim/autoload/plugged/vim-startify/test/viminfo'
end

return M
