function aux(n: i32, acc1: i32, acc2: i32): i32 {
  switch (n) {
    case 0:
      return acc1;
    case 1:
      return acc2;
    default:
      return aux(n - 1, acc2, acc1 + acc2);
  }
}

export function fib2(num: i32): i32 {
  return aux(num, 0, 1);
}
