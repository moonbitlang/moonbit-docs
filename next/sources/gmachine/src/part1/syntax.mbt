///|
enum Token {
  DefFn
  Let
  NIL
  CONS
  Case
  Letrec
  Open(Char) // { [ (
  Close(Char) // } ] )
  Id(String)
  Number(Int)
  EOF
} derive(Eq, Show)

///|
fn between(this : Char, lw : Char, up : Char) -> Bool {
  this >= lw && this <= up
}

///|
fn isDigit(this : Char) -> Bool {
  between(this, '0', '9')
}

///|
fn isAlpha(this : Char) -> Bool {
  between(this, 'A', 'Z') || between(this, 'a', 'z')
}

///|
fn isIdChar(this : Char) -> Bool {
  isAlpha(this) || isDigit(this) || this == '_' || this == '-'
}

///|
fn isWhiteSpace(this : Char) -> Bool {
  this == ' ' || this == '\t' || this == '\n'
}

///|
fn to_number(this : Char) -> Int {
  this.to_int() - 48
}

///|
fn isOpen(this : Char) -> Bool {
  this == '(' || this == '[' || this == '{'
}

///|
fn isClose(this : Char) -> Bool {
  this == ')' || this == ']' || this == '}'
}

///|
struct Tokens {
  tokens : Array[Token]
  mut current : Int
} derive(Show)

///|
fn Tokens::new(tokens : Array[Token]) -> Tokens {
  Tokens::{ tokens, current: 0 }
}

///|
fn Tokens::peek(self : Tokens) -> Token {
  if self.current < self.tokens.length() {
    return self.tokens[self.current]
  } else {
    return EOF
  }
}

///|
suberror ParseError { ParseError(String) }

///|
#callsite(autofill(loc))
fn Tokens::next(self : Tokens, loc~ : SourceLoc) -> Unit {
  self.current = self.current + 1
  if self.current > self.tokens.length() {
    abort("Tokens::next(): \{loc}")
  }
}

///|
/// 
#callsite(autofill(loc))
fn Tokens::eat(
  self : Tokens,
  tok : Token,
  loc~ : SourceLoc,
) -> Unit raise ParseError {
  let __tok = self.peek()
  // assert tok_ != EOF
  if __tok != tok {
    raise ParseError("\{loc} - Tokens::eat(): expect \{tok} but got \{__tok}")
  } else {
    self.next()
  }
}

///|
fn tokenize(source : String) -> Tokens {
  let tokens : Array[Token] = Array::new(capacity=source.length() / 2)
  let mut current = 0
  let source = source.to_array()
  fn peek() -> Char {
    source[current]
  }

  fn next() -> Unit {
    current = current + 1
  }

  while current < source.length() {
    let ch = peek()
    if isWhiteSpace(ch) {
      next()
      continue
    } else if isDigit(ch) {
      let mut num = to_number(ch)
      next()
      while current < source.length() && isDigit(peek()) {
        num = num * 10 + to_number(peek())
        next()
      }
      tokens.push(Number(num))
      continue
    } else if isOpen(ch) {
      next()
      tokens.push(Open(ch))
      continue
    } else if isClose(ch) {
      next()
      tokens.push(Close(ch))
      continue
    } else if isAlpha(ch) {
      let identifier = @buffer.new(size_hint=42)
      identifier.write_char(ch)
      next()
      while current < source.length() && isIdChar(peek()) {
        identifier.write_char(peek())
        next()
      }
      let identifier = identifier.contents().to_unchecked_string()
      match identifier {
        "let" => tokens.push(Let)
        "letrec" => tokens.push(Letrec)
        "Nil" => tokens.push(NIL)
        "Cons" => tokens.push(CONS)
        "case" => tokens.push(Case)
        "defn" => tokens.push(DefFn)
        _ => tokens.push(Id(identifier))
      }
    } else {
      abort("error : invalid Character '\{ch}' in [\{current}]")
    }
  } else {
    return Tokens::new(tokens)
  }
}

///|
test "tokenize" {
  inspect(tokenize("").tokens, content="[]")
  inspect(tokenize("12345678").tokens, content="[Number(12345678)]")
  inspect(tokenize("1234 5678").tokens, content="[Number(1234), Number(5678)]")
  inspect(
    tokenize("a0 a_0 a-0").tokens,
    content=(
      #|[Id("a0"), Id("a_0"), Id("a-0")]
    ),
  )
  inspect(
    tokenize("(Cons 0 (Cons 1 Nil))").tokens,
    content="[Open('('), CONS, Number(0), Open('('), CONS, Number(1), NIL, Close(')'), Close(')')]",
  )
}

///|
fn Tokens::parse_var(self : Tokens) -> String raise ParseError {
  match self.peek() {
    Id(s) => {
      self.next()
      return s
    }
    other => raise ParseError("parse_var(): expect a variable but got \{other}")
  }
}

///|
fn Tokens::parse_cons(self : Tokens) -> RawExpr[String] raise ParseError {
  match self.peek() {
    CONS => {
      self.next()
      let x = self.parse_expr()
      let xs = self.parse_expr()
      return App(App(Constructor(tag=1, arity=2), x), xs)
    }
    other => raise ParseError("parse_cons(): expect Cons but got \{other}")
  }
}

///|
fn Tokens::parse_let(self : Tokens) -> RawExpr[String] raise ParseError {
  self.eat(Let)
  self.eat(Open('('))
  let defs = self.parse_defs()
  self.eat(Close(')'))
  let exp = self.parse_expr()
  Let(false, defs, exp)
}

///|
fn Tokens::parse_letrec(self : Tokens) -> RawExpr[String] raise ParseError {
  self.eat(Letrec)
  self.eat(Open('('))
  let defs = self.parse_defs()
  self.eat(Close(')'))
  let exp = self.parse_expr()
  Let(true, defs, exp)
}

///|
fn Tokens::parse_case(self : Tokens) -> RawExpr[String] raise ParseError {
  self.eat(Case)
  let exp = self.parse_expr()
  let alts = self.parse_alts()
  Case(exp, alts)
}

///|
fn Tokens::parse_alts(
  self : Tokens,
) -> List[(Int, List[String], RawExpr[String])] raise ParseError {
  let acc : List[(Int, List[String], RawExpr[String])] = @list.empty()
  loop (self.peek(), acc) {
    (Open('['), acc) => {
      self.next()
      self.eat(Open('('))
      let (tag, variables) = match self.peek() {
        NIL => {
          self.next()
          (0, @list.empty())
        }
        CONS => {
          self.next()
          let x = self.parse_var()
          let xs = self.parse_var()
          (1, @list.from_array([x, xs]))
        }
        other =>
          raise ParseError("parse_alts(): expect NIL or CONS but got \{other}")
      }
      self.eat(Close(')'))
      let exp = self.parse_expr()
      let alt = (tag, variables, exp)
      self.eat(Close(']'))
      continue (self.peek(), acc.prepend(alt))
    }
    (_, acc) => acc.rev()
  }
}

///|
fn Tokens::parse_defs(
  self : Tokens,
) -> List[(String, RawExpr[String])] raise ParseError {
  let acc : List[(String, RawExpr[String])] = @list.empty()
  loop (self.peek(), acc) {
    (Open('['), acc) => {
      self.next()
      let name = self.parse_var()
      let value = self.parse_expr()
      self.eat(Close(']'))
      continue (self.peek(), acc.prepend((name, value)))
    }
    (_, acc) => acc.rev()
  }
}

///|
fn Tokens::parse_apply(self : Tokens) -> RawExpr[String] raise ParseError {
  let mut res = self.parse_expr()
  while self.peek() != Close(')') {
    res = App(res, self.parse_expr())
  }
  return res
}

///|
fn Tokens::parse_expr(self : Tokens) -> RawExpr[String] raise ParseError {
  match self.peek() {
    EOF =>
      raise ParseError(
        "parse_expr() : expect a token but got a empty token stream",
      )
    Number(n) => {
      self.next()
      Num(n)
    }
    Id(s) => {
      self.next()
      Var(s)
    }
    NIL => {
      self.next()
      Constructor(tag=0, arity=0)
    }
    Open('(') => {
      self.next()
      let exp = match self.peek() {
        Let => self.parse_let()
        Letrec => self.parse_letrec()
        Case => self.parse_case()
        CONS => self.parse_cons()
        Id(_) | Open('(') => self.parse_apply()
        other =>
          raise ParseError("parse_expr(): can't parse \{other} behind a '('")
      }
      self.eat(Close(')'))
      return exp
    }
    other => raise ParseError("parse_expr(): can't parse \{other}")
  }
}

///|
fn Tokens::parse_sc(self : Tokens) -> ScDef[String] raise ParseError {
  self.eat(Open('('))
  self.eat(DefFn)
  let fn_name = self.parse_var()
  self.eat(Open('['))
  let args = loop (self.peek(), @list.empty()) {
    (tok, acc) =>
      if tok != Close(']') {
        let name = self.parse_var()
        continue (self.peek(), acc.prepend(name))
      } else {
        acc.rev()
      }
  }
  self.eat(Close(']'))
  let body = self.parse_expr()
  self.eat(Close(')'))
  ScDef::{ name: fn_name, args, body }
}

///|
test "parse scdef" {
  let test_ = fn(s) raise ParseError { ignore(tokenize(s).parse_sc()) }
  for p in programs {
    let (_, p) = p
    test_(p)
  }
}
