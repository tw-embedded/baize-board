
#[macro_export]
macro_rules! println {
    ($($arg:tt)*) => {{
        use core::fmt::{Write};

        struct Printer;

        extern "C" {
            fn printf(format: *const u8, ...) -> i32;
        }
        impl Write for Printer {
            fn write_str(&mut self, s: &str) -> core::fmt::Result {
                unsafe {
                    printf("%s\0".as_ptr(), s.as_ptr());
                }
                Ok(())
            }
        }

        let _ = writeln!(Printer, $($arg)*);
    }};
}

use core::panic::PanicInfo;
#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}

