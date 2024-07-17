#![no_std]
#![no_main]

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}

#[no_mangle]
fn fib(n: i32) -> i32 {
    fn aux(n: i32, acc1: i32, acc2: i32) -> i32 {
        match n {
            0 => acc1,
            1 => acc2,
            _ => aux(n - 1, acc2, acc1 + acc2),
        }
    }
    aux(n, 0, 1)
}

#[no_mangle]
pub extern "C" fn test(n: i32, count: i32) -> i32 {
    let mut i = 0;
    let mut res = 0;
    while i < count {
        res = fib(n);
        i = i + 1;
    }
    res
}
