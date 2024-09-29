#[cfg(target_arch = "aarch64")]
use crate::println;

pub trait Initializer {
    fn init();
}

pub struct InitInfo {
    pub private: u32
}

#[macro_export]
macro_rules! register1 {
    ($name:ident) => {
        #[allow(dead_code)]
        static GLOBAL: core::mem::MaybeUninit<InitInfo> = core::mem::MaybeUninit::uninit();
        //static GLOBAL: core::cell::UnsafeCell<InitInfo> = core::cell::UnsafeCell::new(0);
        //#[link_section = ".rust_init"]
        //static const ADDR: *const InitInfo = &GLOBAL as *const InitInfo;
    };
}

#[macro_export]
macro_rules! register {
    ($func:ident) => {
        #[link_section = ".rust_init"]
        #[no_mangle]
        static INIT_FUNC_PTR: fn() = $func;
    };
}

pub type InitFn = fn();

extern "C" {
    static __rust_init_start: usize;
    static __rust_init_end: usize;
}

pub fn init_framework() {
    println!("init framework!");
    unsafe {
        let start = &__rust_init_start as *const usize as *const InitFn;
        let end = &__rust_init_end as *const usize as *const InitFn;

        let count = end as usize - start as usize;
        let count = count / core::mem::size_of::<InitFn>();

        let init_fns = core::slice::from_raw_parts(start, count);

        for &fn_ptr in init_fns {
            fn_ptr();
        }
    }
}
