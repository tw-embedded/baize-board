#![no_std]

#[macro_export]
macro_rules! pr_info {
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

#[macro_export]
macro_rules! println {
    ($($arg:tt)*) => {{
        use core::fmt::{self, Write};

        struct Printer;

        extern "C" {
            fn printf(format: *const i8, ...) -> i32;
        }

        impl Write for Printer {
            fn write_str(&mut self, s: &str) -> fmt::Result {
                unsafe {
                    printf(b"%s\0".as_ptr() as *const i8, s.as_ptr() as *const i8);
                }
                Ok(())
            }
        }

        let mut printer = Printer;
        let _ = write!(printer, "{}\n\0", format_args!($($arg)*));
    }};
}

use core::panic::PanicInfo;
#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

