#![cfg_attr(target_arch = "aarch64", no_std)]
#![cfg_attr(target_arch = "aarch64", no_main)]

extern crate alloc;

mod platform;
pub mod framework;
mod features;

use alloc::string::String;
use core::ptr::addr_of_mut;

use crate::platform::binding::*;

fn test_string() {
    let mut s = String::from("test");
    s.push_str("-str");
    println!("{}", s);
}

#[cfg(all(not(feature = "aes"), target_arch = "aarch64"))]
compile_error!("need aes feature in cargo.toml!");

const STACK_MAGIC: u8 = 0xef;

extern "C" fn thread_entry(_input: ULONG) {
    pr_info!("rust thread entry function executing.");
    
    let mut cnt = 1;
    loop {
        println!("rust delay {}", cnt);
        unsafe { _tx_thread_sleep(10000); } // parameter: tick, 10ms
        cnt += 1;
        test_string();

        // stack water level check
        println!("stack bottom {:x}", unsafe { STACK.as_ptr() as usize }); // use {:?} to format as_ptr is a bad idea
        for (index, &value) in unsafe { STACK.iter().enumerate() } {
            if value != STACK_MAGIC {
                //println!("stack water level {}", index);
                pr_info!("stack water level %x. value %x", index, value as u32);
                break;
            }
        }
    }
}

// 1024 is not enough for rust core format
static mut STACK: [u8; 2048] = [0; 2048];

static mut THREAD: TX_THREAD = unsafe { core::mem::zeroed() };

fn create_thread() {
    let status;

    unsafe {
        status = _tx_thread_create(
            addr_of_mut!(THREAD) as *mut TX_THREAD, //&mut THREAD as *mut TX_THREAD,
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
    }
    if status == 0 {
        pr_info!("thread created successfully!");
    } else {
        pr_info!("failed to create thread. status: %d", status);
    }
}

#[no_mangle]
pub extern "C" fn rust_main() {
    pr_info!("rust main");
    #[cfg(target_arch = "aarch64")]
    platform::alloc::init_heap();
    create_thread();
    framework::init::init_framework();
    features::example::init_features();
}

