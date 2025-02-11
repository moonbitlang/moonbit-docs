// start heap definition
// Use the 'type' keyword to encapsulate an address type.
type Addr Int derive(Eq, Show)

// Describe graph nodes with an enumeration type.
enum Node {
  NNum(Int)
  // The application node
  NApp(Addr, Addr)
  // To store the number of parameters and 
  // the corresponding sequence of instructions for a super combinator
  NGlobal(String, Int, List[Instruction])
  // The Indirection node. The key component of implementing lazy evaluation
  NInd(Addr)
} derive(Eq, Show)

struct GHeap {
  // The heap uses an array, 
  // and the space with None content in the array is available as free memory.
  mut object_count : Int
  memory : Array[Node?]
}

// Allocate heap space for nodes.
fn alloc(self : GHeap, node : Node) -> Addr {
  let heap = self
  fn next(n : Int) -> Int {
    (n + 1) % heap.memory.length()
  }

  fn free(i : Int) -> Bool {
    match heap.memory[i] {
      None => true
      _ => false
    }
  }

  let mut i = heap.object_count
  while not(free(i)) {
    i = next(i)
  }
  heap.memory[i] = Some(node)
  heap.object_count = heap.object_count + 1
  return Addr(i)
}
// end heap definition

fn op_get(self : GHeap, key : Addr) -> Node {
  let Addr(i) = key
  match self.memory[i] {
    Some(node) => node
    None => abort("GHeap::get(): index \{i} was empty")
  }
}

fn op_set(self : GHeap, key : Addr, val : Node) -> Unit {
  self.memory[key._] = Some(val)
}

// start state definition
struct GState {
  mut stack : List[Addr]
  heap : GHeap
  globals : @hashmap.T[String, Addr]
  mut code : List[Instruction]
  mut stats : GStats
}

type GStats Int

fn stat_incr(self : GState) -> Unit {
  self.stats = self.stats._ + 1
}

fn put_stack(self : GState, addr : Addr) -> Unit {
  self.stack = Cons(addr, self.stack)
}

fn put_code(self : GState, instrs : List[Instruction]) -> Unit {
  self.code = instrs + self.code
}

fn pop1(self : GState) -> Addr {
  match self.stack {
    Cons(addr, reststack) => {
      self.stack = reststack
      addr
    }
    Nil => abort("pop1(): stack size smaller than 1")
  }
}

// e1 e2 ..... -> (e1, e2) ......
fn pop2(self : GState) -> (Addr, Addr) {
  match self.stack {
    Cons(addr1, Cons(addr2, reststack)) => {
      self.stack = reststack
      (addr1, addr2)
    }
    _ => abort("pop2(): stack size smaller than 2")
  }
}
// end state definition

// start push_int definition
fn push_int(self : GState, num : Int) -> Unit {
  let addr = self.heap.alloc(NNum(num))
  self.put_stack(addr)
}
// end push_int definition

// start push_global definition
fn push_global(self : GState, name : String) -> Unit {
  let sc = self.globals[name]
  match sc {
    None => abort("push_global(): cant find supercombinator \{name}")
    Some(addr) => self.put_stack(addr)
  }
}
// end push_global definition

// start push_arg definition
fn push_arg(self : GState, offset : Int) -> Unit {
  let appaddr = self.stack.unsafe_nth(offset + 1)
  let arg = match self.heap[appaddr] {
    NApp(_, arg) => arg
    otherwise =>
      abort(
        "pusharg: stack offset \{offset} address \{appaddr} node \{otherwise}",
      )
  }
  self.put_stack(arg)
}
// end push_arg definition

// start mk_apply definition
fn mk_apply(self : GState) -> Unit {
  let (a1, a2) = self.pop2()
  let appaddr = self.heap.alloc(NApp(a1, a2))
  self.put_stack(appaddr)
}
// end mk_apply definition

// start update definition
fn update(self : GState, n : Int) -> Unit {
  let addr = self.pop1()
  let dst = self.stack.unsafe_nth(n)
  self.heap[dst] = NInd(addr)
}
// end update definition

// start unwind definition
fn unwind(self : GState) -> Unit {
  let addr = self.pop1()
  match self.heap[addr] {
    NNum(_) => self.put_stack(addr)
    NApp(a1, _) => {
      self.put_stack(addr)
      self.put_stack(a1)
      self.put_code(Cons(Unwind, Nil))
    }
    NGlobal(_, n, c) =>
      if self.stack.length() < n {
        abort("Unwinding with too few arguments")
      } else {
        self.put_stack(addr)
        self.put_code(c)
      }
    NInd(a) => {
      self.put_stack(a)
      self.put_code(Cons(Unwind, Nil))
    }
  }
}
// end unwind definition

// start build_ih definition
fn build_initial_heap(
  scdefs : List[(String, Int, List[Instruction])]
) -> (GHeap, @hashmap.T[String, Addr]) {
  let heap = { object_count: 0, memory: Array::make(10000, None) }
  let globals = @hashmap.new(capacity=50)
  loop scdefs {
    Nil => ()
    Cons((name, arity, instrs), rest) => {
      let addr = heap.alloc(NGlobal(name, arity, instrs))
      globals[name] = addr
      continue rest
    }
  }
  return (heap, globals)
}
// end build_ih definition

// start step definition
fn step(self : GState) -> Bool {
  match self.code {
    Nil => return false
    Cons(i, rest) => {
      self.code = rest
      self.stat_incr()
      match i {
        PushGlobal(f) => self.push_global(f)
        PushInt(n) => self.push_int(n)
        PushArg(n) => self.push_arg(n)
        MkApp => self.mk_apply()
        Unwind => self.unwind()
        Update(n) => self.update(n)
        Pop(n) => self.stack = self.stack.drop(n)
      }
      return true
    }
  }
}
// end step definition

// start reify definition
fn reify(self : GState) -> Node {
  if self.step() {
    self.reify()
  } else {
    let stack = self.stack
    match stack {
      Cons(addr, Nil) => {
        let res = self.heap[addr]
        return res
      }
      _ => abort("wrong stack \{stack}")
    }
  }
}
// end reify definition
