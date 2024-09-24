use crate::println;
use crate::framework::event;
use crate::framework::myevent;

pub struct MyEventHandler;

impl event::EventHandler for MyEventHandler {
    fn handle(&self, event: &dyn event::Event) {
        if event.get_type() == "MyEvent" {
            //let my_event = event.downcast_ref::<myevent::MyEvent>().unwrap();
            //println!("Handling MyEvent with message: {}", my_event.message);
            println!("handle eventtttt");
            //let myevent::MyEvent { message } = event;
        }
    }
}

