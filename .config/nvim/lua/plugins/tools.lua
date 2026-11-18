return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      for _, name in ipairs(require("config.tools").packages) do
        if not vim.tbl_contains(opts.ensure_installed, name) then
          table.insert(opts.ensure_installed, name)
        end
      end
    end,
  },
}
