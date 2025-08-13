extern type JsArray
fn make_js_array() -> JsArray = "mod" "make_js_array"
fn push_js_array(array : JsArray, value : Int) -> Unit = "mod" "push_js_array"