-- -l does not load init.lua. Bootstrap Lazy explicitly, then wait for each stage.
local repo = assert(vim.env.DOTFILES_REPO, "DOTFILES_REPO is required")
vim.opt.rtp:prepend(repo .. "/.config/nvim")
vim.opt.loadplugins = true -- Neovim disables this by default with -l.
local locked = vim.fn.readfile(repo .. "/.config/nvim/lazy-lock.json")
local lockfile = vim.fn.tempname()
vim.fn.writefile(locked, lockfile)
vim.g.dotfiles_lockfile = lockfile
local ok, err = xpcall(function()
  assert(vim.fn.has("nvim-0.11.2") == 1, "Neovim >= 0.11.2 required")
  require("config.lazy")
  -- Lazy's initial missing-plugin install may update its working lockfile.
  vim.fn.writefile(locked, lockfile)
  require("lazy").restore({ wait = true, show = false })
  for name, plugin in pairs(require("lazy.core.config").plugins) do
    assert(vim.fn.isdirectory(plugin.dir) == 1, "Plugin missing: " .. name)
    for _, task in ipairs(plugin._.tasks or {}) do
      assert(not task:has_errors(), "Plugin task failed: " .. name .. "\n" .. task:output())
    end
  end
  require("lazy").load({ plugins = { "mason.nvim", "nvim-treesitter" } })
  local registry = require("mason-registry")
  local refreshed, refresh_ok = false, false
  registry.refresh(function(success)
    refresh_ok = success
    refreshed = true
  end)
  assert(vim.wait(120000, function() return refreshed end, 100), "Mason registry refresh timed out")
  assert(refresh_ok, "Mason registry refresh failed")
  local packages = {}
  for _, name in ipairs(require("config.tools").packages) do
    local package = registry.get_package(name)
    table.insert(packages, package)
    if not package:is_installed() and not package:is_installing() then package:install() end
  end
  assert(vim.wait(1200000, function()
    for _, package in ipairs(packages) do
      if package:is_installing() then return false end
    end
    return true
  end, 200), "Tool installation timed out; inspect :MasonLog")
  for _, package in ipairs(packages) do
    assert(package:is_installed(), "Tool installation failed: " .. package.name .. "; inspect :MasonLog")
  end
  -- The locked Treesitter version exposes the synchronous install task API.
  require("nvim-treesitter").install(require("config.tools").parsers):wait(1200000)
  print("Neovim provisioning finished; running independent checks next.")
end, debug.traceback)
vim.fn.delete(lockfile)
if not ok then
  io.stderr:write("FAILED: " .. tostring(err) .. "\n")
  vim.cmd("cquit 1")
end
vim.cmd("qa!")
