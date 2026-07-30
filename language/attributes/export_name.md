# Export Name Attribute

The `#export_name` attribute assigns a stable exported symbol name to a public
function in a package declared with `pkgtype(kind: "foreign_library")`. The
name is used in generated Wasm, JavaScript, or C output:

```moonbit
#export_name("add")
pub fn add_one(value : Int) -> Int {
  value + 1
}
```

MoonBit currently requires the exported name to be unique within the package
and to be a valid C symbol identifier, regardless of the selected backend.

#### WARNING
Known compiler issue: `#export_name` currently applies its C-symbol-identifier
restriction to every backend. WebAssembly export names are UTF-8 strings and
are not limited to C identifiers.

The attribute cannot be used on generic functions, functions with optional
arguments, methods, or declarations without a body.

Prefer `#export_name` over backend-specific `exports` link configuration for
new exports. It keeps the exported name next to the function and applies to
every backend that supports foreign-library output. Use `exports` when the
export set or names must differ by backend, or when the source cannot be
annotated.

Export declarations are scoped to the package that produces the artifact. An
attribute in a dependency applies when that dependency is built as its own
artifact, but it does not add a symbol to a downstream package's artifact. To
expose dependency functionality, define and export a wrapper in the exporting
package.

#### NOTE
The native backend does not currently support exporting a `foreign_library`
package as a library artifact. Use Wasm or JavaScript if you need an exported
library.

See [Export Functions](../ffi.md#export-functions) for backend-specific
alternatives.
