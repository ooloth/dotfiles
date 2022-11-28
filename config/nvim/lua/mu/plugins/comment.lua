local setup, comment = pcall(require, "Comment") -- import comment plugin safely
if not setup then
  return
end

comment.setup() -- enable comment
