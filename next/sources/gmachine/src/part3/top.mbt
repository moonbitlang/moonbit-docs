fn run(codes : List[String]) -> String {
  fn parse_then_compile(code : String) -> (String, Int, List[Instruction]) {
    let tokens = tokenize(code)
    let code = try tokens.parse_sc!() catch {
      ParseError(s) => abort(s)
    } else {
      expr => expr
    }
    let code = code.compileSC()
    return code
  }

  let codes = codes.map(parse_then_compile) + prelude_defs.map(ScDef::compileSC)
  let codes = compiled_primitives + codes
  let (heap, globals) = build_initial_heap(codes)
  // start init definition
  let initialState : GState = {
    output: @buffer.new(size_hint=60),
    heap,
    stack: Nil,
    code: @immut/list.of([PushGlobal("main"), Eval, Print]),
    globals,
    stats: 0,
    dump: Nil,
  }
  // end init definition
  GState::reify(initialState)
}

test "basic eval" {
  let basic = []
  for kv in programs.iter() {
    let (_, v) = kv
    basic.push(v)
  }
  let basic = @immut/list.from_array(basic)
  let main = "(defn main[] (take 20 fibs))"
  inspect!(
    run(Cons(main, basic)),
    content="0 1 1 2 3 5 8 13 21 34 55 89 144 233 377 610 987 1597 2584 4181 Nil",
  )
}
