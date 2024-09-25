use core::cell::RefCell;
use alloc::vec::Vec;
use alloc::boxed::Box;
use alloc::string::String; 

use crate::framework::event;
use crate::framework::bus;
use crate::println;

pub struct MyEvent {
    pub message: String
}

impl event::Event for MyEvent {
    fn get_type(&self) -> &'static str {
        "MyEvent"
    }
}

pub struct MyEventHandler;

impl event::EventHandler for MyEventHandler {
    fn handle(&self, event: &dyn event::Event) {
        if event.get_type() == "MyEvent" {
            //let my_event = event.downcast_ref::<myevent::MyEvent>().unwrap();
            //println!("Handling MyEvent with message: {}", my_event.message);
            println!("handle example event...");
            //let myevent::MyEvent { message } = event;
        }
    }
}

pub fn init_features() {
    println!("start framework...");
    let mut bus = bus::EventBus::new();
    let handler = MyEventHandler;
    bus.register_handler(Box::new(handler));
    let event = MyEvent { message: String::from("hey") };
    bus.dispatch(&event);
}

