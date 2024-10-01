use alloc::boxed::Box;
use alloc::string::String; 
use core::any::Any;

use crate::framework::event;
use crate::framework::bus;

#[cfg(target_arch = "aarch64")]
use crate::println;

pub struct MyEvent {
    pub message: String
}

impl event::Event for MyEvent {
    fn get_type(&self) -> &'static str {
        "MyEvent"
    }

    fn as_any(&self) -> &dyn Any { self }
}

pub struct MyEventHandler;

impl event::EventHandler for MyEventHandler {
    fn handle(&self, event: &dyn event::Event) {
        if event.get_type() == "MyEvent" {
            let my_event = event.as_any().downcast_ref::<MyEvent>().unwrap();
            println!("handle example event...{}", my_event.message);
        }
    }
}

pub fn init_features() {
    println!("init features...");
    let bus = bus::EventBus::new();
    let handler = MyEventHandler;
    bus.register_handler(Box::new(handler));
    let event = MyEvent { message: String::from("hey") };
    bus.dispatch(&event);
}

use crate::register;
use crate::framework::init;
struct Example;
impl init::Feature for Example {
    fn init(&self) {
        println!("feat 1 init!");
    }
    fn event_type(&self) {}
    fn handler(&self) {}
}
register!(Example, init_example);

