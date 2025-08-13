// unrecognized attribute
#unrecognized
fn f() -> Unit {}

// `#deprecated` can accept at most one message
#deprecated("multiple", "message")
fn g() -> Unit {}
