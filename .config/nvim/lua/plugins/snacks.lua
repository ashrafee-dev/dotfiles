return {
  "folke/snacks.nvim",
  keys = {
    {
      "<leader>uz",
      function()
        vim.g.auto_center_mode = not (Snacks.zen.win and Snacks.zen.win:valid())
        Snacks.zen()
      end,
      desc = "Toggle Center Mode",
    },
  },
  opts = {
    zen = {
      center = false, -- Preserve vertical scroll position instead of centering the cursor.
      toggles = {
        dim = false,
        diagnostics = true,
        inlay_hints = true,
      },
      show = {
        statusline = true,
        tabline = true,
      },
      win = {
        width = 100,
        height = 0, -- Full height; only add horizontal margins.
      },
    },
  },
}
