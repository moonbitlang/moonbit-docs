enum Err {
  IntErr(Int)
}

fn square(x: Int) -> Int {
  x * x
}

fn main {
  IntErr!(1) |> ignore() // Error: The attribute `!` cannot be used on constructors.
  IntErr?(2) |> ignore() // Error: The attribute `?` cannot be used on constructors.
  IntErr!!(3) |> ignore() // Error: The attribute `!!` cannot be used on constructors.
  square!(1) |> ignore() // Error: The attribute `!` cannot be used on application that does not raise errors
  square?(2) |> ignore() // Error: The attribute `?` cannot be used on application that does not raise errors
}