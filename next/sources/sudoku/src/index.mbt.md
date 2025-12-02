# Sudoku Solver

Sudoku is a logic-based puzzle game that originated in 1979. It was well-suited for print media like newspapers, and even in the digital age, many Sudoku game programs are available for computers and smartphones. Despite the variety of entertainment options today, Sudoku enthusiasts continue to form active communities (online forum such as: [enjoysudoku](http://forum.enjoysudoku.com/)). This article will demonstrate how to write a suitable program to solve Sudoku using MoonBit.
![sudoku example](/imgs/sudoku.jpg)

## Squares, Units, and Peers

The most common form of Sudoku is played on a 9x9 grid. We label the rows from top to bottom as A-I, and the columns from left to right as 1-9. This gives each square in the grid a coordinate, for example, the square containing the number 0 in the grid below has the coordinate C3.

```
  1 2 3 4 5 6 7 8 9
A . . . . . . . . .
B . . . . . . . . .
C . . 0 . . . . . .
D . . . . . . . . .
E . . . . . . . . .
F . . . . . . . . .
G . . . . . . . . .
H . . . . . . . . .
I . . . . . . . . .
```

This 9x9 grid has a total of 9 units, and each unit contains squares that must have unique digits from 1 to 9. However, in the initial state of the game, most squares do not contain any digits.

```
 4  1  7 | 3  6  9 | 8  2  5
 6  3  2 | 1  5  8 | 9  4  7
 9  5  8 | 7  2  4 | 3  1  6
---------+---------+---------
 8  2  5 | 4  3  7 | 1  6  9
 7  9  1 | 5  8  6 | 4  3  2
 3  4  6 | 9  1  2 | 7  5  8
---------+---------+---------
 2  8  9 | 6  4  3 | 5  7  1
 5  7  3 | 2  9  1 | 6  8  4
 1  6  4 | 8  7  5 | 2  9  3
```

Beyond the units, another important concept is peers. A square's peers include other squares in the same row, column, and unit. For example, the peers of C2 include these squares:

```

    A2   |         |
    B2   |         |
    C2   |         |
---------+---------+---------
    D2   |         |
    E2   |         |
    F2   |         |
---------+---------+---------
    G2   |         |
    H2   |         |
    I2   |         |

         |         |
         |         |
 C1 C2 C3| C4 C5 C6| C7 C8 C9
---------+---------+---------
         |         |
         |         |
         |         |
---------+---------+---------
         |         |
         |         |
         |         |

 A1 A2 A3|         |
 B1 B2 B3|         |
 C1 C2 C3|         |
---------+---------+---------
         |         |
         |         |
         |         |
---------+---------+---------
         |         |
         |         |
         |         |
```

No two squares that are peers can contain the same digit.

We need a data type, `Grid[T]`, to store the 81 squares and the information associated with each square. This can be implemented using a hashtable, but using an array would be more compact and simple. First, we write a function to convert coordinates A1-I9 to indices 0-80:

```moonbit
// A1 => 0, A2 => 1
fn square_to_int(s : String) -> Int {
  if s[0] is ('A'..='I') && s[1] is ('1'..='9') {
    let row = s[0] - 'A'.to_int() // 'A' <=> 0
    let col = s[1] - '1'.to_int() // '1' <=> 0
    return row * 9 + col
  } else {
    abort("Grid_to_int(): \{s} is not a Grid")
  }
}

///
test {
  inspect(square_to_int("A1"), content="0")
  inspect(square_to_int("A7"), content="6")
  inspect(square_to_int("I9"), content="80")
}
```

Then we wrap the array and provide operations for creating, accessing, assigning values to specific coordinates, and copying `Grid[T]`. By overloading the op_get and op_set methods, we can write convenient code like `table["A2"]` and `table["C3"] = ...`.

```moonbit
///|
struct Grid[T](FixedArray[T])

///|
fn[T] Grid::new(val : T) -> Grid[T] {
  FixedArray::make(81, val)
}

///|
fn[T] Grid::copy(self : Grid[T]) -> Grid[T] {
  if self.0.length() == 0 {
    return []
  }
  let arr = FixedArray::make(81, self.0[0])
  let mut i = 0
  while i < 81 {
    arr[i] = self.0[i]
    i = i + 1
  }
  return arr
}

///|
fn[T] Grid::op_get(self : Grid[T], square : String) -> T {
  let i = square_to_int(square)
  self.0[i]
}

///|
fn[T] Grid::op_set(self : Grid[T], square : String, x : T) -> Unit {
  let i = square_to_int(square)
  self.0[i] = x
}
```

Next, we prepare some constants:

```moonbit skip
let rows = "ABCDEFGHI"

let cols = "123456789"

type Squares =  @immut/sorted_set.SortedSet[String] 

// squares contains the coordinates of each square
let squares : Squares = ......

// units[coord] contains the other squares in the unit of the square at coord
// for example：units["A3"] => [C3, C2, C1, B3, B2, B1, A2, A1]
let units : Grid[Squares] = ......

// peers[coord] contains all the peers of the square at coord
// for example：peers["A3"] => [A1, A2, A4, A5, A6, A7, A8, A9, B1, B2, B3, C1, C2, C3, D3, E3, F3, G3, H3, I3]
let peers : Grid[Squares] = ......
```

The process of constructing the units and peers tables is tedious, so it will not be detailed here.

## Preprocessing the Grid

We use a string to represent the initial Sudoku grid. Various formats are acceptable; both `.` and `0` represent empty squares, and other characters like spaces and newlines are ignored.

```
#|400000805
#|030000000
#|000700000
#|020000060
#|000080400
#|000010000
#|000603070
#|500200000
#|104000000

#|4 . .   . . .   8 . 5
#|. 3 .   . . .   . . .
#|. . .   7 . .   . . .
#|
#|. 2 .   . . .   . 6 .
#|. . .   . 8 .   4 . .
#|. . .   . 1 .   . . .
#|
#|. . .   6 . 3   . 7 .
#|5 . .   2 . .   . . .
#|1 . 4   . . .   . . .
```

For now, let's not consider game rules too much. If we only consider the digits that can be filled in each square, then 1-9 are all possible. Therefore, we initially set the content of all squares to `['1', '2', '3', '4', '5', '6', '7', '8', '9']` (a List).

```moonbit skip
fn Grid::parse(s : String) -> Grid[@immut/sorted_set.T[Char]] {
  let digits = @immut/sorted_set.from_array(cols.to_array())
  let values = Grid::new(digits)
  ...
}
```

Next, we need to assign values to the squares with known digits from the input. This process can be implemented with the function `assign(values, key, val)`, where `key` is a string like `A6` and `val` is a character. It is easy to write such code.

```moonbit skip
fn assign(values : Grid[@immut/sorted_set.T[Char]], key : String, val : Char) -> Unit {
  values[key] = @immut/sorted_set.singleton(val)
}
```

This implementation is simple and precise, but we can do more.

Now, we can reintroduce the rules that we set aside earlier. However, the rules themselves do not tell us what to do. We need heuristic strategies to gain insights from the rules, similar to solving Sudoku with pen and paper. Let's start with the elimination method:

- **Strategy 1**: If a square `key` is assigned a value `val`, then its peers (peers[key]) should not contain `val` in their lists of possible values, as this would violate the rule that no two squares in the same unit, row, or column can have the same digit.

- **Strategy 2**: If there is only one square in a unit that can hold a specific digit (possibly happen after applying the above rule several times), then that digit should be assigned to that square.

We adjust the code by defining an `eliminate` function, which removes a digit from the possible values of a square. After performing the elimination task, it applies the above strategies to `key` and `val` to attempt further eliminations. Note that it includes a boolean return value to handle possible contradictions. If the list of possible values for a square becomes empty, something went wrong, and we return `false`.

```moonbit
fn eliminate(
  values : Grid[@immut/sorted_set.SortedSet[Char]],
  key : String,
  val : Char
) -> Bool {
  if not(values[key].contains(val)) {
    return true
  }
  values[key] = values[key].remove(val)
  // If `key` has only one possible value left, remove this value from its peers
  match values[key].length() {
    1 => {
      let val = values[key].min()
      let mut res = true
      for key in peers[key] {
        res = res && eliminate(values, key, val)
      }
      if not(res) {
        return res
      }
    }
    0 => return false
    _ => ()
  }
  //  If there is only one square in the unit of `key` that can hold `val`, assign `val` to that square
  let unit = units[key]
  let places = unit.filter(fn(sq) { values[sq].contains(val) })
  match places.length() {
    1 => {
      let key = places.min()
      return assign(values, key, val)
    }
    0 => return false
    _ => return true
  }
}
```

Next, we define `assign(values, key, val)` to remove all values except `val` from the possible values of `key`.

```moonbit
///|
fn assign(
  values : Grid[@immut/sorted_set.SortedSet[Char]],
  key : String,
  val : Char
) -> Bool {
  let other_values = values[key].remove(val)
  let mut result = true
  for val in other_values {
    result = result && eliminate(values, key, val)
  }
  return result
}
```

These two functions apply heuristic strategies to each square they access. A successful heuristic application introduces new squares to consider, allowing these strategies to propagate widely across the grid. This is key to quickly eliminating invalid options. In fact, this preprocessing can already solve some simple Sudoku puzzles.

```moonbit
let grid2 =
  #|0 0 3   0 2 0   6 0 0
  #|9 0 0   3 0 5   0 0 1
  #|0 0 1   8 0 6   4 0 0
  #|
  #|0 0 8   1 0 2   9 0 0
  #|7 0 0   0 0 0   0 0 8
  #|0 0 6   7 0 8   2 0 0
  #|
  #|0 0 2   6 0 9   5 0 0
  #|8 0 0   2 0 3   0 0 9
  #|0 0 5   0 1 0   3 0 0

test {
  inspect(
    Grid::parse(grid2).format(),
    content=(
      #| 4  8  3 | 9  2  1 | 6  5  7
      #| 9  6  7 | 3  4  5 | 8  2  1
      #| 2  5  1 | 8  7  6 | 4  9  3
      #|---------+---------+---------
      #| 5  4  8 | 1  3  2 | 9  7  6
      #| 7  2  9 | 5  6  4 | 1  3  8
      #| 1  3  6 | 7  9  8 | 2  4  5
      #|---------+---------+---------
      #| 3  7  2 | 6  8  9 | 5  1  4
      #| 8  1  4 | 2  5  3 | 7  6  9
      #| 6  9  5 | 4  1  7 | 3  8  2
      #|
    ),
  )
}
```

If you are interested in artificial intelligence, you might recognize this as a Constraint Satisfaction Problem (CSP), and `assign` and `eliminate` are specialized arc consistency algorithms. For more on this topic, refer to Chapter 6 of _Artificial Intelligence: A Modern Approach_.

## Search

After preprocessing, we can boldly use brute-force enumeration to search for all feasible combinations. However, we can still use the heuristic strategies during the search process. When trying to assign a value to a square, we still use `assign`, which allows us to apply previous optimizations to eliminate many invalid branches during the search.

Another point to note is that conflicts may arise during the search (when a square's possible values are exhausted). Since mutable structures make backtracking troublesome, we directly copy values each time we assign a value.

```moonbit
fn search(
  values : Grid[@immut/sorted_set.SortedSet[Char]],
) -> Grid[@immut/sorted_set.SortedSet[Char]]? {
  if values.contains(fn(digits) { not(digits.length() == 1) }) {
    let mut minsq = ""
    let mut n = 10
    for sq in squares {
      let len = values[sq].length()
      if len > 1 {
        if len < n {
          n = len
          minsq = sq
        }
      }
    }
    for digit in values[minsq] {
      let another = values.copy()
      if assign(another, minsq, digit) {
        let temp = search(another)
        match temp {
          None => continue
          Some(v) => return Some(v)
        }
      }
    } else {
      return None
    }
  } else {
    return Some(values)
  }
}

fn solve(g : String) -> String {
  match search(Grid::parse(g)) {
    None => "can't solve \{g}"
    Some(v) => v.format()
  }
}
```

Let's run the example taken from [magictour](http://magictour.free.fr/top95), a list of difficult Sudoku puzzles, which is not easy for humans.

```moonbit
let grid1 =
  #|4 . .   . . .   8 . 5
  #|. 3 .   . . .   . . .
  #|. . .   7 . .   . . .
  #|
  #|. 2 .   . . .   . 6 .
  #|. . .   . 8 .   4 . .
  #|. . .   . 1 .   . . .
  #|
  #|. . .   6 . 3   . 7 .
  #|5 . .   2 . .   . . .
  #|1 . 4   . . .   . . .

test {
  inspect(
    solve(grid1),
    content=(
      #| 4  1  7 | 3  6  9 | 8  2  5
      #| 6  3  2 | 1  5  8 | 9  4  7
      #| 9  5  8 | 7  2  4 | 3  1  6
      #|---------+---------+---------
      #| 8  2  5 | 4  3  7 | 1  6  9
      #| 7  9  1 | 5  8  6 | 4  3  2
      #| 3  4  6 | 9  1  2 | 7  5  8
      #|---------+---------+---------
      #| 2  8  9 | 6  4  3 | 5  7  1
      #| 5  7  3 | 2  9  1 | 6  8  4
      #| 1  6  4 | 8  7  5 | 2  9  3
      #|
    ),
  )
}
```

Running on [MoonBit online IDE](https://try.moonbitlang.com/), It takes only about 0.11 seconds to solve this Sudoku!

## Conclusion

The purpose of games is to relieve boredom and bring joy. If playing a game becomes more anxiety-inducing than exciting, it might go against the game designer's original intent. The article demonstrated that simple elimination methods and brute-force search can quickly solve some Sudoku puzzles. This does not mean that Sudoku is not worth playing; rather, it reveals that one should not be overly concerned with an unsolvable Sudoku puzzle.

Let's play with MoonBit with ease!

This tutorial references Norvig's blog: [http://norvig.com/sudoku.html](http://norvig.com/sudoku.html)
