
#[cfg(target_arch = "aarch64")]
use crate::println;

pub trait Feature {
    fn init(&self);
    fn handler(&self);
    fn event_type(&self);
}

#[macro_export]
macro_rules! concat_idents {
    ($($e:ident),+ $(,)?) => { ... };
}

#[macro_export]
macro_rules! init_call {
    ($func:ident, $rb:ident) => {
        #[link_section = ".rust_init"]
        #[no_mangle]
        static $rb: fn() = $func;
    };
}

#[macro_export]
macro_rules! register {
    ($feat:ident, $rb_func:ident) => {
        use init::Feature; // method not found if not use!
        static _V: $feat = $feat;
        fn _init_feature_() {
            println!("init feature {}!", stringify!($feat));
            // TODO: add to golbal features
            _V.init();
        }
        use crate::init_call;
        init_call!(_init_feature_, $rb_func);
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
