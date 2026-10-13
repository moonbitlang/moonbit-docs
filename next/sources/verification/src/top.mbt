pub enum Tree {
  Empty
  Node(Tree, Int32, Tree, Int32)
}

pub struct Bridge {
  reserve : Int32
  used_nonces : Int32
}

// start proof pure 1
#proof_pure
fn height(t : Tree) -> Int32 {
  match t {
    Empty => 0
    Node(_, _, _, h) => h
  }
}
// end proof pure 1

pub fn cached_height(t : Tree) -> Int32 where {
  proof_ensure: result => cached_height_ok(t, result),
} {
  height(t)
}

pub fn leaf(x : Int32) -> Tree {
  Node(Empty, x, Empty, 1)
}

// start contract 1
pub fn binary_search(
  xs : FixedArray[Int32],
  key : Int32,
) -> Int32? where {
  proof_require: sorted(xs),
  proof_ensure: result => binary_search_ok(xs, key, result),
} {
  for i = 0, j = xs.length(); i < j; {
    let h = i + (j - i) / 2
    if xs[h] < key {
      proof_assert ∀ idx : Int32,
        (0 <= idx) && (idx < h + 1) → xs[idx] < key
      continue h + 1, j
    } else if key < xs[h] {
      proof_assert ∀ idx : Int32,
        (h <= idx) && (idx < xs.length()) → key < xs[idx]
      continue i, h
    } else {
      proof_assert xs[h] == key
      break Some(h)
    }
  } nobreak {
    None
  } where {
    proof_invariant: 0 <= i,
    proof_invariant: i <= j,
    proof_invariant: j <= xs.length(),
    proof_invariant: ∀ idx : Int32, (0 <= idx) && (idx < i) → xs[idx] < key,
    proof_invariant: ∀ idx : Int32, (j <= idx) && (idx < xs.length()) → key < xs[idx],
    proof_yield: res => binary_search_ok(xs, key, res),
    proof_reasoning: (
      #| The loop maintains a candidate window `[i, j)`.
      #| Every index before `i` is known to hold a value `< key`, and every
      #| index from `j` onward is known to hold a value `> key`.
      #|
      #| At midpoint `h` there are three cases:
      #|   - `xs[h] < key`: move the left boundary to `h + 1`
      #|   - `key < xs[h]`: move the right boundary to `h`
      #|   - otherwise, the element at `h` is equal to `key`
      #|
      #| If the loop exits normally, the exclusion invariants cover the whole
      #| array, so no index can contain `key`.
    ),
  }
}
// end contract 1

// start loop invariant 1
pub fn search_window(
  xs : FixedArray[Int32],
  key : Int32,
) -> Int32? where {
  proof_require: sorted(xs),
  proof_ensure: result => binary_search_ok(xs, key, result),
} {
  for i = 0, j = xs.length(); i < j; {
    let h = i + (j - i) / 2
    if xs[h] < key {
      proof_assert ∀ idx : Int32,
        (0 <= idx) && (idx < h + 1) → xs[idx] < key
      continue h + 1, j
    } else if key < xs[h] {
      proof_assert ∀ idx : Int32,
        (h <= idx) && (idx < xs.length()) → key < xs[idx]
      continue i, h
    } else {
      proof_assert xs[h] == key
      break Some(h)
    }
  } nobreak {
    None
  } where {
    proof_invariant: 0 <= i,
    proof_invariant: i <= j,
    proof_invariant: j <= xs.length(),
    proof_invariant: ∀ idx : Int32, (0 <= idx) && (idx < i) → xs[idx] < key,
    proof_invariant: ∀ idx : Int32, (j <= idx) && (idx < xs.length()) → key < xs[idx],
    proof_yield: res => binary_search_ok(xs, key, res),
  }
}
// end loop invariant 1

pub fn deposit(bridge : Bridge, amount : Int32) -> Bridge where {
  proof_require: bridge_inv(bridge),
  proof_require: 0 <= amount,
  proof_ensure: result => deposit_post(bridge, amount, result),
} {
  { reserve: bridge.reserve + amount, used_nonces: bridge.used_nonces }
}

// start proof decrease 1
pub fn countdown(n : Int32) -> Int32 where {
  proof_decrease: n,
  proof_require: 0 <= n,
  proof_ensure: result => 0 <= result,
} {
  if n <= 0 {
    0
  } else {
    countdown(n - 1)
  }
}
// end proof decrease 1

// start proof axiomatized 1
pub fn assumed_nonnegative(x : Int32) -> Int32 where {
  proof_axiomatized: true,
  proof_require: 0 <= x,
  proof_ensure: result => 0 <= result,
} {
  x
}
// end proof axiomatized 1
