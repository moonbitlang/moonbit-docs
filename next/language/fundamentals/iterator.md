# Iterator

An iterator is an object that traverse through a sequence while providing access
to its elements. Traditional OO languages like Java's `Iterator<T>` use `next()`
`hasNext()` to step through the iteration process, whereas functional languages
(JavaScript's `forEach`, Lisp's `mapcar`) provides a high-order function which
takes an operation and a sequence then consumes the sequence with that operation
being applied to the sequence. The former is called _external iterator_ (visible
to user) and the latter is called _internal iterator_ (invisible to user).

The built-in type `Iter[T]` is MoonBit's external iterator implementation. It
exposes `next()` to pull the next value: it returns `Some(value)` and advances
the iterator, or `None` when the iteration is finished.
Almost all built-in sequential data structures have implemented `Iter`:

```{literalinclude} /sources/language/src/iter/top.mbt
:language: moonbit
:start-after: start iter 1
:end-before: end iter 1
```

Commonly used methods include:

- `each`: Iterates over each element in the iterator, applying some function to each element.
- `fold`: Folds the elements of the iterator using the given function, starting with the given initial value.
- `collect`: Collects the elements of the iterator into an array.

- `filter`: _lazy_ Filters the elements of the iterator based on a predicate function.
- `map`: _lazy_ Transforms the elements of the iterator using a mapping function.
- `concat`: _lazy_ Combines two iterators into one by appending the elements of the second iterator to the first.

Methods like `filter` and `map` are very common on a sequence object e.g. Array.
But what makes `Iter` special is that any method that constructs a new `Iter` is
_lazy_ (i.e. iteration doesn't start on call because it's wrapped inside a
function), as a result of no allocation for intermediate value. That's what
makes `Iter` superior for traversing through sequence: no extra cost. MoonBit
encourages user to pass an `Iter` across functions instead of the sequence
object itself.

Pre-defined sequence structures like `Array` and its iterators should be
enough to use. But to take advantages of these methods when used with a custom
sequence with elements of type `S`, we will need to implement `Iter`, namely, a function that returns
an `Iter[S]`. Take `Bytes` as an example:

```{literalinclude} /sources/language/src/iter/top.mbt
:language: moonbit
:start-after: start iter 2
:end-before: end iter 2
```

Iterators are single-pass: once you call `next()` or consume them with methods
like `each`, `fold`, or `collect`, their internal state advances and cannot be
reset. If you need to traverse the sequence again, request a new `Iter` from
the source.
