// start trait 1
trait I {
  method_(Int) -> Int
  method_with_label(Int, label~: Int) -> Int
  //! method_with_label(Int, label?: Int) -> Int
}
// end trait 1

// start trait 2
trait MyShow {
  to_string(Self) -> String
}

struct MyType {}

impl MyShow for MyType with to_string(self) { ... }

struct MyContainer[T] {}

// trait implementation with type parameters.
// `[X : Show]` means the type parameter `X` must implement `Show`,
// this will be covered later.
impl[X : MyShow] MyShow for MyContainer[X] with to_string(self) { ... }
// end trait 2

// start trait 3
trait J {
  f(Self) -> Unit
  f_twice(Self) -> Unit
}

impl J with f_twice(self) {
  self.f()
  self.f()
}
// end trait 3

// start trait 4
trait Number {
  op_add(Self, Self) -> Self
  op_mul(Self, Self) -> Self
}
// end trait 4

// start trait 5
fn square[N : Number](x : N) -> N {
  x * x // <=> x.op_mul(x)
}
// end trait 5

// start trait 6
struct Point {
  x : Int
  y : Int
} derive(Eq, Show)

impl Number for Point with op_add(self, other) {
  { x: self.x + other.x, y: self.y + other.y }
}

impl Number for Point with op_mul(self, other) {
  { x: self.x * other.x, y: self.y * other.y }
}

test {
  assert_eq!(square(2), 4)
  assert_eq!(square(1.5), 2.25)
  assert_eq!(square(Point::{ x: 2, y: 3 }), { x: 4, y: 9 })
}
// end trait 6

// start trait 7
test {
  assert_eq!(Show::to_string(42), "42")
  assert_eq!(Compare::compare(1.0, 2.5), -1)
}
// end trait 7

// start trait 8
struct MyCustomType {}

impl Show for MyCustomType with output(self, logger) { ... }

fn f() -> Unit {
  let x = MyCustomType::{  }
  let _ = x.to_string()

}
// end trait 8

// start trait 9
struct T {
  x : Int
  y : Int
} derive(Eq, Compare, Show, Default)

test {
  let t1 = T::default()
  let t2 = T::{ x: 1, y: 1 }
  inspect!(t1, content="{x: 0, y: 0}")
  inspect!(t2, content="{x: 1, y: 1}")
  assert_not_eq!(t1, t2)
  assert_true!(t1 < t2)
}
// end trait 9

// start super trait 1
trait Position {
  pos(Self) -> (Int, Int)
}
trait Draw {
  draw(Self) -> Unit
}

trait Object : Position + Draw {}
// end super trait 1

// start trait object 1
trait Animal {
  speak(Self) -> String
}

type Duck String

fn Duck::make(name : String) -> Duck {
  Duck(name)
}

fn speak(self : Duck) -> String {
  "\{self._}: quack!"
}

type Fox String

fn Fox::make(name : String) -> Fox {
  Fox(name)
}

fn Fox::speak(_self : Fox) -> String {
  "What does the fox say?"
}

test {
  let duck1 = Duck::make("duck1")
  let duck2 = Duck::make("duck2")
  let fox1 = Fox::make("fox1")
  let animals : Array[&Animal] = [
    duck1 as &Animal,
    duck2 as &Animal,
    fox1 as &Animal,
  ]
  inspect!(
    animals.map(fn(animal) { animal.speak() }),
    content=
      #|["duck1: quack!", "duck2: quack!", "What does the fox say?"]
    ,
  )
}
// end trait object 1

// start trait object 2
trait Logger {
  write_string(Self, String) -> Unit
}

trait CanLog {
  log(Self, &Logger) -> Unit
}

fn &Logger::write_object[Obj : CanLog](self : &Logger, obj : Obj) -> Unit {
  obj.log(self)
}

// use the new method to simplify code
impl[A : CanLog, B : CanLog] CanLog for (A, B) with log(self, logger) {
  let (a, b) = self
  logger
  ..write_string("(")
  ..write_object(a)
  ..write_string(", ")
  ..write_object(b)
  .write_string(")")
}
// end trait object 2
