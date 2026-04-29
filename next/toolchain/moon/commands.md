# Command-Line Help for `moon`

This document contains the help content for the `moon` command-line program.

```{hint}
For the up-to-date manual, please check out [moon's repository](https://github.com/moonbitlang/moon/blob/main/docs/manual/src/commands.md)
```

**Command Overview:**

* [`moon`↴](#moon)
* [`moon new`↴](#moon-new)
* [`moon build`↴](#moon-build)
* [`moon check`↴](#moon-check)
* [`moon run`↴](#moon-run)
* [`moon test`↴](#moon-test)
* [`moon clean`↴](#moon-clean)
* [`moon fmt`↴](#moon-fmt)
* [`moon doc`↴](#moon-doc)
* [`moon info`↴](#moon-info)
* [`moon bench`↴](#moon-bench)
* [`moon add`↴](#moon-add)
* [`moon remove`↴](#moon-remove)
* [`moon install`↴](#moon-install)
* [`moon tree`↴](#moon-tree)
* [`moon login`↴](#moon-login)
* [`moon register`↴](#moon-register)
* [`moon publish`↴](#moon-publish)
* [`moon package`↴](#moon-package)
* [`moon update`↴](#moon-update)
* [`moon coverage`↴](#moon-coverage)
* [`moon coverage analyze`↴](#moon-coverage-analyze)
* [`moon coverage report`↴](#moon-coverage-report)
* [`moon coverage clean`↴](#moon-coverage-clean)
* [`moon generate-build-matrix`↴](#moon-generate-build-matrix)
* [`moon upgrade`↴](#moon-upgrade)
* [`moon shell-completion`↴](#moon-shell-completion)
* [`moon version`↴](#moon-version)

## `moon`

**Usage:** `moon <COMMAND>`

**Subcommands:**

* `new` — Create a new MoonBit module
* `build` — Build the current package
* `check` — Check the current package, but don't build object files
* `run` — Run a main package
* `test` — Test the current package
* `clean` — Remove the _build directory
* `fmt` — Format source code
* `doc` — Generate documentation or searching documentation for a symbol
* `info` — Generate public interface (`.mbti`) files for all packages in the module
* `bench` — Run benchmarks in the current package
* `add` — Add a dependency
* `remove` — Remove a dependency
* `install` — Install dependencies
* `tree` — Display the dependency tree
* `login` — Log in to your account
* `register` — Register an account at mooncakes.io
* `publish` — Publish the current module
* `package` — Package the current module
* `update` — Update the package registry index
* `coverage` — Code coverage utilities
* `generate-build-matrix` — Generate build matrix for benchmarking (legacy feature)
* `upgrade` — Upgrade toolchains
* `shell-completion` — Generate shell completion for bash/elvish/fish/pwsh/zsh to stdout
* `version` — Print version information and exit



## `moon new`

Create a new MoonBit module

**Usage:** `moon new [OPTIONS] <PATH>`

**Arguments:**

* `<PATH>` — The path of the new project

**Options:**

* `--user <USER>` — The username of the module. Default to the logged-in username
* `--name <NAME>` — The name of the module. Default to the last part of the path



## `moon build`

Build the current package

**Usage:** `moon build [OPTIONS]`

**Options:**

* `--std` — Enable the standard library (default)
* `--nostd` — Disable the standard library
* `-g`, `--debug` — Emit debug information
* `--release` — Compile in release mode
* `--strip` — Enable stripping debug information
* `--no-strip` — Disable stripping debug information
* `--target <TARGET>` — Select output target

  Possible values: `wasm`, `wasm-gc`, `js`, `native`, `llvm`, `all`

* `--enable-coverage` — Enable coverage instrumentation
* `--sort-input` — Sort input files
* `--output-wat` — Output WAT instead of WASM
* `-d`, `--deny-warn` — Treat all warnings as errors
* `--no-render` — Don't render diagnostics from moonc (don't pass '-error-format json' to moonc)
* `--warn-list <WARN_LIST>` — Warn list config
* `--alert-list <ALERT_LIST>` — Alert list config
* `-j`, `--jobs <JOBS>` — Set the max number of jobs to run in parallel
* `--render-no-loc <MIN_LEVEL>` — Render no-location diagnostics starting from a certain level

  Default value: `error`

  Possible values: `info`, `warn`, `error`

* `--frozen` — Do not sync dependencies, assuming local dependencies are up-to-date
* `-w`, `--watch` — Monitor the file system and automatically build artifacts



## `moon check`

Check the current package, but don't build object files

**Usage:** `moon check [OPTIONS] [SINGLE_FILE]`

**Arguments:**

* `<SINGLE_FILE>` — Check single file (.mbt or .mbt.md)

**Options:**

* `--std` — Enable the standard library (default)
* `--nostd` — Disable the standard library
* `-g`, `--debug` — Emit debug information
* `--release` — Compile in release mode
* `--strip` — Enable stripping debug information
* `--no-strip` — Disable stripping debug information
* `--target <TARGET>` — Select output target

  Possible values: `wasm`, `wasm-gc`, `js`, `native`, `llvm`, `all`

* `--enable-coverage` — Enable coverage instrumentation
* `--sort-input` — Sort input files
* `--output-wat` — Output WAT instead of WASM
* `-d`, `--deny-warn` — Treat all warnings as errors
* `--no-render` — Don't render diagnostics from moonc (don't pass '-error-format json' to moonc)
* `--warn-list <WARN_LIST>` — Warn list config
* `--alert-list <ALERT_LIST>` — Alert list config
* `-j`, `--jobs <JOBS>` — Set the max number of jobs to run in parallel
* `--render-no-loc <MIN_LEVEL>` — Render no-location diagnostics starting from a certain level

  Default value: `error`

  Possible values: `info`, `warn`, `error`

* `--output-json` — Output in json format
* `--frozen` — Do not sync dependencies, assuming local dependencies are up-to-date
* `-w`, `--watch` — Monitor the file system and automatically check files
* `-p`, `--package-path <PACKAGE_PATH>` — The package(and it's deps) to check
* `--patch-file <PATCH_FILE>` — The patch file to check, Only valid when checking specified package
* `--no-mi` — Whether to skip the mi generation, Only valid when checking specified package
* `--explain` — Whether to explain the error code with details



## `moon run`

Run a main package

**Usage:** `moon run [OPTIONS] <PACKAGE_OR_MBT_FILE> [ARGS]...`

**Arguments:**

* `<PACKAGE_OR_MBT_FILE>` — The package or .mbt file to run
* `<ARGS>` — The arguments provided to the program to be run

**Options:**

* `--std` — Enable the standard library (default)
* `--nostd` — Disable the standard library
* `-g`, `--debug` — Emit debug information
* `--release` — Compile in release mode
* `--strip` — Enable stripping debug information
* `--no-strip` — Disable stripping debug information
* `--target <TARGET>` — Select output target

  Possible values: `wasm`, `wasm-gc`, `js`, `native`, `llvm`, `all`

* `--enable-coverage` — Enable coverage instrumentation
* `--sort-input` — Sort input files
* `--output-wat` — Output WAT instead of WASM
* `-d`, `--deny-warn` — Treat all warnings as errors
* `--no-render` — Don't render diagnostics from moonc (don't pass '-error-format json' to moonc)
* `--warn-list <WARN_LIST>` — Warn list config
* `--alert-list <ALERT_LIST>` — Alert list config
* `-j`, `--jobs <JOBS>` — Set the max number of jobs to run in parallel
* `--render-no-loc <MIN_LEVEL>` — Render no-location diagnostics starting from a certain level

  Default value: `error`

  Possible values: `info`, `warn`, `error`

* `--frozen` — Do not sync dependencies, assuming local dependencies are up-to-date
* `--build-only` — Only build, do not run the code



## `moon test`

Test the current package

**Usage:** `moon test [OPTIONS] [SINGLE_FILE]`

**Arguments:**

* `<SINGLE_FILE>` — Run test in single file (.mbt or .mbt.md)

**Options:**

* `--std` — Enable the standard library (default)
* `--nostd` — Disable the standard library
* `-g`, `--debug` — Emit debug information
* `--release` — Compile in release mode
* `--strip` — Enable stripping debug information
* `--no-strip` — Disable stripping debug information
* `--target <TARGET>` — Select output target

  Possible values: `wasm`, `wasm-gc`, `js`, `native`, `llvm`, `all`

* `--enable-coverage` — Enable coverage instrumentation
* `--sort-input` — Sort input files
* `--output-wat` — Output WAT instead of WASM
* `-d`, `--deny-warn` — Treat all warnings as errors
* `--no-render` — Don't render diagnostics from moonc (don't pass '-error-format json' to moonc)
* `--warn-list <WARN_LIST>` — Warn list config
* `--alert-list <ALERT_LIST>` — Alert list config
* `-j`, `--jobs <JOBS>` — Set the max number of jobs to run in parallel
* `--render-no-loc <MIN_LEVEL>` — Render no-location diagnostics starting from a certain level

  Default value: `error`

  Possible values: `info`, `warn`, `error`

* `-p`, `--package <PACKAGE>` — Run test in the specified package
* `-f`, `--file <FILE>` — Run test in the specified file. Only valid when `--package` is also specified
* `-i`, `--index <INDEX>` — Run only the index-th test in the file. Only valid when `--file` is also specified
* `--doc-index <DOC_INDEX>` — Run only the index-th doc test in the file. Only valid when `--file` is also specified
* `-u`, `--update` — Update the test snapshot
* `-l`, `--limit <LIMIT>` — Limit of expect test update passes to run, in order to avoid infinite loops

  Default value: `256`
* `--frozen` — Do not sync dependencies, assuming local dependencies are up-to-date
* `--build-only` — Only build, do not run the tests
* `--no-parallelize` — Run the tests in a target backend sequentially
* `--test-failure-json` — Print failure message in JSON format
* `--patch-file <PATCH_FILE>` — Path to the patch file
* `--doc` — Run doc test



## `moon clean`

Remove the _build directory

**Usage:** `moon clean`



## `moon fmt`

Format source code

**Usage:** `moon fmt [OPTIONS] [ARGS]...`

**Arguments:**

* `<ARGS>`

**Options:**

* `--check` — Check only and don't change the source code
* `--sort-input` — Sort input files
* `--block-style <BLOCK_STYLE>` — Add separator between each segments

  Possible values: `false`, `true`




## `moon doc`

Generate documentation or searching documentation for a symbol

**Usage:** `moon doc [OPTIONS] [SYMBOL]`

**Arguments:**

* `<SYMBOL>` — [Deprecated] The symbol to query documentation for. Use `moon ide doc <SYMBOL>` instead.

**Options:**

* `--serve` — Start a web server to serve the documentation
* `-b`, `--bind <BIND>` — The address of the server

  Default value: `127.0.0.1`
* `-p`, `--port <PORT>` — The port of the server

  Default value: `3000`
* `--frozen` — Do not sync dependencies, assuming local dependencies are up-to-date



## `moon info`

Generate public interface (`.mbti`) files for all packages in the module

**Usage:** `moon info [OPTIONS]`

**Options:**

* `--frozen` — Do not sync dependencies, assuming local dependencies are up-to-date
* `--no-alias` — Do not use alias to shorten package names in the output
* `--target <TARGET>` — Select output target

  Possible values: `wasm`, `wasm-gc`, `js`, `native`, `llvm`, `all`

* `-p`, `--package <PACKAGE>` — only emit mbti files for the specified package



## `moon bench`

Run benchmarks in the current package

**Usage:** `moon bench [OPTIONS]`

**Options:**

* `--std` — Enable the standard library (default)
* `--nostd` — Disable the standard library
* `-g`, `--debug` — Emit debug information
* `--release` — Compile in release mode
* `--strip` — Enable stripping debug information
* `--no-strip` — Disable stripping debug information
* `--target <TARGET>` — Select output target

  Possible values: `wasm`, `wasm-gc`, `js`, `native`, `llvm`, `all`

* `--enable-coverage` — Enable coverage instrumentation
* `--sort-input` — Sort input files
* `--output-wat` — Output WAT instead of WASM
* `-d`, `--deny-warn` — Treat all warnings as errors
* `--no-render` — Don't render diagnostics from moonc (don't pass '-error-format json' to moonc)
* `--warn-list <WARN_LIST>` — Warn list config
* `--alert-list <ALERT_LIST>` — Alert list config
* `-j`, `--jobs <JOBS>` — Set the max number of jobs to run in parallel
* `--render-no-loc <MIN_LEVEL>` — Render no-location diagnostics starting from a certain level

  Default value: `error`

  Possible values: `info`, `warn`, `error`

* `-p`, `--package <PACKAGE>` — Run test in the specified package
* `-f`, `--file <FILE>` — Run test in the specified file. Only valid when `--package` is also specified
* `-i`, `--index <INDEX>` — Run only the index-th test in the file. Only valid when `--file` is also specified
* `--frozen` — Do not sync dependencies, assuming local dependencies are up-to-date
* `--build-only` — Only build, do not bench
* `--no-parallelize` — Run the benchmarks in a target backend sequentially



## `moon add`

Add a dependency

**Usage:** `moon add [OPTIONS] <PACKAGE_PATH>`

**Arguments:**

* `<PACKAGE_PATH>` — The package path to add

**Options:**

* `--bin` — Whether to add the dependency as a binary



## `moon remove`

Remove a dependency

**Usage:** `moon remove <PACKAGE_PATH>`

**Arguments:**

* `<PACKAGE_PATH>` — The package path to remove



## `moon install`

Install dependencies

**Usage:** `moon install`



## `moon tree`

Display the dependency tree

**Usage:** `moon tree`



## `moon login`

Log in to your account

**Usage:** `moon login`



## `moon register`

Register an account at mooncakes.io

**Usage:** `moon register`



## `moon publish`

Publish the current module

**Usage:** `moon publish [OPTIONS]`

**Options:**

* `--frozen` — Do not sync dependencies, assuming local dependencies are up-to-date



## `moon package`

Package the current module

**Usage:** `moon package [OPTIONS]`

**Options:**

* `--frozen` — Do not sync dependencies, assuming local dependencies are up-to-date
* `--list`



## `moon update`

Update the package registry index

**Usage:** `moon update`



## `moon coverage`

Code coverage utilities

**Usage:** `moon coverage <COMMAND>`

**Subcommands:**

* `analyze` — Run test with instrumentation and report coverage
* `report` — Generate code coverage report
* `clean` — Clean up coverage artifacts



## `moon coverage analyze`

Run test with instrumentation and report coverage

**Usage:** `moon coverage analyze [OPTIONS] [-- <EXTRA_FLAGS>...]`

**Arguments:**

* `<EXTRA_FLAGS>` — Extra flags passed directly to `moon_cove_report`

**Options:**

* `-p`, `--package <PACKAGE>` — Analyze coverage for a specific package



## `moon coverage report`

Generate code coverage report

**Usage:** `moon coverage report [args]... [COMMAND]`

**Arguments:**

* `<args>` — Arguments to pass to the coverage utility

**Options:**

* `-h`, `--help` — Show help for the coverage utility



## `moon coverage clean`

Clean up coverage artifacts

**Usage:** `moon coverage clean`



## `moon generate-build-matrix`

Generate build matrix for benchmarking (legacy feature)

**Usage:** `moon generate-build-matrix [OPTIONS] --output-dir <OUT_DIR>`

**Options:**

* `-n <NUMBER>` — Set all of `drow`, `dcol`, `mrow`, `mcol` to the same value
* `--drow <DIR_ROWS>` — Number of directory rows
* `--dcol <DIR_COLS>` — Number of directory columns
* `--mrow <MOD_ROWS>` — Number of module rows
* `--mcol <MOD_COLS>` — Number of module columns
* `-o`, `--output-dir <OUT_DIR>` — The output directory



## `moon upgrade`

Upgrade toolchains

**Usage:** `moon upgrade [OPTIONS]`

**Options:**

* `-f`, `--force` — Force upgrade
* `--dev` — Install the latest development version



## `moon shell-completion`

Generate shell completion for bash/elvish/fish/pwsh/zsh to stdout

**Usage:** `moon shell-completion [OPTIONS]`


Discussion:
Enable tab completion for Bash, Elvish, Fish, Zsh, or PowerShell
The script is output on `stdout`, allowing one to re-direct the
output to the file of their choosing. Where you place the file
will depend on which shell, and which operating system you are
using. Your particular configuration may also determine where
these scripts need to be placed.

The completion scripts won't update itself, so you may need to
periodically run this command to get the latest completions.
Or you may put `eval "$(moon shell-completion --shell <SHELL>)"`
in your shell's rc file to always load newest completions on startup.
Although it's considered not as efficient as having the completions
script installed.

Here are some common set ups for the three supported shells under
Unix and similar operating systems (such as GNU/Linux).

Bash:

Completion files are commonly stored in `/etc/bash_completion.d/` for
system-wide commands, but can be stored in
`~/.local/share/bash-completion/completions` for user-specific commands.
Run the command:

    $ mkdir -p ~/.local/share/bash-completion/completions
    $ moon shell-completion --shell bash >> ~/.local/share/bash-completion/completions/moon

This installs the completion script. You may have to log out and
log back in to your shell session for the changes to take effect.

Bash (macOS/Homebrew):

Homebrew stores bash completion files within the Homebrew directory.
With the `bash-completion` brew formula installed, run the command:

    $ mkdir -p $(brew --prefix)/etc/bash_completion.d
    $ moon shell-completion --shell bash > $(brew --prefix)/etc/bash_completion.d/moon.bash-completion

Fish:

Fish completion files are commonly stored in
`$HOME/.config/fish/completions`. Run the command:

    $ mkdir -p ~/.config/fish/completions
    $ moon shell-completion --shell fish > ~/.config/fish/completions/moon.fish

This installs the completion script. You may have to log out and
log back in to your shell session for the changes to take effect.

Elvish:

Elvish completions are commonly stored in a single `completers` module.
A typical module search path is `~/.config/elvish/lib`, and
running the command:

    $ moon shell-completion --shell elvish >> ~/.config/elvish/lib/completers.elv

will install the completions script. Note that use `>>` (append) 
instead of `>` (overwrite) to prevent overwriting the existing completions 
for other commands. Then prepend your rc.elv with:

    `use completers`

to load the `completers` module and enable completions.

Zsh:

ZSH completions are commonly stored in any directory listed in
your `$fpath` variable. To use these completions, you must either
add the generated script to one of those directories, or add your
own to this list.

Adding a custom directory is often the safest bet if you are
unsure of which directory to use. First create the directory; for
this example we'll create a hidden directory inside our `$HOME`
directory:

    $ mkdir ~/.zfunc

Then add the following lines to your `.zshrc` just before
`compinit`:

    fpath+=~/.zfunc

Now you can install the completions script using the following
command:

    $ moon shell-completion --shell zsh > ~/.zfunc/_moon

You must then open a new zsh session, or simply run

    $ . ~/.zshrc

for the new completions to take effect.

Custom locations:

Alternatively, you could save these files to the place of your
choosing, such as a custom directory inside your $HOME. Doing so
will require you to add the proper directives, such as `source`ing
inside your login script. Consult your shells documentation for
how to add such directives.

PowerShell:

The powershell completion scripts require PowerShell v5.0+ (which
comes with Windows 10, but can be downloaded separately for windows 7
or 8.1).

First, check if a profile has already been set

    PS C:\> Test-Path $profile

If the above command returns `False` run the following

    PS C:\> New-Item -path $profile -type file -force

Now open the file provided by `$profile` (if you used the
`New-Item` command it will be
`${env:USERPROFILE}\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`

Next, we either save the completions file into our profile, or
into a separate file and source it inside our profile. To save the
completions into our profile simply use

    PS C:\> moon shell-completion --shell powershell >>
    ${env:USERPROFILE}\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1

This discussion is taken from `rustup completions` command with some changes.


**Options:**

* `--shell <SHELL>` — The shell to generate completion for

  Default value: `<your shell>`

  Possible values: `bash`, `elvish`, `fish`, `powershell`, `zsh`




## `moon version`

Print version information and exit

**Usage:** `moon version [OPTIONS]`

**Options:**

* `--all` — Print all version information
* `--json` — Print version information in JSON format
* `--no-path` — Do not print the path



<hr/>

<small><i>
    This document was generated automatically by
    <a href="https://crates.io/crates/clap-markdown"><code>clap-markdown</code></a>.
</i></small>
