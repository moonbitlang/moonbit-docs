# MoonBit VSCode Plugin

MoonBit provides a plugin for Visual Studio Code, available in the
[Visual Studio MarketPlace](https://marketplace.visualstudio.com/items?itemName=moonbit.moonbit-lang)
and [Open VSX Registry](https://open-vsx.org/extension/moonbit/moonbit-lang).

## Commands

The plugin provides several commands, available through
[command palettes](https://code.visualstudio.com/docs/getstarted/userinterface#_command-palette)

- Select backend: It allows you to switch between several backends
- Restart MoonBit language server: It allows you to restart the language server,
  in case it's unresponsive or has some stale state.
- Install MoonBit toolchain: Manually triggers the installation process. The
  extension will check if the installed MoonBit toolchain matches the
  extension's version.
- Get lsp's compiler version: It will display the MoonBit compiler version used
  by the extension.
- Toggle multiline string: It can help switching the chosen text between a plain
  text and the MoonBit's
  [multiline string syntax](/language/fundamentals.md#string)

## Actions

The plugin also provides several actions, available through
[quick fix](https://code.visualstudio.com/docs/editing/refactoring#_code-actions-quick-fixes-and-refactorings)

- Add missing arms: It allows you to fill up the branches of a `match`
  expression when encountering [Error 0011](/language/error_codes/E0011.md)

## Code Lens

The plugin provides code lens for each top-level code block, especially test
blocks.

The provided functionalities are:

- Format: format the code block
- Test / Bench: test or bench the test block
- Debug (JavaScript backend only): test the test block with debugger
- Update: update the [snapshot tests](/language/tests.md#snapshot-tests) in the
  code block
- Trace: turn on/off the tracing of the test block where each assignment will
  have the value rendered next to it
