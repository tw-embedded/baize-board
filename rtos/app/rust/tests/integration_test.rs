use core::any::Any;
use rust::framework::bus;
use rust::framework::event;

#[test]
fn it_test_print() {
    println!("test print done!");
}

pub struct ExampleEvent {
    pub message: String
}

impl event::Event for ExampleEvent {
    fn get_type(&self) -> &'static str {
        "MyEvent"
    }

    fn as_any(&self) -> &dyn Any { self }
}

pub struct MyEventHandler;

impl event::EventHandler for MyEventHandler {
    fn handle(&self, event: &dyn event::Event) {
        if event.get_type() == "MyEvent" {
            let my_event = event.as_any().downcast_ref::<ExampleEvent>().unwrap();
            println!("handle example event...{}", my_event.message);
            assert_eq!(my_event.message, "hey", "expect {}, but got {}!", "hey", my_event.message);
        } else {
            assert!(false, "event type error!");
        }
    }
}

#[test]
fn it_test_framework() {
    println!("start framework...");
    let bus = bus::EventBus::new();
    let handler = MyEventHandler;
    bus.register_handler(Box::new(handler));
    let event = ExampleEvent { message: String::from("hey") };
    bus.dispatch(&event);
}

