return {
  "folke/snacks.nvim",
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
        width = function()
          return vim.g.zen_width or 150
        end,
        height = 0, -- Full height; only add horizontal margins.
      },
    },
  },
}
