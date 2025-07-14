// start trait 1
pub(open) trait I {
  method_(Int) -> Int
  method_with_label(Int, label~ : Int) -> Int
  //! method_with_label(Int, label?: Int) -> Int
}
// end trait 1

// start trait 2
pub(open) trait MyShow {
  to_string(Self) -> String
}

struct MyType {}

pub impl MyShow for MyType with to_string(self) {
  ...
}

struct MyContainer[T] {}

// trait implementation with type parameters.
// `[X : Show]` means the type parameter `X` must implement `Show`,
// this will be covered later.
pub impl[X : MyShow] MyShow for MyContainer[X] with to_string(self) {
  ...
}
// end trait 2

// start trait 3
pub(open) trait J {
  f(Self) -> Unit
  f_twice(Self) -> Unit = _
}

impl J with f_twice(self) {
  self.f()
  self.f()
}
// end trait 3

// start trait 4
impl J for Int with f(self) {
  println(self)
}

impl J for String with f(self) {
  println(self)
}

impl J for String with f_twice(self) {
  println(self)
  println(self)
}

// end trait 4

// start trait 5
fn[X : Eq] contains(xs : Array[X], elem : X) -> Bool {
  for x in xs {
    if x == elem {
      return true
    }
  } else {
    false
  }
}
// end trait 5

// start trait 6
struct Point {
  x : Int
  y : Int
}

impl Eq for Point with op_equal(p1, p2) {
  p1.x == p2.x && p1.y == p2.y
}

test {
  assert_false(contains([1, 2, 3], 4))
  assert_true(contains([1.5, 2.25, 3.375], 2.25))
  assert_false(contains([{ x: 2, y: 3 }], { x: 4, y: 9 }))
}
// end trait 6

// start trait 7
test {
  assert_eq(Show::to_string(42), "42")
  assert_eq(Compare::compare(1.0, 2.5), -1)
}
// end trait 7

// start trait 8
struct MyCustomType {}

pub impl Show for MyCustomType with output(self, logger) {
  ...
}

fn f() -> Unit {
  let x = MyCustomType::{  }
  let _ = x.to_string()

}
// end trait 8

// start trait 9
struct T {
  a : Int
  b : Int
} derive(Eq, Compare, Show, Default)

test {
  let t1 = T::default()
  let t2 = T::{ a: 1, b: 1 }
  inspect(t1, content="{a: 0, b: 0}")
  inspect(t2, content="{a: 1, b: 1}")
  assert_not_eq(t1, t2)
  assert_true(t1 < t2)
}
// end trait 9

// start super trait 1
pub(open) trait Position {
  pos(Self) -> (Int, Int)
}

pub(open) trait Draw {
  draw(Self, Int, Int) -> Unit
}

pub(open) trait Object: Position + Draw {}
// end super trait 1

// start super trait 2
impl Position for Point with pos(self) {
  (self.x, self.y)
}

impl Draw for Point with draw(self, x, y) {
  ()
}

pub fn[O : Object] draw_object(obj : O) -> Unit {
  let (x, y) = obj.pos()
  obj.draw(x, y)
}

test {
  let p = Point::{ x: 1, y: 2 }
  draw_object(p)
}
// end super trait 2

// start trait object 1
pub(open) trait Animal {
  speak(Self) -> String
}

type Duck String

fn Duck::make(name : String) -> Duck {
  Duck(name)
}

impl Animal for Duck with speak(self) {
  "\{self.inner()}: quack!"
}

type Fox String

fn Fox::make(name : String) -> Fox {
  Fox(name)
}

impl Animal for Fox with speak(_self) {
  "What does the fox say?"
}

test {
  let duck1 = Duck::make("duck1")
  let duck2 = Duck::make("duck2")
  let fox1 = Fox::make("fox1")
  let animals : Array[&Animal] = [duck1, duck2, fox1]
  inspect(
    animals.map(fn(animal) { animal.speak() }),
    content=(
      #|["duck1: quack!", "duck2: quack!", "What does the fox say?"]
    ),
  )
}
// end trait object 1

// start trait object 2
pub(open) trait Logger {
  write_string(Self, String) -> Unit
}

pub(open) trait CanLog {
  log(Self, &Logger) -> Unit
}

fn[Obj : CanLog] &Logger::write_object(self : &Logger, obj : Obj) -> Unit {
  obj.log(self)
}

// use the new method to simplify code
pub impl[A : CanLog, B : CanLog] CanLog for (A, B) with log(self, logger) {
  let (a, b) = self
  logger
  ..write_string("(")
  ..write_object(a)
  ..write_string(", ")
  ..write_object(b)
  ..write_string(")")
}
// end trait object 2

// start trait alias
// CanCompare is an alias of Compare
traitalias @builtin.Compare as CanCompare
// end trait alias
