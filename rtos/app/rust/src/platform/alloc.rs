use linked_list_allocator::LockedHeap;

#[global_allocator]
static ALLOCATOR: LockedHeap = LockedHeap::empty();

const HEAP_SIZE: usize = 512;
static mut HEAP: [u8; HEAP_SIZE] = [0u8; HEAP_SIZE];

pub fn init_heap() {
    unsafe { ALLOCATOR.lock().init(HEAP.as_mut_ptr() as *mut u8, HEAP_SIZE); }
}

