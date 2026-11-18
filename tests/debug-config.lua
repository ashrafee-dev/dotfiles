-- Validate all launch profiles without installing or starting any debugger.
local repo = assert(vim.env.DOTFILES_REPO)
local dap = {
  adapters = {}, configurations = {}, ABORT = {},
  listeners = { before = { attach = {}, launch = {}, event_terminated = {}, event_exited = {} } },
}
setmetatable(dap, { __index = function() return function() end end })
dap.repl = { toggle = function() end }
package.loaded.dap = dap
package.loaded.dapui = { setup = function() end, open = function() end, close = function() end }
package.loaded["dap-go"] = { setup = function() end }
package.loaded["dap-python"] = { setup = function(path) assert(path:match("debugpy/venv/bin/python$")) end }
package.loaded["dap.utils"] = { pick_process = function() end }
local spec = dofile(repo .. "/.config/nvim/lua/plugins/debugging.lua")
spec.config()
for _, ft in ipairs({ "c", "cpp", "javascript", "typescript", "javascriptreact", "typescriptreact" }) do
  assert(#dap.configurations[ft] >= 3, ft .. " missing launch profiles")
  for _, profile in ipairs(dap.configurations[ft]) do
    assert(dap.adapters[profile.type], "Adapter missing: " .. profile.type)
  end
end
assert(dap.configurations.typescript[1].runtimeArgs[1]:match("tsx/dist/cli.mjs$"))
-- Exercise actual compilation for a standalone C source, not just table shape.
local source = vim.fn.tempname() .. ".c"
vim.fn.writefile({ "int main(void) { return 0; }" }, source)
vim.cmd.edit(source)
vim.bo.filetype = "c"
local executable = dap.configurations.c[1].program()
assert(type(executable) == "string" and vim.fn.executable(executable) == 1)
assert(vim.system({ executable }):wait().code == 0)
vim.fn.delete(source)
vim.fn.delete(executable)
print("PASS: launch profiles, adapter wiring, TypeScript runner, and standalone C build")
