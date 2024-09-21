#![no_std]

#[macro_export]
macro_rules! print {
    ($fmt:expr) => {{
        unsafe {
            extern "C" {
                fn printf(fmt: *const i8, ...) -> i32;
            }
            printf(concat!($fmt, "\n\0").as_ptr() as *const i8);
        }
    }};
    ($fmt:expr, $($arg:tt)*) => {{
        unsafe {
            extern "C" {
                fn printf(fmt: *const i8, ...) -> i32;
            }
            printf(concat!($fmt, "\n\0").as_ptr() as *const i8, $($arg)*);
        }
    }};
}

use core::panic::PanicInfo;
#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

