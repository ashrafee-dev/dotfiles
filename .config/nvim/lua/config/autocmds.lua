-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Center a lone editor automatically, while leaving sidebars and splits usable.
vim.g.auto_center_mode = true
local center_pending = false
local function auto_center()
  if center_pending then
    return
  end
  center_pending = true
  vim.schedule(function()
    center_pending = false
    if not vim.g.auto_center_mode or not Snacks or vim.v.exiting ~= vim.NIL then
      return
    end
    if Snacks.zen.win and Snacks.zen.win:valid() then
      return
    end

    local current = vim.api.nvim_get_current_win()
    if vim.api.nvim_win_get_config(current).relative ~= "" or vim.bo.buftype ~= "" then
      return
    end
    if vim.api.nvim_buf_get_name(0) == "" or vim.bo.filetype == "snacks_dashboard" then
      return
    end

    local windows = 0
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_win_get_config(win).relative == "" then
        windows = windows + 1
      end
    end
    if windows == 1 then
      Snacks.zen()
    end
  end)
end

vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "WinClosed", "TabEnter" }, {
  group = vim.api.nvim_create_augroup("auto_center_mode", { clear = true }),
  callback = auto_center,
})
auto_center()
