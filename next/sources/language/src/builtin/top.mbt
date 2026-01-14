let boolean : Unit = {
  // start boolean 1
  let a = true
  let b = false
  let c = a && b
  let d = a || b
  let e = !a
  let f = not(a)
  // end boolean 1

}

let number : Unit = {
  // start number 1
  let a = 1234
  let b : Int = 1_000_000 + a
  let unsigned_num       : UInt   = 4_294_967_295U
  let large_num          : Int64  = 9_223_372_036_854_775_807L
  let unsigned_large_num : UInt64 = 18_446_744_073_709_551_615UL
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
  let another_hex = 0xA_B_C
  // end number 4

  // start number 6
  let double = 3.14 // Double
  let float : Float = 3.14
  let float2 = (3.14 : Float)
  // end number 6

  // start number 7
  let hex_double = 0x1.2P3 // (1.0 + 2 / 16) * 2^(+3) == 9
  // end number 7

  // start number 5
  let int : Int = 42
  let uint : UInt = 42
  let int64 : Int64 = 42
  let double : Double = 42
  let float : Float = 42
  let bigint : BigInt = 42
  // end number 5

}

test "string 1" (t : @test.Test) {
  let println = fn(show) { t.writeln(show) }
  // start string 1
  let a = "兔rabbit"
  println(a.code_unit_at(0).to_char())
  println(a.code_unit_at(1).to_char())
  let b =
    #| Hello
    #| MoonBit\n
    #|
  println(b)
  // end string 1
  t.snapshot(filename="string_1")
}

let string : Unit = {
  // start string 3
  let x = 42
  println("The answer is \{x}")
  // end string 3
}

test "string 4" (t : @test.Test) {
  let println = fn(show) { t.writeln(show) }
  // start string 4
  let lang = "MoonBit"
  let raw =
    #| Hello
    #| ---
    #| \{lang}
    #| ---
  let interp =
    $| Hello
    $| ---
    $| \{lang}
    $| ---
  println(raw)
  println(interp)
  // end string 4
  t.snapshot(filename="string_4")
}

// start string 5
test {
  let c : Char = '中'
  let s : String = [c, '文']
  inspect(s, content="中文")
}
// end string 5

let char : Unit = {
  // start char 1
  let a : Char = 'A'
  let b = '兔'
  let zero = '\u{30}'
  let zero = '\u0030'
  // end char 1

}

// start char 2
test {
  let s : String = "hello"
  let b : UInt16 = s.code_unit_at(0) // 'h'
  assert_eq(b, 'h') // 'h' is overloaded to UInt16
  let c : Int = '兔'
  // Not ok : exceed range
  // let d : UInt16 = '𠮷'
}
// end char 2

test "byte 1" (t : @test.Test) {
  let println = fn(show) { t.writeln(show) }
  // start byte 1
  let b1 : Byte = b'a'
  println(b1.to_int())
  let b2 = b'\xff'
  println(b2.to_int())
  // end byte 1
  t.snapshot(filename="byte_1")
}

// start byte 2
test {
  let b1 : Bytes = b"abcd"
  let b2 = b"\x61\x62\x63\x64"
  assert_eq(b1, b2)
}
// end byte 2

// start bytes 1
test {
  let b : Byte = '\xFF'
  let bs : Bytes = [b, '\x01']
  inspect(
    bs,
    content=(
      #|b"\xff\x01"
    ),
  )
}
// end bytes 1

// start buffer 1
test "buffer 1" {
  let buf : @buffer.Buffer = @buffer.new()
  buf.write_bytes(b"Hello")
  buf.write_byte(b'!')
  assert_eq(buf.contents(), b"Hello!")
}
// end buffer 1

test "tuple 1" (t : @test.Test) {
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
  t.snapshot(filename="tuple_1")
}

// start tuple 2
test {
  let t = (1, 2)
  let (x1, y1) = t
  let x2 = t.0
  let y2 = t.1
  assert_eq(x1, x2)
  assert_eq(y1, y2)
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
  assert_eq(b, 8)
}
// end array 2

// start array 3
let fixed_array_1 : FixedArray[Int] = [1, 2, 3]

let fixed_array_2 = ([1, 2, 3] : FixedArray[Int])

let array_3 : Array[Int] = [1, 2, 3] // Array[Int]
// end array 3

// start array pitfall
test {
  let two_dimension_array = FixedArray::make(10, FixedArray::make(10, 0))
  two_dimension_array[0][5] = 10
  assert_eq(two_dimension_array[5][5], 10)
}
// end array pitfall

// start array pitfall solution
test {
  let two_dimension_array = FixedArray::makei(10, fn(_i) {
    FixedArray::make(10, 0)
  })
  two_dimension_array[0][5] = 10
  assert_eq(two_dimension_array[5][5], 0)
}
// end array pitfall solution

// start map 1
let map : Map[String, Int] = { "x": 1, "y": 2, "z": 3 }
// end map 1

// start json 1
let moon_pkg_json_example : Json = {
  "import": ["moonbitlang/core/builtin", "moonbitlang/core/coverage"],
  "test-import": ["moonbitlang/core/random"],
}
// end json 1

// start ref 1
let a : Ref[Int] = { val: 100 }

test {
  a.val = 200
  assert_eq(a.val, 200)
  a.val += 1
  assert_eq(a.val, 201)
}
// end ref 1

// start option result 1
test {
  let a : Int? = None
  let b : Option[Int] = Some(42)
  let c : Result[Int, String] = Ok(42)
  let d : Result[Int, String] = Err("error")
  match a {
    Some(_) => assert_true(false)
    None => assert_true(true)
  }
  match d {
    Ok(_) => assert_true(false)
    Err(_) => assert_true(true)
  }
}
// end option result 1

// start overloaded literal 1
fn expect_double(x : Double) -> Unit {

}

test {
  let x = 1 // type of x is Int
  let y : Double = 1
  expect_double(1)
}
// end overloaded literal 1
