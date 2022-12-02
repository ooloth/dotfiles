local setup, bufferline = pcall(require, 'bufferline') -- import comment plugin safely
if not setup then
  return
end

bufferline.setup()
