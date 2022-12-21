local autopairs_ok, autopairs = pcall(require, 'nvim-autopairs')
if not autopairs_ok then
  return
end

local cmp_autopairs_ok, cmp_autopairs = pcall(require, 'nvim-autopairs.completion.cmp')
if not cmp_autopairs_ok then
  return
end

local cmp_ok, cmp = pcall(require, 'cmp')
if not cmp_ok then
  return
end

-- configure autopairs
autopairs.setup({
  check_ts = true, -- enable treesitter
  ts_config = {
    -- lua = { 'string' }, -- don't add pairs in lua string treesitter nodes
    -- javascript = { 'template_string' }, -- don't add pairs in javscript template_string treesitter nodes
  },
})

-- make autopairs and completion work together
cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())
