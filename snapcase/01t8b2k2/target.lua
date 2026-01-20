local rule = require("qlean.rule")
require("qlean").setup({
  keep = rule.any(rule.buftype("", "acwrite", "terminal"), rule.filetype("fern")),
})

vim.go.hidden = true

-- Make a new hidden modified buffer
vim.cmd.new()
vim.fn.setline(1, { "foobar" })
vim.cmd.wincmd("c")

-- Open a quickfix-window as a UI window (it'll not be kept)
vim.cmd.copen()

-- Close last kept window
-- -> It may close other windows, hidden buffer will be found, Neovim stops quiting because it is not saved (E37)
vim.cmd.wincmd("k")
pcall(vim.cmd.quit)

vim.cmd.redraw()
snap_done()
