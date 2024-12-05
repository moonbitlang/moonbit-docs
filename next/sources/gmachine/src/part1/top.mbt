// start run definition
fn run(codes : List[String]) -> Node {
  fn parse_then_compile(code : String) -> (String, Int, List[Instruction]) {
    let tokens = tokenize(code)
    let code = 
      try {
        tokens.parse_sc!()
      } catch {
        ParseError(s) => abort(s)
      } else {
        expr => expr
      }
    let code = compileSC(code)
    return code
  }
  let codes = codes.map(parse_then_compile) + prelude_defs.map(compileSC)
  let (heap, globals) = build_initial_heap(codes)
  let initialState : GState = {
    heap : heap,
    stack : Nil,
    code : List::of([PushGlobal("main"), Unwind]),
    globals : globals,
    stats : 0
  }
  initialState.reify()
}
// end run definition

test "basic eval" {
  // S K K x => ((K x (K x)) => x
  let main = "(defn main[] (S K K 3))" 
  inspect!(run(List::of([main])), content = "NNum(3)")
  let main = "(defn main[] (K 0 1))"
  inspect!(run(List::of([main])), content = "NNum(0)")
  let main = "(defn main[] (K1 0 1))"
  inspect!(run(List::of([main])), content = "NNum(1)")
}