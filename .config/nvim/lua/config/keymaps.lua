-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("n", "<leader>dd", '"_dd')

vim.keymap.set("n", "<leader>uz", function()
  -- Remember the chosen layout when sidebars temporarily interrupt Zen mode.
  vim.g.auto_center_disabled = Snacks.zen.win ~= nil and Snacks.zen.win:valid()
  Snacks.zen()
end, { desc = "Toggle Zen Mode" })

local function resize_zen(delta)
  local win = Snacks.zen.win
  if not (win and win:valid()) then
    return
  end
  vim.g.zen_width = math.max(60, math.min(vim.o.columns - 2, (vim.g.zen_width or 150) + delta))
  win:update()
end

vim.keymap.set("n", "<leader>u-", function()
  resize_zen(-10)
end, { desc = "Narrow Zen Window" })
vim.keymap.set("n", "<leader>u=", function()
  resize_zen(10)
end, { desc = "Widen Zen Window" })
