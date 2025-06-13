// start struct 1
struct User {
  id : Int
  name : String
  mut email : String
}
// end struct 1

test "struct 1" (t : @test.T) {
  let println = fn(show) { t.writeln(show) }
  // start struct 2
  let u = User::{ id: 0, name: "John Doe", email: "john@doe.com" }
  u.email = "john@doe.name"
  //! u.id = 10
  println(u.id)
  println(u.name)
  println(u.email)
  // end struct 2
  t.snapshot(filename="struct_1")
}

let struct_3 : Unit = {
  // start struct 3
  let name = "john"
  let email = "john@doe.com"
  let u = User::{ id: 0, name, email }
  // end struct 3
  // start struct 5
  let u2 = { id: 0, name, email }
  // end struct 5

}

test "struct 4" (t : @test.T) {
  let println = fn(show) { t.writeln(show) }
  // start struct 4
  let user = { id: 0, name: "John Doe", email: "john@doe.com" }
  let updated_user = { ..user, email: "john@doe.name" }
  println(
    $|{ id: \{user.id}, name: \{user.name}, email: \{user.email} }
    $|{ id: \{updated_user.id}, name: \{updated_user.name}, email: \{updated_user.email} }
    ,
  )
  // end struct 4
  t.snapshot(filename="struct_4")
}

// start enum 1
/// An enum type that represents the ordering relation between two values,
/// with three cases "Smaller", "Greater" and "Equal"
enum Relation {
  Smaller
  Greater
  Equal
}
// end enum 1

test "enum 3" (t : @test.T) {
  let println = fn(show) { t.writeln(show) }
  // start enum 2
  /// compare the ordering relation between two integers
  fn compare_int(x : Int, y : Int) -> Relation {
    if x < y {
      // when creating an enum, if the target type is known, 
      // you can write the constructor name directly
      Smaller
    } else if x > y {
      // but when the target type is not known,
      // you can always use `TypeName::Constructor` to create an enum unambiguously
      Relation::Greater
    } else {
      Equal
    }
  }

  /// output a value of type `Relation`
  fn print_relation(r : Relation) -> Unit {
    // use pattern matching to decide which case `r` belongs to
    match r {
      // during pattern matching, if the type is known, 
      // writing the name of constructor is sufficient
      Smaller => println("smaller!")
      // but you can use the `TypeName::Constructor` syntax 
      // for pattern matching as well
      Relation::Greater => println("greater!")
      Equal => println("equal!")
    }
  }
  // end enum 2
  // start enum 3
  print_relation(compare_int(0, 1))
  print_relation(compare_int(1, 1))
  print_relation(compare_int(2, 1))
  // end enum 3
  t.snapshot(filename="enum_3")
}

// start enum 4
enum List {
  Nil
  // constructor `Cons` carries additional payload: the first element of the list,
  // and the remaining parts of the list
  Cons(Int, List)
}
// end enum 4

test "enum 6" (t : @test.T) {
  let println = fn(show) { t.writeln(show) }
  // start enum 5
  // In addition to binding payload to variables,
  // you can also continue matching payload data inside constructors.
  // Here's a function that decides if a list contains only one element
  fn is_singleton(l : List) -> Bool {
    match l {
      // This branch only matches values of shape `Cons(_, Nil)`, 
      // i.e. lists of length 1
      Cons(_, Nil) => true
      // Use `_` to match everything else
      _ => false
    }
  }

  fn print_list(l : List) -> Unit {
    // when pattern-matching an enum with payload,
    // in additional to deciding which case a value belongs to
    // you can extract the payload data inside that case
    match l {
      Nil => println("nil")
      // Here `x` and `xs` are defining new variables 
      // instead of referring to existing variables,
      // if `l` is a `Cons`, then the payload of `Cons` 
      // (the first element and the rest of the list)
      // will be bind to `x` and `xs
      Cons(x, xs) => {
        println("\{x},")
        print_list(xs)
      }
    }
  }
  // end enum 5
  // start enum 6
  // when creating values using `Cons`, the payload of by `Cons` must be provided
  let l : List = Cons(1, Cons(2, Nil))
  println(is_singleton(l))
  print_list(l)
  // end enum 6
  t.snapshot(filename="enum_6")
}

// start enum 7
enum E {
  // `x` and `y` are labelled argument
  C(x~ : Int, y~ : Int)
}
// end enum 7

test "enum 9" (t : @test.T) {
  let println = fn(show) { t.writeln(show) }
  // start enum 8
  // pattern matching constructor with labelled arguments
  fn f(e : E) -> Unit {
    match e {
      // `label=pattern`
      C(x=0, y=0) => println("0!")
      // `x~` is an abbreviation for `x=x`
      // Unmatched labelled arguments can be omitted via `..`
      C(x~, ..) => println(x)
    }
  }
  // end enum 8
  // start enum 9
  f(C(x=0, y=0))
  let x = 0
  f(C(x~, y=1)) // <=> C(x=x, y=1)
  // end enum 9
  t.snapshot(filename="enum_9")
}

// start enum 10
enum Object {
  Point(x~ : Double, y~ : Double)
  Circle(x~ : Double, y~ : Double, radius~ : Double)
}

suberror NotImplementedError derive(Show)

fn distance_with(
  self : Object,
  other : Object
) -> Double raise NotImplementedError {
  match (self, other) {
    // For variables defined via `Point(..) as p`,
    // the compiler knows it must be of constructor `Point`,
    // so you can access fields of `Point` directly via `p.x`, `p.y` etc.
    (Point(_) as p1, Point(_) as p2) => {
      let dx = p2.x - p1.x
      let dy = p2.y - p1.y
      (dx * dx + dy * dy).sqrt()
    }
    (Point(_), Circle(_)) | (Circle(_), Point(_)) | (Circle(_), Circle(_)) =>
      raise NotImplementedError
  }
}
// end enum 10

test "enum 11" (t : @test.T) {
  let println = fn(show) { t.writeln(show) }
  // start enum 11
  let p1 : Object = Point(x=0, y=0)
  let p2 : Object = Point(x=3, y=4)
  let c1 : Object = Circle(x=0, y=0, radius=2)
  try {
    println(p1.distance_with(p2))
    println(p1.distance_with(c1))
  } catch {
    e => println(e)
  }
  // end enum 11
  t.snapshot(filename="enum_11")
}

// start enum 12
// A set implemented using mutable binary search tree.
struct Set[X] {
  mut root : Tree[X]
}

fn[X : Compare] Set::insert(self : Set[X], x : X) -> Unit {
  self.root = self.root.insert(x, parent=Nil)
}

// A mutable binary search tree with parent pointer
enum Tree[X] {
  Nil
  // only labelled arguments can be mutable
  Node(
    mut value~ : X,
    mut left~ : Tree[X],
    mut right~ : Tree[X],
    mut parent~ : Tree[X]
  )
}

// In-place insert a new element to a binary search tree.
// Return the new tree root
fn[X : Compare] Tree::insert(
  self : Tree[X],
  x : X,
  parent~ : Tree[X]
) -> Tree[X] {
  match self {
    Nil => Node(value=x, left=Nil, right=Nil, parent~)
    Node(_) as node => {
      let order = x.compare(node.value)
      if order == 0 {
        // mutate the field of a constructor
        node.value = x
      } else if order < 0 {
        // cycle between `node` and `node.left` created here
        node.left = node.left.insert(x, parent=node)
      } else {
        node.right = node.right.insert(x, parent=node)
      }
      // The tree is non-empty, so the new root is just the original tree
      node
    }
  }
}
// end enum 12

// start newtype 1
// `UserId` is a fresh new type different from `Int`, 
// and you can define new methods for `UserId`, etc.
// But at the same time, the internal representation of `UserId` 
// is exactly the same as `Int`
type UserId Int

type UserName String
// end newtype 1

test "newtype 2" (t : @test.T) {
  let println = fn(show) { t.writeln(show) }
  // start newtype 2
  let id : UserId = UserId(1)
  let name : UserName = UserName("John Doe")
  let UserId(uid) = id // uid : Int
  let UserName(uname) = name // uname: String
  println(uid)
  println(uname)
  // end newtype 2
  t.snapshot(filename="newtype_2")
}

test "newtype 3" (t : @test.T) {
  let println = fn(show) { t.writeln(show) }
  // start newtype 3
  let id : UserId = UserId(1)
  let uid : Int = id._
  println(uid)
  // end newtype 3
  t.snapshot(filename="newtype_3")
}

// start typealias 1
pub typealias Int as Index

// type alias are private by default
typealias @list.T as Lst
// end typealias 1

// start local-type 1
fn[T : Show] toplevel(x : T) -> Unit {
  enum LocalEnum {
    A(T)
    B(Int)
  } derive(Show)
  struct LocalStruct {
    a : (String, T)
  } derive(Show)
  type LocalNewtype T derive(Show)
  ...
}
// end local-type 1
