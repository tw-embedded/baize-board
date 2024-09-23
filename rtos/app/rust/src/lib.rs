#![no_std]
#![no_main]

mod macros;

include!(concat!(env!("OUT_DIR"), "/bindings.rs"));

use core::alloc::{GlobalAlloc, Layout};
use core::panic::PanicInfo;

struct Allocator;

unsafe impl GlobalAlloc for Allocator {
    unsafe fn alloc(&self, layout: Layout) -> *mut u8 {
        pr_info!("implement alloc!!!");
        assert!(false);
        core::ptr::null_mut()
    }

    unsafe fn dealloc(&self, _ptr: *mut u8, _layout: Layout) {
    }
}

#[global_allocator]
static ALLOC: Allocator = Allocator;

extern "C" fn thread_entry(_input: ULONG) {
    pr_info!("rust thread entry function executing.");
    
    let mut cnt = 1;
    loop {
        pr_info!("rust delay %d", cnt);
        println!("count {}", cnt);
        println!("cnt {}", cnt);
        unsafe { _tx_thread_sleep(100); }
        cnt += 1;
    }
}

// note: for println, 1024 is not enough!
static mut stack: [u8; 2048] = [0; 2048];

fn create_thread() {
    unsafe {
        let mut thread: TX_THREAD = core::mem::zeroed();

        let status = _tx_thread_create(
            &mut thread as *mut TX_THREAD,
            b"rust_thread\0".as_ptr() as *mut i8,
            Some(thread_entry),
            0,
            stack.as_mut_ptr() as *mut core::ffi::c_void,
            stack.len() as ULONG,
            1, // priority
            1, // pre-priority
            0,
            1
        );

        if status == 0 {
            pr_info!("thread created successfully!");
        } else {
            pr_info!("failed to create thread. status: {}", status);
        }
    }
}

#[no_mangle]
pub extern "C" fn rust_main() {
    pr_info!("rust main");
    create_thread();
}

