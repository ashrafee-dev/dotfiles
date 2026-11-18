# Debugging

Run `sh bootstrap.sh`, then open a source file in Neovim. Set a breakpoint with
`<leader>db`, press **F5** to select a launch profile. F10 steps over, F11 steps
into, F12 steps out. `<leader>dt` terminates; `<leader>dr` opens the debug REPL.

| Language | Supplied setup | Usage |
| --- | --- | --- |
| Python | Python + isolated debugpy | F5 launches the file; project `.venv`/`venv` is detected by nvim-dap-python. Install your project's packages into it. |
| C / C++ | LLVM compiler + CodeLLDB | “Build and debug current file” compiles a standalone file with debug symbols. For multi-file/CMake projects, build with debug symbols and choose “Debug built executable”. |
| Go | Go + Delve | Start with **Debug Package** for an application; see the profile guide below. |
| Java | JDK 21 + JDTLS + Java debugger/test bundles | Open a Java file, wait for JDTLS to import the project and discover main classes, then F5. Maven/Gradle wrappers and project-selected JDKs remain authoritative. |
| JavaScript / TypeScript | Node + tsx + vscode-js-debug | “Launch current file” handles standalone JS/TS; “Debug npm script” runs an existing package script with child-process debugging. |
| React / JSX / TSX | Downloaded Chromium + vscode-js-debug | Start your project's dev server, choose the browser launch profile, and enter its URL. Source maps must be enabled. React components aren't standalone Node programs. |

## Go: which F5 option should I choose?

**For a normal Go application, choose `Debug Package`.** It builds and runs the
package containing your open file, including its other source files. The package
must be runnable (`package main` with a `main()` function); use a test profile for
library packages.

1. In your terminal, `cd` to the project directory containing `go.mod`, then run
   `nvim .`.
2. Open a Go file in the application package, for example `cmd/server/main.go`.
3. Move to a line inside `main()` and press **Space, d, b** to toggle a breakpoint.
4. Press **F5**, choose **Debug Package**, and press Enter.
5. When it pauses, inspect variables in the debug panels. Use **F10** to step
   over, **F11** to step into, **F5** to continue, and **Space, d, t** to stop.

Here `<leader>` means **Space**; press the keys in sequence. Some keyboards
require **Fn + F5**, etc.

| Menu label | When to choose it |
| --- | --- |
| Debug | Run the current Go file; useful for standalone programs. Prefer Debug Package for multi-file applications. |
| Debug (Arguments) | Run the current file and enter command-line arguments when prompted. |
| Debug (Arguments & Build Flags) | Run the current file with arguments and Go build flags, such as build tags. |
| Debug Package | Run the package containing the current file. Recommended starting point for applications. |
| Attach | Debug an already-running local process; select its process ID. Not the normal starting option. |
| Debug test | Launch a test debug session targeting the current test file. Open a `_test.go` file first. |
| Debug test (go.mod) | Launch tests for the current file's package using a path relative to the project/module working directory. Start Neovim from the directory containing `go.mod`. |

For a focused test, place the cursor inside a `Test...` function in a `_test.go`
file and press `<leader>dgn`. After that first launch, `<leader>dgl` reruns the
same test from any Go source file. Test discovery is intentionally scoped to the
current test buffer; invoking "nearest test" from an implementation file reports
`no test found`. Both actions resolve the nearest `go.mod` or `go.work`
automatically, so Neovim may be started from a repository above a nested module.

Choose by **label**, not menu number: numbers can change. If the same seven
options appear twice, they are duplicate registrations, not different modes.
Either matching entry has the same purpose; report/fix the duplicate setup
rather than treating the second group as additional features.

## Project-specific launch settings

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
