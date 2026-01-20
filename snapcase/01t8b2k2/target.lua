local rule = require("qlean.rule")
require("qlean").setup({
  keep = rule.any(rule.buftype("", "acwrite", "terminal"), rule.filetype("fern")),
})

vim.go.hidden = true

if pcall(vim.cmd.new) then
  vim.fn.setline(1, { "foobar" })
  vim.cmd.wincmd("c")
end
vim.cmd.copen()
vim.cmd.wincmd("k")
vim.cmd.redraw()
snap_done()
