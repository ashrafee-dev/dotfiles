return {
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts.linters = opts.linters or {}
      opts.linters.golangcilint = function()
        local linter = vim.deepcopy(require("lint.linters.golangcilint"))
        local filename = vim.api.nvim_buf_get_name(0)
        local directory = vim.fs.dirname(filename)
        local module_root = vim.fs.root(directory, "go.mod")
        -- A go.work root has no go.mod. Lint the file's package instead
        -- of letting the default adapter treat it as a standalone file.
        linter.cwd = module_root or directory
        linter.args[#linter.args] = module_root and directory or filename
        return linter
      end
    end,
  },
}
