local M = {}
function M.setup()
  local path = vim.fn.stdpath("data") .. "/dotfiles-debug/environment.json"
  if vim.fn.filereadable(path) == 1 then
    local env = vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
    vim.env.JAVA_HOME = env.java_home
    vim.env.PATH = env.java_home .. "/bin:" .. env.llvm_bin .. ":" .. vim.env.PATH
    M.chromium = env.chromium
  end
end
return M
