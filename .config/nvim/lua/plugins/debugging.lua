return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "nvim-neotest/nvim-nio",
    {
      "leoluz/nvim-dap-go",
      opts = {
        tests = { verbose = true },
      },
    },
    "mfussenegger/nvim-dap-python",
  },
  config = function()
    local dap = require("dap")
    local dapui = require("dapui")

    dapui.setup()

    local mason = vim.fn.stdpath("data") .. "/mason"
    require("dap-python").setup(mason .. "/packages/debugpy/venv/bin/python")
    local debug_home = vim.fn.stdpath("data") .. "/dotfiles-debug"
    local function root()
      local markers = {
        go = { "go.mod", "go.work", ".git" },
        javascript = { "package.json", ".git" },
        javascriptreact = { "package.json", ".git" },
        typescript = { "package.json", ".git" },
        typescriptreact = { "package.json", ".git" },
        java = { "pom.xml", "build.gradle", "build.gradle.kts", ".git" },
        c = { "CMakeLists.txt", ".git" },
        cpp = { "CMakeLists.txt", ".git" },
      }
      return vim.fs.root(0, markers[vim.bo.filetype] or { ".git" }) or vim.fn.getcwd()
    end
    -- Delve otherwise inherits Neovim's working directory. That fails for
    -- repositories containing nested Go modules, even when the open file is
    -- inside a valid module.
    for _, config in ipairs(dap.configurations.go or {}) do
      config.cwd = root
    end
    dap.adapters.codelldb = {
      type = "server", port = "${port}",
      executable = { command = mason .. "/bin/codelldb", args = { "--port", "${port}" } },
    }
    for _, language in ipairs({ "c", "cpp" }) do
      dap.configurations[language] = {
        {
          name = "Build and debug current file (standalone)", type = "codelldb", request = "launch",
          cwd = root,
          program = function()
            vim.cmd("write")
            local source = vim.api.nvim_buf_get_name(0)
            local output = vim.fn.stdpath("cache") .. "/dotfiles-debug/" .. vim.fn.sha256(source)
            vim.fn.mkdir(vim.fs.dirname(output), "p")
            local compiler = vim.bo.filetype == "cpp" and "clang++" or "clang"
            local result = vim.system({ compiler, "-g", "-O0", source, "-o", output }, { text = true }):wait()
            if result.code ~= 0 then
              vim.notify(result.stderr, vim.log.levels.ERROR)
              return dap.ABORT
            end
            return output
          end,
        },
        {
          name = "Debug built executable", type = "codelldb", request = "launch", cwd = root,
          program = function() return vim.fn.input("Executable: ", root() .. "/", "file") end,
        },
        {
          name = "Attach to native process", type = "codelldb", request = "attach",
          pid = require("dap.utils").pick_process, cwd = root,
        },
      }
    end

    for _, adapter in ipairs({ "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal" }) do
      dap.adapters[adapter] = {
        type = "server",
        host = "127.0.0.1",
        port = "${port}",
        executable = {
          command = mason .. "/bin/js-debug-adapter",
          args = { "${port}", "127.0.0.1" },
        },
      }
    end

    for _, language in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact" }) do
      dap.configurations[language] = {
        {
          type = "pwa-node",
          request = "launch",
          name = "Launch current file (Node)",
          program = "${file}",
          cwd = root,
          runtimeExecutable = "node",
          runtimeArgs = { debug_home .. "/node_modules/tsx/dist/cli.mjs" },
          sourceMaps = true,
          skipFiles = { "<node_internals>/**", "**/node_modules/**" },
          console = "integratedTerminal",
        },
        {
          type = "pwa-chrome",
          request = "launch",
          name = "Launch Chrome against localhost",
          url = function() return vim.fn.input("Dev server URL: ", "http://localhost:5173") end,
          webRoot = root,
          runtimeExecutable = function()
            return assert(require("config.debug-env").chromium, "Run sh bootstrap.sh to install Chromium")
          end,
          sourceMaps = true,
          userDataDir = vim.fn.stdpath("cache") .. "/dotfiles-chromium",
        },
        {
          name = "Attach to Node (--inspect)", type = "pwa-node", request = "attach",
          processId = require("dap.utils").pick_process, cwd = root, sourceMaps = true,
        },
        {
          name = "Debug npm script", type = "pwa-node", request = "launch",
          runtimeExecutable = "npm", cwd = root, console = "integratedTerminal",
          runtimeArgs = function() return { "run", vim.fn.input("npm script: ", "dev") } end,
          autoAttachChildProcesses = true, sourceMaps = true,
        },
      }
    end

    -- Project .vscode/launch.json entries override defaults by name.
    vim.keymap.set("n", "<leader>dj", function()
      require("dap.ext.vscode").load_launchjs(root() .. "/.vscode/launch.json", {
        codelldb = { "c", "cpp" }, java = { "java" }, python = { "python" },
        ["pwa-node"] = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
        ["pwa-chrome"] = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
      })
    end, { desc = "DAP: Load project launch.json" })

    dap.listeners.before.attach.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.launch.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated.dapui_config = function()
      dapui.close()
    end
    dap.listeners.before.event_exited.dapui_config = function()
      dapui.close()
    end

    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "dap-repl", "dapui_console" },
      callback = function()
        vim.opt_local.winfixheight = true
      end,
    })

    vim.keymap.set("n", "<F5>", dap.continue, { desc = "DAP: Continue" })
    vim.keymap.set("n", "<F10>", dap.step_over, { desc = "DAP: Step over" })
    vim.keymap.set("n", "<F11>", dap.step_into, { desc = "DAP: Step into" })
    vim.keymap.set("n", "<F12>", dap.step_out, { desc = "DAP: Step out" })

    vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "DAP: Toggle breakpoint" })
    vim.keymap.set("n", "<leader>dB", function()
      dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
    end, { desc = "DAP: Conditional breakpoint" })

    vim.keymap.set("n", "<leader>dr", dap.repl.toggle, { desc = "DAP: REPL" })
    vim.keymap.set("n", "<leader>dl", dap.run_last, { desc = "DAP: Run last" })
    vim.keymap.set("n", "<leader>dt", dap.terminate, { desc = "DAP: Terminate" })
    vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "DAP: Continue" })
    local last_go_test
    vim.keymap.set("n", "<leader>dgn", function()
      local dap_go = require("dap-go")
      local package_dir = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
      local config = {
        cwd = root(),
        program = package_dir,
      }
      if dap_go.debug_test(config) then
        last_go_test = {
          type = "go",
          request = "launch",
          mode = "test",
          name = dap_go.last_testname,
          program = package_dir,
          cwd = config.cwd,
          args = { "-test.run", "^" .. dap_go.last_testname .. "$", "-test.v" },
          buildFlags = dap_go.test_buildflags,
          outputMode = "remote",
        }
      end
    end, { desc = "DAP: Debug nearest Go test" })
    vim.keymap.set("n", "<leader>dgl", function()
      if not last_go_test then
        vim.notify("No Go test has been debugged in this session", vim.log.levels.WARN)
        return
      end
      dap.run(vim.deepcopy(last_go_test))
    end, { desc = "DAP: Debug last Go test" })

    vim.keymap.set("n", "<leader>dw", function()
      require("dapui").elements.watches.add()
    end, { desc = "DAP: Add watch" })

    vim.keymap.set("n", "<leader>dW", function()
      require("dapui").elements.watches.remove()
    end, { desc = "DAP: Remove watch" })
  end,
}
