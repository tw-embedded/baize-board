#![no_std]
#![no_main]

mod macros;
mod framework;
mod features;

include!(concat!(env!("OUT_DIR"), "/bindings.rs"));

extern crate alloc;

use core::alloc::{GlobalAlloc, Layout};
use core::panic::PanicInfo;
use alloc::string::String;
use alloc::vec::Vec;

use linked_list_allocator::LockedHeap;

#[global_allocator]
static ALLOCATOR: LockedHeap = LockedHeap::empty();

const HEAP_SIZE: usize = 512;
static mut heap: [u8; HEAP_SIZE] = [0u8; HEAP_SIZE];

fn init_heap() {
    unsafe { ALLOCATOR.lock().init(heap.as_mut_ptr() as *mut u8, HEAP_SIZE); }
}

fn test_string() {
    let mut s = String::from("test");
    s.push_str("-str");
    println!("{}", s);
}

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
        test_string();

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

use crate::features::example;

#[no_mangle]
pub extern "C" fn rust_main() {
    pr_info!("rust main");
    init_heap();
    create_thread();
    example::init_features();
}

