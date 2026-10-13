// start instr definition

enum Instruction {
  Unwind
  PushGlobal(String)
  PushInt(Int32)
  PushArg(Int32)
  MkApp
  Update(Int32)
  Pop(Int32)
} derive(Eq, Debug)

pub extend Instruction with Eq::{not_equal, equal}

pub extend Instruction with @moonbitlang/core/debug.Debug::{to_repr}
// end instr definition
