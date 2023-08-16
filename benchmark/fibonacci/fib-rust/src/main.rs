#![no_std]
#![no_main]

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}

#[no_mangle]
pub extern "C" fn fib2(n: i32) -> i32 {
  fn aux(n: i32, acc1: i32, acc2: i32) -> i32 {
    match n {
        0 => acc1,
        1 => acc2,
        _ => aux(n-1, acc2, acc1+acc2)
    }
  }
  aux(n, 0, 1)
}
