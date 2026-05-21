# Configuration attribute

The `#cfg` attribute is used to perform conditional compilation. Examples are:

<!-- MANUAL CHECK -->
```moonbit
#cfg(true)
fn cfg_true() -> Unit {
  ()
}

#cfg(false)
fn cfg_false() -> Unit {
  ()
}

#cfg(target="wasm")
fn cfg_wasm() -> Unit {
  ()
}

#cfg(not(target="wasm"))
fn cfg_not_wasm() -> Unit {
  ()
}

#cfg(all(target="wasm", true))
fn cfg_all() -> Unit {
  ()
}

#cfg(any(target="wasm", target="native"))
fn cfg_any() -> Unit {
  ()
}
```
