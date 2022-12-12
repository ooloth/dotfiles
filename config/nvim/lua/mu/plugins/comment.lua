local comment_ok, comment = pcall(require, 'Comment')
if not comment_ok then
  return
end

comment.setup()
