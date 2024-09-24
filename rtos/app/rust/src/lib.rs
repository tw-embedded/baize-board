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

//#[cfg(not(feature = "strict-align"))]
//compile_error!("need +strict-align feature!");

const STACK_MAGIC: u8 = 0xef;

extern "C" fn thread_entry(_input: ULONG) {
    pr_info!("rust thread entry function executing.");
    
    let mut cnt = 1;
    loop {
        println!("rust delay {}", cnt);
        unsafe { _tx_thread_sleep(100); }
        cnt += 1;

        // stack water level check
        unsafe { 
            println!("stack bottom {:x}", STACK.as_ptr() as usize); // use {:?} to format as_ptr is a bad idea
            for (index, &value) in STACK.iter().enumerate() {
                if value != STACK_MAGIC {
                    //println!("stack water level {}", index);
                    pr_info!("stack water level %x. value %x", index, value as u32);
                    break;
                }
            }
        }
    }
}

// 1024 is not enough for rust core format
static mut STACK: [u8; 2048] = [0; 2048];

static mut THREAD: TX_THREAD = unsafe { core::mem::zeroed() };

fn create_thread() {
    unsafe {
        let status = _tx_thread_create(
            &mut THREAD as *mut TX_THREAD,
            b"rust_thread\0".as_ptr() as *mut i8,
            Some(thread_entry),
            0,
            STACK.as_mut_ptr() as *mut core::ffi::c_void,
            STACK.len() as ULONG,
            1, // priority
            1, // pre-priority
            0,
            1
        );

        if status == 0 {
            pr_info!("thread created successfully!");
        } else {
            pr_info!("failed to create thread. status: %d", status);
        }
    }
}

#[no_mangle]
pub extern "C" fn rust_main() {
    pr_info!("rust main");
    create_thread();
}

