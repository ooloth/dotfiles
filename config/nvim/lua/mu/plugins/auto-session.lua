local auto_session_ok, auto_session = pcall(require, 'auto-session')
if not auto_session_ok then
  return
end

-- See: https://github.com/rmagatti/auto-session#recommended-sessionoptions-config
vim.o.sessionoptions = 'blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions'

auto_session.setup()
