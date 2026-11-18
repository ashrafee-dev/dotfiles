# Debugging

Run `sh bootstrap.sh`, then open a source file in Neovim. Set a breakpoint with
`<leader>db`, press **F5** to select a launch profile. F10 steps over, F11 steps
into, F12 steps out. `<leader>dt` terminates; `<leader>dr` opens the debug REPL.

| Language | Supplied setup | Usage |
| --- | --- | --- |
| Python | Python + isolated debugpy | F5 launches the file; project `.venv`/`venv` is detected by nvim-dap-python. Install your project's packages into it. |
| C / C++ | LLVM compiler + CodeLLDB | “Build and debug current file” compiles a standalone file with debug symbols. For multi-file/CMake projects, build with debug symbols and choose “Debug built executable”. |
| Go | Go + Delve | F5: debug package/file or tests via nvim-dap-go. Open the project module directory. |
| Java | JDK 21 + JDTLS + Java debugger/test bundles | Open a Java file, wait for JDTLS to import the project and discover main classes, then F5. Maven/Gradle wrappers and project-selected JDKs remain authoritative. |
| JavaScript / TypeScript | Node + tsx + vscode-js-debug | “Launch current file” handles standalone JS/TS; “Debug npm script” runs an existing package script with child-process debugging. |
| React / JSX / TSX | Downloaded Chromium + vscode-js-debug | Start your project's dev server, choose the browser launch profile, and enter its URL. Source maps must be enabled. React components aren't standalone Node programs. |

`<leader>dj` loads `.vscode/launch.json` from the project root for custom
arguments, environment, executable paths, source maps, or attach targets. Use
adapter types `codelldb`, `python`, `java`, `go`, `pwa-node`, or `pwa-chrome`.
VS Code `preLaunchTask` tasks/extensions are not executed by nvim-dap.

Bootstrap installs editor/debugger dependencies, not arbitrary project packages,
databases, services, cross-compilers, or every historic JDK. A project requiring
a different Java version needs that JDK configured in JDTLS. Native attach may
require OS debugging permission. On Linux, Chromium may require system libraries:
run the installed Playwright CLI with `install-deps chromium` (administrator
access may be required), then rerun bootstrap. Bootstrap tests browser startup
and fails if these prerequisites are missing.

`sh doctor.sh` checks installed adapters, Java/C/C++ toolchains, tsx, and browser
startup. Passing these checks is not a claim that every project's debug session
has been tested. Native Windows is unsupported; use WSL.
