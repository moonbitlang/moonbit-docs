///|
#module("local")
extern "js" fn value() -> Int = "value"

///|
test {
  ignore(value)
}
