return {
  { import = "lazyvim.plugins.extras.lang.java" },
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      opts.root_dir = function(path)
        return vim.fs.root(path, { "pom.xml", "build.gradle", "build.gradle.kts", ".git" })
          or vim.fs.dirname(path)
      end
      -- Avoid collisions between projects with identical directory names.
      opts.project_name = function(root)
        return vim.fs.basename(root) .. "-" .. vim.fn.sha256(root):sub(1, 12)
      end
    end,
  },
}
