priv type JsArray

fn JsArray::new() -> JsArray = "array" "new"

fn push(self : JsArray, charCode : Int) = "array" "push"

pub type JsString

fn JsString::from_char_code(charCode : JsArray) -> JsString = "string" "fromCharCode"

fn iter(self : JsString, f : (Int) -> Unit) -> Unit = "string" "iter"

pub fn JsString::from_string(str : String) -> JsString {
  str.iter().fold(
    fn(array : JsArray, char : Char) {
      array.push(char.to_int())
      array
    },
    JsArray::new(),
  )
  |> JsString::from_char_code
}

pub fn JsString::to_string(str : JsString) -> String {
  let buffer = Buffer::new()
  str.iter(fn(i : Int) { buffer.write_char(Char::from_int(i)) })
  buffer.to_string()
}
