-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("n", "<leader>dd", '"_dd')

vim.keymap.set("n", "<leader>uz", function()
  -- Remember the chosen layout when sidebars temporarily interrupt Zen mode.
  vim.g.auto_center_disabled = Snacks.zen.win ~= nil and Snacks.zen.win:valid()
  Snacks.zen()
end, { desc = "Toggle Zen Mode" })
