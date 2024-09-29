
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

#[cfg(target_arch = "aarch64")]
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
        let _ = write!(printer, "{}\0", format_args!($($arg)*));
        unsafe { printf(b"\n\0".as_ptr() as *const i8); }
    }};
}

#[cfg(target_arch = "aarch64")]
use core::panic::PanicInfo;

#[cfg(target_arch = "aarch64")]
#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

