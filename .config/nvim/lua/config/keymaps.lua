-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("n", "<leader>dd", '"_dd')

vim.keymap.set("n", "<leader>uz", function()
  -- Once manually toggled, leave layout control to the user for this session.
  vim.g.auto_center_disabled = true
  Snacks.zen()
end, { desc = "Toggle Zen Mode" })
