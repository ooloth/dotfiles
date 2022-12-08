-- See: https://github.com/mhinz/vim-startify/blob/master/doc/startify.txt

-- cwd
vim.g.startify_change_to_dir = false -- don't change cwd when selecting start screen files
vim.g.startify_change_to_vcs_root = true -- change cwd to root .git directory (if found)

-- sessions
-- TODO: use vim-obsession as well? (see: https://github.com/mhinz/vim-startify/issues/354#issuecomment-462209267)
-- vim.g.startify_session_autoload = true -- autoload directory session when entering vim
-- vim.g.startify_session_delete_buffers = false -- don't delete session buffers when loading/closing session
vim.g.startify_session_persistence = true -- automatically update sessions before exiting vim
vim.g.startify_update_oldfiles = true -- update recent files while vim is open

-- dashboard
vim.g.startify_enable_special = false -- don't show "empty buffer" and "quit" options
vim.g.startify_fortune_use_unicode = true -- use unicode instead of ascii
vim.g.startify_lists = {
  { type = 'sessions', header = { ' Sessions' } },
  { type = 'bookmarks', header = { 'Bookmarks' } },
  { type = 'files', header = { 'Recent files' } },
}
vim.g.startify_relative_path = true -- use relative paths within cwd
vim.g.startify_custom_indices = {
  '1',
  '2',
  '3',
  '4',
  '5',
  '6',
  '7',
  '8',
  '9',
  '0',
  '11',
  '22',
  '33',
  '44',
  '55',
  '66',
  '77',
  '88',
  '99',
  '00',
  '111',
  '222',
  '333',
  '444',
  '555',
  '666',
  '777',
  '888',
  '999',
  '000',
}
