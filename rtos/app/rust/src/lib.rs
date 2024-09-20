#![no_std]
#![no_main]

mod macros;

#[no_mangle]
pub extern "C" fn rust_main() {
    println!("rust main");
}

