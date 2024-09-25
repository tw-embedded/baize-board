use core::cell::RefCell;
use alloc::vec::Vec;
use alloc::boxed::Box;

use crate::framework::event;

pub struct EventBus {
    handlers: RefCell<Vec<Box<dyn event::EventHandler>>>,
}

impl EventBus {
    pub fn new() -> Self {
        Self {
            handlers: RefCell::new(Vec::new()),
        }
    }

    pub fn register_handler(&self, handler: Box<dyn event::EventHandler>) {
        self.handlers.borrow_mut().push(handler);
    }

    pub fn dispatch(&self, event: &dyn event::Event) {
        for handler in self.handlers.borrow().iter() {
            handler.handle(event);
        }
    }
}

