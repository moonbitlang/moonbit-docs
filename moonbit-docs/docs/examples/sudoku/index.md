# Sudoku Solver

Sudoku is a logic-based puzzle game that originated in 1979. It was well-suited for print media like newspapers, and even in the digital age, many Sudoku game programs are available for computers and smartphones. Despite the variety of entertainment options today, Sudoku enthusiasts continue to form active communities (online forum such as: [enjoysudoku](http://forum.enjoysudoku.com/)). This article will demonstrate how to write a suitable program to solve Sudoku using MoonBit.
[1.jpg](1.jpg)

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

We need a data type, SquareMap[T], to store the 81 squares and the information associated with each square. This can be implemented using a hashtable, but using an array would be more compact and simple. First, we write a function to convert coordinates A1-I9 to indices 0-80:

```rust
// A1 => 0, A2 => 1
fn square_to_int(s : String) -> Int {
  if in(s[0], 'A', 'I') && in(s[1], '1', '9') {
    let row = s[0].to_int() - 65 // 'A' <=> 0
    let col = s[1].to_int() - 49 // '1' <=> 0
    return row * 9 + col
  } else {
    abort("square_to_int(): \{s} is not a square")
  }
}

// Helper function `in` checks if a character is between `lw` and `up`
fn in(this : Char, lw : Char, up : Char) -> Bool {
  this >= lw && this <= up
}
```

Then we wrap the array and provide operations for creating, accessing, assigning values to specific coordinates, and copying SquareMap[T]. By overloading the op_get and op_set methods, we can write convenient code like table["A2"] and table["C3"] = Nil.

```rust
struct SquareMap[T] {
  contents : Array[T]
}

fn SquareMap::new[T](val : T) -> SquareMap[T] {
  { contents : Array::make(81, val) }
}

fn copy[T](self : SquareMap[T]) -> SquareMap[T] {
  let arr = Array::make(81, self.contents[0])
  let mut i = 0
  while i < 81 {
    arr[i] = self.contents[i]
    i = i + 1
  }
  return { contents : arr }
}

fn op_get[T](self : SquareMap[T], square : String) -> T {
  self.contents[square_to_int(square)]
}

fn op_set[T](self : SquareMap[T], square : String, x : T) -> Unit {
  self.contents[square_to_int(square)] = x
}
```

Next, we prepare some constants:

```rust
let rows = "ABCDEFGHI"
let cols = "123456789"

// squares contains the coordinates of each square
let squares : List[String] = ......

// units[coord] contains the other squares in the unit of the square at coord
// for example：units["A3"] => [C3, C2, C1, B3, B2, B1, A2, A1]
let units : SquareMap[List[String]] = ......

// peers[coord] contains all the peers of the square at coord
// for example：peers["A3"] => [A1, A2, A4, A5, A6, A7, A8, A9, B1, B2, B3, C1, C2, C3, D3, E3, F3, G3, H3, I3]
let peers : SquareMap[List[String]] = ......
```

The process of constructing the units and peers tables is tedious, so it will not be detailed here.

## Preprocessing the Grid

We use a string to represent the initial Sudoku grid. Various formats are acceptable; both `.` and `0` represent empty squares, and other characters like spaces and newlines are ignored.

```
"4.....8.5.3..........7......2.....6.....8.4......1.......6.3.7.5..2.....1.4......"

"
400000805
030000000
000700000
020000060
000080400
000010000
000603070
500200000
104000000"
```

For now, let's not consider game rules too much. If we only consider the digits that can be filled in each square, then 1-9 are all possible. Therefore, we initially set the content of all squares to `['1', '2', '3', '4', '5', '6', '7', '8', '9']` (a List).

```rust
fn parseGrid(s : String) -> SquareMap[List[Char]] {
  let digits = cols.to_list()
  let values : SquareMap[List[Char]] = SquareMap::new(digits)
  ......
}
```

Next, we need to assign values to the squares with known digits from the input. This process can be implemented with the function `assign(values, key, val)`, where `key` is a string like `A6` and `val` is a character. It is easy to write such code.

```rust
fn assign(values : SquareMap[List[Char]], key : String, val : Char) {
  values[key] = Cons(val, Nil)
}
```

Let's run it and see

```
"4.....8.5.3..........7......2.....6.....8.4......1.......6.3.7.5..2.....1.4......"

// Using parseGrid and printGrid functions, skipping implementation details for simplicity

 4          123456789  123456789 | 123456789  123456789  123456789 | 8          123456789  5
 123456789  3          123456789 | 123456789  123456789  123456789 | 123456789  123456789  123456789
 123456789  123456789  123456789 | 7          123456789  123456789 | 123456789  123456789  123456789
---------------------------------+---------------------------------+---------------------------------
 123456789  2          123456789 | 123456789  123456789  123456789 | 123456789  6          123456789
 123456789  123456789  123456789 | 123456789  8          123456789 | 4          123456789  123456789
 123456789  123456789  123456789 | 123456789  1          123456789 | 123456789  123456789  123456789
---------------------------------+---------------------------------+---------------------------------
 123456789  123456789  123456789 | 6          123456789  3         | 123456789  7          123456789
 5          123456789  123456789 | 2          123456789  123456789 | 123456789  123456789  123456789
 1          123456789  4         | 123456789  123456789  123456789 | 123456789  123456789  123456789
```

This implementation is simple and precise, but we can do more.

Now, we can reintroduce the rules that we set aside earlier. However, the rules themselves do not tell us what to do. We need heuristic strategies to gain insights from the rules, similar to solving Sudoku with pen and paper. Let's start with the elimination method:

- **Strategy 1**: If a square `key` is assigned a value `val`, then its peers (peers[key]) should not contain `val` in their lists of possible values, as this would violate the rule that no two squares in the same unit, row, or column can have the same digit.

- **Strategy 2**: If there is only one square in a unit that can hold a specific digit (possibly happen after applying the above rule several times), then that digit should be assigned to that square.

We adjust the code by defining an `eliminate` function, which removes a digit from the possible values of a square. After performing the elimination task, it applies the above strategies to `key` and `val` to attempt further eliminations. Note that it includes a boolean return value to handle possible contradictions. If the list of possible values for a square becomes empty, something went wrong, and we return `false`.

```rust
fn eliminate(values : SquareMap[List[Char]], key : String, val : Char) -> Bool {
  if not(exist(values[key], fn (v) { v == val })) {
    return true
  }
  values[key] = values[key].remove(val)
  // If `key` has only one possible value left, remove this value from its peers
  match single(values[key]) {
    Err(b) => {
      if not(b) {
        return false
      }
    }
    Ok(val) => {
      let mut result = true
      peers[key].iter(fn (key) {
        result = result && eliminate(values, key, val)
      })
      if not(result) {
        return false
      }
    }
  }
  //  If there is only one square in the unit of `key` that can hold `val`, assign `val` to that square
  let unit = units[key]
  let places = unit.filter(fn (sq) {
    exist(values[sq], fn (v) { v == val })
  })
  match single(places) {
    Err(b) => {
      return b
    }
    Ok(key) => {
      return assign(values, key, val)
    }
  }
}


// Return `Err(false)` if the list is empty
// Return `Ok(x)` if the list contains only `[x]`
// Return `Err(true)` if the list contains `[x1, x2, ......]`
fn single[T](this : List[T]) -> Result[T, Bool] {
  match this {
    Nil => Err(false)
    Cons(x, Nil) => Ok(x)
    _ => Err(true)
  }
}
```

Next, we define `assign(values, key, val)` to remove all values except `val` from the possible values of `key`.

```rust
fn assign(values : SquareMap[List[Char]], key : String, val : Char) -> Bool {
  let other_values = values[key].remove(val)
  let mut result = true
  other_values.iter(fn (val) {
    result = result && eliminate(values, key, val)
  })
  return result
}
```

These two functions apply heuristic strategies to each square they access. A successful heuristic application introduces new squares to consider, allowing these strategies to propagate widely across the grid. This is key to quickly eliminating invalid options.

Let's try the example again

```
"4.....8.5.3..........7......2.....6.....8.4......1.......6.3.7.5..2.....1.4......"

 4        1679     12679   | 139      2369     269     | 8        1239     5
 26789    3        1256789 | 14589    24569    245689  | 12679    1249     124679
 2689     15689    125689  | 7        234569   245689  | 12369    12349    123469
---------------------------+---------------------------+---------------------------
 3789     2        15789   | 3459     34579    4579    | 13579    6        13789
 3679     15679    15679   | 359      8        25679   | 4        12359    12379
 36789    4        56789   | 359      1        25679   | 23579    23589    23789
---------------------------+---------------------------+---------------------------
 289      89       289     | 6        459      3       | 1259     7        12489
 5        6789     3       | 2        479      1       | 69       489      4689
 1        6789     4       | 589      579      5789    | 23569    23589    23689
```

A significant improvement! In fact, this preprocessing can already solve some simple Sudoku puzzles.

```
"003020600900305001001806400008102900700000008006708200002609500800203009005010300"

 4  8  3 | 9  2  1 | 6  5  7
 9  6  7 | 3  4  5 | 8  2  1
 2  5  1 | 8  7  6 | 4  9  3
---------+---------+---------
 5  4  8 | 1  3  2 | 9  7  6
 7  2  9 | 5  6  4 | 1  3  8
 1  3  6 | 7  9  8 | 2  4  5
---------+---------+---------
 3  7  2 | 6  8  9 | 5  1  4
 8  1  4 | 2  5  3 | 7  6  9
 6  9  5 | 4  1  7 | 3  8  2
```

If you are interested in artificial intelligence, you might recognize this as a Constraint Satisfaction Problem (CSP), and `assign` and `eliminate` are specialized arc consistency algorithms. For more on this topic, refer to Chapter 6 of _Artificial Intelligence: A Modern Approach_.

## Search

After preprocessing, we can boldly use brute-force enumeration to search for all feasible combinations. However, we can still use the heuristic strategies during the search process. When trying to assign a value to a square, we still use `assign`, which allows us to apply previous optimizations to eliminate many invalid branches during the search.

Another point to note is that conflicts may arise during the search (when a square's possible values are exhausted). Since mutable structures make backtracking troublesome, we directly copy values each time we assign a value.

```rust
fn search(values : SquareMap[List[Char]]) -> Option[SquareMap[List[Char]]] {
  if values.contains(fn (digits){ not(isSingleton(digits)) }) {
    // // Find the square with the smallest number of possible values greater than 1, and start the search from this square
    // This is just a heuristic strategy; you can try finding a smarter and more effective one
    let mut minsq = ""
    let mut n = 10
    squares.iter(fn (sq) {
      let len = values[sq].length()
      if len > 1 {
        if len < n {
          n = len
          minsq = sq
        }
      }
    })
    // Iterate through assignments and stop if a successful search is found
    loop values[minsq] {
      Nil => None
      Cons(digit, rest) => {
        let another = values.copy()
        if assign(another, minsq, digit){
          match search(another) {
            None => continue rest
            Some(_) as result => result
          }
        } else {
          continue rest
        }
      }
    }
  } else {
    return Some(values)
  }
}
```

Let's run the same example again (the example is actually taken from [magictour](http://magictour.free.fr/top95), a list of difficult Sudoku puzzles, which is not easy for humans)

```
> solve("4.....8.5.3..........7......2.....6.....8.4......1.......6.3.7.5..2.....1.4......")

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

Running on [MoonBit online IDE](https://try.moonbitlang.com/), It takes only about 0.11 seconds to solve this Sudoku!

Complete code here: [try.moonbitlang.com/#6806c2fe](https://try.moonbitlang.com/#6806c2fe)

## Conclusion

The purpose of games is to relieve boredom and bring joy. If playing a game becomes more anxiety-inducing than exciting, it might go against the game designer's original intent. The article demonstrated that simple elimination methods and brute-force search can quickly solve some Sudoku puzzles. This does not mean that Sudoku is not worth playing; rather, it reveals that one should not be overly concerned with an unsolvable Sudoku puzzle.

Let's play with MoonBit with ease!

Visit MoonBit [Gallery](https://www.moonbitlang.com/gallery/sudoku/) to play with the Sudoku solver writen in MoonBit. Click [this link](https://github.com/myfreess/sudoku) to view the full source code.

This tutorial references Norvig's blog: [http://norvig.com/sudoku.html](http://norvig.com/sudoku.html)
