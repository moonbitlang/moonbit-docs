// start instr definition
enum Instruction {
  Unwind
  PushGlobal(String)
  PushInt(Int)
  Push(Int)
  MkApp
  Slide(Int)
  Update(Int)
  Pop(Int)
  Alloc(Int)
  Eval
  Add
  Sub
  Mul
  Div
  Neg
  Eq // ==
  Ne // !=
  Lt // <
  Le // <=
  Gt // >
  Ge // >=
  Cond(List[Instruction], List[Instruction])
  Pack(Int, Int) // tag, arity
  CaseJump(List[(Int, List[Instruction])])
  Split
  Print
} derive(Eq, Show)
// end instr definition
