local rule = require("qlean.rule")
require("qlean").setup({
  keep = rule.any(rule.buftype("", "acwrite", "terminal"), rule.filetype("fern")),
})

vim.go.hidden = true

-- Make a new modified hidden buffer
vim.cmd.new()
vim.fn.setline(1, { "foobar" })
vim.cmd.wincmd("c")

-- Open a quickfix-window as a UI window (it'll not be kept)
vim.cmd.copen()

-- Close last kept window
-- - It closes other windows, hidden buffer is found, Neovim stops quitting because it is not saved (E37)
vim.cmd.wincmd("k")
pcall(vim.api.nvim_cmd, { cmd = "quit" }, { output = true })

vim.cmd.redraw()
snap_done()
