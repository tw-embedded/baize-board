#![no_std]
#![no_main]

mod macros;

include!(concat!(env!("OUT_DIR"), "/bindings.rs"));

extern "C" fn thread_entry(_input: ULONG) {
    println!("rust thread entry function executing.");
    
    let mut cnt = 1;
    loop {
        println!("rust delay");
        unsafe { _tx_thread_sleep(100); }
        cnt += 1;
    }
}

static mut stack: [u8; 1024] = [0; 1024];

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
            1,
            1,
            0,
            1
        );

        if status == 0 {
            println!("thread created successfully!");
        } else {
            println!("failed to create thread. status: {}", status);
        }
    }
}

#[no_mangle]
pub extern "C" fn rust_main() {
    println!("rust main");
    create_thread();
}

