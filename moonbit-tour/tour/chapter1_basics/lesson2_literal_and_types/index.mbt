///|
fn main {
  // Different representations of integers
  let dec : Int = 1000000 
  let dec2 : Int = 1_000_000 
  let hex : Int = 0xFFFF 
  let oct = 0o777 
  let bin = 0b1001 
  println("numbers:")
  println(dec) 
  println(dec2)
  println(hex) 
  println(oct) 
  println(bin) 

  // Basic arithmetic operations
  println("arithmetic:")
  println(1 + 2) 
  println(1 - 2) 
  println(1 * 2) 
  println(5 / 2) 
  println(10 % 3) 

  // Floating-point types
  let num1 : Double = 3.14 // Double-precision floating point
  let num2 : Float = 3.14 // Single-precision floating point
  println("floating point:")
  println(num1) 
  println(num2) 
}
