///|
#module("./local.js")
extern "js" fn value() -> Int32 = "value"

///|
test {
  ignore(value)
}
