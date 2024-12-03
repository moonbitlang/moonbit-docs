let boolean : Unit = {
  // start boolean 1
  let a = true
  let b = false
  let c = a && b
  let d = a || b
  let e = not(a)
  // end boolean 1

}

let number : Unit = {
  // start number 1
  let a = 1234
  let b = 1_000_000 + a
  // UInt : 0_U
  let unsigned_num = 4_294_967_295U
  // Int64 : 0_L
  let large_num = 9_223_372_036_854_775_807L
  // UInt64 : 0_UL
  let unsigned_large_num = 18_446_744_073_709_551_615UL
  // end number 1

  // start number 2
  let bin = 0b110010
  let another_bin = 0B110010
  // end number 2

  // start number 3
  let octal = 0o1234
  let another_octal = 0O1234
  // end number 3

  // start number 4
  let hex = 0XA
  let another_hex = 0xA
  // end number 4

  // start number 5
  let int : Int = 42
  let uint : UInt = 42
  let int64 : Int64 = 42
  let double : Double = 42
  let float : Float = 42
  let bigint : BigInt = 42
  // end number 5

}

test "string 1" (t : @test.T) {
  let println = fn(show) { t.writeln(show) }
  // start string 1
  let a = "兔rabbit"
  println(a[0])
  println(a[1])
  let b =
    #| Hello
    #| MoonBit\n
    #|
  println(b)
  // end string 1
  t.snapshot!(filename="string_1")
}

let string : Unit = {
  // start string 3
  let x = 42
  println("The answer is \{x}")
  // end string 3
}

test "string 4" (t : @test.T) {
  let println = fn(show) { t.writeln(show) }
  // start string 4
  let lang = "MoonBit"
  let str =
    #| Hello
    #| ---
    $| \{lang}\n
    #| ---
  println(str)
  // end string 4
  t.snapshot!(filename="string_4")
}

let char : Unit = {
  // start char 1
  let a : Char = 'A'
  let b = '\x41'
  let c = '兔'
  let zero = '\u{30}'
  let zero = '\u0030'
  // end char 1

}

test "byte 1" (t : @test.T) {
  let println = fn(show) { t.writeln(show) }
  // start byte 1
  let b1 : Byte = b'a'
  println(b1.to_int())
  let b2 = b'\xff'
  println(b2.to_int())
  // end byte 1
  t.snapshot!(filename="byte_1")
}

// start byte 2
test {
  let b1 : Bytes = b"abcd"
  let b2 = b"\x61\x62\x63\x64"
  assert_eq!(b1, b2)
}
// end byte 2

test "tuple 1" (t : @test.T) {
  let println = fn(show) { t.writeln(show) }
  // start tuple 1
  fn pack(
    a : Bool,
    b : Int,
    c : String,
    d : Double
  ) -> (Bool, Int, String, Double) {
    (a, b, c, d)
  }

  let quad = pack(false, 100, "text", 3.14)
  let (bool_val, int_val, str, float_val) = quad
  println("\{bool_val} \{int_val} \{str} \{float_val}")
  // end tuple 1
  t.snapshot!(filename="tuple_1")
}

// start tuple 2
test {
  let t = (1, 2)
  let (x1, y1) = t
  let x2 = t.0
  let y2 = t.1
  assert_eq!(x1, x2)
  assert_eq!(y1, y2)
}
// end tuple 2

let array : Unit = {
  // start array 1
  let numbers = [1, 2, 3, 4]
  // end array 1

}

// start array 2
test {
  let numbers = [1, 2, 3, 4]
  let a = numbers[2]
  numbers[3] = 5
  let b = a + numbers[3]
  assert_eq!(b, 8)
}
// end array 2

// start map 1
let map : Map[String, Int] = { "x": 1, "y": 2, "z": 3 }
// end map 1

// start json 1
let moon_pkg_json_example : Json = {
  "import": ["moonbitlang/core/builtin", "moonbitlang/core/coverage"],
  "test-import": ["moonbitlang/core/random"],
}
// end json 1
