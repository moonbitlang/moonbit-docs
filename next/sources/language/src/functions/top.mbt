// start expression
fn foo() -> Int {
  let x = 1
  x + 1
}

fn bar() -> Int {
  let x = 1
  //! x + 1
  x + 2
}
// end expression

// start top-level functions
fn add3(x : Int, y : Int, z : Int) -> Int {
  x + y + z
}
// end top-level functions

// start function application 1
test {
  let add3 = fn(x, y, z) { x + y + z }
  assert_eq!(add3(1, 2, 7), 10)
}
// end function application 1

// start function application 2
test {
  let f = fn(x) { x + 1 }
  let g = fn(x) { x + 2 }
  let w = (if true { f } else { g })(3)
  assert_eq!(w, 4)
}
// end function application 2

// start partial application 1
fn add(x : Int, y : Int) -> Int {
  x + y
}

test {
  let add10 : (Int) -> Int = add(10, _)
  println(add10(5)) // prints 15
  println(add10(10)) // prints 20
}
// end partial application 1

// start local functions 1
fn local_1() -> Int {
  fn inc(x) { // named as `inc`
    x + 1
  }
  // anonymous, instantly applied to integer literal 6
  (fn(x) { x + inc(2) })(6)
}

test {
  assert_eq!(local_1(), 9)
}
// end local functions 1

// start local functions 2
let global_y = 3

fn local_2(x : Int) -> (Int, Int) {
  fn inc() {
    x + 1
  }

  fn four() {
    global_y + 1
  }

  (inc(), four())
}

test {
  assert_eq!(local_2(3), (4, 4))
}
// end local functions 2

// start local functions 3
let extract : (Int?, Int) -> Int = fn {
  Some(x), _ => x
  None, default => default
}
// end local functions 3

// start labelled arguments 1
fn labelled_1(arg1~ : Int, arg2~ : Int) -> Int {
  arg1 + arg2
}
// end labelled arguments 1

// start labelled arguments 2
test {
  let arg1 = 1
  assert_eq!(labelled_1(arg2=2, arg1~), 3)
}
// end labelled arguments 2

// start optional arguments 1
fn optional(opt~ : Int = 42) -> Int {
  opt
}

test {
  assert_eq!(optional(), 42)
  assert_eq!(optional(opt=0), 0)
}
// end optional arguments 1

// start optional arguments 2
fn incr(counter~ : Ref[Int] = { val: 0 }) -> Ref[Int] {
  counter.val = counter.val + 1
  counter
}

test {
  inspect!(incr(), content="{val: 1}")
  inspect!(incr(), content="{val: 1}")
  let counter : Ref[Int] = { val: 0 }
  inspect!(incr(counter~), content="{val: 1}")
  inspect!(incr(counter~), content="{val: 2}")
}
// end optional arguments 2

// start optional arguments 3
let default_counter : Ref[Int] = { val: 0 }

fn incr_2(counter~ : Ref[Int] = default_counter) -> Int {
  counter.val = counter.val + 1
  counter.val
}

test {
  assert_eq!(incr_2(), 1)
  assert_eq!(incr_2(), 2)
}
// end optional arguments 3

// start optional arguments 4
fn sub_array[X](
  xs : Array[X],
  offset~ : Int,
  len~ : Int = xs.length() - offset
) -> Array[X] {
  xs[offset:offset + len].iter().to_array()
}

test {
  assert_eq!(sub_array([1, 2, 3], offset=1), [2, 3])
  assert_eq!(sub_array([1, 2, 3], offset=1, len=1), [2])
}
// end optional arguments 4

struct Image {
  width : Int
  height : Int
}

// start optional arguments 5
fn ugly_constructor(width~ : Int? = None, height~ : Int? = None) -> Image {
  ...
}

let img : Image = ugly_constructor(width=Some(1920), height=Some(1080))
// end optional arguments 5

// start optional arguments 6
fn nice_constructor(width? : Int, height? : Int) -> Image {
  ...
}

let img2 : Image = nice_constructor(width=1920, height=1080)
// end optional arguments 6

// start optional arguments 7
fn image(width? : Int, height? : Int) -> Image {
  ...
}

fn fixed_width_image(height? : Int) -> Image {
  image(width=1920, height?)
}
// end optional arguments 7

// start autofill arguments
fn f(_x : Int, loc~ : SourceLoc = _, args_loc~ : ArgsLoc = _) -> String {
  $|loc of whole function call: \{loc}
  $|loc of arguments: \{args_loc}
  // loc of whole function call: <filename>:7:3-7:10
  // loc of arguments: [Some(<filename>:7:5-7:6), Some(<filename>:7:8-7:9), None, None]
}
// end autofill arguments

// start function alias
// `hashmap_new` will become an alias of `@hashmap.new`
fnalias @hashmap.new as hashmap_new
fnalias @hashmap.new // same as `fnalias @hashmap.new as new`
fnalias new as new_2 // local alias is also allowed

// creating multiple alias in one package
fnalias @hashmap.(
  iter,
  each as hashmap_each
)
fnalias @list.T::fold // same as `fnalias @list.T::fold as fold`
fnalias @list.T::fold as list_fold // list_fold is an alias of `@list.T::fold`

// creating multiple alias in typename
fnalias @list.T::(fold as foldl, rev_fold as foldr) 
// end function alias
