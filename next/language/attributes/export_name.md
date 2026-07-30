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

The exported name must be a unique valid C symbol identifier. The attribute
cannot be used on generic functions, functions with optional arguments,
methods, or declarations without a body. It exports only functions defined in
the current package; dependency symbols are not re-exported.

```{note}
The native backend does not currently support exporting a `foreign_library`
package as a library artifact. Use Wasm or JavaScript if you need an exported
library.
```

See [Export Functions](/language/ffi.md#export-functions) for package
configuration and backend-specific alternatives.
