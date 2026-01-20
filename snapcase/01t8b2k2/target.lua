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
-- NOTE: use `vim.api.nvim_cmd({cmd="quit"})` instead of `vim.cmd.quit`
-- because `vim.cmd.quit` waits user-input before a commit c2e0fd1c35c22b4c53f903fb46fe9005926b1e16
--     vim-patch:7.4.1886 (#36945)
--
--     Problem:    When waiting for a character is interrupted by receiving channel
--                 data and the first character of a mapping was typed, the mapping
--                 times out. (Ramel Eshed)
--     Solution:   When dealing with channel data don't return from mch_inchar().
--
--     https://github.com/vim/vim/commit/cda7764d8e65325d4524e5d6c3174121eeb12cad
pcall(vim.api.nvim_cmd, { cmd = "quit" }, { output = true })
vim.cmd.redraw()
snap_done()
