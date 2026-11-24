return {
  "folke/snacks.nvim",
  keys = {
    { "<leader>uz", false },
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
