local repo = assert(vim.env.DOTFILES_REPO, "DOTFILES_REPO is required")
vim.opt.rtp:prepend(repo .. "/.config/nvim")
require("config.debug-env").setup()
local failures = 0
local function check(label, ok, hint)
  print((ok and "PASS: " or "FAIL: ") .. label .. (not ok and hint and (" — " .. hint) or ""))
  if not ok then failures = failures + 1 end
end
local function run(command)
  local ok, result = pcall(function() return vim.system(command, { text = true }):wait(30000) end)
  return ok and result.code == 0
end
local config = vim.env.XDG_CONFIG_HOME or (vim.env.HOME .. "/.config")
local function linked(target, source)
  return vim.uv.fs_lstat(target) ~= nil and vim.uv.fs_readlink(target) == source
end
check("Neovim >= 0.11.2", vim.fn.has("nvim-0.11.2") == 1)
for _, tool in ipairs({ "git", "go", "node", "npm", "python3", "rg", "fd", "lazygit", "gh", "fish", "tree-sitter", "cc", "make" }) do
  check(tool .. " executable", vim.fn.executable(tool) == 1, "run sh bootstrap.sh")
end
check("Go runtime", run({ "go", "version" }))
check("Java runtime", run({ "java", "-version" }))
check("Java compiler", run({ "javac", "-version" }))
check("C compiler", run({ "clang", "--version" }))
check("C++ compiler", run({ "clang++", "--version" }))
check("CMake", run({ "cmake", "--version" }))
check("Maven", run({ "mvn", "--version" }))
check("Node runtime", run({ "node", "--version" }))
check("Python virtual environments", run({ "python3", "-c", "import venv, ensurepip" }))
check("Neovim config link", linked(config .. "/nvim", repo .. "/.config/nvim"), "run sh install.sh")
check("GitHub preferences link", linked(config .. "/gh/config.yml", repo .. "/.config/gh/config.yml"))
for _, name in ipairs({ "00_fig_pre.fish", "99_fig_post.fish", "uv.env.fish" }) do
  check("Fish " .. name .. " link", linked(config .. "/fish/conf.d/" .. name, repo .. "/.config/fish/conf.d/" .. name))
end
if vim.fn.has("macunix") == 1 then
  check("Karabiner link", linked(config .. "/karabiner", repo .. "/.config/karabiner"))
  check("Hammerspoon link", linked(vim.env.HOME .. "/.hammerspoon/init.lua", repo .. "/.hammerspoon/init.lua"))
end
-- Use installed plugins without starting Lazy's installer or Mason auto-install.
local data = vim.fn.stdpath("data")
vim.opt.rtp:prepend(data .. "/lazy/lazy.nvim")
-- Check core components, not stale/optional entries in Lazy's historical lockfile.
for _, name in ipairs({ "lazy.nvim", "LazyVim", "nvim-lspconfig", "nvim-lint", "conform.nvim",
  "mason.nvim", "mason-lspconfig.nvim", "nvim-treesitter", "nvim-dap", "nvim-dap-go",
  "nvim-dap-python", "nvim-dap-ui", "nvim-nio" }) do
  check("plugin " .. name, vim.fn.isdirectory(data .. "/lazy/" .. name) == 1)
end
vim.opt.rtp:prepend(data .. "/lazy/mason.nvim")
vim.opt.rtp:prepend(data .. "/lazy/nvim-treesitter")
local mason = data .. "/mason"
local registry_ok, registry = pcall(require, "mason-registry")
check("Mason registry available", registry_ok)
if registry_ok then
  for _, name in ipairs(require("config.tools").packages) do
    local ok, package = pcall(registry.get_package, name)
    check("tool " .. name, ok and package:is_installed(), "run sh bootstrap.sh")
  end
end
check("Delve runs", run({ mason .. "/bin/dlv", "version" }))
check("Go language server runs", run({ mason .. "/bin/gopls", "version" }))
check("Go linter runs", run({ mason .. "/bin/golangci-lint", "version" }))
check("Python debug adapter imports", run({ mason .. "/packages/debugpy/venv/bin/python", "-c", "import debugpy" }))
check("JavaScript debug adapter executable", vim.fn.executable(mason .. "/bin/js-debug-adapter") == 1)
check("C/C++ debug adapter executable", vim.fn.executable(mason .. "/bin/codelldb") == 1)
check("Java integration plugin", vim.fn.isdirectory(data .. "/lazy/nvim-jdtls") == 1)
check("Java debug bundle", #vim.fn.glob(mason .. "/share/java-debug-adapter/*.jar", false, true) > 0)
local debug_home = data .. "/dotfiles-debug"
check("TypeScript runner", run({ "node", debug_home .. "/node_modules/tsx/dist/cli.mjs", "--version" }))
check("Browser launches", run({ "node", "-e",
  "const {chromium}=require(process.argv[1]);chromium.launch({headless:true}).then(b=>b.close()).catch(()=>process.exit(1))",
  debug_home .. "/node_modules/playwright" }))
local ts_ok, ts = pcall(require, "nvim-treesitter")
check("Treesitter module available", ts_ok)
if ts_ok then
  -- Make the installed parser directory visible in this clean -l process.
  vim.opt.rtp:prepend(data .. "/site")
  for _, name in ipairs(require("config.tools").parsers) do
    local ok = pcall(vim.treesitter.language.add, name)
    check("parser " .. name, ok, "run sh bootstrap.sh")
  end
end
if run({ "gh", "auth", "status" }) then
  print("PASS: GitHub CLI authentication")
else
  print("WARN: GitHub CLI not authenticated or unavailable; run gh auth login if needed")
end
print("NOTE: App permissions, terminal fonts, project dependencies, and live debug sessions are not tested.")
if failures > 0 then
  print("FAILED: " .. failures .. " required checks failed. Run sh bootstrap.sh and retry.")
  vim.cmd("cquit 1")
else
  print("PASSED: All required development-environment checks passed.")
  vim.cmd("qa!")
end
