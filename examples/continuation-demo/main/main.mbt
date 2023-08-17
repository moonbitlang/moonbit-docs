// usage 1: early exit

// Define a pub function that calculates the factorial of a number using callCC
pub func earlyExit1(n : Int) -> @lib.Cont[Int, Int] {
  @lib.callCC(
    fn(exit) {
      @lib.return_(n).bind(
        fn(acc) {
          (if acc < 10 {
            exit(-1)
          } else {
            @lib.return_(0)
          }).bind(fn(y) { @lib.return_(acc) })
        },
      )
    },
  )
}

func init {
  let r = earlyExit1(5).runCont(@lib.id)
  @lib.println(r) // -> -1
  let r = earlyExit1(10).runCont(@lib.id)
  @lib.println(r) // -> 10
}

// usage 2: exception handling

enum Either[A, B] {
  Left(A)
  Right(B)
}

pub func bind[A, B, C](self : Either[A, B], f : (B) -> Either[A, C]) ->
     Either[A, C] {
  match self {
    Left(x) => Left(x)
    Right(x) => f(x)
  }
}

pub func to_string[A : Show, B : Show](self : Either[A, B]) -> String {
  match self {
    Left(x) => "Left(\(x))"
    Right(x) => "Right(\(x))"
  }
}

pub func divideCont[A](n : Int) -> @lib.Cont[A, Int] {
  @lib.cont(fn(k) { k(100 / n) })
}

pub func safeDivide[A](n : Int) -> @lib.Cont[A, Either[String, Int]] {
  if n == 0 {
    @lib.cont(fn(k) { k(Either::Left("divide by zero")) })
  } else {
    divideCont(n).bind(fn(x) { @lib.return_(Either::Right(x)) })
  }
}

pub func incr[A](n : Int) -> @lib.Cont[A, Int] {
  @lib.cont(fn(k) { k(n + 1) })
}

func init {
  fn catch(x : Either[String, Int]) {
    match x {
      Left(y) => "Exception: \(y)\n".print()
      Right(y) => "Result: \(y)\n".print()
    }
  }

  let r = safeDivide(0).bind(
    fn(x) {
      match x {
        Right(y) => @lib.fmap(fn(x) { Either::Right(x) }, incr(y))
        _ => @lib.return_(x)
      }
    },
  ).runCont(catch) // -> Left("divide by zero")
  let r = safeDivide(10).bind(
    fn(x) {
      match x {
        Right(y) => @lib.fmap(fn(x) { Either::Right(x) }, incr(y))
        _ => @lib.return_(x)
      }
    },
  ).runCont(catch) // -> Right(11)
  ()
}

// usage 3: delimited continuation

func init {
  fn r(n : Int) {
    @lib.reset(
      @lib.return_(n).bind(
        fn(k) {
          if k < 10 {
            @lib.shift(fn(k0) { @lib.return_(-1) })
          } else {
            @lib.return_(k + 1)
          }
        },
      ).bind(fn(x) { @lib.return_(x + 1) }),
    ).bind(fn(x) { @lib.return_(x * 3) }).runCont(@lib.id)
  }

  @lib.println(r(1)) // -> -3
  @lib.println(r(10)) // -> 36
}

