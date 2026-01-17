local rule = require("qlean.rule")
require("qlean").setup({
  keep = rule.any(rule.buftype("", "acwrite", "terminal"), rule.filetype("fern")),
})

vim.go.hidden = true

vim.cmd.new()
vim.fn.setline(1, { "foobar" })
vim.cmd.quit()
vim.cmd.copen()
vim.cmd.wincmd("k")
pcall(vim.cmd.quit)
