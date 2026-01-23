local rule = require("qlean.rule")
require("qlean").setup({
  keep = rule.any(rule.buftype("", "acwrite", "terminal"), rule.filetype("fern")),
})

vim.fn.setline(1, {
  "test for wzu1lhx4",
})
vim.cmd.copen()
vim.cmd.new({ mods = { split = "topleft" } })
vim.cmd.quit()
