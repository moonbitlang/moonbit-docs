///|
#module("./local.js")
extern "js" fn value() -> Int = "value"

///|
test {
  ignore(value)
}
