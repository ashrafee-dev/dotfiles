-- Shared by bootstrap, doctor, and Mason: one source of truth.
return {
  packages = {
    "gopls", "goimports", "gofumpt", "golangci-lint", "delve",
    "lua-language-server", "stylua", "shfmt",
    "json-lsp", "marksman", "markdownlint-cli2", "markdown-toc",
    "debugpy", "js-debug-adapter",
  },
  parsers = {
    "bash", "c", "diff", "go", "gomod", "gosum", "gowork",
    "html", "javascript", "json", "jsonc", "lua", "luadoc",
    "markdown", "markdown_inline", "python", "query", "regex",
    "toml", "tsx", "typescript", "vim", "vimdoc", "yaml",
  },
}
