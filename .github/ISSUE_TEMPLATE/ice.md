---
name: Internal Compiler Error
description: Report an Internal Compiler Error (ICE) occuring in the MoonBit toolchain
labels: bug, ICE
---

<!--
  Thank you for finding an Internal Compiler Error!

  If possible, please try to find a minimal reproducing example, so that it
  could be simpler for us to pinpoint the issue.
-->

(Your description on the reproducing steps or environment)

### Code

- Target: (wasm, wasm-gc, js, native/c, native/llvm, irrelevant)

```moonbit
// paste your code here
```

### Environment

<!--
  If you're using the `latest` channel of the compiler, you may also see if it
  is also present in the `dev` channel. You can also get a full stacktrace with
  this version of the toolchain.

  Install `dev` channel via:
    Unix:
      curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash -s dev

    Windows:
      $env:MOONBIT_INSTALL_VERSION="dev"
      Set-ExecutionPolicy RemoteSigned -Scope CurrentUser; irm https://cli.moonbitlang.com/install/powershell.ps1 | iex
-->

- OS: (Windows / Linux / macOS)
- OS distribution and/or version: (e.g. Ubuntu 22, Windows 10)
- CPU Architecture: (x86_64 / arm64)

<!-- Run `moon version --all` -->

```
<versions>
```

### Error output

```
<output>
```
