# A Tour of MoonBit for Beginners

This guide is intended for newcomers, and it's not meant to be a 5-minute quick
tour. This article tries to be a succinct yet easy to understand guide for those
who haven't programmed in a way that MoonBit enables them to, that is, in a more
modern, functional way.

See [the General Introduction](../language/index.md) if you want to straight
delve into the language.

## Installation

**The extension**

Currently, MoonBit development support is through the VS Code extension.
Navigate to
[VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=moonbit.moonbit-lang)
to download MoonBit language support.

**The toolchain**

> (Recommended) If you've installed the extension above, the runtime can be
> directly installed by running 'Install moonbit toolchain' in the action menu
> and you may skip this part:
> ![runtime-installation](/imgs/runtime-installation.png)

We also provide an installation script: Linux & macOS users can install via

```bash
curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash
```

For Windows users, PowerShell is used:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser; irm https://cli.moonbitlang.com/install/powershell.ps1 | iex
```

This automatically installs MoonBit in `$HOME/.moon` and adds it to your `PATH`.

If you encounter `moon` not found after installation, try restarting your
terminal or VS Code to let the environment variable take effect.

Do notice that MoonBit is not production-ready at the moment, it's under active
development. To update MoonBit, just run the commands above again.

Running `moon help` gives us a bunch of subcommands. But right now the only
commands we need are `build`, `run`, and `new`.

To create a project (or module, more formally), run `moon new <path>`, where path
is the place you would like to place the project. For example, if you execute
`moon new examine`, you will get:

```
examine
├── Agents.md
├── cmd
│   └── main
│       ├── main.mbt
│       └── moon.pkg.json
├── LICENSE
├── moon.mod.json
├── moon.pkg.json
├── examine_test.mbt
├── examine.mbt
├── README.mbt.md
└── README.md -> README.mbt.md
```

which contains a `cmd/main` lib containing a `fn main` that serves as the entrance
of the program. Try running `cd examine && moon run cmd/main`.

In this tutorial, we assume the project name is `examine`, 
and the current working directory is also `examine`.

## Example: Finding those who passed

In this example, we will try to find out, given the scores of some students, how
many of them have passed the test?

To do so, we will start with defining our data types, identify our functions,
and write our tests. Then we will implement our functions.

Unless specified, the following will be defined under the file `top.mbt`.

### Data types

The [basic data types](/language/fundamentals.md#built-in-data-structures) in MoonBit includes the following:

- `Unit`
- `Bool`
- `Int`, `UInt`, `Int64`, `UInt64`, `Byte`, ...
- `Float`, `Double`
- `Char`, `String`, ...
- `Array[T]`, ...
- Tuples, and still others

To represent a struct containing a student ID and a score using a primitive
type, we can use a 2-tuple containing a student ID (of type `String`) and a
score (of type `Double`) as `(String, Double)`. However this is not very
intuitive as we can't identify with other possible data types, such as a struct
containing a student ID and the height of the student.

So we choose to declare our own data type using [struct](/language/fundamentals.md#struct):

```{code-block} moonbit
:class: top-level
struct Student {
  id : String
  score : Double
}
```

One can either pass or fail an exam, so the judgement result can be defined
using [enum](/language/fundamentals.md#enum):

```{code-block} moonbit
:class: top-level
enum ExamResult {
  Pass
  Fail
}
```

### Functions

[Function](/language/fundamentals.md#functions) is a piece of code that takes some inputs and produces a result.

In our example, we need to judge whether a student have passed an exam:

```{code-block} moonbit
:class: top-level
fn is_qualified(student : Student, criteria: Double) -> ExamResult {
  ...
}
```

This function takes an input `student` of type `Student` that we've just defined, an input `criteria` of type `Double` as the criteria may be different for each course or different in each country, and returns an `ExamResult`. 

The `...` syntax allows us to leave functions unimplemented for now.

We also need to find out how many students have passed an exam:

```{code-block} moonbit
:class: top-level
fn count_qualified_students(
  students : Array[Student],
  is_qualified : (Student) -> ExamResult
) -> Int {
  ...
}
```

In MoonBit, functions are first-classed, meaning that we can bind a function to a variable, pass a function as parameter or receiving a function as a result.
This function takes an array of students' structs and another function that will judge whether a student have passed an exam.

### Writing tests

We can define inline tests to define the expected behavior of the functions. This is also helpful to make sure that there'll be no regressions when we refactor the program.

```{code-block} moonbit
:class: top-level
test "is qualified" {
  assert_eq(is_qualified(Student::{ id : "0", score : 50.0 }, 60.0), Fail)
  assert_eq(is_qualified(Student::{ id : "1", score : 60.0 }, 60.0), Pass)
  assert_eq(is_qualified(Student::{ id : "2", score : 13.0 }, 7.0), Pass)
}
```

We will get an error message, reminding us that `Show` and `Eq` are not implemented for `ExamResult`. 

`Show` and `Eq` are **traits**. A trait in MoonBit defines some common operations that a type should be able to perform.

For example, `Eq` defines that there should be a way to compare two values of the same type with a function called `op_equal`:

```{code-block} moonbit
:class: top-level
trait Eq {
  op_equal(Self, Self) -> Bool
}
```

and `Show` defines that there should be a way to either convert a value of a type into `String` or write it using a `Logger`:

```{code-block} moonbit
:class: top-level
trait Show {
  output(Self, &Logger) -> Unit
  to_string(Self) -> String
}
```

And the `assert_eq` uses them to constraint the passed parameters so that it can compare the two values and print them when they are not equal:

```{code-block} moonbit
:class: top-level
fn assert_eq![A : Eq + Show](value : A, other : A) -> Unit {
  ...
}
```

We need to implement `Eq` and `Show` for our `ExamResult`. There are two ways to do so.

1. By defining an explicit implementation:

    ```{code-block} moonbit
    :class: top-level
    impl Eq for ExamResult with op_equal(self, other) {
      match (self, other) {
        (Pass, Pass) | (Fail, Fail) => true
        _ => false
      }
    }
    ```

    Here we use [pattern matching](/language/fundamentals.md#pattern-matching) to check the cases of the `ExamResult`.

2. Other is by [deriving](/language/derive.md) since `Eq` and `Show` are [builtin traits](/language/methods.md#builtin-traits) and the output for `ExamResult` is quite straightforward:

    ```{code-block} moonbit
    :class: top-level
    enum ExamResult {
      Pass
      Fail
    } derive(Show)
    ```

Now that we've implemented the traits, we can continue with our test implementations:

```{code-block} moonbit
:class: top-level
test "count qualified students" {
  let students = [
    { id: "0", score: 10.0 },
    { id: "1", score: 50.0 },
    { id: "2", score: 61.0 },
  ]
  let criteria1 = fn(student) { is_qualified(student, 10) }
  let criteria2 = fn(student) { is_qualified(student, 50) }
  assert_eq(count_qualified_students(students, criteria1), 3)
  assert_eq(count_qualified_students(students, criteria2), 2)
}

```

Here we use [lambda expressions](/language/fundamentals.md#local-functions) to reuse the previously defined `is_qualified` to create different criteria.

We can run `moon test` to see whether the tests succeed or not.

### Implementing the functions

For the `is_qualified` function, it is as easy as a simple comparison:

```{code-block} moonbit
:class: top-level
fn is_qualified(student : Student, criteria : Double) -> ExamResult {
  if student.score >= criteria {
    Pass
  } else {
    Fail
  }
}
```

In MoonBit, the result of the last expression is the return value of the function, and the result of each branch is the value of the `if` expression.

For the `count_qualified_students` function, we need to iterate through the array to check if each student has passed or not.

A naive version is by using a mutable value and a [`for` loop](/language/fundamentals.md#for-loop):

```{code-block} moonbit
:class: top-level
fn count_qualified_students(
  students : Array[Student],
  is_qualified : (Student) -> ExamResult
) -> Int {
  let mut count = 0
  for i = 0; i < students.length(); i = i + 1 {
    if is_qualified(students[i]) == Pass {
      count += 1
    }
  }
  count
}
```

However, this is neither efficient (due to the border check) nor intuitive, so we can replace the `for` loop with a [`for .. in` loop](/language/fundamentals.md#for--in-loop):

```{code-block} moonbit
:class: top-level
fn count_qualified_students(
  students : Array[Student],
  is_qualified : (Student) -> ExamResult
) -> Int {
  let mut count = 0
  for student in students {
    if is_qualified(student) == Pass { count += 1}
  }
  count
}
```

Still another way is use the functions defined for [iterator](/language/fundamentals.md#iterator):

```{code-block} moonbit
:class: top-level
fn count_qualified_students(
  students : Array[Student],
  is_qualified : (Student) -> ExamResult
) -> Int {
  students.iter().filter(fn(student) { is_qualified(student) == Pass }).count()
}
```

Now the tests defined before should pass.

## Making the library available

Congratulation on your first MoonBit library!

You can now share it with other developers so that they don't need to repeat what you have done.

But before that, you have some other things to do.

### Adjusting the visibility

To see how other people may use our program, MoonBit provides a mechanism called ["black box test"](/language/tests.md#blackbox-tests-and-whitebox-tests).

Let's move the `test` block we defined above into a new file `top_test.mbt`.

Oops! Now there are errors complaining that:
- `is_qualified` and `count_qualified_students` are unbound
- `Fail` and `Pass` are undefined
- `Student` is not a struct type and the field `id` is not found, etc.

All these come from the problem of visibility. By default, a function defined is not visible for other part of the program outside the current package (bound by the current folder).
And by default, a type is viewed as an abstract type, i.e. we know only that there exists a type `Student` and a type `ExamResult`. By using the black box test, you can make sure that
everything you'd like others to have is indeed decorated with the intended visibility.

In order for others to use the functions, we need to add `pub` before the `fn` to make the function public.

In order for others to construct the types and read the content, we need to add `pub(all)` before the `struct` and `enum` to make the types public.

We also need to slightly modify the test of `count qualified students` to add type annotation:

```{code-block} moonbit
:class: top-level
test "count qualified students" {
  let students: Array[@examine.Student] = [
    { id: "0", score: 10.0 },
    { id: "1", score: 50.0 },
    { id: "2", score: 61.0 },
  ]
  let criteria1 = fn(student) { @examine.is_qualified(student, 10) }
  let criteria2 = fn(student) { @examine.is_qualified(student, 50) }
  assert_eq(@examine.count_qualified_students(students, criteria1), 3)
  assert_eq(@examine.count_qualified_students(students, criteria2), 2)
}
```

Note that we access the type and the functions with `@examine`, the name of your package. This is how others use your package, but you can omit them in the black box tests.

And now, the compilation should work and the tests should pass again.

### Publishing the library

Now that you've ready, you can publish this project to [mooncakes.io](https://mooncakes.io),
the module registry of MoonBit. You can find other interesting projects there
too.

1. Execute `moon login` and follow the instruction to create your account with
   an existing GitHub account.
2. Modify the project name in `moon.mod.json` to
   `<your github account name>/<project name>`. Run `moon check` to see if
   there's any other affected places in `moon.pkg.json`.
3. Execute `moon publish` and your done. Your project will be available for
   others to use.

By default, the project will be shared under [Apache 2.0](https://www.apache.org/licenses/LICENSE-2.0.html), 
which is a permissive license allowing everyone to use. You can also use other licenses, such as the [MulanPSL 2.0](https://spdx.org/licenses/MulanPSL-2.0.html),
by changing the field `license` in `moon.mod.json` and the content of `LICENSE`.

### Closing

At this point, we've learned about the very basic and most not-so-trivial
features of MoonBit, yet MoonBit is a feature-rich, multi-paradigm programming
language. Visit [language tours](https://tour.moonbitlang.com) for more information in grammar and basic types,
and other documents to get a better hold of MoonBit.
